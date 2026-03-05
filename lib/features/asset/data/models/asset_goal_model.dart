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
    super.goalType,
    super.loanAmount,
    super.repaymentMethod,
    super.annualInterestRate,
    super.startDate,
    super.monthlyPayment,
    super.isManualPayment,
    super.memo,
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
      goalType: json['goal_type'] == 'loan' ? GoalType.loan : GoalType.asset,
      loanAmount: json['loan_amount'] as int?,
      repaymentMethod: json['repayment_method'] != null
          ? RepaymentMethodExtension.fromJson(
              json['repayment_method'] as String)
          : null,
      annualInterestRate: json['annual_interest_rate'] != null
          ? (json['annual_interest_rate'] as num).toDouble()
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      monthlyPayment: json['monthly_payment'] as int?,
      isManualPayment: json['is_manual_payment'] as bool? ?? false,
      memo: json['memo'] as String?,
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
      'goal_type': goalType == GoalType.loan ? 'loan' : 'asset',
      'loan_amount': loanAmount,
      'repayment_method': repaymentMethod?.toJson(),
      'annual_interest_rate': annualInterestRate,
      if (startDate != null)
        'start_date': startDate!.toIso8601String().split('T')[0],
      'monthly_payment': monthlyPayment,
      'is_manual_payment': isManualPayment,
      'memo': memo,
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
      'goal_type': goalType == GoalType.loan ? 'loan' : 'asset',
      if (loanAmount != null) 'loan_amount': loanAmount,
      if (repaymentMethod != null)
        'repayment_method': repaymentMethod!.toJson(),
      if (annualInterestRate != null)
        'annual_interest_rate': annualInterestRate,
      if (startDate != null)
        'start_date': startDate!.toIso8601String().split('T')[0],
      if (monthlyPayment != null) 'monthly_payment': monthlyPayment,
      'is_manual_payment': isManualPayment,
      if (memo != null) 'memo': memo,
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
      'goal_type': goalType == GoalType.loan ? 'loan' : 'asset',
      'loan_amount': loanAmount,
      'repayment_method': repaymentMethod?.toJson(),
      'annual_interest_rate': annualInterestRate,
      'start_date':
          startDate != null ? startDate!.toIso8601String().split('T')[0] : null,
      'monthly_payment': monthlyPayment,
      'is_manual_payment': isManualPayment,
      'memo': memo,
    };
  }
}
