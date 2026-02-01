# TODO: 자동수집 알림 통합

## 개요
현재 NotificationService는 구현되어 있지만, 실제 자동수집 시점에 알림을 전송하는 로직이 연동되지 않았습니다.

## 구현 위치

### 옵션 1: AutoSaveService에서 전송 (권장)
**파일**: `lib/features/payment_method/data/services/auto_save_service.dart`

**이유**:
- AutoSaveService가 SMS/Push 수신 이벤트를 중앙 집중식으로 관리
- pending 거래 생성 시점을 정확히 파악 가능

**구현 예시**:
```dart
import '../../../notification/data/services/notification_service.dart';
import '../../../notification/domain/entities/notification_type.dart';

void _setupEventListeners() {
  // ... 기존 리스너 코드

  // SMS 처리 완료 후
  _smsSubscription = SmsListenerService.instance.onSmsProcessed.listen((event) async {
    if (event.success) {
      // pending 거래 생성 성공 시 알림 전송
      final notificationService = NotificationService();
      await notificationService.sendAutoCollectNotification(
        userId: _currentUserId!,
        type: NotificationType.autoCollectSuggested,
        title: l10n.notificationAutoCollectSuggestedTitle,
        body: l10n.notificationAutoCollectSuggestedBody(
          event.merchant ?? '알 수 없음',
          event.amount ?? 0,
        ),
        data: {
          'pendingId': event.pendingId,
          'amount': event.amount,
        },
      );
    }
  });
}
```

### 옵션 2: Provider 레이어에서 전송
**파일**: `lib/features/payment_method/presentation/providers/pending_transaction_provider.dart`

**구현 예시**:
```dart
// Realtime subscription에서 새 pending 거래 감지 시
void _subscribeToChanges() {
  _subscription = _repository.subscribePendingTransactions(
    ledgerId: _ledgerId,
    userId: _userId,
    onInsert: (newPending) async {
      // 새 pending 거래가 생성되었을 때 알림 전송
      if (newPending.sourceType == SourceType.sms || newPending.sourceType == SourceType.push) {
        final notificationService = NotificationService();
        await notificationService.sendAutoCollectNotification(
          userId: _userId!,
          type: NotificationType.autoCollectSuggested,
          title: l10n.notificationAutoCollectSuggestedTitle,
          body: l10n.notificationAutoCollectSuggestedBody(
            newPending.parsedMerchant ?? '알 수 없음',
            newPending.parsedAmount ?? 0,
          ),
          data: {
            'pendingId': newPending.id,
            'amount': newPending.parsedAmount,
          },
        );
      }
    },
  );
}
```

## 다국어 키 (이미 추가됨)
- `notificationAutoCollectSuggestedTitle`: "새로운 거래 제안"
- `notificationAutoCollectSuggestedBody`: "{merchant}에서 {amount}원 거래가 수집되었습니다. 확인해주세요."
- `notificationAutoCollectSavedTitle`: "거래 자동저장 완료"
- `notificationAutoCollectSavedBody`: "{title} {amount}원이 자동으로 저장되었습니다."

## 우선순위
Medium - 기능은 작동하지만 사용자 경험 개선을 위해 구현 권장

## 예상 작업 시간
1-2시간
