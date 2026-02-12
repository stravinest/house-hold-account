import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/presentation/widgets/asset_goal_action_buttons.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('AssetGoalActionButtons 위젯 테스트', () {
    late AssetGoal testGoal;

    setUp(() {
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
  });
}
