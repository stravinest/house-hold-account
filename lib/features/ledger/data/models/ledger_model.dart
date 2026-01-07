import '../../domain/entities/ledger.dart';

class LedgerModel extends Ledger {
  const LedgerModel({
    required super.id,
    required super.name,
    super.description,
    required super.currency,
    required super.ownerId,
    required super.isShared,
    required super.createdAt,
    required super.updatedAt,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      currency: json['currency'] as String,
      ownerId: json['owner_id'] as String,
      isShared: json['is_shared'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'currency': currency,
      'owner_id': ownerId,
      'is_shared': isShared,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Map<String, dynamic> toCreateJson({
    required String name,
    String? description,
    required String currency,
    required String ownerId,
    bool isShared = false,
  }) {
    return {
      'name': name,
      'description': description,
      'currency': currency,
      'owner_id': ownerId,
      'is_shared': isShared,
    };
  }
}

class LedgerMemberModel extends LedgerMember {
  const LedgerMemberModel({
    required super.id,
    required super.ledgerId,
    required super.userId,
    required super.role,
    required super.joinedAt,
    super.displayName,
    super.email,
    super.avatarUrl,
  });

  factory LedgerMemberModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return LedgerMemberModel(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      userId: json['user_id'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['created_at'] as String),
      displayName: profile?['display_name'] as String?,
      email: profile?['email'] as String?,
      avatarUrl: profile?['avatar_url'] as String?,
    );
  }
}
