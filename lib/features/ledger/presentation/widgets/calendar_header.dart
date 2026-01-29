import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/spinning_refresh_button.dart';

/// 커스텀 캘린더 헤더
///
/// 월 네비게이션, 오늘 버튼, 새로고침 버튼을 포함하는 헤더 위젯
class CalendarHeader extends StatelessWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function() onRefresh;

  const CalendarHeader({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.onTodayPressed,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final isToday = isSameDay(selectedDate, now);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          // 오늘 버튼 (일/주별 뷰와 동일한 스타일)
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
          // 이전 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.tooltipPreviousMonth,
            onPressed: onPreviousMonth,
          ),
          // 월 타이틀
          Text(
            l10n.calendarYearMonth(focusedDate.year, focusedDate.month),
            style: Theme.of(
              context,
            ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
          ),
          // 다음 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.tooltipNextMonth,
            onPressed: onNextMonth,
          ),
        ],
      ),
    );
  }
}
