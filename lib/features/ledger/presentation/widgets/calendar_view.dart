import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../providers/ledger_provider.dart';
import '../../domain/entities/ledger.dart';
import '../../../../core/utils/color_utils.dart';

class _CalendarConstants {
  static const double cellPadding = 4.0;
  static const double dateBubbleSize = 24.0;
  static const double dateFontSize = 13.0;
  static const double amountFontSize = 9.0;
  static const double dotSize = 6.0;
  static const double dotSpacing = 3.0;
  static const int maxVisibleUsers = 3;
  static const double rowHeight = 70.0;
  static const double smallScreenThreshold = 360.0;
  static const double daysOfWeekHeight = 40.0;
}

class CalendarView extends ConsumerWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;
  final Future<void> Function() onRefresh;

  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dailyTotalsAsync = ref.watch(dailyTotalsProvider);
    final dailyTotals = dailyTotalsAsync.valueOrNull ?? {};
    final currentLedgerAsync = ref.watch(currentLedgerProvider);
    final currentLedger = currentLedgerAsync.valueOrNull;

    return Column(
      children: [
        // 월별 요약
        RepaintBoundary(
          child: _MonthSummary(focusedDate: focusedDate, ref: ref),
        ),

        // 커스텀 헤더
        _CustomCalendarHeader(
          focusedDate: focusedDate,
          selectedDate: selectedDate,
          onTodayPressed: () {
            final today = DateTime.now();
            onDateSelected(today);
            onPageChanged(today);
          },
          onPreviousMonth: () {
            final previousMonth = DateTime(focusedDate.year, focusedDate.month - 1);
            onPageChanged(previousMonth);
          },
          onNextMonth: () {
            final nextMonth = DateTime(focusedDate.year, focusedDate.month + 1);
            onPageChanged(nextMonth);
          },
          onRefresh: onRefresh,
        ),

        // 커스텀 요일 헤더
        _buildDaysOfWeekHeader(colorScheme),

        // 캘린더
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: focusedDate,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: StartingDayOfWeek.sunday,
          locale: 'ko_KR',
          headerVisible: false,
          rowHeight: _CalendarConstants.rowHeight,
          daysOfWeekHeight: _CalendarConstants.daysOfWeekHeight,
          daysOfWeekVisible: false,
          sixWeekMonthsEnforced: true,
          calendarStyle: CalendarStyle(
            outsideDaysVisible: true,
            cellMargin: EdgeInsets.zero,
            todayDecoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            todayTextStyle: TextStyle(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
            selectedDecoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            selectedTextStyle: TextStyle(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
            weekendTextStyle: TextStyle(
              color: colorScheme.error,
            ),
            defaultTextStyle: TextStyle(
              color: colorScheme.onSurface,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              // 현재 월의 날짜가 아니면 빈 셀 반환
              if (day.month != focusedDay.month) {
                return _buildEmptyCell(
                  day: day,
                  focusedDay: focusedDay,
                  colorScheme: colorScheme,
                );
              }
              return _buildDayCell(
                context: context,
                day: day,
                dailyTotals: dailyTotals,
                isSelected: false,
                isToday: false,
                colorScheme: colorScheme,
                currentLedger: currentLedger,
              );
            },
            selectedBuilder: (context, day, focusedDay) {
              // 현재 월의 날짜가 아니면 빈 셀 반환
              if (day.month != focusedDay.month) {
                return _buildEmptyCell(
                  day: day,
                  focusedDay: focusedDay,
                  colorScheme: colorScheme,
                );
              }
              return _buildDayCell(
                context: context,
                day: day,
                dailyTotals: dailyTotals,
                isSelected: true,
                isToday: false,
                colorScheme: colorScheme,
                currentLedger: currentLedger,
              );
            },
            todayBuilder: (context, day, focusedDay) {
              // 현재 월의 날짜가 아니면 빈 셀 반환
              if (day.month != focusedDay.month) {
                return _buildEmptyCell(
                  day: day,
                  focusedDay: focusedDay,
                  colorScheme: colorScheme,
                );
              }
              return _buildDayCell(
                context: context,
                day: day,
                dailyTotals: dailyTotals,
                isSelected: isSameDay(selectedDate, day),
                isToday: true,
                colorScheme: colorScheme,
                currentLedger: currentLedger,
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return _buildEmptyCell(
                day: day,
                focusedDay: focusedDay,
                colorScheme: colorScheme,
              );
            },
          ),
          onDaySelected: (selectedDay, focusedDay) {
            onDateSelected(selectedDay);
          },
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }

  Widget _buildDayCell({
    required BuildContext context,
    required DateTime day,
    required Map<DateTime, Map<String, dynamic>> dailyTotals,
    required bool isSelected,
    required bool isToday,
    required ColorScheme colorScheme,
    required Ledger? currentLedger,
  }) {
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final totals = dailyTotals[normalizedDay];

    final income = totals?['totalIncome'] ?? 0;
    final expense = totals?['totalExpense'] ?? 0;
    final hasData = income > 0 || expense > 0;

    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    // 그리드 선을 위한 요일/주차 계산
    final dayOfWeek = day.weekday % 7;
    final firstDayOfMonth = DateTime(day.year, day.month, 1);
    final weekOfMonth = ((day.day + firstDayOfMonth.weekday - 1) / 7).floor();
    final isFirstColumn = dayOfWeek == 0;
    final isFirstRow = weekOfMonth == 0;

    // Border 설정 (중복 방지)
    final border = Border(
      top: isFirstRow
          ? BorderSide(color: colorScheme.outlineVariant.withAlpha(77))
          : BorderSide.none,
      left: isFirstColumn
          ? BorderSide(color: colorScheme.outlineVariant.withAlpha(77))
          : BorderSide.none,
      right: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
      bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? colorScheme.primary.withAlpha(26) : null,
        border: border,
      ),
      child: Stack(
        children: [
          // 왼쪽 상단: 날짜 숫자
          Positioned(
            top: _CalendarConstants.cellPadding,
            left: _CalendarConstants.cellPadding,
            child: _buildDateBubble(
              day: day,
              isSelected: isSelected,
              isToday: isToday,
              isWeekend: isWeekend,
              colorScheme: colorScheme,
            ),
          ),
          // 오른쪽 하단: 사용자별 금액
          if (hasData && totals?['users'] != null)
            Positioned(
              right: _CalendarConstants.cellPadding,
              bottom: _CalendarConstants.cellPadding,
              child: _buildUserAmountList(
                totals: totals!,
                isSelected: isSelected,
                colorScheme: colorScheme,
                context: context,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDaysOfWeekHeader(ColorScheme colorScheme) {
    const days = ['일', '월', '화', '수', '목', '금', '토'];

    return Container(
      height: _CalendarConstants.daysOfWeekHeight,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
          bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          final isWeekend = index == 0 || index == 6;
          final isFirstColumn = index == 0;

          return Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: isFirstColumn
                      ? BorderSide(color: colorScheme.outlineVariant.withAlpha(77))
                      : BorderSide.none,
                  right: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                days[index],
                style: TextStyle(
                  color: isWeekend ? colorScheme.error : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildEmptyCell({
    required DateTime day,
    required DateTime focusedDay,
    required ColorScheme colorScheme,
  }) {
    final dayOfWeek = day.weekday % 7;
    final firstDayOfMonth = DateTime(focusedDay.year, focusedDay.month, 1);
    final weekOfMonth = ((day.day + firstDayOfMonth.weekday - 1) / 7).floor();
    final isFirstColumn = dayOfWeek == 0;
    final isFirstRow = weekOfMonth == 0;

    final border = Border(
      top: isFirstRow
          ? BorderSide(color: colorScheme.outlineVariant.withAlpha(77))
          : BorderSide.none,
      left: isFirstColumn
          ? BorderSide(color: colorScheme.outlineVariant.withAlpha(77))
          : BorderSide.none,
      right: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
      bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
    );

    return Container(
      decoration: BoxDecoration(
        border: border,
      ),
    );
  }

  Widget _buildDateBubble({
    required DateTime day,
    required bool isSelected,
    required bool isToday,
    required bool isWeekend,
    required ColorScheme colorScheme,
  }) {
    return Container(
      width: _CalendarConstants.dateBubbleSize,
      height: _CalendarConstants.dateBubbleSize,
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary
            : isToday
                ? colorScheme.primaryContainer
                : Colors.transparent,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '${day.day}',
        style: TextStyle(
          color: isSelected
              ? colorScheme.onPrimary
              : isToday
                  ? colorScheme.onPrimaryContainer
                  : isWeekend
                      ? colorScheme.error
                      : colorScheme.onSurface,
          fontWeight: isSelected || isToday ? FontWeight.bold : FontWeight.normal,
          fontSize: _CalendarConstants.dateFontSize,
        ),
      ),
    );
  }

  Widget _buildUserAmountList({
    required Map<String, dynamic> totals,
    required bool isSelected,
    required ColorScheme colorScheme,
    required BuildContext context,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showAmount = screenWidth > _CalendarConstants.smallScreenThreshold;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: (totals['users'] as Map<String, dynamic>)
          .entries
          .take(_CalendarConstants.maxVisibleUsers)
          .map((entry) {
        final userData = entry.value as Map<String, dynamic>;
        final colorHex = userData['color'] as String? ?? '#A8D8EA';
        final color = ColorUtils.parseHexColor(colorHex);
        final expense = userData['expense'] as int? ?? 0;

        return _buildUserAmountRow(
          color: color,
          amount: expense,
          isSelected: isSelected,
          colorScheme: colorScheme,
          showAmount: showAmount,
        );
      }).toList(),
    );
  }

  Widget _buildUserAmountRow({
    required Color color,
    required int amount,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool showAmount,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: _CalendarConstants.dotSize,
            height: _CalendarConstants.dotSize,
            decoration: BoxDecoration(
              color: isSelected ? colorScheme.onPrimary : color,
              shape: BoxShape.circle,
            ),
          ),
          if (showAmount) ...[
            SizedBox(width: _CalendarConstants.dotSpacing),
            Text(
              NumberFormat('#,###').format(amount),
              style: TextStyle(
                fontSize: _CalendarConstants.amountFontSize,
                color: isSelected
                    ? colorScheme.onPrimary.withAlpha(204)
                    : colorScheme.onSurface.withAlpha(179),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ],
      ),
    );
  }
}

// 월별 수입/지출 요약 위젯
class _MonthSummary extends StatelessWidget {
  final DateTime focusedDate;
  final WidgetRef ref;

  const _MonthSummary({required this.focusedDate, required this.ref});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 실제 데이터 연동
    final monthlyTotalAsync = ref.watch(monthlyTotalProvider);

    final income = monthlyTotalAsync.valueOrNull?['income'] ?? 0;
    final expense = monthlyTotalAsync.valueOrNull?['expense'] ?? 0;
    final balance = income - expense;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: '수입',
              amount: income,
              color: Colors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: _SummaryItem(
              label: '지출',
              amount: expense,
              color: Colors.red,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant,
          ),
          Expanded(
            child: _SummaryItem(
              label: '합계',
              amount: balance,
              color: balance >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int amount;
  final Color color;

  const _SummaryItem({
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'ko_KR');

    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount < 0 ? '-' : ''}${formatter.format(amount.abs())}원',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

// 커스텀 캘린더 헤더
class _CustomCalendarHeader extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function() onRefresh;

  const _CustomCalendarHeader({
    required this.focusedDate,
    required this.selectedDate,
    required this.onTodayPressed,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = isSameDay(selectedDate, now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // 오늘 버튼
          TextButton.icon(
            onPressed: isToday ? null : onTodayPressed,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('오늘'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(left: 8, top: 4, bottom: 4, right: 0),
            ),
          ),
          // 새로고침 버튼
          IconButton(
            icon: const Icon(Icons.refresh, size: 16),
            onPressed: onRefresh,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(
              minWidth: 28,
              minHeight: 28,
            ),
          ),
          const Spacer(),
          // 이전 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPreviousMonth,
          ),
          // 월 타이틀
          Text(
            DateFormat('yyyy년 M월', 'ko_KR').format(focusedDate),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          // 다음 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}
