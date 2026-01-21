import '../../domain/entities/pending_transaction.dart';

class PendingTransactionModel extends PendingTransaction {
  const PendingTransactionModel({
    required super.id,
    required super.ledgerId,
    super.paymentMethodId,
    required super.userId,
    required super.sourceType,
    super.sourceSender,
    required super.sourceContent,
    required super.sourceTimestamp,
    super.parsedAmount,
    super.parsedType,
    super.parsedMerchant,
    super.parsedCategoryId,
    super.parsedDate,
    super.status,
    super.transactionId,
    super.duplicateHash,
    required super.createdAt,
    required super.updatedAt,
    required super.expiresAt,
  });

  factory PendingTransactionModel.fromJson(Map<String, dynamic> json) {
    return PendingTransactionModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      paymentMethodId: json['payment_method_id'] as String?,
      userId: json['user_id'] as String,
      sourceType: SourceType.fromString(json['source_type'] as String),
      sourceSender: json['source_sender'] as String?,
      sourceContent: json['source_content'] as String,
      sourceTimestamp: DateTime.parse(json['source_timestamp'] as String),
      parsedAmount: json['parsed_amount'] as int?,
      parsedType: json['parsed_type'] as String?,
      parsedMerchant: json['parsed_merchant'] as String?,
      parsedCategoryId: json['parsed_category_id'] as String?,
      parsedDate: json['parsed_date'] != null
          ? DateTime.parse(json['parsed_date'] as String)
          : null,
      status: PendingTransactionStatus.fromString(json['status'] as String),
      transactionId: json['transaction_id'] as String?,
      duplicateHash: json['duplicate_hash'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'payment_method_id': paymentMethodId,
      'user_id': userId,
      'source_type': sourceType.toJson(),
      'source_sender': sourceSender,
      'source_content': sourceContent,
      'source_timestamp': sourceTimestamp.toIso8601String(),
      'parsed_amount': parsedAmount,
      'parsed_type': parsedType,
      'parsed_merchant': parsedMerchant,
      'parsed_category_id': parsedCategoryId,
      'parsed_date': parsedDate?.toIso8601String().split('T').first,
      'status': status.toJson(),
      'transaction_id': transactionId,
      'duplicate_hash': duplicateHash,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String ledgerId,
    String? paymentMethodId,
    required String userId,
    required SourceType sourceType,
    String? sourceSender,
    required String sourceContent,
    required DateTime sourceTimestamp,
    int? parsedAmount,
    String? parsedType,
    String? parsedMerchant,
    String? parsedCategoryId,
    DateTime? parsedDate,
    String? duplicateHash,
    PendingTransactionStatus? status,
  }) {
    return {
      'ledger_id': ledgerId,
      if (status != null) 'status': status.toJson(),
      if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
      'user_id': userId,
      'source_type': sourceType.toJson(),
      if (sourceSender != null) 'source_sender': sourceSender,
      'source_content': sourceContent,
      'source_timestamp': sourceTimestamp.toIso8601String(),
      if (parsedAmount != null) 'parsed_amount': parsedAmount,
      if (parsedType != null) 'parsed_type': parsedType,
      if (parsedMerchant != null) 'parsed_merchant': parsedMerchant,
      if (parsedCategoryId != null) 'parsed_category_id': parsedCategoryId,
      if (parsedDate != null)
        'parsed_date': parsedDate.toIso8601String().split('T').first,
      if (duplicateHash != null) 'duplicate_hash': duplicateHash,
    };
  }

  static Map<String, dynamic> toUpdateStatusJson({
    required PendingTransactionStatus status,
    String? transactionId,
  }) {
    return {
      'status': status.toJson(),
      'updated_at': DateTime.now().toIso8601String(),
      if (transactionId != null) 'transaction_id': transactionId,
    };
  }
}
