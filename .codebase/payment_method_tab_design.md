# 탭 방식 결제수단 관리 구현 (Tab-based Payment Method Management)

**구현일**: 2026-01-22
**상태**: 진행 중
**저자**: AI Agent

---

## 1️⃣ 아키텍처 결정

### 설계 선택: SMS/Push 알림 저장하지 않기

```
기존 구조 (저장함):
SMS 메시지 → 파싱 → DB 저장 → 대기 중인 거래 → 사용자 확인
                      ↓ 누적 증가 ⚠️

선택한 구조 (저장 안 함):
SMS 메시지 → 파싱 → 실시간 처리 → 대기 중인 거래 → 사용자 확인
(기기 로컬)        (메모리)     (DB 저장)      (무한 보관)
↓ 데이터 증가 없음 ✓
```

### 데이터 증가량 비교

| 항목 | 저장함 | 저장 안 함 | 선택 이유 |
|------|------|----------|---------|
| Push 알림 (월) | ~300건 | 0 | 실시간 발송만 필요 |
| 1년 누적 | 3,600건 | 0 | 스토리지 절약 |
| DB 쿼리 | 복잡 | 간단 | 성능 향상 |
| 사용자 UX | 히스토리 조회 가능 | 최근 상태만 | 대부분 불필요 |

---

## 2️⃣ UI 설계: 탭 방식

### 화면 구성

```
┌─────────────────────────────────────┐
│     결제수단 관리                      │
│  [결제수단(SMS)] [거래 내역]         │ ← TabBar
├─────────────────────────────────────┤
│                                       │
│  탭 1: 결제수단 (SMS)                 │
│  ├─ 기존 결제수단 목록 (ListView)     │
│  ├─ SMS 자동 인식 기반               │
│  └─ 정기예금/자산은 제외             │
│                                       │
│  탭 2: 거래 내역                      │
│  ├─ 대기 중인 거래 (pending)         │
│  ├─ SMS/푸시에서 감지된 것           │
│  └─ 클릭 시 상세 페이지로 이동       │
│                                       │
│                           [+] FAB    │
└─────────────────────────────────────┘
```

### 상태별 화면

**탭 1: 결제수단 (SMS)**
```
🔄 로딩:  CircularProgressIndicator

✅ 데이터:
  ┌─────────────────────────┐
  │ 🎨 KB국민카드           │ ← 색상/아이콘
  │    기본 결제수단         │ ← 설명
  │  [편집] [삭제]          │ ← 액션
  └─────────────────────────┘

❌ 비어있음:
  🏧
  결제수단이 없습니다
  결제수단을 추가해보세요
  [+ 추가]
```

**탭 2: 거래 내역**
```
🔄 로딩:  CircularProgressIndicator

✅ 데이터:
  ┌─────────────────────────┐
  │ 🔔 스타벅스             │
  │    50,000원              │
  │    [자세히 보기 →]       │
  └─────────────────────────┘

❌ 비어있음:
  📄
  대기 중인 거래가 없습니다
  SMS/푸시 알림에서 감지된 거래가 표시됩니다
```

---

## 3️⃣ 핵심 구현 사항

### TabController 관리

```dart
class _PaymentMethodManagementPageState extends ConsumerStatefulWidget {
  with TickerProviderStateMixin {
    late TabController _tabController;

    // 2개 탭 생성
    _tabController = TabController(length: 2, vsync: this);
  }

  // 탭 전환 시 FAB 동적 변경
  floatingActionButton: _tabController.index == 0 ? FAB : null
}
```

### 각 탭별 데이터 출처

**탭 1 (결제수단)**
```dart
final paymentMethodsAsync = ref.watch(
  paymentMethodNotifierProvider,
);
// 데이터 출처: payment_methods 테이블
// 저장: ✓ (영구)
// 갱신: 실시간 구독 (Realtime)
```

**탭 2 (거래 내역)**
```dart
final pendingAsync = ref.watch(
  pendingTransactionNotifierProvider,
);
// 데이터 출처: transactions 테이블 (is_pending=true)
// 저장: ✓ (사용자가 처리할 때까지)
// 갱신: 실시간 구독 (Realtime)
```

---

## 4️⃣ SMS/Push 알림 처리 흐름

### 📱 SMS 기반 자동 인식 (변경 없음)

```
1. SMS 수신
   ↓
2. SmsListenerService 감지
   ↓
3. SmsParsingService 파싱
   - 발신자: KB국민카드 등
   - 금액: 정규식으로 추출
   - 금융 키워드: 출금/입금/승인/결제
   ↓
4. LearnedSmsFormat 학습
   (기기 로컬 저장, DB 아님)
   ↓
5. 거래 제안
   - pending_transactions 생성
   - 사용자 수동 확인 필요 (자동 처리 제외)
   ↓
6. 사용자 확인
   - 탭 2에서 표시
   - 수정/삭제 가능
   - 완료 시 transactions 이동
```

### 🔔 Push 알림 (저장 안 함)

```
1. 공유 가계부 거래 변경 감지
   (트리거: transaction INSERT/UPDATE/DELETE)
   ↓
2. Edge Function: send-push-notification 실행
   ↓
3. FCM으로 실시간 발송
   - 제목: 거래 설명
   - 내용: 금액, 카테고리 등
   - 데이터: ledger_id, transaction_id 등
   ↓
4. 앱이 푸시 수신
   - 로컬 알림 표시 (Android)
   - 네이티브 알림 표시 (iOS)
   - 사용자 기기에만 표시 ← DB 저장 X
   ↓
5. 사용자 클릭
   - 거래 상세 페이지로 이동
   - 또는 무시 (DB 기록 없음)
```

**Push 알림이 저장되지 않는 이유:**
- ✅ 실시간 알림 = 발송 후 역할 종료
- ✅ 거래 이력은 transactions 테이블에 있음
- ✅ 대기 거래는 pending_transactions에 있음
- ✅ DB 스토리지 절약
- ✅ 쿼리 성능 향상

---

## 5️⃣ 데이터 흐름도

```
┌─────────────────────────────────────────────────────────────┐
│                        사용자 활동                             │
└─────────────────────────────────────────────────────────────┘
                              │
                ┌─────────────┼─────────────┐
                ↓             ↓             ↓
          1. SMS 수신   2. 푸시 알림   3. 앱 조작
             (기기)      (Device)      (탭 전환)
                │             │             │
                └─────────────┼─────────────┘
                              ↓
                    PaymentMethodManagementPage
                              │
                ┌─────────────┴─────────────┐
                ↓                           ↓
          탭 1: 결제수단              탭 2: 거래 내역
          (결제수단 관리)            (대기 중 처리)
                │                         │
                ↓                         ↓
    payment_methods 테이블    pending_transactions 테이블
         (영구 저장)                (임시 저장)
                │                         │
                └─────────────┬───────────┘
                              ↓
                    사용자 확인 및 처리
                              │
                    ┌─────────┴─────────┐
                    ↓                   ↓
              [수정/삭제]         [확인/완료]
                    │                   │
                    └─────────┬─────────┘
                              ↓
                    transactions 테이블
                   (최종 거래 기록 저장)
```

---

## 6️⃣ 코드 체크리스트

### 구현 완료 항목

- [x] TabController 추가 (TickerProviderStateMixin)
- [x] TabBar 추가 (AppBar bottom)
- [x] TabBarView 추가 (2개 탭)
- [x] 탭 1: SMS 기반 결제수단 목록
- [x] 탭 2: 거래 내역 (pending_transactions)
- [x] FAB 동적 표시 (탭 1에서만)
- [x] EmptyState 처리

### 테스트 필요 항목

- [ ] TabBar 탭 전환 시 FAB 표시/숨김
- [ ] 탭 1에서 결제수단 추가 (FAB)
- [ ] 탭 2에서 거래 내역 조회
- [ ] 거래 내역 클릭 → 상세 페이지 이동
- [ ] 로딩/에러/비어있음 상태 표시
- [ ] SMS 파싱 및 pending_transactions 생성
- [ ] Push 알림 수신 (저장 안 함 확인)

---

## 7️⃣ 마이그레이션 불필요

Push 알림을 저장하지 않으므로, 다음 항목은 변경 없음:

- ✓ `push_notifications` 테이블 유지 (현재 미사용)
- ✓ `fcm_tokens` 테이블 유지 (토큰 관리용)
- ✓ `notification_settings` 테이블 유지
- ✓ Edge Function 수정 불필요 (발송만 계속)
- ✓ 기존 Provider/Repository 유지

**DB 변경**: 없음 ✓

---

## 8️⃣ 향후 개선 가능

1. **멤버별 결제수단** (Phase 2)
   - payment_methods에 user_id 추가
   - 탭을 멤버별로 확장
   - 각 멤버가 개별 결제수단 관리

2. **거래 필터링** (Phase 2)
   - 카테고리별 필터
   - 금액대별 필터
   - 날짜 범위 선택

3. **통계 대시보드** (Phase 3)
   - 월별 집계
   - 카테고리별 비율
   - 예산 대비 실적

---

## 참고사항

- 🎯 **원칙**: SMS 자동 인식 + Push 실시간 알림 (저장 안 함)
- 📊 **데이터**: transactions만 영구 저장
- ⚡ **성능**: 불필요한 DB 쓰기 제거
- 🔐 **보안**: RLS 정책 유지
