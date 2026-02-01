# Gap Analysis: 알림 시스템 세분화 및 자동수집 알림 추가

## 1. 분석 개요

**Feature**: notification-segmentation (알림 시스템 세분화 및 자동수집 알림 추가)
**분석일**: 2026-02-01
**Design 문서**: docs/02-design/features/notification-segmentation.design.md

---

## 2. Overall Match Rate: **85%**

| Category | Score | Status |
|----------|:-----:|:------:|
| Database Schema | 100% | ✅ Match |
| NotificationType enum | 100% | ✅ Match |
| NotificationSettingsRepository | 100% | ✅ Match |
| NotificationSettingsPage UI | 100% | ✅ Match |
| i18n (다국어 - 설정 UI) | 100% | ✅ Match |
| Edge Function | 100% | ✅ Match |
| NotificationService | 100% | ✅ Match |
| **i18n (알림 메시지)** | **0%** | ❌ **Missing** |
| **PendingTransactionRepository 연동** | **0%** | ❌ **Missing** |

---

## 3. Missing Features (Design에 있지만 구현되지 않음)

### 3.1 [High Priority] PendingTransactionRepository 연동 미구현

**Design 문서 Section 4.2**에서 정의된 자동수집 알림 전송 로직이 구현되지 않았습니다.

**파일**: `lib/features/payment_method/data/repositories/pending_transaction_repository.dart`

**누락 내용**:
- `NotificationService` import 없음
- `createPendingTransaction()` 에서 suggest 모드 알림 전송 로직 없음
- `confirmPendingTransaction()` 에서 auto 모드 알림 전송 로직 없음
- `autoSaveMode` 파라미터 전달 체계 없음

**Design 명세** (Section 4.2):
```dart
// AutoSaveService 또는 PendingTransactionRepository
Future<void> savePendingTransaction(PendingTransaction pending) async {
  // 1. pending 거래 저장
  await _repository.save(pending);

  // 2. 알림 전송 (suggest 모드)
  if (paymentMethod.autoSaveMode == AutoSaveMode.suggest) {
    await _sendNotification(
      userId: pending.userId,
      type: NotificationType.autoCollectSuggested,
      data: {'pendingId': pending.id, 'amount': pending.amount},
    );
  }
}
```

**수정 방안**:
1. Provider 레이어에서 알림 전송 (Repository가 아닌 Presentation 레이어에서 호출)
2. `PendingTransactionProvider.confirmTransaction()` 메서드 수정
3. AutoSaveMode 확인 후 NotificationService 호출

---

### 3.2 [Medium Priority] 다국어 키 4개 누락

**Design 문서 Section 5**에서 정의된 알림 메시지 다국어 키가 arb 파일에 없습니다.

| 누락된 키 | 용도 | Design 명세 |
|-----------|------|-------------|
| `notificationAutoCollectSuggestedTitle` | 자동수집 제안 알림 제목 | '새로운 거래 제안' |
| `notificationAutoCollectSuggestedBody` | 자동수집 제안 알림 본문 | '{merchant}에서 {amount}원 거래가 수집되었습니다. 확인해주세요.' |
| `notificationAutoCollectSavedTitle` | 자동저장 완료 알림 제목 | '거래 자동저장 완료' |
| `notificationAutoCollectSavedBody` | 자동저장 완료 알림 본문 | '{title} {amount}원이 자동으로 저장되었습니다.' |

**현재 상태**: 설정 UI용 키만 추가됨 (notificationAutoCollectSuggested, notificationAutoCollectSaved 등)

**수정 방안**:
1. `app_ko.arb`에 4개 키 추가
2. `app_en.arb`에 영어 번역 추가
3. `flutter pub run build_runner build` 실행

---

## 4. Match된 항목 (구현 완료)

### 4.1 Database Schema ✅

**파일**: `supabase/migrations/045_add_notification_segmentation.sql`

- ✅ `notification_settings` 테이블 컬럼 5개 추가:
  - transaction_added_enabled
  - transaction_updated_enabled
  - transaction_deleted_enabled
  - auto_collect_suggested_enabled
  - auto_collect_saved_enabled
- ✅ `push_notifications` 테이블 CHECK 제약 조건 수정 (5개 타입 추가)
- ✅ `handle_new_user_notification_settings()` 트리거 함수 업데이트

**Design 일치도**: 100%

---

### 4.2 Flutter Code ✅

#### NotificationType enum
**파일**: `lib/features/notification/domain/entities/notification_type.dart`

- ✅ 8개 타입 모두 구현:
  - sharedLedgerChange (deprecated)
  - transactionAdded, transactionUpdated, transactionDeleted
  - autoCollectSuggested, autoCollectSaved
  - inviteReceived, inviteAccepted
- ✅ `icon` getter 구현 (각 타입별 아이콘)

**Design 일치도**: 100%

#### NotificationSettingsRepository
**파일**: `lib/features/notification/data/repositories/notification_settings_repository.dart`

- ✅ `_getColumnName()`: 8개 타입 모두 매핑
- ✅ `getNotificationSettings()`: 8개 타입 반환
- ✅ `initializeDefaultSettings()`: 신규 컬럼 포함

**Design 일치도**: 100%

#### NotificationSettingsPage UI
**파일**: `lib/features/notification/presentation/pages/notification_settings_page.dart`

- ✅ 3개 섹션 구현:
  - 공유 가계부 알림 (transaction_added/updated/deleted)
  - 자동수집 알림 (auto_collect_suggested/saved)
  - 초대 알림 (invite_received/accepted)
- ✅ 각 섹션별 토글 스위치 구현

**Design 일치도**: 100%

#### NotificationService (신규)
**파일**: `lib/features/notification/data/services/notification_service.dart`

- ✅ `sendAutoCollectNotification()` 메서드 구현
- ✅ 알림 설정 확인 로직
- ✅ 로컬 알림 표시 (LocalNotificationService 사용)
- ✅ 알림 히스토리 저장 (_savePushNotification)

**Design 일치도**: 100%

---

### 4.3 Edge Function ✅

**파일**: `supabase/functions/send-push-notification/index.ts`

- ✅ Line 364-383: INSERT/UPDATE/DELETE에 따른 알림 설정 컬럼 분기
  ```typescript
  switch (payload.type) {
    case 'INSERT':
      notificationTypeColumn = 'transaction_added_enabled';
      notificationType = 'transaction_added';
      break;
    // ...
  }
  ```
- ✅ Line 453: FCM data에 세분화된 notificationType 전송
- ✅ Line 503: 알림 히스토리 저장 시 세분화된 타입 사용

**Design 일치도**: 100%

---

### 4.4 다국어 (설정 UI용) ✅

**파일**: `lib/l10n/app_ko.arb`, `lib/l10n/app_en.arb`

- ✅ 설정 페이지용 키 10개 추가:
  - notificationSectionSharedLedger / notificationSectionAutoCollect
  - notificationTransactionAdded / notificationTransactionAddedDesc
  - notificationTransactionUpdated / notificationTransactionUpdatedDesc
  - notificationTransactionDeleted / notificationTransactionDeletedDesc
  - notificationAutoCollectSuggested / notificationAutoCollectSuggestedDesc
  - notificationAutoCollectSaved / notificationAutoCollectSavedDesc

**Design 일치도**: 100%

---

## 5. 권장 조치사항

### 즉시 수행 필요 (High Priority)

#### 5.1 다국어 키 4개 추가

**app_ko.arb**:
```json
"notificationAutoCollectSuggestedTitle": "새로운 거래 제안",
"notificationAutoCollectSuggestedBody": "{merchant}에서 {amount}원 거래가 수집되었습니다. 확인해주세요.",
"@notificationAutoCollectSuggestedBody": {
  "placeholders": {
    "merchant": {"type": "String"},
    "amount": {"type": "int"}
  }
},
"notificationAutoCollectSavedTitle": "거래 자동저장 완료",
"notificationAutoCollectSavedBody": "{title} {amount}원이 자동으로 저장되었습니다.",
"@notificationAutoCollectSavedBody": {
  "placeholders": {
    "title": {"type": "String"},
    "amount": {"type": "int"}
  }
}
```

**app_en.arb**:
```json
"notificationAutoCollectSuggestedTitle": "New Transaction Suggested",
"notificationAutoCollectSuggestedBody": "Transaction of {amount} at {merchant} has been collected. Please review.",
"notificationAutoCollectSavedTitle": "Transaction Auto-Saved",
"notificationAutoCollectSavedBody": "{title} {amount} has been automatically saved."
```

#### 5.2 PendingTransactionRepository 연동

**옵션 1**: Provider 레이어에서 알림 전송 (권장)

`PendingTransactionProvider`에서 거래 확정 후 알림 전송:

```dart
// lib/features/payment_method/presentation/providers/pending_transaction_provider.dart
import '../../../notification/data/services/notification_service.dart';
import '../../../notification/domain/entities/notification_type.dart';

Future<void> confirmTransaction(String id) async {
  // ... 기존 거래 생성 로직

  // 알림 전송 (provider 레이어에서)
  final notificationService = NotificationService();
  await notificationService.sendAutoCollectNotification(
    userId: _userId!,
    type: NotificationType.autoCollectSuggested,
    title: l10n.notificationAutoCollectSuggestedTitle,
    body: l10n.notificationAutoCollectSuggestedBody(
      pendingTx.parsedMerchant ?? l10n.commonUnknown,
      pendingTx.parsedAmount!,
    ),
    data: {
      'pendingId': id,
      'amount': pendingTx.parsedAmount,
    },
  );
}
```

**옵션 2**: AutoSaveService에서 직접 전송

AutoSaveService에서 pending 거래 생성 시 알림 전송 (현재 아키텍처에 더 적합할 수 있음)

---

### 선택 사항 (Nice to Have)

#### 5.3 마이그레이션 실행

```bash
cd supabase
npx supabase db push
```

#### 5.4 Edge Function 배포

```bash
cd supabase
npx supabase functions deploy send-push-notification
```

---

## 6. 결론

### 구현 현황 요약

| 구현 영역 | 완료도 | 비고 |
|-----------|:------:|------|
| 데이터베이스 | 100% | 마이그레이션 파일 완성 |
| Flutter UI | 100% | 설정 페이지 완성 |
| Edge Function | 100% | 거래 알림 세분화 완료 |
| NotificationService | 100% | 기본 구조 완성 |
| **다국어 (알림 메시지)** | **0%** | **4개 키 누락** |
| **자동수집 알림 통합** | **0%** | **실제 전송 로직 미연동** |

### Overall Match Rate: **85%**

**완료된 부분**:
- ✅ 데이터베이스 스키마 변경 (100%)
- ✅ Flutter 알림 설정 UI 및 Repository (100%)
- ✅ Edge Function 수정 (공유 가계부 거래 알림) (100%)
- ✅ NotificationService 기본 구조 (100%)

**미완료 부분**:
- ❌ 자동수집 알림 메시지 다국어 키 (0%)
- ❌ PendingTransactionRepository와 NotificationService 연동 (0%)

자동수집 알림 기능을 완전히 작동시키려면 **다국어 키 추가**와 **Provider/Service 레이어 연동** 작업이 필수입니다.

---

**작성일**: 2026-02-01
**분석자**: Claude Code (gap-detector agent)
**Match Rate**: 85%
