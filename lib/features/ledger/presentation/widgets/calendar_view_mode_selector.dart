import 'package:flutter/material.dart';

import '../providers/calendar_view_provider.dart';

class CalendarViewModeSelector extends StatelessWidget {
  final CalendarViewMode selectedMode;
  final ValueChanged<CalendarViewMode> onModeChanged;

  const CalendarViewModeSelector({
    super.key,
    required this.selectedMode,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // impCmViewTabs 디자인 적용: 배경색 surface-container, cornerRadius 8
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildIconTab(
            icon: Icons.view_day_outlined,
            selectedIcon: Icons.view_day,
            label: '일',
            mode: CalendarViewMode.daily,
            isSelected: selectedMode == CalendarViewMode.daily,
            colorScheme: colorScheme,
          ),
          _buildIconTab(
            icon: Icons.view_week_outlined,
            selectedIcon: Icons.view_week,
            label: '주',
            mode: CalendarViewMode.weekly,
            isSelected: selectedMode == CalendarViewMode.weekly,
            colorScheme: colorScheme,
          ),
          _buildIconTab(
            icon: Icons.calendar_month_outlined,
            selectedIcon: Icons.calendar_month,
            label: '월',
            mode: CalendarViewMode.monthly,
            isSelected: selectedMode == CalendarViewMode.monthly,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildIconTab({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required CalendarViewMode mode,
    required bool isSelected,
    required ColorScheme colorScheme,
  }) {
    final color = isSelected
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant;

    // impCmViewTabs 디자인: 활성 탭은 surface 배경, cornerRadius 6, shadow
    return GestureDetector(
      onTap: () => onModeChanged(mode),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
