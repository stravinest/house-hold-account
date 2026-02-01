import '../../domain/entities/fixed_expense_settings.dart';

/// 고정비 설정 모델 (JSON 변환)
class FixedExpenseSettingsModel extends FixedExpenseSettings {
  const FixedExpenseSettingsModel({
    required super.id,
    required super.ledgerId,
    required super.includeInExpense,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FixedExpenseSettingsModel.fromJson(Map<String, dynamic> json) {
    return FixedExpenseSettingsModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      includeInExpense: json['include_in_expense'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'include_in_expense': includeInExpense,
    };
  }

  static Map<String, dynamic> toUpdateJson({required bool includeInExpense}) {
    return {
      'include_in_expense': includeInExpense,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  FixedExpenseSettingsModel copyWith({
    String? id,
    String? ledgerId,
    bool? includeInExpense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FixedExpenseSettingsModel(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      includeInExpense: includeInExpense ?? this.includeInExpense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
