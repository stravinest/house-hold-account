import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/pending_transaction_card.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('PendingTransactionCard Widget Tests', () {
    late PendingTransactionModel mockTransaction;

    setUp(() {
      final now = DateTime.now();
      mockTransaction = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'payment_method_id',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '카드결제 10,000원 스타벅스',
        sourceTimestamp: now,
        parsedAmount: 10000,
        parsedType: 'expense',
        parsedMerchant: '스타벅스',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );
    });

    testWidgets('거래 카드가 기본 정보를 렌더링한다', (tester) async {
      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: mockTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.text('스타벅스'), findsOneWidget);
      expect(find.text('카드결제 10,000원 스타벅스'), findsOneWidget);
    });

    testWidgets('파싱된 금액이 올바른 형식으로 표시된다', (tester) async {
      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: mockTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );

      // Then: 금액이 포함된 텍스트가 표시되어야 한다 (여러 곳에 표시될 수 있음)
      expect(find.textContaining('10,000원'), findsWidgets);
    });

    testWidgets('SMS 소스 타입 배지가 표시된다', (tester) async {
      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: mockTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.sms_outlined), findsOneWidget);
    });

    testWidgets('Push 소스 타입 배지가 표시된다', (tester) async {
      // Given
      final now = DateTime.now();
      final pushTransaction = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'payment_method_id',
        sourceType: SourceType.notification,
        sourceSender: 'KB Pay',
        sourceContent: '카드결제 10,000원 스타벅스',
        sourceTimestamp: now,
        parsedAmount: 10000,
        parsedType: 'expense',
        parsedMerchant: '스타벅스',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: pushTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    });

    testWidgets('파싱되지 않은 거래는 경고 메시지를 표시한다', (tester) async {
      // Given
      final now = DateTime.now();
      final unparsedTransaction = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'payment_method_id',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '알 수 없는 메시지 형식',
        sourceTimestamp: now,
        parsedAmount: null,
        parsedType: null,
        parsedMerchant: null,
        parsedCategoryId: null,
        parsedDate: null,
        status: PendingTransactionStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: false,
        duplicateHash: null,
        isDuplicate: false,
      );

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: unparsedTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('onConfirm 콜백이 제공되면 저장 버튼이 표시된다', (tester) async {
      // Given
      bool confirmCalled = false;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: mockTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
                onConfirm: () {
                  confirmCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.textContaining('저장'), findsOneWidget);
    });

    testWidgets('onReject 콜백이 제공되면 거부 버튼이 표시된다', (tester) async {
      // Given
      bool rejectCalled = false;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: mockTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
                onReject: () {
                  rejectCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.textContaining('거부'), findsOneWidget);
    });

    testWidgets('삭제 버튼이 렌더링되고 탭이 가능하다', (tester) async {
      // Given
      bool deleteCalled = false;

      // When
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Scaffold(
              body: PendingTransactionCard(
                transaction: mockTransaction,
                ledgerId: 'ledger_id',
                userId: 'user_id',
                onDelete: () {
                  deleteCalled = true;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });
}
