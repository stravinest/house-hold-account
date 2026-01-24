import 'package:equatable/equatable.dart';

enum PendingTransactionStatus {
  pending,
  confirmed,
  rejected,
  converted;

  static PendingTransactionStatus fromString(String value) {
    switch (value) {
      case 'confirmed':
        return PendingTransactionStatus.confirmed;
      case 'rejected':
        return PendingTransactionStatus.rejected;
      case 'converted':
        return PendingTransactionStatus.converted;
      default:
        return PendingTransactionStatus.pending;
    }
  }

  String toJson() => name;
}

enum SourceType {
  sms,
  notification;

  static SourceType fromString(String value) {
    switch (value) {
      case 'notification':
        return SourceType.notification;
      default:
        return SourceType.sms;
    }
  }

  String toJson() => name;
}

class PendingTransaction extends Equatable {
  final String id;
  final String ledgerId;
  final String? paymentMethodId;
  final String userId;
  final SourceType sourceType;
  final String? sourceSender;
  final String sourceContent;
  final DateTime sourceTimestamp;
  final int? parsedAmount;
  final String? parsedType;
  final String? parsedMerchant;
  final String? parsedCategoryId;
  final DateTime? parsedDate;
  final PendingTransactionStatus status;
  final String? transactionId;
  final String? duplicateHash;
  final bool isDuplicate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime expiresAt;
  final bool isViewed;

  const PendingTransaction({
    required this.id,
    required this.ledgerId,
    this.paymentMethodId,
    required this.userId,
    required this.sourceType,
    this.sourceSender,
    required this.sourceContent,
    required this.sourceTimestamp,
    this.parsedAmount,
    this.parsedType,
    this.parsedMerchant,
    this.parsedCategoryId,
    this.parsedDate,
    this.status = PendingTransactionStatus.pending,
    this.transactionId,
    this.duplicateHash,
    this.isDuplicate = false,
    required this.createdAt,
    required this.updatedAt,
    required this.expiresAt,
    this.isViewed = false,
  });

  bool get isParsed => parsedAmount != null;
  bool get isExpense => parsedType == 'expense';
  bool get isIncome => parsedType == 'income';

  PendingTransaction copyWith({
    String? id,
    String? ledgerId,
    String? paymentMethodId,
    String? userId,
    SourceType? sourceType,
    String? sourceSender,
    String? sourceContent,
    DateTime? sourceTimestamp,
    int? parsedAmount,
    String? parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
    PendingTransactionStatus? status,
    String? transactionId,
    String? duplicateHash,
    bool? isDuplicate,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    bool? isViewed,
  }) {
    return PendingTransaction(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      userId: userId ?? this.userId,
      sourceType: sourceType ?? this.sourceType,
      sourceSender: sourceSender ?? this.sourceSender,
      sourceContent: sourceContent ?? this.sourceContent,
      sourceTimestamp: sourceTimestamp ?? this.sourceTimestamp,
      parsedAmount: parsedAmount ?? this.parsedAmount,
      parsedType: parsedType ?? this.parsedType,
      parsedMerchant: parsedMerchant ?? this.parsedMerchant,
      parsedCategoryId: parsedCategoryId ?? this.parsedCategoryId,
      parsedDate: parsedDate ?? this.parsedDate,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      duplicateHash: duplicateHash ?? this.duplicateHash,
      isDuplicate: isDuplicate ?? this.isDuplicate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isViewed: isViewed ?? this.isViewed,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ledgerId,
    paymentMethodId,
    userId,
    sourceType,
    sourceSender,
    sourceContent,
    sourceTimestamp,
    parsedAmount,
    parsedType,
    parsedMerchant,
    parsedCategoryId,
    parsedDate,
    status,
    transactionId,
    duplicateHash,
    isDuplicate,
    createdAt,
    updatedAt,
    expiresAt,
    isViewed,
  ];
}
