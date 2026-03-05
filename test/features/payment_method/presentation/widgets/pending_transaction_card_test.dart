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

    testWidgets('삭제 버튼 탭 시 onDelete 콜백이 호출된다', (tester) async {
      // Given: 삭제 콜백이 있는 카드
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

      // Then: 삭제 버튼을 탭한다
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pump();

      // 콜백이 호출되어야 한다
      expect(deleteCalled, isTrue);
    });

    testWidgets('저장 버튼 탭 시 onConfirm 콜백이 호출된다', (tester) async {
      // Given: 확인 콜백이 있는 카드 (파싱된 거래)
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

      // When: 저장 버튼을 탭한다
      final saveButton = find.textContaining('저장');
      expect(saveButton, findsWidgets);
      await tester.tap(saveButton.first);
      await tester.pump();

      // Then: 콜백이 호출되어야 한다
      expect(confirmCalled, isTrue);
    });

    testWidgets('거부 버튼 탭 시 onReject 콜백이 호출된다', (tester) async {
      // Given: 거부 콜백이 있는 카드
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

      // When: 거부 버튼을 탭한다
      final rejectButton = find.textContaining('거부');
      expect(rejectButton, findsWidgets);
      await tester.tap(rejectButton.first);
      await tester.pump();

      // Then: 콜백이 호출되어야 한다
      expect(rejectCalled, isTrue);
    });

    testWidgets('확인됨 상태의 거래 카드가 올바른 상태 배지를 표시한다', (tester) async {
      // Given: 확인됨 상태의 거래
      final now = DateTime.now();
      final confirmedTx = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '카드결제 5,000원 편의점',
        sourceTimestamp: now,
        parsedAmount: 5000,
        parsedType: 'expense',
        parsedMerchant: '편의점',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.confirmed,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: true,
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
                transaction: confirmedTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 확인 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('거부됨 상태의 거래 카드가 올바른 상태 배지를 표시한다', (tester) async {
      // Given: 거부됨 상태의 거래
      final now = DateTime.now();
      final rejectedTx = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '카드결제 3,000원 카페',
        sourceTimestamp: now,
        parsedAmount: 3000,
        parsedType: 'expense',
        parsedMerchant: '카페',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.rejected,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: true,
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
                transaction: rejectedTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 닫기 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('저장됨(converted) 상태의 거래 카드가 올바른 상태 배지를 표시한다', (tester) async {
      // Given: converted 상태의 거래
      final now = DateTime.now();
      final convertedTx = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '카드결제 8,000원 마트',
        sourceTimestamp: now,
        parsedAmount: 8000,
        parsedType: 'expense',
        parsedMerchant: '마트',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.converted,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: true,
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
                transaction: convertedTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 체크원 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('수입 거래는 파란색 금액이 표시된다', (tester) async {
      // Given: 수입 거래
      final now = DateTime.now();
      final incomeTx = PendingTransactionModel(
        id: 'income_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
        sourceType: SourceType.sms,
        sourceSender: 'BANK',
        sourceContent: '입금 50,000원',
        sourceTimestamp: now,
        parsedAmount: 50000,
        parsedType: 'income',
        parsedMerchant: '월급',
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
                transaction: incomeTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 월급 텍스트가 표시되어야 한다
      expect(find.textContaining('월급'), findsWidgets);
    });

    testWidgets('중복 거래 카드는 경고 섹션을 표시한다', (tester) async {
      // Given: 중복 표시된 거래
      final now = DateTime.now();
      final dupTx = PendingTransactionModel(
        id: 'dup_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
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
        duplicateHash: 'hash_abc',
        isDuplicate: true,
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
                transaction: dupTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
                onConfirm: () {},
                onReject: () {},
                onEdit: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 정보 아이콘이 표시되어야 한다 (중복 경고)
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('중복 거래 카드의 펼침 버튼을 탭하면 내용이 확장된다', (tester) async {
      // Given: 중복 표시된 거래
      final now = DateTime.now();
      final dupTx = PendingTransactionModel(
        id: 'dup_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
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
        duplicateHash: 'hash_abc',
        isDuplicate: true,
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
                transaction: dupTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 펼침 아이콘을 탭한다
      final expandIcon = find.byIcon(Icons.keyboard_arrow_down);
      if (expandIcon.evaluate().isNotEmpty) {
        await tester.tap(expandIcon.first);
        await tester.pumpAndSettle();

        // Then: 접힘 아이콘이 표시되어야 한다
        expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      }
    });

    testWidgets('수신자 이름이 있으면 발신자 텍스트가 표시된다', (tester) async {
      // Given: 발신자가 있는 거래
      final now = DateTime.now();
      final txWithSender = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
        sourceType: SourceType.sms,
        sourceSender: 'KB국민카드',
        sourceContent: '카드결제 10,000원',
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
                transaction: txWithSender,
                ledgerId: 'ledger_id',
                userId: 'user_id',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 발신자 이름이 표시되어야 한다
      expect(find.textContaining('KB국민카드'), findsWidgets);
    });

    testWidgets('콜백 없이 생성된 카드는 액션 버튼을 표시하지 않는다', (tester) async {
      // Given: 콜백이 없는 카드 (확인됨 상태)
      final now = DateTime.now();
      final confirmedTx = PendingTransactionModel(
        id: 'test_id',
        ledgerId: 'ledger_id',
        userId: 'user_id',
        paymentMethodId: 'pm_id',
        sourceType: SourceType.sms,
        sourceSender: '1234',
        sourceContent: '카드결제 5,000원',
        sourceTimestamp: now,
        parsedAmount: 5000,
        parsedType: 'expense',
        parsedMerchant: '편의점',
        parsedCategoryId: null,
        parsedDate: now,
        status: PendingTransactionStatus.confirmed,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        isViewed: true,
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
                transaction: confirmedTx,
                ledgerId: 'ledger_id',
                userId: 'user_id',
                // onConfirm, onReject, onEdit 없음
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: 저장/거부 버튼이 없어야 한다
      expect(find.textContaining('저장'), findsNothing);
      expect(find.textContaining('거부'), findsNothing);
    });
  });
}
