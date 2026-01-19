import 'package:flutter/material.dart';

import '../../../../shared/themes/design_tokens.dart';
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

    return Row(
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
        const SizedBox(width: Spacing.sm),
        _buildIconTab(
          icon: Icons.view_week_outlined,
          selectedIcon: Icons.view_week,
          label: '주',
          mode: CalendarViewMode.weekly,
          isSelected: selectedMode == CalendarViewMode.weekly,
          colorScheme: colorScheme,
        ),
        const SizedBox(width: Spacing.sm),
        _buildIconTab(
          icon: Icons.calendar_month_outlined,
          selectedIcon: Icons.calendar_month,
          label: '월',
          mode: CalendarViewMode.monthly,
          isSelected: selectedMode == CalendarViewMode.monthly,
          colorScheme: colorScheme,
        ),
      ],
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

    return GestureDetector(
      onTap: () => onModeChanged(mode),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xs,
          vertical: Spacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSelected ? selectedIcon : icon, size: 18, color: color),
            const SizedBox(width: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
