import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
import '../providers/calendar_view_provider.dart';
import 'calendar_month_summary.dart';

/// 주별 뷰 위젯
///
/// 선택된 주의 거래 내역을 날짜별로 그룹핑하여 리스트로 표시합니다.
class WeeklyView extends ConsumerWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final Future<void> Function() onRefresh;

  const WeeklyView({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weekStartDay = ref.watch(weekStartDayProvider);
    final weekRange = getWeekRangeFor(selectedDate, weekStartDay);

    // 에러 발생 시 스낵바 표시
    ref.listen<AsyncValue<List<Transaction>>>(weeklyTransactionsProvider, (
      previous,
      next,
    ) {
      if (next.hasError && !next.isLoading) {
        SnackBarUtils.showError(context, l10n.errorGeneric);
      }
    });

    // 실제 멤버 수 사용 (실시간 반영을 위해 isShared 대신 직접 조회)
    final memberCount = ref.watch(currentLedgerMemberCountProvider);

    return Column(
      children: [
        // 고정 헤더: 수입 | 지출 | 합계 (주별)
        _WeeklySummaryHeader(
          weekStart: weekRange.start,
          weekEnd: weekRange.end,
          memberCount: memberCount,
        ),
        // 주 네비게이션 헤더
        _WeeklyNavigationHeader(
          weekStart: weekRange.start,
          weekEnd: weekRange.end,
          onWeekChanged: (newWeekStart) {
            onDateChanged(newWeekStart);
          },
          onTodayPressed: () => onDateChanged(DateTime.now()),
          onRefresh: onRefresh,
          weekStartDay: weekStartDay,
        ),
        // 거래 내역 리스트 (날짜별 그룹)
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: _WeeklyTransactionList(
              weekStart: weekRange.start,
              weekEnd: weekRange.end,
            ),
          ),
        ),
      ],
    );
  }
}

/// 주별 요약 헤더 (수입/지출/합계)
class _WeeklySummaryHeader extends ConsumerWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int memberCount;

  const _WeeklySummaryHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final weeklyTotalAsync = ref.watch(weeklyTotalProvider);

    // 이전 데이터 유지하면서 새 데이터 로딩 (레이아웃 점프 방지)
    final totals = weeklyTotalAsync.valueOrNull ?? {};
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

/// 주별 네비게이션 헤더
class _WeeklyNavigationHeader extends StatefulWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final ValueChanged<DateTime> onWeekChanged;
  final VoidCallback onTodayPressed;
  final Future<void> Function() onRefresh;
  final WeekStartDay weekStartDay;

  const _WeeklyNavigationHeader({
    required this.weekStart,
    required this.weekEnd,
    required this.onWeekChanged,
    required this.onTodayPressed,
    required this.onRefresh,
    required this.weekStartDay,
  });

  @override
  State<_WeeklyNavigationHeader> createState() =>
      _WeeklyNavigationHeaderState();
}

class _WeeklyNavigationHeaderState extends State<_WeeklyNavigationHeader>
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
    final currentWeekRange = getWeekRangeFor(now, widget.weekStartDay);
    final isCurrentWeek =
        widget.weekStart.year == currentWeekRange.start.year &&
        widget.weekStart.month == currentWeekRange.start.month &&
        widget.weekStart.day == currentWeekRange.start.day;

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
                  isActive: !isCurrentWeek,
                  onTap: isCurrentWeek ? () {} : widget.onTodayPressed,
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
          // 이전 주 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => widget.onWeekChanged(
              widget.weekStart.subtract(const Duration(days: 7)),
            ),
          ),
          // 주 범위 표시
          Text(
            l10n.calendarWeeklyRange(
              widget.weekStart.month,
              widget.weekStart.day,
              widget.weekEnd.month,
              widget.weekEnd.day,
            ),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          // 다음 주 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => widget.onWeekChanged(
              widget.weekStart.add(const Duration(days: 7)),
            ),
          ),
        ],
      ),
    );
  }
}

/// 주별 거래 내역 리스트 (날짜별 그룹)
class _WeeklyTransactionList extends ConsumerWidget {
  final DateTime weekStart;
  final DateTime weekEnd;

  const _WeeklyTransactionList({
    required this.weekStart,
    required this.weekEnd,
  });

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
    final weeklyTransactionsAsync = ref.watch(weeklyTransactionsProvider);
    final locale = Localizations.localeOf(context).toString();
    final formatter = NumberFormat('#,###', locale);
    // 이전 데이터 유지하면서 새 데이터 로딩 (레이아웃 점프 방지)
    final transactions = weeklyTransactionsAsync.valueOrNull ?? [];

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

    // 날짜별로 그룹핑
    final Map<DateTime, List<Transaction>> groupedByDate = {};
    for (final tx in transactions) {
      final dateKey = DateTime(tx.date.year, tx.date.month, tx.date.day);
      groupedByDate.putIfAbsent(dateKey, () => []).add(tx);
    }

    // 날짜 내림차순 정렬
    final sortedDates = groupedByDate.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      // impCwTransactionList 디자인 적용: 패딩 제거
      padding: EdgeInsets.zero,
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dayTransactions = groupedByDate[date]!;

        // 해당 날짜의 합계 계산
        int dayIncome = 0;
        int dayExpense = 0;
        for (final tx in dayTransactions) {
          if (tx.type == 'income') {
            dayIncome += tx.amount;
          } else if (tx.type == 'expense') {
            dayExpense += tx.amount;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 날짜 헤더 (impCwTransactionList 디자인: surfaceContainer 배경)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: colorScheme.surfaceContainer,
              child: Row(
                children: [
                  Text(
                    l10n.calendarDailyDateHeader(date.year, date.month, date.day, DateTimeUtils.weekdayLabel(l10n, date.weekday)),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (dayIncome > 0)
                    Text(
                      '+${formatter.format(dayIncome)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                  if (dayIncome > 0 && dayExpense > 0)
                    const SizedBox(width: Spacing.sm),
                  if (dayExpense > 0)
                    Text(
                      '-${formatter.format(dayExpense)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
            // 해당 날짜의 거래 목록
            ...dayTransactions.map((tx) {
              final userName = tx.userName ?? l10n.user;
              final userColor = _parseColor(tx.userColor);
              final categoryDisplay =
                  tx.categoryName ?? l10n.categoryUncategorized;
              final String description =
                  tx.title != null && tx.title!.isNotEmpty
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

              // impCwTransactionList 디자인: surface 배경 + 하단 border
              return Material(
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
                        // 유저별 색상 점 (수정하지 않음)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: userColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
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
            }),
          ],
        );
      },
    );
  }
}
