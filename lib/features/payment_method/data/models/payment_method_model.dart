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
    super.autoSaveMode,
    super.defaultCategoryId,
    super.canAutoSave,
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
      autoSaveMode: AutoSaveMode.fromString(
        (json['auto_save_mode'] as String?) ?? 'manual',
      ),
      defaultCategoryId: json['default_category_id'] as String?,
      canAutoSave: (json['can_auto_save'] as bool?) ?? true,
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
      'auto_save_mode': autoSaveMode.toJson(),
      'default_category_id': defaultCategoryId,
      'can_auto_save': canAutoSave,
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    required String name,
    String icon = '',
    String color = '#6750A4',
    int sortOrder = 0,
    bool canAutoSave = true,
  }) {
    return {
      'ledger_id': ledgerId,
      'name': name,
      'icon': icon,
      'color': color,
      'is_default': false,
      'sort_order': sortOrder,
      'can_auto_save': canAutoSave,
    };
  }

  static Map<String, dynamic> toAutoSaveUpdateJson({
    required AutoSaveMode autoSaveMode,
    String? defaultCategoryId,
  }) {
    return {
      'auto_save_mode': autoSaveMode.toJson(),
      if (defaultCategoryId != null) 'default_category_id': defaultCategoryId,
    };
  }
}
