enum GoalType { asset, loan }

enum RepaymentMethod {
  equalPrincipalInterest,
  equalPrincipal,
  bullet,
  graduated,
}

extension RepaymentMethodExtension on RepaymentMethod {
  String toJson() {
    switch (this) {
      case RepaymentMethod.equalPrincipalInterest:
        return 'equal_principal_interest';
      case RepaymentMethod.equalPrincipal:
        return 'equal_principal';
      case RepaymentMethod.bullet:
        return 'bullet';
      case RepaymentMethod.graduated:
        return 'graduated';
    }
  }

  static RepaymentMethod fromJson(String value) {
    switch (value) {
      case 'equal_principal_interest':
        return RepaymentMethod.equalPrincipalInterest;
      case 'equal_principal':
        return RepaymentMethod.equalPrincipal;
      case 'bullet':
        return RepaymentMethod.bullet;
      case 'graduated':
        return RepaymentMethod.graduated;
      default:
        return RepaymentMethod.equalPrincipalInterest;
    }
  }
}

class AssetGoal {
  final String id;
  final String ledgerId;
  final String title;
  final int targetAmount;
  final DateTime? targetDate;
  final String? assetType;
  final List<String>? categoryIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final GoalType goalType;
  final int? loanAmount;
  final RepaymentMethod? repaymentMethod;
  final double? annualInterestRate;
  final DateTime? startDate;
  final int? monthlyPayment;
  final bool isManualPayment;
  final String? memo;

  const AssetGoal({
    required this.id,
    required this.ledgerId,
    required this.title,
    required this.targetAmount,
    this.targetDate,
    this.assetType,
    this.categoryIds,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.goalType = GoalType.asset,
    this.loanAmount,
    this.repaymentMethod,
    this.annualInterestRate,
    this.startDate,
    this.monthlyPayment,
    this.isManualPayment = false,
    this.memo,
  });

  AssetGoal copyWith({
    String? id,
    String? ledgerId,
    String? title,
    int? targetAmount,
    DateTime? targetDate,
    String? assetType,
    List<String>? categoryIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    GoalType? goalType,
    int? loanAmount,
    RepaymentMethod? repaymentMethod,
    double? annualInterestRate,
    DateTime? startDate,
    int? monthlyPayment,
    bool? isManualPayment,
    String? memo,
  }) {
    return AssetGoal(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      targetDate: targetDate ?? this.targetDate,
      assetType: assetType ?? this.assetType,
      categoryIds: categoryIds ?? this.categoryIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      goalType: goalType ?? this.goalType,
      loanAmount: loanAmount ?? this.loanAmount,
      repaymentMethod: repaymentMethod ?? this.repaymentMethod,
      annualInterestRate: annualInterestRate ?? this.annualInterestRate,
      startDate: startDate ?? this.startDate,
      monthlyPayment: monthlyPayment ?? this.monthlyPayment,
      isManualPayment: isManualPayment ?? this.isManualPayment,
      memo: memo ?? this.memo,
    );
  }
}
