# PRD: 공유 가계부 캘린더 UI/UX 개선 - 사용자별 색상 지정 및 표시

## 배경 및 목적

### 배경
현재 공유 가계부 캘린더에서는 여러 사용자의 거래가 구분 없이 표시되어, 누가 어떤 거래를 했는지 한눈에 파악하기 어렵습니다.

### 목적
- 각 사용자가 자신만의 고유 색상을 지정할 수 있도록 함
- 공유 캘린더에서 사용자별 색상으로 거래를 시각적으로 구분
- "Connected & Minimal" 디자인 컨셉을 적용하여 깔끔하고 직관적인 UI 제공
- 두 사람의 금융 활동을 한눈에 보면서도 정보의 위계(Hierarchy)를 명확하게 유지

## 필수 요구사항

### 1. 사용자 색상 설정 기능
- [ ] 사용자가 설정 화면에서 자신의 고유 색상을 선택할 수 있어야 함
- [ ] 색상 팔레트 제공 (파스텔 톤 중심으로 조화로운 색상)
- [ ] 기본 색상 제안:
  - 파스텔 블루 (#A8D8EA)
  - 코랄 오렌지 (#FFB6A3)
  - 민트 그린 (#B8E6C9)
  - 라벤더 (#D4A5D4)
  - 피치 (#FFCBA4)
- [ ] 사용자가 선택한 색상은 Supabase profiles 테이블에 저장
- [ ] 색상 변경 시 실시간으로 캘린더에 반영

### 2. 캘린더 UI 개선
- [ ] 월간 헤더 재설계:
  - [ ] 중앙에 월(Month) 표시
  - [ ] 좌우측 또는 월 아래에 각 사용자의 프로필 표시
  - [ ] 각 사용자의 총 지출/수입 합계를 사용자 색상으로 표시
  - [ ] 프로필 사진 또는 이니셜 표시 (색상 테두리)

- [ ] 캘린더 그리드 개선:
  - [ ] 각 날짜 셀에 사용자별로 색상 구분하여 거래 표시
  - [ ] 사용자 색상을 활용한 시각적 인디케이터:
    - 색상 도트 (여러 거래가 있을 경우)
    - 색상 바 (금액 표시 시)
  - [ ] 날짜 셀 레이아웃:
    ```
    [날짜]
    [User A 색상 바] -15,000
    [User B 색상 바] -8,000
    ```

### 3. 데이터베이스 스키마 수정
- [ ] Supabase migration 파일 작성
- [ ] profiles 테이블에 color 컬럼 추가 (VARCHAR 또는 TEXT)
- [ ] 기본값: #A8D8EA (파스텔 블루)
- [ ] 색상 형식: HEX 코드 (#RRGGBB)

## UI/UX 요구사항

### 디자인 컨셉: "Connected & Minimal"

#### 컬러 팔레트
- 배경: Clean White (#FFFFFF)
- 선택된 날짜: Dark Grey (#2C2C2C)
- 텍스트: Black (#000000) / Grey (#666666)
- 사용자 색상: 사용자가 선택한 색상 (파스텔 톤)

#### 정보 위계
1. **1차 정보**: 날짜, 월
2. **2차 정보**: 각 사용자의 총 합계
3. **3차 정보**: 개별 거래 금액
4. **시각적 단서**: 사용자 색상 (배경, 테두리, 도트)

### 화면 구성

#### 1. 설정 화면 (Settings Page)
```
┌─────────────────────────────┐
│ 설정                         │
├─────────────────────────────┤
│                             │
│ 프로필                       │
│ ┌─────────────────────────┐ │
│ │ [프로필 사진]            │ │
│ │ 홍길동                   │ │
│ │                         │ │
│ │ 내 색상                  │ │
│ │ [색상 선택기]           │ │
│ │ ● ● ● ● ●              │ │
│ └─────────────────────────┘ │
│                             │
└─────────────────────────────┘
```

#### 2. 캘린더 화면 (Home Page)
```
┌─────────────────────────────┐
│         2024년 1월           │
├─────────────────────────────┤
│ [A 프로필] -150,000         │
│ [B 프로필] -80,000          │
├─────────────────────────────┤
│ 일  월  화  수  목  금  토  │
│     1   2   3   4   5   6   │
│     [A]-  [B]-              │
│         10k  8k              │
│ 7   8   9  10  11  12  13   │
│ [A]- [A]-                   │
│ 15k  20k                    │
└─────────────────────────────┘
```

### 사용자 흐름

#### 색상 설정 흐름
1. 설정 화면 진입
2. "내 색상" 섹션 탭
3. 색상 팔레트에서 원하는 색상 선택
4. 자동 저장 (또는 "저장" 버튼)
5. 토스트 메시지: "색상이 변경되었습니다"
6. 캘린더 화면으로 돌아가면 즉시 반영

#### 캘린더 확인 흐름
1. 홈 화면 (캘린더) 진입
2. 월간 헤더에서 각 사용자의 합계 확인
3. 캘린더 그리드에서 날짜별 거래 확인
4. 사용자 색상으로 누가 지출/수입했는지 직관적으로 파악

## 기술 요구사항

### 1. 데이터 모델

#### profiles 테이블 확장
```sql
ALTER TABLE profiles ADD COLUMN color VARCHAR(7) DEFAULT '#A8D8EA';
```

#### Profile Entity 확장
```dart
class Profile {
  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
  final String color; // 추가
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### 2. Repository 수정
- `ProfileRepository`: 색상 조회 및 업데이트 메서드 추가
  ```dart
  Future<void> updateUserColor(String userId, String color);
  Future<String> getUserColor(String userId);
  ```

### 3. Provider 수정
- `AuthProvider` 또는 `ProfileProvider`: 색상 상태 관리
  ```dart
  AsyncValue<String> get userColor;
  Future<void> updateColor(String color);
  ```

### 4. UI 컴포넌트

#### ColorPicker Widget
- 색상 팔레트 그리드 형태
- 선택된 색상 하이라이트
- 탭 제스처로 색상 선택

#### CalendarHeaderWidget
- 월 표시
- 각 사용자 프로필 카드
  - 프로필 사진 (색상 테두리)
  - 이름
  - 합계 (색상 텍스트)

#### CalendarDayCell Widget
- 날짜 표시
- 사용자별 거래 표시 (색상 바 + 금액)
- 여러 거래 시 세로 스택 레이아웃

### 5. 상태 관리
- Riverpod을 사용한 색상 상태 관리
- 색상 변경 시 캘린더 자동 리빌드
- 로딩 상태 처리
- 에러 처리 (색상 업데이트 실패 시)

## 성공 기준

### 기능 동작
- [ ] 사용자가 설정 화면에서 색상을 선택하면 Supabase에 저장됨
- [ ] 색상 변경 후 캘린더 화면으로 돌아가면 즉시 반영됨
- [ ] 공유 가계부의 다른 멤버도 해당 사용자의 색상을 볼 수 있음
- [ ] 캘린더에서 각 사용자의 거래가 설정한 색상으로 표시됨
- [ ] 월간 헤더에 각 사용자의 프로필과 합계가 색상으로 구분되어 표시됨

### UI/UX
- [ ] 색상 선택이 직관적이고 쉬움
- [ ] 캘린더가 복잡해 보이지 않고 깔끔함
- [ ] 정보의 위계가 명확하게 드러남
- [ ] 사용자별 색상 구분이 명확함

### 테스트
- [ ] 단위 테스트 통과 (Repository, Provider)
- [ ] 위젯 테스트 통과 (ColorPicker, CalendarDayCell)
- [ ] 통합 테스트 통과 (색상 설정 -> 캘린더 반영)
- [ ] `flutter analyze` 통과 (0 issues)
- [ ] `flutter build apk` 성공

### 성능
- [ ] 색상 변경 시 불필요한 리빌드가 발생하지 않음
- [ ] 캘린더 렌더링이 부드러움 (60fps 유지)
- [ ] Supabase 쿼리 최적화 (색상 정보 캐싱)

## 제외 사항

이번 작업에서는 다음 사항을 제외합니다:

- [ ] 커스텀 색상 선택 (색상 휠, RGB 입력 등) - 추후 추가 고려
- [ ] 다크 모드 대응 - 별도 작업으로 진행
- [ ] 애니메이션 효과 - 기본 기능 완성 후 추가
- [ ] 색상 테마 저장 (여러 색상 조합 프리셋) - 추후 고려

## 일정 및 우선순위

### Phase 1: 데이터베이스 및 백엔드 (우선순위: 높음)
- DB 마이그레이션
- Entity 수정
- Repository 구현

### Phase 2: 색상 설정 UI (우선순위: 높음)
- ColorPicker 위젯
- 설정 화면 통합

### Phase 3: 캘린더 UI 개선 (우선순위: 높음)
- CalendarHeader 위젯
- CalendarDayCell 위젯
- 색상 적용 로직

### Phase 4: 테스트 및 검증 (우선순위: 중간)
- 단위 테스트
- 위젯 테스트
- 통합 테스트

## 참고 자료

### 디자인 참고
- Material Design Color System
- iOS Human Interface Guidelines - Color

### 기술 참고
- Flutter Color class documentation
- Supabase Row Level Security for profiles table
- Riverpod best practices for state management
