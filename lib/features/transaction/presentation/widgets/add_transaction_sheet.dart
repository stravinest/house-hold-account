import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../fixed_expense/domain/entities/fixed_expense_category.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../providers/transaction_provider.dart';
import 'category_section_widget.dart';
import 'installment_input_widget.dart';
import 'payment_method_selector_widget.dart';
import 'recurring_settings_widget.dart';
import 'transaction_form_fields.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  final String? initialType;

  const AddTransactionSheet({super.key, this.initialDate, this.initialType});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _type = 'expense';
  Category? _selectedCategory;
  FixedExpenseCategory? _selectedFixedExpenseCategory;
  PaymentMethod? _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isLoading = false;
  RecurringSettings _recurringSettings = const RecurringSettings(
    type: RecurringType.none,
  );
  InstallmentResult? _installmentResult;
  bool _isInstallmentMode = false;
  DateTime? _maturityDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    if (widget.initialType != null) _type = widget.initialType!;
    _amountController.text = '0';
    _amountFocusNode.addListener(_onAmountFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).loadCategories();
      ref.read(paymentMethodNotifierProvider.notifier).loadPaymentMethods();
    });
  }

  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      _amountController.text == '0'
          ? _amountController.clear()
          : _amountController.selection = TextSelection(
              baseOffset: 0,
              extentOffset: _amountController.text.length,
            );
    } else if (_amountController.text.isEmpty) {
      _amountController.text = '0';
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _amountFocusNode.dispose();
    _amountController.dispose();
    _titleController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('ko', 'KR'),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectMaturityDate() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _maturityDate ?? DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 30)),
      helpText: l10n.maturityDateSelect,
    );
    if (picked != null) setState(() => _maturityDate = picked);
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_isInstallmentMode && _installmentResult == null) {
      SnackBarUtils.showError(context, l10n.installmentInfoRequired);
      return;
    }
    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);
      final amount = int.parse(
        _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
      );
      final title = _titleController.text.isNotEmpty
          ? _titleController.text
          : null;
      final memo = _memoController.text.isNotEmpty
          ? _memoController.text
          : null;
      String successMessage;

      if (_isInstallmentMode && _installmentResult != null) {
        await notifier.createRecurringTemplate(
          categoryId: _selectedCategory?.id,
          paymentMethodId: _selectedPaymentMethod?.id,
          amount: _installmentResult!.baseAmount,
          type: _type,
          startDate: _selectedDate,
          endDate: _installmentResult!.endDate,
          recurringType: 'monthly',
          title: title != null
              ? '$title (${l10n.installmentLabel})'
              : l10n.installmentLabel,
          memo: memo,
        );
        successMessage = l10n.installmentRegistered(_installmentResult!.months);
      } else if (_recurringSettings.isRecurring) {
        await notifier.createRecurringTemplate(
          categoryId: _recurringSettings.isFixedExpense
              ? null
              : _selectedCategory?.id,
          paymentMethodId: _selectedPaymentMethod?.id,
          amount: amount,
          type: _type,
          startDate: _selectedDate,
          endDate: _recurringSettings.endDate,
          recurringType: _recurringSettings.recurringTypeString!,
          title: title,
          memo: memo,
          isFixedExpense: _recurringSettings.isFixedExpense,
          fixedExpenseCategoryId: _selectedFixedExpenseCategory?.id,
        );
        final endText = _recurringSettings.endDate != null
            ? l10n.recurringUntil(
                _recurringSettings.endDate!.year,
                _recurringSettings.endDate!.month,
              )
            : l10n.recurringContinue;
        successMessage = l10n.recurringRegistered(endText);
      } else {
        await notifier.createTransaction(
          categoryId: _recurringSettings.isFixedExpense
              ? null
              : _selectedCategory?.id,
          paymentMethodId: _selectedPaymentMethod?.id,
          amount: amount,
          type: _type,
          date: _selectedDate,
          title: title,
          memo: memo,
          isFixedExpense: _recurringSettings.isFixedExpense,
          fixedExpenseCategoryId: _selectedFixedExpenseCategory?.id,
          isAsset: _type == 'asset',
          maturityDate: _type == 'asset' ? _maturityDate : null,
        );
        successMessage = l10n.transactionAdded;
      }

      if (mounted) {
        final navigator = Navigator.of(context);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pop();
          SnackBarUtils.showSuccess(context, successMessage);
        });
      }
    } catch (e) {
      SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SheetHandle(),
              SheetHeader(
                onCancel: () => Navigator.pop(context),
                onSave: _submit,
                isLoading: _isLoading,
              ),
              const Divider(),
              Expanded(child: _buildFormContent(scrollController)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormContent(ScrollController scrollController) {
    // 시스템 네비게이션 바 높이를 고려한 하단 패딩
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionTypeSelector(
            selectedType: _type,
            onTypeChanged: (t) => setState(() {
              _type = t;
              _selectedCategory = null;
              if (t != 'expense') {
                _isInstallmentMode = false;
                _installmentResult = null;
                _selectedPaymentMethod = null;
              }
            }),
          ),
          const SizedBox(height: Spacing.lg),
          TitleInputField(controller: _titleController),
          const SizedBox(height: Spacing.md),
          if (_installmentResult == null) ...[
            AmountInputField(
              controller: _amountController,
              focusNode: _amountFocusNode,
              isInstallmentMode: _isInstallmentMode,
            ),
            const Divider(),
          ],
          if (_type == 'expense') ...[
            const SizedBox(height: Spacing.md),
            _buildInstallment(),
            const Divider(),
          ],
          const SizedBox(height: Spacing.md),
          DateSelectorTile(selectedDate: _selectedDate, onTap: _selectDate),
          const Divider(),
          if (_type == 'asset') ...[
            MaturityDateTile(
              maturityDate: _maturityDate,
              onTap: _selectMaturityDate,
              onClear: () => setState(() => _maturityDate = null),
            ),
            const Divider(),
          ],
          if (!_isInstallmentMode) ...[_buildRecurring(), const Divider()],
          CategorySectionWidget(
            isFixedExpense: _recurringSettings.isFixedExpense,
            selectedCategory: _selectedCategory,
            selectedFixedExpenseCategory: _selectedFixedExpenseCategory,
            transactionType: _type,
            onCategorySelected: (c) => setState(() => _selectedCategory = c),
            onFixedExpenseCategorySelected: (c) =>
                setState(() => _selectedFixedExpenseCategory = c),
            enabled: !_isLoading,
          ),
          const SizedBox(height: Spacing.md),
          const Divider(),
          if (_type == 'expense') ...[
            _buildPaymentSection(),
            const SizedBox(height: Spacing.md),
            const Divider(),
          ],
          MemoInputSection(controller: _memoController),
          // 시스템 네비게이션 바 높이 + 여유 공간
          SizedBox(height: bottomPadding + Spacing.xxl),
        ],
      ),
    );
  }

  Widget _buildInstallment() => InstallmentInputWidget(
    startDate: _selectedDate,
    enabled: !_isLoading,
    onModeChanged: (isOn) => setState(() {
      _isInstallmentMode = isOn;
      if (!isOn) _installmentResult = null;
      if (isOn) {
        _recurringSettings = const RecurringSettings(type: RecurringType.none);
      }
    }),
    onApplied: (result) => setState(() {
      _installmentResult = result;
      _recurringSettings = const RecurringSettings(type: RecurringType.none);
    }),
  );

  Widget _buildRecurring() => RecurringSettingsWidget(
    startDate: _selectedDate,
    initialSettings: _recurringSettings,
    enabled: !_isLoading,
    transactionType: _type,
    onChanged: (settings) => setState(() {
      if (settings.isFixedExpense != _recurringSettings.isFixedExpense) {
        settings.isFixedExpense
            ? _selectedCategory = null
            : _selectedFixedExpenseCategory = null;
      }
      _recurringSettings = settings;
    }),
  );

  Widget _buildPaymentSection() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Text(
            l10n.transactionPaymentMethodOptional,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        PaymentMethodSelectorWidget(
          selectedPaymentMethod: _selectedPaymentMethod,
          onPaymentMethodSelected: (m) =>
              setState(() => _selectedPaymentMethod = m),
          enabled: !_isLoading,
        ),
      ],
    );
  }
}
