# 목표 달성률 업데이트 수정 계획

## 변경 범위

### 수정할 파일
| 파일 | 변경 유형 | 변경 내용 |
|------|----------|----------|
| `lib/features/asset/presentation/providers/asset_goal_provider.dart` | 수정 | assetGoalCurrentAmountProvider에 assetStatisticsProvider 의존성 추가 |
| `lib/features/asset/data/repositories/asset_repository.dart` | 수정 | getCurrentAmount에 assetType 필터 추가 |

### 영향받는 영역
- 직접 영향: 목표 달성률 표시 (AssetGoalCard)
- 간접 영향: 없음 (기존 기능 유지)

## 구현 단계

### 1단계: Provider 의존성 추가
- `assetGoalCurrentAmountProvider`에 `assetStatisticsProvider`를 watch 추가
- 총자산 변경 시 provider가 자동 무효화되도록 함

### 2단계: assetType 필터 복구
- `getCurrentAmount` 함수에 assetType 필터 로직 추가
- assetType이 null일 때는 모든 타입 포함
- assetType이 지정된 경우 해당 타입만 필터링

## 테스트 계획

### 단위 테스트
- [ ] assetType 필터링 로직 테스트
- [ ] null assetType 시 모든 타입 포함 확인

### 통합 테스트
- [ ] 자산 거래 추가 후 목표 달성률 업데이트 확인
- [ ] 목표 생성 후 즉시 달성률 계산 확인
- [ ] assetType별 목표 필터링 확인

### 엣지 케이스 테스트
- [ ] assetType이 null인 목표 (전체 자산 목표)
- [ ] categoryIds가 null인 목표 (모든 카테고리 목표)
- [ ] 목표 달성률 100% 초과 케이스

## 리스크 및 대응

| 리스크 | 대응 방안 |
|--------|----------|
| Provider 무효화로 인한 불필요한 API 호출 | assetStatisticsProvider의 totalAmount만 watch하여 최소화 |
| assetType 필터 추가로 인한 성능 저하 | 인덱스 활용 및 쿼리 최적화 검토 |
| 기존 목표 데이터와의 호환성 | assetType 필터가 null일 때 기존 동작 유지 |

## 예상 변경 사항

### 코드 변경
```dart
// asset_goal_provider.dart
final assetGoalCurrentAmountProvider = FutureProvider.family<int, AssetGoal>((
  ref,
  goal,
) async {
  // 총자산 변경 감지하여 자동 업데이트
  ref.watch(assetStatisticsProvider.select((value) => value.when(
    data: (stats) => stats.totalAmount,
    loading: () => null,
    error: (_, __) => null,
  )));
  
  final repository = ref.watch(assetGoalRepositoryProvider);
  return repository.getCurrentAmount(
    ledgerId: goal.ledgerId,
    assetType: goal.assetType,
    categoryIds: goal.categoryIds,
  );
});

// asset_repository.dart
Future<int> getCurrentAmount({
  required String ledgerId,
  String? assetType,
  List<String>? categoryIds,
}) async {
  var query = _client
      .from('transactions')
      .select('amount')
      .eq('ledger_id', ledgerId)
      .eq('type', 'asset');

  // assetType 필터 추가
  if (assetType != null && assetType.isNotEmpty) {
    // TODO: asset_type 필드 확인 필요
    query = query.eq('asset_type', assetType);
  }

  if (categoryIds != null && categoryIds.isNotEmpty) {
    query = query.inFilter('category_id', categoryIds);
  }
  
  // ... 나머지 로직
}
```

### 데이터베이스 필드 확인 필요
- transactions 테이블에 asset_type 필드가 있는지 확인
- 없으면 추가하거나 다른 방식으로 구현 필요