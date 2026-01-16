import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final locale = Localizations.localeOf(context).languageCode;
    final categoriesAsync = _type == 'expense'
        ? ref.watch(expenseCategoriesProvider)
        : _type == 'income'
        ? ref.watch(incomeCategoriesProvider)
        : ref.watch(savingCategoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

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
                        // 수입/지출/자산 선택
                        SegmentedButton<String>(
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
                          selected: {_type},
                          onSelectionChanged: (selected) {
                            setState(() {
                              _type = selected.first;
                              _selectedCategory = null;
                              if (_type == 'income' || _type == 'asset') {
                                _selectedPaymentMethod = null;
                              }
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // 제목 입력
                        TextFormField(
                          controller: _titleController,
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: l10n.transactionTitle,
                            hintText: l10n.categoryNameHintExample,
                            prefixIcon: const Icon(Icons.edit),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.transactionTitleRequired;
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),

                        // 금액 입력
                        TextFormField(
                          controller: _amountController,
                          focusNode: _amountFocusNode,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            _AmountInputFormatter(locale),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            suffixText: l10n.transactionAmountUnit,
                            suffixStyle: const TextStyle(fontSize: 18),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.isEmpty ||
                                value == '0') {
                              return l10n.transactionAmountRequired;
                            }
                            return null;
                          },
                        ),

                        const Divider(),
                        const SizedBox(height: 16),

                        // 날짜 선택
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            locale == 'ko'
                                ? DateFormat(
                                    'yyyy년 M월 d일 (E)',
                                    'ko_KR',
                                  ).format(_selectedDate)
                                : DateFormat(
                                    'MMMM d, yyyy (E)',
                                    'en_US',
                                  ).format(_selectedDate),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _selectDate,
                        ),

                        const Divider(),

                        // 카테고리 선택
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.transactionCategory,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),

                        categoriesAsync.when(
                          data: (categories) =>
                              _buildCategoryChips(categories, l10n),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) =>
                              Text(l10n.errorWithMessage(e.toString())),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // 결제수단 선택 (지출일 때만)
                        if (_type == 'expense') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              l10n.transactionPaymentMethod,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          paymentMethodsAsync.when(
                            data: (paymentMethods) =>
                                _buildPaymentMethodChips(paymentMethods, l10n),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (e, _) =>
                                Text(l10n.errorWithMessage(e.toString())),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],

                        // 메모 입력 (선택)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            l10n.transactionMemoOptional,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextFormField(
                          controller: _memoController,
                          maxLines: 3,
                          keyboardType: TextInputType.text,
                          decoration: InputDecoration(
                            hintText: l10n.transactionMemoHint,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<Category> categories, AppLocalizations l10n) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 안함 옵션
        FilterChip(
          selected: _selectedCategory == null,
          showCheckmark: false,
          label: Text(l10n.transactionNone),
          onSelected: (_) {
            setState(() => _selectedCategory = null);
          },
        ),
        ...categories.map((category) {
          final isSelected = _selectedCategory?.id == category.id;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (category.icon.isNotEmpty) ...[
                  Text(category.icon),
                  const SizedBox(width: 4),
                ],
                Text(category.name),
              ],
            ),
            onSelected: (_) {
              setState(() => _selectedCategory = category);
            },
            onDeleted: () => _deleteCategory(category),
            deleteIcon: const Icon(Icons.close, size: 18),
          );
        }),
        // 카테고리 추가 버튼
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.commonAdd),
          onPressed: () => _showAddCategoryDialog(),
        ),
      ],
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.categoryDeleteConfirmTitle),
        content: Text(l10n.categoryDeleteConfirm(category.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);

      if (_selectedCategory?.id == category.id) {
        setState(() => _selectedCategory = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.categoryDeleted),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(savingCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // 랜덤 색상 생성
  String _generateRandomColor() {
    final colors = [
      '#4CAF50',
      '#2196F3',
      '#F44336',
      '#FF9800',
      '#9C27B0',
      '#00BCD4',
      '#E91E63',
      '#795548',
      '#607D8B',
      '#3F51B5',
      '#009688',
      '#CDDC39',
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }

  // 카테고리 추가 다이얼로그
  void _showAddCategoryDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    final typeLabel = _type == 'expense'
        ? l10n.transactionExpense
        : _type == 'income'
        ? l10n.transactionIncome
        : l10n.transactionAsset;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.categoryAddType(typeLabel)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.categoryName,
            hintText: l10n.categoryNameHintExample,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCategory(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => _submitCategory(dialogContext, nameController),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCategory(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.categoryNameRequired),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final newCategory = await ref
          .read(categoryNotifierProvider.notifier)
          .createCategory(
            name: nameController.text.trim(),
            icon: '',
            color: _generateRandomColor(),
            type: _type,
          );

      setState(() => _selectedCategory = newCategory);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.categoryAdded),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
      ref.invalidate(savingCategoriesProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Widget _buildPaymentMethodChips(
    List<PaymentMethod> paymentMethods,
    AppLocalizations l10n,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 해제 옵션
        FilterChip(
          selected: _selectedPaymentMethod == null,
          showCheckmark: false,
          label: Text(l10n.transactionNone),
          onSelected: (_) {
            setState(() => _selectedPaymentMethod = null);
          },
        ),
        ...paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod?.id == method.id;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(method.name),
            onSelected: (_) {
              setState(() => _selectedPaymentMethod = method);
            },
            onDeleted: () => _deletePaymentMethod(method),
            deleteIcon: const Icon(Icons.close, size: 18),
          );
        }),
        // 결제수단 추가 버튼
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: Text(l10n.commonAdd),
          onPressed: () => _showAddPaymentMethodDialog(),
        ),
      ],
    );
  }

  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentMethodDeleteConfirmTitle),
        content: Text(l10n.paymentMethodDeleteConfirm(method.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .deletePaymentMethod(method.id);

      if (_selectedPaymentMethod?.id == method.id) {
        setState(() => _selectedPaymentMethod = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentMethodDeleted),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  // 결제수단 추가 다이얼로그
  void _showAddPaymentMethodDialog() {
    final l10n = AppLocalizations.of(context)!;
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentMethodAdd),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodName,
            hintText: l10n.paymentMethodNameHintExample,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (_) =>
              _submitPaymentMethod(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                _submitPaymentMethod(dialogContext, nameController),
            child: Text(l10n.commonAdd),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPaymentMethod(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.paymentMethodNameRequired),
          duration: const Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final newPaymentMethod = await ref
          .read(paymentMethodNotifierProvider.notifier)
          .createPaymentMethod(
            name: nameController.text.trim(),
            icon: '',
            color: _generateRandomColor(),
          );

      setState(() => _selectedPaymentMethod = newPaymentMethod);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.paymentMethodAdded),
            duration: const Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }
}

// 금액 포맷터 (천 단위 구분)
class _AmountInputFormatter extends TextInputFormatter {
  final String locale;

  _AmountInputFormatter(this.locale);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) return oldValue;

    final formatter = NumberFormat('#,###', locale == 'ko' ? 'ko_KR' : 'en_US');
    final formatted = formatter.format(number);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
