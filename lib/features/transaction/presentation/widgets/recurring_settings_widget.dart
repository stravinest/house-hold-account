import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// 반복 주기 타입
enum RecurringType {
  none,
  daily,
  monthly,
  yearly,
}

/// 반복 주기 설정 결과
class RecurringSettings {
  final RecurringType type;
  final DateTime? endDate;
  final int transactionCount;
  final bool isFixedExpense;

  const RecurringSettings({
    required this.type,
    this.endDate,
    this.transactionCount = 1,
    this.isFixedExpense = false,
  });

  bool get isRecurring => type != RecurringType.none;

  String? get recurringTypeString {
    switch (type) {
      case RecurringType.daily:
        return 'daily';
      case RecurringType.monthly:
        return 'monthly';
      case RecurringType.yearly:
        return 'yearly';
      case RecurringType.none:
        return null;
    }
  }

  RecurringSettings copyWith({
    RecurringType? type,
    DateTime? endDate,
    int? transactionCount,
    bool? isFixedExpense,
  }) {
    return RecurringSettings(
      type: type ?? this.type,
      endDate: endDate ?? this.endDate,
      transactionCount: transactionCount ?? this.transactionCount,
      isFixedExpense: isFixedExpense ?? this.isFixedExpense,
    );
  }
}

/// 반복 주기 설정 위젯
class RecurringSettingsWidget extends ConsumerStatefulWidget {
  final DateTime startDate;
  final RecurringSettings? initialSettings;
  final ValueChanged<RecurringSettings> onChanged;
  final bool enabled;
  final String transactionType; // 'income', 'expense', 'saving'

  const RecurringSettingsWidget({
    super.key,
    required this.startDate,
    this.initialSettings,
    required this.onChanged,
    this.enabled = true,
    this.transactionType = 'expense',
  });

  @override
  ConsumerState<RecurringSettingsWidget> createState() => _RecurringSettingsWidgetState();
}

class _RecurringSettingsWidgetState extends ConsumerState<RecurringSettingsWidget> {
  late RecurringType _selectedType;
  DateTime? _endDate;
  bool _isFixedExpense = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSettings?.type ?? RecurringType.none;
    _endDate = widget.initialSettings?.endDate;
    _isFixedExpense = widget.initialSettings?.isFixedExpense ?? false;
  }

  @override
  void didUpdateWidget(covariant RecurringSettingsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 시작 날짜가 변경되면 종료 날짜도 업데이트
    if (oldWidget.startDate != widget.startDate && _endDate != null) {
      if (_endDate!.isBefore(widget.startDate)) {
        setState(() {
          _endDate = null;
        });
        _notifyChange();
      }
    }
  }

  int _calculateTransactionCount() {
    if (_selectedType == RecurringType.none || _endDate == null) {
      return 1;
    }

    var count = 0;
    // 시간 정보 제거하여 날짜만 비교 (종료일 포함 보장)
    var current = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day);
    final endDateNormalized = DateTime(_endDate!.year, _endDate!.month, _endDate!.day);

    while (!current.isAfter(endDateNormalized)) {
      count++;
      switch (_selectedType) {
        case RecurringType.daily:
          current = current.add(const Duration(days: 1));
          break;
        case RecurringType.monthly:
          // 월 증가 시 일자 조정 (예: 1/31 -> 2/28)
          final nextMonth = current.month + 1;
          final nextYear = nextMonth > 12 ? current.year + 1 : current.year;
          final adjustedMonth = nextMonth > 12 ? 1 : nextMonth;
          final lastDayOfMonth = DateTime(nextYear, adjustedMonth + 1, 0).day;
          final day = current.day > lastDayOfMonth ? lastDayOfMonth : current.day;
          current = DateTime(nextYear, adjustedMonth, day);
          break;
        case RecurringType.yearly:
          // 년 증가 시 윤년 처리 (예: 2/29 -> 2/28)
          final nextYear = current.year + 1;
          final lastDayOfMonth = DateTime(nextYear, current.month + 1, 0).day;
          final day = current.day > lastDayOfMonth ? lastDayOfMonth : current.day;
          current = DateTime(nextYear, current.month, day);
          break;
        case RecurringType.none:
          break;
      }
    }

    return count;
  }

  void _notifyChange() {
    final count = _calculateTransactionCount();
    widget.onChanged(RecurringSettings(
      type: _selectedType,
      endDate: _endDate,
      transactionCount: count,
      isFixedExpense: _isFixedExpense,
    ));
  }

  Future<void> _selectEndDate() async {
    switch (_selectedType) {
      case RecurringType.daily:
        await _selectDailyEndDate();
        break;
      case RecurringType.monthly:
        await _selectMonthlyEndDate();
        break;
      case RecurringType.yearly:
        await _selectYearlyEndDate();
        break;
      case RecurringType.none:
        break;
    }
  }

  Future<void> _selectDailyEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? widget.startDate,
      firstDate: widget.startDate,
      lastDate: widget.startDate.add(const Duration(days: 365)),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
      _notifyChange();
    }
  }

  Future<void> _selectMonthlyEndDate() async {
    final currentYear = widget.startDate.year;
    final currentMonth = widget.startDate.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => _MonthYearPickerDialog(
        initialYear: _endDate?.year ?? currentYear,
        initialMonth: _endDate?.month ?? currentMonth,
        minYear: currentYear,
        minMonth: currentMonth,
        maxYear: currentYear + 5,
      ),
    );

    if (result != null) {
      setState(() {
        // 해당 월의 마지막 날로 설정
        _endDate = DateTime(result.year, result.month + 1, 0);
      });
      _notifyChange();
    }
  }

  Future<void> _selectYearlyEndDate() async {
    final currentYear = widget.startDate.year;

    final result = await showDialog<int>(
      context: context,
      builder: (context) => _YearPickerDialog(
        initialYear: _endDate?.year ?? currentYear,
        minYear: currentYear,
        maxYear: currentYear + 10,
      ),
    );

    if (result != null) {
      setState(() {
        // 해당 년도의 마지막 날로 설정
        _endDate = DateTime(result, 12, 31);
      });
      _notifyChange();
    }
  }

  String _getEndDateDisplayText() {
    if (_endDate == null) return '계속 반복';

    switch (_selectedType) {
      case RecurringType.daily:
        return DateFormat('yyyy년 M월 d일', 'ko_KR').format(_endDate!);
      case RecurringType.monthly:
        return DateFormat('yyyy년 M월', 'ko_KR').format(_endDate!);
      case RecurringType.yearly:
        return '${_endDate!.year}년';
      case RecurringType.none:
        return '';
    }
  }

  String _getEndDateLabel() {
    switch (_selectedType) {
      case RecurringType.daily:
        return '종료일';
      case RecurringType.monthly:
        return '종료월';
      case RecurringType.yearly:
        return '종료년';
      case RecurringType.none:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final transactionCount = _calculateTransactionCount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '반복 주기',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),

        // 반복 주기 타입 선택
        SegmentedButton<RecurringType>(
          segments: const [
            ButtonSegment(
              value: RecurringType.none,
              label: Text('없음'),
            ),
            ButtonSegment(
              value: RecurringType.daily,
              label: Text('일'),
            ),
            ButtonSegment(
              value: RecurringType.monthly,
              label: Text('월'),
            ),
            ButtonSegment(
              value: RecurringType.yearly,
              label: Text('년'),
            ),
          ],
          selected: {_selectedType},
          onSelectionChanged: widget.enabled
              ? (selected) {
                  setState(() {
                    _selectedType = selected.first;
                    _endDate = null;
                  });
                  _notifyChange();
                }
              : null,
        ),

        // 종료 기간 선택 (반복 주기가 선택된 경우)
        if (_selectedType != RecurringType.none) ...[
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event),
            title: Text(_getEndDateLabel()),
            subtitle: Text(
              _getEndDateDisplayText(),
              style: TextStyle(
                color: colorScheme.onSurface,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_endDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: widget.enabled ? () {
                      setState(() {
                        _endDate = null;
                      });
                      _notifyChange();
                    } : null,
                    tooltip: '종료일 해제',
                  ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: widget.enabled ? _selectEndDate : null,
          ),

          // 반복 정보 미리보기
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withAlpha(76),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _endDate != null
                        ? '총 $transactionCount건의 거래가 생성됩니다'
                        : '계속 반복 (매일 자동 생성)',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 고정비 설정 (지출 타입이고 반복이 설정된 경우에만)
          if (widget.transactionType == 'expense') ...[
            const SizedBox(height: 16),
            _buildFixedExpenseSection(colorScheme),
          ],
        ],
      ],
    );
  }

  /// 고정비 설정 섹션 빌드 (체크박스만)
  Widget _buildFixedExpenseSection(ColorScheme colorScheme) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('고정비로 등록'),
      subtitle: Text(
        '월세, 보험료 등 정기적으로 지출되는 금액',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      value: _isFixedExpense,
      onChanged: widget.enabled
          ? (value) {
              setState(() {
                _isFixedExpense = value ?? false;
              });
              _notifyChange();
            }
          : null,
    );
  }
}

/// 월/년도 선택 다이얼로그
class _MonthYearPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;
  final int minYear;
  final int minMonth;
  final int maxYear;

  const _MonthYearPickerDialog({
    required this.initialYear,
    required this.initialMonth,
    required this.minYear,
    required this.minMonth,
    required this.maxYear,
  });

  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
    _selectedMonth = widget.initialMonth;
  }

  bool _isValidMonth(int year, int month) {
    if (year < widget.minYear) return false;
    if (year == widget.minYear && month < widget.minMonth) return false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('종료월 선택'),
      content: SizedBox(
        width: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 년도 선택
            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: '년도',
                border: OutlineInputBorder(),
              ),
              items: List.generate(
                widget.maxYear - widget.minYear + 1,
                (index) {
                  final year = widget.minYear + index;
                  return DropdownMenuItem(
                    value: year,
                    child: Text('$year년'),
                  );
                },
              ),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedYear = value;
                    // 선택한 년도가 최소 년도이고 현재 월이 최소 월보다 작으면 조정
                    if (_selectedYear == widget.minYear &&
                        _selectedMonth < widget.minMonth) {
                      _selectedMonth = widget.minMonth;
                    }
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            // 월 선택
            DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                labelText: '월',
                border: OutlineInputBorder(),
              ),
              items: List.generate(12, (index) {
                final month = index + 1;
                final isValid = _isValidMonth(_selectedYear, month);
                return DropdownMenuItem(
                  value: month,
                  enabled: isValid,
                  child: Text(
                    '$month월',
                    style: TextStyle(
                      color: isValid ? null : Colors.grey,
                    ),
                  ),
                );
              }),
              onChanged: (value) {
                if (value != null && _isValidMonth(_selectedYear, value)) {
                  setState(() {
                    _selectedMonth = value;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, DateTime(_selectedYear, _selectedMonth));
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}

/// 년도 선택 다이얼로그
class _YearPickerDialog extends StatefulWidget {
  final int initialYear;
  final int minYear;
  final int maxYear;

  const _YearPickerDialog({
    required this.initialYear,
    required this.minYear,
    required this.maxYear,
  });

  @override
  State<_YearPickerDialog> createState() => _YearPickerDialogState();
}

class _YearPickerDialogState extends State<_YearPickerDialog> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('종료년 선택'),
      content: SizedBox(
        width: 200,
        child: DropdownButtonFormField<int>(
          initialValue: _selectedYear,
          decoration: const InputDecoration(
            labelText: '년도',
            border: OutlineInputBorder(),
          ),
          items: List.generate(
            widget.maxYear - widget.minYear + 1,
            (index) {
              final year = widget.minYear + index;
              return DropdownMenuItem(
                value: year,
                child: Text('$year년'),
              );
            },
          ),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedYear = value;
              });
            }
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, _selectedYear);
          },
          child: const Text('확인'),
        ),
      ],
    );
  }
}
