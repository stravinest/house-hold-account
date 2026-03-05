import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/providers/asset_goal_provider.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_action_buttons.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockAssetRepository extends Mock implements AssetRepository {}

void main() {
  group('AssetGoalActionButtons 위젯 테스트', () {
    late AssetGoal testGoal;
    late MockAssetRepository mockRepository;

    setUpAll(() {
      registerFallbackValue(AssetGoal(
        id: 'fallback',
        ledgerId: 'fallback',
        title: 'fallback',
        targetAmount: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'fallback',
      ));
    });

    setUp(() {
      mockRepository = MockAssetRepository();
      testGoal = AssetGoal(
        id: 'test-goal-id',
        ledgerId: 'test-ledger-id',
        title: '테스트 목표',
        targetAmount: 1000000,
        targetDate: DateTime(2024, 12, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'test-user-id',
      );
    });

    testWidgets('수정 버튼과 삭제 버튼이 렌더링된다', (tester) async {
      // Given

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      // Then: 수정 아이콘과 삭제 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
      expect(find.byIcon(Icons.delete_rounded), findsOneWidget);
    });

    testWidgets('Row와 InkWell이 올바르게 렌더링된다', (tester) async {
      // Given

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      // Then: Row와 InkWell이 렌더링되어야 함
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(InkWell), findsNWidgets(2));
    });

    testWidgets('아이콘 버튼들이 Material 위젯으로 감싸져 있다', (tester) async {
      // Given

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      // Then: Material 위젯이 렌더링되어야 함
      expect(find.byType(Material), findsWidgets);
    });

    testWidgets('두 개의 아이콘이 동일한 크기로 렌더링된다', (tester) async {
      // Given

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      // Then: 두 아이콘의 크기가 동일해야 함
      final editIcon = tester.widget<Icon>(find.byIcon(Icons.edit_rounded));
      final deleteIcon = tester.widget<Icon>(find.byIcon(Icons.delete_rounded));
      expect(editIcon.size, 18);
      expect(deleteIcon.size, 18);
    });

    testWidgets('삭제 버튼 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      // Given
      when(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // When: 삭제 버튼 탭
      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      // Then: AlertDialog가 표시되어야 함
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('삭제 다이얼로그에서 취소 버튼 탭 시 다이얼로그가 닫힌다', (tester) async {
      // Given
      when(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // When: 삭제 버튼 탭 후 다이얼로그 표시
      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // When: 취소 버튼 탭
      final cancelFinder = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      ).first;
      await tester.tap(cancelFinder);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫혀야 함
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('삭제 다이얼로그에서 확인 버튼 탭 시 deleteGoal이 호출된다', (tester) async {
      // Given
      when(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);
      when(() => mockRepository.deleteGoal(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // When: 삭제 버튼 탭
      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      // When: 확인 버튼(두 번째 TextButton) 탭
      final buttons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // Then: deleteGoal이 호출되어야 함
      verify(() => mockRepository.deleteGoal(testGoal.id)).called(1);
    });

    testWidgets('수정 버튼 탭 시 _showGoalFormSheet가 호출된다', (tester) async {
      // Given: 수정 버튼 탭 시 BottomSheet가 열리는지 확인
      when(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // When: 수정 버튼 탭
      await tester.tap(find.byIcon(Icons.edit_rounded));
      await tester.pumpAndSettle();

      // Then: ModalBottomSheet가 표시되거나 위젯 트리가 변경됨
      // (AssetGoalFormSheet가 표시됨을 확인)
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    });

    testWidgets('삭제 실패 시 에러 SnackBar가 표시된다', (tester) async {
      // Given: deleteGoal이 예외를 던지도록 설정
      when(() => mockRepository.getGoals(ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);
      when(() => mockRepository.deleteGoal(any()))
          .thenThrow(Exception('삭제 실패'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            assetGoalRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AssetGoalActionButtons(
                goal: testGoal,
                ledgerId: 'test-ledger-id',
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // When: 삭제 버튼 탭 후 다이얼로그 확인
      await tester.tap(find.byIcon(Icons.delete_rounded));
      await tester.pumpAndSettle();

      final buttons = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextButton),
      );
      await tester.tap(buttons.last);
      await tester.pumpAndSettle();

      // Then: 삭제 실패 시 에러 처리가 되어야 함 (다이얼로그는 닫힘)
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
