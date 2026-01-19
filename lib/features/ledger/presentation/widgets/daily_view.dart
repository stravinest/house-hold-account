import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/color_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/spinning_refresh_button.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
import '../providers/ledger_provider.dart';
import 'calendar_month_summary.dart';

/// 일별 뷰 위젯
///
/// 선택된 날짜의 거래 내역을 리스트로 표시합니다.
class DailyView extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final Future<void> Function() onRefresh;

  const DailyView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 멤버 수 계산
    final currentLedgerAsync = ref.watch(currentLedgerProvider);
    final currentLedger = currentLedgerAsync.valueOrNull;
    final memberCount = currentLedger?.isShared == true ? 2 : 1;

    return Column(
      children: [
        // 고정 헤더: 수입 | 지출 | 합계 (일별)
        _DailySummaryHeader(date: selectedDate, memberCount: memberCount),
        // 날짜 네비게이션 헤더
        _DailyNavigationHeader(
          date: selectedDate,
          onDateChanged: onDateChanged,
          onTodayPressed: () => onDateChanged(DateTime.now()),
          onRefresh: onRefresh,
        ),
        // 거래 내역 리스트
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: _DailyTransactionList(date: selectedDate),
          ),
        ),
      ],
    );
  }
}

/// 일별 요약 상수
class _DailySummaryConstants {
  // 사용자별 금액 표시 행 높이
  static const double userIndicatorRowHeight = 14.0;
}

/// 일별 요약 헤더 (수입/지출/합계)
class _DailySummaryHeader extends ConsumerWidget {
  final DateTime date;
  final int memberCount;

  const _DailySummaryHeader({required this.date, required this.memberCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dailyTotalAsync = ref.watch(dailyTotalProvider);

    // 이전 데이터 유지하면서 새 데이터 로딩 (레이아웃 점프 방지)
    final totals = dailyTotalAsync.valueOrNull ?? {};
    final income = totals['income'] as int? ?? 0;
    final expense = totals['expense'] as int? ?? 0;
    final balance = income - expense;
    // 안전한 타입 변환
    final rawUsers = totals['users'];
    final users = rawUsers != null
        ? Map<String, dynamic>.from(rawUsers as Map)
        : <String, dynamic>{};

    // 공유 가계부일 때 모든 멤버 데이터 보강 (거래 없는 멤버도 표시)
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final members = membersAsync.valueOrNull ?? [];
    final enrichedUsers = Map<String, dynamic>.from(users);

    if (memberCount >= 2) {
      for (final member in members) {
        if (!enrichedUsers.containsKey(member.userId)) {
          enrichedUsers[member.userId] = {
            'displayName': member.displayName ?? l10n.user,
            'income': 0,
            'expense': 0,
            'asset': 0,
            'color': member.color ?? '#A8D8EA',
          };
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SummaryColumn(
                label: l10n.transactionIncome,
                totalAmount: income,
                color: colorScheme.primary,
                users: enrichedUsers,
                type: SummaryType.income,
                memberCount: memberCount,
              ),
            ),
            Container(width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryColumn(
                label: l10n.transactionExpense,
                totalAmount: expense,
                color: colorScheme.error,
                users: enrichedUsers,
                type: SummaryType.expense,
                memberCount: memberCount,
              ),
            ),
            Container(width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryColumn(
                label: l10n.summaryBalance,
                totalAmount: balance,
                color: colorScheme.onSurface,
                users: enrichedUsers,
                type: SummaryType.balance,
                memberCount: memberCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 일별 수입/지출 열 위젯
class _SummaryColumn extends StatelessWidget {
  final String label;
  final int totalAmount;
  final Color color;
  final Map<String, dynamic> users;
  final SummaryType type;
  final int memberCount;

  const _SummaryColumn({
    required this.label,
    required this.totalAmount,
    required this.color,
    required this.users,
    required this.type,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    final colorScheme = Theme.of(context).colorScheme;

    // 유저별 금액 계산
    final userAmounts = <MapEntry<Color, int>>[];
    for (final entry in users.entries) {
      final userData = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};
      final income = userData['income'] as int? ?? 0;
      final expense = userData['expense'] as int? ?? 0;

      int amount;
      switch (type) {
        case SummaryType.income:
          amount = income;
          break;
        case SummaryType.expense:
          amount = expense;
          break;
        case SummaryType.balance:
          amount = income - expense;
          break;
      }

      // 공유 가계부(2명)일 때는 0이어도 항상 표시
      final shouldShow = memberCount >= 2
          ? true
          : (type == SummaryType.balance ? amount != 0 : amount > 0);
      if (shouldShow) {
        final colorHex = userData['color'] as String? ?? '#A8D8EA';
        userAmounts.add(MapEntry(ColorUtils.parseHexColor(colorHex), amount));
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 라벨
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        // 총액
        Text(
          '${totalAmount < 0 ? '-' : ''}${formatter.format(totalAmount.abs())}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        // 유저별 표시 (세로 배치)
        if (memberCount >= 2) ...[
          const SizedBox(height: 2),
          SizedBox(
            height: 2 * _DailySummaryConstants.userIndicatorRowHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.start,
              children: userAmounts.isEmpty
                  ? []
                  : userAmounts
                        .map(
                          (entry) => Padding(
                            padding: const EdgeInsets.only(bottom: 1),
                            child: _UserAmountIndicator(
                              color: entry.key,
                              amount: entry.value,
                            ),
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ],
    );
  }
}

/// 유저별 금액 인디케이터
class _UserAmountIndicator extends StatelessWidget {
  final Color color;
  final int amount;

  const _UserAmountIndicator({required this.color, required this.amount});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');
    final isNegative = amount < 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2),
        Text(
          '${isNegative ? '-' : ''}${formatter.format(amount.abs())}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// 일별 네비게이션 헤더
class _DailyNavigationHeader extends StatelessWidget {
  final DateTime date;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onTodayPressed;
  final Future<void> Function() onRefresh;

  const _DailyNavigationHeader({
    required this.date,
    required this.onDateChanged,
    required this.onTodayPressed,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          // 오늘 버튼
          TextButton.icon(
            onPressed: isToday ? null : onTodayPressed,
            icon: const Icon(Icons.today, size: IconSize.sm),
            label: Text(l10n.calendarToday),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(
                left: Spacing.sm,
                top: Spacing.xs,
                bottom: Spacing.xs,
                right: 0,
              ),
            ),
          ),
          // 새로고침 버튼 (스피닝 효과)
          SpinningRefreshButton(
            onRefresh: onRefresh,
            tooltip: l10n.tooltipRefresh,
          ),
          const Spacer(),
          // 이전 날짜 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () =>
                onDateChanged(date.subtract(const Duration(days: 1))),
          ),
          // 날짜 표시
          Text(
            l10n.calendarDailyDate(date.year, date.month, date.day),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          // 다음 날짜 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onDateChanged(date.add(const Duration(days: 1))),
          ),
        ],
      ),
    );
  }
}

/// 일별 거래 내역 리스트
class _DailyTransactionList extends ConsumerWidget {
  final DateTime date;

  const _DailyTransactionList({required this.date});

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFFA8D8EA);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFA8D8EA);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final dailyTransactionsAsync = ref.watch(dailyTransactionsProvider);
    final formatter = NumberFormat('#,###', 'ko_KR');

    return dailyTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.4,
                child: Center(
                  child: Text(
                    l10n.calendarNoRecords,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ],
          );
        }

        // 금액 내림차순 정렬
        final sortedTransactions = List<Transaction>.from(transactions)
          ..sort((a, b) => b.amount.compareTo(a.amount));

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
          itemCount: sortedTransactions.length,
          itemBuilder: (context, index) {
            final tx = sortedTransactions[index];
            final userName = tx.userName ?? l10n.user;
            final userColor = _parseColor(tx.userColor);
            final categoryDisplay =
                tx.categoryName ?? l10n.categoryUncategorized;
            final String description = tx.title != null && tx.title!.isNotEmpty
                ? '$categoryDisplay - ${tx.title}'
                : categoryDisplay;

            final isIncome = tx.type == 'income';
            final isAssetType = tx.type == 'asset';

            Color amountColor;
            String amountPrefix;
            if (isIncome) {
              amountColor = colorScheme.primary;
              amountPrefix = '';
            } else if (isAssetType) {
              amountColor = colorScheme.tertiary;
              amountPrefix = '';
            } else {
              amountColor = colorScheme.error;
              amountPrefix = '-';
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: Spacing.xs),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) =>
                          TransactionDetailSheet(transaction: tx),
                    );
                  },
                  borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: Spacing.sm,
                      horizontal: Spacing.xs,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: userColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          userName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: Spacing.xs),
                        Flexible(
                          child: Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Text(
                          '$amountPrefix${formatter.format(tx.amount)}${l10n.transactionAmountUnit}',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: amountColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
