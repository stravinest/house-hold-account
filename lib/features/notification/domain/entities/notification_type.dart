enum NotificationType {
  sharedLedgerChange('shared_ledger_change'),
  inviteReceived('invite_received'),
  inviteAccepted('invite_accepted');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown notification type: $value'),
    );
  }
}
