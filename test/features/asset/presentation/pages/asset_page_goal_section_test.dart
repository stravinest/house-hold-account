import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';

import '../../../../helpers/test_helpers.dart';

/// notifier의 비동기 로딩이 완료될 때까지 대기하는 헬퍼
Future<AsyncValue<List<AssetGoal>>> waitForNotifier(
  ProviderContainer container,
  String ledgerId, {
  Duration timeout = const Duration(seconds: 2),
}) async {
  final stopwatch = Stopwatch()..start();
  while (stopwatch.elapsed < timeout) {
    final state = container.read(assetGoalNotifierProvider(ledgerId));
    if (state is! AsyncLoading) return state;
    await Future.delayed(const Duration(milliseconds: 10));
  }
  return container.read(assetGoalNotifierProvider(ledgerId));
}

void main() {
  const testLedgerId = 'test-ledger-id';
  final now = DateTime.now();

  late MockAssetRepository mockRepository;

  final assetGoal1 = AssetGoal(
    id: 'asset-1',
    ledgerId: testLedgerId,
    title: '비상금 모으기',
    targetAmount: 10000000,
    createdAt: now,
    updatedAt: now,
    createdBy: 'user-1',
    goalType: GoalType.asset,
  );

  final assetGoal2 = AssetGoal(
    id: 'asset-2',
    ledgerId: testLedgerId,
    title: '여행 자금',
    targetAmount: 5000000,
    createdAt: now,
    updatedAt: now,
    createdBy: 'user-1',
    goalType: GoalType.asset,
  );

  final loanGoal1 = AssetGoal(
    id: 'loan-1',
    ledgerId: testLedgerId,
    title: '주택담보대출',
    targetAmount: 300000000,
    createdAt: now,
    updatedAt: now,
    createdBy: 'user-1',
    goalType: GoalType.loan,
    loanAmount: 300000000,
  );

  final loanGoal2 = AssetGoal(
    id: 'loan-2',
    ledgerId: testLedgerId,
    title: '자동차 할부',
    targetAmount: 30000000,
    createdAt: now,
    updatedAt: now,
    createdBy: 'user-1',
    goalType: GoalType.loan,
    loanAmount: 30000000,
  );

  setUp(() {
    mockRepository = MockAssetRepository();
  });

  group('assetGoalNotifierProvider 직접 watch 기반 목표 필터링 테스트', () {
    test('notifier 상태에서 자산 목표(GoalType.asset)만 올바르게 필터링할 수 있어야 한다', () async {
      // Given: repository가 자산 + 대출 목표를 모두 반환
      final allGoals = [assetGoal1, loanGoal1, assetGoal2, loanGoal2];
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => allGoals);

      final container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When: provider를 먼저 읽어 생성을 트리거하고, 로딩 완료 대기
      container.read(assetGoalNotifierProvider(testLedgerId));
      final state = await waitForNotifier(container, testLedgerId);

      // Then: data 상태에서 goalType별 필터링이 정확해야 함
      expect(state, isA<AsyncData<List<AssetGoal>>>());
      final goals = state.value!;

      // 자산 목표만 필터링 (asset_page의 _AssetGoalSection이 해야 할 로직)
      final assetOnly = goals.where((g) => g.goalType == GoalType.asset).toList();
      expect(assetOnly.length, 2, reason: '자산 목표는 2개여야 한다');
      expect(assetOnly.map((g) => g.title), containsAll(['비상금 모으기', '여행 자금']));

      // 대출 목표만 필터링 (asset_page의 _LoanGoalSection이 해야 할 로직)
      final loanOnly = goals.where((g) => g.goalType == GoalType.loan).toList();
      expect(loanOnly.length, 2, reason: '대출 목표는 2개여야 한다');
      expect(loanOnly.map((g) => g.title), containsAll(['주택담보대출', '자동차 할부']));

      container.dispose();
    });

    test('notifier는 내부에서 getGoals를 호출하므로 별도 invalidate 없이 상태가 갱신된다', () async {
      // Given: 처음에는 빈 목록으로 시작
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // 초기 로딩 트리거 및 대기
      container.read(assetGoalNotifierProvider(testLedgerId));
      final initialState = await waitForNotifier(container, testLedgerId);
      expect(initialState, isA<AsyncData<List<AssetGoal>>>());
      expect(initialState.value, isEmpty);

      // When: repository가 이제 목표를 반환하도록 변경하고, notifier를 refresh
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => [assetGoal1, loanGoal1]);

      container.refresh(assetGoalNotifierProvider(testLedgerId));
      final updatedState = await waitForNotifier(container, testLedgerId);

      // Then: notifier 상태가 최신 데이터로 갱신됨
      expect(updatedState, isA<AsyncData<List<AssetGoal>>>());
      expect(updatedState.value!.length, 2);

      final assetOnly = updatedState.value!.where((g) => g.goalType == GoalType.asset).toList();
      expect(assetOnly.length, 1);
      expect(assetOnly.first.title, '비상금 모으기');

      final loanOnly = updatedState.value!.where((g) => g.goalType == GoalType.loan).toList();
      expect(loanOnly.length, 1);
      expect(loanOnly.first.title, '주택담보대출');

      container.dispose();
    });

    test('FutureProvider와 StateNotifier는 독립적이므로 notifier 갱신이 FutureProvider에 전파되지 않는다 (버그 재현)', () async {
      // Given: 처음에는 빈 목록
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // 두 provider 모두 초기화
      container.read(assetGoalNotifierProvider(testLedgerId));
      await waitForNotifier(container, testLedgerId);
      final futureInitial = await container.read(assetGoalsProvider.future);
      expect(futureInitial, isEmpty);

      // When: repository가 이제 목표를 반환, notifier만 refresh
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => [assetGoal1, loanGoal1]);

      container.refresh(assetGoalNotifierProvider(testLedgerId));
      await waitForNotifier(container, testLedgerId);

      // Then: notifier는 갱신됨
      final notifierUpdated = container.read(assetGoalNotifierProvider(testLedgerId));
      expect(notifierUpdated.value!.length, 2, reason: 'notifier는 refresh 후 갱신됨');

      // FutureProvider는 갱신되지 않음 (별도의 invalidate 필요)
      // 이것이 asset_page에서 목표가 보이지 않는 근본 원인
      final futureStale = await container.read(assetGoalsProvider.future);
      expect(futureStale, isEmpty,
          reason: 'FutureProvider는 notifier 갱신과 무관하게 캐시된 결과를 유지한다 (버그 원인)');

      container.dispose();
    });

    test('목표가 비어있을 때 필터링 결과도 빈 리스트여야 한다', () async {
      // Given
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => []);

      final container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      container.read(assetGoalNotifierProvider(testLedgerId));
      final state = await waitForNotifier(container, testLedgerId);

      // Then
      expect(state, isA<AsyncData<List<AssetGoal>>>());
      final goals = state.value!;

      expect(goals.where((g) => g.goalType == GoalType.asset).toList(), isEmpty);
      expect(goals.where((g) => g.goalType == GoalType.loan).toList(), isEmpty);

      container.dispose();
    });

    test('자산 목표만 있을 때 대출 필터링 결과는 비어있어야 한다', () async {
      // Given
      when(() => mockRepository.getGoals(ledgerId: testLedgerId))
          .thenAnswer((_) async => [assetGoal1, assetGoal2]);

      final container = createContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      container.read(assetGoalNotifierProvider(testLedgerId));
      final state = await waitForNotifier(container, testLedgerId);

      // Then
      final goals = state.value!;
      expect(goals.where((g) => g.goalType == GoalType.asset).toList().length, 2);
      expect(goals.where((g) => g.goalType == GoalType.loan).toList(), isEmpty);

      container.dispose();
    });
  });
}
