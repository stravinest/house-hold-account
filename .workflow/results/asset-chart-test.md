# 자산 탭 기능 확장 테스트 결과

## 상태
완료

## 생성/수정 파일

### 수정
- `test/features/asset/presentation/widgets/asset_line_chart_test.dart`
  - StatelessWidget -> ConsumerWidget 변환에 맞게 전면 수정
  - ProviderScope + overrides 패턴으로 변경
  - assetChartPeriodProvider, assetMonthlyChartProvider, assetYearlyChartProvider 모두 mock
  - 월별/연별 차트 케이스 분리 테스트
  - 로딩/에러/빈 데이터/음수/단일 데이터 케이스 커버

### 신규 생성
- `test/features/asset/domain/entities/asset_statistics_entity_test.dart`
  - YearlyAsset entity 생성자, Equatable 동등성, hashCode, List 활용 테스트
  - MonthlyAsset entity 기본 테스트 추가

- `test/features/asset/presentation/providers/asset_provider_extended_test.dart`
  - assetChartPeriodProvider 기본값(TrendPeriod.monthly) 및 상태 전환 테스트
  - assetSharedStateProvider 기본값(combined) 및 모드 전환 테스트
  - assetMonthlyChartProvider / assetYearlyChartProvider 유저 필터 테스트
  - assetStatisticsProvider userId 전달 테스트
  - overlay 모드에서 userId null 처리 테스트

### 버그 수정
- `lib/features/asset/data/models/asset_goal_model.dart`
  - toInsertJson()에서 extraRepaidAmount가 0일 때 필드가 누락되는 버그 수정
  - `if (extraRepaidAmount > 0)` -> `'extra_repaid_amount': extraRepaidAmount` 로 변경

## 테스트 결과
- 총 테스트: 547개
- 통과: 547개
- 실패: 0개

## 요약
- AssetLineChart ConsumerWidget 변환에 맞춰 ProviderScope 기반으로 테스트 전면 재작성
- YearlyAsset entity 및 MonthlyAsset entity Equatable 동등성 테스트 19개 작성
- assetChartPeriodProvider/assetSharedStateProvider/assetMonthlyChartProvider/assetYearlyChartProvider 새 Provider 테스트 39개 작성

## 발견된 버그
### AssetGoalModel.toInsertJson() extraRepaidAmount 누락 버그
- 위치: `lib/features/asset/data/models/asset_goal_model.dart:114`
- 문제: extraRepaidAmount가 0일 때 toInsertJson()에서 해당 필드를 포함하지 않아 DB 저장 시 null로 들어갈 수 있음
- 수정: 항상 포함하도록 변경 (`'extra_repaid_amount': extraRepaidAmount`)
