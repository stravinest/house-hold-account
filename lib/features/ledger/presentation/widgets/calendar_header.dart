import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../l10n/generated/app_localizations.dart';

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
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final isToday = isSameDay(selectedDate, now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // 오늘 버튼
          TextButton.icon(
            onPressed: isToday ? null : onTodayPressed,
            icon: const Icon(Icons.today, size: 18),
            label: Text(l10n.calendarToday),
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
            l10n.calendarYearMonth(focusedDate.year, focusedDate.month),
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
