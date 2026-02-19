import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../fixed_expense/domain/entities/fixed_expense_category.dart';
import '../../../fixed_expense/presentation/providers/fixed_expense_category_provider.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../../domain/entities/transaction.dart';
import '../providers/recurring_template_provider.dart';
import '../providers/transaction_provider.dart';
import 'category_section_widget.dart';
import 'payment_method_selector_widget.dart';
import 'transaction_form_fields.dart';

/// 기존 거래를 수정하는 Bottom Sheet
/// [recurringTemplateId]가 설정되면 반복 거래 템플릿 수정 모드로 동작
class EditTransactionSheet extends ConsumerStatefulWidget {
  final Transaction transaction;
  final String? recurringTemplateId;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
    this.recurringTemplateId,
  });

  bool get isTemplateMode => recurringTemplateId != null;

  @override
  ConsumerState<EditTransactionSheet> createState() =>
      _EditTransactionSheetState();
}

class _EditTransactionSheetState extends ConsumerState<EditTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountFocusNode = FocusNode();

  late String _type;
  late bool _isFixedExpense;
  Category? _selectedCategory;
  FixedExpenseCategory? _selectedFixedExpenseCategory;
  PaymentMethod? _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isInitialized = false;

  // 반복 템플릿 수정 모드 전용
  late String _recurringType;
  DateTime? _recurringEndDate;
  bool _hasRecurringEndDate = false;

  bool get _isTemplateMode => widget.isTemplateMode;

  @override
  void initState() {
    super.initState();
    // 기존 거래 데이터로 초기화
    _type = widget.transaction.type;
    _isFixedExpense = widget.transaction.isFixedExpense;
    _selectedDate = widget.transaction.date;
    _amountController.text = NumberFormat(
      '#,###',
    ).format(widget.transaction.amount);
    _titleController.text = widget.transaction.title ?? '';
    _memoController.text = widget.transaction.memo ?? '';

    // 반복 템플릿 모드 초기화
    _recurringType = widget.transaction.recurringType ?? 'monthly';
    _recurringEndDate = widget.transaction.recurringEndDate;
    _hasRecurringEndDate = _recurringEndDate != null;

    // 금액 필드 포커스 시 전체 선택
    _amountFocusNode.addListener(_onAmountFocusChange);
  }

  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      _amountController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _amountController.text.length,
      );
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

  void _initializeSelections() {
    if (_isInitialized) return;
    _isInitialized = true;

    // 고정비 카테고리 초기화
    if (_isFixedExpense && widget.transaction.fixedExpenseCategoryId != null) {
      final fixedCategoriesAsync = ref.read(fixedExpenseCategoriesProvider);
      fixedCategoriesAsync.whenData((categories) {
        final category = categories.cast<FixedExpenseCategory?>().firstWhere(
          (c) => c?.id == widget.transaction.fixedExpenseCategoryId,
          orElse: () => null,
        );
        if (category != null && mounted) {
          setState(() => _selectedFixedExpenseCategory = category);
        }
      });
    }

    // 일반 카테고리 Provider에서 현재 카테고리 찾기
    final categoriesAsync = _type == 'expense'
        ? ref.read(expenseCategoriesProvider)
        : _type == 'income'
        ? ref.read(incomeCategoriesProvider)
        : ref.read(savingCategoriesProvider);

    categoriesAsync.whenData((categories) {
      if (widget.transaction.categoryId != null) {
        final category = categories.cast<Category?>().firstWhere(
          (c) => c?.id == widget.transaction.categoryId,
          orElse: () => null,
        );
        if (category != null && mounted) {
          setState(() => _selectedCategory = category);
        }
      }
    });

    // 결제수단 Provider에서 현재 결제수단 찾기
    final paymentMethodsAsync = ref.read(paymentMethodNotifierProvider);
    paymentMethodsAsync.whenData((methods) {
      if (widget.transaction.paymentMethodId != null) {
        final method = methods.cast<PaymentMethod?>().firstWhere(
          (m) => m?.id == widget.transaction.paymentMethodId,
          orElse: () => null,
        );
        if (method != null && mounted) {
          setState(() => _selectedPaymentMethod = method);
        }
      }
    });
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: Localizations.localeOf(context),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Widget _buildLockedTypeIndicator(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 타입 라벨 결정
    final typeLabel = switch (_type) {
      'income' => l10n.transactionIncome,
      'asset' => l10n.transactionAsset,
      _ => l10n.classificationExpense,
    };

    final label = _isFixedExpense
        ? '$typeLabel - ${l10n.classificationFixedExpense}'
        : typeLabel;

    final fgColor = _isFixedExpense
        ? (isDark
            ? FixedExpenseColors.darkForeground
            : FixedExpenseColors.lightForeground)
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final bgColor = _isFixedExpense
        ? (isDark
            ? FixedExpenseColors.darkBackground
            : FixedExpenseColors.lightBackground)
        : Theme.of(context).colorScheme.surfaceContainerHighest;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        border: Border.all(color: fgColor, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 16, color: fgColor),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w600, color: fgColor),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringTypeSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.recurringTemplateEditRecurringType,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: Spacing.sm),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'daily',
              label: Text(l10n.recurringTypeDaily),
            ),
            ButtonSegment(
              value: 'monthly',
              label: Text(l10n.recurringTypeMonthly),
            ),
            ButtonSegment(
              value: 'yearly',
              label: Text(l10n.recurringTypeYearly),
            ),
          ],
          selected: {_recurringType},
          onSelectionChanged: (selected) =>
              setState(() => _recurringType = selected.first),
        ),
        const SizedBox(height: Spacing.md),
      ],
    );
  }

  Widget _buildRecurringEndDateSection(AppLocalizations l10n) {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(l10n.recurringTemplateEditEndDate),
          subtitle: _hasRecurringEndDate && _recurringEndDate != null
              ? Text(DateFormat('yyyy-MM-dd').format(_recurringEndDate!))
              : Text(l10n.recurringTemplateEditNoEndDate),
          value: _hasRecurringEndDate,
          onChanged: (value) async {
            if (value) {
              final picked = await showDatePicker(
                context: context,
                initialDate: _recurringEndDate ?? DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _hasRecurringEndDate = true;
                  _recurringEndDate = picked;
                });
              }
            } else {
              setState(() {
                _hasRecurringEndDate = false;
                _recurringEndDate = null;
              });
            }
          },
        ),
        if (_hasRecurringEndDate)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _recurringEndDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() => _recurringEndDate = picked);
                }
              },
              icon: const Icon(Icons.calendar_today, size: 16),
              label: Text(l10n.recurringTemplateEditSetEndDate),
            ),
          ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = int.parse(
        _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
      );
      final titleText = _titleController.text.trim();
      final memoText = _memoController.text.trim();

      if (_isTemplateMode) {
        await _submitTemplate(amount, titleText, memoText);
      } else {
        await _submitTransaction(amount, titleText, memoText);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _submitTransaction(
    int amount,
    String titleText,
    String memoText,
  ) async {
    await ref
        .read(transactionNotifierProvider.notifier)
        .updateTransaction(
          id: widget.transaction.id,
          categoryId: _isFixedExpense ? null : _selectedCategory?.id,
          paymentMethodId: _selectedPaymentMethod?.id,
          amount: amount,
          type: _type,
          date: _selectedDate,
          title: titleText.isNotEmpty ? titleText : null,
          memo: memoText.isNotEmpty ? memoText : null,
          isFixedExpense: _isFixedExpense,
          fixedExpenseCategoryId: _isFixedExpense
              ? _selectedFixedExpenseCategory?.id
              : null,
        );

    if (mounted) {
      final l10n = AppLocalizations.of(context);
      Navigator.pop(context);
      SnackBarUtils.showSuccess(context, l10n.transactionUpdated);
    }
  }

  Future<void> _submitTemplate(
    int amount,
    String titleText,
    String memoText,
  ) async {
    await ref
        .read(recurringTemplateNotifierProvider.notifier)
        .update(
          widget.recurringTemplateId!,
          amount: amount,
          title: titleText.isNotEmpty ? titleText : null,
          memo: memoText.isNotEmpty ? memoText : null,
          recurringType: _recurringType,
          endDate: _hasRecurringEndDate ? _recurringEndDate : null,
          clearEndDate: !_hasRecurringEndDate,
          categoryId: _isFixedExpense ? null : _selectedCategory?.id,
          paymentMethodId: _selectedPaymentMethod?.id,
          fixedExpenseCategoryId: _isFixedExpense
              ? _selectedFixedExpenseCategory?.id
              : null,
        );

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    // 시스템 네비게이션 바 높이 + 키보드 높이 감지
    final viewInsets = MediaQuery.of(context).viewInsets;
    final viewPadding = MediaQuery.of(context).viewPadding;
    final bottomPadding = viewInsets.bottom > 0
        ? viewInsets.bottom
        : viewPadding.bottom;

    // 카테고리/결제수단 초기값 설정
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelections();
    });

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

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 타입 선택: 템플릿 모드에서는 비활성화 (잠금 표시)
                      if (_isTemplateMode || _isFixedExpense)
                        _buildLockedTypeIndicator(context)
                      else
                        TransactionTypeSelector(
                          selectedType: _type,
                          onTypeChanged: (t) => setState(() {
                            _type = t;
                            _selectedCategory = null;
                            if (t == 'income' || t == 'asset') {
                              _selectedPaymentMethod = null;
                            }
                          }),
                        ),

                      const SizedBox(height: 24),

                      TitleInputField(controller: _titleController),

                      const SizedBox(height: 16),

                      // 금액 입력
                      AmountInputField(
                        controller: _amountController,
                        focusNode: _amountFocusNode,
                        isInstallmentMode: false,
                      ),

                      const Divider(),
                      const SizedBox(height: 16),

                      // 템플릿 모드: 반복주기 표시 / 일반 모드: 날짜 선택
                      if (_isTemplateMode) ...[
                        _buildRecurringTypeSection(l10n),
                        const Divider(),
                        _buildRecurringEndDateSection(l10n),
                        const Divider(),
                      ] else ...[
                        DateSelectorTile(
                          selectedDate: _selectedDate,
                          onTap: _selectDate,
                        ),
                        const Divider(),
                      ],

                      CategorySectionWidget(
                        isFixedExpense: _isFixedExpense,
                        selectedCategory: _selectedCategory,
                        selectedFixedExpenseCategory:
                            _selectedFixedExpenseCategory,
                        transactionType: _type,
                        onCategorySelected: (c) =>
                            setState(() => _selectedCategory = c),
                        onFixedExpenseCategorySelected: (c) =>
                            setState(
                                () => _selectedFixedExpenseCategory = c),
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: Spacing.md),
                      const Divider(),

                      // 결제수단 선택 (지출일 때만)
                      if (_type == 'expense') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Spacing.sm,
                          ),
                          child: Text(
                            l10n.paymentMethodTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        PaymentMethodSelectorWidget(
                          selectedPaymentMethod: _selectedPaymentMethod,
                          onPaymentMethodSelected: (m) =>
                              setState(() => _selectedPaymentMethod = m),
                          enabled: !_isLoading,
                        ),
                        const SizedBox(height: Spacing.md),
                        const Divider(),
                      ],

                      MemoInputSection(controller: _memoController),

                      // 키보드가 올라왔을 때 충분한 스크롤 공간 확보
                      SizedBox(height: bottomPadding + Spacing.xl),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
