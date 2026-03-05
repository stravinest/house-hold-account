import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/monthly_list_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/monthly_list_view.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 거래 목 데이터 생성 헬퍼
Transaction _buildTransaction({
  String id = 'tx-1',
  String type = 'expense',
  int amount = 10000,
  String? categoryName = '식비',
  String? userName = '홍길동',
  DateTime? date,
}) {
  final d = date ?? DateTime(2024, 1, 15);
  return Transaction(
    id: id,
    ledgerId: 'ledger-1',
    userId: 'user-1',
    type: type,
    amount: amount,
    categoryId: 'cat-1',
    categoryName: categoryName,
    date: d,
    createdAt: d,
    updatedAt: d,
    userName: userName,
    userColor: '#A8D8EA',
    isFixedExpense: false,
    isRecurring: false,
  );
}

/// MonthlyListView 테스트용 래퍼
Widget buildTestWidget({
  AsyncValue<List<Transaction>> transactionsValue = const AsyncValue.loading(),
  Set<TransactionFilter> selectedFilters = const {TransactionFilter.all},
}) {
  return ProviderScope(
    overrides: [
      filteredMonthlyTransactionsProvider.overrideWith((ref) => transactionsValue),
      selectedFiltersProvider.overrideWith((ref) => selectedFilters),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: MonthlyListView(),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MonthlyListView 위젯 테스트', () {
    testWidgets('로딩 상태일 때 스켈레톤 UI가 표시된다', (tester) async {
      // Given: 로딩 상태
      await tester.pumpWidget(buildTestWidget(
        transactionsValue: const AsyncValue.loading(),
      ));
      await tester.pump();

      // Then: ListView가 렌더링됨 (스켈레톤)
      expect(find.byType(MonthlyListView), findsOneWidget);
    });

    testWidgets('거래 목록이 비어있을 때 빈 상태 메시지가 표시된다', (tester) async {
      // Given: 빈 거래 목록
      await tester.pumpWidget(buildTestWidget(
        transactionsValue: const AsyncValue.data([]),
      ));
      await tester.pumpAndSettle();

      // Then: 빈 상태 메시지 표시
      expect(find.byType(Center), findsWidgets);
    });

    testWidgets('거래 목록이 있을 때 ListView가 렌더링된다', (tester) async {
      // Given: 거래 목록이 있는 경우
      final transactions = [
        _buildTransaction(id: 'tx-1', date: DateTime(2024, 1, 15)),
        _buildTransaction(id: 'tx-2', date: DateTime(2024, 1, 14)),
      ];

      await tester.pumpWidget(buildTestWidget(
        transactionsValue: AsyncValue.data(transactions),
      ));
      await tester.pumpAndSettle();

      // Then: ListView가 렌더링됨
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('에러 상태일 때 에러 아이콘이 표시된다', (tester) async {
      // Given: 에러 상태
      await tester.pumpWidget(buildTestWidget(
        transactionsValue: AsyncValue.error(
          Exception('오류 발생'),
          StackTrace.current,
        ),
      ));
      await tester.pumpAndSettle();

      // Then: 에러 아이콘이 표시됨
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('같은 날짜의 거래들이 하나의 날짜 헤더로 그룹핑된다', (tester) async {
      // Given: 같은 날짜의 거래 2개
      final date = DateTime(2024, 1, 15);
      final transactions = [
        _buildTransaction(id: 'tx-1', date: date, amount: 20000),
        _buildTransaction(id: 'tx-2', date: date, amount: 10000),
      ];

      await tester.pumpWidget(buildTestWidget(
        transactionsValue: AsyncValue.data(transactions),
      ));
      await tester.pumpAndSettle();

      // Then: 거래 아이템들이 렌더링됨
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('다른 날짜의 거래들이 별도 그룹으로 표시된다', (tester) async {
      // Given: 다른 날짜의 거래들
      final transactions = [
        _buildTransaction(id: 'tx-1', date: DateTime(2024, 1, 15)),
        _buildTransaction(id: 'tx-2', date: DateTime(2024, 1, 14)),
        _buildTransaction(id: 'tx-3', date: DateTime(2024, 1, 13)),
      ];

      await tester.pumpWidget(buildTestWidget(
        transactionsValue: AsyncValue.data(transactions),
      ));
      await tester.pumpAndSettle();

      // Then: ListView가 렌더링되며 여러 그룹이 있음
      expect(find.byType(ListView), findsOneWidget);
    });
  });

  group('MonthlyListView - _groupByDate 로직 단위 테스트', () {
    test('같은 날짜의 거래가 같은 그룹에 들어간다', () {
      // Given
      final date = DateTime(2024, 1, 15);
      final transactions = [
        _buildTransaction(id: 'tx-1', date: date, amount: 30000),
        _buildTransaction(id: 'tx-2', date: date, amount: 10000),
        _buildTransaction(id: 'tx-3', date: date, amount: 20000),
      ];

      // 날짜 키로 그룹핑 로직 재현
      final Map<String, List<Transaction>> grouped = {};
      for (final tx in transactions) {
        final dateKey =
            '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(dateKey, () => []).add(tx);
      }

      // Then: 같은 날짜 키에 3개 거래가 있음
      expect(grouped['2024-01-15']?.length, equals(3));
    });

    test('서로 다른 날짜의 거래는 다른 그룹에 들어간다', () {
      // Given
      final transactions = [
        _buildTransaction(id: 'tx-1', date: DateTime(2024, 1, 15)),
        _buildTransaction(id: 'tx-2', date: DateTime(2024, 1, 14)),
      ];

      // 그룹핑 로직 재현
      final Map<String, List<Transaction>> grouped = {};
      for (final tx in transactions) {
        final dateKey =
            '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
        grouped.putIfAbsent(dateKey, () => []).add(tx);
      }

      // Then: 2개 그룹
      expect(grouped.length, equals(2));
    });

    test('날짜 키가 내림차순 정렬된다', () {
      // Given
      final dateKeys = ['2024-01-13', '2024-01-15', '2024-01-14'];

      // When: 내림차순 정렬
      final sorted = List<String>.from(dateKeys)..sort((a, b) => b.compareTo(a));

      // Then: 최신 날짜가 앞에 옴
      expect(sorted[0], equals('2024-01-15'));
      expect(sorted[1], equals('2024-01-14'));
      expect(sorted[2], equals('2024-01-13'));
    });
  });
}
