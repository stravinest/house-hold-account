# UX/디자인 일관성 분석 결과

## 분석 개요

| 항목 | 내용 |
|------|------|
| **분석 대상** | UI 일관성, 디자인 시스템 준수, 접근성 |
| **분석 일자** | 2026-02-01 |
| **종합 점수** | 78/100 |

---

## 발견된 이슈

### 1. Critical (즉시 수정 필요)

| 파일 | 이슈 | 권장 조치 |
|------|------|----------|
| 26개 파일 | 색상 하드코딩 114건 | `colorScheme` 사용 |
| pending_transactions_page.dart | SnackBar 직접 사용 | `SnackBarUtils` 사용 |
| share_management_page.dart | AlertDialog 직접 생성 | `DialogUtils.showConfirmation` 사용 |

### 2. Warning (개선 권장)

| 파일 | 이슈 | 권장 조치 |
|------|------|----------|
| 여러 파일 | Spacing 하드코딩 | `Spacing.xs/sm/md/lg` 사용 |
| 일부 버튼 | 터치 영역 < 44px | 최소 44x44px 보장 |
| 여러 위젯 | Semantics 누락 | 접근성 개선 |

---

## 1. 디자인 시스템 준수

### 1.1 색상 하드코딩 (114건)

**심각도: Critical**

**발견 패턴:**
```dart
// ❌ 하드코딩 (114건 발견)
Color(0xFF2E7D32)
Color.fromARGB(255, 46, 125, 50)
Color.fromRGBO(46, 125, 50, 1.0)

// ✅ 권장
colorScheme.primary
```

**주요 파일:**
- `payment_method_wizard_page.dart`: 24건
- `asset_goal_card_simple.dart`: 14건
- `permission_request_dialog.dart`: 12건
- `asset_summary_card.dart`: 7건
- `asset_page.dart`: 6건

### 1.2 간격 하드코딩

**심각도: Warning**

**발견 패턴:**
```dart
// ❌ 하드코딩
padding: EdgeInsets.all(17)
SizedBox(height: 13)

// ✅ 권장
padding: EdgeInsets.all(Spacing.md)
SizedBox(height: Spacing.sm)
```

### 1.3 버튼 일관성

**평가: 양호 (85%)**

- Elevated/Outlined/Text 구분 잘 됨
- 일부 커스텀 버튼 존재 (개선 가능)

---

## 2. 컴포넌트 사용 일관성

### 2.1 SnackBar

**심각도: Critical**

**문제:**
- `pending_transactions_page.dart`에서 직접 `ScaffoldMessenger` 사용

**권장:**
```dart
// ❌ 현재
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('저장되었습니다'))
);

// ✅ 개선
SnackBarUtils.showSuccess(context, l10n.transactionSaved);
```

### 2.2 AlertDialog

**심각도: Warning**

**문제:**
- `share_management_page.dart`에서 AlertDialog 직접 생성 (5+ 위치)

**권장:**
```dart
// ✅ 개선
DialogUtils.showConfirmation(
  context: context,
  title: '멤버 삭제',
  message: '정말 삭제하시겠습니까?',
  onConfirm: () => _deleteMember(),
);
```

---

## 3. 접근성 (Accessibility)

### 3.1 Semantics 사용

**평가: 개선 필요 (50%)**

**누락된 위치:**
- 커스텀 차트 위젯 (Donut Chart, Bar Chart)
- 아이콘 버튼 (label 누락)
- 이미지 (semanticLabel 누락)

**권장:**
```dart
Semantics(
  label: '지출 카테고리 차트',
  child: DonutChart(...),
)
```

### 3.2 터치 영역

**평가: 양호 (80%)**

- 대부분 버튼이 48x48px 이상
- 일부 아이콘 버튼 작음 (개선 필요)

**권장:**
```dart
IconButton(
  constraints: BoxConstraints(minWidth: 44, minHeight: 44),
  icon: Icon(Icons.delete),
)
```

---

## 4. 다크모드 호환성

### 평가: 우수 (90%)

- `ThemeProvider`로 일관된 테마 관리
- `colorScheme` 기반으로 색상 자동 변경
- 하드코딩된 색상이 다크모드에서 문제될 수 있음

**개선 필요:**
- 하드코딩된 114건 색상을 `colorScheme`으로 변경

---

## 5. 에러 메시지 일관성

### 평가: 양호 (80%)

**우수 사례:**
```dart
// 일관된 패턴
l10n.transactionAmountRequired
l10n.transactionCategoryRequired
l10n.errorOccurred
```

**개선 필요:**
- 일부 하드코딩된 에러 메시지 (pending_transactions_page.dart)

---

## 6. 애니메이션

### 평가: 양호 (85%)

**표준 사용:**
```dart
AnimatedSwitcher(
  duration: Duration(milliseconds: 200),
  child: ...
)
```

**개선 제안:**
- 일부 애니메이션 duration이 불일치 (150ms ~ 400ms)
- 디자인 시스템 표준 duration 사용 권장

---

## 7. 종합 평가

```
=====================================
  UX/디자인 일관성 점수: 78/100
=====================================

  디자인 시스템 준수:  65점  (색상 하드코딩)
  컴포넌트 일관성:     75점  (SnackBar/Dialog)
  접근성:              50점  (Semantics 누락)
  다크모드 호환성:     90점  (일부 하드코딩)
  에러 메시지:         80점  (i18n 적용)
  애니메이션:          85점  (표준 준수)
=====================================
```

---

## 8. 권장 조치 사항

### Priority 1 (즉시)
1. **색상 하드코딩 제거 (114건)**
   - 주요 파일 우선: payment_method_wizard_page.dart (24건)

2. **SnackBarUtils 사용 통일**
   - pending_transactions_page.dart 수정

### Priority 2 (이번 주)
1. **DialogUtils 사용 통일**
   - share_management_page.dart 수정

2. **간격 토큰 사용**
   - 주요 레이아웃 파일부터 적용

### Priority 3 (이번 달)
1. **Semantics 추가**
   - 차트, 아이콘 버튼, 이미지

2. **터치 영역 보장**
   - 작은 아이콘 버튼 수정

---

**작성일**: 2026-02-01
**작성자**: Claude Code
**버전**: 1.0
