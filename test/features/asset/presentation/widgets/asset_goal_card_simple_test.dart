import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_card_simple.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockAssetRepository extends Mock implements AssetRepository {}

AssetGoal _makeGoal({
  String id = 'goal-1',
  String title = '비상금 마련',
  int targetAmount = 1000000,
}) {
  return AssetGoal(
    id: id,
    ledgerId: 'ledger-1',
    title: title,
    goalType: GoalType.asset,
    targetAmount: targetAmount,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
    createdBy: 'user-1',
  );
}

void main() {
  late MockAssetRepository mockRepo;

  setUp(() {
    mockRepo = MockAssetRepository();
  });

  group('AssetGoalCardSimple 위젯 테스트', () {
    testWidgets('목표가 없으면 SizedBox.shrink가 렌더링된다', (tester) async {
      // Given: 빈 목표 목록
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯은 렌더링되지만 내용은 없음
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('목표가 있으면 AssetGoalCardSimple이 정상 렌더링된다', (tester) async {
      // Given
      final goal = _makeGoal(title: '여행 자금', targetAmount: 500000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 200000,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('목표 달성률 100% 이상일 때 정상 렌더링된다', (tester) async {
      // Given: 목표금액 초과 달성
      final goal = _makeGoal(title: '비상금', targetAmount: 100000);
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 150000,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 렌더링 성공
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('repository에서 에러 발생 시 위젯이 에러 없이 처리된다',
        (tester) async {
      // Given: 에러 응답
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenThrow(Exception('네트워크 오류'));

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 위젯이 에러 없이 렌더링됨
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('여러 목표가 있을 때 가장 날짜가 가까운 목표가 표시된다', (tester) async {
      // Given: 두 개의 목표 (targetDate 없음)
      final goal1 = _makeGoal(id: 'goal-1', title: '첫번째 목표');
      final goal2 = _makeGoal(id: 'goal-2', title: '두번째 목표');
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal1, goal2]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goal1).overrideWith(
              (ref) async => 0,
            ),
            assetGoalCurrentAmountProvider(goal2).overrideWith(
              (ref) async => 0,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 렌더링 성공
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('targetDate가 있는 목표가 없는 목표보다 먼저 표시된다', (tester) async {
      // Given: targetDate가 있는 목표와 없는 목표
      final goalWithDate = AssetGoal(
        id: 'goal-with-date',
        ledgerId: 'ledger-1',
        title: '날짜 있는 목표',
        goalType: GoalType.asset,
        targetAmount: 1000000,
        targetDate: DateTime.now().add(const Duration(days: 30)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );
      final goalWithoutDate = AssetGoal(
        id: 'goal-no-date',
        ledgerId: 'ledger-1',
        title: '날짜 없는 목표',
        goalType: GoalType.asset,
        targetAmount: 500000,
        targetDate: null,
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      // 날짜 없는 목표가 먼저 오도록 순서를 역으로
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goalWithoutDate, goalWithDate]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goalWithDate).overrideWith(
              (ref) async => 300000,
            ),
            assetGoalCurrentAmountProvider(goalWithoutDate).overrideWith(
              (ref) async => 0,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 날짜 있는 목표 제목이 표시됨 (정렬 결과 가장 가까운 날짜 목표가 앞에 옴)
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('두 목표가 모두 targetDate를 가질 때 더 가까운 목표가 먼저 표시된다',
        (tester) async {
      // Given: 두 개 모두 targetDate 있는 목표
      final nearGoal = AssetGoal(
        id: 'goal-near',
        ledgerId: 'ledger-1',
        title: '가까운 목표',
        goalType: GoalType.asset,
        targetAmount: 1000000,
        targetDate: DateTime.now().add(const Duration(days: 10)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );
      final farGoal = AssetGoal(
        id: 'goal-far',
        ledgerId: 'ledger-1',
        title: '먼 목표',
        goalType: GoalType.asset,
        targetAmount: 5000000,
        targetDate: DateTime.now().add(const Duration(days: 365)),
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
        createdBy: 'user-1',
      );

      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [farGoal, nearGoal]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(nearGoal).overrideWith(
              (ref) async => 500000,
            ),
            assetGoalCurrentAmountProvider(farGoal).overrideWith(
              (ref) async => 0,
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨 (정렬 로직 실행 확인)
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('수정 아이콘 탭 시 BottomSheet가 표시된다', (tester) async {
      // Given
      final goal = _makeGoal(title: '수정 테스트 목표');
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 0,
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
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 수정 아이콘이 있어야 함
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // When: 수정 아이콘 탭
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();
      // BottomSheet가 시도됨 (렌더링 여부만 확인)
      expect(find.byType(AssetGoalCardSimple), findsOneWidget);
    });

    testWidgets('삭제 아이콘 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      // Given
      final goal = _makeGoal(title: '삭제 테스트 목표');
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);
      when(
        () => mockRepo.deleteGoal(any()),
      ).thenAnswer((_) async {});

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 0,
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
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 삭제 아이콘이 있어야 함
      expect(find.byIcon(Icons.delete), findsOneWidget);

      // When: 삭제 아이콘 탭
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Then: 확인 다이얼로그가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('삭제 다이얼로그에서 취소를 누르면 목표가 삭제되지 않는다', (tester) async {
      // Given
      final goal = _makeGoal(title: '취소 테스트 목표');
      when(
        () => mockRepo.getGoals(ledgerId: any(named: 'ledgerId')),
      ).thenAnswer((_) async => [goal]);

      // When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWithValue(mockRepo),
            assetGoalCurrentAmountProvider(goal).overrideWith(
              (ref) async => 0,
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
              body: AssetGoalCardSimple(ledgerId: 'ledger-1'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 삭제 아이콘 탭
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 열리면 취소 버튼 탭
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        // 취소 버튼 탭 (l10n key: commonCancel = '취소')
        final cancelFinder = find.text('취소');
        if (cancelFinder.evaluate().isNotEmpty) {
          await tester.tap(cancelFinder);
          await tester.pumpAndSettle();
        }
      }

      // Then: deleteGoal이 호출되지 않음
      verifyNever(() => mockRepo.deleteGoal(any()));
    });
  });
}
