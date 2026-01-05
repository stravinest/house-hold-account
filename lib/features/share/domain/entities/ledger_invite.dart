class LedgerInvite {
  final String id;
  final String ledgerId;
  final String inviterUserId;
  final String inviteeEmail;
  final String role;
  final String status; // pending, accepted, rejected
  final DateTime expiresAt;
  final DateTime createdAt;

  // 조인된 데이터
  final String? ledgerName;
  final String? inviterEmail;

  const LedgerInvite({
    required this.id,
    required this.ledgerId,
    required this.inviterUserId,
    required this.inviteeEmail,
    required this.role,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
    this.ledgerName,
    this.inviterEmail,
  });

  factory LedgerInvite.fromJson(Map<String, dynamic> json) {
    // Supabase 조인 alias: ledger:ledgers, inviter:profiles
    final ledger = json['ledger'] as Map<String, dynamic>?;
    final inviter = json['inviter'] as Map<String, dynamic>?;

    return LedgerInvite(
      id: json['id'] as String,
      ledgerId: json['ledger_id'] as String,
      inviterUserId: json['inviter_user_id'] as String,
      inviteeEmail: json['invitee_email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      ledgerName: ledger?['name'] as String?,
      inviterEmail: inviter?['email'] as String?,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isPending && !isExpired;
}
