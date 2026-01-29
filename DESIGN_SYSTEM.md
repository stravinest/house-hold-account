# 디자인 시스템 가이드

> **핵심 원칙**: 모든 UI 컴포넌트는 일관된 디자인 시스템을 따라야 합니다.
> 버튼, 다이얼로그, 토스트, 애니메이션 등 모든 요소가 통일된 스타일과 동작을 가져야 합니다.

## 디자인 파일

- **소스**: `household.pen` (pencil.dev 디자인 파일)
- **Flutter 구현**: `lib/shared/themes/` 디렉토리
- **디자인 토큰**: `lib/shared/themes/design_tokens.dart`

### household.pen 구조

| 영역 | x 좌표 | 내용 |
|------|--------|------|
| Components | 0 | 재사용 컴포넌트 |
| Sample Pages | 800-7200 | 현재 앱 디자인 |
| Dialogs/Modals | 7600-9200 | 다이얼로그, 스낵바 |
| **Improved Design** | **10000+** | 개선된 디자인 |

---

## 색상 토큰

```dart
// 기본 색상
$--primary: #2E7D32          // 메인 녹색
$--primary-container: #A8DAB5 // 연한 녹색 배경
$--on-primary: #FFFFFF
$--on-primary-container: #00210B

// 표면 색상
$--surface: #FDFDF5           // 앱 배경
$--surface-container: #EFEEE6 // 카드/입력필드 배경
$--surface-container-highest: #E3E3DB
$--on-surface: #1A1C19        // 기본 텍스트
$--on-surface-variant: #44483E // 보조 텍스트

// 아웃라인
$--outline: #74796D
$--outline-variant: #C4C8BB

// 시맨틱 색상
$--error: #BA1A1A
$--expense: #BA1A1A  // 지출
$--income: #2E7D32   // 수입
$--asset: #006A6A    // 자산
```

## 간격 토큰

```dart
$--spacing-xs:  4px
$--spacing-sm:  8px
$--spacing-md:  16px
$--spacing-lg:  24px
$--spacing-xl:  32px
$--spacing-xxl: 48px
```

## 모서리 반경

```dart
$--radius-xs:   4px
$--radius-sm:   8px
$--radius-md:   12px  // 버튼, 입력필드
$--radius-lg:   16px  // FAB, 카드
$--radius-xl:   20px  // 다이얼로그
$--radius-pill: 9999px
```

## 아이콘 크기

```dart
$--icon-xs:  16px
$--icon-sm:  20px
$--icon-md:  24px  // 기본
$--icon-lg:  32px
$--icon-xl:  48px
$--icon-xxl: 64px
```

## 터치 영역

```dart
$--touch-min:   44px  // 최소
$--touch-rec:   48px  // 권장
$--touch-large: 56px  // FAB
```

---

## 컴포넌트 스펙

### Button/Elevated (Primary)

```
height: 52px
fill: $--primary
cornerRadius: 12px
padding: 14px 24px
fontSize: 16px, fontWeight: 500
color: $--on-primary

상태:
- pressed: darken 10%
- disabled: opacity 0.38
- loading: CircularProgressIndicator (20x20)
```

### Button/Outlined (Secondary)

```
height: 52px
fill: transparent
stroke: 1px $--outline
cornerRadius: 12px
fontSize: 16px, fontWeight: 500
color: $--primary

상태:
- pressed: fill $--primary opacity 0.08
```

### Button/Text

```
height: 40px
padding: 8px 16px
fontSize: 14px, fontWeight: 500
color: $--primary
```

### TextField

```
height: 52px
fill: $--surface-container-highest
cornerRadius: 12px
padding: 14px 16px
icon: 20x20, $--on-surface-variant

포커스 상태:
- stroke: 2px $--primary
- fill: $--surface

에러 상태:
- stroke: 2px $--error
```

### AlertDialog

```
width: 280px
fill: $--surface
cornerRadius: 20px
padding: 24px
gap: 16px

title: 20px, fontWeight 600, center
message: 14px, $--on-surface-variant, center
actions: 오른쪽 정렬, gap 8px
```

### BottomSheet

```
cornerRadius: top 20px
fill: $--surface

handle: 40x4, $--outline-variant, cornerRadius 2
header: 56px height
divider: 1px $--outline-variant
```

### Snackbar

```
cornerRadius: 8px
padding: 16px
position: bottom 16px

success: #388E3C, white text
error: #D32F2F, white text
info: theme default
```

### FAB

```
size: 56x56
fill: $--primary-container
cornerRadius: 16px
shadow: 0 2px 6px rgba(0,0,0,0.25)
icon: 24x24, $--on-primary-container
```

---

## 애니메이션

### Duration

```dart
fast:   150ms  // hover, 작은 변화
normal: 200ms  // 버튼, 탭 전환
medium: 300ms  // 페이지 전환, 다이얼로그
slow:   400ms  // 복잡한 애니메이션
```

### Curves

```dart
standard: Curves.easeInOut
enter:    Curves.easeOut
exit:     Curves.easeIn
emphasis: Curves.easeOutCubic
```

### 적용 예시

```dart
// 버튼 탭
scale: 1.0 → 0.95 → 1.0, 150ms

// 다이얼로그 열기
fade + scale(0.8→1.0), 200ms, easeOutCubic

// 바텀시트
slide up, 300ms, easeOutCubic

// 스낵바
slide up + fade, 250ms
```

---

## 일관성 규칙

### 필수 사항

- [ ] 색상: 디자인 토큰 변수 사용
- [ ] 크기: spacing/radius 토큰 사용
- [ ] 버튼: Elevated/Outlined/Text 중 선택
- [ ] 다이얼로그: AppDialog 또는 DialogUtils 사용
- [ ] 토스트: SnackBarUtils 사용
- [ ] 애니메이션: 표준 duration/curve 사용
- [ ] 터치 영역: 최소 44x44px

### 금지 사항

```dart
// 색상 하드코딩
color: Color(0xFF2E7D32)  // ❌
color: colorScheme.primary // ✅

// 임의 크기
padding: EdgeInsets.all(17)     // ❌
padding: EdgeInsets.all(Spacing.md) // ✅

// 직접 SnackBar 생성
ScaffoldMessenger.of(context).showSnackBar(...) // ❌
SnackBarUtils.showSuccess(context, message)     // ✅
```

---

## pencil.dev 컴포넌트 ID 참조

### 재사용 컴포넌트

| ID | 이름 | 용도 |
|------|------|------|
| ls6bL | Button/Elevated | Primary 버튼 |
| xEqEW | Button/Outlined | Secondary 버튼 |
| euXXC | Button/Text | Text 버튼 |
| XZW46 | TextField | 입력 필드 |
| tXmOp | FAB | 플로팅 버튼 |
| 2FI3b | AppBar | 앱바 |
| 5DojV | AppCard | 카드 |
| fz2Eq | SectionHeader | 섹션 헤더 |
| ipAry | EmptyState | 빈 상태 |

### 개선 디자인 페이지 (x=10000+)

| ID | 이름 | x 좌표 |
|------|------|------|
| improved-login | LoginPage (개선) | 10000 |
| improved-cal-month | CalendarMonth (개선) | 10400 |
| improved-cal-week | CalendarWeek (개선) | 10800 |
| improved-cal-day | CalendarDay (개선) | 11200 |
| improved-stats | StatisticsPage (개선) | 12536 |
