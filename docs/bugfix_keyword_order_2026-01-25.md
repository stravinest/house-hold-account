# 감지 키워드 순서 변경 버그 수정

## 문제 설명

결제수단 수정 화면에서 "현재 규칙으로 수집되는 정보"의 감지 키워드가 순간적으로 순서가 변경되는 문제가 발생했습니다.

**재현 순서:**
1. 자동수집 결제수단 수정 화면 진입
2. 감지 키워드가 처음에 "경기지역화폐, 수원페이" 순으로 표시됨
3. 잠시 후 "수원페이, 경기지역화폐" 순으로 변경됨

## 근본 원인 분석

### 1. Set의 순서 불확실성

**위치:** `lib/features/payment_method/data/services/sms_parsing_service.dart`

```dart
// 문제 코드
final potentialKeywords = <String>{};  // Set은 순서가 보장되지 않음!
```

**Set 자료구조의 특징:**
- 순서가 보장되지 않음 (구현에 따라 순서가 달라질 수 있음)
- `.toList()` 변환 시 매번 다른 순서로 반환될 수 있음
- Dart의 Set은 삽입 순서를 유지하지만, 런타임 최적화에 따라 변경 가능

### 2. 비동기 로딩 경쟁 상태

**위치:** `lib/features/payment_method/presentation/pages/payment_method_wizard_page.dart`

```dart
// 문제 코드 (initState)
if (_selectedMode == PaymentMethodAddMode.autoCollect) {
  _selectedTemplate = ...;
  if (_selectedTemplate != null) {
    _sampleController.text = _selectedTemplate!.defaultSampleSms;
  }

  // 1. DB 로드 시작 (비동기 - 느림)
  _loadExistingFormat();
}
// ...
// 2. 샘플 즉시 분석 (동기 - 빠름!)
if (_sampleController.text.isNotEmpty) {
  _analyzeSampleImmediate();
}
```

**실행 순서:**
1. `_loadExistingFormat()` 호출 (비동기 시작, 백그라운드 실행)
2. `_analyzeSampleImmediate()` 즉시 실행 (동기)
   - `SmsParsingService.generateFormatFromSample()` 호출
   - Set에서 List로 변환 → 키워드 순서 A
   - UI 업데이트: "경기지역화폐, 수원페이"
3. 잠시 후 `_loadExistingFormat()` 완료
   - DB에서 로드된 포맷으로 `_generatedFormat` 덮어씀
   - UI 업데이트: "수원페이, 경기지역화폐"

**결과:**
사용자에게는 키워드 순서가 깜빡이며 변경되는 것처럼 보임

## 해결 방법

### 1. Set → List로 변경 (순서 보장)

**파일:** `sms_parsing_service.dart`

```dart
// Before
final potentialKeywords = <String>{};  // Set - 순서 보장 안 됨

// After
final potentialKeywords = <String>[];  // List - 추가 순서 유지
```

**변경 사항:**
- Set 대신 List 사용
- 중복 제거는 `.contains()` 체크로 수동 처리
- 추가 순서가 그대로 유지됨

**코드 예시:**
```dart
// 대괄호 안의 내용 우선 추출
if (bracketMatch != null && bracketMatch.group(1) != null) {
  final keyword = bracketMatch.group(1)!;
  if (!potentialKeywords.contains(keyword)) {
    potentialKeywords.add(keyword);  // 순서대로 추가
  }
}

// 금융사 패턴 매칭
if (knownSender != null) {
  if (!potentialKeywords.contains(knownSender)) {
    potentialKeywords.add(knownSender);  // 순서대로 추가
  }
  // ...
}
```

### 2. 비동기 로딩 순서 보장

**파일:** `payment_method_wizard_page.dart`

```dart
// Before
_loadExistingFormat();  // 비동기 시작
// ...
if (_sampleController.text.isNotEmpty) {
  _analyzeSampleImmediate();  // 즉시 실행 (경쟁 상태!)
}

// After
_loadExistingFormatThenAnalyze();  // DB 로드 후 샘플 분석
```

**새로운 함수 추가:**
```dart
/// Edit 모드에서 DB 로드 완료 후 샘플 분석 실행 (순서 보장)
Future<void> _loadExistingFormatThenAnalyze() async {
  if (!isEdit || widget.paymentMethod == null) return;

  // 1. 먼저 DB에서 기존 포맷 로드
  final formatRepository = ref.read(learnedSmsFormatRepositoryProvider);
  final existingFormats = await formatRepository.getFormatsByPaymentMethod(
    widget.paymentMethod!.id,
  );

  if (!mounted) return;

  // 2. DB에 기존 포맷이 있으면 사용
  if (existingFormats.isNotEmpty) {
    setState(() {
      _generatedFormat = existingFormats.first;
    });
  }
  // 3. DB에 없고 샘플이 있으면 샘플 분석 실행
  else if (_sampleController.text.isNotEmpty) {
    _analyzeSampleImmediate();
  }
}
```

**동작 순서:**
1. DB 로드 완료 대기 (`await`)
2. DB에 포맷이 있으면 → 그대로 사용 (샘플 분석 건너뜀)
3. DB에 포맷이 없으면 → 샘플 분석 실행
4. 경쟁 상태 완전 제거 ✅

## 수정 결과

### Before
```
[화면 로드]
  ↓
샘플 분석 (동기) → UI: "경기지역화폐, 수원페이"
  ↓
DB 로드 완료 (비동기) → UI: "수원페이, 경기지역화폐"  ← 깜빡임!
```

### After
```
[화면 로드]
  ↓
DB 로드 대기 (await)
  ↓
DB에 데이터 있음 → UI: "수원페이, 경기지역화폐"  ← 일관성 유지!
```

## 테스트 시나리오

### 1. 기존 결제수단 수정
- [ ] 자동수집 결제수단 목록에서 결제수단 선택
- [ ] 수정 화면 진입
- [ ] 감지 키워드가 순서 변경 없이 일관되게 표시되는지 확인
- [ ] 새로고침/재진입 시에도 동일한 순서 유지

### 2. 새 결제수단 추가
- [ ] 금융사 템플릿 선택 (예: 경기지역화폐)
- [ ] 샘플 SMS 입력
- [ ] 감지 키워드가 일관된 순서로 생성되는지 확인
- [ ] 다시 입력해도 동일한 순서인지 확인

### 3. 템플릿 변경
- [ ] 템플릿 선택 → 샘플 자동 입력
- [ ] 감지 키워드 확인
- [ ] 다른 템플릿으로 변경
- [ ] 감지 키워드가 새 템플릿 순서로 일관되게 변경되는지 확인

## 영향 범위

### 변경된 파일
1. `lib/features/payment_method/data/services/sms_parsing_service.dart`
   - `generateFormatFromSample()` 함수
   - Set → List 변경
   - 중복 제거 로직 추가

2. `lib/features/payment_method/presentation/pages/payment_method_wizard_page.dart`
   - `initState()` 함수
   - `_loadExistingFormatThenAnalyze()` 함수 추가
   - 비동기 로딩 순서 보장

### 영향받는 기능
- ✅ 결제수단 수정 화면
- ✅ 결제수단 추가 화면
- ✅ 감지 키워드 표시
- ⚠️ 키워드 순서 (기존 DB 데이터는 변경되지 않음)

### Breaking Changes
없음. 기존 데이터는 그대로 유지되며, UI 표시만 일관되게 개선됨.

## 추가 고려사항

### 키워드 정렬 옵션

현재는 **추가 순서**를 유지합니다:
- 대괄호 키워드 → 금융사 이름 → 개별 키워드 → 일반 패턴

필요하다면 알파벳순 정렬을 추가할 수 있습니다:

```dart
// 옵션: 가나다순 정렬
senderKeywords: potentialKeywords..sort(),

// 결과:
// Before: "경기지역화폐", "수원페이"
// After: "경기지역화폐", "수원페이" (한글 가나다순)
```

**장점:**
- 완전히 일관된 순서 보장
- 언어/문자셋에 관계없이 동일한 순서

**단점:**
- 의미상 중요한 키워드가 뒤로 밀릴 수 있음
- 사용자 의도와 다를 수 있음

**권장:** 현재 구현(추가 순서 유지)을 유지하되, 필요시 정렬 옵션 추가

## 성능 영향

### Set vs List 비교

| 항목 | Set | List (현재) |
|------|-----|------------|
| 추가 (평균) | O(1) | O(1) |
| 중복 체크 | O(1) | O(n) |
| 순서 보장 | ✗ | ✓ |
| 메모리 | 약간 많음 | 적음 |

**키워드 개수:** 보통 3~5개 정도
**성능 영향:** 무시할 수 있는 수준 (n이 매우 작음)

### 비동기 로딩 시간

```
Before: 샘플 분석 (동기, 빠름) + DB 로드 (비동기, 느림) → 총 2회 렌더링
After:  DB 로드 (await) → 1회 렌더링 → 깜빡임 없음
```

**결과:** 오히려 렌더링 횟수가 줄어들어 성능 향상 ✅

## 관련 이슈

- 사용자 보고: 감지 키워드 순서가 변경됨
- 원인: Set 순서 불확실성 + 비동기 경쟁 상태
- 해결: List 사용 + 순서 보장

---

**수정 일자:** 2026-01-25
**테스트 기기:** R3CT90TAG8Z (Samsung SM_S908N)
**검증 방법:** 실물 기기 테스트, 코드 리뷰
