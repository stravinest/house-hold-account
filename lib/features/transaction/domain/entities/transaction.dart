import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String ledgerId;
  final String? categoryId;
  final String userId;
  final String? paymentMethodId;
  final int amount;
  final String type; // income, expense
  final DateTime date;
  final String? title;
  final String? memo;
  final String? imageUrl;
  final bool isRecurring;
  final String? recurringType; // daily, monthly, yearly
  final DateTime? recurringEndDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 조인된 데이터
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? userName;
  final String? userColor;
  final String? paymentMethodName;

  const Transaction({
    required this.id,
    required this.ledgerId,
    this.categoryId,
    required this.userId,
    this.paymentMethodId,
    required this.amount,
    required this.type,
    required this.date,
    this.title,
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
    this.userColor,
    this.paymentMethodName,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final paymentMethod = json['payment_methods'] as Map<String, dynamic>?;

    return Transaction(
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
      paymentMethodName: paymentMethod?['name'] as String?,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isSaving => type == 'saving';

  // 주의: 현재 copyWith에서는 categoryId나 paymentMethodId를 null로 설정할 수 없습니다.
  // null을 전달해도 기존 값이 유지됩니다.
  // 향후 거래 수정 기능 구현 시, null로 설정이 필요하다면 다음 중 하나를 선택하세요:
  // 1. clearCategory(), clearPaymentMethod() 메서드 추가
  // 2. Optional wrapper 클래스 사용 (freezed 패턴)
  // 3. updateWith() 메서드를 별도로 구현하여 명시적으로 null 처리
  Transaction copyWith({
    String? id,
    String? ledgerId,
    String? categoryId,
    String? userId,
    String? paymentMethodId,
    int? amount,
    String? type,
    DateTime? date,
    String? title,
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
    String? userColor,
    String? paymentMethodName,
  }) {
    return Transaction(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      categoryId: categoryId ?? this.categoryId,
      userId: userId ?? this.userId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      title: title ?? this.title,
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
      userColor: userColor ?? this.userColor,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ledgerId,
        categoryId,
        userId,
        paymentMethodId,
        amount,
        type,
        date,
        title,
        memo,
        imageUrl,
        isRecurring,
        recurringType,
        recurringEndDate,
        createdAt,
        updatedAt,
      ];
}
