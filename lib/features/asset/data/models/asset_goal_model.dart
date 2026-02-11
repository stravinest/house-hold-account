import '../../../../core/utils/date_time_utils.dart';
import '../../domain/entities/asset_goal.dart';

class AssetGoalModel extends AssetGoal {
  const AssetGoalModel({
    required super.id,
    required super.ledgerId,
    required super.title,
    required super.targetAmount,
    super.targetDate,
    super.assetType,
    super.categoryIds,
    required super.createdAt,
    required super.updatedAt,
    required super.createdBy,
  });

  factory AssetGoalModel.fromJson(Map<String, dynamic> json) {
    return AssetGoalModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      title: json['title'] as String,
      targetAmount: json['target_amount'] as int,
      targetDate: json['target_date'] != null
          ? DateTime.parse(json['target_date'] as String)
          : null,
      assetType: json['asset_type'] as String?,
      categoryIds: json['category_ids'] != null
          ? List<String>.from(json['category_ids'] as List)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      createdBy: json['created_by'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'title': title,
      'target_amount': targetAmount,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T')[0],
      'asset_type': assetType,
      'category_ids': categoryIds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'ledger_id': ledgerId,
      'title': title,
      'target_amount': targetAmount,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T')[0],
      if (assetType != null) 'asset_type': assetType,
      if (categoryIds != null) 'category_ids': categoryIds,
      'created_by': createdBy,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title,
      'target_amount': targetAmount,
      if (targetDate != null)
        'target_date': targetDate!.toIso8601String().split('T')[0],
      'asset_type': assetType,
      'category_ids': categoryIds,
      'updated_at': DateTimeUtils.nowUtcIso(),
    };
  }
}
