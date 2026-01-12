# 현황 분석 결과

## 수정 대상: 통계 페이지 기준 달 선택 기능

### 관련 파일

**핵심 파일:**
- `lib/features/statistics/presentation/pages/statistics_page.dart` - 메인 페이지 (탭 컨트롤러)
- `lib/features/statistics/presentation/providers/statistics_provider.dart` - 상태 관리
- `lib/features/statistics/data/repositories/statistics_repository.dart` - 데이터 조회 로직

**탭별 위젯:**
- `lib/features/statistics/presentation/widgets/category_tab/category_tab_view.dart`
- `lib/features/statistics/presentation/widgets/trend_tab/trend_tab_view.dart`
- `lib/features/statistics/presentation/widgets/trend_tab/trend_bar_chart.dart`
- `lib/features/statistics/presentation/widgets/payment_method_tab/payment_method_tab_view.dart`

**의존성:**
- `lib/features/transaction/presentation/providers/transaction_provider.dart` - selectedDateProvider

### 현재 UI/UX 상태

**강점:**
- Clean Architecture 기반 잘 구조화된 코드
- Riverpod 자동 의존성 추적
- 평균선 표시로 UX 향상

**개선점:**
1. 통계 화면에서 직접 월/년도 변경 불가 (홈 캘린더에서만 가능)
2. 연별 추이는 항상 현재 시점 기준 (selectedDateProvider 미사용)
3. 평균 계산 시 0원인 달도 포함되어 실제 평균보다 낮게 표시됨

### 현재 날짜 처리 로직

| 탭 | 날짜 기준 | 문제점 |
|----|----------|--------|
| 카테고리 | selectedDateProvider | UI에서 변경 불가 |
| 추이 (월별) | selectedDateProvider 기준 6개월 | UI에서 변경 불가 |
| 추이 (연별) | DateTime.now() 기준 3년 | 항상 현재 연도 고정 |
| 결제수단 | selectedDateProvider | UI에서 변경 불가 |

### 평균 계산 로직 현황

**월별 추이 (statistics_repository.dart:295-354):**
```dart
// 현재 로직 - 모든 달 포함
averageExpense: months > 0 ? (totalExpense / months).round() : 0
```
- 문제: 0원인 달도 분모에 포함되어 평균이 낮아짐

**연별 추이 (trend_bar_chart.dart:288-293):**
```dart
// 클라이언트에서 계산
final average = data.isNotEmpty ? total ~/ data.length : 0;
```
- 문제: 동일하게 0원인 연도 포함

### 식별된 엣지 케이스

1. **데이터 없는 월**: 0원으로 표시되지만 평균에 포함되어 왜곡
2. **미래 월 선택**: 기준 달이 미래일 경우 데이터 없음
3. **가계부 변경**: 기준 달은 유지되어야 함
4. **앱 재시작**: 기준 달은 현재 월로 초기화

### 의존성 구조

```
statisticsSelectedDateProvider (신규)
       |
+------+------+
|             |
v             v
카테고리/결제수단  추이 탭
Provider        Provider
       |
       v
Repository 메서드들
```
