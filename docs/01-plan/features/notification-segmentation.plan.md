# Plan: 알림 시스템 세분화 및 자동수집 알림 추가

## 1. 기능 개요

### 1.1 목적
현재 단일 항목으로 관리되는 '공유 가계부 변경 알림'을 세분화하고, 자동수집 기능 관련 알림을 추가하여 사용자가 원하는 알림만 선택적으로 받을 수 있도록 개선합니다.

### 1.2 핵심 기능
- **공유 가계부 알림 세분화**: 다른 멤버의 거래 추가/수정/삭제 알림을 개별 설정
- **자동수집 알림 추가**: SMS/Push 자동수집 제안 및 자동저장 알림 추가
- **알림 분기 시스템**: 설정에 따라 알림 전송 여부를 동적으로 결정

### 1.3 기대 효과
- 사용자가 불필요한 알림을 차단하여 알림 피로도 감소
- 자동수집 기능의 투명성 향상 (제안/저장 시 즉시 알림)
- 공유 가계부 협업 시 세밀한 알림 제어 가능

## 2. 현재 상태 분석

### 2.1 기존 알림 시스템 구조

**데이터베이스 스키마** (005_add_notification_tables.sql):
```sql
CREATE TABLE notification_settings (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    budget_warning_enabled BOOLEAN DEFAULT TRUE,
    budget_exceeded_enabled BOOLEAN DEFAULT TRUE,
    shared_ledger_change_enabled BOOLEAN DEFAULT TRUE,  -- 현재: 통합 설정
    invite_received_enabled BOOLEAN DEFAULT TRUE,
    invite_accepted_enabled BOOLEAN DEFAULT TRUE,
    ...
);

CREATE TABLE push_notifications (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    type TEXT CHECK (type IN (
        'budget_warning',
        'budget_exceeded',
        'shared_ledger_change',  -- 현재: 통합 타입
        'invite_received',
        'invite_accepted'
    )),
    ...
);
```

**Flutter 코드**:
- `NotificationType` enum: 3가지 타입만 정의 (sharedLedgerChange, inviteReceived, inviteAccepted)
- `NotificationSettings` entity: 타입별 enabled 상태 관리
- `NotificationSettingsPage`: UI에서 토글 스위치로 알림 설정

### 2.2 알림 전송 메커니즘 (추정)
현재 코드에서 명시적인 알림 전송 로직은 확인되지 않음. 다음 사항을 확인 필요:
1. **서버 사이드 알림 전송**: Supabase Edge Functions 또는 Trigger 사용 여부
2. **거래 생성/수정/삭제 시점**: 어디서 알림을 트리거하는지
3. **FCM 전송 로직**: Firebase Cloud Functions 또는 직접 구현 여부

### 2.3 자동수집 기능 현황
- **SMS/Push 수신**: `SmsListenerService`, `NotificationListenerWrapper` 사용
- **임시 거래 저장**: `PendingTransactionRepository`에 pending 상태로 저장
- **AutoSaveMode**:
  - `manual`: 자동수집 비활성화
  - `suggest`: 수집 후 사용자 확인 필요 (UI에 pending 목록 표시)
  - `auto`: 수집 후 즉시 거래 생성
- **현재 문제**: 자동수집 완료 시 알림이 없어 사용자가 인지하기 어려움

## 3. 요구사항 정의

### 3.1 기능 요구사항

#### FR-1: 공유 가계부 알림 세분화
- FR-1.1: 다른 멤버가 거래를 추가했을 때 알림
- FR-1.2: 다른 멤버가 거래를 수정했을 때 알림
- FR-1.3: 다른 멤버가 거래를 삭제했을 때 알림
- FR-1.4: 각 알림을 개별적으로 활성화/비활성화 가능

#### FR-2: 자동수집 알림 추가
- FR-2.1: SMS/Push 수신으로 거래가 제안되었을 때 알림 (`suggest` 모드)
- FR-2.2: 거래가 자동 저장되었을 때 알림 (`auto` 모드)
- FR-2.3: 각 알림을 개별적으로 활성화/비활성화 가능

#### FR-3: 알림 설정 UI
- FR-3.1: 설정 > 알림설정 페이지에 신규 알림 타입 추가
- FR-3.2: 섹션별 그룹화 (공유 가계부 / 자동수집 / 초대)
- FR-3.3: 각 알림의 명확한 설명 제공

#### FR-4: 알림 분기 시스템
- FR-4.1: 거래 생성/수정/삭제 시점에 알림 설정 확인
- FR-4.2: 설정이 활성화된 경우에만 FCM 전송
- FR-4.3: 자동수집 완료 시점에 알림 설정 확인 및 전송

### 3.2 비기능 요구사항
- NFR-1: 기존 사용자는 모든 알림이 활성화된 상태로 마이그레이션 (호환성)
- NFR-2: 알림 전송 성능 최적화 (배치 처리 고려)
- NFR-3: 알림 히스토리 유지 (`push_notifications` 테이블)
- NFR-4: 다국어 지원 (한국어/영어)

## 4. 기술 설계 방향

### 4.1 데이터베이스 스키마 변경

#### 4.1.1 새로운 알림 타입 추가
```sql
-- notification_settings 테이블 컬럼 추가
ALTER TABLE notification_settings
ADD COLUMN transaction_added_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN transaction_updated_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN transaction_deleted_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN auto_collect_suggested_enabled BOOLEAN DEFAULT TRUE,
ADD COLUMN auto_collect_saved_enabled BOOLEAN DEFAULT TRUE;

-- shared_ledger_change_enabled 컬럼 deprecated (호환성 유지)
-- 기존 컬럼은 유지하되 UI에서는 숨김 처리
```

#### 4.1.2 NotificationType enum 확장
```sql
-- push_notifications 테이블 type CHECK 제약 조건 수정
ALTER TABLE push_notifications DROP CONSTRAINT push_notifications_type_check;

ALTER TABLE push_notifications
ADD CONSTRAINT push_notifications_type_check
CHECK (type IN (
    'budget_warning',
    'budget_exceeded',
    'shared_ledger_change',           -- deprecated (호환성)
    'transaction_added',              -- 신규
    'transaction_updated',            -- 신규
    'transaction_deleted',            -- 신규
    'auto_collect_suggested',         -- 신규
    'auto_collect_saved',             -- 신규
    'invite_received',
    'invite_accepted'
));
```

### 4.2 Flutter 코드 변경

#### 4.2.1 NotificationType enum 확장
```dart
enum NotificationType {
  // 기존
  sharedLedgerChange('shared_ledger_change'),  // deprecated
  inviteReceived('invite_received'),
  inviteAccepted('invite_accepted'),

  // 신규 - 공유 가계부
  transactionAdded('transaction_added'),
  transactionUpdated('transaction_updated'),
  transactionDeleted('transaction_deleted'),

  // 신규 - 자동수집
  autoCollectSuggested('auto_collect_suggested'),
  autoCollectSaved('auto_collect_saved');

  // ...
}
```

#### 4.2.2 NotificationSettings entity 확장
현재는 Map<NotificationType, bool> 형태로 관리하고 있으므로, 신규 타입 추가 시 자동 반영됨.

#### 4.2.3 NotificationSettingsPage UI 확장
```dart
// 섹션 구조
1. 공유 가계부 알림
   - 다른 멤버 거래 추가
   - 다른 멤버 거래 수정
   - 다른 멤버 거래 삭제
2. 자동수집 알림
   - 거래 제안 (suggest 모드)
   - 거래 자동저장 (auto 모드)
3. 초대 알림
   - 초대 받음
   - 초대 수락됨
```

### 4.3 알림 전송 로직 구현

#### 4.3.1 거래 변경 시 알림 전송 (공유 가계부)
**현재 파악 필요 사항**:
- 거래 생성/수정/삭제 시점을 어디서 감지하는가?
- Supabase Realtime을 사용하는가, 아니면 직접 API 호출하는가?

**구현 방향**:
```dart
// Option 1: Supabase Database Trigger (권장)
// - transactions 테이블에 AFTER INSERT/UPDATE/DELETE 트리거 추가
// - 트리거 함수에서 ledger_members 조회 후 FCM 전송

// Option 2: Flutter 코드에서 직접 전송
// TransactionRepository.createTransaction() 메서드 내부
Future<void> createTransaction(Transaction transaction) async {
  // 1. 거래 저장
  final result = await _client.from('transactions').insert(...);

  // 2. 공유 가계부인 경우 알림 전송
  if (transaction.ledgerId != null) {
    await _sendNotificationToMembers(
      ledgerId: transaction.ledgerId,
      notificationType: NotificationType.transactionAdded,
      excludeUserId: currentUserId,
    );
  }
}
```

**권장 방식**: Database Trigger 사용
- 장점: Flutter 코드에서 알림 로직 분리, 성능 향상, 안정성 높음
- 단점: SQL 함수 작성 필요, Edge Functions 또는 외부 API 호출 필요

#### 4.3.2 자동수집 시 알림 전송
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

Future<void> confirmTransaction(String pendingId) async {
  // 1. pending 거래 확정 → 실제 거래 생성
  final transaction = await _createTransactionFromPending(pendingId);

  // 2. 알림 전송 (auto 모드)
  if (paymentMethod.autoSaveMode == AutoSaveMode.auto) {
    await _sendNotification(
      userId: transaction.userId,
      type: NotificationType.autoCollectSaved,
      data: {'transactionId': transaction.id, 'amount': transaction.amount},
    );
  }
}
```

### 4.4 알림 분기 시스템
```dart
// NotificationService (신규 생성 권장)
class NotificationService {
  Future<void> sendNotification({
    required String userId,
    required NotificationType type,
    required Map<String, dynamic> data,
  }) async {
    // 1. 사용자 알림 설정 조회
    final settings = await _getNotificationSettings(userId);

    // 2. 해당 알림 타입이 활성화되어 있는지 확인
    if (!settings[type]!) {
      return; // 비활성화된 경우 전송하지 않음
    }

    // 3. FCM 토큰 조회
    final tokens = await _getFcmTokens(userId);

    // 4. Firebase Cloud Messaging 전송
    for (final token in tokens) {
      await _fcmService.send(
        token: token,
        title: _getNotificationTitle(type),
        body: _getNotificationBody(type, data),
        data: data,
      );
    }

    // 5. 알림 히스토리 저장
    await _savePushNotification(
      userId: userId,
      type: type,
      data: data,
    );
  }
}
```

## 5. 구현 우선순위

### Phase 1: 데이터베이스 스키마 변경 (High)
- [ ] 마이그레이션 파일 작성 (컬럼 추가, CHECK 제약 조건 수정)
- [ ] RLS 정책 검토 및 업데이트
- [ ] 기존 데이터 마이그레이션 (shared_ledger_change → 세분화된 설정)

### Phase 2: Flutter 코드 확장 (High)
- [ ] NotificationType enum 확장
- [ ] NotificationSettingsRepository 업데이트
- [ ] NotificationSettingsPage UI 구현

### Phase 3: 알림 전송 로직 구현 (Medium)
- [ ] 거래 생성/수정/삭제 시 알림 트리거 구현 (Database Trigger 또는 Flutter)
- [ ] NotificationService 구현 (알림 분기 로직)
- [ ] FCM 전송 로직 구현

### Phase 4: 자동수집 알림 통합 (Medium)
- [ ] PendingTransactionRepository에 알림 전송 코드 추가
- [ ] AutoSaveService 수정 (suggest/auto 모드별 알림)

### Phase 5: 테스트 및 다국어 지원 (Low)
- [ ] E2E 테스트 작성 (Maestro)
- [ ] 다국어 번역 추가 (app_ko.arb, app_en.arb)
- [ ] 알림 히스토리 UI 개선 (선택 사항)

## 6. 위험 요소 및 대응 방안

### 6.1 기존 사용자 호환성
**위험**: 기존 사용자가 알림을 받지 못하거나 설정이 초기화될 수 있음
**대응**:
- 마이그레이션 시 `shared_ledger_change_enabled` 값을 기반으로 신규 컬럼 초기화
- 신규 컬럼 모두 TRUE로 설정 (기본 활성화)

### 6.2 알림 전송 실패
**위험**: FCM 토큰 만료, 네트워크 오류 등으로 알림이 전송되지 않을 수 있음
**대응**:
- 재시도 로직 구현 (최대 3회)
- 알림 히스토리에 실패 기록 저장
- 에러 로그 모니터링

### 6.3 성능 저하
**위험**: 공유 가계부 멤버가 많을 경우 알림 전송 시 성능 저하
**대응**:
- 배치 처리 구현 (한 번에 여러 FCM 전송)
- Database Trigger 사용 시 비동기 처리 (pg_notify 또는 Queue 사용)

### 6.4 알림 전송 메커니즘 파악 실패
**위험**: 현재 프로젝트에서 알림을 어떻게 전송하는지 명확하지 않음
**대응**:
- Design 단계에서 코드베이스 심층 분석 필요
- Supabase Edge Functions, Database Triggers, Flutter 코드 전체 검토
- 필요 시 새로운 알림 전송 아키텍처 설계

## 7. 성공 지표
- [ ] 사용자가 알림 설정 페이지에서 7가지 알림을 개별 제어 가능
- [ ] 공유 가계부 멤버가 거래 추가/수정/삭제 시 해당 알림이 올바르게 전송됨
- [ ] 자동수집 제안/저장 시 알림이 올바르게 전송됨
- [ ] 기존 사용자의 알림 설정이 마이그레이션 후에도 유지됨
- [ ] 알림 전송 실패율 < 1%

## 8. 다음 단계
1. **Design 문서 작성**: 상세 설계 및 API 명세 정의
2. **알림 전송 메커니즘 분석**: 현재 코드베이스에서 어떻게 알림을 보내는지 파악
3. **마이그레이션 파일 작성**: 044_add_notification_segmentation.sql
4. **Flutter 코드 구현**: NotificationType, UI, Repository 순차 구현
5. **테스트**: Unit Test, E2E Test, 실기기 테스트

---

**작성일**: 2026-02-01
**작성자**: Claude Code
**버전**: 1.0
