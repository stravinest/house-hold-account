import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../../domain/entities/transaction.dart';
import '../providers/transaction_provider.dart';

/// 기존 거래를 수정하는 Bottom Sheet
class EditTransactionSheet extends ConsumerStatefulWidget {
  final Transaction transaction;

  const EditTransactionSheet({
    super.key,
    required this.transaction,
  });

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
    _amountController.text =
        NumberFormat('#,###').format(widget.transaction.amount);
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
      final amount =
          int.parse(_amountController.text.replaceAll(RegExp(r'[^\d]'), ''));

      await ref.read(transactionNotifierProvider.notifier).updateTransaction(
            id: widget.transaction.id,
            categoryId: _selectedCategory?.id,
            paymentMethodId: _selectedPaymentMethod?.id,
            amount: amount,
            type: _type,
            date: _selectedDate,
            title:
                _titleController.text.isNotEmpty ? _titleController.text : null,
            memo:
                _memoController.text.isNotEmpty ? _memoController.text : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래가 수정되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
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
    final colorScheme = Theme.of(context).colorScheme;
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // 헤더
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('취소'),
                      ),
                      const Text(
                        '거래 수정',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('저장'),
                      ),
                    ],
                  ),
                ),

                const Divider(),

                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 수입/지출/저축 선택
                        SegmentedButton<String>(
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
                              value: 'saving',
                              label: Text('저축'),
                              icon: Icon(Icons.savings_outlined),
                            ),
                          ],
                          selected: {_type},
                          onSelectionChanged: (selected) {
                            setState(() {
                              _type = selected.first;
                              _selectedCategory = null;
                              if (_type == 'income' || _type == 'saving') {
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
                          decoration: const InputDecoration(
                            labelText: '제목',
                            hintText: '예: 점심식사, 월급',
                            prefixIcon: Icon(Icons.edit),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '제목을 입력해주세요';
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
                            _AmountInputFormatter(),
                          ],
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            suffixText: '원',
                            suffixStyle: TextStyle(fontSize: 18),
                            border: InputBorder.none,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty || value == '0') {
                              return '금액을 입력해주세요';
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
                            DateFormat('yyyy년 M월 d일 (E)', 'ko_KR')
                                .format(_selectedDate),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _selectDate,
                        ),

                        const Divider(),

                        // 카테고리 선택
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '카테고리',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),

                        categoriesAsync.when(
                          data: (categories) =>
                              _buildCategoryChips(categories),
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (e, _) => Text('오류: $e'),
                        ),

                        const SizedBox(height: 16),
                        const Divider(),

                        // 결제수단 선택 (지출일 때만)
                        if (_type == 'expense') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              '결제수단 (선택)',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          paymentMethodsAsync.when(
                            data: (paymentMethods) =>
                                _buildPaymentMethodChips(paymentMethods),
                            loading: () => const Center(
                                child: CircularProgressIndicator()),
                            error: (e, _) => Text('오류: $e'),
                          ),
                          const SizedBox(height: 16),
                          const Divider(),
                        ],

                        // 메모 입력 (선택)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '메모 (선택)',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        TextFormField(
                          controller: _memoController,
                          maxLines: 3,
                          keyboardType: TextInputType.text,
                          decoration: const InputDecoration(
                            hintText: '추가 메모를 입력하세요',
                            border: OutlineInputBorder(),
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
        );
      },
    );
  }

  Widget _buildCategoryChips(List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 안함 옵션
        FilterChip(
          selected: _selectedCategory == null,
          showCheckmark: false,
          label: const Text('선택 안함'),
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
          );
        }),
      ],
    );
  }

  Widget _buildPaymentMethodChips(List<PaymentMethod> paymentMethods) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 해제 옵션
        FilterChip(
          selected: _selectedPaymentMethod == null,
          showCheckmark: false,
          label: const Text('선택 안함'),
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
          );
        }),
      ],
    );
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
