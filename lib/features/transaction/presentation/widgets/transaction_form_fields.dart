import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../shared/themes/design_tokens.dart';

/// 거래 타입 선택 위젯
class TransactionTypeSelector extends StatelessWidget {
  final String selectedType;
  final ValueChanged<String> onTypeChanged;

  const TransactionTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'expense',
          label: Text('지출'),
          icon: Icon(Icons.remove_circle_outline),
        ),
        ButtonSegment(
          value: 'income',
          label: Text('수입'),
          icon: Icon(Icons.add_circle_outline),
        ),
        ButtonSegment(
          value: 'asset',
          label: Text('자산'),
          icon: Icon(Icons.savings_outlined),
        ),
      ],
      selected: {selectedType},
      onSelectionChanged: (selected) => onTypeChanged(selected.first),
    );
  }
}

/// 제목 입력 필드
class TitleInputField extends StatelessWidget {
  final TextEditingController controller;

  const TitleInputField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: 1,
      textInputAction: TextInputAction.next,
      decoration: const InputDecoration(
        labelText: '제목',
        hintText: '예: 점심식사, 월급',
        prefixIcon: Icon(Icons.edit),
        border: OutlineInputBorder(),
      ),
      validator: (v) => v == null || v.trim().isEmpty ? '제목을 입력해주세요' : null,
    );
  }
}

/// 금액 입력 필드
class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isInstallmentMode;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isInstallmentMode,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        AmountInputFormatter(),
      ],
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      decoration: const InputDecoration(
        suffixText: '원',
        suffixStyle: TextStyle(fontSize: 18),
        border: InputBorder.none,
      ),
      validator: (v) =>
          !isInstallmentMode && (v == null || v.isEmpty || v == '0')
          ? '금액을 입력해주세요'
          : null,
    );
  }
}

/// 날짜 선택 타일
class DateSelectorTile extends StatelessWidget {
  final DateTime selectedDate;
  final VoidCallback onTap;

  const DateSelectorTile({
    super.key,
    required this.selectedDate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: Text(DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(selectedDate)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

/// 만기일 선택 타일
class MaturityDateTile extends StatelessWidget {
  final DateTime? maturityDate;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const MaturityDateTile({
    super.key,
    required this.maturityDate,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.event_available),
      title: Text(
        maturityDate == null
            ? '만기일 선택 (선택사항)'
            : DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(maturityDate!),
      ),
      trailing: maturityDate == null
          ? const Icon(Icons.chevron_right)
          : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
      onTap: onTap,
    );
  }
}

/// 메모 입력 섹션
class MemoInputSection extends StatelessWidget {
  final TextEditingController controller;

  const MemoInputSection({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Text(
            '메모 (선택)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: '추가 메모를 입력하세요',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}

/// 시트 핸들 바
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.onSurfaceVariant.withAlpha(76),
        borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
      ),
    );
  }
}

/// 시트 헤더
class SheetHeader extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback? onSave;
  final bool isLoading;

  const SheetHeader({
    super.key,
    required this.onCancel,
    required this.onSave,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: onCancel, child: const Text('취소')),
          TextButton(
            onPressed: isLoading ? null : onSave,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }
}

/// 금액 포맷터 (천 단위 구분)
class AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) return oldValue;
    final formatted = NumberFormat('#,###', 'ko_KR').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
