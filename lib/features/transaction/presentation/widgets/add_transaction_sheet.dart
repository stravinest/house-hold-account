import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../providers/transaction_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;
  /// 위젯 딥링크에서 전달받는 초기 거래 타입
  /// 'expense' 또는 'income'
  final String? initialType;

  const AddTransactionSheet({
    super.key,
    this.initialDate,
    this.initialType,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();
  final _amountFocusNode = FocusNode();

  String _type = 'expense';
  Category? _selectedCategory;
  PaymentMethod? _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
    // 초기 거래 타입 설정 (위젯 딥링크에서 전달받은 경우)
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    // 초기 금액을 '0'으로 설정
    _amountController.text = '0';
    // 금액 필드 포커스 시 전체 선택
    _amountFocusNode.addListener(_onAmountFocusChange);
  }

  void _onAmountFocusChange() {
    if (_amountFocusNode.hasFocus) {
      // 포커스를 얻었을 때
      if (_amountController.text == '0') {
        _amountController.clear();
      } else {
        _amountController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _amountController.text.length,
        );
      }
    } else {
      // 포커스를 잃었을 때
      if (_amountController.text.isEmpty) {
        _amountController.text = '0';
      }
    }
  }

  @override
  void dispose() {
    _amountFocusNode.removeListener(_onAmountFocusChange);
    _amountFocusNode.dispose();
    _amountController.dispose();
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

      await ref.read(transactionNotifierProvider.notifier).createTransaction(
            categoryId: _selectedCategory?.id,
            paymentMethodId: _selectedPaymentMethod?.id,
            amount: amount,
            type: _type,
            date: _selectedDate,
            memo: _memoController.text.isNotEmpty ? _memoController.text : null,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('거래가 추가되었습니다')),
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
        : ref.watch(incomeCategoriesProvider);
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);

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
                        '거래 추가',
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
                        // 수입/지출 선택
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
                          ],
                          selected: {_type},
                          onSelectionChanged: (selected) {
                            setState(() {
                              _type = selected.first;
                              _selectedCategory = null;
                            });
                          },
                        ),

                        const SizedBox(height: 24),

                        // 지출명/내용 입력
                        TextFormField(
                          controller: _memoController,
                          maxLines: 1,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: _type == 'expense' ? '지출명' : '수입명',
                            hintText: _type == 'expense' ? '예: 점심식사, 커피' : '예: 월급, 용돈',
                            prefixIcon: const Icon(Icons.edit),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return _type == 'expense' ? '지출명을 입력해주세요' : '수입명을 입력해주세요';
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
                          data: (categories) => _buildCategoryGrid(categories),
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

  Widget _buildCategoryGrid(List<Category> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 안함 옵션
        FilterChip(
          selected: _selectedCategory == null,
          label: const Text('선택 안함'),
          onSelected: (_) {
            setState(() => _selectedCategory = null);
          },
        ),
        ...categories.map((category) {
          final isSelected = _selectedCategory?.id == category.id;
          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(category.icon),
                const SizedBox(width: 4),
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
          label: const Text('추가'),
          onPressed: () => _showAddCategoryDialog(),
        ),
      ],
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedIcon = '';
    String selectedColor = '#4CAF50';

    final icons = ['', '', '', '', '', '', '', ''];
    final colors = ['#4CAF50', '#2196F3', '#F44336', '#FF9800', '#9C27B0', '#00BCD4', '#E91E63', '#795548'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${_type == 'expense' ? '지출' : '수입'} 카테고리 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '카테고리 이름',
                    hintText: '예: 식비, 교통비',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('아이콘'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('색상'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                              int.parse(color.substring(1), radix: 16) + 0xFF000000),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('카테고리 이름을 입력해주세요')),
                  );
                  return;
                }
                if (selectedIcon.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('아이콘을 선택해주세요')),
                  );
                  return;
                }

                try {
                  final newCategory = await ref
                      .read(categoryNotifierProvider.notifier)
                      .createCategory(
                        name: nameController.text.trim(),
                        icon: selectedIcon,
                        color: selectedColor,
                        type: _type,
                      );

                  // 새로 만든 카테고리 자동 선택
                  setState(() => _selectedCategory = newCategory);

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('카테고리가 추가되었습니다')),
                    );
                  }

                  // 카테고리 목록 새로고침
                  ref.invalidate(categoriesProvider);
                  ref.invalidate(incomeCategoriesProvider);
                  ref.invalidate(expenseCategoriesProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('카테고리 삭제'),
        content: Text('\'${category.name}\' 카테고리를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(categoryNotifierProvider.notifier).deleteCategory(category.id);

      if (_selectedCategory?.id == category.id) {
        setState(() => _selectedCategory = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('카테고리가 삭제되었습니다')),
        );
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Widget _buildPaymentMethodChips(List<PaymentMethod> paymentMethods) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 해제 옵션
        FilterChip(
          selected: _selectedPaymentMethod == null,
          label: const Text('선택 안함'),
          onSelected: (_) {
            setState(() => _selectedPaymentMethod = null);
          },
        ),
        ...paymentMethods.map((method) {
          final isSelected = _selectedPaymentMethod?.id == method.id;
          return FilterChip(
            selected: isSelected,
            avatar: method.icon.isNotEmpty
                ? Text(method.icon)
                : CircleAvatar(
                    backgroundColor: _parseColor(method.color),
                    radius: 10,
                    child: const Icon(Icons.credit_card, size: 12, color: Colors.white),
                  ),
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
          label: const Text('추가'),
          onPressed: () => _showAddPaymentMethodDialog(),
        ),
      ],
    );
  }

  void _showAddPaymentMethodDialog() {
    final nameController = TextEditingController();
    String selectedIcon = '💳';
    String selectedColor = '#6750A4';

    final icons = ['💳', '💰', '🏦', '📱', '🪙', '💵', '💴', '💶'];
    final colors = ['#6750A4', '#2196F3', '#4CAF50', '#FF9800', '#E91E63', '#00BCD4', '#9C27B0', '#795548'];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('결제수단 추가'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: '결제수단 이름',
                    hintText: '예: 신용카드, 현금, 체크카드',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('아이콘'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: icons.map((icon) {
                    final isSelected = icon == selectedIcon;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIcon = icon),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primaryContainer
                              : Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                )
                              : null,
                        ),
                        child: Center(
                          child: Text(icon, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('색상'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: colors.map((color) {
                    final isSelected = color == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Color(
                              int.parse(color.substring(1), radix: 16) + 0xFF000000),
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('결제수단 이름을 입력해주세요')),
                  );
                  return;
                }

                try {
                  final newPaymentMethod = await ref
                      .read(paymentMethodNotifierProvider.notifier)
                      .createPaymentMethod(
                        name: nameController.text.trim(),
                        icon: selectedIcon,
                        color: selectedColor,
                      );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }

                  setState(() => _selectedPaymentMethod = newPaymentMethod);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('결제수단이 추가되었습니다')),
                    );
                  }

                  // 결제수단 목록 새로고침
                  ref.invalidate(paymentMethodsProvider);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('오류: $e')),
                    );
                  }
                }
              },
              child: const Text('추가'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePaymentMethod(PaymentMethod method) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('결제수단 삭제'),
        content: Text('\'${method.name}\' 결제수단을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(paymentMethodNotifierProvider.notifier).deletePaymentMethod(method.id);

      if (_selectedPaymentMethod?.id == method.id) {
        setState(() => _selectedPaymentMethod = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제수단이 삭제되었습니다')),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(int.parse(colorString.substring(1), radix: 16) + 0xFF000000);
      }
      return Color(int.parse(colorString));
    } catch (e) {
      return Colors.grey;
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
