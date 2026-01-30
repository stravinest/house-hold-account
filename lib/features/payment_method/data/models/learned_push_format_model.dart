import 'dart:convert';

import '../../domain/entities/learned_push_format.dart';

class LearnedPushFormatModel extends LearnedPushFormat {
  const LearnedPushFormatModel({
    required super.id,
    required super.paymentMethodId,
    required super.packageName,
    required super.appKeywords,
    required super.amountRegex,
    required super.typeKeywords,
    super.merchantRegex,
    super.dateRegex,
    super.sampleNotification,
    super.confidence,
    super.matchCount,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LearnedPushFormatModel.fromJson(Map<String, dynamic> json) {
    final typeKeywordsRaw = json['type_keywords'];
    Map<String, List<String>> typeKeywords = {
      'income': ['입금', '충전'],
      'expense': ['출금', '결제', '승인', '이체'],
    };

    if (typeKeywordsRaw != null) {
      if (typeKeywordsRaw is String) {
        final decoded = jsonDecode(typeKeywordsRaw) as Map<String, dynamic>;
        typeKeywords = decoded.map(
          (key, value) => MapEntry(key, (value as List).cast<String>()),
        );
      } else if (typeKeywordsRaw is Map) {
        typeKeywords = (typeKeywordsRaw as Map<String, dynamic>).map(
          (key, value) => MapEntry(key, (value as List).cast<String>()),
        );
      }
    }

    final appKeywordsRaw = json['app_keywords'];
    List<String> appKeywords = [];
    if (appKeywordsRaw != null) {
      if (appKeywordsRaw is List) {
        appKeywords = appKeywordsRaw.cast<String>();
      }
    }

    return LearnedPushFormatModel(
      id: json['id'] as String,
      paymentMethodId: json['payment_method_id'] as String,
      packageName: json['package_name'] as String,
      appKeywords: appKeywords,
      amountRegex: json['amount_regex'] as String,
      typeKeywords: typeKeywords,
      merchantRegex: json['merchant_regex'] as String?,
      dateRegex: json['date_regex'] as String?,
      sampleNotification: json['sample_notification'] as String?,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      matchCount: json['match_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_method_id': paymentMethodId,
      'package_name': packageName,
      'app_keywords': appKeywords,
      'amount_regex': amountRegex,
      'type_keywords': typeKeywords,
      'merchant_regex': merchantRegex,
      'date_regex': dateRegex,
      'sample_notification': sampleNotification,
      'confidence': confidence,
      'match_count': matchCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String paymentMethodId,
    required String packageName,
    List<String> appKeywords = const [],
    required String amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    String? sampleNotification,
    double confidence = 0.8,
  }) {
    return {
      'payment_method_id': paymentMethodId,
      'package_name': packageName,
      'app_keywords': appKeywords,
      'amount_regex': amountRegex,
      'type_keywords':
          typeKeywords ??
          {
            'income': ['입금', '충전'],
            'expense': ['출금', '결제', '승인', '이체'],
          },
      if (merchantRegex != null) 'merchant_regex': merchantRegex,
      if (dateRegex != null) 'date_regex': dateRegex,
      if (sampleNotification != null) 'sample_notification': sampleNotification,
      'confidence': confidence,
    };
  }

  /// Entity를 Model로 변환
  factory LearnedPushFormatModel.fromEntity(LearnedPushFormat entity) {
    return LearnedPushFormatModel(
      id: entity.id,
      paymentMethodId: entity.paymentMethodId,
      packageName: entity.packageName,
      appKeywords: entity.appKeywords,
      amountRegex: entity.amountRegex,
      typeKeywords: entity.typeKeywords,
      merchantRegex: entity.merchantRegex,
      dateRegex: entity.dateRegex,
      sampleNotification: entity.sampleNotification,
      confidence: entity.confidence,
      matchCount: entity.matchCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Model을 Entity로 변환
  LearnedPushFormat toEntity() {
    return LearnedPushFormat(
      id: id,
      paymentMethodId: paymentMethodId,
      packageName: packageName,
      appKeywords: appKeywords,
      amountRegex: amountRegex,
      typeKeywords: typeKeywords,
      merchantRegex: merchantRegex,
      dateRegex: dateRegex,
      sampleNotification: sampleNotification,
      confidence: confidence,
      matchCount: matchCount,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
