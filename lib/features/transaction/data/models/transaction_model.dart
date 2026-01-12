import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.ledgerId,
    super.categoryId,
    required super.userId,
    super.paymentMethodId,
    required super.amount,
    required super.type,
    required super.date,
    super.title,
    super.memo,
    super.imageUrl,
    required super.isRecurring,
    super.recurringType,
    super.recurringEndDate,
    super.isFixedExpense = false,
    super.fixedExpenseCategoryId,
    required super.createdAt,
    required super.updatedAt,
    super.categoryName,
    super.categoryIcon,
    super.categoryColor,
    super.userName,
    super.userColor,
    super.paymentMethodName,
    super.fixedExpenseCategoryName,
    super.fixedExpenseCategoryColor,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final profile = json['profiles'] as Map<String, dynamic>?;
    final paymentMethod = json['payment_methods'] as Map<String, dynamic>?;
    final fixedExpenseCategory =
        json['fixed_expense_categories'] as Map<String, dynamic>?;

    return TransactionModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      categoryId: json['category_id'] as String?,
      userId: json['user_id'] as String,
      paymentMethodId: json['payment_method_id'] as String?,
      amount: json['amount'] as int,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String?,
      memo: json['memo'] as String?,
      imageUrl: json['image_url'] as String?,
      isRecurring: json['is_recurring'] as bool,
      recurringType: json['recurring_type'] as String?,
      recurringEndDate: json['recurring_end_date'] != null
          ? DateTime.parse(json['recurring_end_date'] as String)
          : null,
      isFixedExpense: json['is_fixed_expense'] as bool? ?? false,
      fixedExpenseCategoryId: json['fixed_expense_category_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      userName: profile?['display_name'] as String?,
      userColor: profile?['color'] as String?,
      paymentMethodName: paymentMethod?['name'] as String?,
      fixedExpenseCategoryName: fixedExpenseCategory?['name'] as String?,
      fixedExpenseCategoryColor: fixedExpenseCategory?['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'category_id': categoryId,
      'user_id': userId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String().split('T').first,
      'title': title,
      'memo': memo,
      'image_url': imageUrl,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'recurring_end_date': recurringEndDate?.toIso8601String().split('T').first,
      'is_fixed_expense': isFixedExpense,
      'fixed_expense_category_id': fixedExpenseCategoryId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    String? categoryId,
    required String userId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime date,
    String? title,
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
  }) {
    return {
      'ledger_id': ledgerId,
      'category_id': categoryId,
      'user_id': userId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String().split('T').first,
      'title': title,
      'memo': memo,
      'image_url': imageUrl,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'recurring_end_date': recurringEndDate?.toIso8601String().split('T').first,
      'is_fixed_expense': isFixedExpense,
      'fixed_expense_category_id': fixedExpenseCategoryId,
    };
  }
}
