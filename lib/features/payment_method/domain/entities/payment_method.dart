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
  final String ownerUserId; // 소유자 ID (멤버별 결제수단 관리)
  final String name;
  final String icon;
  final String color;
  final bool isDefault;
  final int sortOrder;
  final DateTime createdAt;
  final AutoSaveMode autoSaveMode;
  final String? defaultCategoryId;
  final bool canAutoSave; // 자동 수집 지원 여부

  const PaymentMethod({
    required this.id,
    required this.ledgerId,
    required this.ownerUserId,
    required this.name,
    required this.icon,
    required this.color,
    required this.isDefault,
    required this.sortOrder,
    required this.createdAt,
    this.autoSaveMode = AutoSaveMode.manual,
    this.defaultCategoryId,
    this.canAutoSave = true,
  });

  bool get isAutoSaveEnabled => autoSaveMode != AutoSaveMode.manual;

  PaymentMethod copyWith({
    String? id,
    String? ledgerId,
    String? ownerUserId,
    String? name,
    String? icon,
    String? color,
    bool? isDefault,
    int? sortOrder,
    DateTime? createdAt,
    AutoSaveMode? autoSaveMode,
    String? defaultCategoryId,
    bool? canAutoSave,
  }) {
    return PaymentMethod(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      autoSaveMode: autoSaveMode ?? this.autoSaveMode,
      defaultCategoryId: defaultCategoryId ?? this.defaultCategoryId,
      canAutoSave: canAutoSave ?? this.canAutoSave,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ledgerId,
    ownerUserId,
    name,
    icon,
    color,
    isDefault,
    sortOrder,
    createdAt,
    autoSaveMode,
    defaultCategoryId,
    canAutoSave,
  ];
}
