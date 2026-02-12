import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('StatisticsProvider Tests', () {
    late MockStatisticsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockStatisticsRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('statisticsRepositoryProvider는 StatisticsRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(statisticsRepositoryProvider);

      // Then
      expect(repository, isA<StatisticsRepository>());
    });

    // 엔티티 구조가 변경되어 복잡한 테스트는 통합 테스트에서 검증
  });
}
