import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String ledgerId;
  final String name;
  final String icon;
  final String color;
  final String type; // income, expense
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isSaving => type == 'saving';

  Category copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? icon,
    String? color,
    String? type,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return Category(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        ledgerId,
        name,
        icon,
        color,
        type,
        isDefault,
        sortOrder,
        createdAt,
      ];
}
