# 테스트 계정 생성 가이드

## 현재 상태

Supabase에 테스트 계정이 생성되어 있지 않습니다. Maestro 테스트를 실행하기 전에 다음 계정을 생성해야 합니다:

- **user1@test.com** / testpass123
- **user2@test.com** / testpass123

## 방법 1: Supabase 대시보드에서 생성 (권장)

### 단계별 가이드

1. **Supabase 대시보드 접속**
   - https://app.supabase.com 으로 이동
   - 로그인

2. **프로젝트 선택**
   - 공유 가계부 앱 프로젝트 클릭

3. **Authentication 메뉴로 이동**
   - 왼쪽 사이드바에서 `Authentication` 클릭
   - `Users` 클릭

4. **첫 번째 사용자 생성**
   - 우측 상단 `Add user` 버튼 클릭
   - `Create new user` 선택
   - 다음 정보 입력:
     ```
     Email: user1@test.com
     Password: testpass123
     Auto Confirm User: ✅ 체크 (중요!)
     ```
   - `Create User` 클릭

5. **두 번째 사용자 생성**
   - 다시 `Add user` 버튼 클릭
   - 다음 정보 입력:
     ```
     Email: user2@test.com
     Password: testpass123
     Auto Confirm User: ✅ 체크 (중요!)
     ```
   - `Create User` 클릭

6. **확인**
   - Users 목록에 두 계정이 표시되어야 함
   - 각 사용자의 `Email Confirmed` 상태가 확인되어야 함

## 방법 2: 앱에서 직접 회원가입 (대안)

앱을 실행하여 직접 회원가입할 수도 있습니다:

1. **에뮬레이터 실행**
   ```bash
   flutter emulators --launch Test_Share_1
   ```

2. **앱 실행**
   ```bash
   flutter run
   ```

3. **회원가입 화면에서**
   - 이메일: user1@test.com
   - 비밀번호: testpass123
   - 회원가입 버튼 클릭

4. **이메일 확인 (중요)**
   - Supabase 대시보드 > Authentication > Users
   - user1@test.com 클릭
   - `Confirm email` 버튼 클릭

5. **user2@test.com도 동일하게 반복**

## 확인 방법

계정이 올바르게 생성되었는지 확인:

```bash
# 앱 실행 후 로그인 테스트
flutter run
# user1@test.com / testpass123로 로그인 시도
```

또는 터미널에서:

```bash
# Supabase SQL 쿼리로 확인
# (Claude Code에서 실행 가능)
SELECT email, email_confirmed_at FROM auth.users
WHERE email IN ('user1@test.com', 'user2@test.com');
```

## 주의사항

1. **Auto Confirm User 체크 필수**
   - 체크하지 않으면 이메일 인증이 필요하여 테스트가 실패합니다

2. **비밀번호 일치**
   - 두 계정 모두 `testpass123`으로 설정해야 Maestro 테스트가 작동합니다

3. **이메일 주소 정확히 입력**
   - `user1@test.com` (숫자 1)
   - `user2@test.com` (숫자 2)

## 다음 단계

계정 생성이 완료되면 Maestro 테스트를 실행할 수 있습니다:

```bash
bash maestro-tests/run_share_test.sh
```
