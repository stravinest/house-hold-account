import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/transaction.dart';
import '../providers/recurring_template_provider.dart';
import '../widgets/edit_transaction_sheet.dart';

// 템플릿 Map에서 안전하게 값을 추출하는 헬퍼
class _TemplateData {
  final String id;
  final String type;
  final int amount;
  final String? title;
  final String? memo;
  final bool isActive;
  final bool isFixedExpense;
  final String recurringType;
  final String? startDate;
  final String? endDate;
  final String? categoryId;
  final String? categoryName;
  final String? fixedExpenseCategoryId;
  final String? fixedExpenseCategoryName;
  final String? paymentMethodId;

  _TemplateData._({
    required this.id,
    required this.type,
    required this.amount,
    this.title,
    this.memo,
    required this.isActive,
    required this.isFixedExpense,
    required this.recurringType,
    this.startDate,
    this.endDate,
    this.categoryId,
    this.categoryName,
    this.fixedExpenseCategoryId,
    this.fixedExpenseCategoryName,
    this.paymentMethodId,
  });

  factory _TemplateData.fromMap(Map<String, dynamic> map) {
    final category = map['categories'] as Map<String, dynamic>?;
    final fixedCategory =
        map['fixed_expense_categories'] as Map<String, dynamic>?;
    return _TemplateData._(
      id: map['id'] as String,
      type: map['type'] as String? ?? 'expense',
      amount: map['amount'] as int? ?? 0,
      title: map['title'] as String?,
      memo: map['memo'] as String?,
      isActive: map['is_active'] as bool? ?? false,
      isFixedExpense: map['is_fixed_expense'] as bool? ?? false,
      recurringType: map['recurring_type'] as String? ?? 'monthly',
      startDate: map['start_date']?.toString(),
      endDate: map['end_date']?.toString(),
      categoryId: map['category_id'] as String?,
      categoryName: category?['name'] as String?,
      fixedExpenseCategoryId:
          map['fixed_expense_category_id'] as String?,
      fixedExpenseCategoryName: fixedCategory?['name'] as String?,
      paymentMethodId: map['payment_method_id'] as String?,
    );
  }

  IconData get typeIcon {
    switch (type) {
      case 'income':
        return Icons.arrow_upward;
      case 'asset':
        return Icons.account_balance;
      default:
        return Icons.arrow_downward;
    }
  }

  Color typeColor(ColorScheme colorScheme) {
    switch (type) {
      case 'income':
        return colorScheme.primary;
      case 'asset':
        return colorScheme.tertiary;
      default:
        return colorScheme.error;
    }
  }

  // 자동저장 날짜 정보 (매월 N일, 매년 M월 N일)
  String recurringScheduleText(AppLocalizations l10n) {
    final date = DateTime.tryParse(startDate ?? '');
    if (date == null) {
      switch (recurringType) {
        case 'daily':
          return l10n.recurringTypeDaily;
        case 'monthly':
          return l10n.recurringTypeMonthly;
        case 'yearly':
          return l10n.recurringTypeYearly;
        default:
          return recurringType;
      }
    }

    switch (recurringType) {
      case 'daily':
        return l10n.recurringTypeDaily;
      case 'monthly':
        return '${l10n.recurringTypeMonthly} ${date.day}${l10n.recurringDaySuffix}';
      case 'yearly':
        return '${l10n.recurringTypeYearly} ${date.month}${l10n.recurringMonthSuffix} ${date.day}${l10n.recurringDaySuffix}';
      default:
        return recurringType;
    }
  }

  // 카테고리 표시명 (고정비면 고정비 카테고리, 아니면 일반 카테고리)
  String? get displayCategoryName {
    if (isFixedExpense && fixedExpenseCategoryName != null) {
      return fixedExpenseCategoryName;
    }
    return categoryName;
  }

  String displayTitle(AppLocalizations l10n) {
    if (title != null && title!.isNotEmpty) return title!;
    return displayCategoryName ?? l10n.recurringTemplateManagement;
  }

  // EditTransactionSheet에 전달할 Transaction 객체 생성
  // ledgerId, userId는 템플릿 수정 모드에서 사용하지 않으므로 빈 값
  Transaction toFakeTransaction() {
    final now = DateTime.now();
    return Transaction(
      id: id,
      ledgerId: '',
      userId: '',
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      date: DateTime.tryParse(startDate ?? '') ?? now,
      title: title,
      memo: memo,
      isRecurring: true,
      recurringType: recurringType,
      recurringEndDate: endDate != null ? DateTime.tryParse(endDate!) : null,
      isFixedExpense: isFixedExpense,
      fixedExpenseCategoryId: fixedExpenseCategoryId,
      createdAt: now,
      updatedAt: now,
    );
  }
}

class RecurringTemplateManagementPage extends ConsumerWidget {
  const RecurringTemplateManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final templatesAsync = ref.watch(recurringTemplatesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recurringTemplateManagement),
        scrolledUnderElevation: 0,
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: templatesAsync.when(
          data: (templates) {
            if (templates.isEmpty) {
              return EmptyState(
                icon: Icons.repeat_outlined,
                message: l10n.recurringTemplateEmpty,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              itemCount: templates.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: Spacing.sm),
              itemBuilder: (context, index) {
                final data = _TemplateData.fromMap(templates[index]);
                return _TemplateCard(data: data);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }
}

class _TemplateCard extends ConsumerWidget {
  final _TemplateData data;

  const _TemplateCard({required this.data});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final formatter = NumberFormat('#,###');
    final color = data.typeColor(colorScheme);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        side: BorderSide(
          color: data.isActive
              ? colorScheme.outlineVariant
              : colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      color: data.isActive
          ? colorScheme.surface
          : colorScheme.surfaceContainerHighest.withAlpha(60),
      child: InkWell(
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        onTap: () => _handleMenuAction(context, ref, 'edit', l10n),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 타입 아이콘
              CircleAvatar(
                radius: 20,
                backgroundColor: color.withAlpha(25),
                child: Icon(data.typeIcon, color: color, size: 20),
              ),
              const SizedBox(width: Spacing.md),

              // 메인 콘텐츠
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 첫째 줄: 제목
                    Text(
                      data.displayTitle(l10n),
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: data.isActive
                            ? null
                            : colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),

                    // 둘째 줄: 금액 + 반복주기
                    Text(
                      '${formatter.format(data.amount)}${l10n.transactionAmountUnit}  ·  ${data.recurringScheduleText(l10n)}',
                      style: textTheme.bodyMedium?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),

                    // 셋째 줄: 카테고리
                    if (data.displayCategoryName != null)
                      Row(
                        children: [
                          Icon(
                            data.isFixedExpense
                                ? Icons.push_pin
                                : Icons.category_outlined,
                            size: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              data.displayCategoryName!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: Spacing.sm),

                    // 넷째 줄: 상태 뱃지
                    _StatusBadge(isActive: data.isActive, l10n: l10n),
                  ],
                ),
              ),
              const SizedBox(width: Spacing.xs),

              // 더보기 메뉴
              PopupMenuButton<String>(
                onSelected: (value) =>
                    _handleMenuAction(context, ref, value, l10n),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 20,
                icon: Icon(
                  Icons.more_vert,
                  color: colorScheme.onSurfaceVariant,
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 20),
                        const SizedBox(width: Spacing.sm),
                        Text(l10n.recurringTemplateEdit),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle',
                    child: Row(
                      children: [
                        Icon(
                          data.isActive ? Icons.pause : Icons.play_arrow,
                          size: 20,
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(data.isActive
                            ? l10n.recurringTemplatePause
                            : l10n.recurringTemplateResume),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: colorScheme.error),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          l10n.recurringTemplateDelete,
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    AppLocalizations l10n,
  ) async {
    final notifier = ref.read(recurringTemplateNotifierProvider.notifier);

    try {
      switch (action) {
        case 'edit':
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => EditTransactionSheet(
              transaction: data.toFakeTransaction(),
              recurringTemplateId: data.id,
            ),
          );
          if (result == true && context.mounted) {
            SnackBarUtils.showSuccess(context, l10n.recurringTemplateUpdated);
          }
          break;
        case 'toggle':
          await notifier.toggle(data.id, !data.isActive);
          if (context.mounted) {
            SnackBarUtils.showSuccess(
              context,
              data.isActive
                  ? l10n.recurringTemplatePausedMessage
                  : l10n.recurringTemplateResumed,
            );
          }
          break;
        case 'delete':
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: Text(l10n.recurringTemplateDeleteConfirm),
              content: Text(l10n.recurringTemplateDeleteDescription),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(l10n.commonCancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                  ),
                  child: Text(l10n.commonDelete),
                ),
              ],
            ),
          );
          if (confirmed == true) {
            await notifier.delete(data.id);
            if (context.mounted) {
              SnackBarUtils.showSuccess(
                context,
                l10n.recurringTemplateDeleted,
              );
            }
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isActive;
  final AppLocalizations l10n;

  const _StatusBadge({required this.isActive, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = isActive
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final fgColor =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.autorenew : Icons.pause_circle_outline,
            size: 12,
            color: fgColor,
          ),
          const SizedBox(width: 3),
          Text(
            isActive
                ? l10n.recurringTemplateActive
                : l10n.recurringTemplatePaused,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fgColor,
            ),
          ),
        ],
      ),
    );
  }
}
