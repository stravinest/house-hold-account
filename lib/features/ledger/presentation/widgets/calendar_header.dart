import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';

/// 커스텀 캘린더 헤더
///
/// 월 네비게이션과 세그먼트 탭 바(오늘, 리스트 토글, 새로고침)를 포함하는 헤더 위젯.
/// 세그먼트 탭 바는 통일된 스타일로 3개의 액션 버튼을 그룹화합니다.
class CalendarHeader extends StatefulWidget {
  final DateTime focusedDate;
  final DateTime selectedDate;
  final VoidCallback onTodayPressed;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function() onRefresh;
  final bool showListView;
  final VoidCallback onListViewToggle;

  const CalendarHeader({
    super.key,
    required this.focusedDate,
    required this.selectedDate,
    required this.onTodayPressed,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onRefresh,
    required this.showListView,
    required this.onListViewToggle,
  });

  @override
  State<CalendarHeader> createState() => _CalendarHeaderState();
}

class _CalendarHeaderState extends State<CalendarHeader>
    with SingleTickerProviderStateMixin {
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

    setState(() {
      _isRefreshing = true;
    });
    unawaited(_refreshController.repeat());

    try {
      await widget.onRefresh();
    } finally {
      _refreshController.stop();
      _refreshController.reset();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  static const double _kSegmentWidth = 56;

  Widget _buildSegment({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    Widget? iconWidget,
  }) {
    final color =
        isActive ? colorScheme.primary : colorScheme.onSurfaceVariant;

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
    final isToday = isSameDay(widget.selectedDate, now);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xs,
      ),
      child: Row(
        children: [
          // 세그먼트 탭 바 컨테이너
          Container(
            padding: const EdgeInsets.all(Spacing.xs),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 오늘 세그먼트
                _buildSegment(
                  icon: Icons.today,
                  label: l10n.calendarToday,
                  isActive: !isToday,
                  onTap: isToday ? () {} : widget.onTodayPressed,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: Spacing.xs),
                // 리스트 토글 세그먼트
                _buildSegment(
                  icon: Icons.format_list_bulleted,
                  label: widget.showListView
                      ? l10n.segmentCalendar
                      : l10n.segmentList,
                  isActive: widget.showListView,
                  onTap: widget.onListViewToggle,
                  colorScheme: colorScheme,
                ),
                const SizedBox(width: Spacing.xs),
                // 새로고침 세그먼트
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
          // 이전 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.tooltipPreviousMonth,
            onPressed: widget.onPreviousMonth,
          ),
          // 월 타이틀
          Text(
            l10n.calendarYearMonth(
              widget.focusedDate.year,
              widget.focusedDate.month,
            ),
            style: Theme.of(context)
                .textTheme
                .titleMedium!
                .copyWith(fontWeight: FontWeight.bold),
          ),
          // 다음 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.tooltipNextMonth,
            onPressed: widget.onNextMonth,
          ),
        ],
      ),
    );
  }
}
