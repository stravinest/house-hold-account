# Plan: 가계부 자동 선택 및 복원 기능 개선

## 1. 문제 정의

### 현재 상황
- 로그인 시 사용자의 가계부가 선택되지 않은 상태가 발생할 수 있음
- 마지막에 선택했던 가계부가 로그인 후 복원되지 않는 경우가 있음
- 공유 가계부에서 나가거나 삭제된 경우, 폴백 처리가 불완전함

### 문제점
1. **초기 선택 실패**: 로그인 직후 `selectedLedgerIdProvider`가 null인 상태로 UI가 렌더링됨
2. **복원 로직 불완전**: SharedPreferences에 저장된 가계부 ID가 있어도 복원이 실패하는 경우 존재
3. **폴백 로직 부재**: 저장된 가계부가 유효하지 않을 때(삭제/탈퇴) 기본 가계부로 자동 전환이 되지 않음
4. **타이밍 문제**: `ledgersProvider`와 `LedgerNotifier.loadLedgers()`가 모두 복원 로직을 가지고 있어 중복 실행되거나 경쟁 상태 발생 가능

### 기대 동작
1. **로그인 시**: 마지막에 선택했던 가계부를 자동으로 복원
2. **복원 실패 시**: 사용 가능한 첫 번째 가계부를 자동 선택
3. **가계부 삭제/탈퇴 시**: 남은 가계부 중 하나를 자동 선택 (내 가계부 우선)
4. **로그아웃 시**: 저장된 가계부 ID 삭제 (다른 사용자 RLS 위반 방지)
5. **일관된 상태**: 항상 하나의 가계부가 선택된 상태 유지

## 2. 현재 구현 분석

### 관련 파일
- `lib/features/ledger/presentation/providers/ledger_provider.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`

### 현재 복원 로직 흐름

```
로그인
  ↓
AuthService.signInWithEmail/signInWithGoogle
  ↓
AuthNotifier.signInWithEmail/signInWithGoogle
  ↓
ledgersProvider 호출 (로그인 감지)
  ↓ (45-63줄)
selectedLedgerIdProvider == null ?
  ↓ YES
restoreLedgerIdProvider 호출 (SharedPreferences 읽기)
  ↓
저장된 ID 유효성 검증
  ↓
유효하면 복원 / 아니면 첫 번째 가계부 선택
```

### LedgerNotifier.loadLedgers() 중복 로직
- `LedgerNotifier` 생성자에서 `loadLedgers()` 자동 호출 (102줄)
- `loadLedgers()` 내에서도 동일한 복원 로직 실행 (151-169줄)
- `ledgersProvider`와 중복 실행 가능성

### 로그아웃 처리
- `AuthService.signOut()`: SharedPreferences에서 가계부 ID 삭제 (256-263줄)
- `AuthNotifier.signOut()`: `selectedLedgerIdProvider` null로 초기화 (419-422줄)

### 삭제/탈퇴 처리
- `LedgerNotifier.deleteLedger()`: 삭제 시 폴백 처리 있음 (219-242줄)
- 하지만 멤버 탈퇴 시 폴백 처리는 명시적으로 없음

## 3. 개선 방안

### 3.1 단일 진입점 원칙

**문제**: 현재 복원 로직이 여러 곳에 분산되어 있음
- `ledgersProvider` (45-63줄)
- `LedgerNotifier.loadLedgers()` (151-169줄)

**해결책**: 복원 로직을 `LedgerNotifier`로 일원화

```
로그인
  ↓
LedgerNotifier.loadLedgers() 호출
  ↓
getLedgers() → 가계부 목록 조회
  ↓
_restoreOrSelectLedger() → 복원 로직 실행
  ↓
저장된 ID 복원 성공?
  YES → 해당 가계부 선택
  NO  → 첫 번째 가계부 선택 (내 가계부 우선)
```

### 3.2 복원 로직 개선

**기존**: 단순 첫 번째 가계부 선택
```dart
ref.read(selectedLedgerIdProvider.notifier).state = ledgers.first.id;
```

**개선**: 내 가계부 우선 선택
```dart
// 1. 내 가계부(owner) 찾기
final myLedger = ledgers.firstWhere(
  (ledger) => ledger.ownerId == userId,
  orElse: () => ledgers.first,
);
// 2. 선택
ref.read(selectedLedgerIdProvider.notifier).state = myLedger.id;
```

### 3.3 실시간 유효성 검증

**문제**: 선택된 가계부가 삭제되거나 멤버에서 제외될 수 있음

**해결책**: `currentLedgerProvider`에서 유효성 검증 추가
```dart
final currentLedgerProvider = FutureProvider<Ledger?>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return null;

  final ledgersAsync = ref.watch(ledgerNotifierProvider);
  final ledgers = ledgersAsync.valueOrNull ?? [];

  // 선택된 가계부가 목록에 없으면 자동 복원
  if (!ledgers.any((ledger) => ledger.id == ledgerId)) {
    ref.read(ledgerNotifierProvider.notifier).restoreOrSelectLedger();
    return null;
  }

  try {
    return ledgers.firstWhere((ledger) => ledger.id == ledgerId);
  } catch (_) {
    final repository = ref.read(ledgerRepositoryProvider);
    return repository.getLedger(ledgerId);
  }
});
```

### 3.4 멤버 탈퇴 처리

**현재**: 명시적인 처리 없음 (Realtime 구독에만 의존)

**개선**: `subscribeLedgerMembers` 콜백에서 유효성 검증
```dart
_membersChannel = _repository.subscribeLedgerMembers(() async {
  await _refreshLedgersQuietly();

  // 현재 선택된 가계부가 목록에 없으면 자동 복원
  final selectedId = ref.read(selectedLedgerIdProvider);
  final ledgers = state.valueOrNull ?? [];
  if (selectedId != null && !ledgers.any((l) => l.id == selectedId)) {
    await restoreOrSelectLedger();
  }
});
```

### 3.5 안전한 상태 초기화

**문제**: 로그아웃 후 다른 사용자 로그인 시 이전 사용자의 가계부 ID가 남아 있을 수 있음

**현재 처리**:
- `AuthService.signOut()`: SharedPreferences 삭제 (258줄)
- `AuthNotifier.signOut()`: Provider 상태 초기화 (420줄)

**개선**: 로그인 시 추가 검증
```dart
Future<void> signInWithEmail(...) async {
  // ... 기존 로그인 로직 ...

  // 로그인 성공 후 가계부 초기화
  _ref.read(selectedLedgerIdProvider.notifier).state = null;
  _ref.invalidate(ledgerNotifierProvider); // 강제 재로딩
}
```

## 4. 구현 계획

### 4.1 Phase 1: 복원 로직 일원화

**목표**: 복원 로직을 `LedgerNotifier`로 통합

**작업**:
1. `LedgerNotifier`에 `restoreOrSelectLedger()` 메서드 추가
2. `ledgersProvider`에서 복원 로직 제거 (단순 조회만)
3. `loadLedgers()` 내에서 `restoreOrSelectLedger()` 호출

**파일**:
- `lib/features/ledger/presentation/providers/ledger_provider.dart`

### 4.2 Phase 2: 내 가계부 우선 선택

**목표**: 저장된 가계부가 없을 때 내 가계부를 우선 선택

**작업**:
1. `Ledger` 엔티티에서 `ownerId` 확인
2. 내 가계부 찾기 로직 추가
3. 없으면 첫 번째 가계부 폴백

**파일**:
- `lib/features/ledger/presentation/providers/ledger_provider.dart`

### 4.3 Phase 3: 실시간 유효성 검증

**목표**: 선택된 가계부가 삭제/탈퇴되었을 때 자동 복원

**작업**:
1. `currentLedgerProvider`에 유효성 검증 추가
2. `subscribeLedgerMembers` 콜백에서 자동 복원 호출
3. 삭제/탈퇴 시 자동 폴백 처리

**파일**:
- `lib/features/ledger/presentation/providers/ledger_provider.dart`

### 4.4 Phase 4: 로그인 상태 초기화

**목표**: 로그인 시 이전 사용자의 상태가 남아있지 않도록 보장

**작업**:
1. `AuthNotifier.signInWithEmail/Google`에서 가계부 상태 초기화
2. `invalidate(ledgerNotifierProvider)` 호출하여 강제 재로딩

**파일**:
- `lib/features/auth/presentation/providers/auth_provider.dart`

### 4.5 Phase 5: 테스트 및 검증

**목표**: 모든 시나리오에서 정상 동작 확인

**테스트 시나리오**:
1. 로그인 → 마지막 선택 가계부 복원 확인
2. 로그인 → 저장된 가계부 없음 → 내 가계부 자동 선택
3. 로그인 → 저장된 가계부 삭제됨 → 내 가계부 자동 선택
4. 공유 가계부 탈퇴 → 내 가계부 자동 선택
5. 가계부 삭제 → 남은 가계부 자동 선택
6. 로그아웃 → 저장된 ID 삭제 확인
7. 다른 사용자 로그인 → 이전 사용자 상태 없음 확인

## 5. 예상 효과

### 5.1 사용자 경험 개선
- 로그인 시 항상 사용 중이던 가계부가 자동으로 열림
- 가계부 삭제/탈퇴 시에도 끊김 없이 다른 가계부로 전환
- 빈 화면이나 에러 화면이 표시되지 않음

### 5.2 안정성 향상
- 경쟁 상태(Race Condition) 제거
- 중복 로직 제거로 버그 발생 가능성 감소
- 명확한 상태 관리 흐름

### 5.3 유지보수성 향상
- 단일 진입점으로 코드 이해 용이
- 복원 로직이 한 곳에 집중되어 수정 용이

## 6. 리스크 및 고려사항

### 6.1 기술적 리스크
- **타이밍 이슈**: SharedPreferences 읽기가 비동기이므로 UI 렌더링 전에 완료되어야 함
  - **완화책**: FutureProvider와 AsyncValue 활용, 로딩 상태 표시
- **Realtime 구독 지연**: 멤버 변경 감지가 늦어질 수 있음
  - **완화책**: 수동 새로고침 버튼 제공

### 6.2 데이터 일관성
- **멀티 디바이스**: 여러 기기에서 동시 로그인 시 각각 다른 가계부 선택 가능
  - **현재 설계**: 문제 없음 (각 기기의 로컬 설정)
- **동시성**: 가계부 삭제와 선택이 동시에 발생할 수 있음
  - **완화책**: 유효성 검증 로직 강화

### 6.3 마이그레이션
- **기존 사용자**: SharedPreferences에 이미 저장된 값이 있을 수 있음
  - **영향 없음**: 유효성 검증으로 자동 처리

## 7. 성공 지표

1. **복원 성공률**: 로그인 시 저장된 가계부 복원 성공률 95% 이상
2. **폴백 성공률**: 복원 실패 시 내 가계부 자동 선택 성공률 100%
3. **에러 발생률**: 가계부 미선택 상태로 인한 에러 0건
4. **사용자 불편 신고**: 가계부 선택 관련 이슈 신고 0건

## 8. 문서 및 참고자료

### 관련 문서
- `CLAUDE.md`: 에러 처리 원칙, 비동기 작업 가이드
- `supabase/migrations/003_auto_create_default_ledger.sql`: 기본 가계부 자동 생성 트리거

### 참고 코드
- `lib/features/ledger/presentation/providers/ledger_provider.dart:19-28`: SharedPreferences 저장 로직
- `lib/features/ledger/presentation/providers/ledger_provider.dart:31-38`: 복원 Provider
- `lib/features/ledger/presentation/providers/ledger_provider.dart:41-66`: 가계부 목록 Provider
- `lib/features/auth/presentation/providers/auth_provider.dart:256-263`: 로그아웃 시 ID 삭제
- `lib/features/ledger/presentation/providers/ledger_provider.dart:219-242`: 삭제 시 폴백 처리
