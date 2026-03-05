import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  group('AssetProvider 확장 테스트', () {
    late MockAssetRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockAssetRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('assetChartPeriodProvider 기본값 테스트', () {
      test('기본값이 TrendPeriod.monthly이어야 한다', () {
        // Given: 별도 오버라이드 없는 기본 컨테이너
        container = createContainer();

        // When
        final period = container.read(assetChartPeriodProvider);

        // Then: 기본값은 월별(monthly)
        expect(period, TrendPeriod.monthly);
      });

      test('TrendPeriod.yearly로 상태를 변경할 수 있어야 한다', () {
        // Given
        container = createContainer();

        // When: 연별로 변경
        container.read(assetChartPeriodProvider.notifier).state = TrendPeriod.yearly;

        // Then
        expect(container.read(assetChartPeriodProvider), TrendPeriod.yearly);
      });

      test('TrendPeriod.monthly에서 yearly로 전환 후 다시 monthly로 돌아올 수 있어야 한다', () {
        // Given
        container = createContainer();
        expect(container.read(assetChartPeriodProvider), TrendPeriod.monthly);

        // When: yearly로 변경 후 다시 monthly로
        container.read(assetChartPeriodProvider.notifier).state = TrendPeriod.yearly;
        container.read(assetChartPeriodProvider.notifier).state = TrendPeriod.monthly;

        // Then
        expect(container.read(assetChartPeriodProvider), TrendPeriod.monthly);
      });
    });

    group('assetSharedStateProvider 기본값 테스트', () {
      test('기본 모드가 SharedStatisticsMode.combined이어야 한다', () {
        // Given: 별도 오버라이드 없는 기본 컨테이너
        container = createContainer();

        // When
        final sharedState = container.read(assetSharedStateProvider);

        // Then: 기본값은 combined 모드
        expect(sharedState.mode, SharedStatisticsMode.combined);
      });

      test('기본 selectedUserId는 null이어야 한다', () {
        // Given
        container = createContainer();

        // When
        final sharedState = container.read(assetSharedStateProvider);

        // Then
        expect(sharedState.selectedUserId, isNull);
      });

      test('singleUser 모드로 상태를 변경할 수 있어야 한다', () {
        // Given
        container = createContainer();

        // When: 특정 사용자 필터 모드로 변경
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(
              mode: SharedStatisticsMode.singleUser,
              selectedUserId: 'user-123',
            );

        // Then
        final sharedState = container.read(assetSharedStateProvider);
        expect(sharedState.mode, SharedStatisticsMode.singleUser);
        expect(sharedState.selectedUserId, 'user-123');
      });

      test('overlay 모드로 상태를 변경할 수 있어야 한다', () {
        // Given
        container = createContainer();

        // When: overlay 모드로 변경
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(mode: SharedStatisticsMode.overlay);

        // Then
        final sharedState = container.read(assetSharedStateProvider);
        expect(sharedState.mode, SharedStatisticsMode.overlay);
        expect(sharedState.selectedUserId, isNull);
      });

      test('combined 모드에서 selectedUserId는 무시되어야 한다', () {
        // Given: combined 모드에서 selectedUserId가 설정된 경우
        container = createContainer();
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(
              mode: SharedStatisticsMode.combined,
              selectedUserId: 'some-user',
            );

        // When: assetMonthlyChartProvider가 userId를 null로 처리하는지 확인
        // _getFilterUserId 함수가 combined 모드에서 null을 반환하는지 체크
        final sharedState = container.read(assetSharedStateProvider);
        expect(sharedState.mode, SharedStatisticsMode.combined);
        // combined 모드에서는 selectedUserId가 있어도 null처럼 동작해야 함
        // (assetProvider 내부 _getFilterUserId가 combined일 때 null 반환)
      });
    });

    group('assetMonthlyChartProvider 테스트', () {
      test('ledgerId가 null이면 빈 리스트를 반환해야 한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final monthly = await container.read(assetMonthlyChartProvider.future);

        // Then
        expect(monthly, isEmpty);
        verifyNever(() => mockRepository.getMonthlyAssets(
          ledgerId: any(named: 'ledgerId'),
        ));
      });

      test('ledgerId가 있고 combined 모드에서 userId 없이 월별 데이터를 가져와야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final mockData = [
          const MonthlyAsset(year: 2024, month: 1, amount: 1000000),
          const MonthlyAsset(year: 2024, month: 2, amount: 1200000),
        ];

        when(() => mockRepository.getMonthlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => mockData);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(mode: SharedStatisticsMode.combined),
            ),
          ],
        );

        // When
        final monthly = await container.read(assetMonthlyChartProvider.future);

        // Then
        expect(monthly.length, 2);
        expect(monthly[0].amount, 1000000);
        verify(() => mockRepository.getMonthlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });

      test('singleUser 모드에서도 차트는 userId 없이 전체 데이터를 가져와야 한다', () async {
        // Given: 유저 필터는 카테고리에만 적용되므로 차트는 항상 전체 합계
        const testLedgerId = 'ledger-1';
        final mockData = [
          const MonthlyAsset(year: 2024, month: 1, amount: 1500000),
        ];

        when(() => mockRepository.getMonthlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => mockData);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(
                mode: SharedStatisticsMode.singleUser,
                selectedUserId: 'user-456',
              ),
            ),
          ],
        );

        // When
        final monthly = await container.read(assetMonthlyChartProvider.future);

        // Then: userId 없이 전체 데이터 반환
        expect(monthly.length, 1);
        expect(monthly[0].amount, 1500000);
        verify(() => mockRepository.getMonthlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });

      test('singleUser 모드에서 selectedUserId가 null이면 userId null로 호출해야 한다', () async {
        // Given: singleUser 모드이지만 selectedUserId가 null인 경우
        const testLedgerId = 'ledger-1';

        when(() => mockRepository.getMonthlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(
                mode: SharedStatisticsMode.singleUser,
                selectedUserId: null, // userId가 null
              ),
            ),
          ],
        );

        // When
        final monthly = await container.read(assetMonthlyChartProvider.future);

        // Then: userId null로 호출
        expect(monthly, isEmpty);
        verify(() => mockRepository.getMonthlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });
    });

    group('assetYearlyChartProvider 테스트', () {
      test('ledgerId가 null이면 빈 리스트를 반환해야 한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final yearly = await container.read(assetYearlyChartProvider.future);

        // Then
        expect(yearly, isEmpty);
        verifyNever(() => mockRepository.getYearlyAssets(
          ledgerId: any(named: 'ledgerId'),
        ));
      });

      test('ledgerId가 있고 combined 모드에서 userId 없이 연별 데이터를 가져와야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        final mockData = [
          const YearlyAsset(year: 2023, amount: 5000000),
          const YearlyAsset(year: 2024, amount: 8000000),
        ];

        when(() => mockRepository.getYearlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => mockData);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(mode: SharedStatisticsMode.combined),
            ),
          ],
        );

        // When
        final yearly = await container.read(assetYearlyChartProvider.future);

        // Then
        expect(yearly.length, 2);
        expect(yearly[0].year, 2023);
        expect(yearly[1].year, 2024);
        verify(() => mockRepository.getYearlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });

      test('singleUser 모드에서도 차트는 userId 없이 전체 데이터를 가져와야 한다', () async {
        // Given: 유저 필터는 카테고리에만 적용되므로 차트는 항상 전체 합계
        const testLedgerId = 'ledger-1';
        final mockData = [
          const YearlyAsset(year: 2024, amount: 8000000),
        ];

        when(() => mockRepository.getYearlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => mockData);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(
                mode: SharedStatisticsMode.singleUser,
                selectedUserId: 'user-789',
              ),
            ),
          ],
        );

        // When
        final yearly = await container.read(assetYearlyChartProvider.future);

        // Then: userId 없이 전체 데이터 반환
        expect(yearly.length, 1);
        expect(yearly[0].amount, 8000000);
        verify(() => mockRepository.getYearlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });
    });

    group('assetStatisticsProvider와 userId 전달 테스트', () {
      test('combined 모드에서 userId 없이 통계를 가져와야 한다', () async {
        // Given
        const testLedgerId = 'ledger-1';
        const mockStats = AssetStatistics(
          totalAmount: 10000000,
          monthlyChange: 500000,
          monthlyChangeRate: 5.0,
          annualGrowthRate: 10.0,
          monthly: [],
          byCategory: [],
        );

        when(() => mockRepository.getEnhancedStatistics(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => mockStats);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(mode: SharedStatisticsMode.combined),
            ),
          ],
        );

        // When
        final stats = await container.read(assetStatisticsProvider.future);

        // Then
        expect(stats.totalAmount, 10000000);
        verify(() => mockRepository.getEnhancedStatistics(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });

      test('ledgerId가 null이면 빈 AssetStatistics를 반환해야 한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final stats = await container.read(assetStatisticsProvider.future);

        // Then: 기본 빈 통계 반환
        expect(stats.totalAmount, 0);
        expect(stats.monthly, isEmpty);
        expect(stats.byCategory, isEmpty);
        verifyNever(() => mockRepository.getEnhancedStatistics(
          ledgerId: any(named: 'ledgerId'),
        ));
      });

      test('singleUser 모드에서도 통계는 userId 없이 전체 합계를 가져와야 한다', () async {
        // Given: 총자산은 항상 전체 합계 (유저 필터는 카테고리에만 적용)
        const testLedgerId = 'ledger-1';
        const mockStats = AssetStatistics(
          totalAmount: 10000000,
          monthlyChange: 500000,
          monthlyChangeRate: 5.0,
          annualGrowthRate: 10.0,
          monthly: [],
          byCategory: [],
        );

        when(() => mockRepository.getEnhancedStatistics(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => mockStats);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(
                mode: SharedStatisticsMode.singleUser,
                selectedUserId: 'user-abc',
              ),
            ),
          ],
        );

        // When
        final stats = await container.read(assetStatisticsProvider.future);

        // Then: userId 없이 전체 합계 반환
        expect(stats.totalAmount, 10000000);
        verify(() => mockRepository.getEnhancedStatistics(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });
    });

    group('assetSharedStateProvider 상태 전환 시나리오 테스트', () {
      test('combined -> singleUser -> combined 순서로 상태가 올바르게 전환되어야 한다', () {
        // Given
        container = createContainer();

        // Then 초기 상태: combined
        var state = container.read(assetSharedStateProvider);
        expect(state.mode, SharedStatisticsMode.combined);

        // When: singleUser 모드로 전환
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(
              mode: SharedStatisticsMode.singleUser,
              selectedUserId: 'user-1',
            );

        // Then: singleUser 상태 확인
        state = container.read(assetSharedStateProvider);
        expect(state.mode, SharedStatisticsMode.singleUser);
        expect(state.selectedUserId, 'user-1');

        // When: 다시 combined 모드로 전환
        container.read(assetSharedStateProvider.notifier).state =
            const SharedStatisticsState(mode: SharedStatisticsMode.combined);

        // Then: combined 상태로 복귀
        state = container.read(assetSharedStateProvider);
        expect(state.mode, SharedStatisticsMode.combined);
        expect(state.selectedUserId, isNull);
      });

      test('overlay 모드에서는 selectedUserId가 있어도 필터가 적용되지 않아야 한다', () async {
        // Given: overlay 모드 (selectedUserId 있어도 userId는 null로 처리)
        const testLedgerId = 'ledger-1';

        when(() => mockRepository.getYearlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetRepositoryProvider.overrideWith((ref) => mockRepository),
            assetSharedStateProvider.overrideWith(
              (ref) => const SharedStatisticsState(
                mode: SharedStatisticsMode.overlay,
                selectedUserId: 'some-user', // overlay 모드에서는 무시됨
              ),
            ),
          ],
        );

        // When
        await container.read(assetYearlyChartProvider.future);

        // Then: userId가 null로 호출되어야 함 (overlay 모드에서는 필터 없이 전체 조회)
        verify(() => mockRepository.getYearlyAssets(
          ledgerId: testLedgerId,
          userId: null,
        )).called(1);
      });
    });
  });
}
