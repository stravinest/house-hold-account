import 'package:equatable/equatable.dart';

enum AutoSaveMode {
  manual,
  suggest,
  auto;

  static AutoSaveMode fromString(String value) {
    switch (value) {
      case 'suggest':
        return AutoSaveMode.suggest;
      case 'auto':
        return AutoSaveMode.auto;
      default:
        return AutoSaveMode.manual;
    }
  }

  String toJson() => name;
}

class PaymentMethod extends Equatable {
  final String id;
  final String ledgerId;
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final AutoSaveMode autoSaveMode;
  final String? defaultCategoryId;

  const PaymentMethod({
    required this.id,
    required this.ledgerId,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
    this.autoSaveMode = AutoSaveMode.manual,
    this.defaultCategoryId,
  });

  bool get isAutoSaveEnabled => autoSaveMode != AutoSaveMode.manual;

  PaymentMethod copyWith({
    String? id,
    String? ledgerId,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    AutoSaveMode? autoSaveMode,
    String? defaultCategoryId,
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
      autoSaveMode: autoSaveMode ?? this.autoSaveMode,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
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
    autoSaveMode,
    defaultCategoryId,
  ];
}
