import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../category/domain/entities/category.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../providers/category_keyword_mapping_provider.dart';

class AddCategoryMappingDialog extends ConsumerStatefulWidget {
  final String paymentMethodId;
  final String ledgerId;
  final String initialSourceType;

  const AddCategoryMappingDialog({
    super.key,
    required this.paymentMethodId,
    required this.ledgerId,
    required this.initialSourceType,
  });

  @override
  ConsumerState<AddCategoryMappingDialog> createState() =>
      _AddCategoryMappingDialogState();
}

class _AddCategoryMappingDialogState
    extends ConsumerState<AddCategoryMappingDialog> {
  late String _selectedSourceType;
  final _keywordController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _selectedSourceType = widget.initialSourceType;
  }

  @override
  void dispose() {
    _keywordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final expenseCategoriesAsync = ref.watch(expenseCategoriesProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
              // 헤더
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.categoryMappingAddTitle,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: Spacing.sm),

              // 수집 유형 (페이지에서 고정된 경우 표시만, 아닌 경우 선택 가능)
              Text(
                l10n.categoryMappingSourceType,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment<String>(
                      value: 'sms',
                      label: Text(l10n.autoSaveSettingsSourceSms),
                      icon: const Icon(Icons.sms_outlined),
                    ),
                    ButtonSegment<String>(
                      value: 'push',
                      label: Text(l10n.autoSaveSettingsSourcePush),
                      icon: const Icon(Icons.notifications_outlined),
                    ),
                  ],
                  selected: {_selectedSourceType},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedSourceType = selection.first;
                    });
                  },
                ),
              ),
              const SizedBox(height: Spacing.md),

              // 키워드 입력
              Text(
                l10n.categoryMappingKeyword,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              TextFormField(
                controller: _keywordController,
                decoration: InputDecoration(
                  hintText: l10n.categoryMappingKeywordHint,
                  border: const OutlineInputBorder(),
                  helperText: l10n.categoryMappingKeywordHelper,
                  helperMaxLines: 2,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.categoryMappingKeywordRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: Spacing.md),

              // 연결할 카테고리
              Text(
                l10n.categoryMappingCategory,
                style: textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.xs),
              expenseCategoriesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (error, _) => Text(
                  l10n.errorWithMessage(error.toString()),
                  style: TextStyle(color: colorScheme.error),
                ),
                data: (categories) => _buildCategoryDropdown(
                  context,
                  l10n,
                  categories,
                ),
              ),

              const SizedBox(height: Spacing.sm),
              const Divider(),
              const SizedBox(height: Spacing.sm),

              // 버튼 (KiPWh 디자인: 둥근 모서리, 취소=아웃라인, 저장=진한 초록)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: colorScheme.outlineVariant,
                        ),
                      ),
                      child: Text(
                        l10n.commonCancel,
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isLoading ? null : _save,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.onPrimary,
                              ),
                            )
                          : Text(
                              l10n.commonSave,
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryDropdown(
    BuildContext context,
    AppLocalizations l10n,
    List<Category> categories,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        hintText: l10n.categoryMappingCategoryHint,
        border: const OutlineInputBorder(),
      ),
      items: categories.map((category) {
        return DropdownMenuItem<String>(
          value: category.id,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryIcon(
                icon: category.icon,
                name: category.name,
                color: category.color,
                size: CategoryIconSize.small,
              ),
              const SizedBox(width: 10),
              Text(
                category.name,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCategoryId = value;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return l10n.categoryMappingCategoryRequired;
        }
        return null;
      },
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    assert(
      _selectedSourceType == 'sms' || _selectedSourceType == 'push',
      'Invalid sourceType: $_selectedSourceType',
    );

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(
            categoryKeywordMappingNotifierProvider(
              widget.paymentMethodId,
            ).notifier,
          )
          .create(
            ledgerId: widget.ledgerId,
            keyword: _keywordController.text.trim().toLowerCase(),
            categoryId: _selectedCategoryId!,
            sourceType: _selectedSourceType,
            createdBy: currentUser.id,
          );

      if (mounted) {
        final savedSourceType = _selectedSourceType;
        final messenger = ScaffoldMessenger.of(context);
        final successMsg = AppLocalizations.of(context).categoryMappingAdded;
        Navigator.pop(context, savedSourceType);
        messenger.showSnackBar(
          SnackBar(content: Text(successMsg)),
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          AppLocalizations.of(context).errorWithMessage(e.toString()),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
