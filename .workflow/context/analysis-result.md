# 현황 분석 결과

## 수정 대상: 목표 달성률 업데이트 문제

### 요청 내용
총자산이 변경되었는데도 목표 달성률이 변함이 없다. 목표 달성률이 총자산 변경을 제대로 반영하도록 수정.

### 관련 파일
- `lib/features/asset/presentation/providers/asset_goal_provider.dart`
- `lib/features/asset/data/repositories/asset_repository.dart`

### 현재 문제 상황

#### 증상
1. AssetPage의 총자산은 정상적으로 업데이트됨
2. 목표 카드의 달성률은 변함이 없음

#### 원인 분석
- `assetStatisticsProvider`와 `assetGoalCurrentAmountProvider`가 독립적으로 동작
- 총자산 변경 시 목표 달성률 provider가 자동으로 업데이트되지 않음
- `assetGoalCurrentAmountProvider`가 FutureProvider로 캐시되어 재호출되지 않음

#### 관련 코드
```dart
// AssetPage - 정상 작동
final statisticsAsync = ref.watch(assetStatisticsProvider);

// AssetGoalCard - 캐시 문제
final currentAmount = ref.watch(assetGoalCurrentAmountProvider(goal));
final progress = ref.watch(assetGoalProgressProvider(goal));
```

### 추가 발견된 문제점

#### 1. getCurrentAmount의 assetType 필터 누락
```dart
Future<int> getCurrentAmount({
  required String ledgerId,
  String? assetType,  // 파라미터 존재
  List<String>? categoryIds,
}) async {
  var query = _client
      .from('transactions')
      .select('amount')
      .eq('ledger_id', ledgerId)
      .eq('type', 'asset');
  
  // assetType 필터가 빠져있음!
  if (categoryIds != null && categoryIds.isNotEmpty) {
    query = query.inFilter('category_id', categoryIds);
  }
}
```

#### 2. 목표 데이터 확인
- 목표: "모으기" (target_amount: 10000)
- asset_type: null, category_ids: null (전체 자산 목표)

### 수정 방안

#### 1. Provider 의존성 추가
`assetGoalCurrentAmountProvider`에 `assetStatisticsProvider`를 의존성으로 추가하여 총자산 변경 시 자동 업데이트

#### 2. assetType 필터 복구
`getCurrentAmount`에 assetType 필터 로직 추가

#### 3. 테스트
- 자산 거래 추가/수정 시 목표 달성률 업데이트 확인
- assetType 필터링 기능 확인

### 엣지 케이스
1. 목표가 없는 경우
2. assetType이 null인 경우 (전체 자산 목표)
3. categoryIds가 null인 경우 (모든 카테고리 목표)
4. 목표 달성률 100% 초과 케이스