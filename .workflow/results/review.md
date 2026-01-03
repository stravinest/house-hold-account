# 코드 리뷰 결과

## 요약
- 검토 파일: 6개
- Critical: 2개 / High: 4개 / Medium: 5개 / Low: 2개

---

## Critical 이슈

### [share_repository.dart:28-32] RLS 정책 우회 가능성 - ledger 조회 시 권한 검증 누락
- **문제**: `isAlreadyMember()` 메서드에서 `ledgers` 테이블을 조회할 때 권한 검증 없이 `owner_id`를 가져옴. 현재 RLS 정책상 `ledger_members`에 등록되지 않은 사용자는 가계부 정보에 접근 불가하므로 에러 발생 가능.
- **위험**: 가계부 소유자가 아닌 관리자가 초대를 시도할 때, 해당 가계부의 `owner_id` 조회 실패로 인해 초대 기능이 동작하지 않을 수 있음.
- **해결**: RLS가 적용된 상태에서 안전하게 조회되도록 하거나, 데이터베이스 함수(RPC)를 통해 권한 검증을 수행해야 함.
```dart
// 현재 코드 - RLS로 인해 접근 제한될 수 있음
final ledger = await _client
    .from('ledgers')
    .select('owner_id')
    .eq('id', ledgerId)
    .single();

// 권장: ledger_members를 통해 소유자 확인
final ownerMember = await _client
    .from('ledger_members')
    .select('user_id')
    .eq('ledger_id', ledgerId)
    .eq('role', 'owner')
    .maybeSingle();
```

### [ledger_repository.dart:90-97] 기본 카테고리 중복 생성 문제
- **문제**: `createLedger()` 실행 시 `_createDefaultCategories()`가 호출되는데, 데이터베이스에 이미 `on_ledger_created_categories` 트리거가 존재하여 기본 카테고리가 2번 생성됨.
- **위험**: 동일한 카테고리가 중복 생성되어 데이터 일관성 훼손 및 사용자 혼란 초래.
- **해결**: 앱 코드의 `_createDefaultCategories()` 호출을 제거하거나, 데이터베이스 트리거를 비활성화해야 함. 둘 중 하나만 사용 권장.
```dart
// 권장: 앱 코드에서 기본 카테고리 생성 제거 (DB 트리거가 처리)
Future<LedgerModel> createLedger({...}) async {
    // ...
    final response = await _client
        .from('ledgers')
        .insert(data)
        .select()
        .single();

    return LedgerModel.fromJson(response);
    // _createDefaultCategories() 호출 제거
}
```

---

## High 이슈

### [share_repository.dart:147-168] 초대 수락 시 트랜잭션 미사용
- **문제**: `acceptInvite()` 메서드에서 3개의 DB 작업(초대 상태 업데이트, 멤버 추가, 가계부 공유 상태 변경)이 개별적으로 실행됨.
- **위험**: 중간 작업 실패 시 데이터 불일치 발생. 예: 멤버 추가 실패 시 초대는 수락됐지만 실제 멤버가 되지 않는 상황.
- **해결**: Supabase RPC 함수를 사용하여 트랜잭션으로 처리하거나, 최소한 실패 시 롤백 로직 구현 필요.
```dart
// 현재: 개별 쿼리 실행
await _client.from('ledger_invites').update({...}).eq('id', inviteId);
await _client.from('ledger_members').insert({...});
await _client.from('ledgers').update({...}).eq('id', invite['ledger_id']);

// 권장: RPC 함수 사용
// SQL: CREATE FUNCTION accept_invite(invite_id UUID) RETURNS void
await _client.rpc('accept_invite', params: {'invite_id': inviteId});
```

### [ledger_repository.dart:12, 20-22] 프로덕션 코드에 디버그 print 문 잔존
- **문제**: `getLedgers()` 메서드에 디버그용 `print()` 문이 4개 포함되어 있음.
- **위험**: 프로덕션 환경에서 로그 노출로 인한 정보 유출 및 성능 저하.
- **해결**: 모든 print 문을 제거하거나 `kDebugMode` 조건으로 감싸기.
```dart
// 제거 대상:
print('[LedgerRepository] getLedgers 호출, userId: $userId');
print('[LedgerRepository] getLedgers 응답: $response');
print('[LedgerRepository] getLedgers 응답 타입: ${response.runtimeType}');
print('[LedgerRepository] getLedgers 응답 길이: ${(response as List).length}');

// 권장: 제거하거나 다음과 같이 변경
import 'package:flutter/foundation.dart';
if (kDebugMode) {
  print('[LedgerRepository] getLedgers 호출');
}
```

### [ledger_provider.dart:16-21, 47-59] Provider에서 print 문 잔존
- **문제**: `ledgersProvider`와 `LedgerNotifier`에 디버그용 print 문이 다수 존재.
- **위험**: 위와 동일.
- **해결**: 모든 print 문 제거.

### [share_repository.dart:217-239] 멤버 제거 시 경합 조건(Race Condition) 가능성
- **문제**: 멤버 삭제 후 남은 멤버 수를 확인하여 공유 상태를 변경하는데, 동시 요청 시 경합 발생 가능.
- **위험**: 동시에 여러 멤버가 탈퇴할 경우 `is_shared` 플래그가 정확하게 업데이트되지 않을 수 있음.
- **해결**: 트랜잭션 또는 데이터베이스 트리거로 원자적 처리 권장.

---

## Medium 이슈

### [001_initial_schema.sql:127-134] 가계부 조회 RLS 정책에 소유자 조건 누락
- **문제**: `ledgers` SELECT 정책이 `ledger_members` 테이블만 확인하는데, 소유자(`owner_id`)는 트리거로 자동 등록되므로 문제없으나, 트리거 실패 시 소유자도 조회 불가.
- **위험**: 트리거 실패 시 가계부 생성자가 자신의 가계부를 볼 수 없는 상황 발생.
- **해결**: 소유자 조건을 명시적으로 추가 권장.
```sql
CREATE POLICY "사용자는 자신이 멤버인 가계부를 조회할 수 있음"
    ON ledgers FOR SELECT
    USING (
        owner_id = auth.uid()  -- 소유자 직접 조회 허용
        OR id IN (
            SELECT ledger_id FROM ledger_members WHERE user_id = auth.uid()
        )
    );
```

### [share_management_page.dart:109-113] 문자열 substring 오류 가능성
- **문제**: `displayName` 또는 `email`이 빈 문자열('')일 경우 `substring(0, 1)` 호출 시 `RangeError` 발생.
- **위험**: 앱 크래시.
- **해결**: 빈 문자열 체크 추가.
```dart
// 현재 코드
child: Text(
    (member.displayName ?? member.email ?? 'U')
        .substring(0, 1)
        .toUpperCase(),
),

// 권장 수정
child: Text(
    ((member.displayName ?? member.email)?.isNotEmpty == true
        ? (member.displayName ?? member.email)!
        : 'U')
        .substring(0, 1)
        .toUpperCase(),
),
```

### [share_management_page.dart:184-208] 권한 검증 없이 멤버 관리 UI 노출
- **문제**: 모든 멤버에게 다른 멤버의 역할 변경/내보내기 메뉴가 표시됨. 실제 작업은 RLS에서 막히겠지만 UX상 혼란.
- **위험**: 일반 멤버가 관리 기능을 시도한 후 에러 메시지를 받게 됨.
- **해결**: 현재 사용자의 역할(owner/admin)을 확인하여 UI 표시 여부 결정.
```dart
// _buildTrailingWidget에서 현재 사용자 역할 확인 필요
final currentUserRole = members.firstWhere(
  (m) => m.userId == currentUserId,
  orElse: () => null,
)?.role;

// owner나 admin인 경우에만 관리 메뉴 표시
if (currentUserRole == 'owner' || currentUserRole == 'admin') {
  return PopupMenuButton(...);
}
return null;
```

### [share_repository.dart:116-130] getReceivedInvites에서 이메일 null 체크
- **문제**: `user.email ?? ''`로 빈 문자열 전달 시 의도치 않은 결과 반환 가능.
- **위험**: 이메일이 없는 사용자(소셜 로그인 등)의 경우 초대를 받을 수 없음.
- **해결**: 이메일 없는 경우 명시적 예외 처리 또는 사용자 알림.

### [share_management_page.dart:617] DropdownButtonFormField의 initialValue 속성
- **문제**: `DropdownButtonFormField`에 `initialValue` 속성이 없음. `value` 속성을 사용해야 함.
- **위험**: 컴파일 에러 또는 런타임 에러 발생 가능.
- **해결**: `value` 속성으로 변경.
```dart
// 현재 (오류)
DropdownButtonFormField<String>(
  initialValue: _selectedRole,

// 수정
DropdownButtonFormField<String>(
  value: _selectedRole,
```

---

## Low 이슈

### [ledger_repository.dart:42-57] 기본 카테고리 상수 위치
- **문제**: `_defaultCategories`가 Repository 클래스 내부에 정의되어 있어 재사용성 저하.
- **개선**: 별도의 상수 파일(`constants/default_categories.dart`)로 분리 권장.

### [share_management_page.dart] 문자열 리터럴에 큰따옴표 사용
- **문제**: 프로젝트 컨벤션(작은따옴표 사용)과 불일치하는 부분 존재.
- **개선**: 모든 문자열을 작은따옴표로 통일.

---

## 긍정적인 점

1. **검증 로직 우수**: `createInvite()` 메서드에서 자기 초대, 가입 여부, 멤버 여부, 중복 초대를 모두 체크하는 포괄적인 검증 로직이 잘 구현됨.

2. **에러 처리 패턴 준수**: `ShareNotifier`에서 모든 비동기 메서드가 에러를 `rethrow`하여 UI까지 전파하는 CLAUDE.md의 에러 처리 원칙을 잘 따름.

3. **RLS 정책 설계**: 역할별(owner/admin/member) 권한이 명확하게 분리되어 있으며, 대부분의 테이블에 적절한 보안 정책이 적용됨.

4. **UI/UX 개선**: 역할별 권한 설명 추가, 역할 뱃지 표시, 가계부 나가기 기능 등 사용자 경험 향상에 신경 씀.

5. **이메일 정규화**: 모든 이메일을 `toLowerCase().trim()`으로 정규화하여 대소문자/공백으로 인한 불일치 방지.

---

## 추가 권장사항

### 테스트
- [ ] `createInvite()` 검증 로직 단위 테스트 작성
- [ ] RLS 정책 통합 테스트 작성 (각 역할별 접근 권한 검증)
- [ ] 초대 수락 시나리오 E2E 테스트 작성

### 리팩토링
- [ ] 데이터베이스 트리거(`on_ledger_created_categories`)와 앱 코드(`_createDefaultCategories`) 중 하나 제거하여 중복 방지
- [ ] 트랜잭션이 필요한 작업들을 Supabase RPC 함수로 마이그레이션
- [ ] 공통 검증 로직을 별도 Validator 클래스로 추출

### 보안
- [ ] 권한 검증 로직을 클라이언트뿐만 아니라 서버(RPC 함수)에서도 수행하도록 개선
- [ ] 초대 만료 시간 검증을 서버에서도 수행 (현재는 클라이언트에서만 `gt('expires_at', ...)` 체크)

---

## 리뷰어 정보
- 리뷰 일시: 2026-01-03
- 리뷰어: Senior Code Reviewer (Claude)
