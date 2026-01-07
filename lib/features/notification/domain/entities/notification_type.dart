/// 알림 유형을 정의하는 enum
enum NotificationType {
  /// 예산 경고 (예산의 80% 초과 시)
  budgetWarning('budget_warning'),

  /// 예산 초과 (예산의 100% 초과 시)
  budgetExceeded('budget_exceeded'),

  /// 공유 가계부 변경 (거래 추가/수정/삭제)
  sharedLedgerChange('shared_ledger_change'),

  /// 가계부 초대 받음
  inviteReceived('invite_received'),

  /// 가계부 초대 수락됨
  inviteAccepted('invite_accepted');

  const NotificationType(this.value);

  final String value;

  /// 문자열 값으로부터 NotificationType을 생성
  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => throw ArgumentError('Unknown notification type: $value'),
    );
  }
}
