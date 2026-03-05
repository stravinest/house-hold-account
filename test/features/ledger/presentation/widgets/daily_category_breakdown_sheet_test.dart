import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/daily_category_breakdown_sheet.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Transaction _makeTransaction({
  String id = 'tx-1',
  String type = 'expense',
  int amount = 10000,
  String? title,
  String? categoryName,
  DateTime? date,
}) {
  return Transaction(
    id: id,
    ledgerId: 'ledger-1',
    userId: 'user-1',
    type: type,
    amount: amount,
    title: title,
    categoryName: categoryName,
    date: date ?? DateTime(2024, 1, 15),
    isRecurring: false,
    createdAt: DateTime(2024, 1, 15),
    updatedAt: DateTime(2024, 1, 15),
  );
}

Widget buildWidget({
  List<Transaction> transactions = const [],
  bool isLoading = false,
  bool hasError = false,
}) {
  return ProviderScope(
    overrides: [
      dailyTransactionsProvider.overrideWith((ref) async {
        if (isLoading) await Future.delayed(const Duration(seconds: 30));
        if (hasError) throw Exception('거래 조회 실패');
        return transactions;
      }),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DailyCategoryBreakdownSheet(date: DateTime(2024, 1, 15)),
      ),
    ),
  );
}

void main() {
  group('DailyCategoryBreakdownSheet 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(transactions: []));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(DailyCategoryBreakdownSheet), findsOneWidget);
    });

    testWidgets('거래가 없으면 빈 상태가 표시된다', (tester) async {
      // Given: 빈 거래 목록
      // When
      await tester.pumpWidget(buildWidget(transactions: []));
      await tester.pumpAndSettle();

      // Then: 빈 상태 메시지 표시
      expect(find.byType(DailyCategoryBreakdownSheet), findsOneWidget);
    });

    testWidgets('거래가 있으면 카테고리별 항목이 표시된다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx-1', type: 'expense', amount: 10000, title: '커피', categoryName: '식비'),
        _makeTransaction(id: 'tx-2', type: 'income', amount: 50000, title: '용돈', categoryName: '수입'),
      ];

      // When
      await tester.pumpWidget(buildWidget(transactions: transactions));
      await tester.pumpAndSettle();

      // Then: 거래 항목이 표시됨
      expect(find.byType(DailyCategoryBreakdownSheet), findsOneWidget);
    });

    testWidgets('로딩 중에 CircularProgressIndicator가 표시된다', (tester) async {
      // Given: Completer를 사용해 Future가 완료되지 않도록 유지
      final completer = Completer<List<Transaction>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTransactionsProvider.overrideWith(
              (ref) => completer.future,
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
              body: DailyCategoryBreakdownSheet(date: DateTime(2024, 1, 15)),
            ),
          ),
        ),
      );
      // 첫 번째 pump - 로딩 상태
      await tester.pump();

      // Then: 로딩 인디케이터 표시
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Cleanup: completer 완료
      completer.complete([]);
    });

    testWidgets('에러 상태에서 에러 위젯이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(hasError: true));
      await tester.pumpAndSettle();

      // Then: 에러 상태 렌더링
      expect(find.byType(DailyCategoryBreakdownSheet), findsOneWidget);
    });

    testWidgets('여러 카테고리의 거래가 있으면 카테고리별로 그룹화된다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx-1', type: 'expense', amount: 5000, title: '아메리카노', categoryName: '카페'),
        _makeTransaction(id: 'tx-2', type: 'expense', amount: 8000, title: '라떼', categoryName: '카페'),
        _makeTransaction(id: 'tx-3', type: 'expense', amount: 12000, title: '점심', categoryName: '식비'),
      ];

      // When
      await tester.pumpWidget(buildWidget(transactions: transactions));
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨
      expect(find.byType(DailyCategoryBreakdownSheet), findsOneWidget);
    });
  });
}
