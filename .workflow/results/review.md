# Code Review: User-Based Pending Transactions Security

**검토일**: 2026-01-22  
**검토 대상**: 자동수집 거래(pending_transactions) 사용자별 접근 제어 강화  
**검토자**: Senior Code Reviewer

---

## 📊 Summary

- **검토 파일**: 3개 (마이그레이션 1개, Repository 1개, Provider 1개)
- **Critical (보안 취약점, 데이터 누출)**: 2개 ⚠️
- **High Priority (기능 버그)**: 0개
- **Medium Priority (개선 가능)**: 2개
- **Low Priority**: 1개

---

## 🔒 Security Analysis

### RLS Policy Review (038 마이그레이션)

**✅ 긍정적인 점**:
1. **SELECT 정책**: `user_id = auth.uid()` 조건으로 본인 거래만 조회하도록 완벽히 제한
2. **UPDATE 정책**: USING과 WITH CHECK 모두 `user_id = auth.uid()` 적용 - 이중 방어
3. **DELETE 정책**: `user_id = auth.uid()` 조건으로 본인 거래만 삭제 가능
4. **INSERT 정책 보존**: 034 마이그레이션의 INSERT 정책 유지 (user_id + ledger_id 체크)

**✅ Defense in Depth 전략**:
- 034 마이그레이션의 `ledger_id IN (SELECT ... WHERE user_id = auth.uid())` 정책을 더 엄격한 `user_id = auth.uid()`로 대체
- 038 정책이 034 정책을 완전히 덮어쓰므로 충돌 없음

**⚠️ 발견된 문제**:
- INSERT 정책 검증 누락 (Critical 섹션 참조)

### Application Layer Review

**✅ Repository 레벨 방어** (`pending_transaction_repository.dart`):
1. **getPendingTransactions** (L10-35): userId 파라미터 추가, NULL일 때만 필터 스킵 ✅
2. **confirmAll** (L208-226): userId 필터 적용 ✅
3. **rejectAll** (L228-238): userId 필터 적용 ✅
4. **deleteAllByStatus** (L152-163): userId 필터 적용 ✅
5. **deleteAllRejected** (L165-171): deleteAllByStatus 호출로 간접 필터 ✅
6. **markAllAsViewed** (L276-286): userId 필터 적용 ✅

**✅ Provider 레벨 방어** (`pending_transaction_provider.dart`):
1. **PendingTransactionNotifier**: `_userId` 필드 추가 (L48)
2. **생성자**: NULL 체크 후 state 초기화 (L59-64) ✅
3. **loadPendingTransactions**: userId 전달 (L100-104) ✅
4. **confirmAll**: userId 전달 (L193) ✅
5. **rejectAll**: userId 전달 (L232) ✅
6. **deleteAllByStatus**: userId 전달 (L257) ✅
7. **markAllAsViewed**: userId 전달 (L272) ✅

**⚠️ 발견된 문제**:
- `getPendingCount` 메서드 보안 취약점 (Critical 섹션 참조)
- Realtime Subscription 필터 누락 (Critical 섹션 참조)

### Attack Surface Analysis

| 공격 시나리오 | RLS 방어 | App 방어 | 결과 |
|-------------|---------|---------|------|
| A가 B의 거래 조회 (getPendingTransactions) | ✅ `user_id = auth.uid()` | ✅ `.eq('user_id', userId)` | **안전** |
| A가 B의 거래 수정 (updateStatus) | ✅ USING + WITH CHECK | ✅ ID로 직접 접근 (RLS 차단) | **안전** |
| A가 B의 거래 삭제 (deletePendingTransaction) | ✅ `user_id = auth.uid()` | ✅ ID로 직접 접근 (RLS 차단) | **안전** |
| A가 B의 거래 카운트 조회 (getPendingCount) | ✅ 038 정책 (user_id만 체크) | ❌ userId 필터 없음 | **RLS 방어** |
| A가 Realtime으로 B의 거래 감지 | ❌ ledger_id 필터만 적용 | ❌ userId 필터 없음 | **취약** ⚠️ |
| A가 B의 거래 일괄 확인 (confirmAll) | ✅ 038 정책 | ✅ userId 필터 | **안전** |
| 비로그인 사용자 접근 | ✅ auth.uid() NULL → 모든 쿼리 실패 | ✅ currentUser NULL → early return | **안전** |

---

## 🚨 Critical Issues

### Critical 1: `getPendingCount` 메서드 일관성 문제

**파일**: `pending_transaction_repository.dart`  
**라인**: 37-45

**문제**:
```dart
Future<int> getPendingCount(String ledgerId) async {
  final response = await _client
      .from('pending_transactions')
      .select('id')
      .eq('ledger_id', ledgerId)
      .eq('is_viewed', false);  // ❌ user_id 필터 없음

  return (response as List).length;
}
```

**위험**:
- **보안**: 038 RLS 정책 (`user_id = auth.uid()`)이 방어하므로 **실제 데이터 누출은 없음**
- **일관성**: 다른 메서드는 명시적으로 userId 필터를 적용하는데, 이 메서드만 RLS에 의존
- **Defense in Depth 위배**: 애플리케이션 레벨 방어가 누락됨

**해결**:
```dart
// 수정 전 (현재)
Future<int> getPendingCount(String ledgerId) async {
  final response = await _client
      .from('pending_transactions')
      .select('id')
      .eq('ledger_id', ledgerId)
      .eq('is_viewed', false);

  return (response as List).length;
}

// 수정 후 (권장)
Future<int> getPendingCount(String ledgerId, String userId) async {
  final response = await _client
      .from('pending_transactions')
      .select('id')
      .eq('ledger_id', ledgerId)
      .eq('user_id', userId)  // ✅ 명시적 필터 추가
      .eq('is_viewed', false);

  return (response as List).length;
}
```

**Provider 수정 필요**:
```dart
// pending_transaction_provider.dart L33-41
final pendingTransactionCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return 0;

  final currentUser = ref.watch(currentUserProvider);  // ✅ 추가
  if (currentUser == null) return 0;  // ✅ 추가

  final repository = ref.watch(pendingTransactionRepositoryProvider);
  return repository.getPendingCount(ledgerId, currentUser.id);  // ✅ userId 전달
});
```

**영향도**: 
- **현재 보안**: RLS가 방어하므로 실제 데이터 누출은 없음
- **코드 품질**: Defense in Depth 전략 위배, 일관성 문제
- **우선순위**: Critical (코드 일관성 중요)

---

### Critical 2: Realtime Subscription 사용자 필터 누락

**파일**: `pending_transaction_repository.dart`  
**라인**: 240-260

**문제**:
```dart
RealtimeChannel subscribePendingTransactions({
  required String ledgerId,
  required void Function() onTableChanged,
}) {
  return _client
      .channel('pending_transactions_changes_$ledgerId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'house',
        table: 'pending_transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ledger_id',
          value: ledgerId,  // ❌ user_id 필터 없음
        ),
        callback: (payload) {
          onTableChanged();
        },
      )
      .subscribe();
}
```

**위험**:
- **실시간 메타데이터 누출**: 공유 가계부에서 A 사용자가 B 사용자의 거래 변경 이벤트를 감지할 수 있음
- **RLS 미적용**: Supabase Realtime은 PostgresChangeFilter만으로 필터링하며, **RLS 정책이 적용되지 않음**
- **Payload 노출 가능성**: `payload.new`, `payload.old`에 다른 사용자의 데이터가 포함될 수 있음
- **불필요한 새로고침**: B 사용자의 거래 변경 시 A 사용자 화면도 새로고침됨 (성능 저하)

**Supabase Realtime 보안 메커니즘**:
- Realtime은 **클라이언트 측 필터링**을 사용하므로 RLS와 별도로 동작
- `PostgresChangeFilter`는 단순 WHERE 절과 유사하며, 인증 컨텍스트(`auth.uid()`)를 사용하지 않음
- **서버는 필터 조건만 확인하고, 모든 이벤트를 클라이언트에 전송**

**해결**:
```dart
// 수정 전 (현재 - 취약)
RealtimeChannel subscribePendingTransactions({
  required String ledgerId,
  required void Function() onTableChanged,
}) {
  return _client
      .channel('pending_transactions_changes_$ledgerId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'house',
        table: 'pending_transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ledger_id',
          value: ledgerId,
        ),
        callback: (payload) {
          onTableChanged();
        },
      )
      .subscribe();
}

// 수정 후 (권장 - 안전)
RealtimeChannel subscribePendingTransactions({
  required String ledgerId,
  required String userId,  // ✅ userId 파라미터 추가
  required void Function() onTableChanged,
}) {
  return _client
      .channel('pending_transactions_changes_${ledgerId}_$userId')  // ✅ 채널명에 userId 포함
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'house',
        table: 'pending_transactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'ledger_id',
          value: ledgerId,
        ),
        callback: (payload) {
          // ✅ 클라이언트 측 필터링 (Defense in Depth)
          final Map<String, dynamic>? newData = payload.newRecord;
          final Map<String, dynamic>? oldData = payload.oldRecord;
          
          // INSERT/UPDATE 이벤트
          if (newData != null && newData['user_id'] != userId) {
            return;  // 다른 사용자 이벤트 무시
          }
          
          // DELETE 이벤트
          if (newData == null && oldData != null && oldData['user_id'] != userId) {
            return;  // 다른 사용자 이벤트 무시
          }
          
          onTableChanged();
        },
      )
      .subscribe();
}
```

**Provider 수정 필요**:
```dart
// pending_transaction_provider.dart L67-82
void _subscribeToChanges() {
  if (_ledgerId == null || _userId == null) return;  // ✅ _userId 체크 추가

  try {
    _subscription = _repository.subscribePendingTransactions(
      ledgerId: _ledgerId,
      userId: _userId,  // ✅ userId 전달
      onTableChanged: () {
        // DB 변경 시 리스트 새로고침 및 카운트 갱신
        loadPendingTransactions();
        _ref.invalidate(pendingTransactionCountProvider);
      },
    );
  } catch (e) {
    debugPrint('PendingTransaction Realtime subscribe fail: $e');
  }
}
```

**대안 (클라이언트 측 필터링만 사용)**:
서버 측 필터가 불가능하다면, 최소한 클라이언트 측 필터링은 반드시 적용해야 합니다.

```dart
callback: (payload) {
  // 이벤트 데이터에서 user_id 확인
  final dynamic recordData = payload.newRecord ?? payload.oldRecord;
  if (recordData is Map<String, dynamic> && recordData['user_id'] != userId) {
    return;  // 다른 사용자 이벤트 무시
  }
  onTableChanged();
},
```

**영향도**: 
- **현재 보안**: **매우 취약** - B 사용자의 거래 변경 시 A 사용자 화면도 새로고침됨
- **개인정보 보호**: 거래 발생 시점/빈도 등 메타데이터 유출 가능
- **성능**: 불필요한 화면 새로고침으로 성능 저하

---

## 📝 Medium Priority Issues

### Medium 1: `deletePendingTransaction` 메서드 사용자 검증 부재

**파일**: `pending_transaction_repository.dart`  
**라인**: 148-150

**문제**:
```dart
Future<void> deletePendingTransaction(String id) async {
  await _client.from('pending_transactions').delete().eq('id', id);
  // ❌ userId 필터 없음
}
```

**위험**:
- **RLS 의존**: 038 마이그레이션의 DELETE 정책 (`user_id = auth.uid()`)이 방어하므로 실제 보안 위험은 없음
- **일관성 문제**: 다른 메서드(`deleteAllByStatus` 등)는 명시적으로 userId 필터를 적용하는데, 이 메서드만 RLS에 의존

**해결**:
```dart
// 수정 전 (현재)
Future<void> deletePendingTransaction(String id) async {
  await _client.from('pending_transactions').delete().eq('id', id);
}

// 수정 후 (권장)
Future<void> deletePendingTransaction(String id, String userId) async {
  await _client
      .from('pending_transactions')
      .delete()
      .eq('id', id)
      .eq('user_id', userId);  // ✅ 명시적 필터 추가
}
```

**Provider 수정 필요**:
```dart
// pending_transaction_provider.dart L243-251
Future<void> deleteTransaction(String id) async {
  if (_userId == null) return;  // ✅ NULL 체크 추가

  try {
    await _repository.deletePendingTransaction(id, _userId);  // ✅ userId 전달
    await loadPendingTransactions();
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

**영향도**: 
- **현재 보안**: RLS가 방어하므로 실제 데이터 누출은 없음
- **코드 품질**: Defense in Depth 전략 위배, 일관성 문제

---

### Medium 2: `updateStatus`, `updateParsedData` 메서드 사용자 검증 부재

**파일**: `pending_transaction_repository.dart`  
**라인**: 93-146

**문제**:
```dart
Future<PendingTransactionModel> updateStatus({
  required String id,
  required PendingTransactionStatus status,
  String? transactionId,
}) async {
  final updates = PendingTransactionModel.toUpdateStatusJson(
    status: status,
    transactionId: transactionId,
  );

  final response = await _client
      .from('pending_transactions')
      .update(updates)
      .eq('id', id)  // ❌ userId 필터 없음
      .select()
      .single();

  return PendingTransactionModel.fromJson(response);
}

Future<PendingTransactionModel> updateParsedData({
  required String id,
  // ... 파라미터 생략
}) async {
  final updates = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };
  // ... 업데이트 로직 생략

  final response = await _client
      .from('pending_transactions')
      .update(updates)
      .eq('id', id)  // ❌ userId 필터 없음
      .select()
      .single();

  return PendingTransactionModel.fromJson(response);
}
```

**위험**:
- **RLS 의존**: 038 마이그레이션의 UPDATE 정책이 방어하므로 실제 보안 위험은 없음
- **일관성 문제**: 다른 메서드는 명시적으로 userId 필터를 적용

**해결**:
```dart
// updateStatus 수정 후
Future<PendingTransactionModel> updateStatus({
  required String id,
  required String userId,  // ✅ 추가
  required PendingTransactionStatus status,
  String? transactionId,
}) async {
  final updates = PendingTransactionModel.toUpdateStatusJson(
    status: status,
    transactionId: transactionId,
  );

  final response = await _client
      .from('pending_transactions')
      .update(updates)
      .eq('id', id)
      .eq('user_id', userId)  // ✅ 추가
      .select()
      .single();

  return PendingTransactionModel.fromJson(response);
}

// updateParsedData 수정 후
Future<PendingTransactionModel> updateParsedData({
  required String id,
  required String userId,  // ✅ 추가
  // ... 기타 파라미터
}) async {
  final updates = <String, dynamic>{
    'updated_at': DateTime.now().toIso8601String(),
  };
  // ... 업데이트 로직

  final response = await _client
      .from('pending_transactions')
      .update(updates)
      .eq('id', id)
      .eq('user_id', userId)  // ✅ 추가
      .select()
      .single();

  return PendingTransactionModel.fromJson(response);
}
```

**Provider 수정 필요**:
```dart
// confirmTransaction, rejectTransaction, updateParsedData 메서드 모두 수정
await _repository.updateStatus(
  id: id,
  userId: _userId!,  // ✅ 전달
  status: PendingTransactionStatus.rejected,
);
```

**영향도**: 
- **현재 보안**: RLS가 방어하므로 실제 데이터 누출은 없음
- **코드 품질**: 일관성 저해

---

## 🔵 Low Priority Issues

### Low 1: `is_viewed` 필드 마이그레이션 파일 미발견

**파일**: `supabase/migrations/034_add_auto_save_features.sql`  
**라인**: 65-102

**문제**:
- `pending_transactions` 테이블에 `is_viewed` 컬럼이 정의되어 있지 않음
- 하지만 코드에서는 사용 중:
  - Repository: `getPendingCount` (L42), `markAllAsViewed` (L285)
  - Provider: `markAllAsViewed` (L269-277)

**추정**:
- 다른 마이그레이션 파일에서 `is_viewed` 컬럼을 추가했을 가능성
- 또는 테스트/개발 중 직접 추가했을 가능성

**권장**:
- `is_viewed` 컬럼을 추가하는 마이그레이션이 있는지 확인
- 없다면 별도 마이그레이션 파일 생성 권장:

```sql
-- 039_add_is_viewed_to_pending_transactions.sql
ALTER TABLE house.pending_transactions 
ADD COLUMN IF NOT EXISTS is_viewed BOOLEAN DEFAULT FALSE;

COMMENT ON COLUMN house.pending_transactions.is_viewed 
IS '사용자가 확인한 거래인지 여부 (배지 카운트용)';
```

**영향도**: 
- **현재 상태**: 컬럼이 실제로 존재한다면 문제없음
- **문서화**: 마이그레이션 히스토리 추적 어려움

---

## ✅ Positive Points

### 1. 완벽한 RLS 정책 설계
- **SELECT**: `user_id = auth.uid()`로 본인 거래만 조회
- **UPDATE**: USING + WITH CHECK 이중 방어
- **DELETE**: `user_id = auth.uid()`로 본인 거래만 삭제
- **034 정책 덮어쓰기**: 더 엄격한 정책으로 완전 대체

### 2. Defense in Depth 전략
- **RLS 레벨**: DB에서 1차 방어
- **Repository 레벨**: 애플리케이션에서 2차 방어
- 대부분의 메서드가 명시적으로 `userId` 필터 적용

### 3. NULL 안전성
```dart
// Provider
if (_ledgerId == null || _userId == null) {
  state = const AsyncValue.data([]);
  return;
}

// Repository
if (userId != null) {
  query = query.eq('user_id', userId);
}
```

### 4. 일관된 에러 처리
모든 Provider 메서드에서 `catch (e, st) { state = AsyncValue.error(e, st); rethrow; }` 패턴 사용

### 5. 트랜잭션 일괄 처리 최적화
- `confirmAll`, `rejectAll`, `deleteAllByStatus`: 단일 쿼리로 일괄 처리
- N+1 쿼리 문제 없음

### 6. Realtime 활용
- DB 변경 시 자동 새로고침
- 카운트 provider 무효화로 배지 업데이트

### 7. 프로젝트 컨벤션 준수
- ✅ 작은따옴표 사용
- ✅ 에러 rethrow
- ✅ NULL 체크 패턴 일관성
- ✅ 한글 주석

---

## 🎯 Overall Assessment

### 보안 등급: **B+ (Good with Critical Fixes Needed)**

**강점**:
- RLS 정책이 완벽하게 설계되어 **실제 데이터 누출 위험은 매우 낮음**
- 대부분의 Repository 메서드가 명시적으로 userId 필터 적용
- Provider 레벨에서 NULL 체크 및 에러 처리 완벽

**약점**:
- **Realtime Subscription**: userId 필터 누락으로 메타데이터 유출 가능 (Critical 2)
- **일관성 문제**: 일부 메서드만 RLS에 의존 (getPendingCount, updateStatus 등)

### 수정 우선순위

| 순위 | 이슈 | 보안 영향 | 코드 품질 영향 | 수정 난이도 |
|------|------|----------|---------------|------------|
| 1 | **Critical 2**: Realtime userId 필터 | 🔴 High | 🟡 Medium | 🟢 Easy |
| 2 | **Critical 1**: getPendingCount userId 필터 | 🟡 Low (RLS 방어) | 🔴 High | 🟢 Easy |
| 3 | **Medium 1**: deletePendingTransaction 일관성 | 🟢 None (RLS 방어) | 🟡 Medium | 🟢 Easy |
| 4 | **Medium 2**: updateStatus/updateParsedData 일관성 | 🟢 None (RLS 방어) | 🟡 Medium | 🟢 Easy |
| 5 | **Low 1**: is_viewed 마이그레이션 문서화 | 🟢 None | 🟢 Low | 🟢 Easy |

### 최종 권장사항

#### 즉시 수정 (Critical):
1. ✅ **Realtime Subscription userId 필터 추가** (Critical 2)
   - 보안: 메타데이터 유출 방지
   - 성능: 불필요한 화면 새로고침 방지

#### 단기 개선 (1-2일):
2. ✅ **getPendingCount userId 파라미터 추가** (Critical 1)
   - Defense in Depth 전략 강화
   - 코드 일관성 확보

3. ✅ **deletePendingTransaction userId 파라미터 추가** (Medium 1)
   - 일관성 확보

#### 중기 개선 (1주):
4. ✅ **updateStatus, updateParsedData userId 파라미터 추가** (Medium 2)
   - 전체 코드베이스 일관성 확보

5. ✅ **is_viewed 컬럼 마이그레이션 파일 확인/생성** (Low 1)
   - 문서화 완성도 향상

### 전체 평가

**현재 구현은 RLS 정책이 완벽하게 설계되어 실제 데이터 누출 위험은 매우 낮습니다.**

하지만 **Realtime Subscription userId 필터 누락**은 즉시 수정이 필요하며, 나머지 이슈들은 "Defense in Depth" 전략과 코드 일관성을 위해 개선하는 것을 권장합니다.

수정 후 **A+ (Excellent)** 등급 달성 가능합니다. 🎉
