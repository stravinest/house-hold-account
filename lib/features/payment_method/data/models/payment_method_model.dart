import '../../domain/entities/payment_method.dart';

class PaymentMethodModel extends PaymentMethod {
  const PaymentMethodModel({
    required super.id,
    required super.ledgerId,
    required super.name,
    required super.icon,
    required super.color,
    required super.isDefault,
    required super.sortOrder,
    required super.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      name: json['name'] as String,
      icon: (json['icon'] as String?) ?? '',
      color: (json['color'] as String?) ?? '#6750A4',
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
      'is_default': isDefault,
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    required String name,
    String icon = '',
    String color = '#6750A4',
    int sortOrder = 0,
  }) {
    return {
      'ledger_id': ledgerId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': false,
      'sort_order': sortOrder,
    };
  }
}
