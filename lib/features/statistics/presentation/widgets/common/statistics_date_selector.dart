import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/statistics_provider.dart';

// 통계 페이지 날짜 선택 위젯
class StatisticsDateSelector extends ConsumerWidget {
  const StatisticsDateSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(statisticsSelectedDateProvider);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이전 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => _goToPreviousMonth(ref),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
          // 월 표시
          GestureDetector(
            onTap: () => _showMonthPicker(context, ref, selectedDate),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                DateFormat('yyyy년 M월', 'ko_KR').format(selectedDate),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // 다음 월 버튼
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => _goToNextMonth(ref),
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
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

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime currentDate) {
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
    final theme = Theme.of(context);
    final now = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '날짜 선택',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onDateSelected(DateTime(now.year, now.month, 1));
                },
                child: const Text('오늘'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 연도 선택
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedYear--;
                  });
                },
              ),
              Text(
                '$_selectedYear년',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  setState(() {
                    _selectedYear++;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 월 그리드
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = _selectedYear == widget.selectedDate.year &&
                  month == widget.selectedDate.month;
              final isCurrent = _selectedYear == now.year && month == now.month;

              return InkWell(
                onTap: () {
                  widget.onDateSelected(DateTime(_selectedYear, month, 1));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : isCurrent
                            ? theme.colorScheme.primaryContainer
                            : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isCurrent && !isSelected
                        ? Border.all(color: theme.colorScheme.primary)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$month월',
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
