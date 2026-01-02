import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String ledgerId;
  final String categoryId;
  final String userId;
  final int amount;
  final String type; // income, expense
  final DateTime date;
  final String? memo;
  final String? imageUrl;
  final bool isRecurring;
  final String? recurringType; // daily, weekly, monthly
  final DateTime? recurringEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 조인된 데이터
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? userName;

  const Transaction({
    required this.id,
    required this.ledgerId,
    required this.categoryId,
    required this.userId,
    required this.amount,
    required this.type,
    required this.date,
    this.memo,
    this.imageUrl,
    required this.isRecurring,
    this.recurringType,
    this.recurringEndDate,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.userName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;

    return Transaction(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      categoryId: json['category_id'] as String,
      userId: json['user_id'] as String,
      amount: json['amount'] as int,
      type: json['type'] as String,
      date: DateTime.parse(json['date'] as String),
      memo: json['memo'] as String?,
      imageUrl: json['image_url'] as String?,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurringType: json['recurring_type'] as String?,
      recurringEndDate: json['recurring_end_date'] != null
          ? DateTime.parse(json['recurring_end_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  Transaction copyWith({
    String? id,
    String? ledgerId,
    String? categoryId,
    String? userId,
    int? amount,
    String? type,
    DateTime? date,
    String? memo,
    String? imageUrl,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? userName,
  }) {
    return Transaction(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      memo: memo ?? this.memo,
      imageUrl: imageUrl ?? this.imageUrl,
      isRecurring: isRecurring ?? this.isRecurring,
      recurringType: recurringType ?? this.recurringType,
      recurringEndDate: recurringEndDate ?? this.recurringEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ledgerId,
        categoryId,
        userId,
        amount,
        type,
        date,
        memo,
        imageUrl,
        isRecurring,
        recurringType,
        recurringEndDate,
        createdAt,
        updatedAt,
      ];
}
