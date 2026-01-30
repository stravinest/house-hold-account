import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/supabase_error_handler.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/learned_sms_format.dart';
import '../../domain/entities/financial_service_template.dart';
import '../../data/services/sms_parsing_service.dart';
import '../../data/services/sms_listener_service.dart';
import '../../data/services/sms_scanner_service.dart';
import '../../data/services/auto_save_service.dart';
import '../providers/payment_method_provider.dart';

/// Payment method add mode
enum PaymentMethodAddMode {
  /// Manual entry (shared, canAutoSave = false)
  manual,

  /// Auto collect (personal, canAutoSave = true)
  autoCollect,
}

class PaymentMethodWizardPage extends ConsumerStatefulWidget {
  final PaymentMethod? paymentMethod;
  final PaymentMethodAddMode? initialMode;

  const PaymentMethodWizardPage({
    super.key,
    this.paymentMethod,
    this.initialMode,
  });

  @override
  ConsumerState<PaymentMethodWizardPage> createState() =>
      _PaymentMethodWizardPageState();
}

class _PaymentMethodWizardPageState
    extends ConsumerState<PaymentMethodWizardPage> {
  late int _currentStep;
  PaymentMethodAddMode? _selectedMode;
  FinancialServiceTemplate? _selectedTemplate;
  late TextEditingController _nameController;
  late TextEditingController _sampleController;
  late TextEditingController _keywordsController;

  bool get isEdit => widget.paymentMethod != null;

  // Auto save mode selection (suggest | auto)
  AutoSaveMode _autoSaveMode = AutoSaveMode.suggest;

  // Notification type for auto-collect (sms or push)
  String _notificationType = 'sms';

  // Analyzed format
  LearnedSmsFormat? _generatedFormat;

  // Debounce timer for sample analysis
  Timer? _debounceTimer;

  // Submission loading state
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.paymentMethod?.name ?? '',
    );
    _sampleController = TextEditingController();
    _keywordsController = TextEditingController();

    // Edit mode initial settings
    if (isEdit) {
      _currentStep = 2; // Go directly to settings screen
      _selectedMode = widget.paymentMethod!.canAutoSave
          ? PaymentMethodAddMode.autoCollect
          : PaymentMethodAddMode.manual;

      // Initialize autoSaveMode from existing payment method
      _autoSaveMode = widget.paymentMethod!.autoSaveMode;

      // Initialize notification type (SMS/Push) from existing payment method
      _notificationType = widget.paymentMethod!.autoCollectSource.name;

      // Try template matching for auto-collect mode
      if (_selectedMode == PaymentMethodAddMode.autoCollect) {
        _selectedTemplate = FinancialServiceTemplate.templates
            .cast<FinancialServiceTemplate?>()
            .firstWhere(
              (t) => t?.name == widget.paymentMethod?.name,
              orElse: () => null,
            );

        if (_selectedTemplate != null) {
          _sampleController.text = _selectedTemplate!.defaultSampleSms;
        }

        // Load existing learned_sms_format from DB
        // DB 로드 완료 후 샘플 분석 실행 (순서 보장)
        _loadExistingFormatThenAnalyze();
      }
    } else if (widget.initialMode != null) {
      // When initialMode is specified
      _selectedMode = widget.initialMode;
      if (_selectedMode == PaymentMethodAddMode.manual) {
        _currentStep = 2; // Manual entry goes directly to name input
      } else {
        _currentStep = 1; // Auto-collect goes to service selection
      }
    } else {
      _currentStep = 0; // Start with mode selection
    }

    // Re-analyze format when sample text changes (with debounce)
    _sampleController.addListener(_onSampleTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _sampleController.removeListener(_onSampleTextChanged);
    _nameController.dispose();
    _sampleController.dispose();
    _keywordsController.dispose();
    super.dispose();
  }

  void _onSampleTextChanged() {
    // Cancel previous timer and set new one (debounce)
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _analyzeSampleImmediate();
    });
  }

  void _analyzeSampleImmediate() {
    if (_selectedTemplate == null) return;

    final sample = _sampleController.text;
    if (sample.isEmpty) return;

    setState(() {
      _generatedFormat = SmsParsingService.generateFormatFromSample(
        sample: sample,
        paymentMethodId: widget.paymentMethod?.id ?? 'temp_id',
      );
    });
  }

  /// Edit 모드에서 DB에서 기존 learned_sms_format 로드
  Future<void> _loadExistingFormat() async {
    if (!isEdit || widget.paymentMethod == null) return;

    final formatRepository = ref.read(learnedSmsFormatRepositoryProvider);
    final existingFormats = await formatRepository.getFormatsByPaymentMethod(
      widget.paymentMethod!.id,
    );

    if (existingFormats.isNotEmpty && mounted) {
      setState(() {
        _generatedFormat = existingFormats.first;
      });
    }
  }

  /// Edit 모드에서 DB 로드 완료 후 샘플 분석 실행 (순서 보장)
  Future<void> _loadExistingFormatThenAnalyze() async {
    if (!isEdit || widget.paymentMethod == null) return;

    // 1. 먼저 DB에서 기존 포맷 로드
    final formatRepository = ref.read(learnedSmsFormatRepositoryProvider);
    final existingFormats = await formatRepository.getFormatsByPaymentMethod(
      widget.paymentMethod!.id,
    );

    if (!mounted) return;

    // 2. DB에 기존 포맷이 있으면 사용
    if (existingFormats.isNotEmpty) {
      setState(() {
        _generatedFormat = existingFormats.first;
      });
    }
    // 3. DB에 없고 샘플이 있으면 샘플 분석 실행
    else if (_sampleController.text.isNotEmpty) {
      _analyzeSampleImmediate();
    }
  }

  void _selectMode(PaymentMethodAddMode mode) {
    setState(() {
      _selectedMode = mode;
      if (mode == PaymentMethodAddMode.manual) {
        _currentStep = 2; // Manual entry goes directly to name input
        _selectedTemplate = null;
        _nameController.text = '';
      } else {
        _currentStep = 1; // Auto-collect goes to service selection
      }
    });
  }

  void _selectTemplate(FinancialServiceTemplate? template) {
    setState(() {
      _selectedTemplate = template;
      _currentStep = 2;

      if (template != null) {
        _nameController.text = template.name;
        _notificationType = 'sms';
        _sampleController.text = template.defaultSampleSms;
        _analyzeSampleImmediate();
      } else {
        // Direct input (selecting "Other" in auto-collect mode)
        _nameController.text = '';
        _sampleController.text = '';
        _generatedFormat = null;
      }
    });
  }

  void _changeNotificationType(String type) {
    setState(() {
      _notificationType = type;
      // Update sample when switching types
      if (_selectedTemplate != null) {
        if (type == 'sms') {
          _sampleController.text = _selectedTemplate!.defaultSampleSms;
        } else {
          _sampleController.text = _selectedTemplate!.defaultSamplePush ?? '';
        }
        _analyzeSampleImmediate();
      }
    });
  }

  void _goBack() {
    if (isEdit) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      if (_currentStep == 2) {
        if (_selectedMode == PaymentMethodAddMode.manual) {
          // Manual entry -> mode selection
          if (widget.initialMode != null) {
            Navigator.pop(context);
          } else {
            _currentStep = 0;
            _selectedMode = null;
          }
        } else {
          // Auto-collect settings -> service selection
          _currentStep = 1;
          _selectedTemplate = null;
        }
      } else if (_currentStep == 1) {
        // Service selection -> mode selection
        if (widget.initialMode != null) {
          Navigator.pop(context);
        } else {
          _currentStep = 0;
          _selectedMode = null;
        }
      } else {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _submit() async {
    // Cannot proceed if template selected in auto-collect mode but no format
    if (_selectedMode == PaymentMethodAddMode.autoCollect &&
        _selectedTemplate != null &&
        _generatedFormat == null) {
      return;
    }

    // Prevent double submission
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final notifier = ref.read(paymentMethodNotifierProvider.notifier);
      final formatRepository = ref.read(learnedSmsFormatRepositoryProvider);

      // Determine canAutoSave: false for manual, true for auto-collect
      final canAutoSave = _selectedMode == PaymentMethodAddMode.autoCollect;

      final trimmedName = _nameController.text.trim();

      if (isEdit) {
        // 개인 → 공유로 변경 시 경고
        final oldCanAutoSave = widget.paymentMethod!.canAutoSave;
        if (oldCanAutoSave && !canAutoSave) {
          final confirmed = await _showPermissionEscalationWarning();
          if (confirmed != true) return;
        }

        // 1. Update payment method
        await notifier.updatePaymentMethod(
          id: widget.paymentMethod!.id,
          name: trimmedName,
          canAutoSave: canAutoSave,
        );

        // 2. Update autoSaveMode and autoCollectSource (only for auto-collect mode)
        if (canAutoSave) {
          await notifier.updateAutoSaveSettings(
            id: widget.paymentMethod!.id,
            autoSaveMode: _autoSaveMode,
            autoCollectSource: AutoCollectSource.fromString(_notificationType),
          );
        }

        // 3. Save or update learned format (only when template selected in auto-collect mode)
        // Delete all existing formats and create new one to ensure consistency
        if (canAutoSave &&
            _selectedTemplate != null &&
            _generatedFormat != null) {
          final existingFormats = await formatRepository
              .getFormatsByPaymentMethod(widget.paymentMethod!.id);

          // Delete all existing formats to prevent inconsistency
          for (final format in existingFormats) {
            await formatRepository.deleteFormat(format.id);
          }

          // Create new format with updated settings
          await formatRepository.createFormat(
            paymentMethodId: widget.paymentMethod!.id,
            senderPattern: _generatedFormat!.senderPattern,
            senderKeywords: _generatedFormat!.senderKeywords,
            amountRegex: _generatedFormat!.amountRegex,
            typeKeywords: _generatedFormat!.typeKeywords,
            merchantRegex: _generatedFormat!.merchantRegex,
            dateRegex: _generatedFormat!.dateRegex,
            sampleSms: _generatedFormat!.sampleSms,
            isSystem: false,
            confidence: _generatedFormat!.confidence,
          );
        }
      } else {
        // 1. Create payment method
        final paymentMethod = await notifier.createPaymentMethod(
          name: trimmedName,
          icon: '',
          color: _selectedTemplate?.color ?? '#9E9E9E',
          canAutoSave: canAutoSave,
        );

        // 2. Update autoSaveMode and autoCollectSource (only for auto-collect mode)
        if (canAutoSave) {
          await notifier.updateAutoSaveSettings(
            id: paymentMethod.id,
            autoSaveMode: _autoSaveMode,
            autoCollectSource: AutoCollectSource.fromString(_notificationType),
          );
        }

        // 3. Save learned format (only when template selected in auto-collect mode)
        if (canAutoSave &&
            _selectedTemplate != null &&
            _generatedFormat != null) {
          await formatRepository.createFormat(
            paymentMethodId: paymentMethod.id,
            senderPattern: _generatedFormat!.senderPattern,
            senderKeywords: _generatedFormat!.senderKeywords,
            amountRegex: _generatedFormat!.amountRegex,
            typeKeywords: _generatedFormat!.typeKeywords,
            merchantRegex: _generatedFormat!.merchantRegex,
            dateRegex: _generatedFormat!.dateRegex,
            sampleSms: _generatedFormat!.sampleSms,
            isSystem: false,
            confidence: _generatedFormat!.confidence,
          );
        }
      }

      // Refresh providers - invalidate all related providers
      ref.invalidate(sharedPaymentMethodsProvider);
      ref.invalidate(paymentMethodsProvider);

      // For auto-collect payment method, also refresh the user's provider and listeners
      if (canAutoSave) {
        final currentUserId = ref.read(currentUserProvider)?.id;
        if (currentUserId != null) {
          ref.invalidate(
            autoCollectPaymentMethodsByOwnerProvider(currentUserId),
          );
        }
        // Refresh SMS/Push listener caches to apply new autoCollectSource setting
        await AutoSaveService.instance.refreshPaymentMethods();
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, st) {
      debugPrint('PaymentMethod save failed: $e\n$st');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (e is DuplicateItemException) {
          SnackBarUtils.showError(
            context,
            l10n.paymentMethodWizardDuplicateName,
          );
        } else {
          SnackBarUtils.showError(context, l10n.paymentMethodWizardSaveFailed);
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String title;
    if (isEdit) {
      title = l10n.paymentMethodWizardEditTitle;
    } else if (_currentStep == 0) {
      title = l10n.paymentMethodWizardAddTitle;
    } else if (_selectedMode == PaymentMethodAddMode.manual) {
      title = l10n.paymentMethodWizardManualAddTitle;
    } else {
      title = l10n.paymentMethodWizardAutoCollectAddTitle;
    }

    // Show bottom button only in configuration step (step 2)
    final showBottomButton = _currentStep == 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : _goBack,
        ),
        bottom: _isSubmitting
            ? const PreferredSize(
                preferredSize: Size.fromHeight(2),
                child: LinearProgressIndicator(minHeight: 2),
              )
            : null,
      ),
      body: _buildBody(),
      bottomNavigationBar: showBottomButton
          ? Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      disabledBackgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.6),
                      disabledForegroundColor: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withValues(alpha: 0.8),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: _isSubmitting
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                l10n.paymentMethodWizardSaving,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            isEdit
                                ? l10n.paymentMethodWizardSaveButton
                                : l10n.paymentMethodWizardAddButton,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_currentStep == 0) {
      return _buildModeSelection();
    } else if (_currentStep == 1) {
      return _buildServiceSelection();
    } else {
      return _buildConfiguration();
    }
  }

  /// Step 0: Mode selection (manual vs auto-collect)
  Widget _buildModeSelection() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.paymentMethodWizardModeQuestion,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // Manual entry card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _selectMode(PaymentMethodAddMode.manual),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.edit_outlined,
                        color: Colors.blue[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.paymentMethodWizardManualMode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.paymentMethodWizardSharedBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.paymentMethodWizardManualDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Auto-collect card
          Card(
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _selectMode(PaymentMethodAddMode.autoCollect),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        color: Colors.green[700],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                l10n.paymentMethodWizardAutoCollectMode,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.paymentMethodWizardPersonalBadge,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.paymentMethodWizardAutoCollectDescription,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Step 1: Service selection (auto-collect mode only) - chip grid style
  Widget _buildServiceSelection() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final cards = FinancialServiceTemplate.templates
        .where((t) => t.category == FinancialServiceCategory.card)
        .toList();
    final localCurrencies = FinancialServiceTemplate.templates
        .where((t) => t.category == FinancialServiceCategory.localCurrency)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          l10n.paymentMethodWizardServiceQuestion,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.paymentMethodWizardServiceDescription,
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        const SizedBox(height: 24),

        // 1. Card section
        if (cards.isNotEmpty) ...[
          Text(
            l10n.paymentMethodWizardCategoryCard,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: cards.map((t) => _buildTemplateChip(t)).toList(),
          ),
        ],

        const SizedBox(height: 24),

        // 2. Local currency section
        if (localCurrencies.isNotEmpty) ...[
          Text(
            l10n.paymentMethodWizardCategoryLocalCurrency,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: localCurrencies
                .map((t) => _buildTemplateChip(t))
                .toList(),
          ),
        ],
      ],
    );
  }

  /// Template chip widget - improved touch target size
  Widget _buildTemplateChip(FinancialServiceTemplate template) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(template.name),
      onPressed: () => _selectTemplate(template),
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      // Increased padding for better touch target (min 48dp)
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  /// Step 2: Configuration screen
  Widget _buildConfiguration() {
    // Manual mode or auto-collect mode without template
    if (_selectedMode == PaymentMethodAddMode.manual ||
        (_selectedMode == PaymentMethodAddMode.autoCollect &&
            _selectedTemplate == null)) {
      return _buildManualConfiguration();
    }

    // Auto-collect mode with template selected
    return _buildAutoCollectConfiguration();
  }

  /// Manual entry configuration screen (name only)
  Widget _buildManualConfiguration() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shared notice badge
          if (_selectedMode == PaymentMethodAddMode.manual) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.people_outline, size: 18, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.paymentMethodWizardSharedNotice,
                      style: TextStyle(fontSize: 13, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          Text(
            l10n.paymentMethodWizardNameLabel,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            maxLength: 20,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.paymentMethodWizardNameHint,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }

  /// Auto-collect configuration screen (after template selection)
  Widget _buildAutoCollectConfiguration() {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal use notice badge - 디자인 시스템 적용
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0), // #FFF3E0
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFFCC80)), // #FFCC80
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline,
                  size: 18,
                  color: Color(0xFFE65100),
                ), // #E65100
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.paymentMethodWizardPersonalNotice,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFFE65100), // #E65100
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 1. Name setting - 자동수집은 수정 불가 (읽기 전용)
          TextFormField(
            controller: _nameController,
            maxLength: 20,
            enabled: false, // 자동수집 결제수단은 이름 수정 불가
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF5F5F5), // #F5F5F5
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
              counterText: '',
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(4),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Notification type selection (SMS / Push) - 디자인 시스템 적용
          Text(
            l10n.paymentMethodWizardCollectSource,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildCollectSourceOption(
                    value: 'sms',
                    icon: Icons.sms_outlined,
                    label: l10n.paymentMethodWizardSmsSource,
                    isSelected: _notificationType == 'sms',
                    colorScheme: colorScheme,
                  ),
                ),
                Expanded(
                  child: _buildCollectSourceOption(
                    value: 'push',
                    icon: Icons.notifications_outlined,
                    label: l10n.paymentMethodWizardPushSource,
                    isSelected: _notificationType == 'push',
                    colorScheme: colorScheme,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Collection rule settings - 디자인 시스템 적용
          if (_generatedFormat != null)
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD), // #E3F2FD
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF90CAF9)), // #90CAF9
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Color(0xFF1976D2),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.paymentMethodWizardCurrentRules,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _showEditKeywordsDialog,
                        icon: const Icon(Icons.edit, size: 16),
                        tooltip: l10n.paymentMethodEditKeywords,
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                  const Divider(color: Color(0xFF90CAF9)),
                  // 감지 키워드 - Chip 형태로 표시
                  Text(
                    l10n.paymentMethodWizardDetectionKeywords,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _generatedFormat!.senderKeywords
                        .map(
                          (keyword) => Chip(
                            label: Text(
                              keyword,
                              style: const TextStyle(fontSize: 13),
                            ),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFF90CAF9)),
                            visualDensity: VisualDensity.compact,
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  // 금액 패턴
                  Text(
                    l10n.paymentMethodWizardAmountPattern,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF424242),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFriendlyAmountPattern(_generatedFormat!.amountRegex),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          // SMS에서 규칙 가져오기 버튼 (SMS 선택 시에만 표시)
          if (_notificationType == 'sms') ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showSmsImportDialog,
                icon: const Icon(Icons.sms_outlined, size: 18),
                label: Text(l10n.paymentMethodWizardImportFromSms),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: 16),

          // 4. Auto save mode selection (자동 / 제안)
          Text(
            l10n.autoSaveSettingsAutoProcessMode,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildAutoSaveModeSelector(l10n),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  /// Auto save mode selector UI (제안 / 자동)
  Widget _buildAutoSaveModeSelector(AppLocalizations l10n) {
    return Column(
      children: [
        _buildAutoSaveModeOption(
          mode: AutoSaveMode.suggest,
          icon: Icons.notifications_active_outlined,
          title: l10n.autoSaveSettingsSuggestModeTitle,
          description: l10n.autoSaveSettingsSuggestModeDesc,
        ),
        const SizedBox(height: 8),
        _buildAutoSaveModeOption(
          mode: AutoSaveMode.auto,
          icon: Icons.auto_awesome_outlined,
          title: l10n.autoSaveSettingsAutoModeTitle,
          description: l10n.autoSaveSettingsAutoModeDesc,
        ),
      ],
    );
  }

  /// 수집방식 옵션 위젯 (SMS/Push)
  Widget _buildCollectSourceOption({
    required String value,
    required IconData icon,
    required String label,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    return InkWell(
      onTap: () => _changeNotificationType(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            Icon(
              icon,
              size: 20,
              color: isSelected
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoSaveModeOption({
    required AutoSaveMode mode,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _autoSaveMode == mode;
    final isAutoMode = mode == AutoSaveMode.auto;

    // 선택 여부와 모드에 따른 색상 적용
    final Color backgroundColor;
    final Color iconBoxColor;
    final Color iconColor;
    final Color textColor;

    if (isSelected) {
      // 선택된 항목: 각 모드의 강조 색상
      if (isAutoMode) {
        // 자동 모드 선택: 녹색
        backgroundColor = const Color(0xFFC8E6C9); // 연한 녹색
        iconBoxColor = const Color(0xFF4CAF50); // 진한 녹색
        iconColor = Colors.white;
        textColor = const Color(0xFF1B5E20); // 진한 녹색 텍스트
      } else {
        // 제안 모드 선택: 파란색
        backgroundColor = const Color(0xFFE3F2FD); // 연한 파란색
        iconBoxColor = const Color(0xFF2196F3); // 파란색
        iconColor = Colors.white;
        textColor = const Color(0xFF0D47A1); // 진한 파란색 텍스트
      }
    } else {
      // 선택 안 된 항목: 회색
      backgroundColor = const Color(0xFFF5F5F5); // 연한 회색
      iconBoxColor = const Color(0xFFE0E0E0); // 회색
      iconColor = const Color(0xFF9E9E9E);
      textColor = const Color(0xFF757575); // 회색 텍스트
    }

    final checkColor = isAutoMode
        ? const Color(0xFF2E7D32) // Darker green
        : const Color(0xFF1976D2); // Blue

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _autoSaveMode = mode;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconBoxColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: textColor.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: checkColor, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getFriendlyAmountPattern(String regex) {
    // Provide user-friendly description for common patterns
    if (regex.contains('Won') && regex.contains('[0-9,]+')) {
      return 'Number before "Won"';
    }
    if (regex.contains(r'\d') || regex.contains('[0-9')) {
      return 'Auto-detected number pattern';
    }
    return regex;
  }

  Future<void> _showEditKeywordsDialog() async {
    if (_generatedFormat == null) return;

    // 현재 키워드 복사본 생성
    final currentKeywords = List<String>.from(_generatedFormat!.senderKeywords);
    _keywordsController.clear();

    if (!mounted) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        return _KeywordEditDialog(
          initialKeywords: currentKeywords,
          keywordsController: _keywordsController,
        );
      },
    );

    if (result != null && mounted) {
      // 메모리상 _generatedFormat 업데이트
      setState(() {
        _generatedFormat = _generatedFormat!.copyWith(senderKeywords: result);
      });

      // Edit 모드이고 DB에 저장된 포맷이 있으면 즉시 DB 업데이트
      if (isEdit && _generatedFormat!.id.isNotEmpty) {
        try {
          final formatRepository = ref.read(learnedSmsFormatRepositoryProvider);
          await formatRepository.updateFormat(
            id: _generatedFormat!.id,
            senderKeywords: result,
          );

          if (mounted) {
            final l10n = AppLocalizations.of(context);
            SnackBarUtils.showSuccess(
              context,
              l10n.paymentMethodWizardKeywordsSaved,
            );
          }
        } catch (e) {
          debugPrint('Failed to update keywords in DB: $e');
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            SnackBarUtils.showError(
              context,
              l10n.paymentMethodWizardKeywordsSaveFailed,
            );
          }
        }
      }
    }
  }

  Future<void> _showSmsImportDialog() async {
    final scanner = ref.read(smsScannerServiceProvider);
    final l10n = AppLocalizations.of(context);

    final hasPermission = await SmsListenerService.instance.checkPermissions();
    if (!hasPermission) {
      final granted = await SmsListenerService.instance.requestPermissions();
      if (!granted) {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            l10n.paymentMethodWizardSmsPermissionRequired,
          );
        }
        return;
      }
    }

    if (!mounted) return;

    unawaited(
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          final sheetL10n = AppLocalizations.of(sheetContext);
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.9,
            expand: false,
            builder: (sheetContext, scrollController) {
              return FutureBuilder<SmsFormatScanResult>(
                future: scanner.scanFinancialSms(),
                builder: (builderContext, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final messages = snapshot.data?.financialMessages ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Text(sheetL10n.paymentMethodWizardNoFinancialSms),
                    );
                  }

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          sheetL10n.paymentMethodWizardSelectSmsTitle,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: messages.length,
                          itemBuilder: (itemContext, index) {
                            final msg = messages[index];
                            return ListTile(
                              title: Text(msg.sender),
                              subtitle: Text(msg.body),
                              trailing: Text(
                                '${msg.date.month}/${msg.date.day}',
                              ),
                              onTap: () {
                                // SMS를 분석하여 키워드 업데이트
                                _updateKeywordsFromSms(msg.body);
                                Navigator.pop(sheetContext);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  /// SMS 본문을 분석하여 키워드를 업데이트
  void _updateKeywordsFromSms(String smsBody) {
    if (_selectedTemplate == null) return;

    // SMS 분석하여 새 포맷 생성
    final newFormat = SmsParsingService.generateFormatFromSample(
      sample: smsBody,
      paymentMethodId: widget.paymentMethod?.id ?? 'temp_id',
    );

    setState(() {
      // 기존 포맷이 있으면 키워드만 병합, 없으면 새로 설정
      if (_generatedFormat != null) {
        // 기존 키워드와 새 키워드 병합 (중복 제거)
        final mergedKeywords = <String>{
          ..._generatedFormat!.senderKeywords,
          ...newFormat.senderKeywords,
        }.toList();

        _generatedFormat = _generatedFormat!.copyWith(
          senderKeywords: mergedKeywords,
          sampleSms: smsBody,
        );
      } else {
        _generatedFormat = newFormat;
      }
    });

    // 성공 메시지 표시
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      SnackBarUtils.showSuccess(
        context,
        l10n.paymentMethodWizardKeywordsUpdated,
      );
    }
  }

  /// 개인 결제수단 → 공유 결제수단 변경 시 경고 다이얼로그
  Future<bool?> _showPermissionEscalationWarning() {
    final l10n = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentMethodPermissionWarningTitle),
        content: Text(l10n.paymentMethodPermissionWarningMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}

/// 키워드 수정을 위한 Chip 기반 다이얼로그
class _KeywordEditDialog extends StatefulWidget {
  final List<String> initialKeywords;
  final TextEditingController keywordsController;

  const _KeywordEditDialog({
    required this.initialKeywords,
    required this.keywordsController,
  });

  @override
  State<_KeywordEditDialog> createState() => _KeywordEditDialogState();
}

class _KeywordEditDialogState extends State<_KeywordEditDialog> {
  late List<String> _keywords;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _keywords = List<String>.from(widget.initialKeywords);
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _addKeyword() {
    final newKeyword = widget.keywordsController.text.trim();
    if (newKeyword.isEmpty) return;

    final l10n = AppLocalizations.of(context);

    // 중복 확인
    if (_keywords.contains(newKeyword)) {
      SnackBarUtils.showError(
        context,
        l10n.paymentMethodWizardKeywordDuplicate,
      );
      return;
    }

    setState(() {
      _keywords.add(newKeyword);
      widget.keywordsController.clear();
    });

    // 포커스 유지
    _focusNode.requestFocus();
  }

  void _removeKeyword(String keyword) {
    setState(() {
      _keywords.remove(keyword);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(l10n.paymentMethodWizardEditKeywordsTitle),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.paymentMethodWizardEditKeywordsDescription,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // 등록된 키워드 Chip 리스트
            if (_keywords.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _keywords
                    .map(
                      (keyword) => InputChip(
                        label: Text(keyword),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () => _removeKeyword(keyword),
                        backgroundColor: colorScheme.surfaceContainerHighest,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 키워드 입력 필드
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.keywordsController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: l10n.paymentMethodWizardKeywordInputHint,
                      border: const OutlineInputBorder(),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addKeyword(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _addKeyword,
                  child: Text(l10n.paymentMethodWizardKeywordAdd),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () {
            if (_keywords.isEmpty) {
              SnackBarUtils.showError(
                context,
                l10n.paymentMethodWizardEditKeywordsMinError,
              );
              return;
            }
            Navigator.pop(context, _keywords);
          },
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
