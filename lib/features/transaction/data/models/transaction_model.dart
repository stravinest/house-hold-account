import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.ledgerId,
    required super.categoryId,
    required super.userId,
    super.paymentMethodId,
    required super.amount,
    required super.type,
    required super.date,
    super.memo,
    super.imageUrl,
    required super.isRecurring,
    super.recurringType,
    super.recurringEndDate,
    required super.createdAt,
    required super.updatedAt,
    super.categoryName,
    super.categoryIcon,
    super.categoryColor,
    super.userName,
    super.paymentMethodName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final profile = json['profiles'] as Map<String, dynamic>?;
    final paymentMethod = json['payment_methods'] as Map<String, dynamic>?;

    return TransactionModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      categoryId: json['category_id'] as String,
      userId: json['user_id'] as String,
      paymentMethodId: json['payment_method_id'] as String?,
      amount: json['amount'] as int,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
      imageUrl: json['image_url'] as String?,
      isRecurring: json['is_recurring'] as bool,
      recurringType: json['recurring_type'] as String?,
      recurringEndDate: json['recurring_end_date'] != null
          ? DateTime.parse(json['recurring_end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      userName: profile?['display_name'] as String?,
      paymentMethodName: paymentMethod?['name'] as String?,
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
      'memo': memo,
      'image_url': imageUrl,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'recurring_end_date': recurringEndDate?.toIso8601String().split('T').first,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    required String categoryId,
    required String userId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime date,
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
  }) {
    return {
      'ledger_id': ledgerId,
      'category_id': categoryId,
      'user_id': userId,
      'payment_method_id': paymentMethodId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String().split('T').first,
      'memo': memo,
      'image_url': imageUrl,
      'is_recurring': isRecurring,
      'recurring_type': recurringType,
      'recurring_end_date': recurringEndDate?.toIso8601String().split('T').first,
    };
  }
}
