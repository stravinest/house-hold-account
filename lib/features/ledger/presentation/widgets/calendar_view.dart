import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../providers/ledger_provider.dart';
import '../../domain/entities/ledger.dart';
import '../../../../core/utils/color_utils.dart';

// 달력 셀 상수
class _CalendarCellConfig {
  static const int maxVisibleItems = 2; // 캘린더 셀에 최대 표시할 항목 수 (날짜 아래 공간 제약)
}

class _CalendarConstants {
  static const double cellPadding = 2.0;
  static const double dateBubbleSize = 20.0;
  static const double dateFontSize = 11.0;
  static const double amountFontSize = 10.0; // 8 -> 10 (최대 크기)
  static const double amountRowHeight = 15.0; // 각 행 높이 제한
  static const double dotSize = 6.0; // 5 -> 6
  static const double dotSpacing = 2.0;
  static const double rowHeight = 76.0;
  static const double smallScreenThreshold = 360.0;
  static const double daysOfWeekHeight = 28.0;
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

    // 공유 가계부 여부에 따른 멤버 수 결정
    // 현재 공유 가계부는 최대 2명으로 제한됨 (AppConstants.maxMembersPerLedger)
    // isShared가 true면 2명, 아니면 1명 (개인 가계부)
    final memberCount = currentLedger?.isShared == true ? 2 : 1;

    return Column(
      children: [
        // 월별 요약
        RepaintBoundary(
          child: _MonthSummary(
            focusedDate: focusedDate,
            ref: ref,
            memberCount: memberCount,
          ),
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
            weekendTextStyle: TextStyle(color: colorScheme.error),
            defaultTextStyle: TextStyle(color: colorScheme.onSurface),
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
    // 안전한 타입 변환으로 hasAsset 계산
    final rawUsers = totals?['users'];
    final usersForAsset = rawUsers is Map
        ? Map<String, dynamic>.from(rawUsers)
        : <String, dynamic>{};
    final hasAsset = usersForAsset.values.any((u) {
      final userData = u is Map
          ? Map<String, dynamic>.from(u)
          : <String, dynamic>{};
      return (userData['asset'] as int? ?? 0) > 0;
    });
    final hasData = income > 0 || expense > 0 || hasAsset;

    final isWeekend =
        day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

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
          // 날짜 아래: 사용자별 금액 (날짜를 가리지 않도록 날짜 버블 아래 배치)
          if (hasData && totals?['users'] != null)
            Positioned(
              top:
                  _CalendarConstants.cellPadding +
                  _CalendarConstants.dateBubbleSize +
                  2, // 날짜 버블 아래에 배치
              left: _CalendarConstants.cellPadding,
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
                      ? BorderSide(
                          color: colorScheme.outlineVariant.withAlpha(77),
                        )
                      : BorderSide.none,
                  right: BorderSide(
                    color: colorScheme.outlineVariant.withAlpha(77),
                  ),
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 4), // 8 -> 4
              child: Text(
                days[index],
                style: TextStyle(
                  color: isWeekend ? colorScheme.error : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 12, // 14 -> 12
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

    return Container(decoration: BoxDecoration(border: border));
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
          fontWeight: isSelected || isToday
              ? FontWeight.bold
              : FontWeight.normal,
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

    // 모든 항목을 수집 (색상, 금액)
    final List<_AmountItem> allItems = [];

    // 안전한 타입 변환
    final rawUsers = totals['users'];
    final usersMap = rawUsers is Map
        ? Map<String, dynamic>.from(rawUsers)
        : <String, dynamic>{};

    for (final entry in usersMap.entries) {
      final userData = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};
      final colorHex = userData['color'] as String? ?? '#A8D8EA';
      final color = ColorUtils.parseHexColor(colorHex);
      final income = userData['income'] as int? ?? 0;
      final expense = userData['expense'] as int? ?? 0;
      final saving = userData['asset'] as int? ?? 0;

      // 수입이 있으면 추가
      if (income > 0) {
        allItems.add(_AmountItem(color: color, amount: income));
      }

      // 지출이 있으면 추가
      if (expense > 0) {
        allItems.add(_AmountItem(color: color, amount: expense));
      }

      // 자산이 있으면 추가
      if (saving > 0) {
        allItems.add(_AmountItem(color: color, amount: saving));
      }
    }

    // 최대 표시 개수 제한
    final maxItems = _CalendarCellConfig.maxVisibleItems;
    final hasMore = allItems.length > maxItems;
    final visibleItems = hasMore ? allItems.take(maxItems).toList() : allItems;
    final remainingCount = allItems.length - maxItems;

    final List<Widget> rows = [];

    for (final item in visibleItems) {
      rows.add(
        _buildUserAmountRow(
          color: item.color,
          amount: item.amount,
          isSelected: isSelected,
          colorScheme: colorScheme,
          showAmount: showAmount,
        ),
      );
    }

    // 더 많은 항목이 있으면 "+n" 표시
    if (hasMore) {
      rows.add(
        _buildMoreIndicator(
          count: remainingCount,
          isSelected: isSelected,
          colorScheme: colorScheme,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  Widget _buildMoreIndicator({
    required int count,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    return SizedBox(
      height: _CalendarConstants.amountRowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '+$count',
          style: TextStyle(
            fontSize: _CalendarConstants.amountFontSize,
            color: isSelected
                ? colorScheme.onPrimary.withAlpha(179)
                : colorScheme.onSurface.withAlpha(128),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildUserAmountRow({
    required Color color,
    required int amount,
    required bool isSelected,
    required ColorScheme colorScheme,
    required bool showAmount,
  }) {
    final displayColor = isSelected ? colorScheme.onPrimary : color;

    // 모든 인디케이터를 채워진 동그라미로 통일
    final indicator = Container(
      width: _CalendarConstants.dotSize,
      height: _CalendarConstants.dotSize,
      decoration: BoxDecoration(color: displayColor, shape: BoxShape.circle),
    );

    return SizedBox(
      height: _CalendarConstants.amountRowHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          indicator,
          if (showAmount) ...[
            SizedBox(width: _CalendarConstants.dotSpacing),
            Flexible(
              child: Text(
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
            ),
          ],
        ],
      ),
    );
  }
}

// 금액 항목 데이터 클래스
class _AmountItem {
  final Color color;
  final int amount;

  const _AmountItem({required this.color, required this.amount});
}

// 월별 수입/지출 요약 위젯
class _MonthSummary extends StatelessWidget {
  final DateTime focusedDate;
  final WidgetRef ref;
  final int memberCount;

  const _MonthSummary({
    required this.focusedDate,
    required this.ref,
    required this.memberCount,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 실제 데이터 연동
    final monthlyTotalAsync = ref.watch(monthlyTotalProvider);

    final income = monthlyTotalAsync.valueOrNull?['income'] ?? 0;
    final expense = monthlyTotalAsync.valueOrNull?['expense'] ?? 0;
    final balance = income - expense;
    // 안전한 타입 변환 - Map<dynamic, dynamic>을 Map<String, dynamic>으로 변환
    final rawUsers = monthlyTotalAsync.valueOrNull?['users'];
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
          // 거래가 없는 멤버 기본값 추가
          enrichedUsers[member.userId] = {
            'displayName': member.displayName ?? '사용자',
            'income': 0,
            'expense': 0,
            'asset': 0,
            'color': member.color ?? '#A8D8EA',
          };
        }
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 2,
      ), // vertical 8 -> 2
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _SummaryColumn(
                label: '수입',
                totalAmount: income,
                color: colorScheme.primary,
                users: enrichedUsers,
                type: _SummaryType.income,
                memberCount: memberCount,
              ),
            ),
            Container(width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryColumn(
                label: '지출',
                totalAmount: expense,
                color: colorScheme.error,
                users: enrichedUsers,
                type: _SummaryType.expense,
                memberCount: memberCount,
              ),
            ),
            Container(width: 1, color: colorScheme.outlineVariant),
            Expanded(
              child: _SummaryColumn(
                label: '합계',
                totalAmount: balance,
                color: colorScheme.onSurface,
                users: enrichedUsers,
                type: _SummaryType.balance,
                memberCount: memberCount,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SummaryType { income, expense, balance }

// 상단 요약 영역 상수
class _SummaryConstants {
  // 사용자별 금액 표시 행 높이 (UserAmountIndicator 높이 + padding)
  static const double userIndicatorRowHeight = 14.0;
}

// 수입/지출 열 위젯
class _SummaryColumn extends StatelessWidget {
  final String label;
  final int totalAmount;
  final Color color;
  final Map<String, dynamic> users;
  final _SummaryType type;
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
      // 안전한 타입 변환
      final userData = entry.value is Map
          ? Map<String, dynamic>.from(entry.value as Map)
          : <String, dynamic>{};
      final income = userData['income'] as int? ?? 0;
      final expense = userData['expense'] as int? ?? 0;

      int amount;
      switch (type) {
        case _SummaryType.income:
          amount = income;
          break;
        case _SummaryType.expense:
          amount = expense;
          break;
        case _SummaryType.balance:
          amount = income - expense;
          break;
      }

      // 공유 가계부(2명)일 때는 0이어도 항상 표시
      // 개인 가계부일 때는 기존 로직: 합계는 0이 아닌 경우, 수입/지출은 0보다 큰 경우만
      final shouldShow = memberCount >= 2
          ? true
          : (type == _SummaryType.balance ? amount != 0 : amount > 0);
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
            fontSize: 11, // 더 작게
          ),
        ),
        // 총액
        Text(
          '${totalAmount < 0 ? '-' : ''}${formatter.format(totalAmount.abs())}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14, // 더 작게
          ),
        ),
        // 유저별 표시 (세로 배치)
        // 공유 가계부(2명)일 때는 항상 2줄 높이를 고정하여 레이아웃 변동 방지
        if (memberCount >= 2) ...[
          const SizedBox(height: 2),
          // 고정 높이: userIndicatorRowHeight(14.0) * 2명 = 28.0
          SizedBox(
            height: 2 * _SummaryConstants.userIndicatorRowHeight,
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
          // 개인 가계부(memberCount < 2)일 때는 사용자별 금액 표시 불필요
        ],
      ],
    );
  }
}

// 유저별 금액 인디케이터
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
          width: 6, // 8 -> 6
          height: 6, // 8 -> 6
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 2), // 3 -> 2
        Text(
          '${isNegative ? '-' : ''}${formatter.format(amount.abs())}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 9, // 10 -> 9
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ), // vertical 12 -> 4
      child: Row(
        children: [
          // 오늘 버튼
          TextButton.icon(
            onPressed: isToday ? null : onTodayPressed,
            icon: const Icon(Icons.today, size: 18),
            label: const Text('오늘'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.only(
                left: 8,
                top: 4,
                bottom: 4,
                right: 0,
              ),
            ),
          ),
          // 새로고침 버튼
          IconButton(
            icon: Icon(
              Icons.refresh,
              size: 18,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await onRefresh();
            },
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
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
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
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
