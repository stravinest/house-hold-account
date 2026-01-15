import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../../category/domain/entities/category.dart';
import '../../../fixed_expense/domain/entities/fixed_expense_category.dart';
import 'category_selector_widget.dart';
import 'fixed_expense_category_selector_widget.dart';

/// 카테고리 섹션 위젯
///
/// 고정비 여부에 따라 일반 카테고리 또는 고정비 카테고리 선택기를 표시합니다.
class CategorySectionWidget extends ConsumerWidget {
  /// 고정비 모드 여부
  final bool isFixedExpense;

  /// 현재 선택된 일반 카테고리
  final Category? selectedCategory;

  /// 현재 선택된 고정비 카테고리
  final FixedExpenseCategory? selectedFixedExpenseCategory;

  /// 거래 타입 ('expense', 'income', 'asset')
  final String transactionType;

  /// 일반 카테고리 선택 콜백
  final ValueChanged<Category?> onCategorySelected;

  /// 고정비 카테고리 선택 콜백
  final ValueChanged<FixedExpenseCategory?> onFixedExpenseCategorySelected;

  /// 위젯 활성화 여부
  final bool enabled;

  const CategorySectionWidget({
    super.key,
    required this.isFixedExpense,
    required this.selectedCategory,
    required this.selectedFixedExpenseCategory,
    required this.transactionType,
    required this.onCategorySelected,
    required this.onFixedExpenseCategorySelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Text(
            isFixedExpense ? '고정비 카테고리' : '카테고리',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        if (isFixedExpense)
          FixedExpenseCategorySelectorWidget(
            selectedCategory: selectedFixedExpenseCategory,
            onCategorySelected: onFixedExpenseCategorySelected,
            enabled: enabled,
          )
        else
          CategorySelectorWidget(
            selectedCategory: selectedCategory,
            transactionType: transactionType,
            onCategorySelected: onCategorySelected,
            enabled: enabled,
          ),
      ],
    );
  }
}

/// 결제수단 섹션 위젯
class PaymentMethodSectionWidget extends ConsumerWidget {
  final dynamic selectedPaymentMethod;
  final ValueChanged<dynamic> onPaymentMethodSelected;
  final bool enabled;

  const PaymentMethodSectionWidget({
    super.key,
    required this.selectedPaymentMethod,
    required this.onPaymentMethodSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          child: Text(
            '결제수단 (선택)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        // PaymentMethodSelectorWidget은 이미 별도로 import되어 사용됨
      ],
    );
  }
}
