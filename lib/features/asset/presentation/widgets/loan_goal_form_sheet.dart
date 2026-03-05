import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/korean_amount_formatter.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../data/services/loan_calculator_service.dart';
import '../../domain/entities/asset_goal.dart';
import '../providers/asset_goal_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';

class LoanGoalFormSheet extends ConsumerStatefulWidget {
  final AssetGoal? goal;

  const LoanGoalFormSheet({super.key, this.goal});

  @override
  ConsumerState<LoanGoalFormSheet> createState() => _LoanGoalFormSheetState();
}

class _LoanGoalFormSheetState extends ConsumerState<LoanGoalFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _loanAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _monthlyPaymentController;
  late TextEditingController _memoController;

  RepaymentMethod _repaymentMethod = RepaymentMethod.equalPrincipalInterest;
  DateTime? _startDate;
  DateTime? _maturityDate;
  bool _isManualPayment = false;
  bool _isLoading = false;
  int? _selectedPeriodYears;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final goal = widget.goal;
    _titleController = TextEditingController(
      text: goal?.title ?? '',
    );
    _loanAmountController = TextEditingController(
      text: goal?.loanAmount != null
          ? NumberFormat('#,###').format(goal?.loanAmount)
          : '',
    );
    _interestRateController = TextEditingController(
      text: goal?.annualInterestRate?.toString() ?? '',
    );
    _monthlyPaymentController = TextEditingController(
      text: goal?.monthlyPayment != null
          ? NumberFormat('#,###').format(goal?.monthlyPayment)
          : '',
    );
    _memoController = TextEditingController(
      text: goal?.memo ?? '',
    );
    _repaymentMethod =
        goal?.repaymentMethod ?? RepaymentMethod.equalPrincipalInterest;
    _startDate = goal?.startDate;
    _maturityDate = goal?.targetDate;
    _isManualPayment = goal?.isManualPayment ?? false;
    // 기존 기간이 정확히 N년인 경우 칩 선택 상태 복원
    if (_startDate != null && _maturityDate != null) {
      final diffYears = _maturityDate!.year - _startDate!.year;
      final sameMonthDay = _maturityDate!.month == _startDate!.month &&
          _maturityDate!.day == _startDate!.day;
      if (sameMonthDay && const [10, 20, 30, 40].contains(diffYears)) {
        _selectedPeriodYears = diffYears;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _monthlyPaymentController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  // 자동 계산된 월 상환금
  int? get _calculatedMonthlyPayment {
    final loanAmountText = _loanAmountController.text.replaceAll(',', '');
    final loanAmount = int.tryParse(loanAmountText);
    final annualRate = double.tryParse(_interestRateController.text);
    final start = _startDate;
    final end = _maturityDate;

    if (loanAmount == null || loanAmount <= 0) return null;
    if (annualRate == null || annualRate < 0) return null;
    if (start == null || end == null) return null;

    final totalMonths =
        (end.year - start.year) * 12 + (end.month - start.month);
    if (totalMonths <= 0) return null;

    return LoanCalculatorService.calculateMonthlyPayment(
      loanAmount: loanAmount,
      annualInterestRate: annualRate,
      totalMonths: totalMonths,
      method: _repaymentMethod,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isEditing = widget.goal != null;
    final colorScheme = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
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
                _buildHeader(context, l10n, isEditing),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTitleField(l10n),
                        const SizedBox(height: 20),
                        _buildLoanAmountField(l10n),
                        const SizedBox(height: 20),
                        _buildRepaymentMethodField(context, l10n),
                        const SizedBox(height: 20),
                        _buildInterestRateField(l10n),
                        const SizedBox(height: 20),
                        _buildStartDateField(context, l10n),
                        const SizedBox(height: 20),
                        _buildMaturityDateField(context, l10n),
                        const SizedBox(height: 20),
                        _buildMonthlyPaymentField(context, l10n),
                        const SizedBox(height: 20),
                        _buildMemoField(l10n),
                        const SizedBox(height: 32),
                        _buildSubmitButton(context, l10n, isEditing),
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
            isEditing ? l10n.loanGoalEdit : l10n.loanGoalNew,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: _isLoading ? null : () => _submit(context, isEditing),
            child: _isLoading
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

  Widget _buildTitleField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.goalTitleLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _titleController,
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            hintText: l10n.goalTitleHint,
            prefixIcon: Icon(
              Icons.flag_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.goalTitleRequired;
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoanAmountField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.loanGoalAmount),
        const SizedBox(height: 8),
        TextFormField(
          controller: _loanAmountController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _AmountInputFormatter(),
          ],
          onChanged: (_) => setState(() {}),
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            hintText: '0',
            prefixIcon: Icon(
              Icons.account_balance_outlined,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            suffixText: l10n.transactionAmountUnit,
            suffixStyle: Theme.of(context).textTheme.titleMedium,
            counterText: '',
          ),
          maxLength: 18,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return l10n.assetGoalAmountRequired;
            }
            final clean = value.replaceAll(RegExp(r'[^\d]'), '');
            final amount = int.tryParse(clean);
            if (amount == null || amount <= 0) {
              return l10n.assetGoalAmountInvalid;
            }
            return null;
          },
        ),
        _buildKoreanAmountLabel(_loanAmountController.text),
      ],
    );
  }

  Widget _buildRepaymentMethodField(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.repaymentMethod),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RepaymentMethod.values.map((method) {
            final isSelected = _repaymentMethod == method;
            return ChoiceChip(
              label: Text(_repaymentMethodLabel(l10n, method)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _repaymentMethod = method;
                  });
                }
              },
              selectedColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInterestRateField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.loanInterestRate),
        const SizedBox(height: 8),
        TextFormField(
          controller: _interestRateController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '3.8',
            prefixIcon: Icon(
              Icons.percent,
              color: Theme.of(context).colorScheme.tertiary,
            ),
            suffixText: '%',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) return null;
            final rate = double.tryParse(value);
            if (rate == null || rate < 0 || rate > 100) {
              return '0~100 사이의 이율을 입력하세요';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStartDateField(BuildContext context, AppLocalizations l10n) {
    return _buildDatePickerField(
      context: context,
      label: l10n.loanStartDate,
      date: _startDate,
      hint: '시작일 선택',
      icon: Icons.play_circle_outline,
      onClear: () => setState(() => _startDate = null),
      onTap: () => _selectDate(
        context,
        initial: _startDate,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
        onPicked: (date) => setState(() {
          _startDate = date;
          if (_selectedPeriodYears != null) {
            _maturityDate = DateTime(
              date.year + _selectedPeriodYears!,
              date.month,
              date.day,
            );
          }
        }),
      ),
    );
  }

  Widget _buildMaturityDateField(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    const periodOptions = [10, 20, 30, 40];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.loanMaturityDate),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...periodOptions.map((years) {
              final isSelected = _selectedPeriodYears == years;
              return ChoiceChip(
                label: Text(l10n.loanPeriodYears(years)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected && _startDate != null) {
                    setState(() {
                      _selectedPeriodYears = years;
                      _maturityDate = DateTime(
                        _startDate!.year + years,
                        _startDate!.month,
                        _startDate!.day,
                      );
                    });
                  } else if (selected) {
                    setState(() => _selectedPeriodYears = years);
                  }
                },
                selectedColor: colorScheme.tertiaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onTertiaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              );
            }),
            ChoiceChip(
              label: Text(l10n.loanPeriodDirect),
              selected: _selectedPeriodYears == null && _maturityDate != null,
              onSelected: (_) {
                setState(() => _selectedPeriodYears = null);
                _selectDate(
                  context,
                  initial: _maturityDate,
                  firstDate: _startDate ?? DateTime(2000),
                  lastDate: DateTime(2100),
                  onPicked: (date) => setState(() {
                    _maturityDate = date;
                    _selectedPeriodYears = null;
                  }),
                );
              },
              selectedColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                color: _selectedPeriodYears == null && _maturityDate != null
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: _selectedPeriodYears == null && _maturityDate != null
                    ? FontWeight.w600
                    : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
        if (_maturityDate != null) ...[
          const SizedBox(height: 8),
          Material(
            color: colorScheme.surfaceContainerHighest.withAlpha(128),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => _selectDate(
                context,
                initial: _maturityDate,
                firstDate: _startDate ?? DateTime(2000),
                lastDate: DateTime(2100),
                onPicked: (date) => setState(() {
                  _maturityDate = date;
                  _selectedPeriodYears = null;
                }),
              ),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Icon(Icons.flag_outlined, color: colorScheme.tertiary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        DateFormat('yyyy년 MM월 dd일').format(_maturityDate!),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => setState(() {
                        _maturityDate = null;
                        _selectedPeriodYears = null;
                      }),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDatePickerField({
    required BuildContext context,
    required String label,
    required DateTime? date,
    required String hint,
    required IconData icon,
    required VoidCallback onClear,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        const SizedBox(height: 8),
        Material(
          color: colorScheme.surfaceContainerHighest.withAlpha(128),
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: colorScheme.tertiary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      date != null
                          ? DateFormat('yyyy년 MM월 dd일').format(date)
                          : hint,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: date != null
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (date != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      visualDensity: VisualDensity.compact,
                    )
                  else
                    Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyPaymentField(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final calculated = _calculatedMonthlyPayment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.loanMonthlyPayment),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.loanAutoCalculate),
              selected: !_isManualPayment,
              onSelected: (selected) {
                if (selected) setState(() => _isManualPayment = false);
              },
              selectedColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                color: !_isManualPayment
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: !_isManualPayment ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
            ChoiceChip(
              label: Text(l10n.loanManualInput),
              selected: _isManualPayment,
              onSelected: (selected) {
                if (selected) setState(() => _isManualPayment = true);
              },
              selectedColor: colorScheme.tertiaryContainer,
              labelStyle: TextStyle(
                color: _isManualPayment
                    ? colorScheme.onTertiaryContainer
                    : colorScheme.onSurfaceVariant,
                fontWeight: _isManualPayment ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_isManualPayment)
          TextFormField(
            controller: _monthlyPaymentController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _AmountInputFormatter(),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: '0',
              prefixIcon: Icon(
                Icons.monetization_on_outlined,
                color: colorScheme.tertiary,
              ),
              suffixText: l10n.transactionAmountUnit,
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: colorScheme.tertiaryContainer.withAlpha(80),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calculate_outlined,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: calculated != null
                      ? Text(
                          '₩${NumberFormat('#,###').format(calculated)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.tertiary,
                          ),
                        )
                      : Text(
                          '이율, 날짜 입력 후 자동 계산',
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ],
            ),
          ),
        if (_isManualPayment)
          _buildKoreanAmountLabel(_monthlyPaymentController.text),
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
      onPressed: _isLoading ? null : () => _submit(context, isEditing),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: colorScheme.tertiary,
        foregroundColor: colorScheme.onTertiary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colorScheme.onTertiary,
              ),
            )
          : Text(
              isEditing ? l10n.loanGoalEdit : l10n.loanGoalCreate,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
    );
  }

  Widget _buildKoreanAmountLabel(String amountText) {
    final clean = amountText.replaceAll(RegExp(r'[^\d]'), '');
    final amount = int.tryParse(clean) ?? 0;
    final korean = formatKoreanAmount(amount);
    if (korean.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, right: 4),
      child: Text(
        korean,
        textAlign: TextAlign.right,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildMemoField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(l10n.goalMemoLabel),
        const SizedBox(height: 8),
        TextFormField(
          controller: _memoController,
          maxLines: 3,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: l10n.goalMemoHint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Icon(
                Icons.notes_outlined,
                color: Theme.of(context).colorScheme.tertiary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Future<void> _selectDate(
    BuildContext context, {
    required DateTime? initial,
    required DateTime firstDate,
    required DateTime lastDate,
    required void Function(DateTime) onPicked,
  }) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      onPicked(picked);
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

    setState(() => _isLoading = true);
    final notifier = ref.read(assetGoalNotifierProvider(ledgerId).notifier);

    try {
      final loanAmountText =
          _loanAmountController.text.replaceAll(RegExp(r'[^\d]'), '');
      final loanAmount = int.tryParse(loanAmountText) ?? 0;
      final annualInterestRate = double.tryParse(_interestRateController.text);

      int? monthlyPayment;
      if (_isManualPayment) {
        final mpText =
            _monthlyPaymentController.text.replaceAll(RegExp(r'[^\d]'), '');
        monthlyPayment = int.tryParse(mpText);
      } else {
        monthlyPayment = _calculatedMonthlyPayment;
      }

      final memo = _memoController.text.trim().isEmpty
          ? null
          : _memoController.text.trim();

      if (isEditing && widget.goal != null) {
        final updated = widget.goal!.copyWith(
          title: _titleController.text.trim(),
          loanAmount: loanAmount,
          targetAmount: loanAmount,
          repaymentMethod: _repaymentMethod,
          annualInterestRate: annualInterestRate,
          startDate: _startDate,
          targetDate: _maturityDate,
          monthlyPayment: monthlyPayment,
          isManualPayment: _isManualPayment,
          goalType: GoalType.loan,
          memo: memo,
        );
        await notifier.updateGoal(updated);
      } else {
        await notifier.createLoanGoal(
          title: _titleController.text.trim(),
          loanAmount: loanAmount,
          repaymentMethod: _repaymentMethod,
          annualInterestRate: annualInterestRate,
          startDate: _startDate,
          targetDate: _maturityDate,
          monthlyPayment: monthlyPayment,
          isManualPayment: _isManualPayment,
          memo: memo,
        );
      }

      if (context.mounted) {
        ref.invalidate(assetGoalsProvider);
        Navigator.pop(context);
        SnackBarUtils.showSuccess(
          context,
          isEditing ? l10n.loanGoalUpdated : l10n.loanGoalCreated,
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _repaymentMethodLabel(AppLocalizations l10n, RepaymentMethod method) {
    switch (method) {
      case RepaymentMethod.equalPrincipalInterest:
        return l10n.repaymentMethodEqualPrincipalInterest;
      case RepaymentMethod.equalPrincipal:
        return l10n.repaymentMethodEqualPrincipal;
      case RepaymentMethod.bullet:
        return l10n.repaymentMethodBullet;
      case RepaymentMethod.graduated:
        return l10n.repaymentMethodGraduated;
    }
  }
}

class _AmountInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    final cleanText = newValue.text.replaceAll(',', '');
    if (cleanText.length > 14) return oldValue;
    final number = int.tryParse(cleanText);
    if (number == null) return oldValue;
    final formatter = NumberFormat('#,###');
    final formatted = formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
