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

/// 자동 수집 소스 타입 (SMS 또는 Push 알림 중 하나만 선택)
/// 카카오톡 알림톡은 Push 알림의 일종으로, Push 소스에 포함됨
enum AutoCollectSource {
  sms,
  push;

  static AutoCollectSource fromString(String value) {
    switch (value) {
      case 'push':
        return AutoCollectSource.push;
      default:
        return AutoCollectSource.sms;
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
  final AutoCollectSource autoCollectSource; // SMS 또는 Push 중 하나만 선택

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
    this.autoCollectSource = AutoCollectSource.sms,
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
    AutoCollectSource? autoCollectSource,
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
      autoCollectSource: autoCollectSource ?? this.autoCollectSource,
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
    autoCollectSource,
  ];
}
