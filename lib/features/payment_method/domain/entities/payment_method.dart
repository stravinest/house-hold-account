import 'package:equatable/equatable.dart';

class PaymentMethod extends Equatable {
  final String id;
  final String ledgerId;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;

  const PaymentMethod({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
  });

  PaymentMethod copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
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
        isDefault,
        sortOrder,
        createdAt,
      ];
}
