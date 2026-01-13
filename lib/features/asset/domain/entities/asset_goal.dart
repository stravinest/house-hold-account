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
    );
  }
}
