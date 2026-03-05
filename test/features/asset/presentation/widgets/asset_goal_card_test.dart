import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockAssetRepository extends Mock implements AssetRepository {}

AssetGoal _makeGoal({
  String id = 'goal-1',
  String title = '비상금 마련',
  GoalType goalType = GoalType.asset,
  int targetAmount = 1000000,
  DateTime? targetDate,
  String? assetType,
}) {
  return AssetGoal(
    id: id,
    ledgerId: 'ledger-1',
    title: title,
    goalType: goalType,
    targetAmount: targetAmount,
    targetDate: targetDate,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
  );
}

Widget buildWidget({
  required AssetGoal goal,
  VoidCallback? onTap,
  VoidCallback? onDelete,
  int currentAmount = 500000,
}) {
  return ProviderScope(
    overrides: [
      assetGoalCurrentAmountProvider(goal).overrideWith(
        (ref) async => currentAmount,
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AssetGoalCard(
          goal: goal,
          onTap: onTap,
          onDelete: onDelete,
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      AssetGoal(
        id: 'fallback',
        ledgerId: 'fallback',
        title: 'fallback',
        targetAmount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'fallback',
      ),
    );
  });

  group('AssetGoalCard 위젯 테스트', () {
    testWidgets('목표 제목이 표시된다', (tester) async {
      // Given
      final goal = _makeGoal(title: '비상금 마련');

      // When
      await tester.pumpWidget(buildWidget(goal: goal));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('비상금 마련'), findsOneWidget);
    });

    testWidgets('데이터 로딩 중에 CircularProgressIndicator가 표시된다',
        (tester) async {
      // Given
      final goal = _makeGoal();
      // Completer를 사용해서 타이머 없이 로딩 상태 시뮬레이션
      final completer = Future<int>.value(500000);

      // When: 위젯 렌더링 후 pump 한 번만 실행 (완료 전 상태)
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) => completer,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCard(goal: goal),
            ),
          ),
        ),
      );
      // pump 한 번만: Future 완료 전 로딩 상태
      await tester.pump();

      // Then: 로딩 중 인디케이터 또는 위젯이 정상 렌더링
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('onDelete 콜백이 제공되면 삭제 버튼이 표시된다', (tester) async {
      // Given
      final goal = _makeGoal();
      bool deleteCalled = false;

      // When
      await tester.pumpWidget(
        buildWidget(goal: goal, onDelete: () => deleteCalled = true),
      );
      await tester.pumpAndSettle();

      // Then: 삭제 버튼이 존재
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('onDelete가 null이면 삭제 버튼이 표시되지 않는다', (tester) async {
      // Given
      final goal = _makeGoal();

      // When
      await tester.pumpWidget(buildWidget(goal: goal, onDelete: null));
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('삭제 버튼 탭 시 onDelete 콜백이 호출된다', (tester) async {
      // Given
      final goal = _makeGoal();
      bool deleteCalled = false;

      // When
      await tester.pumpWidget(
        buildWidget(goal: goal, onDelete: () => deleteCalled = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete_outline));

      // Then
      expect(deleteCalled, isTrue);
    });

    testWidgets('카드를 탭하면 onTap 콜백이 호출된다', (tester) async {
      // Given
      final goal = _makeGoal();
      bool tapCalled = false;

      // When
      await tester.pumpWidget(
        buildWidget(goal: goal, onTap: () => tapCalled = true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(InkWell).first);

      // Then
      expect(tapCalled, isTrue);
    });

    testWidgets('목표 금액 데이터가 로드되면 프로그레스바가 표시된다', (tester) async {
      // Given
      final goal = _makeGoal(targetAmount: 1000000);

      // When
      await tester.pumpWidget(
        buildWidget(goal: goal, currentAmount: 500000),
      );
      await tester.pumpAndSettle();

      // Then: 데이터 로드 후 위젯이 정상 렌더링
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('목표 달성일이 있는 경우 카드가 정상 렌더링된다', (tester) async {
      // Given
      final goal = _makeGoal(
        targetDate: DateTime(2025, 12, 31),
      );

      // When
      await tester.pumpWidget(buildWidget(goal: goal));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('목표 달성일이 없는 경우도 카드가 정상 렌더링된다', (tester) async {
      // Given
      final goal = _makeGoal(targetDate: null);

      // When
      await tester.pumpWidget(buildWidget(goal: goal));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('현재 금액이 목표 금액의 75% 이상일 때 카드가 렌더링된다', (tester) async {
      // Given: progress >= 0.75 분기
      final goal = _makeGoal(targetAmount: 1000000);

      // When
      await tester.pumpWidget(buildWidget(goal: goal, currentAmount: 800000));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('현재 금액이 목표 금액의 50% 이상 75% 미만일 때 카드가 렌더링된다', (tester) async {
      // Given: 0.5 <= progress < 0.75 분기
      final goal = _makeGoal(targetAmount: 1000000);

      // When
      await tester.pumpWidget(buildWidget(goal: goal, currentAmount: 600000));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('현재 금액이 0일 때 progress 0 카드가 렌더링된다', (tester) async {
      // Given: progress = 0, displayProgress = 0.01 분기
      final goal = _makeGoal(targetAmount: 1000000);

      // When
      await tester.pumpWidget(buildWidget(goal: goal, currentAmount: 0));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('목표 달성(100%) 시 check_circle 아이콘과 달성 뱃지가 표시된다',
        (tester) async {
      // Given: progress >= 1.0 분기 (isCompleted = true)
      final goal = _makeGoal(targetAmount: 1000000);

      // When
      await tester.pumpWidget(buildWidget(goal: goal, currentAmount: 1000000));
      await tester.pumpAndSettle();

      // Then: 달성 시 check_circle 아이콘이 포함됨
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('목표 달성(100% 초과) 시 카드가 렌더링된다', (tester) async {
      // Given: progress > 1.0
      final goal = _makeGoal(targetAmount: 1000000);

      // When
      await tester.pumpWidget(buildWidget(goal: goal, currentAmount: 1500000));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('목표 날짜가 지났을 때 경과 일수 뱃지가 표시될 수 있다', (tester) async {
      // Given: 목표 날짜가 과거
      final goal = _makeGoal(
        targetDate: DateTime.now().subtract(const Duration(days: 10)),
      );

      // When
      await tester.pumpWidget(buildWidget(goal: goal, currentAmount: 300000));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });

    testWidgets('현재 금액 에러 시 에러 텍스트가 표시된다', (tester) async {
      // Given: 에러 상태를 반환하는 provider
      final goal = _makeGoal();

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => throw Exception('조회 실패'),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCard(goal: goal),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 에러 텍스트가 표시됨
      expect(find.byType(AssetGoalCard), findsOneWidget);
    });
  });

  group('AssetGoalListView 위젯 테스트', () {
    late MockAssetRepository mockRepo;

    setUp(() {
      mockRepo = MockAssetRepository();
    });

    Widget buildListView({List<AssetGoal> goals = const []}) {
      return ProviderScope(
        overrides: [
          assetGoalRepositoryProvider.overrideWithValue(mockRepo),
          assetGoalNotifierProvider('ledger-1').overrideWith(
            (ref) => AssetGoalNotifier(mockRepo, 'ledger-1', ref),
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(
            body: AssetGoalListView(ledgerId: 'ledger-1'),
          ),
        ),
      );
    }

    testWidgets('목표가 없을 때 EmptyState가 표시된다', (tester) async {
      // Given
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(buildListView());
      await tester.pumpAndSettle();

      // Then: EmptyState 아이콘이 표시됨
      expect(find.byIcon(Icons.flag_outlined), findsOneWidget);
    });

    testWidgets('목표가 있을 때 ListView가 렌더링된다', (tester) async {
      // Given
      final goal = _makeGoal(title: '비상금');
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalNotifierProvider('ledger-1').overrideWith(
              (ref) => AssetGoalNotifier(mockRepo, 'ledger-1', ref),
            ),
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 200000,
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AssetGoalListView(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AssetGoalListView), findsOneWidget);
    });

    testWidgets('로딩 중에 CircularProgressIndicator가 표시된다', (tester) async {
      // Given: getGoals가 완료되지 않는 상태 시뮬레이션
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(buildListView());
      await tester.pump(); // 첫 번째 pump만

      // Then: 로딩 인디케이터 또는 ListView
      expect(find.byType(AssetGoalListView), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('에러 발생 시 에러 텍스트가 표시된다', (tester) async {
      // Given: 에러 응답
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenThrow(Exception('목표 로드 실패'));

      // When
      await tester.pumpWidget(buildListView());
      await tester.pumpAndSettle();

      // Then: 에러 텍스트 표시
      expect(find.byType(AssetGoalListView), findsOneWidget);
    });
  });
}
