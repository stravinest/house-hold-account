import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/statistics/domain/entities/statistics_entities.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AssetProvider Tests', () {
    late MockAssetRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAssetRepository();
    });

    tearDown(() {
      container.dispose();
    });

    // assetRepositoryProvider는 Supabase 초기화가 필요하므로 통합 테스트에서 검증

    group('assetStatisticsProvider', () {
      test('ledgerId가 null일 때 빈 통계 객체를 반환한다', () async {
        // Given: ledgerId가 null인 상태
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        // When
        final statistics = await container.read(assetStatisticsProvider.future);

        // Then: 빈 AssetStatistics 반환
        expect(statistics.totalAmount, equals(0));
        expect(statistics.monthlyChange, equals(0));
        expect(statistics.monthlyChangeRate, equals(0.0));
        expect(statistics.annualGrowthRate, equals(0.0));
        expect(statistics.monthly, isEmpty);
        expect(statistics.byCategory, isEmpty);
      });

      test('ledgerId가 존재할 때 repository에서 자산 통계를 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockStatistics = AssetStatistics(
          totalAmount: 1000000,
          monthlyChange: 50000,
          monthlyChangeRate: 5.0,
          annualGrowthRate: 60.0,
          monthly: const [],
          byCategory: const [],
        );

        when(() => mockRepository.getEnhancedStatistics(
              ledgerId: testLedgerId, userId: any(named: 'userId')))
            .thenAnswer((_) async => mockStatistics);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final statistics = await container.read(assetStatisticsProvider.future);

        // Then
        expect(statistics.totalAmount, equals(1000000));
        expect(statistics.monthlyChange, equals(50000));
        expect(statistics.monthlyChangeRate, equals(5.0));
        expect(statistics.annualGrowthRate, equals(60.0));
        verify(() => mockRepository.getEnhancedStatistics(
              ledgerId: testLedgerId, userId: any(named: 'userId')))
            .called(1);
      });

      test('repository에서 에러 발생 시 AsyncError 상태를 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final exception = Exception('데이터베이스 오류');

        when(() => mockRepository.getEnhancedStatistics(
              ledgerId: testLedgerId, userId: any(named: 'userId')))
            .thenThrow(exception);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When & Then
        expect(
          () => container.read(assetStatisticsProvider.future),
          throwsA(exception),
        );
      });

      test('ledgerId 변경 시 통계 데이터가 다시 로드된다', () async {
        // Given
        const ledgerId1 = 'ledger-1';
        const ledgerId2 = 'ledger-2';

        final stats1 = AssetStatistics(
          totalAmount: 1000000,
          monthlyChange: 50000,
          monthlyChangeRate: 5.0,
          annualGrowthRate: 60.0,
          monthly: const [],
          byCategory: const [],
        );

        final stats2 = AssetStatistics(
          totalAmount: 2000000,
          monthlyChange: 100000,
          monthlyChangeRate: 5.0,
          annualGrowthRate: 60.0,
          monthly: const [],
          byCategory: const [],
        );

        when(() => mockRepository.getEnhancedStatistics(
              ledgerId: ledgerId1, userId: any(named: 'userId')))
            .thenAnswer((_) async => stats1);
        when(() => mockRepository.getEnhancedStatistics(
              ledgerId: ledgerId2, userId: any(named: 'userId')))
            .thenAnswer((_) async => stats2);

        container = createContainer(
          overrides: [
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When: ledgerId1로 조회
        container.read(selectedLedgerIdProvider.notifier).state = ledgerId1;
        final result1 = await container.read(assetStatisticsProvider.future);

        // Then
        expect(result1.totalAmount, equals(1000000));

        // When: ledgerId2로 변경
        container.read(selectedLedgerIdProvider.notifier).state = ledgerId2;
        final result2 = await container.read(assetStatisticsProvider.future);

        // Then
        expect(result2.totalAmount, equals(2000000));
        verify(() => mockRepository.getEnhancedStatistics(
              ledgerId: ledgerId1, userId: any(named: 'userId')))
            .called(1);
        verify(() => mockRepository.getEnhancedStatistics(
              ledgerId: ledgerId2, userId: any(named: 'userId')))
            .called(1);
      });
    });

    group('assetChartPeriodProvider - 기간 선택 Provider', () {
      test('기본값이 TrendPeriod.monthly여야 한다', () {
        // Given
        container = createContainer();

        // When
        final period = container.read(assetChartPeriodProvider);

        // Then: 기본값은 월별
        expect(period, equals(TrendPeriod.monthly));
      });

      test('연별로 변경하면 TrendPeriod.yearly가 되어야 한다', () {
        // Given
        container = createContainer();

        // When: 연별로 변경
        container.read(assetChartPeriodProvider.notifier).state =
            TrendPeriod.yearly;

        // Then
        expect(
          container.read(assetChartPeriodProvider),
          equals(TrendPeriod.yearly),
        );
      });
    });

    group('assetSharedStateProvider - 유저 필터 Provider', () {
      test('기본값이 combined 모드여야 한다', () {
        // Given
        container = createContainer();

        // When
        final state = container.read(assetSharedStateProvider);

        // Then: 기본값은 합계 모드
        expect(state.mode, equals(SharedStatisticsMode.combined));
        expect(state.selectedUserId, isNull);
      });

      test('특정 유저를 선택하면 singleUser 모드로 변경되어야 한다', () {
        // Given
        container = createContainer();
        const testUserId = 'user-123';

        // When: 유저 선택
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(
          mode: SharedStatisticsMode.singleUser,
          selectedUserId: testUserId,
        );

        // Then
        final state = container.read(assetSharedStateProvider);
        expect(state.mode, equals(SharedStatisticsMode.singleUser));
        expect(state.selectedUserId, equals(testUserId));
      });

      test('합계로 되돌리면 combined 모드로 변경되어야 한다', () {
        // Given
        container = createContainer();

        // 유저 선택 상태로 변경
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(
          mode: SharedStatisticsMode.singleUser,
          selectedUserId: 'user-123',
        );

        // When: 합계로 복귀
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(
          mode: SharedStatisticsMode.combined,
        );

        // Then
        final state = container.read(assetSharedStateProvider);
        expect(state.mode, equals(SharedStatisticsMode.combined));
        expect(state.selectedUserId, isNull);
      });
    });

    group('assetMonthlyChartProvider - 월별 차트 데이터', () {
      test('ledgerId가 null일 때 빈 리스트를 반환한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        // When
        final monthly =
            await container.read(assetMonthlyChartProvider.future);

        // Then
        expect(monthly, isEmpty);
      });

      test('ledgerId가 존재할 때 repository에서 월별 데이터를 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger';
        const mockMonthly = [
          MonthlyAsset(year: 2024, month: 1, amount: 1000000),
          MonthlyAsset(year: 2024, month: 2, amount: 1500000),
        ];

        when(() => mockRepository.getMonthlyAssets(
              ledgerId: testLedgerId,
              userId: any(named: 'userId'),
            )).thenAnswer((_) async => mockMonthly);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final monthly =
            await container.read(assetMonthlyChartProvider.future);

        // Then
        expect(monthly, equals(mockMonthly));
        expect(monthly.length, equals(2));
      });
    });

    group('assetYearlyChartProvider - 연별 차트 데이터', () {
      test('ledgerId가 null일 때 빈 리스트를 반환한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        // When
        final yearly =
            await container.read(assetYearlyChartProvider.future);

        // Then
        expect(yearly, isEmpty);
      });

      test('ledgerId가 존재할 때 repository에서 연별 데이터를 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger';
        const mockYearly = [
          YearlyAsset(year: 2022, amount: 5000000),
          YearlyAsset(year: 2023, amount: 8000000),
          YearlyAsset(year: 2024, amount: 12000000),
        ];

        when(() => mockRepository.getYearlyAssets(
              ledgerId: testLedgerId,
              userId: any(named: 'userId'),
            )).thenAnswer((_) async => mockYearly);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final yearly =
            await container.read(assetYearlyChartProvider.future);

        // Then
        expect(yearly, equals(mockYearly));
        expect(yearly.length, equals(3));
      });
    });
  });
}
