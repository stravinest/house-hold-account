import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../fixed_expense/domain/entities/fixed_expense_category.dart';
import '../../../fixed_expense/presentation/providers/fixed_expense_category_provider.dart';
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
  FixedExpenseCategory? _selectedFixedExpenseCategory;
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
    // 화면 진입 시 카테고리/결제수단 데이터 새로 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryNotifierProvider.notifier).loadCategories();
      ref.read(paymentMethodNotifierProvider.notifier).loadPaymentMethods();
    });
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

    // 할부 모드일 때 할부 결과 유효성 검사
    if (_isInstallmentMode && _installmentResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('할부 정보를 입력해주세요'),
          duration: Duration(seconds: 1),
        ),
      );
      return false;
    }

    // 고정비 선택 시 카테고리 선택 검증은 선택 안함 옵션이 있으므로 제거
    // (고정비 카테고리도 선택 안함이 가능)

    return true;
  }

  Future<void> _submit() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      final notifier = ref.read(transactionNotifierProvider.notifier);

      // 성공 메시지를 저장할 변수
      String? successMessage;

      if (_isInstallmentMode && _installmentResult != null) {
        // 할부 거래 생성 (템플릿 + 오늘까지 거래)
        successMessage = await _createInstallmentTransactions(notifier);
      } else if (_recurringSettings.isRecurring) {
        // 반복 거래 생성 (템플릿 + 오늘까지 거래)
        successMessage = await _createRecurringTransactions(notifier);
        // 사용자가 취소한 경우 화면을 닫지 않음
        if (successMessage == null) {
          return;
        }
      } else {
        // 단일 거래 생성
        successMessage = await _createSingleTransaction(notifier);
      }

      if (mounted) {
        // Navigator와 ScaffoldMessenger 참조를 미리 저장
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final navigator = Navigator.of(context);

        // Navigator.pop을 다음 프레임에서 실행하여 locked 상태 문제 방지
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigator.pop();
          // SnackBar는 pop 후에 표시
          if (successMessage != null) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(successMessage),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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

  /// 단일 거래 생성 후 성공 메시지 반환
  Future<String> _createSingleTransaction(TransactionNotifier notifier) async {
    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );

    await notifier.createTransaction(
      categoryId: _recurringSettings.isFixedExpense ? null : _selectedCategory?.id,
      paymentMethodId: _selectedPaymentMethod?.id,
      amount: amount,
      type: _type,
      date: _selectedDate,
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      memo: _memoController.text.isNotEmpty ? _memoController.text : null,
      isFixedExpense: _recurringSettings.isFixedExpense,
      fixedExpenseCategoryId: _selectedFixedExpenseCategory?.id,
    );

    return '거래가 추가되었습니다';
  }

  /// 반복 거래 템플릿 생성 (취소 시 null 반환)
  Future<String?> _createRecurringTransactions(
    TransactionNotifier notifier,
  ) async {
    final amount = int.parse(
      _amountController.text.replaceAll(RegExp(r'[^\d]'), ''),
    );

    // 템플릿 생성 + 오늘까지 거래 자동 생성
    await notifier.createRecurringTemplate(
      categoryId: _recurringSettings.isFixedExpense ? null : _selectedCategory?.id,
      paymentMethodId: _selectedPaymentMethod?.id,
      amount: amount,
      type: _type,
      startDate: _selectedDate,
      endDate: _recurringSettings.endDate,
      recurringType: _recurringSettings.recurringTypeString!,
      title: _titleController.text.isNotEmpty ? _titleController.text : null,
      memo: _memoController.text.isNotEmpty ? _memoController.text : null,
      isFixedExpense: _recurringSettings.isFixedExpense,
      fixedExpenseCategoryId: _selectedFixedExpenseCategory?.id,
    );

    final endDateText = _recurringSettings.endDate != null
        ? '${_recurringSettings.endDate!.year}년 ${_recurringSettings.endDate!.month}월까지'
        : '계속';
    return '반복 거래가 등록되었습니다 ($endDateText)';
  }

  /// 할부 거래 템플릿 생성 후 성공 메시지 반환
  Future<String> _createInstallmentTransactions(
    TransactionNotifier notifier,
  ) async {
    final result = _installmentResult!;

    // 할부도 템플릿 기반으로 변경
    // 할부는 월별 금액이 다를 수 있으므로 첫 달 금액으로 템플릿 생성
    // 실제로는 할부는 금액이 다를 수 있어서 기존 방식 유지가 더 나을 수 있음
    // 여기서는 첫 달 금액으로 템플릿 생성
    await notifier.createRecurringTemplate(
      categoryId: _selectedCategory?.id,
      paymentMethodId: _selectedPaymentMethod?.id,
      amount: result.baseAmount,
      type: _type,
      startDate: _selectedDate,
      endDate: result.endDate,
      recurringType: 'monthly',
      title: _titleController.text.isNotEmpty
          ? '${_titleController.text} (할부)'
          : '할부',
      memo: _memoController.text.isNotEmpty ? _memoController.text : null,
    );

    return '${result.months}개월 할부가 등록되었습니다';
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
                              // 수입/저축으로 변경 시 할부 모드 해제
                              if (_type == 'income' || _type == 'saving') {
                                _isInstallmentMode = false;
                                _installmentResult = null;
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
                            transactionType: _type,
                            onChanged: (settings) {
                              setState(() {
                                // 고정비 상태가 변경되면 해당 카테고리 초기화
                                if (settings.isFixedExpense != _recurringSettings.isFixedExpense) {
                                  if (settings.isFixedExpense) {
                                    // 고정비로 변경: 일반 카테고리 초기화
                                    _selectedCategory = null;
                                  } else {
                                    // 일반으로 변경: 고정비 카테고리 초기화
                                    _selectedFixedExpenseCategory = null;
                                  }
                                }
                                _recurringSettings = settings;
                              });
                            },
                          ),
                          const Divider(),
                        ],

                        // 카테고리 선택 (고정비 여부에 따라 다른 카테고리 표시)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            _recurringSettings.isFixedExpense ? '고정비 카테고리' : '카테고리',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),

                        if (_recurringSettings.isFixedExpense)
                          // 고정비 카테고리 표시
                          ref.watch(fixedExpenseCategoriesProvider).when(
                            data: (categories) => _buildFixedExpenseCategoryGrid(categories),
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (e, _) => Text('오류: $e'),
                          )
                        else
                          // 일반 카테고리 표시
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

  Widget _buildFixedExpenseCategoryGrid(List<FixedExpenseCategory> categories) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // 선택 안함 옵션
        FilterChip(
          selected: _selectedFixedExpenseCategory == null,
          showCheckmark: false,
          label: const Text('선택 안함'),
          onSelected: (_) {
            setState(() => _selectedFixedExpenseCategory = null);
          },
        ),
        ...categories.map((category) {
          final isSelected = _selectedFixedExpenseCategory?.id == category.id;
          return FilterChip(
            selected: isSelected,
            showCheckmark: false,
            label: Text(category.name),
            onSelected: (_) {
              setState(() => _selectedFixedExpenseCategory = category);
            },
            onDeleted: () => _deleteFixedExpenseCategory(category),
            deleteIcon: const Icon(Icons.close, size: 18),
          );
        }),
        // 고정비 카테고리 추가 버튼
        ActionChip(
          avatar: const Icon(Icons.add, size: 18),
          label: const Text('추가'),
          onPressed: () => _showAddFixedExpenseCategoryDialog(),
        ),
      ],
    );
  }

  Future<void> _deleteFixedExpenseCategory(FixedExpenseCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('고정비 카테고리 삭제'),
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
          .read(fixedExpenseCategoryNotifierProvider.notifier)
          .deleteCategory(category.id);

      if (_selectedFixedExpenseCategory?.id == category.id) {
        setState(() => _selectedFixedExpenseCategory = null);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('고정비 카테고리가 삭제되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  void _showAddFixedExpenseCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('고정비 카테고리 추가'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: '카테고리 이름',
            hintText: '예: 월세, 통신비',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _submitFixedExpenseCategory(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => _submitFixedExpenseCategory(dialogContext, nameController),
            child: const Text('추가'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFixedExpenseCategory(
    BuildContext dialogContext,
    TextEditingController nameController,
  ) async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('카테고리 이름을 입력해주세요'),
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    try {
      final newCategory = await ref
          .read(fixedExpenseCategoryNotifierProvider.notifier)
          .createCategory(
            name: nameController.text.trim(),
            icon: '',
            color: _generateRandomColor(),
          );

      setState(() => _selectedFixedExpenseCategory = newCategory);

      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('고정비 카테고리가 추가되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('카테고리가 삭제되었습니다'),
            duration: Duration(seconds: 1),
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
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('결제수단이 삭제되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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

  // 카테고리 추가 다이얼로그 (이름만 입력)
  void _showAddCategoryDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          '${_type == 'expense'
              ? '지출'
              : _type == 'income'
              ? '수입'
              : '저축'} 카테고리 추가',
        ),
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
        const SnackBar(
          content: Text('카테고리 이름을 입력해주세요'),
          duration: Duration(seconds: 1),
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
          const SnackBar(
            content: Text('카테고리가 추가되었습니다'),
            duration: Duration(seconds: 1),
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
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
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
          onSubmitted: (_) =>
              _submitPaymentMethod(dialogContext, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () =>
                _submitPaymentMethod(dialogContext, nameController),
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
        const SnackBar(
          content: Text('결제수단 이름을 입력해주세요'),
          duration: Duration(seconds: 1),
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
          const SnackBar(
            content: Text('결제수단이 추가되었습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }

      ref.invalidate(paymentMethodsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
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
