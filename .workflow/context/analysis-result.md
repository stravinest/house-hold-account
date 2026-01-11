# 현황 분석 결과

## 수정 대상: 상단 수입/지출 합계 영역 높이 고정

### 문제 상황
- 공유 가계부에서 두 명의 멤버가 모두 거래를 입력하면 각 멤버별 금액이 표시됨
- 멤버 중 한 명 또는 둘 다 거래가 없으면 해당 행이 표시되지 않음
- 이로 인해 상단 요약 영역의 높이가 동적으로 변경됨
- 결과적으로 캘린더 전체의 위치가 변동되어 UX가 일관되지 않음

### 관련 파일
- `lib/features/ledger/presentation/widgets/calendar_view.dart` (핵심)
  - `_MonthSummary` 위젯 (라인 551-619)
  - `_SummaryColumn` 위젯 (라인 624-710)
  - `_UserAmountIndicator` 위젯 (라인 713-748)

### 현재 코드 분석

#### _SummaryColumn 위젯 (문제 부분)
```dart
// 유저별 표시 (세로 배치)
if (userAmounts.isNotEmpty) ...[
  const SizedBox(height: 2),
  ...userAmounts.map((entry) => Padding(
        padding: const EdgeInsets.only(bottom: 1),
        child: _UserAmountIndicator(
          color: entry.key,
          amount: entry.value,
        ),
      )),
],
```

위 코드에서 `userAmounts`가 비어있으면 아무것도 렌더링하지 않아 높이가 줄어듭니다.

### 식별된 엣지 케이스
1. 공유 멤버 0명 (개인 가계부) - 사용자별 표시 불필요
2. 공유 멤버 1명 - 1줄만 표시하면 됨
3. 공유 멤버 2명 (최대) - 항상 2줄 높이 유지 필요
4. 멤버 A만 거래 있음 - A의 금액만 표시, B는 빈 줄
5. 멤버 B만 거래 있음 - B의 금액만 표시, A는 빈 줄
6. 둘 다 거래 없음 - 빈 2줄 높이 유지
7. 둘 다 거래 있음 - 정상 표시

### 해결 방향
1. 공유 가계부 여부와 멤버 수 정보 필요
2. 멤버 수에 따라 고정 높이 공간 확보
3. 거래 데이터 유무와 관계없이 일정한 높이 유지
4. _UserAmountIndicator의 높이를 상수로 정의하여 관리

### 의존성
- `currentLedgerProvider`: 현재 선택된 가계부 정보 (공유 여부, 멤버 수)
- `monthlyTotalProvider`: 월별 합계 및 사용자별 데이터
