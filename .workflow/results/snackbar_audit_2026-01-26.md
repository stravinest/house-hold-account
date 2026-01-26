# SnackBar 전수조사 결과

**조사 일자**: 2026-01-26

## 요약

- **SnackBarUtils 사용**: 128곳 (권장 패턴)
- **직접 ScaffoldMessenger 사용**: 9곳 (통일 필요)
- **테마 설정**: `SnackBarBehavior.floating` 적용됨 (app_theme.dart)

## 1. 현재 구조

### SnackBarUtils (core/utils/snackbar_utils.dart)

**제공 메서드**:
- `showSuccess()` - 녹색 배경 (Colors.green[700])
- `showError()` - 빨간색 배경 (Colors.red[700])
- `showInfo()` - 기본 배경

**특징**:
- context.mounted 체크 내장
- 기본 duration: SnackBarDuration.short (2초)
- 커스텀 duration 지원
- ❌ SnackBarAction 미지원

### 앱 테마 설정 (shared/themes/app_theme.dart)

```dart
snackBarTheme: SnackBarThemeData(
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
  ),
),
```

## 2. 통일되지 않은 사용 패턴

### 직접 ScaffoldMessenger 사용 (9곳)

| 파일 | 라인 | 사유 | 우선순위 |
|------|------|------|---------|
| `category_tab_view.dart` | 74, 93 | `behavior: SnackBarBehavior.floating` 명시 | Medium |
| `asset_goal_action_buttons.dart` | 90 | 기본 SnackBar | High |
| `permission_status_banner.dart` | 176 | **SnackBarAction 사용** | Low |
| `payment_method_wizard_page.dart` | 1126, 1134, 1262, 1329, 1426 | 기본 SnackBar | High |

### 사용 패턴 분석

#### 1) SnackBarAction 사용 케이스
**파일**: `permission_status_banner.dart:176`
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.permissionSettingsSnackbar),
    action: SnackBarAction(
      label: l10n.commonConfirm,
      onPressed: _checkPermissions,
    ),
    duration: const Duration(seconds: 5),
  ),
);
```
**평가**: ✅ 정당한 사용 (SnackBarUtils가 action 미지원)

#### 2) 명시적 behavior 설정
**파일**: `category_tab_view.dart:74`
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.errorSessionExpired),
    duration: const Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,  // ← 불필요 (테마에 이미 설정됨)
  ),
);
```
**평가**: ⚠️ 중복 설정 (테마에서 이미 floating 적용)

#### 3) 기본 SnackBar만 사용
**파일**: `payment_method_wizard_page.dart:1126`
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.paymentMethodWizardKeywordsSaved)),
);
```
**평가**: ❌ SnackBarUtils.showInfo() 사용 권장

## 3. 문제점

### Critical
- ❌ 없음

### High
1. **일관성 부족**: 9곳에서 직접 ScaffoldMessenger 사용
2. **타입 미분류**: success/error/info 구분 없이 기본 SnackBar 사용

### Medium
1. **불필요한 behavior 명시**: 테마에서 이미 설정된 값 중복 지정
2. **SnackBarAction 미지원**: SnackBarUtils가 action 파라미터 미제공

### Low
1. **warning 타입 없음**: SnackBarUtils에 warning 메서드 부재

## 4. 권장 개선사항

### 즉시 수정 (High)

**payment_method_wizard_page.dart** (5곳)
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.paymentMethodWizardKeywordsSaved)),
);

// After
SnackBarUtils.showSuccess(context, l10n.paymentMethodWizardKeywordsSaved);
```

**asset_goal_action_buttons.dart** (1곳)
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(l10n.assetGoalDeleteFailed(e.toString()))),
);

// After
SnackBarUtils.showError(context, l10n.assetGoalDeleteFailed(e.toString()));
```

### 다음 스프린트 (Medium)

**SnackBarUtils 확장**: action 파라미터 지원
```dart
static void showInfo(
  BuildContext context,
  String message, {
  Duration? duration,
  SnackBarAction? action,  // ← 추가
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration ?? SnackBarDuration.short,
      action: action,
    ),
  );
}
```

**category_tab_view.dart** (2곳): behavior 명시 제거
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text(l10n.errorSessionExpired),
    duration: const Duration(seconds: 4),
    behavior: SnackBarBehavior.floating,  // ← 제거
  ),
);

// After
SnackBarUtils.showError(
  context,
  l10n.errorSessionExpired,
  duration: const Duration(seconds: 4),
);
```

### 선택적 개선 (Low)

**warning 타입 추가**
```dart
static void showWarning(
  BuildContext context,
  String message, {
  Duration? duration,
  SnackBarAction? action,
}) {
  if (!context.mounted) return;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: duration ?? SnackBarDuration.short,
      backgroundColor: Colors.orange[700],
      action: action,
    ),
  );
}
```

## 5. 체크리스트

### 즉시 수정 (High)
- [ ] `payment_method_wizard_page.dart:1126` - SnackBarUtils.showSuccess 전환
- [ ] `payment_method_wizard_page.dart:1134` - SnackBarUtils.showError 전환
- [ ] `payment_method_wizard_page.dart:1262` - SnackBarUtils.showSuccess 전환
- [ ] `payment_method_wizard_page.dart:1329` - SnackBarUtils.showError 전환
- [ ] `payment_method_wizard_page.dart:1426` - SnackBarUtils.showError 전환
- [ ] `asset_goal_action_buttons.dart:90` - SnackBarUtils.showError 전환

### 다음 스프린트 (Medium)
- [ ] SnackBarUtils에 action 파라미터 추가
- [ ] `permission_status_banner.dart:176` - SnackBarUtils.showInfo + action 사용
- [ ] `category_tab_view.dart:74` - behavior 제거, SnackBarUtils 전환
- [ ] `category_tab_view.dart:93` - behavior 제거, SnackBarUtils 전환

### 선택적 개선 (Low)
- [ ] SnackBarUtils.showWarning() 메서드 추가
- [ ] 전체 프로젝트에서 warning 케이스 적용

## 6. 결론

### 긍정적 측면
- ✅ SnackBarUtils가 존재하고 대부분의 코드(128곳)에서 사용 중
- ✅ 테마에서 floating behavior가 일관되게 적용됨
- ✅ context.mounted 체크가 유틸리티에 내장되어 있음

### 개선 필요 사항
- ⚠️ 6개 파일, 9곳에서 직접 ScaffoldMessenger 사용 → 통일 필요
- ⚠️ SnackBarAction 지원 부족 → 확장 필요
- ⚠️ warning 타입 부재 → 추가 고려

### 우선순위
1. **High**: 6곳 SnackBarUtils 전환 (30분 소요 예상)
2. **Medium**: SnackBarUtils action 지원 추가 (1시간 소요 예상)
3. **Low**: warning 타입 추가 및 적용 (선택적)
