# Phase 1: 디자인 시스템 기반 구축 - 상세 실행 계획

**생성일**: 2026-01-14
**기반 문서**: `.kombai/resources/design-review-app-consistency-1705123456.md`
**목표**: 디자인 토큰 정의 → 하드코딩 제거 → 공통 위젯 생성 → borderRadius 통일
**예상 시간**: 10시간
**영향 파일 수**: 약 50개

---

## 📊 Explore Agents 분석 결과 요약

### 1. BorderRadius 현황 (bg_e4904268)
- **총 파일**: 23개
- **총 인스턴스**: 155개 (BorderRadius.circular 78개 + Radius.circular 77개)
- **고유 값**: 12 (34회), 8 (19회), 20 (3회), 16 (3회), 4 (4회), 2 (5회), 10 (1회), 1 (1회)
- **비표준 값**: 1, 2, 10 → 제거 필요

### 2. Empty State 현황 (bg_66f7c029)
- **총 위치**: 13개
- **Pattern 1 (Icon 64px)**: 9곳 (search, asset_goal, transaction_list, daily_breakdown, fixed_expense, category, payment_method, ledger, share)
- **Pattern 2 (Icon 32px)**: 1곳 (asset_page)
- **Pattern 3 (Text only)**: 3곳 (차트 위젯들)
- **중복 코드**: 평균 15-20줄 × 13곳 = 약 200줄 중복

### 3. Section Header 현황 (bg_c60f5ba4)
- **총 구현**: 5개 (share_management: Row+Icon+Text, settings/notification/fixed_expense: Text-only, asset: Card-based)
- **총 사용**: 12곳
- **가장 기능적**: share_management_page의 Row+Icon+Text 패턴

### 4. Hardcoded fontSize 현황 (bg_7d48dbe6)
- **총 위치**: 65개 (18개 파일)
- **빈도**: 12 (18회), 16 (8회), 13 (8회), 11 (8회), 10 (7회), 24 (4회), 14 (6회), 20 (2회), 18 (2회), 15 (1회), 9 (1회)
- **리팩토링 우선순위**: P0 (24, 20, 18), P1 (16, 14, 13), P2 (12, 11, 10)

---

## 🎯 Task 1: 디자인 토큰 파일 생성 (2시간)

### 1.1 파일 생성
**담당**: **직접 처리** (순수 로직, 상수 정의)
**생성 파일**: `lib/shared/themes/design_tokens.dart`

**내용**:
```dart
/// 앱 전체의 디자인 토큰 정의
/// 
/// 사용 예시:
/// ```dart
/// padding: EdgeInsets.all(DesignTokens.spacingMd)
/// borderRadius: BorderRadius.circular(DesignTokens.radiusMedium)
/// ```
class DesignTokens {
  DesignTokens._();
  
  // ========== Spacing ==========
  /// 4dp - 최소 간격 (아이콘 내부, Chip 패딩, 차트 바 간격)
  static const double spacingXs = 4.0;
  
  /// 8dp - 작은 간격 (리스트 아이템 내부, 작은 요소 간격)
  static const double spacingSm = 8.0;
  
  /// 16dp - 기본 간격 (컨테이너 패딩, 섹션 간격)
  static const double spacingMd = 16.0;
  
  /// 24dp - 큰 간격 (섹션 간 여백, 페이지 상단 여백)
  static const double spacingLg = 24.0;
  
  /// 32dp - 매우 큰 간격 (주요 섹션 구분, 상단 히어로 영역)
  static const double spacingXl = 32.0;
  
  // ========== Border Radius ==========
  /// 4dp - 매우 작은 요소 (차트 바, 통계 인디케이터)
  static const double radiusXs = 4.0;
  
  /// 8dp - 작은 요소 (Chip, Tag, SnackBar)
  static const double radiusSmall = 8.0;
  
  /// 12dp - 기본값 (Card, Container, Button, TextField)
  static const double radiusMedium = 12.0;
  
  /// 16dp - FAB 전용
  static const double radiusFab = 16.0;
  
  /// 20dp - Sheet 전용 (BottomSheet, ModalBottomSheet)
  static const double radiusSheet = 20.0;
  
  // ========== Elevation ==========
  /// Material 3 elevation 레벨
  static const double elevationNone = 0.0;
  static const double elevationLow = 1.0;
  static const double elevationMedium = 2.0;
  static const double elevationHigh = 3.0;
  
  // ========== Icon Sizes ==========
  /// 매우 작은 아이콘 (리스트 보조 아이콘)
  static const double iconSizeXs = 16.0;
  
  /// 작은 아이콘 (섹션 헤더)
  static const double iconSizeSmall = 20.0;
  
  /// 기본 아이콘 (버튼, 앱바)
  static const double iconSizeMedium = 24.0;
  
  /// 중간 크기 아이콘 (일부 Empty State)
  static const double iconSizeLg = 32.0;
  
  /// 큰 아이콘 (Empty State)
  static const double iconSizeLarge = 64.0;
  
  // ========== Touch Target ==========
  /// 최소 터치 영역 크기 (Material Design 가이드라인)
  static const double minTouchTarget = 48.0;
}
```

### 1.2 Export 추가
**수정 파일**: `lib/shared/shared.dart` (새로 생성 또는 기존 수정)

```dart
// Themes
export 'themes/app_theme.dart';
export 'themes/theme_provider.dart';
export 'themes/design_tokens.dart';

// Widgets
export 'widgets/color_picker.dart';
```

### 1.3 검증 단계
- [ ] `flutter analyze` 실행 → 에러 없음
- [ ] Import 테스트 (`import 'package:house_hold_account/shared/themes/design_tokens.dart'`)
- [ ] 상수 접근 테스트 (`DesignTokens.spacingMd`)

**의존성**: 없음 (독립 실행 가능)
**예상 시간**: 30분

---

## 🎨 Task 2: 하드코딩 색상 제거 (4시간)

### 2.1 색상 매핑 정의

| 하드코딩 색상 | 대체 ColorScheme | 용도 | 파일 수 |
|--------------|-----------------|------|---------|
| `Colors.grey[400]` | `colorScheme.onSurfaceVariant` | 비활성 아이콘, 빈 상태 | 8곳 |
| `Colors.grey[600]` | `colorScheme.onSurface.withOpacity(0.6)` | 부제목, 설명 텍스트 | 15곳 |
| `Colors.grey[500]` | `colorScheme.onSurfaceVariant` | 중간 회색 | 6곳 |
| `Colors.grey[200]` | `colorScheme.surfaceContainerHighest` | 배경, 구분선 | 1곳 |
| `Colors.grey[300]` | `colorScheme.surfaceContainerHigh` | 비활성 배경 | 1곳 |
| `Colors.grey[700]` | `colorScheme.onSurface.withOpacity(0.8)` | 진한 텍스트 | 1곳 |
| `Colors.red` | `colorScheme.error` | 에러, 삭제 버튼 | 8곳 |
| `Colors.red[400]` | `colorScheme.error` | 에러 상태 | 1곳 |
| `Colors.blue` | `colorScheme.primary` | 수입 | 5곳 |
| `Colors.green` | `colorScheme.tertiary` | 저축/자산 | 6곳 |
| `Colors.orange` | `colorScheme.secondary` | 경고, 초대 | 3곳 |

**총 변경 위치**: 26개 파일, 118개 인스턴스

### 2.2 영향 파일 우선순위

**Priority 1 - High (11개 파일, 44개 인스턴스)**:
1. `lib/features/share/presentation/widgets/owned_ledger_card.dart` (14곳)
2. `lib/features/share/presentation/pages/share_management_page.dart` (9곳)
3. `lib/features/share/presentation/widgets/invited_ledger_card.dart` (8곳)
4. `lib/features/ledger/presentation/pages/ledger_management_page.dart` (11곳)
5. `lib/features/search/presentation/pages/search_page.dart` (7곳)
6. `lib/features/asset/presentation/widgets/asset_goal_card.dart` (6곳)
7. `lib/features/settings/presentation/pages/settings_page.dart` (4곳)
8. `lib/features/asset/presentation/pages/asset_page.dart` (4곳)
9. `lib/features/category/presentation/pages/category_management_page.dart` (2곳)
10. `lib/features/payment_method/presentation/pages/payment_method_management_page.dart` (2곳)
11. `lib/features/fixed_expense/presentation/pages/fixed_expense_management_page.dart` (2곳)

**Priority 2 - Medium (8개 파일, 차트 위젯)**:
- `category_summary_card.dart`, `trend_bar_chart.dart`, `trend_detail_list.dart`, `category_ranking_list.dart`, `category_donut_chart.dart`, `payment_method_list.dart`, `payment_method_donut_chart.dart`, `asset_donut_chart.dart`, `asset_category_list.dart`

**Priority 3 - Low (7개 파일, 단일 색상)**:
- `transaction_detail_sheet.dart`, `recurring_settings_widget.dart`, `transaction_list.dart`, `daily_category_breakdown_sheet.dart`, `home_page.dart`, `calendar_view.dart`

### 2.3 작업 분할

**담당**: **frontend-ui-ux-engineer** (시각적 검증 필수)

**Agent 작업 지시서 템플릿**:
```
Task: Remove hardcoded Colors in [파일명]

Input Files:
- Target: lib/features/[feature]/presentation/[pages|widgets]/[파일명].dart
- Reference: lib/shared/themes/design_tokens.dart
- Theme: lib/shared/themes/app_theme.dart

Color Mapping:
[위 2.1 매핑 테이블 첨부]

Requirements:
1. Replace ALL hardcoded Colors.grey[xxx] with appropriate ColorScheme properties
2. Replace ALL hardcoded Colors.red with colorScheme.error
3. Replace chart colors (blue, green, red) with ColorScheme properties while maintaining dark mode compatibility
4. Ensure Theme.of(context) is accessible in all locations
5. Test both light and dark mode visually

Output:
- Modified file path
- List of changed lines with before/after
- Screenshot comparison (light mode, dark mode)
- Confirmation: "All hardcoded Colors removed"

Constraints:
- DO NOT change ColorPicker widget (user-selected HEX colors)
- DO NOT change parseHexColor() utility function
- Maintain existing behavior and visual appearance
```

**작업 순서** (3단계):
1. **Phase 2A**: Priority 1 파일 11개 (2시간)
2. **Phase 2B**: Priority 2 차트 파일 9개 (1시간)
3. **Phase 2C**: Priority 3 파일 7개 (1시간)

### 2.4 검증 단계
- [ ] 컴파일: `flutter analyze` 에러 없음
- [ ] 시각 검증 (라이트 모드): 모든 변경 페이지 스크린샷
- [ ] 시각 검증 (다크 모드): 모든 변경 페이지 스크린샷
- [ ] 색상 대비: WCAG AA 기준 충족 확인 (4.5:1 이상)
- [ ] 기능 검증: 버튼 클릭, 네비게이션 등 기존 동작 유지
- [ ] Grep 검증: `grep -r "Colors\.grey\[" lib/` 결과 0개

**의존성**: Task 1 완료
**예상 시간**: 4시간

---

## 🧩 Task 3: 공통 위젯 생성 (3시간)

### 3.1 EmptyState 위젯

**생성 파일**: `lib/shared/widgets/empty_state.dart`
**담당**: **frontend-ui-ux-engineer** (UI 컴포넌트)

**적용 대상** (13곳):
1. `search_page.dart` (2곳: 초기 상태, 결과 없음)
2. `asset_goal_card.dart` (1곳)
3. `transaction_list.dart` (1곳: _EmptyState 클래스 교체)
4. `daily_category_breakdown_sheet.dart` (1곳: _buildEmptyState 교체)
5. `fixed_expense_management_page.dart` (1곳)
6. `category_management_page.dart` (1곳)
7. `payment_method_management_page.dart` (1곳)
8. `ledger_management_page.dart` (1곳)
9. `share_management_page.dart` (1곳: _buildEmptyState 교체)
10. `asset_page.dart` (1곳)
11. `category_donut_chart.dart` (1곳: Text-only)
12. `payment_method_donut_chart.dart` (1곳: Text-only)
13. `trend_bar_chart.dart` (2곳: 월별, 연도별)

**위젯 코드**:
```dart
import 'package:flutter/material.dart';
import '../themes/design_tokens.dart';

/// 빈 상태를 표시하는 공통 위젯
/// 
/// 세 가지 변형을 지원:
/// 1. 기본 (Icon 64px + Title + Subtitle + Action)
/// 2. 중간 (Icon 32px + Title + Subtitle)
/// 3. Text-only (차트용)
/// 
/// 사용 예시:
/// ```dart
/// // 기본 변형
/// EmptyState(
///   icon: Icons.account_balance_wallet_outlined,
///   title: '가계부가 없습니다',
///   subtitle: '가계부를 생성하여 시작하세요',
///   action: ElevatedButton(...),
/// )
/// 
/// // 차트용 변형
/// EmptyState.chart(
///   message: '데이터가 없습니다',
///   height: 250,
/// )
/// ```
class EmptyState extends StatelessWidget {
  /// 표시할 아이콘
  final IconData? icon;
  
  /// 주 제목 (필수)
  final String title;
  
  /// 부제목 (선택)
  final String? subtitle;
  
  /// 액션 버튼 (선택)
  final Widget? action;
  
  /// 아이콘 크기 (기본값: 64)
  final double iconSize;

  const EmptyState({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.iconSize = DesignTokens.iconSizeLarge,
  });
  
  /// 차트용 간단한 Empty State
  const EmptyState.chart({
    super.key,
    required String message,
    double? height,
  }) : icon = null,
       title = message,
       subtitle = null,
       action = null,
       iconSize = 0;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    // 차트용 간단한 변형
    if (icon == null && subtitle == null && action == null) {
      return Center(
        child: Text(
          title,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: iconSize,
              color: colorScheme.onSurfaceVariant,
            ),
          if (icon != null)
            const SizedBox(height: DesignTokens.spacingMd),
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: DesignTokens.spacingSm),
            Text(
              subtitle!,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: DesignTokens.spacingLg),
            action!,
          ],
        ],
      ),
    );
  }
}
```

**삭제 예상 코드**: 약 200줄 (15줄 × 13곳)

### 3.2 SectionHeader 위젯

**생성 파일**: `lib/shared/widgets/section_header.dart`
**담당**: **frontend-ui-ux-engineer**

**적용 대상** (12곳):
- share_management_page.dart (2곳)
- settings_page.dart (4곳)
- notification_settings_page.dart (2곳)
- fixed_expense_management_page.dart (1곳)
- asset_page.dart (3곳, Card 변형)

**위젯 코드**:
```dart
import 'package:flutter/material.dart';
import '../themes/design_tokens.dart';

/// 섹션 헤더 위젯
/// 
/// 두 가지 변형:
/// 1. Icon + Text (기본)
/// 2. Text-only
/// 
/// 사용 예시:
/// ```dart
/// // Icon + Text
/// SectionHeader(
///   icon: Icons.group,
///   title: '초대한 사람',
///   trailing: IconButton(...),
/// )
/// 
/// // Text-only
/// SectionHeader(
///   title: '앱 설정',
/// )
/// ```
class SectionHeader extends StatelessWidget {
  /// 아이콘 (선택)
  final IconData? icon;
  
  /// 섹션 타이틀 (필수)
  final String title;
  
  /// 우측 위젯 (선택)
  final Widget? trailing;
  
  /// 텍스트 스타일 (기본값: titleSmall)
  final TextStyle? textStyle;

  const SectionHeader({
    super.key,
    this.icon,
    required this.title,
    this.trailing,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTextStyle = textStyle ?? 
      theme.textTheme.titleSmall?.copyWith(
        color: colorScheme.primary,
        fontWeight: FontWeight.bold,
      );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DesignTokens.spacingMd,
        DesignTokens.spacingMd,
        DesignTokens.spacingMd,
        DesignTokens.spacingSm,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon, 
              size: DesignTokens.iconSizeSmall,
              color: colorScheme.primary,
            ),
            const SizedBox(width: DesignTokens.spacingSm),
          ],
          Text(title, style: effectiveTextStyle),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}
```

**삭제할 클래스**:
- `_SectionHeader` (settings_page.dart, notification_settings_page.dart, fixed_expense_management_page.dart)
- `_buildSectionHeader` 메서드 (share_management_page.dart)

### 3.3 AppCard 위젯

**생성 파일**: `lib/shared/widgets/app_card.dart`
**담당**: **frontend-ui-ux-engineer**

**적용 대상**:
- `owned_ledger_card.dart`, `invited_ledger_card.dart` (Container를 Card로 교체)
- 기타 직접 Container + BoxDecoration 사용하는 카드형 위젯

**위젯 코드**:
```dart
import 'package:flutter/material.dart';
import '../themes/design_tokens.dart';

/// 앱 전체에서 사용하는 통일된 Card 위젯
/// 
/// Material 3 Card 스타일을 강제하여 일관성 유지
/// 
/// 사용 예시:
/// ```dart
/// AppCard(
///   child: ListTile(...),
///   onTap: () => ...,
///   margin: EdgeInsets.all(16),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// 카드 내용 (필수)
  final Widget child;
  
  /// 탭 이벤트 (선택)
  final VoidCallback? onTap;
  
  /// 마진 (기본값: EdgeInsets.zero)
  final EdgeInsetsGeometry? margin;
  
  /// 패딩 (기본값: EdgeInsets.zero)
  final EdgeInsetsGeometry? padding;
  
  /// 커스텀 elevation (기본값: DesignTokens.elevationNone)
  final double? elevation;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final card = Card(
      margin: margin ?? EdgeInsets.zero,
      elevation: elevation ?? DesignTokens.elevationNone,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: padding != null
          ? Padding(padding: padding!, child: child)
          : child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignTokens.radiusMedium),
        child: card,
      );
    }

    return card;
  }
}
```

### 3.4 Barrel Export 추가

**수정 파일**: `lib/shared/widgets/widgets.dart` (새로 생성)

```dart
export 'empty_state.dart';
export 'section_header.dart';
export 'app_card.dart';
export 'color_picker.dart';
```

**수정 파일**: `lib/shared/shared.dart`
```dart
// Themes
export 'themes/app_theme.dart';
export 'themes/theme_provider.dart';
export 'themes/design_tokens.dart';

// Widgets
export 'widgets/widgets.dart';
```

### 3.5 검증 단계
- [ ] 컴파일: `flutter analyze` 에러 없음
- [ ] 시각 검증 (라이트): EmptyState 13곳, SectionHeader 12곳, AppCard 적용 위치
- [ ] 시각 검증 (다크): 동일
- [ ] 코드 중복 감소: 약 200줄 → 150줄 (EmptyState 위젯 1개)
- [ ] 기존 UI 동일: 픽셀 단위 비교 (스크린샷)

**의존성**: Task 1, 2 완료
**예상 시간**: 3시간

---

## 📐 Task 4: borderRadius 통일 (1시간)

### 4.1 변경 규칙

**담당**: **직접 처리** (규칙 기반 변경)

**Explore Agent 분석 결과**:
- **총 파일**: 23개
- **총 인스턴스**: 155개
- **비표준 값 제거**: 1 (1곳), 2 (5곳), 10 (1곳)
- **표준 값 매핑**: 4 → radiusXs, 8 → radiusSmall, 12 → radiusMedium, 16 → radiusFab, 20 → radiusSheet

| 위젯 타입 | 기존 값 | 새 값 | DesignTokens | 파일 수 |
|----------|--------|-------|--------------|---------|
| Card | 12 | 12 | `radiusMedium` | 이미 통일됨 (app_theme.dart) |
| Container (카드형) | 8, 12 | 12 | `radiusMedium` | 2개 |
| Sheet | 20 | 20 | `radiusSheet` | 3개 (예외 유지) |
| FAB | 16 | 16 | `radiusFab` | 1개 (예외 유지) |
| SnackBar | 8 | 8 | `radiusSmall` | 1개 (예외 유지) |
| 차트 바 | 4 | 4 | `radiusXs` | 4개 (예외 유지) |
| 비표준 | 1, 2, 10 | 4 or 8 | `radiusXs` or `radiusSmall` | 7개 |

### 4.2 변경 대상 파일 (우선순위별)

**Priority 1 - 비표준 값 제거 (3개 파일)**:
1. `asset_page.dart` - borderRadius: 1, 2 → 4 (radiusXs)
2. `asset_goal_card.dart` - borderRadius: 10 → 8 (radiusSmall)
3. `asset_goal_form_sheet.dart` - borderRadius: 2 → 4 (radiusXs)
4. `transaction_detail_sheet.dart` - borderRadius: 2 → 4 (radiusXs)
5. `add_transaction_sheet.dart` - borderRadius: 2 → 4 (radiusXs)
6. `edit_transaction_sheet.dart` - borderRadius: 2 → 4 (radiusXs)

**Priority 2 - 하드코딩 제거 (20개 파일)**:
- 모든 `BorderRadius.circular(12)` → `BorderRadius.circular(DesignTokens.radiusMedium)`
- 모든 `BorderRadius.circular(8)` → `BorderRadius.circular(DesignTokens.radiusSmall)`
- 모든 `BorderRadius.circular(20)` → `BorderRadius.circular(DesignTokens.radiusSheet)`
- 모든 `BorderRadius.circular(16)` → `BorderRadius.circular(DesignTokens.radiusFab)`
- 모든 `BorderRadius.circular(4)` → `BorderRadius.circular(DesignTokens.radiusXs)`

### 4.3 AST-Grep 패턴 검색 및 변경

**검색 명령어**:
```bash
# 비표준 값 찾기
rg "BorderRadius\.circular\((1|2|10)\)" lib/
rg "Radius\.circular\((1|2|10)\)" lib/

# 모든 borderRadius 찾기 (수동 검증용)
rg "BorderRadius\.circular\([0-9]+\)" lib/ | wc -l
```

**일괄 변경 스크립트** (수동 실행):
```bash
# 1단계: 비표준 값 수정 (수동 확인 후 적용)
# asset_page.dart, asset_goal_card.dart 등

# 2단계: 하드코딩 → DesignTokens 변경
find lib/ -name "*.dart" -exec sed -i '' \
  -e 's/BorderRadius\.circular(12)/BorderRadius.circular(DesignTokens.radiusMedium)/g' \
  -e 's/BorderRadius\.circular(8)/BorderRadius.circular(DesignTokens.radiusSmall)/g' \
  -e 's/BorderRadius\.circular(20)/BorderRadius.circular(DesignTokens.radiusSheet)/g' \
  -e 's/BorderRadius\.circular(16)/BorderRadius.circular(DesignTokens.radiusFab)/g' \
  -e 's/BorderRadius\.circular(4)/BorderRadius.circular(DesignTokens.radiusXs)/g' \
  -e 's/Radius\.circular(12)/Radius.circular(DesignTokens.radiusMedium)/g' \
  -e 's/Radius\.circular(8)/Radius.circular(DesignTokens.radiusSmall)/g' \
  -e 's/Radius\.circular(20)/Radius.circular(DesignTokens.radiusSheet)/g' \
  -e 's/Radius\.circular(16)/Radius.circular(DesignTokens.radiusFab)/g' \
  -e 's/Radius\.circular(4)/Radius.circular(DesignTokens.radiusXs)/g' \
  {} \;

# 3단계: Import 추가 (필요한 파일만)
# import 'package:house_hold_account/shared/themes/design_tokens.dart';
```

**주의사항**:
- 일괄 변경 전 Git commit 필수
- 변경 후 `flutter analyze` 실행하여 import 누락 확인
- Sheet, FAB, SnackBar는 예외 유지 확인

### 4.4 검증 단계
- [ ] 컴파일: `flutter analyze` 에러 없음
- [ ] Import 확인: 모든 파일에 `design_tokens.dart` import 추가
- [ ] 시각 검증: Card 모서리 일관성 (12), Sheet 상단 모서리 (20)
- [ ] Grep 검증:
  - `rg "BorderRadius\.circular\((1|2|10)\)" lib/` → 0건
  - `rg "BorderRadius\.circular\([0-9]+\)" lib/` → DesignTokens 사용 확인
- [ ] 통계 비교:
  - 변경 전: 고유 값 8개 (1, 2, 4, 8, 10, 12, 16, 20)
  - 변경 후: 5개 (4, 8, 12, 16, 20) via DesignTokens

**의존성**: Task 1 완료
**예상 시간**: 1시간

---

## 📊 작업 의존성 다이어그램

```
Task 1: design_tokens.dart 생성 (30분)
    ↓
    ├─→ Task 2: 색상 제거 (4시간) ──┐
    │       ↓                        │
    ├─→ Task 3: 공통 위젯 (3시간) ←─┘
    │
    └─→ Task 4: borderRadius (1시간)
```

**병렬 실행 가능**:
- Task 2와 Task 4는 동시 진행 가능 (서로 독립)
- Task 3은 Task 2 완료 후 시작 권장 (EmptyState/SectionHeader가 ColorScheme 사용)

**Critical Path**: Task 1 → Task 2 → Task 3 (총 7.5시간)

---

## 🤖 Agent 할당 전략

| Task | 담당 | Session 관리 | 이유 |
|------|------|-------------|------|
| 1. design_tokens.dart | **직접 처리** | 단일 세션 | 순수 상수, 시각 검증 불필요 |
| 2. 색상 제거 (P1) | **frontend-ui-ux-engineer** | 별도 세션 1 | 11개 파일, 라이트/다크 검증 |
| 2. 색상 제거 (P2, P3) | **frontend-ui-ux-engineer** | 별도 세션 2 | 16개 파일, 차트 시각 검증 |
| 3. EmptyState | **frontend-ui-ux-engineer** | 별도 세션 3 | 13곳 리팩토링, UI 일관성 |
| 3. SectionHeader | **frontend-ui-ux-engineer** | 세션 3 재사용 | EmptyState와 유사 패턴 |
| 3. AppCard | **직접 처리** | 단일 세션 | 간단한 래퍼, 빠른 적용 |
| 4. borderRadius | **직접 처리** | 단일 세션 | 규칙 기반, AST 검색 |

**frontend-ui-ux-engineer 작업 분할 (Zero-Context Handoff)**:

**Session 1 - 색상 제거 P1 (2시간)**:
```
Task: Phase1-ColorRemoval-P1

Input:
- Priority 1 files: [11개 파일 목록]
- Color mapping: [2.1 테이블]
- Design tokens: lib/shared/themes/design_tokens.dart

Output: .workflow/results/task-2.1-color-removal-p1.md
- Status: 완료/실패
- Modified files: [파일 목록]
- Changed lines: [변경 요약]
- Screenshots: light/dark comparison
- Summary: "Removed hardcoded Colors in 11 files, 44 instances"
```

**Session 2 - 색상 제거 P2, P3 (2시간)**:
```
Task: Phase1-ColorRemoval-P2-P3

Input: .workflow/results/task-2.1-color-removal-p1.md (이전 작업 참고)
Output: .workflow/results/task-2.2-color-removal-p2-p3.md
```

**Session 3 - 공통 위젯 (3시간)**:
```
Task: Phase1-CommonWidgets

Input:
- Widget specs: [3.1, 3.2 코드]
- Apply to: [13곳 + 12곳 목록]

Output: .workflow/results/task-3-common-widgets.md
- Created: empty_state.dart, section_header.dart, app_card.dart
- Modified: [25개 파일 목록]
- Deleted lines: ~200
- Summary: "Created 3 common widgets, reduced duplication by 200 lines"
```

---

## ✅ 최종 검증 체크리스트

### 코드 품질
- [ ] `flutter analyze` 에러 0개
- [ ] `flutter test` 기존 테스트 통과
- [ ] Import 충돌 없음
- [ ] 모든 DesignTokens 참조 정상 동작

### 디자인 일관성
- [ ] 모든 Card borderRadius 12 (예외: Sheet 20, FAB 16)
- [ ] 하드코딩 `Colors.grey` 0개
- [ ] 하드코딩 `Colors.red` 0개
- [ ] EmptyState 13곳 적용 완료
- [ ] SectionHeader 12곳 적용 완료
- [ ] AppCard 적용 완료

### 접근성
- [ ] 라이트 모드 색상 대비 WCAG AA 통과
- [ ] 다크 모드 색상 대비 WCAG AA 통과
- [ ] ColorScheme 자동 대비 활용

### 파일 변경 통계
- [ ] 신규 생성: 4개 (design_tokens.dart, empty_state.dart, section_header.dart, app_card.dart)
- [ ] 수정: 약 50개
- [ ] 삭제 코드: 약 200줄 (중복 제거)
- [ ] 순 증가: 약 400줄 (새 위젯 150줄 - 중복 200줄 + 변경 450줄)

### 문서화
- [ ] design_tokens.dart 주석 완료 (각 상수 용도 설명)
- [ ] 공통 위젯 사용 예시 포함
- [ ] AGENTS.md 업데이트 (WHERE TO LOOK 섹션)
- [ ] .workflow/phase1-completion-report.md 작성

---

## 📝 Phase 2 예고 (별도 계획)

**예상 작업 (5시간)**:

1. **타이포그래피 통일** (2시간)
   - 하드코딩 fontSize 65개 → Theme.of(context).textTheme
   - Priority: 24/20/18 (P0), 16/14/13 (P1), 12/11/10 (P2)
   - Agent: frontend-ui-ux-engineer

2. **접근성 개선** (3시간)
   - semanticLabel 추가 (IconButton 10곳)
   - 터치 타겟 크기 검증 (minTouchTarget 48dp)
   - Agent: 직접 처리 + oracle 컨설팅

---

## 🚀 시작 전 준비사항

### 1. Git Checkpoint
```bash
git add .
git commit -m "checkpoint: before Phase 1 design system foundation"
git branch phase1-design-system
git checkout phase1-design-system
```

### 2. 백업
```bash
# 주요 파일 백업
cp -r lib/features lib/features.backup
cp -r lib/shared lib/shared.backup
```

### 3. 도구 설치
```bash
# AST-Grep (이미 설치되어 있을 가능성 높음)
brew install ast-grep

# Ripgrep
brew install ripgrep
```

### 4. Agent 세션 준비
- frontend-ui-ux-engineer 에이전트 3개 세션 준비
- .workflow/results/ 디렉토리 생성

---

## 📌 다음 액션

**사용자 확인 필요**:
1. ✅ 이 실행 계획 검토 및 승인
2. ⏭️ Task 1 (design_tokens.dart) 직접 실행 시작
3. ⏭️ Task 2 (색상 제거) Agent 호출 승인
4. ⏭️ Task 3 (공통 위젯) Agent 호출 승인
5. ⏭️ Task 4 (borderRadius) 직접 실행 시작

**예상 완료 시점**: 
- Task 1: 즉시 (30분)
- Task 2-3: 7시간 (Agent 작업)
- Task 4: 1시간
- **총 8.5시간** (병렬 실행 시 6시간)

---

**계획 완료**. 승인 후 Task 1부터 시작하겠습니다.
