import 'package:equatable/equatable.dart';

class Ledger extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String currency;
  final String ownerId;
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ledger({
    required this.id,
    required this.name,
    this.description,
    required this.currency,
    required this.ownerId,
    required this.isShared,
    required this.createdAt,
    required this.updatedAt,
  });

  Ledger copyWith({
    String? id,
    String? name,
    String? description,
    String? currency,
    String? ownerId,
    bool? isShared,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ledger(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      currency: currency ?? this.currency,
      ownerId: ownerId ?? this.ownerId,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        currency,
        ownerId,
        isShared,
        createdAt,
        updatedAt,
      ];
}

class LedgerMember extends Equatable {
  final String id;
  final String ledgerId;
  final String userId;
  final String role; // owner, editor, viewer
  final DateTime joinedAt;
  final String? displayName;
  final String? email;
  final String? avatarUrl;

  const LedgerMember({
    required this.id,
    required this.ledgerId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.displayName,
    this.email,
    this.avatarUrl,
  });

  factory LedgerMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;

    return LedgerMember(
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

  bool get isOwner => role == 'owner';
  bool get isEditor => role == 'editor';
  bool get isViewer => role == 'viewer';
  bool get canEdit => isOwner || isEditor;

  @override
  List<Object?> get props => [
        id,
        ledgerId,
        userId,
        role,
        joinedAt,
        displayName,
        email,
        avatarUrl,
      ];
}
