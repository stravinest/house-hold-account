import 'dart:convert';

import '../../domain/entities/learned_sms_format.dart';
import '../services/financial_constants.dart';

class LearnedSmsFormatModel extends LearnedSmsFormat {
  const LearnedSmsFormatModel({
    required super.id,
    required super.paymentMethodId,
    required super.senderPattern,
    required super.senderKeywords,
    required super.amountRegex,
    required super.typeKeywords,
    super.merchantRegex,
    super.dateRegex,
    super.sampleSms,
    super.isSystem,
    super.confidence,
    super.matchCount,
    super.excludedKeywords,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LearnedSmsFormatModel.fromJson(Map<String, dynamic> json) {
    final typeKeywordsRaw = json['type_keywords'];
    Map<String, List<String>> typeKeywords = Map.from(
      FinancialConstants.defaultTypeKeywords,
    );

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

    final senderKeywordsRaw = json['sender_keywords'];
    List<String> senderKeywords = [];
    if (senderKeywordsRaw != null) {
      if (senderKeywordsRaw is List) {
        senderKeywords = senderKeywordsRaw.cast<String>();
      }
    }

    final excludedKeywordsRaw = json['excluded_keywords'];
    List<String> excludedKeywords = [];
    if (excludedKeywordsRaw != null) {
      if (excludedKeywordsRaw is List) {
        excludedKeywords = excludedKeywordsRaw.cast<String>();
      }
    }

    return LearnedSmsFormatModel(
      id: json['id'] as String,
      paymentMethodId: json['payment_method_id'] as String,
      senderPattern: json['sender_pattern'] as String,
      senderKeywords: senderKeywords,
      amountRegex: json['amount_regex'] as String,
      typeKeywords: typeKeywords,
      merchantRegex: json['merchant_regex'] as String?,
      dateRegex: json['date_regex'] as String?,
      sampleSms: json['sample_sms'] as String?,
      isSystem: json['is_system'] as bool? ?? false,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
      matchCount: json['match_count'] as int? ?? 0,
      excludedKeywords: excludedKeywords,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payment_method_id': paymentMethodId,
      'sender_pattern': senderPattern,
      'sender_keywords': senderKeywords,
      'amount_regex': amountRegex,
      'type_keywords': typeKeywords,
      'merchant_regex': merchantRegex,
      'date_regex': dateRegex,
      'sample_sms': sampleSms,
      'is_system': isSystem,
      'confidence': confidence,
      'match_count': matchCount,
      'excluded_keywords': excludedKeywords,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String paymentMethodId,
    required String senderPattern,
    List<String> senderKeywords = const [],
    required String amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    String? sampleSms,
    bool isSystem = false,
    double confidence = 0.8,
    List<String> excludedKeywords = const [],
  }) {
    return {
      'payment_method_id': paymentMethodId,
      'sender_pattern': senderPattern,
      'sender_keywords': senderKeywords,
      'amount_regex': amountRegex,
      'type_keywords': typeKeywords ?? FinancialConstants.defaultTypeKeywords,
      if (merchantRegex != null) 'merchant_regex': merchantRegex,
      if (dateRegex != null) 'date_regex': dateRegex,
      if (sampleSms != null) 'sample_sms': sampleSms,
      'is_system': isSystem,
      'confidence': confidence,
      'excluded_keywords': excludedKeywords,
    };
  }

  /// Entity를 Model로 변환
  factory LearnedSmsFormatModel.fromEntity(LearnedSmsFormat entity) {
    return LearnedSmsFormatModel(
      id: entity.id,
      paymentMethodId: entity.paymentMethodId,
      senderPattern: entity.senderPattern,
      senderKeywords: entity.senderKeywords,
      amountRegex: entity.amountRegex,
      typeKeywords: entity.typeKeywords,
      merchantRegex: entity.merchantRegex,
      dateRegex: entity.dateRegex,
      sampleSms: entity.sampleSms,
      isSystem: entity.isSystem,
      confidence: entity.confidence,
      matchCount: entity.matchCount,
      excludedKeywords: entity.excludedKeywords,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Model을 Entity로 변환
  LearnedSmsFormat toEntity() {
    return LearnedSmsFormat(
      id: id,
      paymentMethodId: paymentMethodId,
      senderPattern: senderPattern,
      senderKeywords: senderKeywords,
      amountRegex: amountRegex,
      typeKeywords: typeKeywords,
      merchantRegex: merchantRegex,
      dateRegex: dateRegex,
      sampleSms: sampleSms,
      isSystem: isSystem,
      confidence: confidence,
      matchCount: matchCount,
      excludedKeywords: excludedKeywords,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
