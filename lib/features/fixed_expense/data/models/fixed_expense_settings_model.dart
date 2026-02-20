import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/fixed_expense_settings.dart';

/// 고정비 설정 모델 (JSON 변환)
class FixedExpenseSettingsModel extends FixedExpenseSettings {
  const FixedExpenseSettingsModel({
    required super.id,
    required super.ledgerId,
    required super.userId,
    required super.includeInExpense,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FixedExpenseSettingsModel.fromJson(Map<String, dynamic> json) {
    return FixedExpenseSettingsModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      userId: json['user_id'] as String,
      includeInExpense: json['include_in_expense'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'user_id': userId,
      'include_in_expense': includeInExpense,
    };
  }

  static Map<String, dynamic> toUpdateJson({required bool includeInExpense}) {
    return {
      'include_in_expense': includeInExpense,
      'updated_at': DateTimeUtils.nowUtcIso(),
    };
  }

  FixedExpenseSettingsModel copyWith({
    String? id,
    String? ledgerId,
    String? userId,
    bool? includeInExpense,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FixedExpenseSettingsModel(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      userId: userId ?? this.userId,
      includeInExpense: includeInExpense ?? this.includeInExpense,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
