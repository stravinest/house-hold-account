import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
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
    // 실제 멤버 수 사용 (실시간 반영을 위해 isShared 대신 직접 조회)
    final memberCount = ref.watch(currentLedgerMemberCountProvider);

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

/// 일별 요약 헤더 (수입/지출/합계)
class _DailySummaryHeader extends ConsumerWidget {
  final DateTime date;
  final int memberCount;

  const _DailySummaryHeader({required this.date, required this.memberCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
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
              child: SummaryColumn(
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
              child: SummaryColumn(
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
              child: SummaryColumn(
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

/// 일별 네비게이션 헤더
class _DailyNavigationHeader extends StatefulWidget {
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
  State<_DailyNavigationHeader> createState() => _DailyNavigationHeaderState();
}

class _DailyNavigationHeaderState extends State<_DailyNavigationHeader>
    with SingleTickerProviderStateMixin {
  static const double _kSegmentWidth = 56;
  late final AnimationController _refreshController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() => _isRefreshing = true);
    unawaited(_refreshController.repeat());
    try {
      await widget.onRefresh();
    } finally {
      _refreshController.stop();
      _refreshController.reset();
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  Widget _buildSegment({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Widget? iconWidget,
  }) {
    final color = isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _kSegmentWidth,
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget ?? Icon(icon, size: IconSize.xs, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final isToday =
        widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          // 세그먼트 탭 바 (오늘 + 새로고침)
          Container(
            padding: const EdgeInsets.all(Spacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildSegment(
                  icon: Icons.today,
                  label: l10n.calendarToday,
                  isActive: !isToday,
                  onTap: isToday ? () {} : widget.onTodayPressed,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: Spacing.xs),
                _buildSegment(
                  icon: Icons.refresh,
                  label: l10n.tooltipRefresh,
                  isActive: _isRefreshing,
                  onTap: _handleRefresh,
                  colorScheme: colorScheme,
                  iconWidget: AnimatedBuilder(
                    animation: _refreshController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _refreshController.value * 2 * math.pi,
                        child: child,
                      );
                    },
                    child: Icon(
                      Icons.refresh,
                      size: IconSize.xs,
                      color: _isRefreshing
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // 이전 날짜 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => widget.onDateChanged(
              widget.date.subtract(const Duration(days: 1)),
            ),
          ),
          // 날짜 표시
          Text(
            l10n.calendarDailyDate(
              widget.date.year,
              widget.date.month,
              widget.date.day,
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          // 다음 날짜 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () =>
                widget.onDateChanged(widget.date.add(const Duration(days: 1))),
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
    final l10n = AppLocalizations.of(context);
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

        // 일별 총액 계산
        int dailyTotal = 0;
        for (final tx in sortedTransactions) {
          if (tx.type == 'expense') {
            dailyTotal -= tx.amount;
          } else if (tx.type == 'income') {
            dailyTotal += tx.amount;
          }
        }

        return ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          // impCdDayHeader, impCdTx 디자인 적용: 패딩 제거
          padding: EdgeInsets.zero,
          // +1 for date header
          itemCount: sortedTransactions.length + 1,
          itemBuilder: (context, index) {
            // 첫 번째 아이템: 날짜 헤더 (impCdDayHeader)
            if (index == 0) {
              final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
              final weekday = weekdays[date.weekday - 1];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: colorScheme.surfaceContainer,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${date.month}월 ${date.day}일 ($weekday)',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${dailyTotal >= 0 ? '' : ''}${formatter.format(dailyTotal)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: dailyTotal >= 0
                            ? colorScheme.primary
                            : colorScheme.error,
                      ),
                    ),
                  ],
                ),
              );
            }

            // 거래 항목 (impCdTx1, impCdTx2)
            final tx = sortedTransactions[index - 1];
            final userName = tx.userName ?? l10n.user;
            final userColor = _parseColor(tx.userColor);
            final categoryDisplay =
                tx.categoryName ?? l10n.categoryUncategorized;
            final String description = tx.title != null && tx.title!.isNotEmpty
                ? '$userName $categoryDisplay - ${tx.title}'
                : '$userName $categoryDisplay';

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

            return Material(
              // impCdTx 디자인: surface 배경색
              color: colorScheme.surface,
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
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // impCdTx 디자인: 사각형 점 (cornerRadius 4)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: userColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          description,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$amountPrefix${formatter.format(tx.amount)}${l10n.transactionAmountUnit}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: amountColor,
                        ),
                      ),
                    ],
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
