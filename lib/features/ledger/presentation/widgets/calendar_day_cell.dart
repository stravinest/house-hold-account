import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/color_utils.dart';
import '../providers/calendar_view_provider.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/ledger.dart';

/// 캘린더 셀 관련 상수
class CalendarCellConfig {
  static const int maxVisibleItems = 2; // 캘린더 셀에 최대 표시할 항목 수
}

/// 캘린더 상수
class CalendarConstants {
  static const double cellPadding = 2.0;
  static const double dateBubbleSize = 20.0;
  static const double dateFontSize = 11.0;
  static const double amountFontSize = 10.0;
  static const double amountRowHeight = 15.0;
  static const double dotSize = 6.0;
  static const double dotSpacing = 2.0;
  static const double rowHeight = 76.0;
  static const double smallScreenThreshold = 360.0;
  static const double daysOfWeekHeight = 28.0;
}

/// 캘린더에 표시할 거래 타입
enum TransactionDisplayType {
  /// 수입 (primary 색상)
  income,

  /// 지출 (error 색상)
  expense,

  /// 자산 (tertiary 색상)
  asset,
}

/// 금액 항목 데이터 클래스
class AmountItem {
  final Color color;
  final int amount;
  final TransactionDisplayType type;

  const AmountItem({
    required this.color,
    required this.amount,
    required this.type,
  });
}

/// 캘린더 날짜 셀 위젯
///
/// 개별 날짜를 표시하며, 해당 날짜의 거래 요약 정보를 함께 보여줍니다.
class CalendarDayCell extends StatelessWidget {
  final DateTime day;
  final Map<DateTime, Map<String, dynamic>> dailyTotals;
  final bool isSelected;
  final bool isToday;
  final ColorScheme colorScheme;
  final Ledger? currentLedger;

  const CalendarDayCell({
    super.key,
    required this.day,
    required this.dailyTotals,
    required this.isSelected,
    required this.isToday,
    required this.colorScheme,
    required this.currentLedger,
  });

  @override
  Widget build(BuildContext context) {
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
            top: CalendarConstants.cellPadding,
            left: CalendarConstants.cellPadding,
            child: _DateBubble(
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
                  CalendarConstants.cellPadding +
                  CalendarConstants.dateBubbleSize +
                  2, // 날짜 버블 아래에 배치
              left: CalendarConstants.cellPadding,
              right: CalendarConstants.cellPadding,
              bottom: CalendarConstants.cellPadding,
              child: _UserAmountList(
                totals: totals!,
                isSelected: isSelected,
                colorScheme: colorScheme,
              ),
            ),
        ],
      ),
    );
  }
}

/// 빈 셀 위젯 (현재 월이 아닌 날짜용)
class CalendarEmptyCell extends StatelessWidget {
  final DateTime day;
  final DateTime focusedDay;
  final ColorScheme colorScheme;

  const CalendarEmptyCell({
    super.key,
    required this.day,
    required this.focusedDay,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
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
}

/// 요일 헤더 위젯
class CalendarDaysOfWeekHeader extends ConsumerWidget {
  final ColorScheme colorScheme;

  const CalendarDaysOfWeekHeader({super.key, required this.colorScheme});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final weekStartDay = ref.watch(weekStartDayProvider);

    // 주 시작일에 따라 요일 배열 생성
    final List<String> days;
    if (weekStartDay == WeekStartDay.monday) {
      // 월요일 시작: 월화수목금토일
      days = [
        l10n.calendarDayMon,
        l10n.calendarDayTue,
        l10n.calendarDayWed,
        l10n.calendarDayThu,
        l10n.calendarDayFri,
        l10n.calendarDaySat,
        l10n.calendarDaySun,
      ];
    } else {
      // 일요일 시작: 일월화수목금토
      days = [
        l10n.calendarDaySun,
        l10n.calendarDayMon,
        l10n.calendarDayTue,
        l10n.calendarDayWed,
        l10n.calendarDayThu,
        l10n.calendarDayFri,
        l10n.calendarDaySat,
      ];
    }

    return Container(
      height: CalendarConstants.daysOfWeekHeight,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
          bottom: BorderSide(color: colorScheme.outlineVariant.withAlpha(77)),
        ),
      ),
      child: Row(
        children: List.generate(7, (index) {
          // 주 시작일에 따라 주말 인덱스 결정
          final bool isWeekend;
          if (weekStartDay == WeekStartDay.monday) {
            // 월요일 시작: 인덱스 5(토), 6(일)이 주말
            isWeekend = index == 5 || index == 6;
          } else {
            // 일요일 시작: 인덱스 0(일), 6(토)이 주말
            isWeekend = index == 0 || index == 6;
          }
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
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                days[index],
                style: TextStyle(
                  color: isWeekend ? colorScheme.error : colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// 날짜 버블 위젯 (날짜 숫자 표시)
class _DateBubble extends StatelessWidget {
  final DateTime day;
  final bool isSelected;
  final bool isToday;
  final bool isWeekend;
  final ColorScheme colorScheme;

  const _DateBubble({
    required this.day,
    required this.isSelected,
    required this.isToday,
    required this.isWeekend,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: CalendarConstants.dateBubbleSize,
      height: CalendarConstants.dateBubbleSize,
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
          fontSize: CalendarConstants.dateFontSize,
        ),
      ),
    );
  }
}

/// 사용자별 금액 목록 위젯
class _UserAmountList extends StatelessWidget {
  final Map<String, dynamic> totals;
  final bool isSelected;
  final ColorScheme colorScheme;

  const _UserAmountList({
    required this.totals,
    required this.isSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showAmount = screenWidth > CalendarConstants.smallScreenThreshold;

    // 모든 항목을 수집 (색상, 금액)
    final List<AmountItem> allItems = [];

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
        allItems.add(
          AmountItem(
            color: color,
            amount: income,
            type: TransactionDisplayType.income,
          ),
        );
      }

      // 지출이 있으면 추가
      if (expense > 0) {
        allItems.add(
          AmountItem(
            color: color,
            amount: expense,
            type: TransactionDisplayType.expense,
          ),
        );
      }

      // 자산이 있으면 추가
      if (saving > 0) {
        allItems.add(
          AmountItem(
            color: color,
            amount: saving,
            type: TransactionDisplayType.asset,
          ),
        );
      }
    }

    // 최대 표시 개수 제한
    const maxItems = CalendarCellConfig.maxVisibleItems;
    final hasMore = allItems.length > maxItems;
    final visibleItems = hasMore ? allItems.take(maxItems).toList() : allItems;
    final remainingCount = allItems.length - maxItems;

    final List<Widget> rows = [];

    for (final item in visibleItems) {
      rows.add(
        _UserAmountRow(
          color: item.color,
          amount: item.amount,
          type: item.type,
          isSelected: isSelected,
          colorScheme: colorScheme,
          showAmount: showAmount,
        ),
      );
    }

    // 더 많은 항목이 있으면 "+n" 표시
    if (hasMore) {
      rows.add(
        _MoreIndicator(
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
}

/// 더 많은 항목 표시 인디케이터
class _MoreIndicator extends StatelessWidget {
  final int count;
  final bool isSelected;
  final ColorScheme colorScheme;

  const _MoreIndicator({
    required this.count,
    required this.isSelected,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: CalendarConstants.amountRowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          '+$count',
          style: TextStyle(
            fontSize: CalendarConstants.amountFontSize,
            // 선택 여부와 관계없이 동일한 색상 사용
            color: colorScheme.onSurface.withAlpha(128),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// 사용자별 금액 행 위젯
class _UserAmountRow extends StatelessWidget {
  final Color color;
  final int amount;
  final TransactionDisplayType type;
  final bool isSelected;
  final ColorScheme colorScheme;
  final bool showAmount;

  const _UserAmountRow({
    required this.color,
    required this.amount,
    required this.type,
    required this.isSelected,
    required this.colorScheme,
    required this.showAmount,
  });

  @override
  Widget build(BuildContext context) {
    // 선택 여부와 관계없이 항상 사용자 색상 사용
    final indicator = Container(
      width: CalendarConstants.dotSize,
      height: CalendarConstants.dotSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );

    // 거래 타입에 따라 금액 색상 결정 (거래 리스트와 동일한 색상 사용)
    final Color amountColor;
    switch (type) {
      case TransactionDisplayType.income:
        amountColor = colorScheme.primary;
        break;
      case TransactionDisplayType.expense:
        amountColor = colorScheme.error;
        break;
      case TransactionDisplayType.asset:
        amountColor = colorScheme.tertiary;
        break;
    }

    return SizedBox(
      height: CalendarConstants.amountRowHeight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          indicator,
          if (showAmount) ...[
            const SizedBox(width: CalendarConstants.dotSpacing),
            Flexible(
              child: Text(
                NumberFormatUtils.currency.format(amount),
                style: TextStyle(
                  fontSize: CalendarConstants.amountFontSize,
                  color: amountColor,
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
