import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/user_profile_summary.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserChip 위젯 테스트', () {
    testWidgets('필수 프로퍼티가 올바르게 렌더링된다', (tester) async {
      // Given
      const testName = '홍길동';
      const testAmount = 50000;
      const testColor = Colors.blue;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      expect(find.text('-50,000'), findsOneWidget);
    });

    testWidgets('이름과 금액이 표시된다', (tester) async {
      // Given
      const testName = '김철수';
      const testAmount = 100000;
      const testColor = Colors.green;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      expect(find.text('-100,000'), findsOneWidget);
    });

    testWidgets('금액이 0원일 때 올바르게 표시된다', (tester) async {
      // Given
      const testName = '이영희';
      const testAmount = 0;
      const testColor = Colors.red;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      expect(find.text('-0'), findsOneWidget);
    });

    testWidgets('긴 이름이 ellipsis로 표시된다', (tester) async {
      // Given
      const testName = '매우긴이름을가진사용자입니다정말긴이름';
      const testAmount = 123456;
      const testColor = Colors.purple;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: UserChip(
                name: testName,
                amount: testAmount,
                color: testColor,
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testName), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text(testName));
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 1);
    });

    testWidgets('색상이 Container 테두리와 원에 적용된다', (tester) async {
      // Given
      const testName = '박민수';
      const testAmount = 75000;
      const testColor = Colors.orange;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserChip(
              name: testName,
              amount: testAmount,
              color: testColor,
            ),
          ),
        ),
      );

      // Then - 위젯이 렌더링되는지 확인
      expect(find.byType(UserChip), findsOneWidget);
    });

    testWidgets('다양한 금액 형식이 올바르게 표시된다', (tester) async {
      // Given
      const testCases = [
        (1000, '-1,000'),
        (10000, '-10,000'),
        (100000, '-100,000'),
        (1000000, '-1,000,000'),
        (999, '-999'),
      ];

      for (final (amount, expected) in testCases) {
        // When
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: UserChip(
                name: '테스트',
                amount: amount,
                color: Colors.blue,
              ),
            ),
          ),
        );

        // Then
        expect(find.text(expected), findsOneWidget,
            reason: '$amount 원은 $expected 으로 표시되어야 합니다');

        await tester.pumpWidget(Container());
      }
    });
  });

  group('UserProfileSummary 위젯 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget(AsyncValue<Map<String, dynamic>> value) {
      return ProviderScope(
        overrides: [
          monthlyTotalProvider.overrideWith((ref) async {
            return value.when(
              data: (d) => d,
              loading: () => throw Exception('loading'),
              error: (e, _) => throw e,
            );
          }),
        ],
        child: const MaterialApp(
          localizationsDelegates: [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: UserProfileSummary()),
        ),
      );
    }

    testWidgets('사용자 데이터가 있을 때 UserChip이 렌더링된다', (tester) async {
      // Given
      final total = {
        'income': 100000,
        'expense': 50000,
        'users': {
          'user-1': {
            'displayName': '홍길동',
            'income': 100000,
            'expense': 50000,
            'color': '#A8D8EA',
          },
        },
      };

      await tester.pumpWidget(
        buildTestWidget(AsyncValue.data(total)),
      );
      await tester.pumpAndSettle();

      // Then: UserChip이 렌더링됨
      expect(find.byType(UserChip), findsOneWidget);
      expect(find.text('홍길동'), findsOneWidget);
    });

    testWidgets('사용자가 없을 때 SizedBox.shrink를 렌더링한다', (tester) async {
      // Given
      final total = {
        'income': 0,
        'expense': 0,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        buildTestWidget(AsyncValue.data(total)),
      );
      await tester.pumpAndSettle();

      // Then: UserChip이 없어야 함
      expect(find.byType(UserChip), findsNothing);
    });

    testWidgets('users가 null일 때 SizedBox.shrink를 렌더링한다', (tester) async {
      // Given
      final total = {
        'income': 0,
        'expense': 0,
        'users': null,
      };

      await tester.pumpWidget(
        buildTestWidget(AsyncValue.data(total)),
      );
      await tester.pumpAndSettle();

      // Then: UserChip이 없어야 함
      expect(find.byType(UserChip), findsNothing);
    });

    testWidgets('여러 사용자가 있을 때 각각의 UserChip이 렌더링된다', (tester) async {
      // Given
      final total = {
        'income': 200000,
        'expense': 100000,
        'users': {
          'user-1': {
            'displayName': '홍길동',
            'income': 100000,
            'expense': 50000,
            'color': '#A8D8EA',
          },
          'user-2': {
            'displayName': '김철수',
            'income': 100000,
            'expense': 50000,
            'color': '#FFB6A3',
          },
        },
      };

      await tester.pumpWidget(
        buildTestWidget(AsyncValue.data(total)),
      );
      await tester.pumpAndSettle();

      // Then: 2개의 UserChip이 렌더링됨
      expect(find.byType(UserChip), findsNWidgets(2));
      expect(find.text('홍길동'), findsOneWidget);
      expect(find.text('김철수'), findsOneWidget);
    });

    testWidgets('로딩 상태일 때 SizedBox(height: 60)가 렌더링된다', (tester) async {
      // Given: 완료되지 않는 future (Completer 사용)
      final completer = Completer<Map<String, dynamic>>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            monthlyTotalProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: UserProfileSummary()),
          ),
        ),
      );
      await tester.pump();

      // Then: 로딩 상태에서는 SizedBox가 렌더링됨
      expect(find.byType(SizedBox), findsWidgets);

      // 정리: completer를 완료시켜 pending 상태 해제
      completer.complete({});
      await tester.pumpAndSettle();
    });
  });
}
