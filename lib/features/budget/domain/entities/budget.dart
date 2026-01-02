class Budget {
  final String id;
  final String ledgerId;
  final String? categoryId;
  final int amount;
  final int year;
  final int month;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 조인된 데이터
  final String? categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  const Budget({
    required this.id,
    required this.ledgerId,
    this.categoryId,
    required this.amount,
    required this.year,
    required this.month,
    required this.createdAt,
    required this.updatedAt,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    final category = json['categories'] as Map<String, dynamic>?;

    return Budget(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      categoryId: json['category_id'] as String?,
      amount: json['amount'] as int,
      year: json['year'] as int,
      month: json['month'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      categoryName: category?['name'] as String?,
      categoryIcon: category?['icon'] as String?,
      categoryColor: category?['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'category_id': categoryId,
      'amount': amount,
      'year': year,
      'month': month,
    };
  }

  Budget copyWith({
    String? id,
    String? ledgerId,
    String? categoryId,
    int? amount,
    int? year,
    int? month,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? categoryName,
    String? categoryIcon,
    String? categoryColor,
  }) {
    return Budget(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      year: year ?? this.year,
      month: month ?? this.month,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
    );
  }

  // 예산 진행률 계산을 위한 헬퍼
  double getProgressRate(int spent) {
    if (amount == 0) return 0;
    return (spent / amount).clamp(0.0, 2.0);
  }

  // 남은 예산
  int getRemainingBudget(int spent) {
    return amount - spent;
  }

  // 총 예산인지 여부 (카테고리 없음)
  bool get isTotalBudget => categoryId == null;
}
