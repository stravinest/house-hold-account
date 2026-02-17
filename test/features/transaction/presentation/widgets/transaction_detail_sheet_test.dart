import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/transaction_detail_sheet.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Transaction _createTransaction({
  String type = 'expense',
  bool isFixedExpense = false,
}) {
  return Transaction(
    id: 'test-id',
    ledgerId: 'ledger-id',
    userId: 'user-id',
    type: type,
    amount: 10000,
    date: DateTime(2026, 1, 15),
    createdAt: DateTime(2026, 1, 15, 10, 30),
    isFixedExpense: isFixedExpense,
    isRecurring: false,
    updatedAt: DateTime(2026, 1, 15, 10, 30),
  );
}

Widget _buildTestWidget(Transaction transaction) {
  return ProviderScope(
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (_) => TransactionDetailSheet(
                  transaction: transaction,
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('TransactionDetailSheet 분류 뱃지 테스트', () {
    testWidgets('지출 거래일 때 "지출" 뱃지만 표시된다', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(_createTransaction(type: 'expense')),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('지출'), findsOneWidget);
      expect(find.text('고정비'), findsNothing);
      expect(find.text('수입'), findsNothing);
      expect(find.text('자산'), findsNothing);
    });

    testWidgets('수입 거래일 때 "수입" 뱃지만 표시된다', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(_createTransaction(type: 'income')),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('수입'), findsOneWidget);
      expect(find.text('지출'), findsNothing);
      expect(find.text('자산'), findsNothing);
    });

    testWidgets('자산 거래일 때 "자산" 뱃지만 표시된다', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(_createTransaction(type: 'asset')),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('자산'), findsOneWidget);
      expect(find.text('지출'), findsNothing);
      expect(find.text('수입'), findsNothing);
    });

    testWidgets('고정비 지출 거래일 때 "지출"과 "고정비" 뱃지 2개가 표시된다',
        (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(
          _createTransaction(type: 'expense', isFixedExpense: true),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('지출'), findsOneWidget);
      expect(find.text('고정비'), findsOneWidget);
    });

    testWidgets('분류 라벨 텍스트가 표시된다', (tester) async {
      await tester.pumpWidget(
        _buildTestWidget(_createTransaction()),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.text('분류'), findsOneWidget);
    });
  });
}
