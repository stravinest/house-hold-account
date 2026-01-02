import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../domain/entities/budget.dart';
import '../providers/budget_provider.dart';

class AddBudgetDialog extends ConsumerStatefulWidget {
  final Budget? budget;

  const AddBudgetDialog({super.key, this.budget});

  @override
  ConsumerState<AddBudgetDialog> createState() => _AddBudgetDialogState();
}

class _AddBudgetDialogState extends ConsumerState<AddBudgetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _numberFormat = NumberFormat('#,###');

  Category? _selectedCategory;
  bool _isTotalBudget = false;
  bool _isLoading = false;

  bool get isEditing => widget.budget != null;

  @override
  void initState() {
    super.initState();
    if (widget.budget != null) {
      _amountController.text = _numberFormat.format(widget.budget!.amount);
      _isTotalBudget = widget.budget!.isTotalBudget;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return AlertDialog(
      title: Text(isEditing ? '예산 수정' : '예산 추가'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 예산 타입 선택
              if (!isEditing) ...[
                const Text('예산 유형'),
                const SizedBox(height: 8),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: true,
                      label: Text('전체 예산'),
                    ),
                    ButtonSegment(
                      value: false,
                      label: Text('카테고리별'),
                    ),
                  ],
                  selected: {_isTotalBudget},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _isTotalBudget = selected.first;
                      _selectedCategory = null;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ],

              // 카테고리 선택 (카테고리별 예산일 때만)
              if (!_isTotalBudget && !isEditing) ...[
                const Text('카테고리'),
                const SizedBox(height: 8),
                categoriesAsync.when(
                  data: (categories) {
                    return DropdownButtonFormField<Category>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '카테고리 선택',
                      ),
                      items: categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Row(
                            children: [
                              Text(category.icon),
                              const SizedBox(width: 8),
                              Text(category.name),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (selectedValue) {
                        setState(() {
                          _selectedCategory = selectedValue;
                        });
                      },
                      validator: (val) {
                        if (!_isTotalBudget && val == null) {
                          return '카테고리를 선택해주세요';
                        }
                        return null;
                      },
                    );
                  },
                  loading: () => const CircularProgressIndicator(),
                  error: (e, st) => Text('오류: $e'),
                ),
                const SizedBox(height: 16),
              ],

              // 예산 금액
              const Text('예산 금액'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '금액 입력',
                  suffixText: '원',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ThousandsSeparatorInputFormatter(),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '금액을 입력해주세요';
                  }
                  final amount = int.tryParse(value.replaceAll(',', ''));
                  if (amount == null || amount <= 0) {
                    return '올바른 금액을 입력해주세요';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _saveBudget,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? '수정' : '추가'),
        ),
      ],
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount =
          int.parse(_amountController.text.replaceAll(',', ''));

      if (isEditing) {
        await ref.read(budgetNotifierProvider.notifier).updateBudget(
              id: widget.budget!.id,
              amount: amount,
            );
      } else {
        await ref.read(budgetNotifierProvider.notifier).createBudget(
              categoryId: _isTotalBudget ? null : _selectedCategory?.id,
              amount: amount,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing ? '예산이 수정되었습니다' : '예산이 추가되었습니다'),
          ),
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
}

// 천 단위 구분 포맷터
class _ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final _numberFormat = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) return oldValue;

    final formatted = _numberFormat.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
