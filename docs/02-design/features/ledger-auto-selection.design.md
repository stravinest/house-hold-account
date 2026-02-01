# Design: 가계부 자동 선택 및 복원 기능 개선

## 1. 개요

### 목적
- 로그인 시 마지막 선택 가계부 자동 복원
- 가계부 삭제/탈퇴 시 자동 폴백 처리
- 복원 로직 일원화로 경쟁 상태 제거

### 범위
- `lib/features/ledger/presentation/providers/ledger_provider.dart` 수정
- `lib/features/auth/presentation/providers/auth_provider.dart` 수정

### 참고 문서
- Plan: `docs/01-plan/features/ledger-auto-selection.plan.md`
- CLAUDE.md: 에러 처리 원칙, 비동기 작업 가이드

## 2. 아키텍처 설계

### 2.1 전체 흐름도

```
┌─────────────────────────────────────────────────────┐
│                  로그인 트리거                       │
│     (AuthNotifier.signInWithEmail/Google)           │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│          가계부 상태 초기화 (AuthNotifier)           │
│  - selectedLedgerIdProvider ← null                  │
│  - invalidate(ledgerNotifierProvider)               │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│      LedgerNotifier 생성 및 초기화                   │
│         loadLedgers() 자동 호출                      │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│           getLedgers() - DB 조회                    │
│      (ledger_members 조인으로 멤버 가계부만)         │
└──────────────────┬──────────────────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────────────────┐
│      restoreOrSelectLedger() - 복원 로직 실행        │
│                                                     │
│  1. selectedLedgerIdProvider == null?              │
│     NO → 종료 (이미 선택됨)                         │
│     YES ↓                                          │
│                                                     │
│  2. SharedPreferences에서 저장된 ID 읽기            │
│     (restoreLedgerIdProvider 사용)                 │
│     ↓                                              │
│                                                     │
│  3. 저장된 ID 유효성 검증                           │
│     - ledgers 목록에 존재하는가?                    │
│     YES → 해당 가계부 선택 후 종료                  │
│     NO ↓                                           │
│                                                     │
│  4. 내 가계부 찾기 (ownerId == userId)             │
│     - firstWhere(ownerId == userId)                │
│     발견 → 내 가계부 선택 후 종료                   │
│     없음 ↓                                         │
│                                                     │
│  5. 폴백: 첫 번째 가계부 선택                       │
│     - ledgers.first.id 선택                        │
│                                                     │
└─────────────────────────────────────────────────────┘
```

### 2.2 상태 다이어그램

```
                    ┌──────────────┐
                    │  로그아웃 상태 │
                    └──────┬───────┘
                           │ 로그인
                           ▼
                    ┌──────────────┐
                    │  초기화 중    │
                    │(state=null)  │
                    └──────┬───────┘
                           │
                  ┌────────┴────────┐
                  │                 │
        저장된 ID 있음        저장된 ID 없음
                  │                 │
                  ▼                 ▼
           ┌──────────┐      ┌──────────┐
           │유효성 검증│      │내 가계부 │
           │          │      │  찾기    │
           └────┬─────┘      └────┬─────┘
                │                 │
         ┌──────┴──────┐    ┌─────┴──────┐
      유효함     유효하지 않음  있음      없음
         │          │        │          │
         ▼          │        │          │
    ┌────────┐     │        │          │
    │복원 완료│◄────┴────────┴──────────┘
    │        │                (폴백: 첫 번째)
    └────────┘

    복원 완료 후:
    - selectedLedgerIdProvider 설정
    - SharedPreferences 자동 저장
    - UI 렌더링
```

### 2.3 실시간 유효성 검증 흐름

```
Realtime 이벤트 발생
  ↓
┌─────────────────────────────────────────┐
│ ledgers 테이블 변경 (INSERT/UPDATE/DELETE) │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│   subscribeLedgers 콜백                 │
│   - getLedgers() 재조회                 │
│   - state 업데이트                      │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ ledger_members 테이블 변경 (멤버 탈퇴 등) │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│   subscribeLedgerMembers 콜백            │
│   - _refreshLedgersQuietly() 호출       │
│   - _validateCurrentSelection() 호출    │
└──────────────────┬──────────────────────┘
                   ▼
┌─────────────────────────────────────────┐
│  _validateCurrentSelection()            │
│                                         │
│  1. selectedLedgerId 읽기               │
│  2. ledgers 목록에 존재하는지 확인       │
│     NO → restoreOrSelectLedger() 호출   │
│     YES → 아무것도 하지 않음             │
└─────────────────────────────────────────┘
```

## 3. 상세 설계

### 3.1 LedgerNotifier 클래스 수정

#### 3.1.1 새로운 메서드: `restoreOrSelectLedger()`

**목적**: 복원 로직의 단일 진입점

**시그니처**:
```dart
Future<void> restoreOrSelectLedger() async
```

**알고리즘**:
```dart
Future<void> restoreOrSelectLedger() async {
  // 1. 이미 선택된 경우 종료
  final selectedId = ref.read(selectedLedgerIdProvider);
  if (selectedId != null) {
    debugPrint('[LedgerNotifier] Ledger already selected: $selectedId');
    return;
  }

  // 2. 가계부 목록이 비어있으면 종료
  final ledgers = state.valueOrNull ?? [];
  if (ledgers.isEmpty) {
    debugPrint('[LedgerNotifier] No ledgers available');
    return;
  }

  // 3. 현재 사용자 ID 가져오기
  final userId = SupabaseConfig.client.auth.currentUser?.id;
  if (userId == null) {
    debugPrint('[LedgerNotifier] User not logged in');
    return;
  }

  // 4. SharedPreferences에서 저장된 ID 복원 시도
  try {
    final savedId = await ref.read(restoreLedgerIdProvider.future);

    // 4-1. 저장된 ID가 유효한지 검증
    if (savedId != null) {
      final isValid = ledgers.any((ledger) => ledger.id == savedId);
      if (isValid) {
        ref.read(selectedLedgerIdProvider.notifier).state = savedId;
        debugPrint('[LedgerNotifier] Restored saved ledger: $savedId');
        return;
      } else {
        debugPrint('[LedgerNotifier] Saved ledger not found in list: $savedId');
      }
    }
  } catch (e) {
    debugPrint('[LedgerNotifier] Failed to restore saved ledger: $e');
  }

  // 5. 내 가계부 찾기 (ownerId == userId)
  try {
    final myLedger = ledgers.firstWhere(
      (ledger) => ledger.ownerId == userId,
    );
    ref.read(selectedLedgerIdProvider.notifier).state = myLedger.id;
    debugPrint('[LedgerNotifier] Selected my ledger: ${myLedger.id}');
    return;
  } catch (_) {
    debugPrint('[LedgerNotifier] My ledger not found, using first available');
  }

  // 6. 폴백: 첫 번째 가계부 선택
  ref.read(selectedLedgerIdProvider.notifier).state = ledgers.first.id;
  debugPrint('[LedgerNotifier] Selected first ledger: ${ledgers.first.id}');
}
```

**에러 처리**:
- SharedPreferences 읽기 실패: try-catch로 무시하고 다음 단계 진행
- 내 가계부 없음: firstWhere 예외를 catch하여 폴백 처리
- 사용자 미로그인: 조기 종료

**로깅**:
- 각 단계마다 debugPrint로 상태 기록
- 프로덕션에서는 kDebugMode 체크 필요 없음 (debugPrint는 자동 제거)

#### 3.1.2 수정된 메서드: `loadLedgers()`

**변경 사항**:
- 복원 로직 제거
- `restoreOrSelectLedger()` 호출로 대체

**수정 후 코드**:
```dart
Future<void> loadLedgers() async {
  state = const AsyncValue.loading();
  try {
    final ledgers = await _repository.getLedgers();
    if (!mounted) return;
    state = AsyncValue.data(ledgers);

    // 복원 로직 실행 (단일 진입점)
    await restoreOrSelectLedger();
  } catch (e, st) {
    if (!mounted) return;
    state = AsyncValue.error(e, st);
  }
}
```

#### 3.1.3 새로운 메서드: `_validateCurrentSelection()`

**목적**: 선택된 가계부가 목록에 존재하는지 검증 (Realtime 이벤트용)

**시그니처**:
```dart
Future<void> _validateCurrentSelection() async
```

**알고리즘**:
```dart
Future<void> _validateCurrentSelection() async {
  final selectedId = ref.read(selectedLedgerIdProvider);
  if (selectedId == null) return;

  final ledgers = state.valueOrNull ?? [];
  final isValid = ledgers.any((ledger) => ledger.id == selectedId);

  if (!isValid) {
    debugPrint('[LedgerNotifier] Current ledger no longer accessible: $selectedId');
    // 가계부가 삭제되었거나 멤버에서 제외됨 → 자동 복원
    ref.read(selectedLedgerIdProvider.notifier).state = null;
    await restoreOrSelectLedger();
  }
}
```

**호출 위치**:
- `subscribeLedgerMembers` 콜백

#### 3.1.4 수정된 메서드: `_subscribeToChanges()`

**변경 사항**:
- `subscribeLedgerMembers` 콜백에 `_validateCurrentSelection()` 추가

**수정 후 코드**:
```dart
void _subscribeToChanges() {
  try {
    // ledgers 테이블 변경 구독
    _ledgersChannel = _repository.subscribeLedgers((ledgers) {
      if (!mounted) return;
      state = AsyncValue.data(ledgers);
    });

    // ledger_members 테이블 변경 구독 (멤버 나감/들어옴 감지)
    _membersChannel = _repository.subscribeLedgerMembers(() async {
      // 로딩 상태 없이 데이터만 새로고침
      await _refreshLedgersQuietly();

      // 현재 선택된 가계부 유효성 검증
      if (!mounted) return;
      await _validateCurrentSelection();
    });
  } catch (e) {
    // Realtime 구독 실패 시 무시 (기본 기능에는 영향 없음)
    debugPrint('[LedgerNotifier] Realtime 구독 실패: $e');
  }
}
```

#### 3.1.5 수정된 메서드: `deleteLedger()`

**변경 사항**:
- 폴백 로직을 `restoreOrSelectLedger()`로 대체

**수정 후 코드**:
```dart
Future<void> deleteLedger(String id) async {
  await safeAsync(() => _repository.deleteLedger(id));

  // 삭제한 가계부가 현재 선택된 가계부면 선택 해제
  final selectedId = ref.read(selectedLedgerIdProvider);
  final wasSelected = selectedId == id;

  if (wasSelected) {
    ref.read(selectedLedgerIdProvider.notifier).state = null;
  }

  await loadLedgers();

  // 삭제 후 자동 복원
  if (wasSelected) {
    await restoreOrSelectLedger();
  }
}
```

### 3.2 ledgersProvider 단순화

**변경 사항**:
- 복원 로직 제거
- 단순 조회만 수행

**수정 후 코드**:
```dart
// 사용자의 가계부 목록
final ledgersProvider = FutureProvider<List<Ledger>>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return await repository.getLedgers();
});
```

**설명**:
- `LedgerNotifier`가 복원 로직을 담당하므로 중복 제거
- 단순 조회만 필요한 곳에서 사용

### 3.3 AuthNotifier 수정

#### 3.3.1 수정된 메서드: `signInWithEmail()`

**변경 사항**:
- 로그인 성공 후 가계부 상태 초기화 추가

**수정 후 코드**:
```dart
Future<void> signInWithEmail({
  required String email,
  required String password,
}) async {
  state = const AsyncValue.loading();
  try {
    final response = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    // 로그인 성공 후 가계부 상태 초기화
    _ref.read(selectedLedgerIdProvider.notifier).state = null;
    _ref.invalidate(ledgerNotifierProvider);

    state = AsyncValue.data(response.user);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

#### 3.3.2 수정된 메서드: `signInWithGoogle()`

**변경 사항**:
- 로그인 성공 후 가계부 상태 초기화 추가

**수정 후 코드**:
```dart
Future<void> signInWithGoogle() async {
  state = const AsyncValue.loading();
  try {
    final response = await _authService.signInWithGoogle();

    // 로그인 성공 후 가계부 상태 초기화
    _ref.read(selectedLedgerIdProvider.notifier).state = null;
    _ref.invalidate(ledgerNotifierProvider);

    state = AsyncValue.data(response.user);
  } catch (e, st) {
    state = AsyncValue.error(e, st);
    rethrow;
  }
}
```

**설명**:
- `selectedLedgerIdProvider` null로 초기화하여 이전 사용자 상태 제거
- `invalidate(ledgerNotifierProvider)` 호출로 `LedgerNotifier` 재생성 및 `loadLedgers()` 트리거

### 3.4 currentLedgerProvider 개선 (선택사항)

**목적**: 선택된 가계부가 목록에 없을 때 자동 복원

**수정 후 코드**:
```dart
// 현재 선택된 가계부
final currentLedgerProvider = FutureProvider<Ledger?>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return null;

  final ledgersAsync = ref.watch(ledgerNotifierProvider);
  final ledgers = ledgersAsync.valueOrNull ?? [];

  // 선택된 가계부가 목록에 없으면 자동 복원 (추가 안전장치)
  if (ledgers.isNotEmpty && !ledgers.any((ledger) => ledger.id == ledgerId)) {
    debugPrint('[currentLedgerProvider] Selected ledger not in list, triggering restore');
    ref.read(ledgerNotifierProvider.notifier).restoreOrSelectLedger();
    return null;
  }

  try {
    return ledgers.firstWhere((ledger) => ledger.id == ledgerId);
  } catch (_) {
    // 캐시에 없으면 직접 조회
    final repository = ref.read(ledgerRepositoryProvider);
    return repository.getLedger(ledgerId);
  }
});
```

**설명**:
- Realtime 구독 외에 추가 안전장치 역할
- UI 렌더링 시점에 유효성 재검증

## 4. 데이터 구조

### 4.1 Ledger 엔티티

**기존 구조** (변경 없음):
```dart
class Ledger extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String currency;
  final String ownerId;  // 소유자 식별에 사용
  final bool isShared;
  final DateTime createdAt;
  final DateTime updatedAt;

  // ...
}
```

**사용**:
- `ownerId`: 내 가계부 찾기에 사용 (`ledger.ownerId == userId`)

### 4.2 SharedPreferences 키

**키**: `'current_ledger_id'`
**타입**: `String` (가계부 ID)
**저장 시점**: `selectedLedgerIdProvider` 변경 시 (ledgerIdPersistenceProvider)
**삭제 시점**: 로그아웃 시 (AuthService.signOut)

### 4.3 Provider 상태 관리

```dart
// 선택된 가계부 ID (앱 전역 상태)
final selectedLedgerIdProvider = StateProvider<String?>((ref) => null);

// SharedPreferences 자동 저장 (listen)
final ledgerIdPersistenceProvider = Provider<void>((ref) {
  ref.listen<String?>(selectedLedgerIdProvider, (previous, next) async {
    if (next != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_ledger_id', next);
      debugPrint('[Persistence] Saved ledger ID: $next');
    }
  });
});

// SharedPreferences에서 복원 (FutureProvider)
final restoreLedgerIdProvider = FutureProvider<String?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final savedId = prefs.getString('current_ledger_id');
  debugPrint('[Restore] Loaded ledger ID: ${savedId ?? 'null'}');
  return savedId;
});
```

## 5. 인터페이스 설계

### 5.1 LedgerNotifier 퍼블릭 메서드

```dart
class LedgerNotifier extends SafeNotifier<List<Ledger>> {
  // 기존 메서드
  Future<void> loadLedgers();
  Future<Ledger> createLedger({...});
  Future<void> updateLedger({...});
  Future<void> deleteLedger(String id);
  void selectLedger(String id);
  Future<void> syncShareStatus({...});

  // 새로운 메서드 (퍼블릭)
  Future<void> restoreOrSelectLedger();
}
```

### 5.2 프라이빗 메서드

```dart
class LedgerNotifier extends SafeNotifier<List<Ledger>> {
  // 기존 프라이빗 메서드
  void _subscribeToChanges();
  Future<void> _refreshLedgersQuietly();

  // 새로운 프라이빗 메서드
  Future<void> _validateCurrentSelection();
}
```

## 6. 시퀀스 다이어그램

### 6.1 로그인 → 복원 시퀀스

```
User          AuthNotifier    LedgerNotifier   Repository   SharedPreferences
 |                 |                |               |               |
 |--signIn-------->|                |               |               |
 |                 |                |               |               |
 |                 |--signInWithEmail()             |               |
 |                 |                |               |               |
 |                 |--초기화------->|               |               |
 |                 |  (state=null)  |               |               |
 |                 |                |               |               |
 |                 |--invalidate--->|               |               |
 |                 |                |               |               |
 |                 |                |--loadLedgers()|               |
 |                 |                |               |               |
 |                 |                |--getLedgers()->|               |
 |                 |                |<--ledgers-----|               |
 |                 |                |               |               |
 |                 |                |--restoreOrSelectLedger()       |
 |                 |                |               |               |
 |                 |                |--read savedId---------------->|
 |                 |                |<--savedId---------------------|
 |                 |                |               |               |
 |                 |                |--유효성 검증  |               |
 |                 |                | (유효?)       |               |
 |                 |                |               |               |
 |                 |                |--select ledger|               |
 |                 |                | (state 업데이트)              |
 |                 |                |               |               |
 |<--UI 렌더링-----|<--state.data---|               |               |
 |                 |                |               |               |
```

### 6.2 멤버 탈퇴 → 자동 복원 시퀀스

```
Supabase     LedgerNotifier   Repository   SharedPreferences
Realtime
 |                 |               |               |
 |--member deleted |               |               |
 |                 |               |               |
 |--callback------>|               |               |
 |                 |               |               |
 |                 |--_refreshLedgersQuietly()     |
 |                 |               |               |
 |                 |--getLedgers()->|               |
 |                 |<--ledgers-----|               |
 |                 |               |               |
 |                 |--_validateCurrentSelection()  |
 |                 | (선택된 가계부가 목록에 없음)  |
 |                 |               |               |
 |                 |--state=null   |               |
 |                 |               |               |
 |                 |--restoreOrSelectLedger()      |
 |                 |               |               |
 |                 |--read savedId---------------->|
 |                 |<--null (같은 가계부)-----------|
 |                 |               |               |
 |                 |--find my ledger|              |
 |                 |--select my ledger             |
 |                 |               |               |
```

## 7. 에러 처리

### 7.1 에러 시나리오 및 처리

| 시나리오 | 에러 타입 | 처리 방법 | 사용자 영향 |
|---------|----------|----------|-----------|
| SharedPreferences 읽기 실패 | Exception | try-catch 무시, 내 가계부 찾기 진행 | 없음 (폴백) |
| 가계부 목록 조회 실패 | PostgrestException | AsyncValue.error로 전파, UI에 에러 표시 | 에러 화면 |
| 내 가계부 없음 | StateError (firstWhere) | catch 후 첫 번째 가계부 선택 | 없음 (폴백) |
| 사용자 미로그인 | null check | 조기 종료, 로그 기록 | 로그인 화면 유지 |
| Realtime 구독 실패 | Exception | try-catch 무시, 로그 기록 | 수동 새로고침 필요 |

### 7.2 에러 로깅 전략

**프로덕션**:
```dart
// debugPrint는 프로덕션에서 자동 제거됨
debugPrint('[LedgerNotifier] Error occurred: $e');
```

**디버그 모드만 로깅 필요 시**:
```dart
if (kDebugMode) {
  debugPrint('[LedgerNotifier] Debug info: $data');
}
```

### 7.3 에러 전파 원칙 (CLAUDE.md 준수)

1. **데이터베이스 에러는 절대 무시하지 않음**
   ```dart
   try {
     await _repository.getLedgers();
   } catch (e, st) {
     state = AsyncValue.error(e, st);
     // rethrow 없음 (state에 에러 저장으로 UI까지 전파)
   }
   ```

2. **UI 레이어까지 에러 전파**
   ```dart
   // AuthNotifier
   try {
     await _authService.signInWithEmail(...);
   } catch (e, st) {
     state = AsyncValue.error(e, st);
     rethrow; // 호출자(UI)가 catch 가능
   }
   ```

3. **로컬 에러는 폴백 처리**
   ```dart
   // SharedPreferences 실패는 무시하고 계속
   try {
     final savedId = await ref.read(restoreLedgerIdProvider.future);
   } catch (e) {
     // 로그만 남기고 계속 진행
     debugPrint('[LedgerNotifier] Failed to restore: $e');
   }
   ```

## 8. 성능 고려사항

### 8.1 최적화 포인트

1. **불필요한 재로딩 방지**
   - `_refreshLedgersQuietly()`: 로딩 상태 없이 조용히 갱신
   - `invalidate()` 대신 직접 상태 업데이트

2. **SharedPreferences 읽기 캐싱**
   - `restoreLedgerIdProvider`는 FutureProvider로 자동 캐싱
   - 같은 세션에서 여러 번 읽어도 한 번만 실행

3. **비동기 작업 타이밍**
   - `loadLedgers()` 완료 후 `restoreOrSelectLedger()` 호출
   - 순차 실행으로 경쟁 상태 방지

### 8.2 메모리 관리

```dart
@override
void dispose() {
  _ledgersChannel?.unsubscribe();
  _membersChannel?.unsubscribe();
  super.dispose();
}
```

- Realtime 채널 정리로 메모리 누수 방지

## 9. 테스트 계획

### 9.1 단위 테스트

**대상**: `LedgerNotifier.restoreOrSelectLedger()`

**시나리오**:
1. 이미 선택된 경우 → 아무것도 하지 않음
2. 저장된 ID 유효 → 해당 가계부 선택
3. 저장된 ID 무효 + 내 가계부 있음 → 내 가계부 선택
4. 저장된 ID 무효 + 내 가계부 없음 → 첫 번째 가계부 선택
5. 가계부 목록 비어있음 → 아무것도 하지 않음

**Mocking**:
- `LedgerRepository.getLedgers()` → 가짜 가계부 목록 반환
- `SharedPreferences` → MockSharedPreferences 사용
- `SupabaseConfig.client.auth.currentUser` → 가짜 사용자

### 9.2 통합 테스트

**시나리오**:
1. 로그인 → 마지막 선택 가계부 복원
2. 로그인 → 저장된 가계부 없음 → 내 가계부 자동 선택
3. 가계부 삭제 → 자동 폴백
4. 멤버 탈퇴 → 자동 폴백
5. 로그아웃 → 저장된 ID 삭제 확인

**도구**:
- `flutter_test` 패키지
- `integration_test` 패키지

### 9.3 E2E 테스트 (Maestro)

**테스트 플로우**:
```yaml
# maestro-tests/ledger_auto_selection.yaml
- launchApp
- tapOn: 'Login'
- inputText:
    text: 'test@example.com'
- inputText:
    text: 'password'
- tapOn: 'Submit'
- assertVisible: '내 가계부' # 자동 선택 확인
- tapOn: '공유 가계부'
- tapOn: 'Logout'
- tapOn: 'Login'
- inputText:
    text: 'test@example.com'
- inputText:
    text: 'password'
- tapOn: 'Submit'
- assertVisible: '공유 가계부' # 마지막 선택 복원 확인
```

## 10. 구현 순서

### 10.1 Phase 1: 복원 로직 일원화

**파일**: `lib/features/ledger/presentation/providers/ledger_provider.dart`

**작업**:
1. `LedgerNotifier`에 `restoreOrSelectLedger()` 메서드 추가
2. `loadLedgers()` 수정 (복원 로직 제거 → 메서드 호출로 대체)
3. `ledgersProvider` 단순화 (복원 로직 제거)

**검증**:
- 로그인 시 가계부 자동 선택 확인
- debugPrint로 로그 확인

### 10.2 Phase 2: 내 가계부 우선 선택

**파일**: `lib/features/ledger/presentation/providers/ledger_provider.dart`

**작업**:
1. `restoreOrSelectLedger()` 내부에 내 가계부 찾기 로직 추가
2. `firstWhere(ownerId == userId)` 사용

**검증**:
- 저장된 가계부 없을 때 내 가계부 선택 확인
- 내 가계부 없을 때 첫 번째 가계부 폴백 확인

### 10.3 Phase 3: 실시간 유효성 검증

**파일**: `lib/features/ledger/presentation/providers/ledger_provider.dart`

**작업**:
1. `_validateCurrentSelection()` 메서드 추가
2. `_subscribeToChanges()` 수정 (멤버 변경 콜백에 유효성 검증 추가)
3. `deleteLedger()` 수정 (폴백 로직을 `restoreOrSelectLedger()`로 대체)

**검증**:
- 멤버 탈퇴 시 자동 복원 확인
- 가계부 삭제 시 자동 폴백 확인

### 10.4 Phase 4: 로그인 상태 초기화

**파일**: `lib/features/auth/presentation/providers/auth_provider.dart`

**작업**:
1. `AuthNotifier.signInWithEmail()` 수정
2. `AuthNotifier.signInWithGoogle()` 수정
3. 로그인 성공 후 `selectedLedgerIdProvider` null 설정
4. `invalidate(ledgerNotifierProvider)` 호출

**검증**:
- 다른 사용자 로그인 시 이전 상태 없음 확인
- RLS 위반 없음 확인

### 10.5 Phase 5: 테스트 및 검증

**작업**:
1. 단위 테스트 작성 (`test/features/ledger/ledger_notifier_test.dart`)
2. 통합 테스트 작성
3. E2E 테스트 작성 (Maestro)
4. 수동 테스트 (7가지 시나리오)

**검증 체크리스트**:
- [ ] 로그인 → 마지막 선택 가계부 복원
- [ ] 로그인 → 저장된 가계부 없음 → 내 가계부 자동 선택
- [ ] 로그인 → 저장된 가계부 삭제됨 → 내 가계부 자동 선택
- [ ] 공유 가계부 탈퇴 → 내 가계부 자동 선택
- [ ] 가계부 삭제 → 남은 가계부 자동 선택
- [ ] 로그아웃 → 저장된 ID 삭제 확인
- [ ] 다른 사용자 로그인 → 이전 사용자 상태 없음 확인

## 11. 롤백 계획

### 11.1 롤백 트리거

- 가계부 선택 실패율 5% 초과
- 사용자 불편 신고 3건 이상
- RLS 위반 에러 발생

### 11.2 롤백 절차

1. Git revert 실행
   ```bash
   git revert <commit-hash>
   ```

2. 기존 복원 로직 복구
   - `ledgersProvider`에 복원 로직 재추가
   - `LedgerNotifier.loadLedgers()`의 복원 로직 재활성화

3. 긴급 배포

### 11.3 데이터 마이그레이션

- SharedPreferences 데이터는 변경 없음 (기존 호환)
- 롤백 시 추가 작업 불필요

## 12. 모니터링 지표

### 12.1 성공 지표

- **복원 성공률**: 95% 이상
- **폴백 성공률**: 100%
- **에러 발생률**: 0건
- **평균 선택 시간**: 500ms 이하

### 12.2 로그 수집

```dart
// 복원 성공
debugPrint('[LedgerNotifier] Restored saved ledger: $savedId');

// 폴백 (내 가계부)
debugPrint('[LedgerNotifier] Selected my ledger: ${myLedger.id}');

// 폴백 (첫 번째)
debugPrint('[LedgerNotifier] Selected first ledger: ${ledgers.first.id}');

// 유효성 검증 실패
debugPrint('[LedgerNotifier] Current ledger no longer accessible: $selectedId');
```

### 12.3 알림 조건

- 가계부 미선택 상태로 5초 이상 유지
- 복원 로직 3회 연속 실패
- SharedPreferences 읽기 실패

## 13. 문서화

### 13.1 코드 주석

```dart
/// 가계부 자동 선택 및 복원 로직
///
/// 다음 순서로 가계부를 선택합니다:
/// 1. SharedPreferences에 저장된 가계부 ID 복원
/// 2. 복원 실패 시 내 가계부(ownerId == userId) 선택
/// 3. 내 가계부 없으면 첫 번째 가계부 선택
///
/// 이미 선택된 경우나 가계부 목록이 비어있으면 아무것도 하지 않습니다.
Future<void> restoreOrSelectLedger() async {
  // ...
}
```

### 13.2 CLAUDE.md 업데이트

**추가 내용**:
```markdown
## 가계부 자동 선택

로그인 시 가계부가 자동으로 선택됩니다:
1. 마지막 선택 가계부 복원 (SharedPreferences)
2. 복원 실패 시 내 가계부 선택
3. 내 가계부 없으면 첫 번째 가계부 선택

복원 로직은 `LedgerNotifier.restoreOrSelectLedger()`에 일원화되어 있습니다.
```

## 14. 의존성

### 14.1 패키지 의존성

**기존 패키지** (변경 없음):
- `shared_preferences`: SharedPreferences 저장/읽기
- `flutter_riverpod`: 상태 관리
- `supabase_flutter`: Realtime 구독

**새로운 패키지**: 없음

### 14.2 코드 의존성

**LedgerNotifier 의존**:
- `LedgerRepository`: 가계부 목록 조회
- `selectedLedgerIdProvider`: 선택 상태 관리
- `restoreLedgerIdProvider`: SharedPreferences 읽기
- `SafeNotifier`: 안전한 비동기 작업

**AuthNotifier 의존**:
- `selectedLedgerIdProvider`: 로그인 시 초기화
- `ledgerNotifierProvider`: invalidate로 재생성

## 15. 보안 고려사항

### 15.1 RLS (Row Level Security)

**시나리오**: 사용자 A 로그아웃 → 사용자 B 로그인 → A의 가계부 ID가 남아있음

**현재 처리**:
- `AuthService.signOut()`: SharedPreferences에서 ID 삭제
- `AuthNotifier.signOut()`: `selectedLedgerIdProvider` null로 초기화

**추가 보완**:
- 로그인 시 `selectedLedgerIdProvider` null로 재초기화
- `invalidate(ledgerNotifierProvider)`로 강제 재로딩

**결과**:
- 사용자 B가 A의 가계부에 접근 불가 (RLS 정책에 의해 차단)
- UI에서도 미리 차단 (선택 상태 초기화)

### 15.2 데이터 유효성

**검증 포인트**:
1. 저장된 ID가 현재 사용자의 가계부 목록에 존재하는가?
2. 선택된 가계부가 실시간으로 삭제/탈퇴되지 않았는가?

**검증 로직**:
- `restoreOrSelectLedger()`: 복원 전 유효성 검증
- `_validateCurrentSelection()`: Realtime 이벤트 시 유효성 검증
- `currentLedgerProvider`: UI 렌더링 전 유효성 검증

## 16. 향후 개선 방향

### 16.1 멀티 디바이스 동기화

**현재 한계**:
- 각 기기의 SharedPreferences는 독립적
- A 기기에서 선택한 가계부가 B 기기에 반영되지 않음

**개선안**:
- Supabase에 `user_preferences` 테이블 추가
- `current_ledger_id` 컬럼으로 서버 동기화
- Realtime으로 다른 기기에 전파

### 16.2 최근 사용 가계부 목록

**현재 한계**:
- 하나의 가계부 ID만 저장

**개선안**:
- 최근 3개 가계부 ID 저장 (JSON 배열)
- 복원 시 순서대로 유효성 검증
- 가계부 전환 UI 개선 (최근 사용 목록 표시)

### 16.3 오프라인 모드

**현재 한계**:
- 네트워크 없으면 가계부 목록 조회 실패

**개선안**:
- 로컬 캐싱 (Hive, Isar 등)
- 오프라인에서도 마지막 가계부 표시
- 온라인 복귀 시 동기화

## 17. 참고자료

### 17.1 Flutter 공식 문서

- [SharedPreferences](https://pub.dev/packages/shared_preferences)
- [Riverpod FutureProvider](https://riverpod.dev/docs/providers/future_provider)
- [Riverpod StateProvider](https://riverpod.dev/docs/providers/state_provider)

### 17.2 Supabase 문서

- [Realtime 구독](https://supabase.com/docs/guides/realtime)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

### 17.3 프로젝트 문서

- Plan: `docs/01-plan/features/ledger-auto-selection.plan.md`
- CLAUDE.md: 에러 처리 원칙, 비동기 작업 가이드
