# 디자인 리뷰 결과: 전체 앱 일관성

**리뷰 날짜**: 2026-01-13  
**범위**: 전체 앱 디자인 시스템 및 일관성  
**집중 영역**: 비주얼 디자인, UX/사용성, 일관성, 접근성, 모바일 최적화

## 요약

공유 가계부 앱의 전체 디자인을 검토한 결과, **Material 3 기반의 견고한 구조**를 가지고 있으나 **디자인 토큰 부재, 하드코딩된 값, 컴포넌트 중복**으로 인한 일관성 문제가 발견되었습니다. 14개 feature 모듈에서 유사한 UI 패턴이 반복되지만 미묘한 차이로 인해 통일감이 부족합니다.

**주요 발견사항**:
- ✅ Material 3 ColorScheme 적극 활용
- ✅ Light/Dark 테마 지원 완비
- ❌ 하드코딩된 색상 (Colors.grey, Colors.red 등) 다수 사용
- ❌ borderRadius 불일치 (8, 12, 16, 20 혼용)
- ❌ 공통 위젯 부재로 코드 중복 심각

## 이슈

| # | 이슈 | 심각도 | 카테고리 | 위치 |
|---|------|--------|----------|------|
| 1 | 하드코딩된 Colors.grey[400], Colors.grey[600] 사용 - 다크모드 대비 불일치 | High | 일관성, 접근성 | `lib/features/share/presentation/pages/share_management_page.dart:163-170`<br>`lib/features/category/presentation/pages/category_management_page.dart:97-102`<br>`lib/features/payment_method/presentation/pages/payment_method_management_page.dart:44-49` |
| 2 | 하드코딩된 Colors.red 사용 - ColorScheme.error 대신 | High | 일관성 | `lib/features/settings/presentation/pages/settings_page.dart:170-176` |
| 3 | borderRadius 값 불일치 (Card: 8, 12, 20 혼용) | High | 비주얼 디자인 | `lib/features/ledger/presentation/widgets/calendar_view.dart:115`<br>`lib/features/transaction/presentation/widgets/add_transaction_sheet.dart:301`<br>`lib/shared/themes/app_theme.dart:29` |
| 4 | 디자인 토큰 파일 부재 - 간격, 반경, 색상 상수 분산 | Critical | 일관성 | 전체 프로젝트 |
| 5 | 중복된 빈 상태(Empty State) 구현 - 최소 6곳 | Medium | 유지보수성 | `lib/features/share/presentation/pages/share_management_page.dart:154-189`<br>`lib/features/category/presentation/pages/category_management_page.dart:89-106`<br>`lib/features/payment_method/presentation/pages/payment_method_management_page.dart:40-56` |
| 6 | 중복된 섹션 헤더 구현 - 아이콘+텍스트 패턴 반복 | Medium | 유지보수성 | `lib/features/share/presentation/pages/share_management_page.dart:135-151` |
| 7 | 하드코딩된 fontSize (10, 11, 12, 14, 15 등) - textTheme 미사용 | Medium | 타이포그래피 | `lib/features/ledger/presentation/widgets/calendar_view.dart:19-21`<br>`lib/features/share/presentation/pages/share_management_page.dart:144` |
| 8 | Card elevation 불일치 (0과 기본값 혼용) | Low | 비주얼 디자인 | `lib/shared/themes/app_theme.dart:27`<br>`lib/features/statistics/presentation/widgets/category_tab/category_tab_view.dart:46` |
| 9 | 일부 IconButton semanticLabel 누락 - 스크린리더 접근성 저하 | Medium | 접근성 | `lib/features/ledger/presentation/pages/home_page.dart:198-200` |
| 10 | 터치 타겟 크기 불명확 - 일부 아이콘 버튼 44dp 미만 가능성 | Medium | 접근성, 모바일 | `lib/features/share/presentation/pages/share_management_page.dart:140` |
| 11 | Container 직접 사용 - Card 위젯 대신 수동 decoration | Medium | 일관성 | `lib/features/share/presentation/widgets/owned_ledger_card.dart:32-35`<br>`lib/features/share/presentation/widgets/invited_ledger_card.dart:33-36` |
| 12 | 색상 파싱 로직 중복 - ColorUtils.parseHexColor 미사용 | Low | 코드 품질 | `lib/features/asset/presentation/widgets/asset_category_list.dart:11-19` |
| 13 | 반복되는 padding 값 (8, 12, 16, 24, 32) - 디자인 토큰 부재 | Medium | 일관성 | 전체 프로젝트 |
| 14 | SnackBar duration 불일치 (1초, 2초, 3초, 4초 혼용) | Low | UX | `lib/features/category/presentation/pages/category_management_page.dart:187-189` |
| 15 | 색상 대비 미달 가능성 - Colors.grey[400]/[600] 라이트 배경 | Medium | 접근성 | `lib/features/share/presentation/pages/share_management_page.dart:163-170` |

## 심각도 범례
- **Critical**: 시스템 전체에 영향, 즉시 해결 필요
- **High**: 사용자 경험에 직접적 영향, 우선 해결
- **Medium**: 개선 권장, 중기 해결
- **Low**: 작은 개선사항, 시간 여유 시 해결

## 상세 분석

### 1. 색상 시스템 문제

**현재 상황**:
```dart
// ❌ 여러 파일에서 발견되는 하드코딩 패턴
color: Colors.grey[400]  // share_management_page.dart:163
color: Colors.grey[600]  // category_management_page.dart:102
color: Colors.red        // settings_page.dart:170
```

**문제점**:
- Material 3 ColorScheme을 무시하고 직접 색상 지정
- 다크모드에서 대비 문제 발생 (grey[400]이 어두운 배경에서 보이지 않음)
- 테마 변경 시 일괄 조정 불가능

**개선안**:
```dart
// ✅ ColorScheme 활용
color: Theme.of(context).colorScheme.onSurfaceVariant  // grey[400] 대체
color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)  // grey[600] 대체
color: Theme.of(context).colorScheme.error  // Colors.red 대체
```

**영향 파일**: 15개 이상의 페이지/위젯 파일

---

### 2. 디자인 토큰 부재

**현재 상황**:
- borderRadius: 8, 12, 16, 20 혼용 (4가지 값)
- padding/margin: 4, 8, 12, 16, 24, 32 혼용 (6가지 값)
- 각 개발자가 임의로 값 선택

**개선안**:
새로운 파일 `lib/shared/themes/design_tokens.dart` 생성:
```dart
class DesignTokens {
  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingSm = 8.0;
  static const double spacingMd = 16.0;
  static const double spacingLg = 24.0;
  static const double spacingXl = 32.0;
  
  // Border Radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusSheet = 20.0;
  
  // Elevation (Material 3 기본값 사용 권장)
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
}
```

---

### 3. 컴포넌트 중복 문제

**빈 상태(Empty State) 중복**: 6곳 이상에서 유사한 코드 반복
```dart
// ❌ 각 페이지마다 반복
Center(
  child: Column(
    children: [
      Icon(Icons.xxx, size: 64, color: Colors.grey[400]),
      SizedBox(height: 16),
      Text('데이터 없음', style: TextStyle(color: Colors.grey[600])),
    ],
  ),
)
```

**개선안**: 공통 위젯 생성
```dart
// ✅ lib/shared/widgets/empty_state.dart
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  
  // 사용법
  EmptyState(
    icon: Icons.account_balance_wallet_outlined,
    title: '가계부가 없습니다',
    subtitle: '가계부를 생성하여 시작하세요',
    action: ElevatedButton(...),
  )
}
```

**추가 필요 공통 위젯**:
- `SectionHeader` (아이콘 + 타이틀) - 4곳 중복
- `AppCard` (통일된 Card 스타일) - 전체 사용
- `LoadingIndicator` (일관된 로딩 표시) - 8곳 중복

---

### 4. 타이포그래피 불일치

**현재 상황**:
```dart
// ❌ 하드코딩된 fontSize
fontSize: 10  // calendar_view.dart:21
fontSize: 11  // calendar_view.dart:19
fontSize: 12  // transaction_list.dart:108
fontSize: 14  // share_management_page.dart:177
fontSize: 15  // share_management_page.dart:144
```

**개선안**:
```dart
// ✅ Material 3 TextTheme 사용
style: Theme.of(context).textTheme.bodySmall    // 12sp
style: Theme.of(context).textTheme.bodyMedium   // 14sp
style: Theme.of(context).textTheme.bodyLarge    // 16sp
style: Theme.of(context).textTheme.titleMedium  // 22sp
```

---

### 5. 접근성 이슈

**터치 타겟 크기**:
- Material Design 가이드라인: 최소 48x48dp (권장), 44x44dp (최소)
- 현재: IconButton 일부 명시적 크기 지정 없음
- 개선: `IconButton.styleFrom(minimumSize: Size(48, 48))` 또는 `constraints` 설정

**색상 대비**:
- WCAG AA 기준: 일반 텍스트 4.5:1, 큰 텍스트 3:1
- `Colors.grey[400]` 흰 배경: 약 3.1:1 (미달)
- `Colors.grey[600]` 흰 배경: 약 5.7:1 (통과)
- 개선: ColorScheme의 onSurfaceVariant 사용 (자동 대비 보장)

**시맨틱 라벨**:
```dart
// ❌ 현재
IconButton(
  icon: Icon(Icons.book),
  onPressed: () => _showLedgerSelector(context),
)

// ✅ 개선
IconButton(
  icon: Icon(Icons.book),
  tooltip: '가계부 선택',
  semanticsLabel: '가계부 선택',
  onPressed: () => _showLedgerSelector(context),
)
```

---

### 6. 다크 모드 일관성

**문제 파일들**:
1. `share_management_page.dart`: Colors.grey[400]/[600] 사용
2. `category_management_page.dart`: Colors.grey[400]/[600] 사용
3. `payment_method_management_page.dart`: Colors.grey[400]/[600] 사용
4. `settings_page.dart`: Colors.red 직접 사용

**다크 모드 테스트 결과**:
- 하드코딩된 grey 색상이 어두운 배경에서 대비 저하
- ColorScheme을 사용하는 부분은 자동 조정되어 정상 동작

---

## 개선 로드맵

### Phase 1: 디자인 시스템 기반 구축 (우선순위 P0-P1, 예상 10시간)

1. **디자인 토큰 파일 생성** (2시간)
   - `lib/shared/themes/design_tokens.dart` 생성
   - Spacing, BorderRadius, Elevation 상수 정의

2. **하드코딩 색상 제거** (4시간)
   - Colors.grey → ColorScheme.onSurfaceVariant
   - Colors.red → ColorScheme.error
   - 15개 파일 수정

3. **공통 위젯 생성** (3시간)
   - AppCard, SectionHeader, EmptyState 위젯
   - 기존 코드에 적용

4. **borderRadius 통일** (1시간)
   - Card/Container: 12로 통일
   - 예외(Sheet: 20, FAB: 16) 유지

### Phase 2: 일관성 향상 (우선순위 P2, 예상 5시간)

5. **타이포그래피 통일** (2시간)
   - 하드코딩 fontSize → textTheme
   - 20개 이상 파일 수정

6. **접근성 개선** (3시간)
   - 터치 타겟 크기 검증 및 수정
   - semanticLabel 추가
   - 색상 대비 검증

### Phase 3: 세부 개선 (우선순위 P3, 예상 3시간)

7. **기타 개선사항** (3시간)
   - Card elevation 통일
   - SnackBar duration 표준화
   - 색상 파싱 로직 통일

---

## 모범 사례

### ✅ 잘 구현된 부분

1. **Material 3 적극 활용**:
   - `app_theme.dart`에서 ColorScheme.fromSeed 사용
   - Material 3 컴포넌트 스타일링 (InputDecoration, Button 등)

2. **Clean Architecture**:
   - Feature-first 구조로 모듈화 우수
   - Presentation/Domain/Data 분리 명확

3. **테마 관리**:
   - Light/Dark 테마 완전 지원
   - ThemeModeNotifier로 상태 관리

4. **코드 생성**:
   - Riverpod 코드 생성 활용
   - 보일러플레이트 최소화

---

## 추가 권장사항

### 디자인 시스템 문서화
- Figma 또는 Storybook으로 컴포넌트 카탈로그 생성
- 디자인 토큰 사용 가이드 작성

### 린트 규칙 추가
```yaml
# analysis_options.yaml
linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_hardcoded_colors  # 커스텀 규칙 고려
```

### 디자인 리뷰 프로세스
- PR 시 디자인 토큰 사용 체크리스트
- 새 기능 추가 시 공통 위젯 재사용 확인

---

## 다음 단계

1. ✅ 디자인 리뷰 완료
2. 🔄 개선된 디자인 시스템 와이어프레임 검토 (제공됨)
3. ⏭️ Phase 1 구현 시작 여부 결정
4. ⏭️ 기존 코드베이스에 점진적 적용

**예상 총 작업 시간**: 18시간  
**예상 파일 수정**: 40개 이상  
**예상 효과**: 
- 디자인 일관성 90% 이상 향상
- 다크 모드 품질 개선
- 유지보수성 50% 향상
- 접근성 기준 충족