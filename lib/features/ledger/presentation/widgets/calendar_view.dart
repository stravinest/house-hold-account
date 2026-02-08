import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../providers/ledger_provider.dart';
import 'calendar_header.dart';
import 'calendar_month_summary.dart';
import 'calendar_day_cell.dart';

/// 캘린더 뷰 위젯
///
/// 월별 달력과 요약 정보를 표시하는 메인 캘린더 위젯입니다.
/// 날짜 선택, 월 이동, 새로고침 기능을 제공합니다.
///
/// [showSummary]가 false이면 CalendarMonthSummary를 표시하지 않습니다.
/// 이 경우 부모 위젯에서 CalendarMonthSummary를 별도로 고정 헤더로 표시할 수 있습니다.
/// [showHeader]가 false이면 CalendarHeader를 표시하지 않습니다.
/// 이 경우 부모 위젯에서 CalendarHeader를 별도로 관리할 수 있습니다.
/// [showListView]와 [onListViewToggle]은 월별 뷰에서만 사용되며, 선택적입니다.
class CalendarView extends ConsumerWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;
  final Future<void> Function() onRefresh;

  /// true이면 CalendarMonthSummary를 내부에 표시, false이면 외부에서 별도 관리
  final bool showSummary;

  /// true이면 CalendarHeader를 내부에 표시, false이면 외부에서 별도 관리
  final bool showHeader;

  /// 리스트 뷰 모드 여부 (월별 뷰에서만 사용)
  final bool? showListView;

  /// 리스트 뷰 토글 콜백 (월별 뷰에서만 사용)
  final VoidCallback? onListViewToggle;

  const CalendarView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onRefresh,
    this.showSummary = true,
    this.showHeader = true,
    this.showListView,
    this.onListViewToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final dailyTotalsAsync = ref.watch(dailyTotalsProvider);
    final dailyTotals = dailyTotalsAsync.valueOrNull ?? {};

    // CalendarDayCell에 currentLedger 전체가 필요하므로 전체 watch
    final currentLedgerAsync = ref.watch(currentLedgerProvider);
    final currentLedger = currentLedgerAsync.valueOrNull;

    // 실제 멤버 수 사용 (실시간 반영을 위해 isShared 대신 직접 조회)
    final memberCount = ref.watch(currentLedgerMemberCountProvider);

    // 주 시작일 설정
    final weekStartDay = ref.watch(weekStartDayProvider);
    final startingDayOfWeek = weekStartDay == WeekStartDay.monday
        ? StartingDayOfWeek.monday
        : StartingDayOfWeek.sunday;

    return Column(
      children: [
        // 월별 요약 (showSummary가 true일 때만 표시)
        if (showSummary)
          RepaintBoundary(
            child: CalendarMonthSummary(
              focusedDate: focusedDate,
              memberCount: memberCount,
            ),
          ),

        // 커스텀 헤더 (showHeader가 true일 때만 표시)
        if (showHeader)
          CalendarHeader(
            focusedDate: focusedDate,
            selectedDate: selectedDate,
            onTodayPressed: () {
              final today = DateTime.now();
              onDateSelected(today);
              onPageChanged(today);
            },
            onPreviousMonth: () {
              final previousMonth = DateTime(
                focusedDate.year,
                focusedDate.month - 1,
              );
              onPageChanged(previousMonth);
            },
            onNextMonth: () {
              final nextMonth = DateTime(focusedDate.year, focusedDate.month + 1);
              onPageChanged(nextMonth);
            },
            onRefresh: onRefresh,
            showListView: showListView ?? false,
            onListViewToggle: onListViewToggle ?? () {},
          ),

        // 커스텀 요일 헤더
        CalendarDaysOfWeekHeader(colorScheme: colorScheme),

        // 캘린더
        TableCalendar(
          firstDay: DateTime(2020, 1, 1),
          lastDay: DateTime(2030, 12, 31),
          focusedDay: focusedDate,
          selectedDayPredicate: (day) => isSameDay(selectedDate, day),
          calendarFormat: CalendarFormat.month,
          startingDayOfWeek: startingDayOfWeek,
          locale: 'ko_KR',
          headerVisible: false,
          rowHeight: CalendarConstants.rowHeight,
          daysOfWeekHeight: CalendarConstants.daysOfWeekHeight,
          daysOfWeekVisible: false,
          sixWeekMonthsEnforced: true,
          // 수평 스와이프로 월 이동 활성화 (세로 스크롤과 충돌 방지)
          availableGestures: AvailableGestures.horizontalSwipe,
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
            weekendTextStyle: TextStyle(color: colorScheme.error),
            defaultTextStyle: TextStyle(color: colorScheme.onSurface),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              // 현재 월의 날짜가 아니면 빈 셀 반환
              if (day.month != focusedDay.month) {
                return CalendarEmptyCell(
                  day: day,
                  focusedDay: focusedDay,
                  colorScheme: colorScheme,
                );
              }
              return CalendarDayCell(
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
                return CalendarEmptyCell(
                  day: day,
                  focusedDay: focusedDay,
                  colorScheme: colorScheme,
                );
              }
              return CalendarDayCell(
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
                return CalendarEmptyCell(
                  day: day,
                  focusedDay: focusedDay,
                  colorScheme: colorScheme,
                );
              }
              return CalendarDayCell(
                day: day,
                dailyTotals: dailyTotals,
                isSelected: isSameDay(selectedDate, day),
                isToday: true,
                colorScheme: colorScheme,
                currentLedger: currentLedger,
              );
            },
            outsideBuilder: (context, day, focusedDay) {
              return CalendarEmptyCell(
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
}
