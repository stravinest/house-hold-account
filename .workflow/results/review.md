# 코드 리뷰 결과

## 요약
- 검토 파일: 2개
  - `payment_method_wizard_page.dart` (1,223 lines)
  - `payment_method_management_page.dart` (1,327 lines)
- **Critical: 0개** / **High: 3개** / **Medium: 5개** / **Low: 3개**

---

## High 이슈

### 1. [payment_method_wizard_page.dart:232-358] 저장 로직에서 트랜잭션 미사용
- **문제**: `_submit()` 메서드에서 여러 비동기 작업(updatePaymentMethod, updateAutoSaveSettings, createFormat/updateFormat)을 순차적으로 수행하지만, 하나의 트랜잭션으로 묶지 않음
- **위험**: 중간 단계에서 실패 시 데이터 불일치 발생 가능. 예: paymentMethod는 업데이트되었지만 autoSaveSettings 업데이트가 실패하는 경우
- **해결**: Supabase의 RPC 함수나 repository 레벨에서 트랜잭션 처리를 구현하거나, 최소한 실패 시 롤백 로직 추가

```dart
// 현재 코드 (문제)
await notifier.updatePaymentMethod(...);
await notifier.updateAutoSaveSettings(...);  // 여기서 실패하면?
await formatRepository.createFormat(...);    // 부분 업데이트 상태

// 권장 방안: Repository에 트랜잭션 메서드 추가
await notifier.updatePaymentMethodWithSettings(
  id: id,
  name: name,
  canAutoSave: canAutoSave,
  autoSaveMode: autoSaveMode,
  format: generatedFormat,
);
```

### 2. [payment_method_wizard_page.dart:273-296] 포맷 업데이트 시 첫 번째 포맷만 업데이트
- **문제**: `existingFormats.first`만 업데이트하고, 동일 paymentMethod에 여러 포맷이 있을 경우 나머지는 무시됨
- **위험**: 기존에 여러 SMS 포맷이 등록된 경우 의도치 않은 동작 발생 가능
- **해결**: 명확한 정책 수립 필요 (전체 삭제 후 재생성 또는 특정 조건으로 포맷 선택)

```dart
// 현재 코드
if (existingFormats.isNotEmpty) {
  await formatRepository.updateFormat(
    id: existingFormats.first.id,  // 첫 번째만 업데이트
    senderKeywords: _generatedFormat!.senderKeywords,
  );
}

// 권장: 명확한 의도 표현
// 옵션 1: 전체 삭제 후 재생성
await formatRepository.deleteFormatsByPaymentMethod(widget.paymentMethod!.id);
await formatRepository.createFormat(...);

// 옵션 2: 모든 기존 포맷 업데이트
for (final format in existingFormats) {
  await formatRepository.updateFormat(id: format.id, ...);
}
```

### 3. [payment_method_management_page.dart:688-697] context.mounted 중복 체크
- **문제**: `_showAutoSaveModeDialog` 메서드에서 `context.mounted` 체크 후 `Navigator.push`를 호출하지만, 이 메서드는 `ConsumerWidget`의 `build` 외부에서 호출되어 StatelessWidget의 context가 항상 mounted 상태임
- **위험**: 불필요한 코드이며, 실제 문제(async gap 후 context 사용)를 해결하지 못함

```dart
// 현재 코드 (불필요한 체크)
void _showAutoSaveModeDialog(BuildContext context, PaymentMethod paymentMethod) {
  if (context.mounted) {  // StatelessWidget에서는 항상 true
    Navigator.push(...);
  }
}

// 이 메서드는 동기적으로 호출되므로 mounted 체크 불필요
void _showAutoSaveModeDialog(BuildContext context, PaymentMethod paymentMethod) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => PaymentMethodWizardPage(paymentMethod: paymentMethod),
    ),
  );
}
```

---

## Medium 이슈

### 1. [payment_method_wizard_page.dart:84-95] 편집 모드에서 템플릿 매칭 로직의 취약성
- **문제**: 템플릿 매칭을 이름으로만 수행. 사용자가 이름을 변경했거나, 동일 이름의 다른 결제수단이 있을 경우 잘못된 템플릿이 매칭됨
- **개선**: 템플릿 ID를 PaymentMethod에 저장하거나, 더 강건한 매칭 로직 필요

```dart
// 현재 (취약)
_selectedTemplate = FinancialServiceTemplate.templates
    .cast<FinancialServiceTemplate?>()
    .firstWhere(
      (t) => t?.name == widget.paymentMethod?.name,  // 이름만으로 매칭
      orElse: () => null,
    );

// 권장: PaymentMethod에 templateId 필드 추가
_selectedTemplate = FinancialServiceTemplate.templates
    .cast<FinancialServiceTemplate?>()
    .firstWhere(
      (t) => t?.id == widget.paymentMethod?.templateId,
      orElse: () => null,
    );
```

### 2. [payment_method_wizard_page.dart:46-48] TextEditingController 초기화 누락
- **문제**: `_keywordsController`가 빈 문자열로 초기화되지만, 편집 모드에서 기존 키워드가 로드되지 않음
- **개선**: 편집 모드 초기화 시 기존 LearnedSmsFormat의 키워드를 로드

```dart
// initState에서 편집 모드일 때 기존 포맷 로드 필요
if (isEdit && _selectedMode == PaymentMethodAddMode.autoCollect) {
  // 기존 포맷 로드 후 _keywordsController 초기화
  _loadExistingFormat();
}
```

### 3. [payment_method_management_page.dart:24] Platform.isAndroid 캐싱 방식
- **문제**: 전역 getter로 `Platform.isAndroid`를 사용. 테스트 시 mocking이 어려움
- **개선**: Provider나 생성자 파라미터로 주입

```dart
// 현재 (테스트 어려움)
bool get _isAndroidPlatform => Platform.isAndroid;

// 권장: Provider로 주입
final isAndroidProvider = Provider<bool>((ref) => Platform.isAndroid);

// 또는 Widget 파라미터로 주입 (테스트용)
class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  final bool? overrideIsAndroid;  // 테스트용
  // ...
}
```

### 4. [payment_method_wizard_page.dart:1115-1199] SMS 불러오기 다이얼로그의 에러 핸들링 부족
- **문제**: `_showSmsImportDialog`에서 `scanner.scanFinancialSms()` 실패 시 단순히 에러 메시지만 표시. 구체적인 에러 유형(권한, 네트워크 등)에 따른 처리 없음
- **개선**: 에러 유형별 적절한 사용자 안내 제공

```dart
// 현재
if (snapshot.hasError) {
  return Center(child: Text('Error: ${snapshot.error}'));
}

// 권장
if (snapshot.hasError) {
  final error = snapshot.error;
  if (error is PermissionDeniedException) {
    return _buildPermissionErrorView(context);
  }
  return Center(child: Text(l10n.smsLoadError));
}
```

### 5. [payment_method_management_page.dart:69-79] 날짜 그룹 분류 로직의 경계 케이스
- **문제**: `_getDateGroup`에서 월 경계 처리가 불완전. 예: 1월 7일에 12월 31일 데이터는 `thisWeek`가 아닌 `older`로 분류되어야 하지만, 로직이 복잡하고 테스트하기 어려움
- **개선**: 단순히 일수 차이만으로 분류하거나, 별도 유틸 클래스로 분리

```dart
// 현재 (복잡한 조건)
if (difference <= 7 && date.year == now.year && date.month == now.month) {
  return _DateGroup.thisWeek;
}

// 권장: 단순화
if (difference <= 7) return _DateGroup.thisWeek;
```

---

## Low 이슈

### 1. [payment_method_wizard_page.dart:348] debugPrint 사용
- **문제**: 프로덕션 코드에 `debugPrint` 사용. 로깅 전략이 일관되지 않음
- **개선**: 로깅 유틸리티 또는 Logger 패키지 사용

```dart
// 현재
debugPrint('PaymentMethod save failed: $e\n$st');

// 권장: 앱 전체 로깅 전략 사용
AppLogger.error('PaymentMethod save failed', error: e, stackTrace: st);
```

### 2. [payment_method_management_page.dart:910-912] DateFormat/NumberFormat 매번 생성
- **문제**: `build` 메서드에서 DateFormat, NumberFormat을 매번 생성. 성능에 미미한 영향이지만 불필요한 객체 생성
- **개선**: 상위 위젯에서 한 번만 생성하거나, static const로 선언

```dart
// 현재 (매번 생성)
final timeFormat = DateFormat('HH:mm');
final dateFormat = DateFormat('MM/dd HH:mm');
final currencyFormat = NumberFormat('#,###');

// 권장: 클래스 레벨 또는 Provider로 관리
static final _timeFormat = DateFormat('HH:mm');
static final _dateFormat = DateFormat('MM/dd HH:mm');
static final _currencyFormat = NumberFormat('#,###');
```

### 3. [payment_method_wizard_page.dart:1029-1038] 하드코딩된 문자열
- **문제**: `_getFriendlyAmountPattern` 메서드에서 영어 문자열 하드코딩
- **개선**: l10n으로 이동

```dart
// 현재 (하드코딩)
if (regex.contains('Won') && regex.contains('[0-9,]+')) {
  return 'Number before "Won"';
}

// 권장
return l10n.amountPatternBeforeWon;
```

---

## 긍정적인 점

1. **SafeArea 적용**: `bottomNavigationBar`에 SafeArea를 적용하여 노치/홈 인디케이터 영역을 고려함
2. **접근성 고려**: Semantics 위젯을 적절히 사용하여 스크린 리더 지원
3. **상태 관리**: Riverpod을 사용한 일관된 상태 관리 패턴
4. **UI/UX**: 모드 선택 카드, 칩 스타일의 직관적인 UI 구현
5. **에러 처리**: mounted 체크를 통한 비동기 작업 후 안전한 UI 업데이트
6. **코드 분리**: 기능별 위젯 분리 (공유 섹션, 자동수집 섹션, 트랜잭션 카드 등)

---

## 추가 권장사항

### 테스트
- `_submit()` 메서드의 복잡한 저장 로직에 대한 단위 테스트 추가 권장
- 날짜 그룹 분류 로직(`_getDateGroup`)에 대한 경계값 테스트 추가

### 리팩토링
- `PaymentMethodWizardPage`가 1,200줄로 큰 편. 각 Step을 별도 위젯으로 분리 고려
- SMS 불러오기 다이얼로그를 별도 위젯으로 분리하여 재사용성 향상

### 문서화
- `autoSaveMode`의 세 가지 모드(manual, suggest, auto)의 동작 차이를 주석으로 명확히 문서화
- 편집 모드와 생성 모드의 플로우 차이를 문서화
