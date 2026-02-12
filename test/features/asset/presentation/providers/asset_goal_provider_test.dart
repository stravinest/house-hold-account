import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('AssetGoalProvider Tests', () {
    late MockAssetRepository mockRepository;
    late ProviderContainer container;

    setUpAll(() {
      registerFallbackValue(
        AssetGoal(
          id: 'test-id',
          ledgerId: 'test-ledger',
          title: 'test',
          targetAmount: 1000000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'test-user',
        ),
      );
    });

    setUp(() {
      mockRepository = MockAssetRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('assetGoalsProvider', () {
      test('ledgerId가 null인 경우 빈 리스트를 반환한다', () async {
        // Given
        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => null),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final goals = await container.read(assetGoalsProvider.future);

        // Then
        expect(goals, isEmpty);
        verifyNever(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')));
      });

      test('ledgerId가 있는 경우 목표 목록을 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockGoals = [
          AssetGoal(
            id: 'goal-1',
            ledgerId: testLedgerId,
            title: '비상금 모으기',
            targetAmount: 10000000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'user-1',
          ),
          AssetGoal(
            id: 'goal-2',
            ledgerId: testLedgerId,
            title: '주택 구입 자금',
            targetAmount: 500000000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            createdBy: 'user-1',
          ),
        ];

        when(() => mockRepository.getGoals(ledgerId: testLedgerId))
            .thenAnswer((_) async => mockGoals);

        container = createContainer(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final goals = await container.read(assetGoalsProvider.future);

        // Then
        expect(goals.length, equals(2));
        expect(goals[0].title, equals('비상금 모으기'));
        expect(goals[1].title, equals('주택 구입 자금'));
        verify(() => mockRepository.getGoals(ledgerId: testLedgerId)).called(1);
      });
    });


    group('assetGoalRemainingDaysProvider', () {
      test('목표 날짜가 있는 경우 남은 일수를 계산한다', () {
        // Given
        final now = DateTime.now();
        final targetDate = now.add(const Duration(days: 30));

        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          targetDate: targetDate,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
        );

        container = createContainer();

        // When
        final remainingDays =
            container.read(assetGoalRemainingDaysProvider(goal));

        // Then: 약 30일
        expect(remainingDays, isNotNull);
        expect(remainingDays! >= 29 && remainingDays <= 30, isTrue);
      });

      test('목표 날짜가 없는 경우 null을 반환한다', () {
        // Given
        final goal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          targetDate: null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          createdBy: 'user-1',
        );

        container = createContainer();

        // When
        final remainingDays =
            container.read(assetGoalRemainingDaysProvider(goal));

        // Then
        expect(remainingDays, isNull);
      });
    });
  });
}
