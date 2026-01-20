import 'package:equatable/equatable.dart';

class LearnedSmsFormat extends Equatable {
  final String id;
  final String paymentMethodId;
  final String senderPattern;
  final List<String> senderKeywords;
  final String amountRegex;
  final Map<String, List<String>> typeKeywords;
  final String? merchantRegex;
  final String? dateRegex;
  final String? sampleSms;
  final bool isSystem;
  final double confidence;
  final int matchCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearnedSmsFormat({
    required this.id,
    required this.paymentMethodId,
    required this.senderPattern,
    required this.senderKeywords,
    required this.amountRegex,
    required this.typeKeywords,
    this.merchantRegex,
    this.dateRegex,
    this.sampleSms,
    this.isSystem = false,
    this.confidence = 0.8,
    this.matchCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  bool matchesSender(String sender) {
    if (sender.contains(senderPattern)) return true;
    return senderKeywords.any((keyword) => sender.contains(keyword));
  }

  LearnedSmsFormat copyWith({
    String? id,
    String? paymentMethodId,
    String? senderPattern,
    List<String>? senderKeywords,
    String? amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    String? sampleSms,
    bool? isSystem,
    double? confidence,
    int? matchCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearnedSmsFormat(
      id: id ?? this.id,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      senderPattern: senderPattern ?? this.senderPattern,
      senderKeywords: senderKeywords ?? this.senderKeywords,
      amountRegex: amountRegex ?? this.amountRegex,
      typeKeywords: typeKeywords ?? this.typeKeywords,
      merchantRegex: merchantRegex ?? this.merchantRegex,
      dateRegex: dateRegex ?? this.dateRegex,
      sampleSms: sampleSms ?? this.sampleSms,
      isSystem: isSystem ?? this.isSystem,
      confidence: confidence ?? this.confidence,
      matchCount: matchCount ?? this.matchCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    paymentMethodId,
    senderPattern,
    senderKeywords,
    amountRegex,
    typeKeywords,
    merchantRegex,
    dateRegex,
    sampleSms,
    isSystem,
    confidence,
    matchCount,
    createdAt,
    updatedAt,
  ];
}
