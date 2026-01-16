import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_provider.dart';
import 'category_section_widget.dart';
import 'payment_method_selector_widget.dart';
import 'transaction_form_fields.dart';

/// 기존 거래를 수정하는 Bottom Sheet
class EditTransactionSheet extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionSheet({super.key, required this.transaction});

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
  Category? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // 기존 거래 데이터로 초기화
    _type = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _amountController.text = NumberFormat(
      '#,###',
    ).format(widget.transaction.amount);
    _titleController.text = widget.transaction.title ?? '';
    _memoController.text = widget.transaction.memo ?? '';

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

    // 카테고리 Provider에서 현재 카테고리 찾기
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
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = int.parse(
        _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
      );

      await ref
          .read(transactionNotifierProvider.notifier)
          .updateTransaction(
            id: widget.transaction.id,
            categoryId: _selectedCategory?.id,
            paymentMethodId: _selectedPaymentMethod?.id,
            amount: amount,
            type: _type,
            date: _selectedDate,
            title: _titleController.text.isNotEmpty
                ? _titleController.text
                : null,
            memo: _memoController.text.isNotEmpty ? _memoController.text : null,
          );

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.transactionUpdated),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

                      DateSelectorTile(
                        selectedDate: _selectedDate,
                        onTap: _selectDate,
                      ),

                      const Divider(),

                      CategorySectionWidget(
                        isFixedExpense: false,
                        selectedCategory: _selectedCategory,
                        selectedFixedExpenseCategory: null,
                        transactionType: _type,
                        onCategorySelected: (c) =>
                            setState(() => _selectedCategory = c),
                        onFixedExpenseCategorySelected: (_) {},
                        enabled: !_isLoading,
                      ),

                      const SizedBox(height: Spacing.md),
                      const Divider(),

                      // 결제수단 선택 (지출일 때만)
                      if (_type == 'expense') ...[
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
                        const SizedBox(height: Spacing.md),
                        const Divider(),
                      ],

                      MemoInputSection(controller: _memoController),

                      const SizedBox(height: 100),
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
