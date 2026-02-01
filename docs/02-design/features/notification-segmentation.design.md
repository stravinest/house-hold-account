# Design: 알림 시스템 세분화 및 자동수집 알림 추가

## 1. 시스템 아키텍처

### 1.1 현재 알림 시스템 분석 (완료)

**거래 알림 플로우**:
```
Flutter App                  Supabase                    Edge Function              FCM
───────────                  ────────                    ─────────────              ───
createTransaction()
    ↓
transactions.insert()
    ↓
                          [Trigger]
                          notify_transaction_change()
                              ↓
                          pg_net.http_post()
                              ↓
                                                    send-push-notification
                                                    1. 공유 가계부 확인
                                                    2. 알림 설정 확인
                                                    3. FCM 토큰 조회
                                                    4. 메시지 전송 ───────────> FCM API
                                                    5. 히스토리 저장
```

**핵심 발견**:
- ✅ Database Trigger 기반 알림 전송 (026_add_transaction_webhook_trigger.sql)
- ✅ Supabase Edge Function으로 FCM 전송 (send-push-notification/index.ts)
- ✅ 현재 `shared_ledger_change_enabled` 컬럼으로 알림 필터링 (359-365줄)
- ⚠️ 자동수집 알림은 **현재 구현되지 않음**

### 1.2 신규 알림 시스템 설계

#### 공유 가계부 알림 세분화
```
거래 추가 → transactionAdded
거래 수정 → transactionUpdated
거래 삭제 → transactionDeleted
```

#### 자동수집 알림 추가
```
SMS/Push 수신 → pending_transaction 생성 → autoCollectSuggested (suggest 모드)
pending 확정 → transaction 생성 → autoCollectSaved (auto 모드)
```

## 2. 데이터베이스 설계

### 2.1 마이그레이션: 044_add_notification_segmentation.sql

```sql
-- ============================================
-- 알림 시스템 세분화 마이그레이션
-- ============================================

-- 1. notification_settings 테이블 컬럼 추가
ALTER TABLE house.notification_settings
ADD COLUMN IF NOT EXISTS transaction_added_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS transaction_updated_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS transaction_deleted_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS auto_collect_suggested_enabled BOOLEAN NOT NULL DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS auto_collect_saved_enabled BOOLEAN NOT NULL DEFAULT TRUE;

-- 기존 shared_ledger_change_enabled 값을 기반으로 세분화된 설정 초기화
UPDATE house.notification_settings
SET
  transaction_added_enabled = shared_ledger_change_enabled,
  transaction_updated_enabled = shared_ledger_change_enabled,
  transaction_deleted_enabled = shared_ledger_change_enabled
WHERE transaction_added_enabled IS NULL OR transaction_updated_enabled IS NULL OR transaction_deleted_enabled IS NULL;

COMMENT ON COLUMN house.notification_settings.shared_ledger_change_enabled IS 'DEPRECATED: 하위 호환성을 위해 유지. transaction_*_enabled 사용 권장';
COMMENT ON COLUMN house.notification_settings.transaction_added_enabled IS '다른 멤버 거래 추가 알림 활성화 여부';
COMMENT ON COLUMN house.notification_settings.transaction_updated_enabled IS '다른 멤버 거래 수정 알림 활성화 여부';
COMMENT ON COLUMN house.notification_settings.transaction_deleted_enabled IS '다른 멤버 거래 삭제 알림 활성화 여부';
COMMENT ON COLUMN house.notification_settings.auto_collect_suggested_enabled IS '자동수집 거래 제안 알림 활성화 여부 (suggest 모드)';
COMMENT ON COLUMN house.notification_settings.auto_collect_saved_enabled IS '자동수집 거래 자동저장 알림 활성화 여부 (auto 모드)';

-- 2. push_notifications 테이블 type CHECK 제약 조건 수정
ALTER TABLE house.push_notifications DROP CONSTRAINT IF EXISTS push_notifications_type_check;

ALTER TABLE house.push_notifications
ADD CONSTRAINT push_notifications_type_check
CHECK (type IN (
    'budget_warning',
    'budget_exceeded',
    'shared_ledger_change',           -- deprecated (하위 호환성)
    'transaction_added',              -- 신규
    'transaction_updated',            -- 신규
    'transaction_deleted',            -- 신규
    'auto_collect_suggested',         -- 신규
    'auto_collect_saved',             -- 신규
    'invite_received',
    'invite_accepted'
));

COMMENT ON CONSTRAINT push_notifications_type_check ON house.push_notifications IS '알림 타입 제약 조건 (세분화됨)';

-- 3. 기존 알림 히스토리 마이그레이션 (선택 사항)
-- shared_ledger_change 타입은 유지 (히스토리 보존)
-- 신규 알림부터는 세분화된 타입 사용

-- 4. 신규 사용자 기본 설정 트리거 함수 업데이트
CREATE OR REPLACE FUNCTION house.handle_new_user_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO house.notification_settings (
        user_id,
        budget_warning_enabled,
        budget_exceeded_enabled,
        shared_ledger_change_enabled,
        transaction_added_enabled,
        transaction_updated_enabled,
        transaction_deleted_enabled,
        auto_collect_suggested_enabled,
        auto_collect_saved_enabled,
        invite_received_enabled,
        invite_accepted_enabled
    )
    VALUES (
        NEW.id,
        TRUE,  -- budget_warning_enabled
        TRUE,  -- budget_exceeded_enabled
        TRUE,  -- shared_ledger_change_enabled (deprecated)
        TRUE,  -- transaction_added_enabled
        TRUE,  -- transaction_updated_enabled
        TRUE,  -- transaction_deleted_enabled
        TRUE,  -- auto_collect_suggested_enabled
        TRUE,  -- auto_collect_saved_enabled
        TRUE,  -- invite_received_enabled
        TRUE   -- invite_accepted_enabled
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMENT ON FUNCTION house.handle_new_user_notification_settings() IS '신규 사용자 생성 시 기본 알림 설정 자동 생성 (세분화 반영)';
```

### 2.2 RLS 정책 검토
기존 RLS 정책은 `user_id` 기반이므로 변경 불필요. 신규 컬럼도 동일한 정책 적용됨.

## 3. Flutter 코드 설계

### 3.1 NotificationType enum 확장

**파일**: `lib/features/notification/domain/entities/notification_type.dart`

```dart
enum NotificationType {
  // 기존 (하위 호환성)
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
```

### 3.2 NotificationSettingsRepository 수정

**파일**: `lib/features/notification/data/repositories/notification_settings_repository.dart`

현재 구조는 **컬럼 기반**이므로 다음과 같이 수정 필요:

```dart
class NotificationSettingsRepository {
  final _client = SupabaseConfig.client;

  /// 사용자 알림 설정 조회 (Map<NotificationType, bool> 반환)
  Future<Map<NotificationType, bool>> getNotificationSettings(String userId) async {
    final response = await _client
        .from('notification_settings')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) {
      // 기본 설정 생성 후 다시 조회
      await _createDefaultSettings(userId);
      return getNotificationSettings(userId);
    }

    // 컬럼 기반 데이터를 Map으로 변환
    return {
      NotificationType.transactionAdded: response['transaction_added_enabled'] ?? true,
      NotificationType.transactionUpdated: response['transaction_updated_enabled'] ?? true,
      NotificationType.transactionDeleted: response['transaction_deleted_enabled'] ?? true,
      NotificationType.autoCollectSuggested: response['auto_collect_suggested_enabled'] ?? true,
      NotificationType.autoCollectSaved: response['auto_collect_saved_enabled'] ?? true,
      NotificationType.inviteReceived: response['invite_received_enabled'] ?? true,
      NotificationType.inviteAccepted: response['invite_accepted_enabled'] ?? true,
      // deprecated는 UI에 노출하지 않음
    };
  }

  /// 알림 설정 업데이트
  Future<void> updateNotificationSetting(
    String userId,
    NotificationType type,
    bool enabled,
  ) async {
    final columnName = _getColumnName(type);

    await _client
        .from('notification_settings')
        .update({columnName: enabled})
        .eq('user_id', userId);
  }

  /// NotificationType을 컬럼명으로 변환
  String _getColumnName(NotificationType type) {
    switch (type) {
      case NotificationType.transactionAdded:
        return 'transaction_added_enabled';
      case NotificationType.transactionUpdated:
        return 'transaction_updated_enabled';
      case NotificationType.transactionDeleted:
        return 'transaction_deleted_enabled';
      case NotificationType.autoCollectSuggested:
        return 'auto_collect_suggested_enabled';
      case NotificationType.autoCollectSaved:
        return 'auto_collect_saved_enabled';
      case NotificationType.inviteReceived:
        return 'invite_received_enabled';
      case NotificationType.inviteAccepted:
        return 'invite_accepted_enabled';
      case NotificationType.sharedLedgerChange:
        return 'shared_ledger_change_enabled';
    }
  }

  Future<void> _createDefaultSettings(String userId) async {
    await _client.from('notification_settings').insert({
      'user_id': userId,
      'transaction_added_enabled': true,
      'transaction_updated_enabled': true,
      'transaction_deleted_enabled': true,
      'auto_collect_suggested_enabled': true,
      'auto_collect_saved_enabled': true,
      'invite_received_enabled': true,
      'invite_accepted_enabled': true,
    });
  }
}
```

### 3.3 NotificationSettingsPage UI 확장

**파일**: `lib/features/notification/presentation/pages/notification_settings_page.dart`

```dart
Widget _buildSettingsList(
  BuildContext context,
  WidgetRef ref,
  Map<NotificationType, bool> settings,
  AppLocalizations l10n,
) {
  return ListView(
    children: [
      // 설명
      Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Text(
          l10n.notificationSettingsDescription,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),

      // 1. 공유 가계부 알림
      SectionHeader(title: l10n.notificationSectionSharedLedger),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.transactionAdded,
        title: l10n.notificationTransactionAdded,
        subtitle: l10n.notificationTransactionAddedDesc,
        icon: Icons.add_circle_outline,
        enabled: settings[NotificationType.transactionAdded] ?? true,
      ),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.transactionUpdated,
        title: l10n.notificationTransactionUpdated,
        subtitle: l10n.notificationTransactionUpdatedDesc,
        icon: Icons.edit_outlined,
        enabled: settings[NotificationType.transactionUpdated] ?? true,
      ),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.transactionDeleted,
        title: l10n.notificationTransactionDeleted,
        subtitle: l10n.notificationTransactionDeletedDesc,
        icon: Icons.delete_outline,
        enabled: settings[NotificationType.transactionDeleted] ?? true,
      ),

      const Divider(),

      // 2. 자동수집 알림
      SectionHeader(title: l10n.notificationSectionAutoCollect),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.autoCollectSuggested,
        title: l10n.notificationAutoCollectSuggested,
        subtitle: l10n.notificationAutoCollectSuggestedDesc,
        icon: Icons.notifications_outlined,
        enabled: settings[NotificationType.autoCollectSuggested] ?? true,
      ),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.autoCollectSaved,
        title: l10n.notificationAutoCollectSaved,
        subtitle: l10n.notificationAutoCollectSavedDesc,
        icon: Icons.save_outlined,
        enabled: settings[NotificationType.autoCollectSaved] ?? true,
      ),

      const Divider(),

      // 3. 초대 알림
      SectionHeader(title: l10n.notificationSectionInvite),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.inviteReceived,
        title: l10n.notificationInviteReceived,
        subtitle: l10n.notificationInviteReceivedDesc,
        icon: Icons.mail_outline,
        enabled: settings[NotificationType.inviteReceived] ?? true,
      ),
      _buildNotificationToggle(
        context,
        ref,
        type: NotificationType.inviteAccepted,
        title: l10n.notificationInviteAccepted,
        subtitle: l10n.notificationInviteAcceptedDesc,
        icon: Icons.check_circle_outline,
        enabled: settings[NotificationType.inviteAccepted] ?? true,
      ),

      const SizedBox(height: 32),
    ],
  );
}
```

## 4. 알림 전송 로직 설계

### 4.1 거래 알림 Edge Function 수정

**파일**: `supabase/functions/send-push-notification/index.ts`

**수정 사항**:
1. Webhook payload에서 `type` (INSERT/UPDATE/DELETE) 확인
2. 해당 타입에 맞는 알림 설정 컬럼 조회 (`transaction_added_enabled` 등)
3. 알림 메시지 및 타입 변경

```typescript
// 4. 알림 설정 확인 (타입별 세분화)
let notificationTypeColumn: string;
let notificationType: string;

switch (payload.type) {
  case 'INSERT':
    notificationTypeColumn = 'transaction_added_enabled';
    notificationType = 'transaction_added';
    break;
  case 'UPDATE':
    notificationTypeColumn = 'transaction_updated_enabled';
    notificationType = 'transaction_updated';
    break;
  case 'DELETE':
    notificationTypeColumn = 'transaction_deleted_enabled';
    notificationType = 'transaction_deleted';
    break;
  default:
    throw new Error(`Unknown operation type: ${payload.type}`);
}

// 해당 알림 타입이 활성화된 사용자만 조회
const { data: settings, error: settingsError } = await supabase
  .schema('house')
  .from('notification_settings')
  .select('user_id')
  .in('user_id', targetUserIds)
  .eq(notificationTypeColumn, true);

// ... (나머지 로직 동일)

// FCM 전송 시 data에 세분화된 타입 포함
const result = await sendFcmMessage(
  accessToken,
  firebaseServiceAccount.project_id,
  tokenData.token,
  title,
  body,
  {
    type: notificationType,  // transaction_added/updated/deleted
    ledger_id: record.ledger_id,
    transaction_id: record.id,
    creator_user_id: record.user_id,
  }
);

// 알림 히스토리 저장 (세분화된 타입 사용)
const { error: insertError } = await supabase.schema('house').from('push_notifications').insert({
  user_id: userId,
  type: notificationType,  // 세분화된 타입
  title: title,
  body: body,
  data: { /* ... */ },
});
```

### 4.2 자동수집 알림 전송 구현

**신규 파일**: `lib/features/notification/data/services/notification_service.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../domain/entities/notification_type.dart';
import '../repositories/fcm_token_repository.dart';
import '../repositories/notification_settings_repository.dart';
import '../../services/firebase_messaging_service.dart';

/// 알림 전송 서비스
/// 알림 설정 확인 후 FCM 전송 및 히스토리 저장
class NotificationService {
  final _client = SupabaseConfig.client;
  final _settingsRepository = NotificationSettingsRepository();
  final _fcmRepository = FcmTokenRepository();

  /// 알림 전송 (자동수집 전용)
  ///
  /// [userId] 알림 받을 사용자 ID
  /// [type] 알림 타입 (autoCollectSuggested 또는 autoCollectSaved)
  /// [title] 알림 제목
  /// [body] 알림 내용
  /// [data] 추가 데이터 (pendingId, transactionId 등)
  Future<void> sendAutoCollectNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      // 1. 사용자 알림 설정 조회
      final settings = await _settingsRepository.getNotificationSettings(userId);

      // 2. 해당 알림 타입이 활성화되어 있는지 확인
      final isEnabled = settings[type] ?? false;
      if (!isEnabled) {
        if (kDebugMode) {
          debugPrint('[NotificationService] $type 알림이 비활성화되어 있습니다.');
        }
        return;
      }

      // 3. FCM 토큰 조회
      final tokens = await _fcmRepository.getFcmTokensByUserId(userId);
      if (tokens.isEmpty) {
        if (kDebugMode) {
          debugPrint('[NotificationService] FCM 토큰이 없습니다. (userId: $userId)');
        }
        return;
      }

      // 4. 로컬 알림 표시 (포그라운드인 경우)
      // LocalNotificationService를 사용하여 즉시 표시
      // (FCM은 백그라운드에서만 자동 표시됨)

      // 5. 알림 히스토리 저장 (선택 사항)
      await _savePushNotification(
        userId: userId,
        type: type,
        title: title,
        body: body,
        data: data,
      );

      if (kDebugMode) {
        debugPrint('[NotificationService] $type 알림 전송 완료 (userId: $userId)');
      }
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[NotificationService] 알림 전송 실패: $e');
        debugPrint(st.toString());
      }
      // 알림 전송 실패는 치명적 에러가 아니므로 rethrow 하지 않음
    }
  }

  /// 알림 히스토리 저장
  Future<void> _savePushNotification({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    await _client.from('push_notifications').insert({
      'user_id': userId,
      'type': type.value,
      'title': title,
      'body': body,
      'data': data,
    });
  }
}
```

**파일 수정**: `lib/features/payment_method/data/repositories/pending_transaction_repository.dart`

```dart
import '../../../notification/data/services/notification_service.dart';
import '../../../notification/domain/entities/notification_type.dart';

class PendingTransactionRepository {
  final _client = SupabaseConfig.client;
  final _notificationService = NotificationService();

  /// Pending 거래 생성 (SMS/Push 자동수집)
  Future<PendingTransactionModel> createPendingTransaction({
    // ... 기존 파라미터
    AutoSaveMode? autoSaveMode,  // 신규 파라미터 추가
  }) async {
    // ... 기존 생성 로직

    final pendingTransaction = PendingTransactionModel.fromJson(response.first);

    // suggest 모드인 경우 알림 전송
    if (autoSaveMode == AutoSaveMode.suggest && parsedAmount != null) {
      final l10n = AppLocalizations.of(context);  // context 전달 필요
      await _notificationService.sendAutoCollectNotification(
        userId: userId,
        type: NotificationType.autoCollectSuggested,
        title: l10n.notificationAutoCollectSuggestedTitle,
        body: l10n.notificationAutoCollectSuggestedBody(
          parsedMerchant ?? l10n.commonUnknown,
          parsedAmount,
        ),
        data: {
          'pendingId': pendingTransaction.id,
          'amount': parsedAmount,
          'merchant': parsedMerchant,
        },
      );
    }

    return pendingTransaction;
  }

  /// Pending 거래 확정 → 실제 거래 생성
  Future<void> confirmPendingTransaction({
    required String pendingId,
    AutoSaveMode? autoSaveMode,  // 신규 파라미터 추가
  }) async {
    // ... 기존 확정 로직

    // auto 모드인 경우 알림 전송
    if (autoSaveMode == AutoSaveMode.auto) {
      final l10n = AppLocalizations.of(context);
      await _notificationService.sendAutoCollectNotification(
        userId: userId,
        type: NotificationType.autoCollectSaved,
        title: l10n.notificationAutoCollectSavedTitle,
        body: l10n.notificationAutoCollectSavedBody(
          transactionTitle,
          amount,
        ),
        data: {
          'transactionId': transactionId,
          'amount': amount,
        },
      );
    }
  }
}
```

## 5. 다국어 지원 (i18n)

**파일**: `lib/l10n/app_ko.arb` (추가 필요한 키)

```json
{
  "notificationSectionSharedLedger": "공유 가계부 알림",
  "notificationSectionAutoCollect": "자동수집 알림",

  "notificationTransactionAdded": "다른 멤버 거래 추가",
  "notificationTransactionAddedDesc": "다른 멤버가 거래를 추가했을 때 알림을 받습니다.",

  "notificationTransactionUpdated": "다른 멤버 거래 수정",
  "notificationTransactionUpdatedDesc": "다른 멤버가 거래를 수정했을 때 알림을 받습니다.",

  "notificationTransactionDeleted": "다른 멤버 거래 삭제",
  "notificationTransactionDeletedDesc": "다른 멤버가 거래를 삭제했을 때 알림을 받습니다.",

  "notificationAutoCollectSuggested": "거래 제안",
  "notificationAutoCollectSuggestedDesc": "SMS/알림으로 거래가 자동수집되어 제안되었을 때 알림을 받습니다.",

  "notificationAutoCollectSaved": "거래 자동저장",
  "notificationAutoCollectSavedDesc": "거래가 자동으로 저장되었을 때 알림을 받습니다.",

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
}
```

## 6. 구현 순서

### Phase 1: 데이터베이스 스키마 변경 (1일)
- [ ] `044_add_notification_segmentation.sql` 작성
- [ ] 로컬 Supabase에서 마이그레이션 테스트
- [ ] 프로덕션 마이그레이션 실행

### Phase 2: Flutter 코드 확장 (2일)
- [ ] `NotificationType` enum 확장
- [ ] `NotificationSettingsRepository` 수정 (컬럼 매핑)
- [ ] `NotificationSettingsPage` UI 구현
- [ ] 다국어 번역 추가 (app_ko.arb, app_en.arb)

### Phase 3: 거래 알림 Edge Function 수정 (1일)
- [ ] `send-push-notification/index.ts` 수정
  - 타입별 알림 설정 조회 로직
  - 세분화된 알림 타입 사용
- [ ] Edge Function 배포 및 테스트

### Phase 4: 자동수집 알림 구현 (2일)
- [ ] `NotificationService` 신규 생성
- [ ] `PendingTransactionRepository` 수정
  - `createPendingTransaction`에 알림 전송 추가
  - `confirmPendingTransaction`에 알림 전송 추가
- [ ] `AutoSaveMode` 파라미터 전달 체계 정비

### Phase 5: 테스트 및 검증 (1일)
- [ ] Unit Test 작성 (NotificationService)
- [ ] Widget Test (NotificationSettingsPage)
- [ ] E2E 테스트 (Maestro - 알림 설정 변경 시나리오)
- [ ] 실기기 테스트 (FCM 전송 확인)

**총 예상 기간**: 7일

## 7. 테스트 전략

### 7.1 단위 테스트
```dart
// test/features/notification/data/services/notification_service_test.dart
void main() {
  group('NotificationService', () {
    test('알림 비활성화 시 전송하지 않음', () async {
      // Given: autoCollectSuggested 알림이 비활성화된 상태

      // When: sendAutoCollectNotification 호출

      // Then: FCM 전송 안 됨, 히스토리 저장 안 됨
    });

    test('알림 활성화 시 정상 전송', () async {
      // Given: autoCollectSuggested 알림이 활성화된 상태

      // When: sendAutoCollectNotification 호출

      // Then: 히스토리 저장됨
    });
  });
}
```

### 7.2 E2E 테스트 (Maestro)
```yaml
# maestro-tests/notification_settings_test.yaml
appId: com.yourapp.household
---
- launchApp
- tapOn: '설정'
- tapOn: '알림설정'

# 공유 가계부 알림 비활성화
- tapOn: '다른 멤버 거래 추가'
- assertVisible: '비활성화됨'

# 자동수집 알림 활성화 확인
- assertVisible: '거래 제안'
- assertVisible: '거래 자동저장'
```

### 7.3 실기기 테스트 체크리스트
- [ ] 공유 가계부에서 거래 추가 시 알림 수신 (transactionAdded)
- [ ] 공유 가계부에서 거래 수정 시 알림 수신 (transactionUpdated)
- [ ] 공유 가계부에서 거래 삭제 시 알림 수신 (transactionDeleted)
- [ ] SMS 자동수집 시 알림 수신 (autoCollectSuggested, suggest 모드)
- [ ] 자동저장 시 알림 수신 (autoCollectSaved, auto 모드)
- [ ] 알림 설정 비활성화 시 알림 안 옴
- [ ] 기존 사용자 마이그레이션 후 모든 알림 활성화 상태 확인

## 8. 위험 요소 및 대응 방안

### 8.1 Edge Function 배포 실패
**위험**: 수정된 Edge Function 배포 중 에러 발생
**대응**:
- 로컬 Supabase CLI로 사전 테스트
- Blue-Green 배포 전략 (신규 버전 배포 후 기존 버전 유지)
- 롤백 계획 수립

### 8.2 알림 폭탄 (Notification Spam)
**위험**: 자동수집 알림이 과도하게 발생하여 사용자 피로도 증가
**대응**:
- 배치 처리 고려 (N분 내 여러 pending 거래는 하나의 알림으로 묶기)
- 알림 빈도 제한 (동일 타입 알림은 최소 1분 간격)
- 사용자 피드백 수집 후 조정

### 8.3 성능 저하
**위험**: 알림 설정 조회 쿼리 증가로 성능 저하
**대응**:
- 알림 설정을 Flutter에서 캐싱 (Riverpod Provider)
- Edge Function에서 배치 쿼리 사용 (IN 절)

### 8.4 다국어 번역 누락
**위험**: 영어 번역이 누락되어 영어 사용자에게 한국어 표시
**대응**:
- CI/CD에서 번역 키 누락 자동 체크
- app_en.arb에도 모든 키 추가

## 9. 성공 지표
- [ ] 사용자가 알림 설정 페이지에서 7가지 알림을 개별 제어 가능
- [ ] 공유 가계부 멤버가 거래 추가/수정/삭제 시 해당 알림이 올바르게 전송됨
- [ ] 자동수집 제안/저장 시 알림이 올바르게 전송됨
- [ ] 기존 사용자의 알림 설정이 마이그레이션 후에도 유지됨 (모두 활성화)
- [ ] 알림 전송 실패율 < 1%
- [ ] E2E 테스트 통과율 100%

## 10. 다음 단계
다음 명령어로 구현을 시작하세요:
```bash
/pdca do notification-segmentation
```

---

**작성일**: 2026-02-01
**작성자**: Claude Code
**버전**: 1.0
**Plan 문서 참조**: docs/01-plan/features/notification-segmentation.plan.md
