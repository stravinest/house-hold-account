import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/snackbar_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../share/presentation/providers/share_provider.dart';
import '../../providers/statistics_provider.dart';
import '../common/expense_type_filter.dart';
import '../common/member_tabs.dart';
import 'payment_method_donut_chart.dart';
import 'payment_method_list.dart';

class PaymentMethodTabView extends ConsumerWidget {
  const PaymentMethodTabView({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    ref.invalidate(paymentMethodStatisticsProvider);
    ref.invalidate(paymentMethodStatisticsByUserProvider);
    await ref.read(paymentMethodStatisticsProvider.future);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final expenseTypeFilter =
        ref.watch(selectedPaymentMethodExpenseTypeFilterProvider);
    final isShared = ref.watch(isSharedLedgerProvider);

    return RefreshIndicator(
      onRefresh: () => _onRefresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 필터 섹션: 지출 라벨(탭 시 토스트) + 구분선 + 전체/고정비/변동비
            Row(
              children: [
                // 지출 고정 라벨 (탭하면 안내 토스트 표시)
                GestureDetector(
                  onTap: () {
                    SnackBarUtils.showInfo(
                      context,
                      l10n.statisticsPaymentNotice,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.statisticsTypeExpense,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 1,
                  height: 20,
                  child:
                      ColoredBox(color: theme.colorScheme.outlineVariant),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: ExpenseTypeFilterWidget(
                    selectedFilter: expenseTypeFilter,
                    onChanged: (filter) {
                      ref
                          .read(
                              selectedPaymentMethodExpenseTypeFilterProvider
                                  .notifier)
                          .state = filter;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 도넛 차트 카드
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.statisticsPaymentDistribution,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const PaymentMethodDonutChart(),
                  // 유저별 탭 (공유 가계부일 때만, 도넛 차트 아래)
                  if (isShared) ...[
                    const SizedBox(height: 16),
                    const _PaymentMethodMemberTabs(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 결제수단 리스트
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      l10n.statisticsPaymentRanking,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  const PaymentMethodList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 유저별 탭 - 공통 MemberTabs 위젯 사용
class _PaymentMethodMemberTabs extends ConsumerWidget {
  const _PaymentMethodMemberTabs();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final sharedState =
        ref.watch(paymentMethodSharedStatisticsStateProvider);

    return membersAsync.when(
      data: (members) {
        if (members.length < 2) return const SizedBox.shrink();

        return MemberTabs(
          members: members,
          sharedState: sharedState,
          onStateChanged: (newState) {
            ref
                .read(paymentMethodSharedStatisticsStateProvider.notifier)
                .state = newState;
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
