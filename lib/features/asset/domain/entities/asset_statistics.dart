import 'package:equatable/equatable.dart';

class AssetStatistics extends Equatable {
  final int totalAmount;
  final int monthlyChange;
  final double monthlyChangeRate;
  final double annualGrowthRate;
  final List<MonthlyAsset> monthly;
  final List<CategoryAsset> byCategory;
  final AssetTypeBreakdown byType;

  const AssetStatistics({
    required this.totalAmount,
    required this.monthlyChange,
    required this.monthlyChangeRate,
    required this.annualGrowthRate,
    required this.monthly,
    required this.byCategory,
    required this.byType,
  });

  @override
  List<Object?> get props => [
    totalAmount,
    monthlyChange,
    monthlyChangeRate,
    annualGrowthRate,
    monthly,
    byCategory,
    byType,
  ];
}

class MonthlyAsset extends Equatable {
  final int year;
  final int month;
  final int amount;

  const MonthlyAsset({
    required this.year,
    required this.month,
    required this.amount,
  });

  @override
  List<Object?> get props => [year, month, amount];
}

class CategoryAsset extends Equatable {
  final String categoryId;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;
  final int amount;
  final List<AssetItem> items;

  const CategoryAsset({
    required this.categoryId,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    required this.amount,
    required this.items,
  });

  @override
  List<Object?> get props => [
    categoryId,
    categoryName,
    categoryIcon,
    categoryColor,
    amount,
    items,
  ];
}

class AssetItem extends Equatable {
  final String id;
  final String title;
  final int amount;
  final DateTime? maturityDate;

  const AssetItem({
    required this.id,
    required this.title,
    required this.amount,
    this.maturityDate,
  });

  @override
  List<Object?> get props => [id, title, amount, maturityDate];
}

class AssetTypeBreakdown extends Equatable {
  final int savingAmount;
  final int investmentAmount;
  final int realEstateAmount;

  const AssetTypeBreakdown({
    required this.savingAmount,
    required this.investmentAmount,
    required this.realEstateAmount,
  });

  int get total => savingAmount + investmentAmount + realEstateAmount;

  double get savingRatio => total == 0 ? 0.0 : savingAmount / total;
  double get investmentRatio => total == 0 ? 0.0 : investmentAmount / total;
  double get realEstateRatio => total == 0 ? 0.0 : realEstateAmount / total;

  @override
  List<Object?> get props => [savingAmount, investmentAmount, realEstateAmount];
}
