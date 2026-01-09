# 현황 분석 결과

## 수정 대상: 설정 및 프로필 관련 UI/기능 개선

### 관련 파일
- `lib/features/settings/presentation/pages/settings_page.dart` - 설정 화면
- `lib/features/ledger/presentation/pages/home_page.dart` - 더보기 탭 (MoreTabView)
- `lib/features/payment_method/presentation/pages/payment_method_management_page.dart` - 결제수단 관리
- `lib/shared/widgets/color_picker.dart` - 색상 선택 위젯
- `lib/features/auth/presentation/providers/auth_provider.dart` - 인증 서비스

---

## 1. 설정 화면 - 프로필 표시이름 변경 기능

### 현재 상태
- TextFormField의 `onFieldSubmitted`로 엔터 키 누르면 바로 저장됨
- 수정 버튼이 별도로 없음

### 개선점
- 수정 버튼 추가 필요
- 값이 변경된 경우에만 버튼 활성화
- 변경되지 않은 경우 버튼 비활성화

---

## 2. 더보기 - 프로필 수정 칸 변경

### 현재 상태 (MoreTabView, 369-381줄)
```dart
ListTile(
  leading: CircleAvatar(
    child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
  ),
  title: Text(user?.email ?? '사용자'),
  subtitle: const Text('프로필 수정'),
  trailing: const Icon(Icons.chevron_right),
  onTap: () {
    // TODO: 프로필 페이지로 이동
  },
),
```

### 개선점
- leading: 사용자 설정 색상으로 CircleAvatar 배경색 표시
- title: 사용자 이메일(아이디) 표시
- subtitle: 사용자 표시이름 표시
- trailing: chevron_right 아이콘 제거
- onTap: 동작 없음 (정보 표시 용도만)

---

## 3. 결제수단 관리 - 랜덤 색상 지정

### 현재 상태
- `_PaymentMethodDialogState`에 이미 `_generateRandomColor()` 메서드 존재
- 생성 시 `color: _generateRandomColor()` 사용 중
- 이미 랜덤 색상 지정이 구현되어 있음

### 확인 결과
- 기능이 이미 구현되어 있으므로 추가 작업 불필요

---

## 4. 설정 화면 - 색상 선택 레이아웃 수정

### 현재 상태 (color_picker.dart)
- 10개 색상
- Wrap 위젯 사용, spacing: 12, runSpacing: 12
- 원형 크기: 50x50
- 왼쪽 여백이 좁고 오른쪽 여백이 넓음

### 개선점
- 색상 12개로 확장 (2개 추가)
- 원형 크기 축소 (정확한 크기는 화면에 맞춰 조정)
- 6개씩 2줄로 정렬 (Row + MainAxisAlignment.spaceEvenly 또는 GridView)
- 좌우 여백 동일하게 조정

---

## 5. 비밀번호 변경 방식 변경

### 현재 상태 (_showPasswordChangeDialog)
- 이메일로 비밀번호 재설정 링크 발송하는 방식
- 앱 내에서 직접 변경 불가

### 개선점
- 다이얼로그를 별도 페이지 또는 모달로 변경
- 현재 비밀번호 입력 필드
- 새 비밀번호 입력 필드
- 새 비밀번호 확인 입력 필드
- 현재 비밀번호 검증 후 변경 허용

### 기술적 고려사항
- Supabase에서 비밀번호 변경 시 현재 비밀번호 검증 필요
- 재인증 방식: `signInWithPassword`로 현재 비밀번호 확인 후 `updateUser`로 변경
- AuthService에 `verifyAndUpdatePassword` 메서드 추가 필요

---

## 의존성

### Provider
- `userProfileProvider`: 사용자 프로필 정보
- `userColorProvider`: 사용자 색상
- `authServiceProvider`: 인증 서비스

### Repository
- `AuthService.updatePassword()`: 비밀번호 변경

---

## 엣지 케이스

1. **표시이름 변경**
   - 빈 문자열 입력 시 처리
   - 네트워크 오류 시 에러 표시

2. **비밀번호 변경**
   - 현재 비밀번호 틀린 경우 에러 메시지
   - 새 비밀번호와 확인이 일치하지 않는 경우
   - 새 비밀번호가 최소 요구사항을 충족하지 않는 경우

3. **색상 선택**
   - 선택된 색상 표시 확인
   - 다크모드에서 색상 가시성
