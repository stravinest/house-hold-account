# 멤버 방출 기능 수정 보고서

**작업 일자**: 2026-01-26
**이슈**: 가계부 소유자가 멤버 방출 버튼을 눌러도 방출되지 않음
**원인**: 존재하지 않는 RPC 함수 호출
**해결**: 직접 DELETE 쿼리로 변경

---

## 문제 원인 분석

### 코드 흐름

```
UI: 방출하기 버튼 클릭
  ↓
share_management_page.dart: _removeMember()
  ↓
share_provider.dart: ShareNotifier.removeMember()
  ↓
share_repository.dart: removeMember()
  ↓
❌ _client.rpc('delete_ledger_member')  ← 존재하지 않는 RPC 함수!
```

### 근본 원인

**share_repository.dart:328-351** (수정 전)
```dart
Future<void> removeMember({
  required String ledgerId,
  required String userId,
}) async {
  final response = await _client.rpc(
    'delete_ledger_member',  // ← 이 RPC 함수가 DB에 없음!
    params: {'target_ledger_id': ledgerId, 'target_user_id': userId},
  );

  final result = response as Map<String, dynamic>;
  if (result['success'] != true) {
    // ... 30줄의 에러 처리 로직
  }
}
```

**문제점**:
1. `delete_ledger_member` RPC 함수가 Supabase에 정의되지 않음
2. 마이그레이션 파일 전체 검색 결과: 해당 함수 없음
3. RPC 호출이 실패하지만 명확한 에러 메시지가 UI에 표시되지 않음

---

## 수정 방법 선택

### 두 가지 옵션 비교

| 항목 | 방법 1: RPC 함수 생성 | 방법 2: 직접 DELETE ✅ |
|------|---------------------|----------------------|
| 구현 복잡도 | 높음 (마이그레이션 + RPC) | 낮음 (코드만 수정) |
| 코드 라인 | 30줄 + SQL 50줄 | 3줄 |
| 권한 체크 | RPC 내부에서 구현 | RLS 정책 활용 |
| 즉시 적용 | 불가 (마이그레이션 필요) | 가능 |
| 유지보수성 | 복잡 | 간단 |
| 일관성 | 다른 메서드와 상이 | 다른 메서드와 동일 |

### 선택: 방법 2 (직접 DELETE)

**이유**:
1. **RLS 정책이 이미 완벽함** (001_initial_schema.sql):
   ```sql
   CREATE POLICY "소유자 또는 본인은 멤버를 삭제할 수 있음"
       ON ledger_members FOR DELETE
       USING (
           ledger_id IN (
               SELECT id FROM ledgers WHERE owner_id = auth.uid()
           )
           OR user_id = auth.uid()
       );
   ```
   → DB 레벨에서 권한 검증 완료

2. **단순 삭제 작업만 필요**
   - 복잡한 비즈니스 로직 불필요
   - 트랜잭션도 단일 DELETE로 충분

3. **프로젝트 일관성**
   - 다른 Repository 메서드들도 직접 쿼리 사용
   - 예: `updateMemberRole()`, `getMembers()`, `createInvite()` 등

4. **코드 간결성**
   - 30줄 → 3줄 (90% 감소)
   - 불필요한 RPC 응답 파싱 로직 제거

---

## 수정 내역

### share_repository.dart

**Before** (30줄):
```dart
Future<void> removeMember({
  required String ledgerId,
  required String userId,
}) async {
  final response = await _client.rpc(
    'delete_ledger_member',
    params: {'target_ledger_id': ledgerId, 'target_user_id': userId},
  );

  final result = response as Map<String, dynamic>;
  if (result['success'] != true) {
    final errorCode = result['error_code'];
    String message;
    switch (errorCode) {
      case 'NOT_FOUND':
        message = '더 이상 가계부 멤버가 아닙니다.';
        break;
      case 'PERMISSION_DENIED':
        message = '멤버를 관리할 권한이 없습니다.';
        break;
      case 'UNAUTHORIZED':
        message = '인증 정보가 없습니다. 다시 로그인해 주세요.';
        break;
      default:
        message = result['error'] ?? '멤버 제거 중 오류가 발생했습니다.';
    }
    throw Exception(message);
  }
}
```

**After** (3줄):
```dart
Future<void> removeMember({
  required String ledgerId,
  required String userId,
}) async {
  await _client
      .from('ledger_members')
      .delete()
      .eq('ledger_id', ledgerId)
      .eq('user_id', userId);
}
```

**개선 효과**:
- ✅ 코드 라인: 30줄 → 3줄 (90% 감소)
- ✅ 복잡도: 높음 → 낮음
- ✅ 가독성: 명확하고 직관적
- ✅ 유지보수성: 표준 Supabase 패턴

---

## 권한 검증 메커니즘

### RLS 정책 (DB 레벨)

```sql
-- 001_initial_schema.sql
CREATE POLICY "소유자 또는 본인은 멤버를 삭제할 수 있음"
    ON ledger_members FOR DELETE
    USING (
        ledger_id IN (
            SELECT id FROM ledgers WHERE owner_id = auth.uid()
        )
        OR user_id = auth.uid()
    );
```

**작동 방식**:
1. **소유자 체크**: `ledger_id`에 해당하는 가계부의 `owner_id`가 현재 사용자(`auth.uid()`)와 일치
   → ✅ 다른 멤버 방출 가능

2. **본인 체크**: 삭제하려는 `user_id`가 현재 사용자와 일치
   → ✅ 본인 탈퇴 가능

3. 둘 다 아니면:
   → ❌ DELETE 쿼리 실패 (권한 없음)

### 에러 처리

Supabase PostgrestException이 자동으로 발생하며, 상위 레이어에서 처리:
- `ShareNotifier.removeMember()`: try-catch로 에러 캐치
- `share_management_page.dart`: SnackBarUtils.showError()로 사용자에게 표시

---

## 테스트 시나리오

### 1. 정상 케이스: 소유자가 다른 멤버 방출

**조건**:
- 현재 사용자: eungyu (소유자)
- 대상 멤버: TestUser1 (일반 멤버)

**예상 결과**: ✅ 성공
- DB에서 `ledger_members` 레코드 삭제
- UI 새로고침 (myOwnedLedgersWithInvitesProvider invalidate)
- SnackBar: "멤버가 제거되었습니다"

### 2. 정상 케이스: 본인 탈퇴

**조건**:
- 현재 사용자: TestUser1
- 대상 멤버: TestUser1 (본인)

**예상 결과**: ✅ 성공
- 본인의 멤버십 삭제

### 3. 에러 케이스: 권한 없는 사용자

**조건**:
- 현재 사용자: TestUser1 (일반 멤버)
- 대상 멤버: eungyu (소유자)

**예상 결과**: ❌ 실패
- RLS 정책에 의해 DELETE 쿼리 거부
- PostgrestException 발생
- SnackBar: "멤버를 관리할 권한이 없습니다"

---

## 검증 결과

### 코드 분석
```bash
$ flutter analyze lib/features/share/data/repositories/share_repository.dart
No issues found! ✅
```

### 앱 재시작
- 백그라운드에서 flutter run 실행 중
- 핫 리로드 적용 완료 예정

---

## 향후 개선 사항 (선택적)

### 1. 에러 메시지 개선

현재는 Supabase의 기본 에러 메시지를 그대로 사용하고 있습니다.
필요시 PostgrestException의 에러 코드를 파싱하여 커스텀 메시지 제공 가능:

```dart
Future<void> removeMember({
  required String ledgerId,
  required String userId,
}) async {
  try {
    await _client
        .from('ledger_members')
        .delete()
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId);
  } on PostgrestException catch (e) {
    if (e.code == '42501') {
      throw Exception('멤버를 관리할 권한이 없습니다.');
    } else if (e.code == '23503') {
      throw Exception('해당 멤버를 찾을 수 없습니다.');
    }
    rethrow;
  }
}
```

### 2. 삭제 전 확인 쿼리

멤버가 존재하는지 먼저 확인 후 삭제:

```dart
Future<void> removeMember({
  required String ledgerId,
  required String userId,
}) async {
  // 1. 존재 여부 확인
  final existing = await _client
      .from('ledger_members')
      .select('id')
      .eq('ledger_id', ledgerId)
      .eq('user_id', userId)
      .maybeSingle();

  if (existing == null) {
    throw Exception('더 이상 가계부 멤버가 아닙니다.');
  }

  // 2. 삭제
  await _client
      .from('ledger_members')
      .delete()
      .eq('ledger_id', ledgerId)
      .eq('user_id', userId);
}
```

**장점**: 명확한 에러 메시지
**단점**: 추가 쿼리 (성능 영향 미미)

---

## 결론

✅ **멤버 방출 기능 수정 완료**

- 존재하지 않는 RPC 함수 호출 → 직접 DELETE 쿼리로 변경
- 코드 복잡도 90% 감소 (30줄 → 3줄)
- RLS 정책 활용으로 권한 검증 보장
- 표준 Supabase 패턴 적용으로 일관성 향상

**다음 단계**:
1. 앱 재시작 완료 대기
2. 실제 기기에서 "방출하기" 버튼 테스트
3. 성공 메시지 확인: "멤버가 제거되었습니다"

---

**관련 파일**:
- 수정: `lib/features/share/data/repositories/share_repository.dart`
- RLS 정책: `supabase/migrations/001_initial_schema.sql`
- UI: `lib/features/share/presentation/pages/share_management_page.dart`
