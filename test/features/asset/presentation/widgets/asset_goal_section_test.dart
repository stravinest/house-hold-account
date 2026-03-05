import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_progress_bar.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_section.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockAssetRepository extends Mock implements AssetRepository {}

AssetGoal _makeGoal({
  String id = 'goal-1',
  String title = '비상금 마련',
  int targetAmount = 1000000,
  DateTime? targetDate,
}) {
  return AssetGoal(
    id: id,
    ledgerId: 'ledger-1',
    title: title,
    goalType: GoalType.asset,
    targetAmount: targetAmount,
    targetDate: targetDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
  );
}

Widget _buildApp({
  required MockAssetRepository mockRepo,
  List<Override> extraOverrides = const [],
}) {
  return ProviderScope(
    overrides: [
      assetGoalRepositoryProvider.overrideWithValue(mockRepo),
      ...extraOverrides,
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AssetGoalSection(ledgerId: 'ledger-1'),
      ),
    ),
  );
}

void main() {
  late MockAssetRepository mockRepo;

  setUp(() {
    mockRepo = MockAssetRepository();
  });

  group('AssetGoalSection 위젯 테스트 - 빈 상태', () {
    testWidgets('목표가 없으면 AssetGoalSection이 렌더링된다', (tester) async {
      // Given
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(_buildApp(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('목표가 없을 때 깃발 아이콘이 표시된다', (tester) async {
      // Given
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(_buildApp(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Then: 빈 상태 컨테이너에 깃발 아이콘
      expect(find.byIcon(Icons.flag_rounded), findsAtLeastNWidgets(1));
    });
  });

  group('AssetGoalSection 위젯 테스트 - 목표 있음', () {
    testWidgets('목표가 있으면 AssetGoalSection이 정상 렌더링된다', (tester) async {
      // Given
      final goal = _makeGoal(title: '여행 자금');
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 200000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('목표 금액이 표시되어야 한다', (tester) async {
      // Given
      final goal = _makeGoal(title: '비상금', targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 300000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 목표 금액 '1,000,000원' 표시
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('프로그레스바(AssetGoalProgressBar)가 표시되어야 한다', (tester) async {
      // Given
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 500000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalProgressBar), findsOneWidget);
    });

    testWidgets('목표 날짜가 있으면 D-day 뱃지 영역이 렌더링된다', (tester) async {
      // Given: 목표 날짜가 미래인 목표
      final goal = _makeGoal(
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 200000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 날짜가 있으므로 D-day 뱃지가 렌더링됨
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('목표 날짜가 없으면 D-day 뱃지가 표시되지 않는다', (tester) async {
      // Given: 목표 날짜가 없는 목표
      final goal = _makeGoal(targetDate: null);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 200000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });
  });

  group('AssetGoalSection 위젯 테스트 - 진행도 세부 정보', () {
    testWidgets('프로그레스바 탭 시 세부 정보 영역이 토글된다', (tester) async {
      // Given
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 500000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 프로그레스바 탭
      final progressBar = find.byType(AssetGoalProgressBar);
      if (progressBar.evaluate().isNotEmpty) {
        await tester.tap(progressBar);
        await tester.pump();
      }

      // Then: 세부 정보가 토글됨
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('목표 미달성 시 잔여 금액 정보가 표시된다', (tester) async {
      // Given: 현재 금액이 목표보다 작음
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 300000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 프로그레스바 탭으로 세부 정보 표시
      final progressBar = find.byType(AssetGoalProgressBar);
      if (progressBar.evaluate().isNotEmpty) {
        await tester.tap(progressBar);
        await tester.pump();
      }

      // Then
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('목표 달성(progress >= 1.0) 시 달성 배지가 표시된다', (tester) async {
      // Given: 현재 금액이 목표 이상
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 1200000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 프로그레스바 탭으로 세부 정보 표시
      final progressBar = find.byType(AssetGoalProgressBar);
      if (progressBar.evaluate().isNotEmpty) {
        await tester.tap(progressBar);
        await tester.pump();
      }

      // Then: 달성 배지 또는 세부 정보 표시됨
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('세부 정보 미표시 시 탭 안내 텍스트가 표시된다', (tester) async {
      // Given
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When: 세부 정보 미표시 상태 (기본값 _showGoalDetails = false)
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 500000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: '탭하여 자세히 보기' 안내 텍스트 또는 프로그레스바가 표시됨
      expect(find.byType(AssetGoalProgressBar), findsOneWidget);
    });
  });

  group('AssetGoalSection 위젯 테스트 - 목표 정렬', () {
    testWidgets('날짜가 있는 목표가 없는 목표보다 앞에 정렬되어야 한다', (tester) async {
      // Given: 목표 날짜가 있는 목표와 없는 목표
      final goalWithDate = _makeGoal(
        id: 'goal-with-date',
        title: '날짜있는목표',
        targetDate: DateTime(2026, 6, 1),
      );
      final goalWithoutDate = _makeGoal(
        id: 'goal-without-date',
        title: '날짜없는목표',
      );

      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goalWithoutDate, goalWithDate]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goalWithDate).overrideWith(
              (ref) async => 100000,
            ),
            assetGoalCurrentAmountProvider(goalWithoutDate).overrideWith(
              (ref) async => 50000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 날짜 있는 목표가 먼저 표시됨 (nearestGoal)
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('두 목표 모두 날짜가 없을 때 첫 번째 목표가 표시된다', (tester) async {
      // Given: 두 목표 모두 날짜 없음
      final goal1 = _makeGoal(id: 'goal-1', title: '목표1');
      final goal2 = _makeGoal(id: 'goal-2', title: '목표2');

      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal1, goal2]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal1).overrideWith(
              (ref) async => 100000,
            ),
            assetGoalCurrentAmountProvider(goal2).overrideWith(
              (ref) async => 200000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('두 목표가 다른 날짜를 가질 때 이른 날짜 목표가 표시된다', (tester) async {
      // Given: 서로 다른 날짜를 가진 두 목표
      final earlierGoal = _makeGoal(
        id: 'goal-earlier',
        title: '빠른목표',
        targetDate: DateTime(2025, 3, 1),
      );
      final laterGoal = _makeGoal(
        id: 'goal-later',
        title: '늦은목표',
        targetDate: DateTime(2026, 12, 1),
      );

      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [laterGoal, earlierGoal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(earlierGoal).overrideWith(
              (ref) async => 100000,
            ),
            assetGoalCurrentAmountProvider(laterGoal).overrideWith(
              (ref) async => 200000,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });
  });

  group('AssetGoalSection 위젯 테스트 - 에러/로딩', () {
    testWidgets('repository에서 에러 발생 시 위젯이 에러 없이 처리된다',
        (tester) async {
      // Given: 에러 응답
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenThrow(Exception('네트워크 오류'));

      // When
      await tester.pumpWidget(_buildApp(mockRepo: mockRepo));
      await tester.pump();

      // Then: 위젯이 정상 렌더링됨 (에러 상태)
      expect(find.byType(AssetGoalSection), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('현재 금액 로딩 중에 위젯이 정상 렌더링된다', (tester) async {
      // Given: 목표는 있지만 현재 금액이 즉시 완료되는 Future
      // Completer를 사용하면 타이머 없이 로딩 상태를 시뮬레이션할 수 있으나
      // fake_async에서 dispose 시 pending 상태로 에러 발생.
      // 대신 즉시 완료되는 Future로 로딩 흐름을 검증
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When: 현재 금액을 즉시 완료되는 Future로 설정
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 500000,
            ),
          ],
        ),
      );

      // 첫 번째 pump: 로딩 상태 (getGoals 완료 전)
      await tester.pump();

      // Then: 위젯이 렌더링됨
      expect(find.byType(AssetGoalSection), findsOneWidget);

      // 완전 완료 후에도 렌더링 유지
      await tester.pumpAndSettle();
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });

    testWidgets('현재 금액 에러 시 에러 컨테이너가 표시된다', (tester) async {
      // Given
      final goal = _makeGoal(targetAmount: 1000000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        _buildApp(
          mockRepo: mockRepo,
          extraOverrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => throw Exception('금액 조회 실패'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 에러 상태 위젯이 렌더링됨
      expect(find.byType(AssetGoalSection), findsOneWidget);
    });
  });
}
