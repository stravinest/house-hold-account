import 'package:equatable/equatable.dart';

class CategoryKeywordMapping extends Equatable {
  final String id;
  final String paymentMethodId;
  final String ledgerId;
  final String keyword;
  final String categoryId;
  final String sourceType; // 'sms' or 'push'
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CategoryKeywordMapping({
    required this.id,
    required this.paymentMethodId,
    required this.ledgerId,
    required this.keyword,
    required this.categoryId,
    required this.sourceType,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryKeywordMapping copyWith({
    String? id,
    String? paymentMethodId,
    String? ledgerId,
    String? keyword,
    String? categoryId,
    String? sourceType,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryKeywordMapping(
      id: id ?? this.id,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      ledgerId: ledgerId ?? this.ledgerId,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      sourceType: sourceType ?? this.sourceType,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    paymentMethodId,
    ledgerId,
    keyword,
    categoryId,
    sourceType,
    createdBy,
    createdAt,
    updatedAt,
  ];
}
