import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';

class AssetGoalFormSheet extends ConsumerStatefulWidget {
  final AssetGoal? goal;

  const AssetGoalFormSheet({super.key, this.goal});

  @override
  ConsumerState<AssetGoalFormSheet> createState() => _AssetGoalFormSheetState();
}

class _AssetGoalFormSheetState extends ConsumerState<AssetGoalFormSheet> {
  late TextEditingController _amountController;
  DateTime? _targetDate;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final amount = widget.goal?.targetAmount;
    _amountController = TextEditingController(
      text: amount != null ? NumberFormat('#,###', 'ko_KR').format(amount) : '',
    );
    _targetDate = widget.goal?.targetDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.goal != null;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // 핸들 바
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withAlpha(76),
                    borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
                  ),
                ),

                // 헤더
                _buildHeader(context, l10n, isEditing),

                const Divider(height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAmountField(l10n),
                        const SizedBox(height: 20),
                        _buildTargetDateField(context, l10n),
                        const SizedBox(height: 32),
                        _buildSubmitButton(context, l10n, isEditing),
                        // 키보드 높이 + 시스템 네비게이션 바 높이 감지
                        SizedBox(
                          height:
                              (MediaQuery.of(context).viewInsets.bottom > 0
                                  ? MediaQuery.of(context).viewInsets.bottom
                                  : MediaQuery.of(context).viewPadding.bottom) +
                              Spacing.lg,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    bool isEditing,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          Text(
            isEditing ? l10n.assetGoalEdit : l10n.assetGoalNew,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => _submit(context, isEditing),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assetGoalAmount,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _amountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _AmountInputFormatter(),
          ],
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: Icon(
              Icons.monetization_on_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            suffixText: l10n.transactionAmountUnit,
            suffixStyle: Theme.of(context).textTheme.titleMedium,
            counterText: "",
          ),
          maxLength: 18, // 콤마 포함 약 14~15자리 숫자 제한
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.assetGoalAmountRequired;
            }
            final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
            final amount = int.tryParse(cleanValue);
            if (amount == null || amount <= 0) {
              return l10n.assetGoalAmountInvalid;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTargetDateField(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.assetGoalDateOptional,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: colorScheme.surfaceContainerHighest.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _selectDate(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_month_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _targetDate != null
                          ? DateFormat(
                              'yyyy년 M월 d일 (E)',
                              'ko_KR',
                            ).format(_targetDate!)
                          : l10n.assetGoalDateHint,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: _targetDate != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_targetDate != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _targetDate = null;
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                      tooltip: l10n.tooltipClear,
                    )
                  else
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton(
    BuildContext context,
    AppLocalizations l10n,
    bool isEditing,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return FilledButton(
      onPressed: () => _submit(context, isEditing),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        isEditing ? l10n.assetGoalEdit : l10n.assetGoalCreate,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? tomorrow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 10),
    );

    if (picked != null) {
      setState(() {
        _targetDate = picked;
      });
    }
  }

  Future<void> _submit(BuildContext context, bool isEditing) async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    final ledgerId = ref.read(selectedLedgerIdProvider);
    if (ledgerId == null) {
      SnackBarUtils.showError(context, l10n.assetLedgerRequired);
      return;
    }

    final notifier = ref.read(assetGoalNotifierProvider(ledgerId).notifier);

    try {
      final amountText = _amountController.text.replaceAll(
        RegExp(r'[^\d]'),
        '',
      );
      final targetAmount = int.parse(amountText);

      if (isEditing && widget.goal != null) {
        final updatedGoal = widget.goal!.copyWith(
          title: l10n.assetGoalTitle,
          targetAmount: targetAmount,
          targetDate: _targetDate,
          assetType: null,
        );
        await notifier.updateGoal(updatedGoal);
      } else {
        await notifier.createGoal(
          title: l10n.assetGoalTitle,
          targetAmount: targetAmount,
          targetDate: _targetDate,
          assetType: null,
        );
      }

      if (context.mounted) {
        ref.invalidate(assetGoalsProvider);
        Navigator.pop(context);
        SnackBarUtils.showSuccess(
          context,
          isEditing ? l10n.assetGoalUpdated : l10n.assetGoalCreated,
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }
}

// 금액 포맷터 (천 단위 구분)
class _AmountInputFormatter extends TextInputFormatter {
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

    final formatter = NumberFormat('#,###', 'ko_KR');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
