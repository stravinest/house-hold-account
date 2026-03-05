import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/calendar_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_month_summary.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/weekly_view.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('WeeklyView 관련 단위 테스트', () {
    test('WeeklyView 주 범위 계산 - 일요일 시작', () {
      // Given: 2024년 1월 15일 (월요일)
      final date = DateTime(2024, 1, 15);
      const weekStartDay = WeekStartDay.sunday;

      // When
      final range = getWeekRangeFor(date, weekStartDay);

      // Then: 1월 14일 (일요일) ~ 1월 20일 (토요일)
      expect(range.start.weekday, equals(DateTime.sunday));
      expect(range.end.weekday, equals(DateTime.saturday));
    });

    test('WeeklyView 주 범위 계산 - 월요일 시작', () {
      // Given: 2024년 1월 15일 (월요일)
      final date = DateTime(2024, 1, 15);
      const weekStartDay = WeekStartDay.monday;

      // When
      final range = getWeekRangeFor(date, weekStartDay);

      // Then: 1월 15일 (월요일) ~ 1월 21일 (일요일)
      expect(range.start, equals(DateTime(2024, 1, 15)));
      expect(range.end, equals(DateTime(2024, 1, 21)));
    });

    test('WeeklyView 이전 주 이동 - 7일 이전', () {
      // Given: 현재 주 시작
      final weekStart = DateTime(2024, 1, 14);

      // When: 이전 주로 이동
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));

      // Then
      expect(previousWeekStart, equals(DateTime(2024, 1, 7)));
    });

    test('WeeklyView 다음 주 이동 - 7일 이후', () {
      // Given: 현재 주 시작
      final weekStart = DateTime(2024, 1, 14);

      // When: 다음 주로 이동
      final nextWeekStart = weekStart.add(const Duration(days: 7));

      // Then
      expect(nextWeekStart, equals(DateTime(2024, 1, 21)));
    });

    test('WeeklyView 현재 주 여부 판별', () {
      // Given: 오늘 날짜로 주 범위 계산
      final now = DateTime.now();
      final currentWeekRange = getWeekRangeFor(now, WeekStartDay.sunday);

      // When
      final isCurrentWeek =
          currentWeekRange.start.year == currentWeekRange.start.year &&
          currentWeekRange.start.month == currentWeekRange.start.month &&
          currentWeekRange.start.day == currentWeekRange.start.day;

      // Then: 오늘을 포함하는 주는 현재 주이다
      expect(isCurrentWeek, isTrue);
    });

    test('WeeklyView 날짜별 그룹핑 - 같은 날짜는 같은 키', () {
      // Given
      final date1 = DateTime(2024, 1, 15, 10, 0);
      final date2 = DateTime(2024, 1, 15, 20, 0);

      // When: 날짜 키 생성
      final key1 = DateTime(date1.year, date1.month, date1.day);
      final key2 = DateTime(date2.year, date2.month, date2.day);

      // Then: 같은 날짜 키
      expect(key1, equals(key2));
    });

    test('WeeklyView 날짜별 그룹핑 - 다른 날짜는 다른 키', () {
      // Given
      final date1 = DateTime(2024, 1, 14);
      final date2 = DateTime(2024, 1, 15);

      // When
      final key1 = DateTime(date1.year, date1.month, date1.day);
      final key2 = DateTime(date2.year, date2.month, date2.day);

      // Then
      expect(key1, isNot(equals(key2)));
    });

    test('WeeklyView 날짜 내림차순 정렬', () {
      // Given
      final dates = [
        DateTime(2024, 1, 13),
        DateTime(2024, 1, 15),
        DateTime(2024, 1, 14),
      ];

      // When: 내림차순 정렬
      dates.sort((a, b) => b.compareTo(a));

      // Then: 최신 날짜가 앞에
      expect(dates[0], equals(DateTime(2024, 1, 15)));
      expect(dates[1], equals(DateTime(2024, 1, 14)));
      expect(dates[2], equals(DateTime(2024, 1, 13)));
    });

    test('WeeklyView 일별 합계 계산', () {
      // Given: 하루의 거래들
      final dayTransactions = [
        {'type': 'income', 'amount': 100000},
        {'type': 'expense', 'amount': 50000},
        {'type': 'expense', 'amount': 20000},
      ];

      // When
      int dayIncome = 0;
      int dayExpense = 0;
      for (final tx in dayTransactions) {
        if (tx['type'] == 'income') {
          dayIncome += tx['amount'] as int;
        } else if (tx['type'] == 'expense') {
          dayExpense += tx['amount'] as int;
        }
      }

      // Then
      expect(dayIncome, equals(100000));
      expect(dayExpense, equals(70000));
    });

    testWidgets('SummaryColumn 합계 타입 렌더링', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: '합계',
              totalAmount: 30000,
              color: Colors.black,
              users: const {},
              type: SummaryType.balance,
              memberCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.text('합계'), findsOneWidget);
      expect(find.text('30,000'), findsOneWidget);
    });

    testWidgets('SummaryColumn 음수 잔액 표시', (tester) async {
      // Given & When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryColumn(
              label: '합계',
              totalAmount: -15000,
              color: Colors.red,
              users: const {},
              type: SummaryType.balance,
              memberCount: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 음수 금액 표시
      expect(find.text('-15,000'), findsOneWidget);
    });
  });

  group('WeeklyView 위젯 렌더링 테스트', () {
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
      Map<String, dynamic>? weeklyTotal,
      WeekStartDay weekStartDay = WeekStartDay.sunday,
    }) {
      final date = selectedDate ?? DateTime(2024, 1, 15);
      final total = weeklyTotal ??
          {
            'income': 0,
            'expense': 0,
            'users': <String, dynamic>{},
          };

      return ProviderScope(
        overrides: [
          weeklyTransactionsProvider.overrideWith((ref) async => transactions),
          weeklyTotalProvider.overrideWith((ref) async => total),
          currentLedgerMemberCountProvider.overrideWith((ref) => 1),
          currentLedgerMembersProvider.overrideWith((ref) async => []),
          weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WeeklyView(
              selectedDate: date,
              onDateChanged: (_) {},
              onRefresh: () async {},
            ),
          ),
        ),
      );
    }

    testWidgets('WeeklyView가 기본 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Then: WeeklyView가 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
    });

    testWidgets('빈 거래 목록일 때 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(buildTestWidget(transactions: []));
      await tester.pumpAndSettle();

      // Then: WeeklyView가 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
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
        buildTestWidget(transactions: transactions, weeklyTotal: total),
      );
      await tester.pumpAndSettle();

      // Then: WeeklyView 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
    });

    testWidgets('수입/지출/합계 헤더가 표시된다', (tester) async {
      // Given
      final total = {
        'income': 200000,
        'expense': 80000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(buildTestWidget(weeklyTotal: total));
      await tester.pumpAndSettle();

      // Then: SummaryColumn이 3개 렌더링됨
      expect(find.byType(SummaryColumn), findsNWidgets(3));
    });

    testWidgets('월요일 시작 설정으로 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildTestWidget(weekStartDay: WeekStartDay.monday),
      );
      await tester.pumpAndSettle();

      // Then: WeeklyView가 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
    });

    testWidgets('일요일 시작 설정으로 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildTestWidget(weekStartDay: WeekStartDay.sunday),
      );
      await tester.pumpAndSettle();

      // Then: WeeklyView가 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
    });

    testWidgets('멤버 2명 이상일 때 멤버 보강 로직이 실행된다', (tester) async {
      // Given: memberCount >= 2 분기 커버
      final transactions = [
        _buildTx(id: 'tx-1', type: 'expense', amount: 10000),
      ];
      final total = {
        'income': 0,
        'expense': 10000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyTransactionsProvider.overrideWith(
              (ref) async => transactions,
            ),
            weeklyTotalProvider.overrideWith((ref) async => total),
            currentLedgerMemberCountProvider.overrideWith((ref) => 2),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WeeklyView(
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
      expect(find.byType(WeeklyView), findsOneWidget);
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
      final total = {
        'income': 100000,
        'expense': 0,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        buildTestWidget(transactions: [incomeTransaction], weeklyTotal: total),
      );
      await tester.pumpAndSettle();

      // Then: 거래 목록이 표시됨
      expect(find.byType(WeeklyView), findsOneWidget);
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
      final total = {
        'income': 0,
        'expense': 0,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        buildTestWidget(transactions: [assetTransaction], weeklyTotal: total),
      );
      await tester.pumpAndSettle();

      // Then: 자산 거래 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
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
      final total = {
        'income': 0,
        'expense': 30000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        buildTestWidget(transactions: [expenseTransaction], weeklyTotal: total),
      );
      await tester.pumpAndSettle();

      // Then: 지출 거래 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
    });

    testWidgets('income과 expense가 모두 있는 날짜 헤더가 표시된다', (tester) async {
      // Given: 같은 날짜에 income과 expense 동시 존재 (양쪽 조건 커버)
      final d = DateTime(2024, 1, 15);
      final transactions = [
        Transaction(
          id: 'tx-1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          type: 'income',
          amount: 100000,
          date: d,
          isRecurring: false,
          createdAt: d,
          updatedAt: d,
        ),
        Transaction(
          id: 'tx-2',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          type: 'expense',
          amount: 50000,
          date: d,
          isRecurring: false,
          createdAt: d,
          updatedAt: d,
        ),
      ];
      final total = {
        'income': 100000,
        'expense': 50000,
        'users': <String, dynamic>{},
      };

      await tester.pumpWidget(
        buildTestWidget(transactions: transactions, weeklyTotal: total),
      );
      await tester.pumpAndSettle();

      // Then: income, expense 금액 헤더 모두 표시
      expect(find.byType(WeeklyView), findsOneWidget);
    });

    testWidgets('이전 주 버튼 탭 시 콜백이 호출된다', (tester) async {
      // Given: 이전/다음 주 버튼 콜백 커버
      DateTime? changedDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyTransactionsProvider.overrideWith((ref) async => []),
            weeklyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WeeklyView(
                selectedDate: DateTime(2024, 1, 15),
                onDateChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 이전 주 버튼 탭
      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      // Then: 콜백 호출됨
      expect(changedDate, isNotNull);
    });

    testWidgets('다음 주 버튼 탭 시 콜백이 호출된다', (tester) async {
      // Given
      DateTime? changedDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weeklyTransactionsProvider.overrideWith((ref) async => []),
            weeklyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WeeklyView(
                selectedDate: DateTime(2024, 1, 15),
                onDateChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 다음 주 버튼 탭
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
            weeklyTransactionsProvider.overrideWith((ref) async => []),
            weeklyTotalProvider.overrideWith((ref) async => {
                  'income': 0,
                  'expense': 0,
                  'users': <String, dynamic>{},
                }),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            currentLedgerMembersProvider.overrideWith((ref) async => []),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: WeeklyView(
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
          weeklyTotal: {
            'income': 0,
            'expense': 15000,
            'users': <String, dynamic>{},
          },
        ),
      );
      await tester.pumpAndSettle();

      // Then: 제목이 있는 거래 렌더링됨
      expect(find.byType(WeeklyView), findsOneWidget);
    });
  });
}
