# 캘린더 하단 패널 잔상 버그 분석 리포트

## 버그 설명
거래 내역이 있는 날짜를 클릭한 후 다른 날짜를 클릭할 때 하단 패널이 두 번까지 잔상으로 남는 현상

## 버그 재현 시나리오

### 시나리오 1: 거래 있는 날짜 간 이동
1. 6일(거래 있음) 클릭 → 패널 슬라이드 업 애니메이션 시작
2. 애니메이션 진행 중 8일(거래 있음) 클릭
3. 패널이 완전히 올라오지 않은 상태에서 새 애니메이션 시작
4. 결과: 두 개의 애니메이션이 겹쳐서 실행되며 잔상 발생

### 시나리오 2: 빠른 연속 클릭
1. 6일 클릭 → 패널 표시 애니메이션 시작
2. 즉시 10일(거래 없음) 클릭 → 패널 숨김 애니메이션 시작
3. 즉시 12일(거래 있음) 클릭 → 다시 패널 표시 애니메이션 시작
4. 결과: 애니메이션이 충돌하며 패널이 중복 렌더링됨

## 근본 원인 분석

### 1. 애니메이션 상태 관리 부재
```dart
// 문제가 있는 기존 코드
void _handleDateSelected(DateTime date) {
  widget.onDateSelected(date);

  final transactionsAsync = ref.read(dailyTransactionsProvider);
  final hasTransactions = transactionsAsync.valueOrNull?.isNotEmpty ?? false;

  if (hasTransactions) {
    if (!_showPanel) {
      setState(() { _showPanel = true; });
      _animationController.forward();  // 진행 중인 애니메이션을 체크하지 않음
    }
  } else {
    if (_showPanel) {
      _animationController.reverse().then((_) { /* ... */ });  // 진행 중인 forward를 중단하지 않음
    }
  }
}
```

**문제점:**
- 이미 실행 중인 애니메이션이 있는지 확인하지 않음
- 새 애니메이션을 시작하기 전 기존 애니메이션을 중단하지 않음
- `_animationController.forward()`와 `reverse()`가 동시에 실행될 수 있음

### 2. 상태와 애니메이션 불일치
```dart
// 문제 상황
_showPanel = true  // UI에 패널 표시
_animationController.value = 0.5  // 애니메이션은 50% 진행
```

**문제점:**
- `_showPanel` 상태는 즉시 변경되지만 애니메이션은 시간이 걸림
- 상태 변경과 애니메이션 완료 시점이 동기화되지 않음
- 패널이 위젯 트리에 추가/제거되는 타이밍과 애니메이션이 맞지 않음

### 3. 중복 애니메이션 실행
**타임라인 분석:**
```
시간 0ms: 6일 클릭
  → _showPanel = true
  → forward() 시작 (0.0 → 1.0, 300ms 소요)

시간 150ms: 8일 클릭 (애니메이션 50% 진행)
  → _showPanel은 이미 true
  → if (!_showPanel) 조건에 걸리지 않음
  → 아무 동작 없음 (의도한 동작)

시간 160ms: 10일 클릭 (거래 없음)
  → if (_showPanel) 조건 충족
  → reverse() 시작 (현재 값 0.5 → 0.0)
  → 하지만 forward()가 아직 진행 중!
  → 두 애니메이션이 충돌
```

## 해결 방법

### 1차 수정 (부분 해결)

```dart
void _handleDateSelected(DateTime date) {
  widget.onDateSelected(date);
  _animationController.stop();

  final transactionsAsync = ref.read(dailyTransactionsProvider);
  final hasTransactions = transactionsAsync.valueOrNull?.isNotEmpty ?? false;

  if (hasTransactions) {
    if (!_showPanel) {
      setState(() { _showPanel = true; });
      _animationController.forward(from: 0.0);
    } else {
      _animationController.value = 1.0;
    }
  } else {
    if (_showPanel) {
      // ❌ 문제: reverse() 애니메이션 진행 중 패널이 위젯 트리에 남아있음
      _animationController.reverse(from: _animationController.value).then((_) {
        if (mounted) {
          setState(() { _showPanel = false; });
        }
      });
    }
  }
}
```

**여전히 남은 문제:**
- `reverse()` 애니메이션이 완료될 때까지 `_showPanel = true` 유지
- 위젯 빌드 시 `if (_showPanel)` 조건으로 패널이 위젯 트리에 포함됨
- 애니메이션이 매우 짧게 실행되면 잔상처럼 보임

**잔상 발생 상세 분석:**
```
[사용자 동작]
1. 6일(거래 있음) 클릭
2. 패널이 슬라이드 업되어 완전히 표시됨
3. 10일(거래 없음) 클릭

[시스템 동작]
시간 T: 10일 클릭
  → _handleDateSelected(10일) 호출
  → hasTransactions = false
  → if (_showPanel) 조건 진입

시간 T+1ms: reverse() 시작
  → _animationController.reverse(from: 1.0)
  → _showPanel = true 상태 유지 ⚠️

시간 T+1ms ~ T+300ms: 빌드 사이클
  → build() 호출
  → if (_showPanel) → true
  → Positioned 위젯 생성
  → SlideTransition 위젯 생성
  → 패널이 화면에 렌더링됨 ⚠️
  → 애니메이션 값에 따라 아래로 내려감

시간 T+300ms: 애니메이션 완료
  → .then() 콜백 실행
  → setState(() { _showPanel = false; })
  → 패널이 위젯 트리에서 제거됨
```

**왜 잔상처럼 보이는가?**
- 300ms 동안 패널이 화면에 보임
- 슬라이드 다운 애니메이션이 진행됨
- 사용자는 "거래 없는 날짜를 클릭했는데 왜 패널이 보이지?"라고 느낌
- 특히 애니메이션이 빠르게 진행되면 "잔상"처럼 깜빡이는 것처럼 보임

### 2차 수정 (완전 해결)

```dart
void _handleDateSelected(DateTime date) {
  widget.onDateSelected(date);

  final transactionsAsync = ref.read(dailyTransactionsProvider);
  final hasTransactions = transactionsAsync.valueOrNull?.isNotEmpty ?? false;

  if (hasTransactions) {
    if (!_showPanel) {
      // ✅ 1. 패널 표시: 애니메이션 중단 후 처음부터 시작
      _animationController.stop();
      setState(() { _showPanel = true; });
      _animationController.forward(from: 0.0);
    } else {
      // ✅ 2. 이미 표시된 경우: 즉시 완전 표시 상태로
      _animationController.stop();
      _animationController.value = 1.0;
    }
  } else {
    if (_showPanel) {
      // ✅ 3. 패널 숨김: 애니메이션 없이 즉시 상태 변경 (잔상 방지)
      _animationController.stop();
      _animationController.value = 0.0;
      setState(() { _showPanel = false; });
    }
  }
}
```

### 수정 내용 상세 설명

#### 1. 조건부 애니메이션 중단
- **거래 있는 날짜**: 애니메이션 중단 후 새로 시작
- **거래 없는 날짜**: 애니메이션 중단하고 즉시 상태 변경
- 각 분기마다 필요한 시점에만 `stop()` 호출

#### 2. 명시적 시작 위치 (`forward(from: 0.0)`)
- 패널을 새로 표시할 때는 항상 처음부터 시작
- 이전 애니메이션의 잔여 상태 영향 제거
- 일관된 애니메이션 경험 제공

#### 3. 즉시 완료 상태 설정 (`_animationController.value = 1.0`)
- 패널이 이미 표시된 상태에서 다른 거래 날짜 클릭 시
- 애니메이션 없이 즉시 완전히 표시된 상태로 설정
- 불필요한 애니메이션 제거로 부드러운 UX

#### 4. 즉시 숨김 처리 (잔상 제거의 핵심)
```dart
// 거래 없는 날짜 클릭 시
_animationController.stop();        // 진행 중인 애니메이션 중단
_animationController.value = 0.0;   // 애니메이션 값 즉시 0으로
setState(() { _showPanel = false; }); // 상태 즉시 변경 → 위젯 트리에서 제거
```

**핵심 원리:**
- `setState(() { _showPanel = false; })`를 **즉시** 호출
- 위젯 빌드 시 `if (_showPanel)` 조건에 의해 패널이 위젯 트리에서 제거됨
- `reverse()` 애니메이션을 사용하지 않아 애니메이션 진행 중 렌더링 없음
- 결과: 잔상 완전히 제거

#### 5. 안전 가드 (`_closePanel()`에 `if (!_showPanel) return;`)
- 이미 숨겨진 패널을 다시 숨기려는 시도 방지
- 불필요한 애니메이션 실행 방지

## 기대 효과

### Before (1차 수정 - 부분 해결)
- ❌ 빠른 연속 클릭 시 패널이 겹쳐 보임
- ❌ 애니메이션이 끊기거나 튐
- ⚠️ 거래 있는 날짜 → 거래 없는 날짜 클릭 시 잔상 발생

### After (2차 수정 - 완전 해결)
- ✅ 어떤 순서로 클릭해도 일관된 동작
- ✅ 부드러운 애니메이션 전환
- ✅ 잔상 완전히 제거
- ✅ 거래 없는 날짜 클릭 시 즉시 패널 숨김
- ✅ 깔끔하고 반응성 좋은 UI

## 추가 개선 사항

### 금액 입력 필드 개선
**문제:** 금액 입력 필드를 클릭했을 때 '0'이 표시되지 않아 사용자가 빈 필드인지 헷갈림

**해결:**
- `hintText: '0'` 추가하여 입력 전 '0' 표시
- 포커스 시 '0' 또는 빈 값은 자동으로 지워짐
- 기존 금액은 전체 선택되어 바로 덮어쓰기 가능

## 테스트 체크리스트

### 1차 수정 검증
- [x] 거래 있는 날짜 → 거래 있는 날짜 (빠른 연속 클릭)
- [x] 거래 있는 날짜 → 거래 없는 날짜 → 거래 있는 날짜 (빠른 연속)
- [x] 패널 표시 애니메이션 진행 중 다른 날짜 클릭
- [x] 패널 숨김 애니메이션 진행 중 거래 있는 날짜 클릭
- [x] 패널 닫기 버튼 클릭 후 즉시 날짜 클릭
- [❌] 거래 있는 날짜 → 거래 없는 날짜 클릭 시 잔상 발생 → **2차 수정 필요**

### 2차 수정 검증 (잔상 완전 제거)
- [x] 거래 있는 날짜 → 거래 없는 날짜 (잔상 없이 즉시 숨김)
- [x] 거래 없는 날짜 → 거래 있는 날짜 (부드러운 슬라이드 업)
- [x] 거래 있는 날짜 → 거래 있는 날짜 (패널 유지)
- [x] 거래 없는 날짜 → 거래 없는 날짜 (패널 계속 숨김)
- [x] 패널 표시 중 빠르게 연속 클릭 (날짜 변경만 발생)
- [x] 매우 빠른 연속 클릭 (잔상 없음)

### 금액 입력 필드
- [x] 초기 상태 '0' 표시 확인
- [x] 포커스 시 '0' 자동 삭제 확인
- [x] 포커스 해제 시 빈 값이면 '0' 복원 확인
- [x] '0' 상태로 저장 시도 시 에러 메시지 확인

## 결론

캘린더 하단 패널의 잔상 버그는 **애니메이션과 상태 관리의 비동기 처리**가 근본 원인이었습니다.

### 1차 수정 (부분 해결)
- 애니메이션 충돌 문제를 해결하여 대부분의 경우 정상 동작
- 하지만 거래 없는 날짜 클릭 시 `reverse()` 애니메이션이 진행되는 동안 패널이 위젯 트리에 남아있어 잔상 발생

### 2차 수정 (완전 해결)
- 거래 없는 날짜 클릭 시 **즉시 상태 변경** (`_showPanel = false`)
- 애니메이션을 사용하지 않고 즉시 패널을 위젯 트리에서 제거
- 애니메이션 값도 0으로 리셋하여 다음 표시 시 깔끔하게 시작

### 핵심 원리
- **위젯 렌더링 제어**: `_showPanel` 상태로 위젯 트리 포함 여부 결정
- **즉시 반응**: 거래 없는 날짜는 애니메이션 없이 즉시 숨김
- **부드러운 전환**: 거래 있는 날짜는 애니메이션으로 부드럽게 표시

이로써 잔상 없이 반응성 좋고 일관된 사용자 경험을 제공하게 되었습니다.
