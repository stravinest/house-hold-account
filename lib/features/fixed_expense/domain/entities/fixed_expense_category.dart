import 'package:equatable/equatable.dart';

/// 고정비 카테고리 엔티티
class FixedExpenseCategory extends Equatable {
  final String id;
  final String ledgerId;
  final String name;
  final String icon;
  final String color;
  final int sortOrder;
  final DateTime createdAt;

  const FixedExpenseCategory({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.icon,
    required this.color,
    required this.sortOrder,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, ledgerId, name, icon, color, sortOrder, createdAt];
}
