import '../../domain/entities/category.dart';

class CategoryModel extends Category {
  const CategoryModel({
    required super.id,
    required super.ledgerId,
    required super.name,
    required super.icon,
    required super.color,
    required super.type,
    required super.isDefault,
    required super.sortOrder,
    required super.createdAt,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      type: json['type'] as String,
      isDefault: json['is_default'] as bool,
      sortOrder: json['sort_order'] as int,
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
      'type': type,
      'is_default': isDefault,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    required String name,
    required String icon,
    required String color,
    required String type,
    int sortOrder = 0,
  }) {
    return {
      'ledger_id': ledgerId,
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': false,
      'sort_order': sortOrder,
    };
  }
}
