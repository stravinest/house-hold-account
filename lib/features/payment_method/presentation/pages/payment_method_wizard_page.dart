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

  // Notification type selection (sms | push)
  String _notificationType = 'sms';

  // Auto save mode selection (suggest | auto)
  AutoSaveMode _autoSaveMode = AutoSaveMode.suggest;

  // Analyzed format
  LearnedSmsFormat? _generatedFormat;

  // Debounce timer for sample analysis
  Timer? _debounceTimer;

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

    // Run initial analysis
    if (_sampleController.text.isNotEmpty) {
      _analyzeSampleImmediate();
    }
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
    if (_selectedTemplate == null) return;

    setState(() {
      _notificationType = type;
      if (type == 'sms') {
        _sampleController.text = _selectedTemplate!.defaultSampleSms;
      } else {
        _sampleController.text =
            _selectedTemplate!.defaultSamplePush ??
            _selectedTemplate!.defaultSampleSms;
      }
      _analyzeSampleImmediate();
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

        // 2. Update autoSaveMode (only for auto-collect mode)
        if (canAutoSave) {
          await notifier.updateAutoSaveSettings(
            id: widget.paymentMethod!.id,
            autoSaveMode: _autoSaveMode,
          );
        }

        // 3. Save or update learned format (only when template selected in auto-collect mode)
        // Delete all existing formats and create new one to ensure consistency
        if (canAutoSave && _selectedTemplate != null && _generatedFormat != null) {
          final existingFormats = await formatRepository.getFormatsByPaymentMethod(
            widget.paymentMethod!.id,
          );

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

        // 2. Update autoSaveMode (only for auto-collect mode)
        if (canAutoSave) {
          await notifier.updateAutoSaveSettings(
            id: paymentMethod.id,
            autoSaveMode: _autoSaveMode,
          );
        }

        // 3. Save learned format (only when template selected in auto-collect mode)
        if (canAutoSave && _selectedTemplate != null && _generatedFormat != null) {
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

      // For auto-collect payment method, also refresh the user's provider
      if (canAutoSave) {
        final currentUserId = ref.read(currentUserProvider)?.id;
        if (currentUserId != null) {
          ref.invalidate(autoCollectPaymentMethodsByOwnerProvider(currentUserId));
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e, st) {
      debugPrint('PaymentMethod save failed: $e\n$st');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        if (e is DuplicateItemException) {
          SnackBarUtils.showError(context, l10n.paymentMethodWizardDuplicateName);
        } else {
          SnackBarUtils.showError(context, l10n.paymentMethodWizardSaveFailed);
        }
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
          onPressed: _goBack,
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: showBottomButton
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(isEdit ? l10n.paymentMethodWizardSaveButton : l10n.paymentMethodWizardAddButton),
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
            children: localCurrencies.map((t) => _buildTemplateChip(t)).toList(),
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
        (_selectedMode == PaymentMethodAddMode.autoCollect && _selectedTemplate == null)) {
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
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue[700],
                      ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal use notice badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 18, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.paymentMethodWizardPersonalNotice,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.orange[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 1. Name setting
          TextFormField(
            controller: _nameController,
            maxLength: 20,
            decoration: InputDecoration(
              labelText: l10n.paymentMethodWizardAliasLabel,
              helperText: l10n.paymentMethodWizardAliasHelper,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 24),

          // 2. Sample editor (collection settings)
          Text(
            l10n.paymentMethodWizardAutoCollectRuleTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                Expanded(
                  child: Visibility(
                    visible: _notificationType == 'sms',
                    maintainSize: true,
                    maintainAnimation: true,
                    maintainState: true,
                    child: TextButton.icon(
                      onPressed: _showSmsImportDialog,
                      icon: const Icon(Icons.sms_outlined),
                      label: Text(l10n.paymentMethodWizardImportFromSms),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerLeft,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
                // SMS / Push toggle
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'sms', label: Text('SMS')),
                    ButtonSegment(value: 'push', label: Text('Push')),
                  ],
                  selected: {_notificationType},
                  onSelectionChanged: (Set<String> newSelection) {
                    _changeNotificationType(newSelection.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.paymentMethodWizardSampleNotice,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _sampleController,
            readOnly: true,
            maxLines: 5,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
          ),

          const SizedBox(height: 24),

          // 3. Analysis result preview (rules)
          if (_generatedFormat != null)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 20, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.paymentMethodWizardCurrentRules,
                            style: const TextStyle(fontWeight: FontWeight.bold),
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
                    const Divider(),
                    _buildRuleRow(
                      l10n.paymentMethodWizardDetectionKeywordsOr,
                      _generatedFormat!.senderKeywords.join(', '),
                    ),
                    _buildRuleRow(
                      l10n.paymentMethodWizardAmountPatternRequired,
                      _getFriendlyAmountPattern(_generatedFormat!.amountRegex),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.paymentMethodWizardAmountPatternNote,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // 4. Auto save mode selection (자동 / 제안)
          Text(
            l10n.autoSaveSettingsAutoProcessMode,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        _buildAutoSaveModeOption(
          mode: AutoSaveMode.suggest,
          icon: Icons.notifications_active_outlined,
          title: l10n.autoSaveSettingsSuggestModeTitle,
          description: l10n.autoSaveSettingsSuggestModeDesc,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 8),
        _buildAutoSaveModeOption(
          mode: AutoSaveMode.auto,
          icon: Icons.auto_awesome_outlined,
          title: l10n.autoSaveSettingsAutoModeTitle,
          description: l10n.autoSaveSettingsAutoModeDesc,
          colorScheme: colorScheme,
        ),
      ],
    );
  }

  Widget _buildAutoSaveModeOption({
    required AutoSaveMode mode,
    required IconData icon,
    required String title,
    required String description,
    required ColorScheme colorScheme,
  }) {
    final isSelected = _autoSaveMode == mode;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isSelected ? colorScheme.primaryContainer : null,
      child: InkWell(
        onTap: () {
          setState(() {
            _autoSaveMode = mode;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : null,
                      ),
                    ),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: isSelected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: const TextStyle(color: Colors.grey)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
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

    _keywordsController.text = _generatedFormat!.senderKeywords.join(', ');

    if (!mounted) return;

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) {
        final dialogL10n = AppLocalizations.of(dialogContext);
        return AlertDialog(
          title: Text(dialogL10n.paymentMethodWizardEditKeywordsTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogL10n.paymentMethodWizardEditKeywordsDescription,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _keywordsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: dialogL10n.paymentMethodWizardEditKeywordsHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  helperText: dialogL10n.paymentMethodWizardEditKeywordsHelper,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: Text(dialogL10n.commonCancel),
            ),
            ElevatedButton(
              onPressed: () {
                final keywords = _keywordsController.text
                    .split(',')
                    .map((k) => k.trim())
                    .where((k) => k.isNotEmpty)
                    .toList();

                if (keywords.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(dialogL10n.paymentMethodWizardEditKeywordsMinError)),
                  );
                  return;
                }

                Navigator.pop(dialogContext, keywords);
              },
              child: Text(dialogL10n.commonSave),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        _generatedFormat = _generatedFormat!.copyWith(
          senderKeywords: result,
        );
      });
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.paymentMethodWizardSmsPermissionRequired)));
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
                    return Center(child: Text(sheetL10n.paymentMethodWizardNoFinancialSms));
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
                              trailing: Text('${msg.date.month}/${msg.date.day}'),
                              onTap: () {
                                _sampleController.text = msg.body;
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
