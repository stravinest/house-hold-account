import 'package:equatable/equatable.dart';

class LearnedPushFormat extends Equatable {
  final String id;
  final String paymentMethodId;
  final String packageName;
  final List<String> appKeywords;
  final String amountRegex;
  final Map<String, List<String>> typeKeywords;
  final String? merchantRegex;
  final String? dateRegex;
  final String? sampleNotification;
  final double confidence;
  final int matchCount;
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
    required this.createdAt,
    required this.updatedAt,
  });

  bool matchesPackageName(String packageName) {
    return this.packageName == packageName;
  }

  bool matchesNotification(String packageName, String content) {
    if (!matchesPackageName(packageName)) return false;
    return appKeywords.any((keyword) => content.contains(keyword));
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
    createdAt,
    updatedAt,
  ];
}
