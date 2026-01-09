import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// 할부 계산 결과
class InstallmentResult {
  final int totalAmount;
  final int months;
  final int baseAmount;
  final int firstMonthAmount;
  final DateTime endDate;
  final List<int> monthlyAmounts;

  const InstallmentResult({
    required this.totalAmount,
    required this.months,
    required this.baseAmount,
    required this.firstMonthAmount,
    required this.endDate,
    required this.monthlyAmounts,
  });

  factory InstallmentResult.calculate({
    required int totalAmount,
    required int months,
    required DateTime startDate,
  }) {
    final baseAmount = totalAmount ~/ months;
    final remainder = totalAmount % months;
    final firstMonthAmount = baseAmount + remainder;

    // 월별 금액 리스트 생성
    final monthlyAmounts = <int>[];
    for (int i = 0; i < months; i++) {
      monthlyAmounts.add(i == 0 ? firstMonthAmount : baseAmount);
    }

    // 종료월 계산 (시작월 포함, 월말 날짜 조정)
    final totalMonths = startDate.month + months - 1;
    final endYear = startDate.year + (totalMonths - 1) ~/ 12;
    final endMonth = ((totalMonths - 1) % 12) + 1;
    final lastDayOfEndMonth = DateTime(endYear, endMonth + 1, 0).day;
    final endDay = startDate.day > lastDayOfEndMonth ? lastDayOfEndMonth : startDate.day;
    final endDate = DateTime(endYear, endMonth, endDay);

    return InstallmentResult(
      totalAmount: totalAmount,
      months: months,
      baseAmount: baseAmount,
      firstMonthAmount: firstMonthAmount,
      endDate: endDate,
      monthlyAmounts: monthlyAmounts,
    );
  }
}

/// 할부 입력 위젯
class InstallmentInputWidget extends StatefulWidget {
  final DateTime startDate;
  final bool enabled;
  final ValueChanged<bool> onModeChanged;
  final ValueChanged<InstallmentResult> onApplied;

  const InstallmentInputWidget({
    super.key,
    required this.startDate,
    required this.onModeChanged,
    required this.onApplied,
    this.enabled = true,
  });

  @override
  State<InstallmentInputWidget> createState() => _InstallmentInputWidgetState();
}

class _InstallmentInputWidgetState extends State<InstallmentInputWidget> {
  bool _isInstallment = false;
  final _totalAmountController = TextEditingController();
  final _monthsController = TextEditingController();
  InstallmentResult? _previewResult;
  bool _isApplied = false;

  @override
  void dispose() {
    _totalAmountController.dispose();
    _monthsController.dispose();
    super.dispose();
  }

  void _updatePreview() {
    final totalAmountText = _totalAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
    final monthsText = _monthsController.text;

    if (totalAmountText.isEmpty || monthsText.isEmpty) {
      setState(() {
        _previewResult = null;
      });
      return;
    }

    final totalAmount = int.tryParse(totalAmountText);
    final months = int.tryParse(monthsText);

    if (totalAmount == null || totalAmount <= 0 || months == null || months <= 0) {
      setState(() {
        _previewResult = null;
      });
      return;
    }

    if (totalAmount < months) {
      setState(() {
        _previewResult = null;
      });
      return;
    }

    final result = InstallmentResult.calculate(
      totalAmount: totalAmount,
      months: months,
      startDate: widget.startDate,
    );

    setState(() {
      _previewResult = result;
    });
  }

  void _applyInstallment() {
    if (_previewResult == null) return;

    setState(() {
      _isApplied = true;
    });
    widget.onApplied(_previewResult!);
  }

  String _formatAmount(int amount) {
    return NumberFormat('#,###', 'ko_KR').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 할부 입력 토글 (스위치만 터치 가능)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('할부로 입력'),
          subtitle: const Text('총금액을 여러 달에 나눠서 기록합니다'),
          trailing: Switch(
            value: _isInstallment,
            onChanged: widget.enabled
                ? (value) {
                    setState(() {
                      _isInstallment = value;
                      if (!value) {
                        _totalAmountController.clear();
                        _monthsController.clear();
                        _previewResult = null;
                        _isApplied = false;
                      }
                    });
                    widget.onModeChanged(value);
                  }
                : null,
          ),
        ),

        // 할부 설정 (활성화된 경우)
        if (_isInstallment) ...[
          const SizedBox(height: 16),

          // 적용 완료 상태 표시
          if (_isApplied && _previewResult != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withAlpha(76),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withAlpha(76),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '할부 적용됨',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildResultRow(
                    '총 금액',
                    '${_formatAmount(_previewResult!.totalAmount)}원',
                  ),
                  const SizedBox(height: 4),
                  _buildResultRow(
                    '월 납입금',
                    '${_formatAmount(_previewResult!.baseAmount)}원',
                  ),
                  if (_previewResult!.firstMonthAmount != _previewResult!.baseAmount) ...[
                    const SizedBox(height: 4),
                    _buildResultRow(
                      '첫 달',
                      '${_formatAmount(_previewResult!.firstMonthAmount)}원',
                      highlight: true,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildResultRow(
                    '할부 기간',
                    '${_previewResult!.months}개월',
                  ),
                  const SizedBox(height: 4),
                  _buildResultRow(
                    '종료월',
                    DateFormat('yyyy년 M월', 'ko_KR').format(_previewResult!.endDate),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: widget.enabled
                          ? () {
                              setState(() {
                                _isApplied = false;
                              });
                            }
                          : null,
                      child: const Text('수정하기'),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // 입력 폼 (적용 전)
            // 총 금액 입력
            TextFormField(
              controller: _totalAmountController,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                _AmountInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: '총 금액',
                hintText: '할부 총 금액을 입력하세요',
                suffixText: '원',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.attach_money),
              ),
              onChanged: (_) => _updatePreview(),
            ),

            const SizedBox(height: 16),

            // 개월 수 입력
            TextFormField(
              controller: _monthsController,
              enabled: widget.enabled,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
                _MonthsInputFormatter(),
              ],
              decoration: const InputDecoration(
                labelText: '개월 수',
                hintText: '1-60개월',
                suffixText: '개월',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_month),
              ),
              onChanged: (_) => _updatePreview(),
            ),

            // 계산 결과 미리보기
            if (_previewResult != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(76),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withAlpha(76),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '할부 계산 미리보기',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildResultRow(
                      '월 납입금',
                      '${_formatAmount(_previewResult!.baseAmount)}원',
                    ),
                    if (_previewResult!.firstMonthAmount != _previewResult!.baseAmount) ...[
                      const SizedBox(height: 4),
                      _buildResultRow(
                        '첫 달',
                        '${_formatAmount(_previewResult!.firstMonthAmount)}원',
                        highlight: true,
                      ),
                    ],
                    const SizedBox(height: 4),
                    _buildResultRow(
                      '할부 기간',
                      '${_previewResult!.months}개월',
                    ),
                    const SizedBox(height: 4),
                    _buildResultRow(
                      '종료월',
                      DateFormat('yyyy년 M월', 'ko_KR').format(_previewResult!.endDate),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: widget.enabled ? _applyInstallment : null,
                        icon: const Icon(Icons.check),
                        label: const Text('할부 적용'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 유효성 오류 메시지
            if (_totalAmountController.text.isNotEmpty &&
                _monthsController.text.isNotEmpty &&
                _previewResult == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withAlpha(76),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '금액이 개월 수보다 커야 합니다',
                        style: TextStyle(color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ],
    );
  }

  Widget _buildResultRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
            color: highlight
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// 금액 포맷터 (천 단위 구분)
class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) return oldValue;

    final formatter = NumberFormat('#,###', 'ko_KR');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 개월 수 입력 포맷터 (1-60 범위 제한)
class _MonthsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text);
    if (number == null) return oldValue;

    // 1-60 범위로 제한
    if (number < 1) {
      return const TextEditingValue(
        text: '1',
        selection: TextSelection.collapsed(offset: 1),
      );
    }
    if (number > 60) {
      return const TextEditingValue(
        text: '60',
        selection: TextSelection.collapsed(offset: 2),
      );
    }

    return newValue;
  }
}
