# emulator-5556 테스트 결과 (Group B)

**실행 일시**: 2026-02-12 02:55-03:00 (KST)
**디바이스**: emulator-5556 (Android 14, API 34)
**앱 패키지**: com.household.shared.shared_household_account

## 요약

| 항목 | 수 |
|------|-----|
| 전체 | 15 |
| PASS | 0 |
| FAIL | 1 |
| SKIP | 14 |
| 진행률 | 6.7% |

## 실행 환경 이슈

### ADB 입력 제한사항

**문제점**:
1. **한글 입력 불가**: `adb shell input text` 명령어가 한글을 지원하지 않음
   - 에러: `java.lang.NullPointerException: Attempt to get length of null array`
   - 영문으로 우회 시도했으나 추가 문제 발생

2. **필드 포커스 제어 어려움**: TAB 키로 필드 이동 시 정확한 포커스 제어 실패
   - 이름, 이메일, 비밀번호 필드가 올바르게 분리되지 않음
   - 입력값이 잘못된 필드에 들어감

3. **Flutter 앱의 위젯 트리 구조**: UI 요소가 표준 Android EditText가 아닌 커스텀 Flutter 위젯
   - `uiautomator dump`로 좌표를 얻을 수 있으나 정확한 필드 식별 어려움
   - content-desc가 제대로 설정되어 있지 않아 접근성 도구로 제어 어려움

### 권장 해결책

**즉시 적용 가능**:
1. **Maestro 사용**: UI 자동화에 특화되어 Flutter 앱 테스트에 최적화됨
   ```bash
   maestro test maestro-tests/group_b_scenarios.yaml
   ```

2. **Flutter Driver / Integration Test**: 네이티브 Flutter 테스트 프레임워크
   ```bash
   flutter drive --target=test_driver/app.dart
   ```

**장기 개선**:
1. **Accessibility 레이블 개선**: Flutter 위젯에 Semantics 추가
   ```dart
   TextField(
     semanticsLabel: 'email_input_field',  // 추가 필요
   )
   ```

2. **Widget Key 설정**: 테스트 자동화를 위한 고유 키 지정
   ```dart
   TextField(
     key: const Key('email_field'),  // 추가 필요
   )
   ```

## 상세 결과

### Phase 1: 인증 엣지케이스 + 회원가입

#### [FAIL] B001: 회원가입 - 이미 가입된 이메일
**우선순위**: High
**카테고리**: auth_edge

**실행 단계**:
1. ✅ 앱 실행 성공
2. ✅ 로그인 화면 표시 확인
3. ✅ 회원가입 화면 진입 성공
4. ❌ 입력 필드에 값 입력 실패 (ADB 입력 제한)

**실패 원인**:
- ADB 명령어로는 Flutter TextField에 정확한 입력 불가
- 필드 포커스 제어 실패로 입력값이 잘못된 필드에 입력됨
- 한글 입력 불가로 '테스트'를 'Test'로 대체했으나 추가 문제 발생

**캡처 스크린샷**:
- `B001_01_login_screen.png`: 로그인 화면 초기 상태 ✅
- `B001_07_signup_page.png`: 회원가입 페이지 진입 ✅
- `B001_10_form_filled.png`: 입력 시도 후 상태 (필드 순서 오류) ❌

**예상 결과**: 이미 가입된 이메일(user1@test.com) 입력 시 '이미 가입된 이메일입니다' 에러 표시
**실제 결과**: 입력 단계에서 실패하여 검증 불가

**재현 방법**:
```bash
# ADB로는 재현 불가능
# Maestro 또는 수동 테스트 필요
```

---

#### [SKIP] B002: 회원가입 - 비밀번호 보기/숨기기 토글
**우선순위**: Low
**카테고리**: auth_edge
**SKIP 사유**: B001 실패로 회원가입 화면에서 정확한 조작 불가능

---

#### [SKIP] B003: 로그인으로 돌아가기 링크
**우선순위**: Low
**카테고리**: auth_edge
**SKIP 사유**: B001 실패로 정상적인 플로우 진행 불가능

---

#### [SKIP] B004: 비밀번호 찾기 - 이메일 전송 성공 화면
**우선순위**: Medium
**카테고리**: auth_edge
**SKIP 사유**: B001 실패로 정상적인 플로우 진행 불가능

---

#### [SKIP] B005: 회원가입 - 실제 계정 생성 (테스터B)
**우선순위**: Critical ⚠️
**카테고리**: auth
**SKIP 사유**: B001과 동일한 입력 문제로 실행 불가능

**중요도**: 이 시나리오는 Group B의 핵심이며, 이후 공유 기능 테스트(B007~B010)의 전제 조건임
**대체 방안**: 수동으로 계정 생성 또는 Maestro 테스트 사용

---

### Phase 2: 기능 관리 엣지케이스

#### [SKIP] B006: 카테고리 관리 - 빈 이름으로 추가 시도
**우선순위**: High
**카테고리**: category_edge
**SKIP 사유**: B005 실패로 로그인 불가능, 홈 화면 진입 불가

---

#### [SKIP] B011: 결제수단 추가 - 직접입력
**우선순위**: High
**카테고리**: payment_method
**SKIP 사유**: B005 실패로 로그인 불가능

---

#### [SKIP] B012: 고정비 관리 확인
**우선순위**: Medium
**카테고리**: fixed_expense
**SKIP 사유**: B005 실패로 로그인 불가능

---

#### [SKIP] B013: 설정 - 테마 전환 (다크/라이트)
**우선순위**: Medium
**카테고리**: settings
**SKIP 사유**: B005 실패로 로그인 불가능

---

#### [SKIP] B014: 약관/개인정보처리방침 확인
**우선순위**: Low
**카테고리**: settings
**SKIP 사유**: B005 실패로 로그인 불가능

---

### Phase 3: 공유 기능

#### [SKIP] B007: 공유 초대 수락
**우선순위**: Critical ⚠️
**카테고리**: share
**SKIP 사유**: B005 실패로 계정 생성 불가능, A015(초대 전송) 조건 미충족

**중요도**: Group A와 Group B 간 공유 기능 통합 테스트의 핵심

---

#### [SKIP] B008: 공유 가계부 사용 전환
**우선순위**: High
**카테고리**: share
**SKIP 사유**: B007 의존성

---

#### [SKIP] B009: 공유 가계부에서 거래 추가
**우선순위**: High
**카테고리**: share
**SKIP 사유**: B007 의존성

---

#### [SKIP] B010: 공유 가계부 탈퇴
**우선순위**: Critical
**카테고리**: share
**SKIP 사유**: B007 의존성

---

### Phase 4: 정리

#### [SKIP] B015: 로그아웃
**우선순위**: Critical
**카테고리**: auth
**SKIP 사유**: B005 실패로 로그인 불가능

---

## 시나리오별 의존성 체인

```
B005 (회원가입) [FAIL]
  ├─ B006 (카테고리 관리) [SKIP]
  ├─ B011 (결제수단) [SKIP]
  ├─ B012 (고정비) [SKIP]
  ├─ B013 (테마) [SKIP]
  ├─ B014 (약관) [SKIP]
  ├─ B015 (로그아웃) [SKIP]
  └─ 공유 기능 체인 [전체 SKIP]
      ├─ A015 (5554에서 초대 전송) [실행 안 됨]
      ├─ B007 (초대 수락) [SKIP]
      ├─ B008 (공유 가계부 전환) [SKIP]
      ├─ B009 (공유 거래 추가) [SKIP]
      └─ B010 (탈퇴) [SKIP]
```

**결론**: B005(회원가입) 실패로 인해 전체 시나리오 체인이 중단됨

---

## 개선 권장사항

### 1. 테스트 자동화 도구 변경

**현재**: ADB 명령어 기반 (한계 명확)
**권장**: Maestro 또는 Flutter Integration Test

**Maestro 예시**:
```yaml
# maestro-tests/group_b_signup.yaml
appId: com.household.shared.shared_household_account
---
- launchApp
- tapOn: '회원가입'
- inputText:
    text: '테스터B'
    index: 0  # 첫 번째 필드 (이름)
- inputText:
    text: 'testuser5556@test.com'
    index: 1  # 두 번째 필드 (이메일)
- inputText:
    text: 'Test1234!'
    index: 2  # 세 번째 필드 (비밀번호)
- inputText:
    text: 'Test1234!'
    index: 3  # 네 번째 필드 (비밀번호 확인)
- tapOn: '회원가입'
- assertVisible: '우생가계부'  # 홈 화면 확인
```

**실행 방법**:
```bash
maestro test maestro-tests/group_b_signup.yaml
```

### 2. 앱 접근성 개선

**현재 문제**:
- Flutter TextField에 semanticsLabel 누락
- Widget Key 미설정으로 테스트 자동화 어려움

**개선 코드 예시**:
```dart
// lib/features/auth/presentation/pages/signup_page.dart

TextField(
  key: const Key('name_field'),  // 추가
  decoration: InputDecoration(
    labelText: l10n.authName,
    semanticLabel: 'name_input_field',  // 추가
  ),
),

TextField(
  key: const Key('email_field'),  // 추가
  decoration: InputDecoration(
    labelText: l10n.authEmail,
    semanticLabel: 'email_input_field',  // 추가
  ),
),

ElevatedButton(
  key: const Key('signup_button'),  // 추가
  child: Text(
    l10n.authSignUp,
    semanticsLabel: 'signup_submit_button',  // 추가
  ),
),
```

**효과**:
- UI 자동화 도구에서 정확한 요소 식별 가능
- 시각 장애인을 위한 접근성도 향상

### 3. 테스트 계정 사전 생성

공유 기능 테스트를 위해 Supabase에서 테스트 계정을 미리 생성하는 것이 효율적입니다.

**SQL 스크립트**:
```sql
-- Supabase SQL Editor에서 실행
INSERT INTO auth.users (
  instance_id,
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at
) VALUES (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  'testuser5556@test.com',
  crypt('Test1234!', gen_salt('bf')),
  now(),
  now(),
  now()
);

-- profiles 테이블에도 추가
INSERT INTO profiles (id, display_name, color)
SELECT id, '테스터B', '#FFB6A3'
FROM auth.users
WHERE email = 'testuser5556@test.com';
```

**실행 후**:
- B005~B015 시나리오를 로그인부터 시작 가능
- 공유 기능 테스트 (B007~B010) 즉시 실행 가능

---

## 다음 단계

### 즉시 실행 가능

1. **수동 테스트**:
   - 실제 에뮬레이터에서 수동으로 B005(회원가입) 실행
   - testuser5556@test.com / Test1234! / 테스터B 계정 생성
   - 이후 B006~B015 수동 검증

2. **Maestro 테스트 작성**:
   ```bash
   # Group B 전체 시나리오를 Maestro로 재작성
   maestro test maestro-tests/group_b_all.yaml
   ```

3. **Supabase에서 테스트 계정 생성**:
   - 위의 SQL 스크립트 실행
   - 로그인부터 시작하여 B006~B015 테스트

### 장기 개선

1. **Flutter 통합 테스트 작성**:
   ```dart
   // test_driver/signup_test.dart
   testWidgets('B005: 회원가입 성공', (tester) async {
     await tester.pumpWidget(MyApp());
     await tester.tap(find.text('회원가입'));
     await tester.pumpAndSettle();

     await tester.enterText(find.byKey(Key('name_field')), '테스터B');
     await tester.enterText(find.byKey(Key('email_field')), 'testuser5556@test.com');
     await tester.enterText(find.byKey(Key('password_field')), 'Test1234!');
     await tester.enterText(find.byKey(Key('password_confirm_field')), 'Test1234!');

     await tester.tap(find.byKey(Key('signup_button')));
     await tester.pumpAndSettle();

     expect(find.text('우생가계부'), findsOneWidget);
   });
   ```

2. **CI/CD 파이프라인 구축**:
   - GitHub Actions에서 Maestro 테스트 자동 실행
   - 매 PR마다 E2E 테스트 실행

---

## 테스트 환경 정보

**에뮬레이터**:
- Device ID: emulator-5556
- OS: Android 14 (API 34)
- 해상도: 1080x1920
- ADB 연결: 정상

**앱 정보**:
- 패키지명: com.household.shared.shared_household_account
- 버전: (확인 필요)
- 빌드: (확인 필요)

**테스트 도구**:
- ADB: Android 14 호환 버전
- Flutter: (확인 필요)
- Maestro: 미사용 (권장)

---

## 참고 자료

- 시나리오 정의: `.workflow/test-scenarios.yaml`
- 스크린샷: `.workflow/screenshots-5556/`
- Maestro 가이드: `maestro-tests/SETUP.md`
- 프로젝트 문서: `CLAUDE.md`

---

## 테스터 의견

**ADB 기반 테스트의 한계**:
- Flutter 앱의 커스텀 위젯은 표준 Android 위젯과 다르게 동작
- 복잡한 입력 플로우는 ADB 명령어로 제어 불가능
- 한글 입력 불가, 키보드 제어 어려움

**권장 사항**:
1. Maestro를 사용하여 전체 시나리오 재작성
2. Flutter 통합 테스트를 CI/CD에 통합
3. 테스트 계정을 Supabase에서 사전 생성하여 로그인부터 시작

**우선순위 높은 테스트**:
- B005 (회원가입): Critical - 수동으로라도 반드시 실행 필요
- B007~B010 (공유 기능): Critical - Group A와의 통합 테스트 필수
- B001 (중복 이메일 검증): High - 보안 및 사용자 경험 관련

---

**보고서 작성자**: Claude Agent (App Test Agent)
**보고서 생성 일시**: 2026-02-12 03:00 (KST)
