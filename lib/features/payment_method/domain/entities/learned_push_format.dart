import 'package:equatable/equatable.dart';

import 'learned_format.dart';

class LearnedPushFormat extends Equatable implements LearnedFormat {
  final String id;
  final String paymentMethodId;
  final String packageName;
  final List<String> appKeywords;
  @override
  final String amountRegex;
  @override
  final Map<String, List<String>> typeKeywords;
  @override
  final String? merchantRegex;
  @override
  final String? dateRegex;
  final String? sampleNotification;
  @override
  final double confidence;
  final int matchCount;
  final List<String> excludedKeywords;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LearnedPushFormat({
    required this.id,
    required this.paymentMethodId,
    required this.packageName,
    required this.appKeywords,
    required this.amountRegex,
    required this.typeKeywords,
    this.merchantRegex,
    this.dateRegex,
    this.sampleNotification,
    this.confidence = 0.8,
    this.matchCount = 0,
    this.excludedKeywords = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool matchesPackageName(String packageName) {
    return this.packageName == packageName;
  }

  bool matchesNotification(String packageName, String content) {
    if (!matchesPackageName(packageName)) return false;
    final contentLower = content.toLowerCase();
    if (!appKeywords.any((kw) => contentLower.contains(kw.toLowerCase()))) {
      return false;
    }
    if (excludedKeywords.any((kw) => contentLower.contains(kw.toLowerCase()))) {
      return false;
    }
    return true;
  }

  LearnedPushFormat copyWith({
    String? id,
    String? paymentMethodId,
    String? packageName,
    List<String>? appKeywords,
    String? amountRegex,
    Map<String, List<String>>? typeKeywords,
    String? merchantRegex,
    String? dateRegex,
    String? sampleNotification,
    double? confidence,
    int? matchCount,
    List<String>? excludedKeywords,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LearnedPushFormat(
      id: id ?? this.id,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      packageName: packageName ?? this.packageName,
      appKeywords: appKeywords ?? this.appKeywords,
      amountRegex: amountRegex ?? this.amountRegex,
      typeKeywords: typeKeywords ?? this.typeKeywords,
      merchantRegex: merchantRegex ?? this.merchantRegex,
      dateRegex: dateRegex ?? this.dateRegex,
      sampleNotification: sampleNotification ?? this.sampleNotification,
      confidence: confidence ?? this.confidence,
      matchCount: matchCount ?? this.matchCount,
      excludedKeywords: excludedKeywords ?? this.excludedKeywords,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    paymentMethodId,
    packageName,
    appKeywords,
    amountRegex,
    typeKeywords,
    merchantRegex,
    dateRegex,
    sampleNotification,
    confidence,
    matchCount,
    excludedKeywords,
    createdAt,
    updatedAt,
  ];
}
