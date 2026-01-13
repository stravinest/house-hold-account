import 'package:equatable/equatable.dart';

class AssetStatistics extends Equatable {
  final int totalAmount;
  final int monthlyChange;
  final double monthlyChangeRate;
  final double annualGrowthRate;
  final List<MonthlyAsset> monthly;
  final List<CategoryAsset> byCategory;

  const AssetStatistics({
    required this.totalAmount,
    required this.monthlyChange,
    required this.monthlyChangeRate,
    required this.annualGrowthRate,
    required this.monthly,
    required this.byCategory,
  });

  @override
  List<Object?> get props => [
    totalAmount,
    monthlyChange,
    monthlyChangeRate,
    annualGrowthRate,
    monthly,
    byCategory,
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
