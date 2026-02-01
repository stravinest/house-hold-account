import 'package:flutter/material.dart';

enum NotificationType {
  // 기존 (하위 호환성 - deprecated)
  @Deprecated('Use transactionAdded, transactionUpdated, transactionDeleted instead')
  sharedLedgerChange('shared_ledger_change'),
  inviteReceived('invite_received'),
  inviteAccepted('invite_accepted'),

  // 신규 - 공유 가계부
  transactionAdded('transaction_added'),
  transactionUpdated('transaction_updated'),
  transactionDeleted('transaction_deleted'),

  // 신규 - 자동수집
  autoCollectSuggested('auto_collect_suggested'),
  autoCollectSaved('auto_collect_saved');

  const NotificationType(this.value);

  final String value;

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown notification type: $value'),
    );
  }

  /// UI 표시용 아이콘
  IconData get icon {
    switch (this) {
      case NotificationType.transactionAdded:
        return Icons.add_circle_outline;
      case NotificationType.transactionUpdated:
        return Icons.edit_outlined;
      case NotificationType.transactionDeleted:
        return Icons.delete_outline;
      case NotificationType.autoCollectSuggested:
        return Icons.notifications_outlined;
      case NotificationType.autoCollectSaved:
        return Icons.save_outlined;
      case NotificationType.inviteReceived:
        return Icons.mail_outline;
      case NotificationType.inviteAccepted:
        return Icons.check_circle_outline;
      case NotificationType.sharedLedgerChange:
        return Icons.people_outline;
    }
  }
}
