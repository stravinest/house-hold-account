import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../data/services/keyword_extractor.dart';
import '../providers/category_keyword_mapping_provider.dart';

/// 거래 상세에서 카테고리 키워드 매핑을 추가하는 다이얼로그
class AddCategoryMappingFromTransactionDialog extends ConsumerStatefulWidget {
  final String paymentMethodId;
  final String ledgerId;
  final String? transactionTitle;
  final double? transactionAmount;
  final String initialSourceType;

  const AddCategoryMappingFromTransactionDialog({
    super.key,
    required this.paymentMethodId,
    required this.ledgerId,
    this.transactionTitle,
    this.transactionAmount,
    this.initialSourceType = 'notification',
  });

  @override
  ConsumerState<AddCategoryMappingFromTransactionDialog> createState() =>
      _AddCategoryMappingFromTransactionDialogState();
}

class _AddCategoryMappingFromTransactionDialogState
    extends ConsumerState<AddCategoryMappingFromTransactionDialog> {
  late String _selectedSourceType;
  final _keywordController = TextEditingController();
  String? _selectedCategoryId;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  late final List<String> _suggestedKeywords;

  @override
  void initState() {
    super.initState();
    _selectedSourceType = widget.initialSourceType;
    _suggestedKeywords = KeywordExtractor.extract(widget.transactionTitle);
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
    final formatter = NumberFormat('#,###');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
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
                        l10n.categoryMappingFromTransaction,
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

                  // 거래 컨텍스트 표시
                  if (widget.transactionTitle != null ||
                      widget.transactionAmount != null)
                    Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius:
                            BorderRadius.circular(BorderRadiusToken.md),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (widget.transactionTitle != null)
                            Text(
                              widget.transactionTitle!,
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          if (widget.transactionAmount != null)
                            Text(
                              '${formatter.format(widget.transactionAmount)}${l10n.transactionAmountUnit}',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),

                  const Divider(),
                  const SizedBox(height: Spacing.sm),

                  // 추천 키워드 영역
                  if (_suggestedKeywords.isNotEmpty) ...[
                    Text(
                      l10n.categoryMappingSuggestedKeywords,
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Wrap(
                      spacing: Spacing.xs,
                      runSpacing: Spacing.xs,
                      children: _suggestedKeywords.map((keyword) {
                        final isSelected =
                            _keywordController.text.trim().toLowerCase() ==
                                keyword.toLowerCase();
                        return FilterChip(
                          label: Text(keyword),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _keywordController.text =
                                  selected ? keyword : '';
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],

                  // 키워드 직접 입력
                  Text(
                    l10n.categoryMappingDirectInput,
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
                    onChanged: (_) => setState(() {}),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.categoryMappingKeywordRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: Spacing.md),

                  // 수집 유형
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
                          value: 'notification',
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

                  // 카테고리 선택
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

                  // 버튼
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
        final messenger = ScaffoldMessenger.of(context);
        final successMsg = AppLocalizations.of(context).categoryMappingAdded;
        Navigator.pop(context, true);
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
