# SMS vs Push 알림 아키텍처 가이드

**업데이트**: 2026-01-22
**상태**: 진행 중

---

## 📊 데이터 흐름 비교

### 1️⃣ SMS 기반 자동 인식 (저장함)

```
기기 SMS 수신
├─ SmsListenerService (기기 로컬)
│  └─ 최근 30일 SMS만 스캔
│
├─ SmsParsingService (메모리)
│  ├─ 발신자: KB국민카드 등 매칭
│  ├─ 금액: 정규식 추출 (콤마 처리)
│  └─ 키워드: 출금/입금/승인/결제 검증
│
└─ LearnedSmsFormat (DB 저장 - 학습용)
   ├─ senderKeywords: ['KB국민', 'KB국민카드']
   ├─ amountPattern: r'([0-9,]+)\s*원'
   └─ 목적: 향후 자동 인식 개선
```

**저장 위치**: `learned_sms_formats` 테이블
**저장 빈도**: SMS 파싱 시 1회 (새로운 패턴 감지)
**보관 기간**: 무제한
**데이터량**: 결제수단당 1~2행 (매우 적음)

---

### 2️⃣ Push 알림 (저장 안 함)

```
공유 가계부 거래 변경
├─ DB 트리거 (transaction 테이블)
│  └─ INSERT/UPDATE/DELETE 감지
│
├─ Edge Function: send-push-notification 실행
│  ├─ 공유 멤버의 FCM 토큰 조회 (fcm_tokens)
│  ├─ 알림 설정 확인 (notification_settings)
│  └─ FCM으로 실시간 발송
│
└─ 사용자 기기 수신 (저장 안 함)
   ├─ 네이티브 알림 표시
   ├─ 알림 센터 저장 (기기)
   └─ DB에는 기록 없음 ← 의도적 설계
```

**저장 위치**: 없음 (의도적)
**발송 빈도**: 거래 변경 시마다
**기기 보관**: 알림 센터 (자동 삭제)
**DB 영향**: 0 (성능 최적)

---

## 🎯 "저장 안 함" 설계의 이유

### 문제점: 만약 저장했다면?

```
월 데이터:
├─ 거래: ~300건 (저장함)
└─ 푸시 알림: ~300건 (저장하면 2배 증가)

연간 데이터:
├─ 거래: 3,600건 (OK)
└─ 푸시 알림: 3,600건 (DB 무거워짐) ⚠️

3년 운영 시:
├─ 거래: 10,800건
└─ 푸시 알림: 10,800건 ← 불필요한 데이터

📈 문제:
1. 조회 쿼리 느려짐 (LIKE, WHERE로 필터링)
2. 인덱싱 복잡 (생성_일시, 사용자, 상태)
3. 백업 용량 증가
4. 거래 + 알림 중복 저장
```

### 솔루션: 저장하지 않기

```
설계:
1. Push 알림 = 실시간 알림 용도
2. 거래 확인 = transactions 테이블에서
3. 대기 처리 = pending_transactions에서

장점:
✅ DB 스토리지 증가 0
✅ 쿼리 성능 향상
✅ 구조 단순화
✅ 백업 용량 절약

단점:
❌ 과거 알림 조회 불가 (거의 필요 없음)
   → 대신 거래 이력에서 확인 가능

트레이드오프:
"알림 히스토리"가 정말 필요한가?
→ 대부분 불필요
→ 필요하면 거래 상세 페이지에서 확인
```

---

## 🔄 사용자 확인 흐름

### SMS 기반 자동 인식

```
[SMS 수신]
  ↓
[SmsListenerService 감지]
  ↓
[SmsParsingService 파싱]
  ↓
[LearnedSmsFormat 저장] ← 학습용 저장
  ↓
[pending_transactions 생성] ← DB 저장 (임시)
  ↓
[PaymentMethodManagementPage 탭 2 표시]
  ├─ "대기 중인 거래" 목록
  └─ 사용자가 수정/삭제/확인 가능
  ↓
[거래 확정 시 transactions 이동] ← 최종 저장
```

**DB 저장 항목**:
- ✓ LearnedSmsFormat (1회, 학습용)
- ✓ pending_transactions (임시, 처리 시 삭제)
- ✓ transactions (최종, 영구)
- ✗ 알림 히스토리 (저장 안 함)

---

### Push 기반 멤버 알림

```
[거래 INSERT/UPDATE/DELETE]
  ↓
[DB 트리거 실행]
  ↓
[Edge Function: send-push-notification]
  ├─ 공유 멤버 조회
  ├─ FCM 토큰 조회 ← DB 읽음만 함
  ├─ 알림 설정 확인 ← DB 읽음만 함
  └─ FCM 발송
     ↓ (여기서 종료)
     ↓ (저장 안 함)
  
[사용자 기기에서 받음]
  ├─ 알림 센터에 표시
  └─ 자동 정리 (기기)
  
[사용자 확인]
  ├─ 알림 클릭 → 거래 상세 페이지
  └─ 또는 탭 2의 "거래 내역"에서 확인
```

**DB 변경 사항**:
- ✗ 저장하지 않음 (의도적)
- ✓ transactions는 여전히 저장됨 (발송과 무관)

---

## 📱 UI에서의 표현

### PaymentMethodManagementPage (탭 방식)

```
┌──────────────────────────────────────┐
│  결제수단 관리                         │
│  [결제수단(SMS)] [거래 내역]          │
├──────────────────────────────────────┤

탭 1: 결제수단 (SMS)
├─ payment_methods 테이블 출처
├─ SMS 파싱 기반 자동 학습
├─ 사용자가 수정/추가 가능
└─ 영구 저장

탭 2: 거래 내역
├─ pending_transactions 테이블 출처
├─ SMS/자동 인식 기반 대기
├─ 사용자 확인 후 처리
└─ 임시 저장 (처리 후 삭제)
```

**Push 알림 표시 위치**:
- 네이티브 알림 센터 (기기)
- 탭 2의 "거래 내역"에서 최근 거래 확인
- 히스토리 미제공 (DB에 저장 안 했으므로)

---

## ✅ 구현 체크리스트

### SMS 관련 (변경 없음)

- [x] SmsListenerService (기기 로컬)
- [x] SmsParsingService (파싱 로직)
- [x] LearnedSmsFormat (DB 저장 - 학습용)
- [x] payment_method_wizard_page (감지 키워드 편집)
- [x] pending_transactions (임시 저장)

### Push 알림 관련 (저장 제거)

- [x] Edge Function 주석 추가 (저장 안 함 이유)
- [x] push_notifications 테이블 (미사용 표시)
- [x] 설계 문서 작성
- [ ] 팀 공유 및 합의

### UI 관련 (탭 방식)

- [x] TabController 추가
- [x] TabBar (SMS / 거래 내역)
- [x] 탭 1: payment_methods 목록
- [x] 탭 2: pending_transactions 목록
- [ ] 테스트 및 검증

---

## 🔐 보안 & RLS 정책

**현재 상태**: 변경 없음

```sql
-- 거래 변경 시 공유 멤버에게만 알림
-- (RLS로 접근 제어)

-- 사용자가 자신의 pending_transactions만 조회
SELECT * FROM pending_transactions
WHERE user_id = auth.uid()
   OR ledger_id IN (
     SELECT ledger_id FROM ledger_members
     WHERE user_id = auth.uid()
   );

-- Push 알림 발송 (Edge Function)
-- FCM 토큰은 사용자별 저장
SELECT token FROM fcm_tokens
WHERE user_id = $1; -- 특정 사용자

-- 알림 설정 존중
SELECT shared_ledger_change_enabled 
FROM notification_settings
WHERE user_id = $1;
```

---

## 📈 향후 개선 시나리오

### 만약 알림 히스토리가 정말 필요하다면?

**Phase 2: 선택적 저장**

```dart
// 사용자 설정
class NotificationSetting {
  bool keepNotificationHistory = false; // 기본값: 미저장
}

// 저장 조건
if (userSettings.keepNotificationHistory) {
  // 푸시 알림 저장
  await savePushNotification(...);
  // 자동 정리: 90일 후 삭제
}
```

**마이그레이션**:
```sql
-- 옵션: 저장하려면 이 트리거 활성화
CREATE TRIGGER save_push_notifications
AFTER <FCM 발송 이벤트>
BEGIN
  INSERT INTO push_notifications (...)
  VALUES (...);
END;
```

**지금은 불필요**: 대부분의 사용자에게 필요 없는 기능

---

## 참고문서

| 문서 | 위치 | 내용 |
|------|------|------|
| 설계 제안 | `.codebase/payment_method_design_proposals.md` | 5가지 UI 옵션 |
| 상세 가이드 | `.codebase/payment_method_design_detailed.md` | 화면별 상세 |
| 탭 방식 | `.codebase/payment_method_tab_design.md` | 현재 구현 |
| Edge Function | `supabase/functions/send-push-notification/` | 발송 로직 |

---

**결론**: Push 알림은 실시간 용도이므로 저장하지 않는 것이 최적. 필요하면 거래 이력에서 확인 가능. 💡
