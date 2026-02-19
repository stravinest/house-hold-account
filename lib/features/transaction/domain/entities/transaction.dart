import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final String id;
  final String ledgerId;
  final String? categoryId;
  final String userId;
  final String? paymentMethodId;
  final int amount;
  final String type; // income, expense, asset
  final DateTime date;
  final String? title;
  final String? memo;
  final String? imageUrl;
  final bool isRecurring;
  final String? recurringType; // daily, monthly, yearly
  final DateTime? recurringEndDate;
  final bool isFixedExpense;
  final String? fixedExpenseCategoryId;
  final bool isAsset;
  final DateTime? maturityDate;
  final String? recurringTemplateId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 조인된 데이터
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final String? userName;
  final String? userColor;
  final String? paymentMethodName;
  final String? fixedExpenseCategoryName;
  final String? fixedExpenseCategoryIcon;
  final String? fixedExpenseCategoryColor;
  final DateTime? recurringTemplateStartDate;

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
    this.isFixedExpense = false,
    this.fixedExpenseCategoryId,
    this.isAsset = false,
    this.maturityDate,
    this.recurringTemplateId,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.userName,
    this.userColor,
    this.paymentMethodName,
    this.fixedExpenseCategoryName,
    this.fixedExpenseCategoryIcon,
    this.fixedExpenseCategoryColor,
    this.recurringTemplateStartDate,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;
    final paymentMethod = json['payment_methods'] as Map<String, dynamic>?;
    final fixedExpenseCategory =
        json['fixed_expense_categories'] as Map<String, dynamic>?;
    final recurringTemplate =
        json['recurring_templates'] as Map<String, dynamic>?;

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
      isFixedExpense: json['is_fixed_expense'] as bool? ?? false,
      fixedExpenseCategoryId: json['fixed_expense_category_id'] as String?,
      isAsset: json['is_asset'] as bool? ?? false,
      maturityDate: json['maturity_date'] != null
          ? DateTime.parse(json['maturity_date'] as String)
          : null,
      recurringTemplateId: json['recurring_template_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
      paymentMethodName: paymentMethod?['name'] as String?,
      fixedExpenseCategoryName: fixedExpenseCategory?['name'] as String?,
      fixedExpenseCategoryIcon: fixedExpenseCategory?['icon'] as String?,
      fixedExpenseCategoryColor: fixedExpenseCategory?['color'] as String?,
      recurringTemplateStartDate: recurringTemplate?['start_date'] != null
          ? DateTime.parse(recurringTemplate!['start_date'] as String)
          : null,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isAssetType => type == 'asset';
  bool get isAssetTransaction => type == 'asset' && isAsset == true;

  // 할부 거래 여부 (title에 "할부" 포함 + 반복거래 + 종료일 있음)
  bool get isInstallment =>
      isRecurring &&
      recurringEndDate != null &&
      title != null &&
      title!.contains('할부');

  // 할부 시작일 (recurringTemplateStartDate 우선, 없으면 createdAt 기반 추정)
  DateTime? get _installmentStartDate {
    if (recurringTemplateStartDate != null) return recurringTemplateStartDate;
    // recurring_template_id가 없는 기존 거래: createdAt의 월 첫날을 시작으로 추정
    return DateTime(createdAt.year, createdAt.month, 1);
  }

  // 할부 총 개월수
  int get installmentTotalMonths {
    if (!isInstallment) return 0;
    final start = _installmentStartDate;
    if (start == null) return 0;
    final end = recurringEndDate!;
    final months = (end.year - start.year) * 12 + end.month - start.month + 1;
    return months > 0 ? months : 0;
  }

  // 현재 할부 회차 (1부터 시작)
  int get installmentCurrentMonth {
    if (!isInstallment) return 0;
    final start = _installmentStartDate;
    if (start == null) return 0;
    final month = (date.year - start.year) * 12 + date.month - start.month + 1;
    return month > 0 ? month : 1;
  }

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
    bool? isFixedExpense,
    String? fixedExpenseCategoryId,
    bool? isAsset,
    DateTime? maturityDate,
    String? recurringTemplateId,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
    String? userName,
    String? userColor,
    String? paymentMethodName,
    String? fixedExpenseCategoryName,
    String? fixedExpenseCategoryIcon,
    String? fixedExpenseCategoryColor,
    DateTime? recurringTemplateStartDate,
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
      isFixedExpense: isFixedExpense ?? this.isFixedExpense,
      fixedExpenseCategoryId:
          fixedExpenseCategoryId ?? this.fixedExpenseCategoryId,
      isAsset: isAsset ?? this.isAsset,
      maturityDate: maturityDate ?? this.maturityDate,
      recurringTemplateId: recurringTemplateId ?? this.recurringTemplateId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      userName: userName ?? this.userName,
      userColor: userColor ?? this.userColor,
      paymentMethodName: paymentMethodName ?? this.paymentMethodName,
      fixedExpenseCategoryName:
          fixedExpenseCategoryName ?? this.fixedExpenseCategoryName,
      fixedExpenseCategoryIcon:
          fixedExpenseCategoryIcon ?? this.fixedExpenseCategoryIcon,
      fixedExpenseCategoryColor:
          fixedExpenseCategoryColor ?? this.fixedExpenseCategoryColor,
      recurringTemplateStartDate:
          recurringTemplateStartDate ?? this.recurringTemplateStartDate,
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
    isFixedExpense,
    fixedExpenseCategoryId,
    isAsset,
    maturityDate,
    recurringTemplateId,
    createdAt,
    updatedAt,
  ];
}
