import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../payment_method/domain/entities/payment_method.dart';
import '../../../payment_method/presentation/providers/payment_method_provider.dart';
import '../providers/transaction_provider.dart';
import 'installment_input_widget.dart';
import 'recurring_settings_widget.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final DateTime? initialDate;

  /// 위젯 딥링크에서 전달받는 초기 거래 타입
  /// 'expense' 또는 'income'
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
  PaymentMethod? _selectedPaymentMethod;
  late DateTime _selectedDate;
  bool _isLoading = false;

  // 반복 주기 설정
  RecurringSettings _recurringSettings = const RecurringSettings(
    type: RecurringType.none,
  );

  // 할부 설정
  InstallmentResult? _installmentResult;
  bool _isInstallmentMode = false;

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

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _validateForm() {
    if (!_formKey.currentState!.validate()) return false;

    // 할부 모드가 아닐 때 반복 주기 유효성 검사
    if (!_isInstallmentMode && _recurringSettings.isRecurring) {
      if (_recurringSettings.endDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('반복 종료 기간을 선택해주세요')),
        );
        return false;
      }
    }

    // 할부 모드일 때 할부 결과 유효성 검사
    if (_isInstallmentMode && _installmentResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('할부 정보를 입력해주세요')),
      );
      return false;
    }

    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);

      if (_isInstallmentMode && _installmentResult != null) {
        // 할부 거래 생성
        await _createInstallmentTransactions(notifier);
      } else if (_recurringSettings.isRecurring && _recurringSettings.endDate != null) {
        // 반복 거래 생성
        await _createRecurringTransactions(notifier);
      } else {
        // 단일 거래 생성
        await _createSingleTransaction(notifier);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _createSingleTransaction(TransactionNotifier notifier) async {
    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );

    await notifier.createTransaction(
      categoryId: _selectedCategory?.id,
      paymentMethodId: _selectedPaymentMethod?.id,
      amount: amount,
      type: _type,
      date: _selectedDate,
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      memo: _memoController.text.isNotEmpty ? _memoController.text : null,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('거래가 추가되었습니다')),
      );
    }
  }

  Future<void> _createRecurringTransactions(TransactionNotifier notifier) async {
    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );

    final dates = _calculateRecurringDates(
      startDate: _selectedDate,
      endDate: _recurringSettings.endDate!,
      type: _recurringSettings.type,
    );

    // 경고: 너무 많은 거래 생성 시 확인
    if (dates.length > 100) {
      final confirmed = await _showLargeTransactionWarning(dates.length);
      if (!confirmed) return;
    }

    for (final date in dates) {
      await notifier.createTransaction(
        categoryId: _selectedCategory?.id,
        paymentMethodId: _selectedPaymentMethod?.id,
        amount: amount,
        type: _type,
        date: date,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        memo: _memoController.text.isNotEmpty ? _memoController.text : null,
        isRecurring: true,
        recurringType: _recurringSettings.recurringTypeString,
        recurringEndDate: _recurringSettings.endDate,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${dates.length}건의 거래가 추가되었습니다')),
      );
    }
  }

  Future<void> _createInstallmentTransactions(TransactionNotifier notifier) async {
    final result = _installmentResult!;

    final dates = _calculateRecurringDates(
      startDate: _selectedDate,
      endDate: result.endDate,
      type: RecurringType.monthly,
    );

    for (int i = 0; i < dates.length && i < result.monthlyAmounts.length; i++) {
      await notifier.createTransaction(
        categoryId: _selectedCategory?.id,
        paymentMethodId: _selectedPaymentMethod?.id,
        amount: result.monthlyAmounts[i],
        type: _type,
        date: dates[i],
        title: _titleController.text.isNotEmpty
            ? '${_titleController.text} (${i + 1}/${result.months})'
            : '할부 ${i + 1}/${result.months}',
        memo: _memoController.text.isNotEmpty ? _memoController.text : null,
        isRecurring: true,
        recurringType: 'monthly',
        recurringEndDate: result.endDate,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.months}건의 할부 거래가 추가되었습니다')),
      );
    }
  }

  List<DateTime> _calculateRecurringDates({
    required DateTime startDate,
    required DateTime endDate,
    required RecurringType type,
  }) {
    final dates = <DateTime>[];
    // 시간 정보 제거하여 날짜만 비교 (종료일 포함 보장)
    var current = DateTime(startDate.year, startDate.month, startDate.day);
    final endDateNormalized = DateTime(endDate.year, endDate.month, endDate.day);

    while (!current.isAfter(endDateNormalized)) {
      dates.add(current);
      switch (type) {
        case RecurringType.daily:
          current = current.add(const Duration(days: 1));
          break;
        case RecurringType.monthly:
          // 월 증가 시 일자 조정 (예: 1/31 -> 2/28)
          final nextMonth = current.month + 1;
          final nextYear = nextMonth > 12 ? current.year + 1 : current.year;
          final adjustedMonth = nextMonth > 12 ? 1 : nextMonth;
          final lastDayOfMonth = DateTime(nextYear, adjustedMonth + 1, 0).day;
          final day = current.day > lastDayOfMonth ? lastDayOfMonth : current.day;
          current = DateTime(nextYear, adjustedMonth, day);
          break;
        case RecurringType.yearly:
          // 년 증가 시 윤년 처리 (예: 2/29 -> 2/28)
          final nextYear = current.year + 1;
          final lastDayOfMonth = DateTime(nextYear, current.month + 1, 0).day;
          final day = current.day > lastDayOfMonth ? lastDayOfMonth : current.day;
          current = DateTime(nextYear, current.month, day);
          break;
        case RecurringType.none:
          break;
      }
    }
    return dates;
  }

  Future<bool> _showLargeTransactionWarning(int count) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('경고'),
        content: Text('$count건의 거래가 생성됩니다. 계속하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('계속'),
          ),
        ],
      ),
    );
    return result ?? false;
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
                      TextButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
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
                              // 수입으로 변경 시 할부 모드 해제
                              if (_type == 'income') {
                                _isInstallmentMode = false;
                                _installmentResult = null;
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

                        // 금액 입력 (할부가 적용되지 않았을 때만)
                        if (_installmentResult == null) ...[
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
                              if (_isInstallmentMode) return null;
                              if (value == null ||
                                  value.isEmpty ||
                                  value == '0') {
                                return '금액을 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const Divider(),
                        ],

                        // 할부 입력 (지출일 때만)
                        if (_type == 'expense') ...[
                          const SizedBox(height: 16),
                          InstallmentInputWidget(
                            startDate: _selectedDate,
                            enabled: !_isLoading,
                            onModeChanged: (isOn) {
                              setState(() {
                                _isInstallmentMode = isOn;
                                if (!isOn) {
                                  _installmentResult = null;
                                }
                                // 할부 모드일 때 반복 주기 비활성화
                                if (_isInstallmentMode) {
                                  _recurringSettings = const RecurringSettings(
                                    type: RecurringType.none,
                                  );
                                }
                              });
                            },
                            onApplied: (result) {
                              setState(() {
                                _installmentResult = result;
                                // 할부 적용 시 반복 주기를 월로 설정
                                _recurringSettings = const RecurringSettings(
                                  type: RecurringType.none,
                                );
                              });
                            },
                          ),
                          const Divider(),
                        ],

                        const SizedBox(height: 16),

                        // 날짜 선택
                        ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(
                            DateFormat(
                              'yyyy년 M월 d일 (E)',
                              'ko_KR',
                            ).format(_selectedDate),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _selectDate,
                        ),

                        const Divider(),

                        // 반복 주기 설정 (할부 모드가 아닐 때만)
                        if (!_isInstallmentMode) ...[
                          RecurringSettingsWidget(
                            startDate: _selectedDate,
                            initialSettings: _recurringSettings,
                            enabled: !_isLoading,
                            onChanged: (settings) {
                              setState(() {
                                _recurringSettings = settings;
                              });
                            },
                          ),
                          const Divider(),
                        ],

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
                              child: CircularProgressIndicator(),
                            ),
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

  Widget _buildCategoryGrid(List<Category> categories) {
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
      await ref
          .read(categoryNotifierProvider.notifier)
          .deleteCategory(category.id);

      if (_selectedCategory?.id == category.id) {
        setState(() => _selectedCategory = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('카테고리가 삭제되었습니다')));
      }

      ref.invalidate(categoriesProvider);
      ref.invalidate(incomeCategoriesProvider);
      ref.invalidate(expenseCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
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
      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .deletePaymentMethod(method.id);

      if (_selectedPaymentMethod?.id == method.id) {
        setState(() => _selectedPaymentMethod = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('결제수단이 삭제되었습니다')));
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  // 랜덤 색상 생성
  String _generateRandomColor() {
    final colors = [
      '#4CAF50', '#2196F3', '#F44336', '#FF9800',
      '#9C27B0', '#00BCD4', '#E91E63', '#795548',
      '#607D8B', '#3F51B5', '#009688', '#CDDC39',
    ];
    return colors[(DateTime.now().millisecondsSinceEpoch % colors.length)];
  }

  // 카테고리 추가 다이얼로그 (이름만 입력)
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('${_type == 'expense' ? '지출' : '수입'} 카테고리 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '카테고리 이름',
            hintText: '예: 식비, 교통비',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitCategory(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => _submitCategory(dialogContext, nameController),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCategory(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('카테고리 이름을 입력해주세요')),
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
          const SnackBar(content: Text('카테고리가 추가되었습니다')),
        );
      }

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
  }

  // 결제수단 추가 다이얼로그 (이름만 입력)
  void _showAddPaymentMethodDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('결제수단 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '결제수단 이름',
            hintText: '예: 신용카드, 현금',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitPaymentMethod(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => _submitPaymentMethod(dialogContext, nameController),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitPaymentMethod(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
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
            icon: '',
            color: _generateRandomColor(),
          );

      setState(() => _selectedPaymentMethod = newPaymentMethod);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('결제수단이 추가되었습니다')),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
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
