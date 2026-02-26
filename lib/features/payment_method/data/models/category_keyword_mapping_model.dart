import '../../domain/entities/category_keyword_mapping.dart';

class CategoryKeywordMappingModel extends CategoryKeywordMapping {
  const CategoryKeywordMappingModel({
    required super.id,
    required super.paymentMethodId,
    required super.ledgerId,
    required super.keyword,
    required super.categoryId,
    required super.sourceType,
    required super.createdBy,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CategoryKeywordMappingModel.fromJson(Map<String, dynamic> json) {
    return CategoryKeywordMappingModel(
      id: json['id'] as String,
      paymentMethodId: json['payment_method_id'] as String,
      ledgerId: json['ledger_id'] as String,
      keyword: json['keyword'] as String,
      categoryId: json['category_id'] as String,
      sourceType: json['source_type'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_method_id': paymentMethodId,
      'ledger_id': ledgerId,
      'keyword': keyword,
      'category_id': categoryId,
      'source_type': sourceType,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String paymentMethodId,
    required String ledgerId,
    required String keyword,
    required String categoryId,
    required String sourceType,
    required String createdBy,
  }) {
    return {
      'payment_method_id': paymentMethodId,
      'ledger_id': ledgerId,
      'keyword': keyword,
      'category_id': categoryId,
      'source_type': sourceType,
      'created_by': createdBy,
    };
  }

  factory CategoryKeywordMappingModel.fromEntity(CategoryKeywordMapping entity) {
    return CategoryKeywordMappingModel(
      id: entity.id,
      paymentMethodId: entity.paymentMethodId,
      ledgerId: entity.ledgerId,
      keyword: entity.keyword,
      categoryId: entity.categoryId,
      sourceType: entity.sourceType,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  CategoryKeywordMapping toEntity() {
    return CategoryKeywordMapping(
      id: id,
      paymentMethodId: paymentMethodId,
      ledgerId: ledgerId,
      keyword: keyword,
      categoryId: categoryId,
      sourceType: sourceType,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
