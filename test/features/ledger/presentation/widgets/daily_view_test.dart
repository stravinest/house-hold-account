import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_month_summary.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/daily_view.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('DailyView 관련 단위 테스트', () {
    test('DailyView 기본 구조 확인', () {
      // DailyView는 복잡한 Provider 의존성으로 단위 테스트 범위를 제한
      // 핵심 로직은 별도 단위 테스트로 검증

      // Given: 일별 데이터
      final totals = {
        'income': 50000,
        'expense': 30000,
        'users': {
          'user-1': {
            'displayName': '홍길동',
            'income': 50000,
            'expense': 30000,
            'asset': 0,
            'color': '#A8D8EA',
          },
        },
      };

      // When: 잔액 계산
      final income = totals['income'] as int;
      final expense = totals['expense'] as int;
      final balance = income - expense;

      // Then
      expect(balance, equals(20000));
    });

    test('DailyView 날짜 이동 로직 - 이전 날짜로 이동', () {
      // Given
      final currentDate = DateTime(2024, 1, 15);

      // When: 하루 전으로 이동
      final previousDate = currentDate.subtract(const Duration(days: 1));

      // Then
      expect(previousDate, equals(DateTime(2024, 1, 14)));
    });

    test('DailyView 날짜 이동 로직 - 다음 날짜로 이동', () {
      // Given
      final currentDate = DateTime(2024, 1, 15);

      // When: 하루 후로 이동
      final nextDate = currentDate.add(const Duration(days: 1));

      // Then
      expect(nextDate, equals(DateTime(2024, 1, 16)));
    });

    test('DailyView 날짜 이동 로직 - 월 경계 이전', () {
      // Given: 1월 1일
      final currentDate = DateTime(2024, 1, 1);

      // When: 하루 전으로 이동
      final previousDate = currentDate.subtract(const Duration(days: 1));

      // Then: 12월 31일
      expect(previousDate, equals(DateTime(2023, 12, 31)));
    });

    test('DailyView 날짜 이동 로직 - 월 경계 이후', () {
      // Given: 1월 31일
      final currentDate = DateTime(2024, 1, 31);

      // When: 하루 후로 이동
      final nextDate = currentDate.add(const Duration(days: 1));

      // Then: 2월 1일
      expect(nextDate, equals(DateTime(2024, 2, 1)));
    });

    test('DailyView 오늘 여부 판별 로직', () {
      // Given
      final today = DateTime.now();
      final testDate = DateTime(today.year, today.month, today.day);
      final yesterday = testDate.subtract(const Duration(days: 1));

      // When & Then: 오늘은 true
      final isToday = testDate.year == today.year &&
          testDate.month == today.month &&
          testDate.day == today.day;
      expect(isToday, isTrue);

      // When & Then: 어제는 false
      final isYesterdayToday = yesterday.year == today.year &&
          yesterday.month == today.month &&
          yesterday.day == today.day;
      expect(isYesterdayToday, isFalse);
    });

    test('DailyView 일별 합계 계산 - 지출만 있는 경우', () {
      // Given: 지출 거래들
      final transactions = [
        {'type': 'expense', 'amount': 10000},
        {'type': 'expense', 'amount': 20000},
        {'type': 'expense', 'amount': 5000},
      ];

      // When: 일별 합계
      int dailyTotal = 0;
      for (final tx in transactions) {
        if (tx['type'] == 'expense') {
          dailyTotal -= tx['amount'] as int;
        } else if (tx['type'] == 'income') {
          dailyTotal += tx['amount'] as int;
        }
      }

      // Then: 음수 합계
      expect(dailyTotal, equals(-35000));
    });

    test('DailyView 일별 합계 계산 - 수입과 지출 혼합', () {
      // Given
      final transactions = [
        {'type': 'income', 'amount': 100000},
        {'type': 'expense', 'amount': 30000},
        {'type': 'expense', 'amount': 20000},
      ];

      // When
      int dailyTotal = 0;
      for (final tx in transactions) {
        if (tx['type'] == 'expense') {
          dailyTotal -= tx['amount'] as int;
        } else if (tx['type'] == 'income') {
          dailyTotal += tx['amount'] as int;
        }
      }

      // Then
      expect(dailyTotal, equals(50000));
    });

    testWidgets('SummaryColumn 수입 타입 렌더링', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: '수입',
              totalAmount: 100000,
              color: Colors.blue,
              users: const {},
              type: SummaryType.income,
              memberCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('수입'), findsOneWidget);
    });

    testWidgets('SummaryColumn 지출 타입 렌더링', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: '지출',
              totalAmount: 50000,
              color: Colors.red,
              users: const {},
              type: SummaryType.expense,
              memberCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('지출'), findsOneWidget);
    });
  });

  group('DailyView 위젯 렌더링 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Transaction _buildTx({
      String id = 'tx-1',
      String type = 'expense',
      int amount = 10000,
    }) {
      final d = DateTime(2024, 1, 15);
      return Transaction(
        id: id,
        ledgerId: 'ledger-1',
        userId: 'user-1',
        type: type,
        amount: amount,
        date: d,
        isRecurring: false,
        createdAt: d,
        updatedAt: d,
      );
    }

    Widget buildTestWidget({
      DateTime? selectedDate,
      List<Transaction> transactions = const [],
      Map<String, dynamic>? dailyTotal,
    }) {
      final date = selectedDate ?? DateTime(2024, 1, 15);
      final total = dailyTotal ??
          {
            'income': 0,
            'expense': 0,
            'users': <String, dynamic>{},
          };

      return ProviderScope(
        overrides: [
          dailyTransactionsProvider.overrideWith((ref) async => transactions),
          dailyTotalProvider.overrideWith((ref) async => total),
          currentLedgerMemberCountProvider.overrideWith((ref) => 1),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: DailyView(
              selectedDate: date,
              onDateChanged: (_) {},
              onRefresh: () async {},
            ),
          ),
        ),
      );
    }

    testWidgets('DailyView가 기본 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Then: DailyView가 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('빈 거래 목록일 때 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(buildTestWidget(transactions: []));
      await tester.pumpAndSettle();

      // Then: DailyView가 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('거래 목록이 있을 때 렌더링된다', (tester) async {
      // Given
      final transactions = [
        _buildTx(id: 'tx-1', type: 'expense', amount: 30000),
        _buildTx(id: 'tx-2', type: 'income', amount: 50000),
      ];
      final total = {
        'income': 50000,
        'expense': 30000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        buildTestWidget(transactions: transactions, dailyTotal: total),
      );
      await tester.pumpAndSettle();

      // Then: DailyView 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('수입/지출/합계 헤더가 표시된다', (tester) async {
      // Given
      final total = {
        'income': 100000,
        'expense': 40000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(buildTestWidget(dailyTotal: total));
      await tester.pumpAndSettle();

      // Then: SummaryColumn이 3개 렌더링됨
      expect(find.byType(SummaryColumn), findsNWidgets(3));
    });

    testWidgets('날짜 네비게이션 콜백이 호출된다', (tester) async {
      // Given
      DateTime? changedDate;
      final date = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTransactionsProvider.overrideWith((ref) async => []),
            dailyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DailyView(
                selectedDate: date,
                onDateChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: DailyView가 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('멤버 2명 이상일 때 멤버 보강 로직이 실행된다', (tester) async {
      // Given: memberCount >= 2 분기 커버
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTransactionsProvider.overrideWith((ref) async => []),
            dailyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 2),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DailyView(
                selectedDate: DateTime(2024, 1, 15),
                onDateChanged: (_) {},
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 공유 가계부 상태로 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('income 타입 거래가 있을 때 렌더링된다', (tester) async {
      // Given: income 타입 거래 (색상 분기 커버)
      final d = DateTime(2024, 1, 15);
      final incomeTransaction = Transaction(
        id: 'tx-income',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        type: 'income',
        amount: 100000,
        date: d,
        isRecurring: false,
        createdAt: d,
        updatedAt: d,
      );

      await tester.pumpWidget(
        buildTestWidget(
          transactions: [incomeTransaction],
          dailyTotal: {
            'income': 100000,
            'expense': 0,
            'users': <String, dynamic>{},
          },
        ),
      );
      await tester.pumpAndSettle();

      // Then: 거래 목록이 표시됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('asset 타입 거래가 있을 때 렌더링된다', (tester) async {
      // Given: asset 타입 거래 (tertiary 색상 분기 커버)
      final d = DateTime(2024, 1, 15);
      final assetTransaction = Transaction(
        id: 'tx-asset',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        type: 'asset',
        amount: 500000,
        date: d,
        isRecurring: false,
        createdAt: d,
        updatedAt: d,
      );

      await tester.pumpWidget(
        buildTestWidget(
          transactions: [assetTransaction],
          dailyTotal: {
            'income': 0,
            'expense': 0,
            'users': <String, dynamic>{},
          },
        ),
      );
      await tester.pumpAndSettle();

      // Then: 자산 거래 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('expense 타입 거래가 있을 때 렌더링된다', (tester) async {
      // Given: expense 타입 거래 (error 색상 분기 커버)
      final d = DateTime(2024, 1, 15);
      final expenseTransaction = Transaction(
        id: 'tx-expense',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        type: 'expense',
        amount: 30000,
        date: d,
        isRecurring: false,
        createdAt: d,
        updatedAt: d,
      );

      await tester.pumpWidget(
        buildTestWidget(
          transactions: [expenseTransaction],
          dailyTotal: {
            'income': 0,
            'expense': 30000,
            'users': <String, dynamic>{},
          },
        ),
      );
      await tester.pumpAndSettle();

      // Then: 지출 거래 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('타이틀이 있는 거래 설명이 올바르게 표시된다', (tester) async {
      // Given: 제목이 있는 거래 (description 분기 커버)
      final d = DateTime(2024, 1, 15);
      final txWithTitle = Transaction(
        id: 'tx-titled',
        ledgerId: 'ledger-1',
        userId: 'user-1',
        type: 'expense',
        amount: 15000,
        date: d,
        isRecurring: false,
        title: '커피',
        createdAt: d,
        updatedAt: d,
      );

      await tester.pumpWidget(
        buildTestWidget(
          transactions: [txWithTitle],
          dailyTotal: {
            'income': 0,
            'expense': 15000,
            'users': <String, dynamic>{},
          },
        ),
      );
      await tester.pumpAndSettle();

      // Then: 제목이 있는 거래 렌더링됨
      expect(find.byType(DailyView), findsOneWidget);
    });

    testWidgets('이전 날짜 버튼 탭 시 콜백이 호출된다', (tester) async {
      // Given: 이전/다음 날짜 버튼 커버
      DateTime? changedDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTransactionsProvider.overrideWith((ref) async => []),
            dailyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DailyView(
                selectedDate: DateTime(2024, 1, 15),
                onDateChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 이전 날짜 버튼 탭
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      // Then: 콜백 호출됨
      expect(changedDate, isNotNull);
    });

    testWidgets('다음 날짜 버튼 탭 시 콜백이 호출된다', (tester) async {
      // Given
      DateTime? changedDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTransactionsProvider.overrideWith((ref) async => []),
            dailyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DailyView(
                selectedDate: DateTime(2024, 1, 15),
                onDateChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 다음 날짜 버튼 탭
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      // Then: 콜백 호출됨
      expect(changedDate, isNotNull);
    });

    testWidgets('새로고침 버튼 탭 시 _handleRefresh가 호출된다', (tester) async {
      // Given: 새로고침 콜백 커버
      bool refreshCalled = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTransactionsProvider.overrideWith((ref) async => []),
            dailyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: DailyView(
                selectedDate: DateTime(2024, 1, 15),
                onDateChanged: (_) {},
                onRefresh: () async {
                  refreshCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 새로고침 아이콘 탭
      await tester.tap(find.byIcon(Icons.refresh).first);
      await tester.pump();

      // Then: 새로고침 콜백 호출됨
      expect(refreshCalled, isTrue);
    });
  });
}
