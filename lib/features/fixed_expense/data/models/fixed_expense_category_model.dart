import '../../domain/entities/fixed_expense_category.dart';

/// 고정비 카테고리 모델 (JSON 변환)
class FixedExpenseCategoryModel extends FixedExpenseCategory {
  const FixedExpenseCategoryModel({
    required super.id,
    required super.ledgerId,
    required super.name,
    required super.icon,
    required super.color,
    required super.sortOrder,
    required super.createdAt,
  });

  factory FixedExpenseCategoryModel.fromJson(Map<String, dynamic> json) {
    return FixedExpenseCategoryModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String? ?? '',
      color: json['color'] as String? ?? '#6750A4',
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    required String name,
    String icon = '',
    required String color,
    int sortOrder = 0,
  }) {
    return {
      'ledger_id': ledgerId,
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    };
  }

  static Map<String, dynamic> toUpdateJson({
    required String name,
    String? icon,
    String? color,
    int? sortOrder,
  }) {
    final json = <String, dynamic>{'name': name};
    if (icon != null) json['icon'] = icon;
    if (color != null) json['color'] = color;
    if (sortOrder != null) json['sort_order'] = sortOrder;
    return json;
  }

  FixedExpenseCategoryModel copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? icon,
    String? color,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return FixedExpenseCategoryModel(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
