import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../../shared/themes/design_tokens.dart';
import '../../providers/statistics_provider.dart';

// 통계 페이지 날짜 선택 위젯
class StatisticsDateSelector extends ConsumerWidget {
  const StatisticsDateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedDate = ref.watch(statisticsSelectedDateProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: l10n.tooltipPreviousMonth,
            onPressed: () => _goToPreviousMonth(ref),
          ),
          // 월 표시
          InkWell(
            onTap: () => _showMonthPicker(context, ref, selectedDate),
            borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Text(
                l10n.statisticsYearMonthFormat(
                  selectedDate.year,
                  selectedDate.month,
                ),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 다음 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: l10n.tooltipNextMonth,
            onPressed: () => _goToNextMonth(ref),
          ),
        ],
      ),
    );
  }

  void _goToPreviousMonth(WidgetRef ref) {
    final current = ref.read(statisticsSelectedDateProvider);
    final newDate = DateTime(current.year, current.month - 1, 1);
    _updateSelectedDate(ref, newDate);
  }

  void _goToNextMonth(WidgetRef ref) {
    final current = ref.read(statisticsSelectedDateProvider);
    final newDate = DateTime(current.year, current.month + 1, 1);
    _updateSelectedDate(ref, newDate);
  }

  void _updateSelectedDate(WidgetRef ref, DateTime newDate) {
    // 먼저 날짜 상태 변경
    ref.read(statisticsSelectedDateProvider.notifier).state = newDate;
    // 날짜 변경 후 관련 provider 강제 갱신 (새 날짜로 데이터 가져오기)
    ref.invalidate(monthlyTrendWithAverageProvider);
    ref.invalidate(yearlyTrendWithAverageProvider);
  }

  void _showMonthPicker(
    BuildContext context,
    WidgetRef ref,
    DateTime currentDate,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MonthPickerSheet(
        selectedDate: currentDate,
        onDateSelected: (date) {
          _updateSelectedDate(ref, date);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// 월 선택 바텀시트
class _MonthPickerSheet extends StatefulWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateSelected;

  const _MonthPickerSheet({
    required this.selectedDate,
    required this.onDateSelected,
  });

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.selectedDate.year;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.statisticsDateSelect,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onDateSelected(DateTime(now.year, now.month, 1));
                },
                child: Text(l10n.statisticsToday),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // 연도 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: l10n.tooltipPreviousYear,
                onPressed: () {
                  setState(() {
                    _selectedYear--;
                  });
                },
              ),
              Text(
                l10n.statisticsYearLabel(_selectedYear),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: l10n.tooltipNextYear,
                onPressed: () {
                  setState(() {
                    _selectedYear++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // 월 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2,
              crossAxisSpacing: Spacing.sm,
              mainAxisSpacing: Spacing.sm,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected =
                  _selectedYear == widget.selectedDate.year &&
                  month == widget.selectedDate.month;
              final isCurrent = _selectedYear == now.year && month == now.month;

              return InkWell(
                onTap: () {
                  widget.onDateSelected(DateTime(_selectedYear, month, 1));
                },
                borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isCurrent
                        ? theme.colorScheme.primaryContainer
                        : null,
                    borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
                    border: isCurrent && !isSelected
                        ? Border.all(color: theme.colorScheme.primary)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    l10n.statisticsMonthLabel(month),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : isCurrent
                          ? theme.colorScheme.primary
                          : null,
                      fontWeight: isSelected || isCurrent
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: Spacing.md),
        ],
      ),
    );
  }
}
