import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../providers/category_keyword_mapping_provider.dart';
import '../widgets/add_category_mapping_dialog.dart';

class CategoryKeywordMappingPage extends ConsumerWidget {
  final String paymentMethodId;
  final String sourceType;
  final String ledgerId;

  const CategoryKeywordMappingPage({
    super.key,
    required this.paymentMethodId,
    required this.sourceType,
    required this.ledgerId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final title = sourceType == 'sms'
        ? l10n.categoryMappingSmsTtile
        : l10n.categoryMappingPushTitle;

    final description = sourceType == 'sms'
        ? l10n.categoryMappingSmsDescription
        : l10n.categoryMappingPushDescription;

    final mappingsAsync = ref.watch(
      categoryKeywordMappingNotifierProvider(paymentMethodId),
    );

    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.md,
                Spacing.sm,
              ),
              child: Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: mappingsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text(l10n.errorWithMessage(error.toString())),
                ),
                data: (mappings) {
                  final filtered = mappings
                      .where((m) => m.sourceType == sourceType)
                      .toList();

                  if (filtered.isEmpty) {
                    return EmptyState(
                      icon: Icons.label_outline,
                      message: l10n.categoryMappingEmpty,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: Spacing.sm),
                    itemBuilder: (context, index) {
                      final mapping = filtered[index];

                      return categoriesAsync.when(
                        loading: () => const SizedBox(
                          height: 56,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                        error: (error, stack) => const SizedBox.shrink(),
                        data: (categories) {
                          final category = categories
                              .where((c) => c.id == mapping.categoryId)
                              .firstOrNull;

                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                                width: 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Spacing.md,
                                vertical: 14,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mapping.keyword,
                                          style:
                                              textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              '\u2192  ',
                                              style: textTheme.bodySmall
                                                  ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Flexible(
                                              child: Text(
                                                category?.name ??
                                                    l10n
                                                        .categoryMappingUnknown,
                                                style: textTheme.bodySmall
                                                    ?.copyWith(
                                                  color: colorScheme.primary,
                                                  fontSize: 12,
                                                  decoration:
                                                      TextDecoration.underline,
                                                  decorationColor:
                                                      colorScheme.primary,
                                                ),
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                        Icons.delete_outline_rounded),
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.7),
                                    iconSize: 20,
                                    onPressed: () => _deleteMapping(
                                      context,
                                      ref,
                                      l10n,
                                      mapping.id,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context, WidgetRef ref) async {
    final savedSourceType = await showDialog<String>(
      context: context,
      builder: (context) => AddCategoryMappingDialog(
        paymentMethodId: paymentMethodId,
        ledgerId: ledgerId,
        initialSourceType: sourceType,
      ),
    );

    if (savedSourceType == null) return;

    await ref
        .read(categoryKeywordMappingNotifierProvider(paymentMethodId).notifier)
        .loadMappings();

    // 저장한 sourceType이 현재 페이지와 다르면 해당 페이지로 이동
    if (savedSourceType != sourceType && context.mounted) {
      context.pushReplacement(
        '/settings/payment-methods/$paymentMethodId/category-mapping/$savedSourceType',
        extra: {'ledgerId': ledgerId},
      );
    }
  }

  Future<void> _deleteMapping(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    String mappingId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.categoryMappingDeleteTitle),
        content: Text(l10n.categoryMappingDeleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(
            categoryKeywordMappingNotifierProvider(paymentMethodId).notifier,
          )
          .delete(mappingId);

      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.categoryMappingDeleted);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(
          context,
          l10n.errorWithMessage(e.toString()),
        );
      }
    }
  }
}
