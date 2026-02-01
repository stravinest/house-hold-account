# 가계부 자동 선택 기능 테스트 가이드

## 테스트 환경 준비

### 1. 테스트 계정 준비
- 계정 A: test1@example.com / testpass123
- 계정 B: test2@example.com / testpass123

### 2. 테스트 가계부 준비
- 계정 A: '내 가계부' (owner), '공유 가계부' (shared)
- 계정 B: '내 가계부' (owner), '공유 가계부' (shared with A)

## 테스트 시나리오

### ✅ 시나리오 1: 로그인 → 마지막 선택 가계부 복원

**목적**: SharedPreferences에 저장된 가계부 ID가 정상적으로 복원되는지 확인

**절차**:
1. 계정 A로 로그인
2. '공유 가계부' 선택
3. 로그아웃
4. 계정 A로 다시 로그인

**기대 결과**:
- 로그인 후 '공유 가계부'가 자동으로 선택됨
- 로그에 `[LedgerNotifier] Restored saved ledger: <ledger-id>` 출력

**확인 방법**:
```bash
# Android
adb logcat | grep LedgerNotifier

# iOS
xcrun simctl spawn booted log stream --predicate 'subsystem contains "flutter"' | grep LedgerNotifier
```

---

### ✅ 시나리오 2: 로그인 → 저장된 가계부 없음 → 내 가계부 자동 선택

**목적**: 저장된 가계부 ID가 없을 때 내 가계부가 우선 선택되는지 확인

**절차**:
1. SharedPreferences 삭제 (앱 삭제 후 재설치 또는 수동 삭제)
2. 계정 A로 로그인

**기대 결과**:
- 로그인 후 '내 가계부'가 자동으로 선택됨
- 로그에 `[LedgerNotifier] Selected my ledger: <ledger-id>` 출력

**SharedPreferences 수동 삭제 방법**:
```dart
// 개발자 도구에서 실행
final prefs = await SharedPreferences.getInstance();
await prefs.remove('current_ledger_id');
```

---

### ✅ 시나리오 3: 로그인 → 저장된 가계부 삭제됨 → 내 가계부 자동 선택

**목적**: 저장된 가계부 ID가 유효하지 않을 때 폴백이 정상 작동하는지 확인

**절차**:
1. 계정 A로 로그인
2. '공유 가계부' 선택
3. 로그아웃
4. 웹 브라우저 또는 Supabase 대시보드에서 '공유 가계부' 삭제
5. 계정 A로 다시 로그인

**기대 결과**:
- 로그인 후 '내 가계부'가 자동으로 선택됨
- 로그에 `[LedgerNotifier] Saved ledger not found in list: <old-ledger-id>` 출력
- 이어서 `[LedgerNotifier] Selected my ledger: <new-ledger-id>` 출력

---

### ✅ 시나리오 4: 공유 가계부 탈퇴 → 내 가계부 자동 선택

**목적**: 실시간으로 멤버에서 제외될 때 자동 복원이 작동하는지 확인

**절차**:
1. 계정 A로 로그인
2. '공유 가계부' 선택
3. 앱 실행 상태 유지
4. 계정 B로 다른 기기에서 로그인
5. 계정 B가 '공유 가계부'에서 계정 A를 멤버에서 제거

**기대 결과**:
- 계정 A 앱에서 자동으로 '내 가계부'로 전환됨
- 로그에 `[LedgerNotifier] Current ledger no longer accessible: <old-ledger-id>` 출력
- 이어서 `[LedgerNotifier] Selected my ledger: <new-ledger-id>` 출력

**주의**:
- Realtime 구독이 정상 작동해야 함
- 네트워크 연결 확인

---

### ✅ 시나리오 5: 가계부 삭제 → 남은 가계부 자동 선택

**목적**: 선택된 가계부를 삭제할 때 자동 폴백이 작동하는지 확인

**절차**:
1. 계정 A로 로그인
2. '공유 가계부' 선택
3. '공유 가계부' 삭제 (설정 > 가계부 삭제)

**기대 결과**:
- 삭제 후 '내 가계부'가 자동으로 선택됨
- 로그에 `[LedgerNotifier] Selected my ledger: <ledger-id>` 출력

---

### ✅ 시나리오 6: 로그아웃 → 저장된 ID 삭제 확인

**목적**: 로그아웃 시 SharedPreferences가 정상적으로 삭제되는지 확인

**절차**:
1. 계정 A로 로그인
2. '공유 가계부' 선택
3. 로그아웃

**기대 결과**:
- 로그아웃 시 SharedPreferences에서 `current_ledger_id` 삭제됨
- 로그에 `[AuthService] Stored ledger ID deleted` 출력
- 로그에 `[AuthNotifier] selectedLedgerIdProvider cleared` 출력

**확인 방법**:
```dart
// 로그아웃 후 개발자 도구에서 확인
final prefs = await SharedPreferences.getInstance();
final savedId = prefs.getString('current_ledger_id');
print('Saved ID: $savedId'); // null이어야 함
```

---

### ✅ 시나리오 7: 다른 사용자 로그인 → 이전 사용자 상태 없음 확인

**목적**: 로그아웃 후 다른 사용자 로그인 시 이전 상태가 남아있지 않은지 확인

**절차**:
1. 계정 A로 로그인
2. '공유 가계부' 선택
3. 로그아웃
4. 계정 B로 로그인

**기대 결과**:
- 계정 B 로그인 후 계정 B의 '내 가계부'가 선택됨
- 계정 A의 '공유 가계부'가 선택되지 않음
- 로그에 `[LedgerNotifier] Selected my ledger: <b-ledger-id>` 출력 (계정 B의 가계부 ID)

**RLS 위반 확인**:
- 로그에 RLS 에러가 없어야 함
- 계정 B가 계정 A의 가계부에 접근 시도하지 않아야 함

---

## 디버그 로그 확인 방법

### Android (adb logcat)

```bash
# 전체 로그
adb logcat | grep -E "LedgerNotifier|AuthNotifier|AuthService"

# LedgerNotifier만
adb logcat | grep LedgerNotifier

# 특정 시간부터
adb logcat -T "$(date +%m-%d\ %H:%M:%S.000)"
```

### iOS (Xcode Console)

```bash
# 시뮬레이터 로그
xcrun simctl spawn booted log stream --predicate 'subsystem contains "flutter"' | grep -E "LedgerNotifier|AuthNotifier"

# 실물 기기 로그 (Xcode > Window > Devices and Simulators > Open Console)
```

### Flutter DevTools

```bash
flutter pub global activate devtools
flutter pub global run devtools
```

## 예상 로그 출력

### 정상 복원 (시나리오 1)
```
[LedgerNotifier] Ledger already selected: null
[LedgerNotifier] Restored saved ledger: abc123
```

### 내 가계부 선택 (시나리오 2, 3)
```
[LedgerNotifier] Saved ledger not found in list: xyz789
[LedgerNotifier] Selected my ledger: abc123
```

### 첫 번째 가계부 폴백
```
[LedgerNotifier] My ledger not found, using first available
[LedgerNotifier] Selected first ledger: def456
```

### 실시간 유효성 검증 (시나리오 4)
```
[LedgerNotifier] Current ledger no longer accessible: xyz789
[LedgerNotifier] Selected my ledger: abc123
```

## 에러 시나리오 테스트

### ❌ 에러 1: 가계부 목록 조회 실패

**절차**:
1. 네트워크 연결 끊기
2. 로그인 시도

**기대 결과**:
- UI에 에러 메시지 표시
- 로그에 `PostgrestException` 출력
- `AsyncValue.error` 상태로 전파

### ❌ 에러 2: SharedPreferences 읽기 실패

**절차**:
1. 기기 저장소 가득 참 (시뮬레이션)
2. 로그인 시도

**기대 결과**:
- 로그에 `[LedgerNotifier] Failed to restore saved ledger: <error>` 출력
- 폴백으로 내 가계부 선택됨
- 앱 정상 작동

### ❌ 에러 3: Realtime 구독 실패

**절차**:
1. Realtime 비활성화 (Supabase 대시보드)
2. 로그인 시도

**기대 결과**:
- 로그에 `Realtime 구독 실패: <error>` 출력
- 앱 정상 작동 (수동 새로고침만 필요)

## 성능 테스트

### 복원 속도 측정

**절차**:
1. 로그인 시작 시간 기록
2. 가계부 선택 완료 시간 기록
3. 차이 계산

**기대 결과**:
- 평균 복원 시간: 500ms 이하
- 최대 복원 시간: 1000ms 이하

**측정 코드**:
```dart
// ledger_provider.dart에 추가
final stopwatch = Stopwatch()..start();
await restoreOrSelectLedger();
stopwatch.stop();
debugPrint('[Performance] Restore time: ${stopwatch.elapsedMilliseconds}ms');
```

## 회귀 테스트

기존 기능이 정상 작동하는지 확인:

1. ✅ 가계부 생성 → 새 가계부 자동 선택
2. ✅ 가계부 수정 → 선택 상태 유지
3. ✅ 가계부 전환 → SharedPreferences 저장 확인
4. ✅ 멤버 초대 → 공유 상태 동기화

## 문제 해결

### 가계부가 선택되지 않음

**원인**:
- `restoreOrSelectLedger()`가 호출되지 않음
- `ledgers.isEmpty == true`

**해결**:
1. 로그 확인: `[LedgerNotifier] No ledgers available`
2. 가계부 생성 확인
3. RLS 정책 확인

### 이전 사용자 가계부가 선택됨

**원인**:
- SharedPreferences 삭제 실패
- 로그인 시 초기화 누락

**해결**:
1. 로그 확인: `[AuthService] Stored ledger ID deleted`
2. `AuthNotifier.signInWithEmail/Google`에 초기화 코드 확인
3. 수동으로 SharedPreferences 삭제

### Realtime 유효성 검증 작동 안 함

**원인**:
- Realtime 구독 실패
- `_validateCurrentSelection()` 호출 누락

**해결**:
1. 로그 확인: `Realtime 구독 실패`
2. Supabase Realtime 활성화 확인
3. 네트워크 연결 확인

## 체크리스트

구현 완료 후 아래 항목을 모두 확인하세요:

- [ ] 시나리오 1: 마지막 선택 가계부 복원
- [ ] 시나리오 2: 저장된 가계부 없음 → 내 가계부 선택
- [ ] 시나리오 3: 저장된 가계부 삭제됨 → 내 가계부 선택
- [ ] 시나리오 4: 공유 가계부 탈퇴 → 내 가계부 선택
- [ ] 시나리오 5: 가계부 삭제 → 남은 가계부 선택
- [ ] 시나리오 6: 로그아웃 → 저장된 ID 삭제
- [ ] 시나리오 7: 다른 사용자 로그인 → 이전 상태 없음
- [ ] 에러 시나리오: 네트워크 실패 처리
- [ ] 에러 시나리오: SharedPreferences 실패 폴백
- [ ] 성능 테스트: 복원 시간 500ms 이하
- [ ] 회귀 테스트: 기존 기능 정상 작동
- [ ] RLS 위반 없음
- [ ] 메모리 누수 없음 (dispose 확인)

## 배포 전 최종 확인

1. **프로덕션 빌드 테스트**:
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

2. **debugPrint 제거 확인**:
   - 프로덕션 빌드에서는 debugPrint가 자동 제거됨
   - `kDebugMode` 체크가 필요한 곳 확인

3. **성능 프로파일링**:
   ```bash
   flutter run --profile
   ```

4. **최종 사용자 시나리오 테스트**:
   - 신규 사용자 첫 로그인
   - 기존 사용자 로그인
   - 여러 기기에서 동시 로그인
