# Plan: 자동수집 제안 모드 버그 수정

## 1. 개요

### 문제 정의
- **증상**: 수원페이 결제수단이 제안(suggest) 모드로 설정되어 있음에도 불구하고 자동(auto) 모드처럼 동작하여 거래가 자동으로 생성됨
- **재현 환경**: 실제 기기 (R3CT90TAG8Z)
- **대조군**: KB국민카드는 제안 모드가 정상 작동 (수집내역에 "대기중"으로 표시됨)

### 영향 범위
- **사용자 경험**: 제안 모드 설정이 무시되어 사용자 확인 없이 거래가 생성됨
- **데이터 정합성**: 의도하지 않은 거래가 자동으로 추가될 수 있음
- **알림 시스템**: 제안 모드인데도 "푸시알림 자동수집 제안" 알림이 R3CT90TAG8Z로 전송됨

### 목표
1. 수원페이가 제안 모드에서 자동 저장되는 원인 파악
2. KB국민카드와 수원페이의 처리 차이점 분석
3. 제안 모드 로직 수정 및 검증
4. 푸시알림 전송 로직 검증 및 수정

## 2. 현재 상황 분석

### 관련 기능 개요

#### AutoSaveMode 타입
```dart
enum AutoSaveMode {
  manual,   // 수동: SMS/Push 자동수집 비활성화
  suggest,  // 제안: 수집 후 사용자 확인 필요 (pending 상태로 저장)
  auto;     // 자동: 수집 후 즉시 거래 생성 (confirmed 상태로 저장)
}
```

#### AutoCollectSource 타입
```dart
enum AutoCollectSource {
  sms,   // SMS로 수집
  push;  // Push 알림으로 수집
}
```

### 자동수집 흐름도

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Push 알림 수신                                            │
│    NotificationListenerWrapper.onNotificationReceived()     │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 2. 금융 앱 패키지명 확인                                     │
│    _isFinancialApp(packageName)                             │
│    - KB Pay: com.kbcard.cxh.appcard ✅                      │
│    - 경기지역화폐: gov.gyeonggi.ggcard ✅                   │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 3. 결제수단 매칭                                             │
│    _findMatchingPaymentMethod(packageName, content)         │
│    - autoCollectSource == push 체크 (line 574)             │
│    - 학습된 포맷으로 매칭 (line 586-602)                    │
│    - Fallback: 결제수단 이름으로 매칭 (line 604-618)       │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 4. 알림 처리                                                 │
│    _processNotification()                                   │
│    - SMS 파싱 (line 652-663)                                │
│    - 중복 체크 (line 680-685)                               │
│    - 카테고리 매핑 (line 687-693)                           │
│    - **autoSaveMode 확인** (line 695-706) ⚠️                │
│    - shouldAutoSave 결정 (line 708-710)                     │
└─────────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────────┐
│ 5. Pending Transaction 생성                                 │
│    _createPendingTransaction()                              │
│    - 항상 pending 상태로 먼저 생성 (line 785-807)          │
│    - **shouldAutoSave == true 시 거래 생성** (line 814-846) │
│    - 거래 생성 성공 시 confirmed로 업데이트 (line 836-839) │
└─────────────────────────────────────────────────────────────┘
```

### 핵심 로직 분석

#### 1. autoSaveMode 캐싱 메커니즘 (notification_listener_wrapper.dart:695-706)

```dart
// 캐시에서 최신 autoSaveMode 확인 (refreshPaymentMethods()로 동기화됨)
final cachedPaymentMethod = _autoSavePaymentMethods
    .where((pm) => pm.id == paymentMethod.id)
    .firstOrNull;
final autoSaveModeStr =
    cachedPaymentMethod?.autoSaveMode.toJson() ??
    paymentMethod.autoSaveMode.toJson();
if (kDebugMode) {
  debugPrint(
    'Notification matched: mode=$autoSaveModeStr (from cache), pm=${paymentMethod.name}',
  );
}
```

**문제점 가능성:**
- `_autoSavePaymentMethods` 캐시가 최신 상태로 업데이트되지 않았을 수 있음
- `_findMatchingPaymentMethod`에서 반환된 `paymentMethod` 객체가 오래된 데이터일 수 있음

#### 2. shouldAutoSave 결정 로직 (notification_listener_wrapper.dart:708-710)

```dart
// 자동 저장 여부 결정: 중복이 아니고 auto 모드일 때만 자동 저장
final shouldAutoSave =
    !duplicateResult.isDuplicate && autoSaveModeStr == 'auto';
```

**정상 동작:**
- `suggest` 모드: `shouldAutoSave = false` → pending 상태로만 저장
- `auto` 모드: `shouldAutoSave = true` → 거래 생성 + confirmed 상태로 업데이트

#### 3. 거래 자동 생성 로직 (notification_listener_wrapper.dart:814-846)

```dart
// 2. 자동 저장 모드일 때만 거래 생성 시도
if (shouldAutoSave) {
  final amount = parsedResult.amount;
  final type = parsedResult.transactionType;

  // 금액과 타입이 있어야만 거래 생성 가능
  if (amount != null && type != null) {
    if (kDebugMode) {
      debugPrint('[AutoSave] Creating actual transaction...');
    }
    try {
      await _transactionRepository.createTransaction(
        // ... 거래 생성
      );

      // 3. 거래 생성 성공 시에만 confirmed로 업데이트
      await _pendingTransactionRepository.updateStatus(
        id: pendingTx.id,
        status: PendingTransactionStatus.confirmed,
      );
      // ...
    }
  }
}
```

**정상 동작:**
- `shouldAutoSave == false` (suggest 모드): 이 블록이 실행되지 않음
- pending 상태 유지 → "대기중" 탭에 표시

### 가능한 원인 추론

#### 가설 1: 캐시 동기화 문제
- `_autoSavePaymentMethods` 캐시가 결제수단 설정 변경 후 갱신되지 않음
- `refreshPaymentMethods()` 호출 시점 문제

#### 가설 2: 결제수단 매칭 문제
- `_findMatchingPaymentMethod`가 잘못된 결제수단 객체를 반환
- 수원페이와 다른 auto 모드 결제수단이 혼동됨

#### 가설 3: Race Condition
- 설정 변경과 알림 처리가 동시에 발생하여 오래된 캐시 사용
- Realtime subscription으로 설정 변경이 반영되기 전에 알림 처리됨

#### 가설 4: 학습된 포맷 문제
- 수원페이의 학습된 포맷(LearnedPushFormat)이 잘못된 결제수단 ID를 가리킴
- KB국민카드는 학습된 포맷이 없어서 정상 동작

## 3. 조사 계획

### Phase 1: 실제 로그 수집 (즉시 실행)

#### 목표
실제 기기(R3CT90TAG8Z)에서 수원페이 결제 시 상세 로그 수집

#### 방법
```bash
# 1. 로그 초기화
adb -s R3CT90TAG8Z logcat -c

# 2. Flutter 앱 재시작 (디버그 모드)
flutter run --device-id=R3CT90TAG8Z

# 3. 수원페이 실제 결제 (소액)

# 4. 로그 수집
adb -s R3CT90TAG8Z logcat | grep -E "\[NotificationListener\]|\[AutoSave\]|\[CreatePending\]|\[Matching\]"
```

#### 수집할 정보
1. **결제수단 매칭 로그**
   - `[Matching] Checking PM:` - 어떤 결제수단들이 확인되는지
   - `[Matching] Matched by format!` 또는 `Matched by payment method name!`

2. **autoSaveMode 로그**
   - `Notification matched: mode=xxx (from cache), pm=수원페이`
   - mode가 'suggest'인지 'auto'인지 확인

3. **거래 생성 로그**
   - `[AutoSave] Creating actual transaction...` - 이 로그가 있으면 안됨!
   - `[CreatePending] Success! ID: xxx`

4. **상태 업데이트 로그**
   - `status updated to confirmed` - 이 로그가 있으면 안됨!

### Phase 2: 데이터베이스 직접 조회 (즉시 실행)

#### 목표
Supabase에서 실제 저장된 데이터 확인

#### 조회 쿼리
```sql
-- 1. 수원페이 결제수단 설정 확인
SELECT
  id,
  name,
  auto_save_mode,
  auto_collect_source,
  can_auto_save,
  owner_user_id
FROM payment_methods
WHERE ledger_id = '<현재 가계부 ID>'
  AND name LIKE '%수원%';

-- 2. KB국민카드 결제수단 설정 확인
SELECT
  id,
  name,
  auto_save_mode,
  auto_collect_source,
  can_auto_save,
  owner_user_id
FROM payment_methods
WHERE ledger_id = '<현재 가계부 ID>'
  AND name LIKE '%KB%';

-- 3. 최근 pending_transactions 확인
SELECT
  id,
  payment_method_id,
  status,
  parsed_amount,
  parsed_merchant,
  source_type,
  created_at
FROM pending_transactions
WHERE ledger_id = '<현재 가계부 ID>'
  AND created_at >= NOW() - INTERVAL '1 hour'
ORDER BY created_at DESC;

-- 4. 학습된 Push 포맷 확인
SELECT
  lpf.id,
  lpf.payment_method_id,
  pm.name as payment_method_name,
  lpf.package_name,
  lpf.confidence,
  lpf.match_count
FROM learned_push_formats lpf
JOIN payment_methods pm ON lpf.payment_method_id = pm.id
WHERE pm.ledger_id = '<현재 가계부 ID>'
  AND (pm.name LIKE '%수원%' OR pm.name LIKE '%KB%');
```

### Phase 3: 코드 레벨 디버깅 (로그 분석 후)

#### 의심 지점
1. **notification_listener_wrapper.dart:359-362**
   ```dart
   Future<void> refreshPaymentMethods() async {
     await _loadAutoSavePaymentMethods();
     await _loadLearnedFormats();
   }
   ```
   - `refreshPaymentMethods()` 호출 시점 확인 필요
   - 설정 변경 후 즉시 호출되는지 검증

2. **notification_listener_wrapper.dart:573-577**
   ```dart
   // Push 소스로 설정된 결제수단만 매칭 (SMS로 설정된 결제수단은 무시)
   if (pm.autoCollectSource != AutoCollectSource.push) {
     continue;
   }
   ```
   - autoCollectSource가 올바르게 필터링되는지 확인

3. **notification_listener_wrapper.dart:586-602**
   ```dart
   // 1. 학습된 포맷으로 먼저 매칭 시도
   if (formats != null && formats.isNotEmpty) {
     for (final format in formats) {
       if (format.matchesNotification(packageLower, contentLower)) {
         return _PaymentMethodMatchResult(
           paymentMethod: pm,
           learnedFormat: format.toEntity(),
         );
       }
     }
   }
   ```
   - 수원페이의 학습된 포맷이 잘못된 결제수단을 가리키는지 확인

### Phase 4: 푸시알림 전송 로직 검증

#### 목표
제안 모드인데도 "푸시알림 자동수집 제안" 알림이 전송되는 원인 파악

#### 조사 대상
- `lib/features/notification/services/firebase_messaging_service.dart`
- `lib/features/notification/data/services/notification_service.dart`
- Supabase Edge Functions (푸시 알림 전송 트리거)

#### 의심 지점
1. **알림 전송 조건 로직**
   - pending_transactions 생성 시 트리거되는 로직
   - status가 'pending'일 때만 알림을 보내야 함

2. **알림 중복 전송 방지**
   - `firebase_messaging_service.dart:233-269` - 중복 메시지 ID 체크
   - `notification_listener_wrapper.dart:52-54` - 최근 처리된 메시지 캐시

## 4. 수정 계획

### 수정 1: refreshPaymentMethods() 호출 시점 보장

#### 목적
설정 변경 후 즉시 캐시를 갱신하여 최신 autoSaveMode 반영

#### 수정 위치
- `lib/features/payment_method/presentation/pages/payment_method_management_page.dart`
- 설정 저장 후 `NotificationListenerWrapper.instance.refreshPaymentMethods()` 호출

#### 구현
```dart
// AutoSaveMode 변경 후
await paymentMethodRepository.updateAutoSaveMode(
  id: paymentMethod.id,
  mode: newMode,
);

// 즉시 캐시 갱신
if (Platform.isAndroid) {
  await NotificationListenerWrapper.instance.refreshPaymentMethods();
}
```

### 수정 2: autoSaveMode 로그 강화

#### 목적
실제 사용된 autoSaveMode 값을 명확히 로깅하여 디버깅 용이성 향상

#### 수정 위치
- `notification_listener_wrapper.dart:695-716`

#### 구현
```dart
// 기존 로그에 추가 정보 포함
if (kDebugMode) {
  debugPrint('=== AutoSaveMode Decision ===');
  debugPrint('  PM ID: ${paymentMethod.id}');
  debugPrint('  PM Name: ${paymentMethod.name}');
  debugPrint('  Original mode: ${paymentMethod.autoSaveMode.toJson()}');
  debugPrint('  Cached mode: ${cachedPaymentMethod?.autoSaveMode.toJson() ?? "not found"}');
  debugPrint('  Final mode: $autoSaveModeStr');
  debugPrint('  shouldAutoSave: $shouldAutoSave');
  debugPrint('  isDuplicate: ${duplicateResult.isDuplicate}');
  debugPrint('=============================');
}
```

### 수정 3: 학습된 포맷 검증 로직 추가

#### 목적
학습된 포맷이 올바른 결제수단을 가리키는지 검증

#### 수정 위치
- `notification_listener_wrapper.dart:586-602`

#### 구현
```dart
// 학습된 포맷으로 매칭 시 결제수단 ID 일치 여부 검증
if (formats != null && formats.isNotEmpty) {
  for (final format in formats) {
    // payment_method_id 일치 여부 확인
    if (format.paymentMethodId != pm.id) {
      if (kDebugMode) {
        debugPrint('[Matching] WARNING: Format payment_method_id mismatch!');
        debugPrint('  Format ID: ${format.id}');
        debugPrint('  Format PM ID: ${format.paymentMethodId}');
        debugPrint('  Current PM ID: ${pm.id}');
      }
      continue; // 불일치하면 스킵
    }

    if (format.matchesNotification(packageLower, contentLower)) {
      return _PaymentMethodMatchResult(
        paymentMethod: pm,
        learnedFormat: format.toEntity(),
      );
    }
  }
}
```

### 수정 4: 푸시알림 전송 조건 검증

#### 목적
pending 상태인 거래에 대해서만 "자동수집 제안" 알림 전송

#### 수정 위치
- Supabase Edge Functions 또는 알림 트리거 로직

#### 구현 (추후 코드 확인 후 결정)
```typescript
// Edge Function 예시
if (pendingTransaction.status === 'pending' &&
    paymentMethod.auto_save_mode === 'suggest') {
  await sendPushNotification({
    userId: pendingTransaction.user_id,
    title: '푸시알림 자동수집 제안',
    body: `${pendingTransaction.parsed_merchant} ${pendingTransaction.parsed_amount}원`,
  });
}
```

### 수정 5: Realtime 동기화 개선

#### 목적
설정 변경 시 모든 기기에서 즉시 캐시 갱신

#### 수정 위치
- `lib/features/payment_method/data/repositories/payment_method_repository.dart`
- Realtime subscription 추가

#### 구현
```dart
// payment_methods 테이블 변경 감지
RealtimeChannel subscribePaymentMethodChanges({
  required String ledgerId,
  required void Function() onChanged,
}) {
  return _client
      .channel('payment_methods_changes_$ledgerId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'house',
        table: 'payment_methods',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ledger_id',
          value: ledgerId,
        ),
        callback: (payload) {
          onChanged(); // NotificationListenerWrapper.refreshPaymentMethods() 호출
        },
      )
      .subscribe();
}
```

## 5. 검증 계획

### 시나리오 1: 수원페이 제안 모드 검증

#### 전제 조건
- 수원페이 결제수단: autoSaveMode = 'suggest', autoCollectSource = 'push'

#### 테스트 단계
1. 수원페이 실제 결제 (소액)
2. 로그 확인: `mode=suggest (from cache)`, `shouldAutoSave=false`
3. 데이터베이스 확인:
   - `pending_transactions.status = 'pending'`
   - `transactions` 테이블에 거래가 생성되지 않음
4. UI 확인: "대기중" 탭에 표시됨

#### 성공 기준
- 거래가 자동으로 생성되지 않음
- pending 상태로만 저장됨

### 시나리오 2: KB국민카드 제안 모드 검증 (대조군)

#### 전제 조건
- KB국민카드 결제수단: autoSaveMode = 'suggest', autoCollectSource = 'push'

#### 테스트 단계
1. KB Pay 실제 결제
2. 시나리오 1과 동일한 검증 수행

#### 성공 기준
- 수원페이와 동일하게 동작

### 시나리오 3: 자동 모드 검증

#### 전제 조건
- 테스트용 결제수단: autoSaveMode = 'auto', autoCollectSource = 'push'

#### 테스트 단계
1. 실제 결제
2. 로그 확인: `mode=auto (from cache)`, `shouldAutoSave=true`
3. 데이터베이스 확인:
   - `pending_transactions.status = 'confirmed'`
   - `transactions` 테이블에 거래가 생성됨
4. UI 확인: "확인됨" 탭에 표시됨

#### 성공 기준
- 거래가 자동으로 생성됨
- confirmed 상태로 업데이트됨

### 시나리오 4: 캐시 갱신 검증

#### 테스트 단계
1. 결제수단 설정을 suggest → auto로 변경
2. 즉시 실제 결제 (Race Condition 테스트)
3. auto 모드로 동작하는지 확인

#### 성공 기준
- 설정 변경이 즉시 반영됨
- 오래된 캐시 사용하지 않음

### 시나리오 5: 푸시알림 전송 검증

#### 테스트 단계
1. 수원페이 제안 모드로 결제
2. 푸시 알림 수신 여부 확인
3. 알림 내용 확인: "푸시알림 자동수집 제안"

#### 성공 기준
- pending 상태일 때만 알림 전송
- confirmed 상태일 때는 알림 전송하지 않음

## 6. 롤백 계획

### 위험 평가
- **낮음**: 로그 추가는 기능 변경 없음
- **중간**: 캐시 갱신 로직 변경은 기존 기능에 영향 가능
- **높음**: 학습된 포맷 검증 로직은 매칭 실패 가능성 있음

### 롤백 절차
1. **즉시 롤백 필요 시**
   - Git revert 또는 이전 커밋으로 복구
   - 수정 전 커밋 해시 기록 필수

2. **부분 롤백**
   - 로그 추가만 유지, 로직 변경은 원복
   - Feature flag로 새 로직 제어

3. **긴급 패치**
   - 모든 결제수단을 manual 모드로 임시 전환
   - 사용자에게 수동 거래 입력 안내

## 7. 일정

### Phase 1: 조사 (1일)
- [x] Plan 문서 작성
- [ ] 실제 로그 수집
- [ ] 데이터베이스 조회
- [ ] 원인 특정

### Phase 2: 수정 (1일)
- [ ] refreshPaymentMethods() 호출 시점 보장
- [ ] 로그 강화
- [ ] 학습된 포맷 검증 로직 추가
- [ ] Realtime 동기화 개선

### Phase 3: 검증 (0.5일)
- [ ] 시나리오 1-5 테스트
- [ ] 회귀 테스트

### Phase 4: 문서화 (0.5일)
- [ ] Design 문서 작성
- [ ] 변경 사항 CHANGELOG 기록
- [ ] CLAUDE.md 업데이트

## 8. 참고 자료

### 관련 파일
1. **핵심 로직**
   - `lib/features/payment_method/data/services/notification_listener_wrapper.dart`
   - `lib/features/payment_method/presentation/providers/pending_transaction_provider.dart`
   - `lib/features/payment_method/data/repositories/pending_transaction_repository.dart`

2. **도메인 모델**
   - `lib/features/payment_method/domain/entities/payment_method.dart`
   - `lib/features/payment_method/domain/entities/pending_transaction.dart`
   - `lib/features/payment_method/domain/entities/learned_push_format.dart`

3. **UI**
   - `lib/features/payment_method/presentation/pages/payment_method_management_page.dart`
   - `lib/features/payment_method/presentation/widgets/pending_transaction_card.dart`

### 데이터베이스 마이그레이션
- `supabase/migrations/034_add_auto_save_features.sql` - 자동수집 기능 추가
- `supabase/migrations/042_add_auto_collect_source.sql` - SMS/Push 소스 선택 컬럼 추가

### 관련 문서
- `CLAUDE.md` - SMS 자동수집 기능 섹션
- `docs/updates_2026-01-25.md` - 금융 앱 패키지명 검증 기록

## 9. 추가 고려사항

### 다중 기기 환경
- 사용자가 여러 기기를 사용하는 경우 캐시 동기화 전략
- Realtime subscription으로 모든 기기에서 즉시 갱신

### 성능 최적화
- `refreshPaymentMethods()` 호출 빈도 제한 (Debounce)
- 캐시 TTL(Time To Live) 설정 고려

### 보안
- 학습된 포맷 데이터 무결성 검증
- 악의적인 포맷 데이터로 인한 잘못된 매칭 방지

### 사용자 경험
- 설정 변경 후 "캐시 갱신 중..." 로딩 표시
- 에러 발생 시 사용자 친화적인 메시지

---

## 변경 이력

| 날짜 | 작성자 | 변경 내용 |
|------|--------|-----------|
| 2026-02-01 | Claude | 초기 작성 |
