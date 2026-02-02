# Gap Analysis: 자동수집 푸시알림 미발송 버그 수정

**Feature ID**: `auto-collect-notification-fix`
**분석일**: 2026-02-02
**PDCA Phase**: Check (Gap Analysis)

---

## 1. 분석 개요

| 항목 | 내용 |
|------|------|
| **Design 문서** | `docs/02-design/features/auto-collect-notification-fix.design.md` |
| **구현 파일** | `SupabaseHelper.kt`, `FinancialNotificationListener.kt` |
| **분석 방법** | Design 문서 vs 실제 코드 항목별 비교 |

---

## 2. Overall Scores

| 카테고리 | 점수 | 상태 |
|----------|:-----:|:------:|
| Design Match | **100%** | ✅ |
| Architecture Compliance | **100%** | ✅ |
| Convention Compliance | **100%** | ✅ |
| **Overall** | **100%** | ✅ |

---

## 3. SupabaseHelper.kt 분석

### 3.1 getAutoCollectNotificationSetting() 함수

| 항목 | Design | Implementation | 상태 |
|------|--------|----------------|:----:|
| 함수 시그니처 | `suspend fun getAutoCollectNotificationSetting(userId, isAutoMode): Boolean` | ✅ 동일 | ✅ |
| API URL | `notification_settings?select=$column&user_id=eq.$userId` | ✅ 동일 | ✅ |
| Headers | Authorization, apikey, Accept-Profile | ✅ 동일 | ✅ |
| isAutoMode=true 컬럼 | `auto_collect_saved_enabled` | ✅ 동일 | ✅ |
| isAutoMode=false 컬럼 | `auto_collect_suggested_enabled` | ✅ 동일 | ✅ |
| 기본값 | `true` | ✅ 동일 | ✅ |

**소계**: 6/6 (100%)

### 3.2 savePushNotificationHistory() 함수

| 항목 | Design | Implementation | 상태 |
|------|--------|----------------|:----:|
| 함수 시그니처 | `suspend fun savePushNotificationHistory(...): Boolean` | ✅ 동일 | ✅ |
| HTTP Method | POST `/push_notifications` | ✅ 동일 | ✅ |
| Headers | Authorization, apikey, Content-Type, Content-Profile, Prefer | ✅ 동일 | ✅ |
| Body fields | user_id, type, title, body, data, is_read | ✅ 동일 | ✅ |

**소계**: 4/4 (100%)

---

## 4. FinancialNotificationListener.kt 분석

### 4.1 Import 추가

| Import | 상태 |
|--------|:----:|
| `android.app.NotificationChannel` | ✅ |
| `android.app.NotificationManager` | ✅ |
| `android.app.PendingIntent` | ✅ |
| `android.content.Context` | ✅ |
| `android.os.Build` | ✅ |
| `androidx.core.app.NotificationCompat` | ✅ |

**소계**: 6/6 (100%)

### 4.2 showAutoCollectNotification() 함수

| 항목 | Design | Implementation | 상태 |
|------|--------|----------------|:----:|
| Channel ID | `household_account_channel` | ✅ 동일 | ✅ |
| Channel Name | `공유 가계부 알림` | ✅ 동일 | ✅ |
| Channel Importance | `IMPORTANCE_DEFAULT` | ✅ 동일 | ✅ |
| 채널 중복 생성 방지 | `getNotificationChannel()` 체크 | ✅ 동일 | ✅ |
| Title (suggest) | `자동수집 거래 확인` | ✅ 동일 | ✅ |
| Title (auto) | `자동수집 거래 저장` | ✅ 동일 | ✅ |
| Intent flags | `FLAG_ACTIVITY_NEW_TASK or FLAG_ACTIVITY_CLEAR_TOP` | ✅ 동일 | ✅ |
| Intent - targetTab | `confirmed` / `pending` | ✅ 동일 | ✅ |
| Intent - route | `/payment-method-management` | ✅ 동일 | ✅ |
| PendingIntent flags | `FLAG_UPDATE_CURRENT or FLAG_IMMUTABLE` | ✅ 동일 | ✅ |
| SmallIcon | `R.mipmap.ic_launcher` | ✅ 동일 | ✅ |
| AutoCancel | `true` | ✅ 동일 | ✅ |

**소계**: 12/12 (100%)

### 4.3 buildNotificationBody() 헬퍼 함수

| 항목 | Design | Implementation | 상태 |
|------|--------|----------------|:----:|
| 금액 포맷 | `%,d원` | ✅ 동일 | ✅ |
| 상호 추가 | 공백 + merchant | ✅ 동일 | ✅ |
| 결제수단 추가 | ` - ` + paymentMethodName | ✅ 동일 | ✅ |
| 기본 메시지 | `새로운 거래가 수집되었습니다.` | ✅ 동일 | ✅ |

**소계**: 4/4 (100%)

### 4.4 processNotification() 수정

| 항목 | Design | Implementation | 상태 |
|------|--------|----------------|:----:|
| 수정 위치 | Supabase 저장 성공 후 | ✅ 동일 | ✅ |
| 알림 설정 조회 | `getAutoCollectNotificationSetting()` 호출 | ✅ 동일 | ✅ |
| 조건부 알림 표시 | `if (shouldShowNotification)` | ✅ 동일 | ✅ |
| showAutoCollectNotification 호출 | 4개 파라미터 | ✅ 동일 | ✅ |
| notificationType | `auto_collect_saved` / `auto_collect_suggested` | ✅ 동일 | ✅ |
| savePushNotificationHistory 호출 | 5개 파라미터 + data map | ✅ 동일 | ✅ |
| 비활성화 로그 | `Notification disabled by user setting` | ✅ 동일 | ✅ |

**소계**: 7/7 (100%)

---

## 5. 추가 개선 사항

Design에 명시되지 않았으나 구현에서 추가된 개선점:

| 항목 | 설명 |
|------|------|
| KDoc 문서화 | `getAutoCollectNotificationSetting`, `savePushNotificationHistory` 함수에 상세 KDoc 추가 |
| 함수 분리 | `buildNotificationBody`를 별도 private 함수로 추출하여 재사용성 향상 |
| 로그 추가 | 알림 설정 조회 결과, 알림 표시 여부 등 디버그 로그 추가 |

---

## 6. Match Rate Summary

```
┌─────────────────────────────────────────────┐
│  Overall Match Rate: 100%                   │
├─────────────────────────────────────────────┤
│  SupabaseHelper.kt                          │
│    - getAutoCollectNotificationSetting: 6/6 │
│    - savePushNotificationHistory: 4/4       │
├─────────────────────────────────────────────┤
│  FinancialNotificationListener.kt           │
│    - Import 추가: 6/6                       │
│    - showAutoCollectNotification: 12/12     │
│    - buildNotificationBody: 4/4             │
│    - processNotification 수정: 7/7          │
├─────────────────────────────────────────────┤
│  Total: 39/39 항목 일치                     │
│  추가 개선: +3 (KDoc, 함수 분리, 로그)      │
└─────────────────────────────────────────────┘
```

---

## 7. 결론

### 7.1 분석 결과

Design 문서와 Implementation이 **100% 일치**합니다.

- 모든 함수 시그니처 일치
- 모든 API 요청 형식 일치
- 모든 알림 설정 (채널, Intent, 딥링크) 일치
- 추가로 코드 품질 개선 (KDoc, 함수 분리)

### 7.2 다음 단계

Match Rate **100%** 달성으로 Report 생성 가능:

```bash
/pdca report auto-collect-notification-fix
```

### 7.3 테스트 권장 사항

실기기에서 다음 시나리오 테스트 권장:

| ID | 시나리오 | 예상 결과 |
|----|----------|----------|
| T-1 | 앱 종료 상태에서 결제 | 상단바에 알림 표시 |
| T-2 | `auto_collect_suggested_enabled = false` 설정 | 알림 표시 안 됨 |
| T-3 | 알림 탭 | 앱 → 결제수단 관리 → 대기중 탭 |

---

**Gap Analysis 완료**
분석일: 2026-02-02
Match Rate: 100%
