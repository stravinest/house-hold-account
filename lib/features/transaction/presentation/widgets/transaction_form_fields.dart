import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return SegmentedButton<String>(
      segments: [
        ButtonSegment(
          value: 'expense',
          label: Text(l10n.transactionExpense),
          icon: const Icon(Icons.remove_circle_outline),
        ),
        ButtonSegment(
          value: 'income',
          label: Text(l10n.transactionIncome),
          icon: const Icon(Icons.add_circle_outline),
        ),
        ButtonSegment(
          value: 'asset',
          label: Text(l10n.transactionAsset),
          icon: const Icon(Icons.savings_outlined),
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
    final l10n = AppLocalizations.of(context);
    return TextFormField(
      controller: controller,
      maxLines: 1,
      maxLength: 40,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: l10n.transactionTitle,
        hintText: l10n.categoryNameHintExample,
        prefixIcon: const Icon(Icons.edit),
        border: const OutlineInputBorder(),
        counterText: '', // 카운터 표시 숨김 (깔끔한 UI)
      ),
      validator: (v) =>
          v == null || v.trim().isEmpty ? l10n.transactionTitleRequired : null,
    );
  }
}

/// 금액 입력 필드
class AmountInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isInstallmentMode;
  final bool autofocus;

  const AmountInputField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isInstallmentMode,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        AmountInputFormatter(locale),
      ],
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
      decoration: InputDecoration(
        suffixText: l10n.transactionAmountUnit,
        suffixStyle: const TextStyle(fontSize: 18),
        border: InputBorder.none,
        counterText: '',
      ),
      maxLength: 18, // 콤마 포함 약 14~15자리 숫자 제한
      validator: (v) =>
          !isInstallmentMode && (v == null || v.isEmpty || v == '0')
          ? l10n.transactionAmountRequired
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
    final localeStr = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMEd(localeStr);
    return ListTile(
      leading: const Icon(Icons.calendar_today),
      title: Text(dateFormat.format(selectedDate)),
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
    final l10n = AppLocalizations.of(context);
    final localeStr = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMEd(localeStr);
    return ListTile(
      leading: const Icon(Icons.event_available),
      title: Text(
        maturityDate == null
            ? l10n.maturityDateSelectOptional
            : dateFormat.format(maturityDate!),
      ),
      trailing: maturityDate == null
          ? const Icon(Icons.chevron_right)
          : IconButton(
              icon: const Icon(Icons.clear),
              onPressed: onClear,
              tooltip: l10n.tooltipClear,
            ),
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
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Text(
            l10n.transactionMemoOptional,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        TextFormField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: l10n.transactionMemoHint,
            border: const OutlineInputBorder(),
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
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(onPressed: onCancel, child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: isLoading ? null : onSave,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

/// 금액 포맷터 (천 단위 구분)
class AmountInputFormatter extends TextInputFormatter {
  final String locale;

  AmountInputFormatter(this.locale);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // 숫자 이외의 문자 제거
    final cleanText = newValue.text.replaceAll(',', '');

    // 최대 14자리 숫자까지만 허용 (99조원)
    if (cleanText.length > 14) return oldValue;

    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###').format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
