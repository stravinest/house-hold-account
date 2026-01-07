import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../providers/ledger_provider.dart';
import '../../domain/entities/ledger.dart';
import 'user_profile_summary.dart';
import '../../../../core/utils/color_utils.dart';

class CalendarView extends ConsumerWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;

  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onPageChanged,
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
        _MonthSummary(focusedDate: focusedDate, ref: ref),

        // 사용자 프로필 요약
        const UserProfileSummary(),

        // 커스텀 헤더
        _CustomCalendarHeader(
          focusedDate: focusedDate,
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
        ),

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
          rowHeight: 60,
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
            weekendStyle: TextStyle(
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            cellMargin: const EdgeInsets.all(2),
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
    // 날짜 정규화 (시간 제거)
    final normalizedDay = DateTime(day.year, day.month, day.day);
    final totals = dailyTotals[normalizedDay];

    // 새로운 데이터 구조에서 totalIncome과 totalExpense 추출
    final income = totals?['totalIncome'] ?? 0;
    final expense = totals?['totalExpense'] ?? 0;
    final hasData = income > 0 || expense > 0;

    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.primary
            : isToday
                ? colorScheme.primaryContainer
                : null,
        borderRadius: BorderRadius.circular(8),
        border: hasData && !isSelected
            ? Border.all(
                color: colorScheme.outline.withAlpha(128),
                width: 1,
              )
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 날짜
          Text(
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
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          // 사용자별 점 인디케이터
          if (hasData && totals?['users'] != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: (totals!['users'] as Map<String, dynamic>).entries.take(3).map((entry) {
                final userData = entry.value as Map<String, dynamic>;
                final colorHex = userData['color'] as String? ?? '#A8D8EA';
                final color = ColorUtils.parseHexColor(colorHex);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.onPrimary : color,
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              }).toList(),
            )
          else
            const SizedBox(height: 5),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            label: '수입',
            amount: income,
            color: Colors.blue,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant,
          ),
          _SummaryItem(
            label: '지출',
            amount: expense,
            color: Colors.red,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.outlineVariant,
          ),
          _SummaryItem(
            label: '합계',
            amount: balance,
            color: balance >= 0 ? Colors.green : Colors.red,
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
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  const _CustomCalendarHeader({
    required this.focusedDate,
    required this.onTodayPressed,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isTodayMonth = focusedDate.year == now.year &&
                         focusedDate.month == now.month;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: Row(
        children: [
          // 오늘 버튼
          TextButton.icon(
            onPressed: isTodayMonth ? null : onTodayPressed,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('오늘'),
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
