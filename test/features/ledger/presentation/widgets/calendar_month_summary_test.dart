import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_month_summary.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UserAmountIndicator 위젯 테스트', () {
    testWidgets('필수 프로퍼티가 올바르게 렌더링된다', (tester) async {
      // Given
      const testColor = Colors.blue;
      const testAmount = 10000;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(UserAmountIndicator), findsOneWidget);
      expect(find.text('10,000'), findsOneWidget);
    });

    testWidgets('음수 금액이 올바르게 표시된다', (tester) async {
      // Given
      const testColor = Colors.red;
      const testAmount = -5000;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('-5,000'), findsOneWidget);
    });

    testWidgets('0원일 때 올바르게 표시된다', (tester) async {
      // Given
      const testColor = Colors.green;
      const testAmount = 0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('큰 금액이 올바르게 포맷된다', (tester) async {
      // Given
      const testColor = Colors.orange;
      const testAmount = 1234567;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('1,234,567'), findsOneWidget);
    });

    testWidgets('색상 원이 표시된다', (tester) async {
      // Given
      const testColor = Colors.purple;
      const testAmount = 1000;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAmountIndicator(
              color: testColor,
              amount: testAmount,
            ),
          ),
        ),
      );

      // Then - Container가 렌더링되는지 확인
      expect(find.byType(UserAmountIndicator), findsOneWidget);
      expect(find.byType(Row), findsOneWidget);
    });
  });

  group('SummaryColumn 위젯 테스트', () {
    testWidgets('수입 타입으로 렌더링된다', (tester) async {
      // Given
      const label = '수입';
      const totalAmount = 100000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.blue,
              users: const {},
              type: SummaryType.income,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(label), findsOneWidget);
      expect(find.text('100,000'), findsOneWidget);
    });

    testWidgets('지출 타입으로 렌더링된다', (tester) async {
      // Given
      const label = '지출';
      const totalAmount = 50000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.red,
              users: const {},
              type: SummaryType.expense,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(label), findsOneWidget);
      expect(find.text('50,000'), findsOneWidget);
    });

    testWidgets('합계 타입으로 렌더링된다', (tester) async {
      // Given
      const label = '합계';
      const totalAmount = 30000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.black,
              users: const {},
              type: SummaryType.balance,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(label), findsOneWidget);
      expect(find.text('30,000'), findsOneWidget);
    });

    testWidgets('음수 금액이 마이너스 부호와 함께 표시된다', (tester) async {
      // Given
      const label = '합계';
      const totalAmount = -20000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.red,
              users: const {},
              type: SummaryType.balance,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('-20,000'), findsOneWidget);
    });

    testWidgets('멤버가 1명일 때 사용자 인디케이터가 표시되지 않는다', (tester) async {
      // Given
      const label = '수입';
      const totalAmount = 100000;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.blue,
              users: const {},
              type: SummaryType.income,
              memberCount: 1,
            ),
          ),
        ),
      );

      // Then - UserAmountIndicator가 없어야 함
      expect(find.byType(UserAmountIndicator), findsNothing);
    });

    testWidgets('멤버가 2명 이상일 때 사용자 인디케이터가 표시된다', (tester) async {
      // Given
      const label = '지출';
      const totalAmount = 50000;
      final users = {
        'user1': {
          'displayName': '사용자1',
          'income': 0,
          'expense': 30000,
          'color': '#A8D8EA',
        },
        'user2': {
          'displayName': '사용자2',
          'income': 0,
          'expense': 20000,
          'color': '#FFB6A3',
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: label,
              totalAmount: totalAmount,
              color: Colors.red,
              users: users,
              type: SummaryType.expense,
              memberCount: 2,
            ),
          ),
        ),
      );

      // Then - 2개의 UserAmountIndicator가 있어야 함
      expect(find.byType(UserAmountIndicator), findsNWidgets(2));
    });
  });

  group('CalendarMonthSummary ConsumerWidget 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({
      required Map<String, dynamic> totalData,
      List<LedgerMember> members = const [],
      int memberCount = 1,
    }) {
      return ProviderScope(
        overrides: [
          monthlyTotalProvider.overrideWith((ref) async => totalData),
          currentLedgerMembersProvider.overrideWith((ref) async => members),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarMonthSummary(
              focusedDate: DateTime(2024, 1, 1),
              memberCount: memberCount,
            ),
          ),
        ),
      );
    }

    testWidgets('수입/지출/합계 3개 열이 렌더링된다', (tester) async {
      // Given
      final total = {
        'income': 100000,
        'expense': 60000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(buildTestWidget(totalData: total));
      await tester.pumpAndSettle();

      // Then: SummaryColumn 3개
      expect(find.byType(SummaryColumn), findsNWidgets(3));
    });

    testWidgets('수입 100000원, 지출 60000원이면 합계 40000원을 표시한다', (tester) async {
      // Given
      final total = {
        'income': 100000,
        'expense': 60000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(buildTestWidget(totalData: total));
      await tester.pumpAndSettle();

      // Then
      expect(find.text('100,000'), findsOneWidget);
      expect(find.text('60,000'), findsOneWidget);
      expect(find.text('40,000'), findsOneWidget);
    });

    testWidgets('지출이 수입보다 크면 음수 합계를 표시한다', (tester) async {
      // Given
      final total = {
        'income': 50000,
        'expense': 80000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(buildTestWidget(totalData: total));
      await tester.pumpAndSettle();

      // Then: 합계 -30000
      expect(find.text('-30,000'), findsOneWidget);
    });

    testWidgets('memberCount가 1일 때 UserAmountIndicator가 표시되지 않는다', (tester) async {
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
        buildTestWidget(totalData: total, memberCount: 1),
      );
      await tester.pumpAndSettle();

      // Then: memberCount 1이므로 사용자 인디케이터 없음
      expect(find.byType(UserAmountIndicator), findsNothing);
    });

    testWidgets('memberCount가 2이상이면 사용자별 인디케이터가 표시된다', (tester) async {
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
        buildTestWidget(totalData: total, memberCount: 2),
      );
      await tester.pumpAndSettle();

      // Then: 각 SummaryColumn에 2개씩 총 6개 (income/expense/balance 각 2개)
      expect(find.byType(UserAmountIndicator), findsWidgets);
    });

    testWidgets('데이터가 없을 때 0원으로 표시한다', (tester) async {
      // Given: 빈 데이터
      final total = <String, dynamic>{};

      await tester.pumpWidget(buildTestWidget(totalData: total));
      await tester.pumpAndSettle();

      // Then: 0원이 여러 개 표시됨
      expect(find.text('0'), findsWidgets);
    });
  });
}
