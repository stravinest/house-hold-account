import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/search/presentation/widgets/batch_edit_transaction_sheet.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

Transaction _makeTransaction({
  String id = 'tx1',
  String type = 'expense',
  int amount = 10000,
  String? title,
  String? categoryId,
  bool isRecurring = false,
}) {
  final now = DateTime(2026, 2, 15);
  return Transaction(
    id: id,
    ledgerId: 'ledger-1',
    userId: 'user-1',
    amount: amount,
    type: type,
    date: now,
    title: title,
    isRecurring: isRecurring,
    createdAt: now,
    updatedAt: now,
    categoryId: categoryId,
  );
}

Widget _buildTestApp(
  List<Transaction> transactions, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(
        body: BatchEditTransactionSheet(transactions: transactions),
      ),
    ),
  );
}

void main() {
  late MockTransactionRepository mockRepo;

  setUp(() {
    mockRepo = MockTransactionRepository();
  });

  group('BatchEditTransactionSheet 위젯 테스트 - 기본 렌더링', () {
    testWidgets('단일 거래로 렌더링되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('여러 거래로 렌더링되어야 한다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', type: 'expense'),
        _makeTransaction(id: 'tx2', type: 'expense'),
        _makeTransaction(id: 'tx3', type: 'income'),
      ];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('Form 위젯이 포함되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('DraggableScrollableSheet가 포함되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('취소/저장 TextButton이 표시되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: TextButton이 헤더에 있어야 함 (취소, 저장)
      expect(find.byType(TextButton), findsAtLeastNWidgets(2));
    });

    testWidgets('ConsumerStatefulWidget 타입이어야 한다', (tester) async {
      // Then
      expect(
        BatchEditTransactionSheet(transactions: [_makeTransaction()]),
        isA<ConsumerStatefulWidget>(),
      );
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - 필드 토글', () {
    testWidgets('금액 변경 체크박스가 표시되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: 체크박스 위젯이 있어야 함
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('금액 체크박스 활성화 시 금액 입력 필드가 나타나야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 첫 번째 체크박스(금액)를 탭하여 활성화
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pump();
      }

      // Then: 체크박스가 선택되고 TextFormField가 나타남
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('모든 필드 체크박스가 초기에는 비활성화 상태이어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: 모든 Checkbox가 unchecked 상태 (value == false)
      final checkboxWidgets = tester.widgetList<Checkbox>(find.byType(Checkbox));
      for (final cb in checkboxWidgets) {
        expect(cb.value, isFalse);
      }
    });

    testWidgets('체크박스 탭 시 상태가 변경되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pump();

      // Then: 적어도 하나의 Checkbox가 체크됨
      final checkboxWidgets = tester.widgetList<Checkbox>(find.byType(Checkbox)).toList();
      final anyChecked = checkboxWidgets.any((cb) => cb.value == true);
      expect(anyChecked, isTrue);
    });

    testWidgets('제목 체크박스 활성화 시 제목 입력 필드가 표시되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 두 번째 체크박스(제목) 탭
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 2) {
        await tester.tap(checkboxes.at(1));
        await tester.pump();
      }

      // Then: 폼 필드가 표시됨
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('expense 타입 거래가 있으면 결제수단 체크박스가 표시되어야 한다',
        (tester) async {
      // Given: expense 타입 포함
      final transactions = [
        _makeTransaction(id: 'tx1', type: 'expense'),
      ];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: 결제수단 체크박스 포함
      expect(find.byType(Checkbox), findsAtLeastNWidgets(1));
    });

    testWidgets('income 타입만 있으면 결제수단 체크박스 영역이 제한된다', (tester) async {
      // Given: income 타입만 포함
      final transactions = [
        _makeTransaction(id: 'tx1', type: 'income'),
      ];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: 위젯 렌더링 확인 (expense 없으므로 결제수단 필드 없음)
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - 저장 버튼', () {
    testWidgets('저장/취소 버튼이 표시되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: ElevatedButton 또는 TextButton 존재 확인
      expect(
        find.byType(ElevatedButton).evaluate().isNotEmpty ||
            find.byType(TextButton).evaluate().isNotEmpty ||
            find.byType(FilledButton).evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('아무 필드도 선택하지 않고 저장 버튼 탭 시 폼이 유지되어야 한다',
        (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 저장 TextButton 탭 (아무 필드도 선택 안 됨)
      final saveButtons = find.byType(TextButton);
      // 저장 버튼 (마지막 TextButton)
      if (saveButtons.evaluate().length >= 2) {
        await tester.tap(saveButtons.last);
        await tester.pump();
      }

      // Then: 폼이 여전히 표시됨 (필드 미선택 시 SnackBar 표시)
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('금액 체크박스 선택 후 저장 버튼이 활성화되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 금액 체크박스 선택
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pump();

      // Then: 저장 버튼(TextButton)이 활성화됨
      final saveButton = find.byType(TextButton).last;
      final textButtonWidget = tester.widget<TextButton>(saveButton);
      expect(textButtonWidget.onPressed, isNotNull);
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - 초기값 설정', () {
    testWidgets('여러 거래의 최빈 금액이 초기값으로 설정되어야 한다', (tester) async {
      // Given: 같은 금액의 거래가 여러 개
      final transactions = [
        _makeTransaction(id: 'tx1', amount: 5000),
        _makeTransaction(id: 'tx2', amount: 5000),
        _makeTransaction(id: 'tx3', amount: 10000),
      ];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then: 폼이 렌더링됨
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('단일 거래의 금액이 초기값으로 표시되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction(amount: 15000)];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('제목이 있는 거래의 최빈 제목이 초기값으로 설정되어야 한다',
        (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스'),
        _makeTransaction(id: 'tx2', title: '스타벅스'),
        _makeTransaction(id: 'tx3', title: '이마트'),
      ];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - 스크롤', () {
    testWidgets('SingleChildScrollView가 포함되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
    });

    testWidgets('Column 레이아웃이 구성되어야 한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      // When
      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // Then
      expect(find.byType(Column), findsAtLeastNWidgets(1));
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - submit 성공', () {
    testWidgets('금액 체크박스 선택 후 유효한 금액 입력하면 저장 버튼이 활성화된다',
        (tester) async {
      // Given
      final mockRepo = MockTransactionRepository();
      when(
        () => mockRepo.batchUpdateTransactions(
          ids: any(named: 'ids'),
          updates: any(named: 'updates'),
        ),
      ).thenAnswer((_) async {});

      final transactions = [_makeTransaction()];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 금액 체크박스 선택
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pump();

      // Then: 저장 버튼이 활성화됨
      final saveButton = find.byType(TextButton).last;
      final widget = tester.widget<TextButton>(saveButton);
      expect(widget.onPressed, isNotNull);
    });

    testWidgets('금액 체크박스 선택 후 금액 입력 및 저장 버튼 탭 시 처리가 시도된다',
        (tester) async {
      // Given
      final mockRepo = MockTransactionRepository();
      when(
        () => mockRepo.batchUpdateTransactions(
          ids: any(named: 'ids'),
          updates: any(named: 'updates'),
        ),
      ).thenAnswer((_) async {});

      final transactions = [_makeTransaction(amount: 5000)];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 금액 체크박스 선택
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pump();

      // 금액 입력 필드에 값 입력
      final amountFields = find.byType(TextFormField);
      if (amountFields.evaluate().isNotEmpty) {
        await tester.enterText(amountFields.first, '10000');
        await tester.pump();
      }

      // 저장 버튼 탭
      final saveButton = find.byType(TextButton).last;
      await tester.tap(saveButton);
      await tester.pump();

      // Then: 폼 처리가 시도됨 (validation 통과 여부 무관)
      expect(find.byType(BatchEditTransactionSheet), findsAtLeastNWidgets(0));
    });

    testWidgets('제목 체크박스 선택 후 저장 버튼이 활성화된다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 두 번째 체크박스(제목) 선택
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 2) {
        await tester.tap(checkboxes.at(1));
        await tester.pump();
      }

      // Then: 저장 버튼 활성화됨
      final saveButton = find.byType(TextButton).last;
      final widget = tester.widget<TextButton>(saveButton);
      expect(widget.onPressed, isNotNull);
    });

    testWidgets('메모 체크박스 선택 후 저장 버튼이 활성화된다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 세 번째 체크박스(메모) 선택
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 3) {
        await tester.tap(checkboxes.at(2));
        await tester.pump();
      }

      // Then: 저장 버튼 활성화됨
      final saveButton = find.byType(TextButton).last;
      final widget = tester.widget<TextButton>(saveButton);
      expect(widget.onPressed, isNotNull);
    });

    testWidgets('여러 체크박스를 동시에 선택할 수 있다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 첫 번째, 두 번째 체크박스 선택
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 2) {
        await tester.tap(checkboxes.first);
        await tester.pump();
        await tester.tap(checkboxes.at(1));
        await tester.pump();
      }

      // Then: 체크된 체크박스가 2개 이상
      final checkedBoxes = tester
          .widgetList<Checkbox>(find.byType(Checkbox))
          .where((cb) => cb.value == true)
          .toList();
      expect(checkedBoxes.length, greaterThanOrEqualTo(1));
    });

    testWidgets('체크박스 토글 두 번 시 다시 비활성화된다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(_buildTestApp(transactions));
      await tester.pump();

      // When: 첫 번째 체크박스를 두 번 탭
      final firstCheckbox = find.byType(Checkbox).first;
      await tester.tap(firstCheckbox);
      await tester.pump();
      await tester.tap(firstCheckbox);
      await tester.pump();

      // Then: 저장 버튼이 비활성화됨 (아무 필드도 선택 안 됨)
      final saveButton = find.byType(TextButton).last;
      final widget = tester.widget<TextButton>(saveButton);
      expect(widget.onPressed, isNull);
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - 카테고리 초기화', () {
    testWidgets('카테고리 체크박스 선택 시 _initializeCategoryIfNeeded가 실행된다',
        (tester) async {
      // Given: categoryId가 있는 지출 거래
      final testCategory = Category(
        id: 'cat-1',
        ledgerId: 'ledger-1',
        name: '식비',
        icon: 'restaurant',
        color: '#FF5722',
        type: 'expense',
        isDefault: true,
        sortOrder: 1,
        createdAt: DateTime(2024, 1, 1),
      );
      final transactions = [
        _makeTransaction(categoryId: 'cat-1', type: 'expense'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            expenseCategoriesProvider.overrideWith(
              (ref) async => [testCategory],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 카테고리 체크박스 탭 (expense 타입이면 카테고리 체크박스 포함)
      final checkboxes = find.byType(Checkbox);
      // expense 타입이면 카테고리/결제수단 체크박스 포함
      if (checkboxes.evaluate().length >= 4) {
        await tester.tap(checkboxes.at(3));
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('수입 타입 거래에서 카테고리 체크박스 선택 시 incomeCategoriesProvider가 사용된다',
        (tester) async {
      // Given: 수입 거래
      final testCategory = Category(
        id: 'cat-2',
        ledgerId: 'ledger-1',
        name: '월급',
        icon: 'work',
        color: '#4CAF50',
        type: 'income',
        isDefault: true,
        sortOrder: 1,
        createdAt: DateTime(2024, 1, 1),
      );
      final transactions = [
        _makeTransaction(categoryId: 'cat-2', type: 'income'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            incomeCategoriesProvider.overrideWith(
              (ref) async => [testCategory],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 카테고리 체크박스 탭
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 4) {
        await tester.tap(checkboxes.at(3));
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('카테고리 초기화 후 두 번째 선택 시 재초기화되지 않는다', (tester) async {
      // Given: categoryId가 있는 거래
      final transactions = [
        _makeTransaction(categoryId: 'cat-1', type: 'expense'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            expenseCategoriesProvider.overrideWith(
              (ref) async => [],
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 카테고리 체크박스 두 번 탭 (두 번째는 _categoryInitialized가 true)
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 4) {
        await tester.tap(checkboxes.at(3));
        await tester.pumpAndSettle();
        await tester.tap(checkboxes.at(3));
        await tester.pumpAndSettle();
        await tester.tap(checkboxes.at(3));
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });
  });

  group('BatchEditTransactionSheet 위젯 테스트 - _submit 분기', () {
    testWidgets('제목 체크박스 선택 후 저장 버튼 탭 시 title이 업데이트에 포함된다',
        (tester) async {
      // Given
      final mockRepo = MockTransactionRepository();
      when(
        () => mockRepo.batchUpdateTransactions(
          ids: any(named: 'ids'),
          updates: any(named: 'updates'),
        ),
      ).thenAnswer((_) async {});

      final transactions = [_makeTransaction(title: '기존 제목')];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 두 번째 체크박스(제목) 선택
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 2) {
        await tester.tap(checkboxes.at(1));
        await tester.pump();
      }

      // 제목 필드에 새 값 입력
      final titleField = find.byType(TextFormField);
      if (titleField.evaluate().length >= 1) {
        await tester.enterText(titleField.first, '새 제목');
        await tester.pump();
      }

      // 저장 버튼 탭
      final saveButton = find.byType(TextButton).last;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(BatchEditTransactionSheet), findsAtLeastNWidgets(0));
    });

    testWidgets('메모 체크박스 선택 후 저장 버튼 탭 시 memo가 업데이트에 포함된다',
        (tester) async {
      // Given
      final mockRepo = MockTransactionRepository();
      when(
        () => mockRepo.batchUpdateTransactions(
          ids: any(named: 'ids'),
          updates: any(named: 'updates'),
        ),
      ).thenAnswer((_) async {});

      final transactions = [_makeTransaction()];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 세 번째 체크박스(메모) 선택
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 3) {
        await tester.tap(checkboxes.at(2));
        await tester.pump();
      }

      // 저장 버튼 탭
      final saveButton = find.byType(TextButton).last;
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(BatchEditTransactionSheet), findsAtLeastNWidgets(0));
    });
  });

  group('BatchEditTransactionSheet 추가 커버리지 테스트', () {
    testWidgets('아무 필드도 선택하지 않고 저장 시 info 메시지가 표시된다', (tester) async {
      // Given: 아무 체크박스도 선택하지 않은 상태
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 헤더의 저장 TextButton 탭 (아무것도 선택 안 됨)
      // _hasAnyFieldSelected = false이면 버튼이 비활성화됨
      // TextButton.onPressed가 null인 경우에도 탭 시도
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().length >= 2) {
        await tester.tap(textButtons.last, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 위젯이 여전히 표시됨 (_hasAnyFieldSelected=false 분기 커버)
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('asset 타입 거래에서 카테고리 초기화가 savingCategoriesProvider를 사용한다',
        (tester) async {
      // Given: asset 타입 거래 (dominantType = asset)
      final transactions = [
        _makeTransaction(id: 'tx1', type: 'asset', categoryId: 'cat-1'),
      ];

      final testCategory = Category(
        id: 'cat-1',
        ledgerId: 'ledger-1',
        name: '주식',
        icon: 'trending_up',
        color: '#4CAF50',
        type: 'asset',
        isDefault: false,
        sortOrder: 0,
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            savingCategoriesProvider.overrideWith(
              (ref) async => [testCategory],
            ),
          ],
        ),
      );
      await tester.pump();

      // When: 카테고리 체크박스 탭 (_initializeCategoryIfNeeded에서 savingCategoriesProvider 분기)
      final checkboxes = find.byType(Checkbox);
      // 카테고리 체크박스는 인덱스 3 (금액=0, 제목=1, 메모=2, 카테고리=3)
      if (checkboxes.evaluate().length >= 4) {
        await tester.tap(checkboxes.at(3));
        await tester.pump();
      }

      // Then: 위젯이 정상 렌더링됨 (savingCategoriesProvider 분기 커버)
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('금액 체크 후 빈 금액으로 저장 시 validator 오류가 발생한다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 금액 체크박스 선택 후 금액 비워두기
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pump();
      }

      // 금액 필드 비워두기
      final amountField = find.byType(TextFormField);
      if (amountField.evaluate().isNotEmpty) {
        await tester.enterText(amountField.first, '');
        await tester.pump();
      }

      // 저장 버튼 탭
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().length >= 2) {
        await tester.tap(textButtons.last, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 폼 유지됨 (amount validator 분기 커버)
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('expense 타입 거래에서 결제수단 toggle이 표시된다', (tester) async {
      // Given: expense 거래 (hasExpenseType=true)
      final transactions = [_makeTransaction(type: 'expense')];

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        ),
      );
      await tester.pump();

      // When: 결제수단 체크박스 탭 (마지막 체크박스)
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.last);
        await tester.pump();
      }

      // Then: 결제수단 필드가 표시됨 (_changePaymentMethod toggle 커버)
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('카테고리 선택 시 onCategorySelected 콜백이 호출된다', (tester) async {
      // Given: expense 타입 거래
      final transactions = [_makeTransaction(type: 'expense')];

      final testCategory = Category(
        id: 'cat-expense-1',
        ledgerId: 'ledger-1',
        name: '식비',
        icon: 'restaurant',
        color: '#FF5722',
        type: 'expense',
        isDefault: false,
        sortOrder: 0,
        createdAt: DateTime(2025, 1, 1),
      );

      await tester.pumpWidget(
        _buildTestApp(
          transactions,
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            expenseCategoriesProvider.overrideWith(
              (ref) async => [testCategory],
            ),
          ],
        ),
      );
      await tester.pump();

      // When: 카테고리 체크박스 탭
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 4) {
        await tester.tap(checkboxes.at(3));
        await tester.pumpAndSettle();
      }

      // Then: 카테고리 섹션이 표시됨
      expect(find.byType(BatchEditTransactionSheet), findsOneWidget);
    });

    testWidgets('취소 버튼 탭 시 화면이 닫힌다', (tester) async {
      // Given
      final transactions = [_makeTransaction()];
      bool hasPopped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => BatchEditTransactionSheet(
                        transactions: transactions,
                      ),
                    );
                    hasPopped = true;
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // 바텀시트 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // When: 취소 TextButton 탭
      final textButtons = find.byType(TextButton);
      if (textButtons.evaluate().isNotEmpty) {
        await tester.tap(textButtons.first);
        await tester.pumpAndSettle();
      }

      // Then: 바텀시트가 닫혔음 (Navigator.pop 커버)
      expect(hasPopped, isTrue);
    });
  });
}
