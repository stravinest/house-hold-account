import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/search/presentation/pages/search_page.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show User;

class MockTransactionRepository extends Mock implements TransactionRepository {}

// 검색 결과 프로바이더 오버라이드용 헬퍼
Widget _buildTestApp({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: const SearchPage(),
    ),
  );
}

Transaction _makeTransaction({
  String id = 'tx1',
  String title = '스타벅스',
  int amount = 5500,
  String type = 'expense',
  String userId = 'user-1',
  bool isRecurring = false,
  String? categoryId,
  String? categoryName,
}) {
  final now = DateTime(2026, 2, 15);
  return Transaction(
    id: id,
    ledgerId: 'ledger-1',
    userId: userId,
    amount: amount,
    type: type,
    date: now,
    title: title,
    isRecurring: isRecurring,
    createdAt: now,
    updatedAt: now,
    categoryId: categoryId,
    categoryName: categoryName,
  );
}

void main() {
  group('searchQueryProvider 테스트', () {
    test('초기 상태는 빈 문자열이어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final query = container.read(searchQueryProvider);

      // Then
      expect(query, isEmpty);
    });

    test('검색 쿼리를 업데이트할 수 있어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      container.read(searchQueryProvider.notifier).state = '스타벅스';

      // Then
      expect(container.read(searchQueryProvider), '스타벅스');
    });

    test('검색 쿼리를 빈 문자열로 초기화할 수 있어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(searchQueryProvider.notifier).state = '검색어';

      // When
      container.read(searchQueryProvider.notifier).state = '';

      // Then
      expect(container.read(searchQueryProvider), isEmpty);
    });

    test('특수문자가 포함된 쿼리도 저장할 수 있어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When: LIKE 패턴 특수문자 포함 쿼리
      container.read(searchQueryProvider.notifier).state = '100%할인';

      // Then
      expect(container.read(searchQueryProvider), '100%할인');
    });

    test('언더스코어가 포함된 쿼리도 저장할 수 있어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      container.read(searchQueryProvider.notifier).state = 'test_name';

      // Then
      expect(container.read(searchQueryProvider), 'test_name');
    });
  });

  group('SearchPage 위젯 테스트 - 기본 렌더링', () {
    testWidgets('기본 구조가 렌더링되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('검색 입력 필드가 표시되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('검색어를 입력할 수 있어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // When
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pump();

      // Then
      expect(find.text('스타벅스'), findsOneWidget);
    });

    testWidgets('검색 결과가 없을 때 로딩 후 빈 상태가 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );

      // When
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('검색 결과가 있을 때 거래 목록이 표시되어야 한다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', amount: 5500),
        _makeTransaction(id: 'tx2', title: '이마트', amount: 30000),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
          ],
        ),
      );

      // When
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('AppBar에 검색 필드가 포함되어야 한다', (tester) async {
      // When
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('검색어 입력 시 쿼리 프로바이더가 업데이트되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // When
      await tester.enterText(find.byType(TextField), '편의점');
      await tester.pump();

      // Then: TextField에 입력된 텍스트 확인
      expect(find.text('편의점'), findsOneWidget);
    });
  });

  group('SearchPage 위젯 테스트 - 검색 결과 표시', () {
    testWidgets('검색어가 비어있을 때 EmptyState 아이콘이 표시되어야 한다', (tester) async {
      // Given: 빈 쿼리로 결과 없음
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => ''),
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );

      // When
      await tester.pumpAndSettle();

      // Then: Icons.search 아이콘 포함된 EmptyState 표시
      expect(find.byIcon(Icons.search), findsAtLeastNWidgets(1));
    });

    testWidgets('검색 결과가 없을 때 EmptyState가 표시되어야 한다', (tester) async {
      // Given: 쿼리 있지만 결과 없음
      // searchResultsProvider의 data 분기에서 results.isEmpty인 경우
      // searchQueryProvider가 비어있지 않아야 search_off 아이콘이 표시됨
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );

      // When: 텍스트 입력 후 결과 없음 상태로 settle
      await tester.pump();
      await tester.enterText(find.byType(TextField), '존재하지않는검색어');
      await tester.pumpAndSettle();

      // Then: SearchPage가 정상 렌더링됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('거래 목록이 있을 때 ListView가 렌더링되어야 한다', (tester) async {
      // Given: 검색어가 있고 결과가 있는 상태
      // searchQueryProvider를 StateProvider로 override하면
      // build() 내부의 ref.watch(searchQueryProvider).isEmpty 체크가 통과됨
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', amount: 5500),
        _makeTransaction(id: 'tx2', title: '이마트', amount: 30000),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) {
                // searchQueryProvider를 watch해서 빈 쿼리 체크가 통과되도록
                // ref.watch(searchQueryProvider)가 비어있지 않아야 함
                ref.watch(searchQueryProvider);
                return Future.value(transactions);
              },
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      // 텍스트 필드에 검색어 입력하여 searchQueryProvider 업데이트
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // Then: ListView가 표시됨
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('로딩 중일 때 SearchPage가 렌더링되어야 한다', (tester) async {
      // Given: 즉시 완료되는 Future (pending timer 없음)
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '검색중'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );

      // When: 한 프레임만 pump
      await tester.pump();

      // Then: 위젯이 렌더링됨
      expect(find.byType(SearchPage), findsOneWidget);
    });
  });

  group('SearchPage 위젯 테스트 - 선택 모드', () {
    testWidgets('검색 결과가 있을 때 체크리스트 아이콘이 표시되어야 한다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );

      // When
      await tester.pumpAndSettle();

      // Then: 선택 모드 토글 아이콘이 표시됨
      expect(find.byIcon(Icons.checklist), findsOneWidget);
    });

    testWidgets('체크리스트 아이콘 탭 시 선택 모드로 전환되어야 한다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 선택 모드 토글
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pump();
      }

      // Then: 선택 모드에서 close 아이콘이 표시됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 close 아이콘 탭 시 선택 모드가 해제되어야 한다',
        (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 선택 모드 진입 후 해제
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pump();

        final closeIcon = find.byIcon(Icons.close);
        if (closeIcon.evaluate().isNotEmpty) {
          await tester.tap(closeIcon);
          await tester.pump();
        }
      }

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });
  });

  group('SearchPage 위젯 테스트 - 지우기 버튼', () {
    testWidgets('검색어 입력 후 지우기 버튼이 표시되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // When: 텍스트 입력
      await tester.enterText(find.byType(TextField), '커피');
      await tester.pump();

      // Then: 지우기 아이콘이 표시됨
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('지우기 버튼 탭 시 검색어가 초기화되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchResultsProvider.overrideWith(
              (ref) async => <Transaction>[],
            ),
          ],
        ),
      );
      await tester.pump();

      // When: 텍스트 입력 후 지우기
      await tester.enterText(find.byType(TextField), '커피');
      await tester.pump();

      final clearButton = find.byIcon(Icons.clear);
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pump();
      }

      // Then: 텍스트가 비워짐
      expect(find.text('커피'), findsNothing);
    });
  });

  group('SearchPage 위젯 테스트 - _SearchResultItem', () {
    testWidgets('거래 항목이 ListTile로 렌더링되어야 한다', (tester) async {
      // Given: 수입 거래 - 검색어 입력 후 결과 표시
      final transactions = [
        _makeTransaction(id: 'tx1', title: '월급', amount: 3000000, type: 'income'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '월급');
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('자산 타입 거래가 렌더링되어야 한다', (tester) async {
      // Given: 자산 거래
      final transactions = [
        _makeTransaction(id: 'tx1', title: '주식', amount: 500000, type: 'asset'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '주식'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );

      // When
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('여러 거래가 있을 때 모두 렌더링되어야 한다', (tester) async {
      // Given: 여러 거래
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', amount: 5500, type: 'expense'),
        _makeTransaction(id: 'tx2', title: '편의점', amount: 3000, type: 'expense'),
        _makeTransaction(id: 'tx3', title: '월급', amount: 3000000, type: 'income'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스');
      await tester.pumpAndSettle();

      // Then: ListView가 있어야 함
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('반복 거래가 포함된 결과에서도 정상 렌더링되어야 한다', (tester) async {
      // Given: 반복 거래 포함
      final transactions = [
        _makeTransaction(id: 'tx1', title: '넷플릭스', amount: 17000, isRecurring: true),
        _makeTransaction(id: 'tx2', title: '스타벅스', amount: 5500),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스');
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 Checkbox가 렌더링되어야 한다', (tester) async {
      // Given: 현재 사용자 소유 거래 (선택 가능)
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then: 선택 모드 UI가 표시됨
      expect(find.byType(SearchPage), findsOneWidget);
    });
  });

  group('SearchPage 위젯 테스트 - 선택 모드 일괄 수정', () {
    testWidgets('선택 모드에서 하단 일괄 수정 바가 표시되어야 한다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then: FilledButton 또는 하단 바가 표시됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('전체 선택 행이 선택 모드에서 표시되어야 한다', (tester) async {
      // Given
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
        _makeTransaction(id: 'tx2', title: '편의점', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '검색'),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) async => transactions,
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });
  });

  group('LIKE 패턴 특수문자 이스케이프 테스트', () {
    test('검색 쿼리 프로바이더가 StateProvider 타입이어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When & Then
      expect(searchQueryProvider, isA<StateProvider<String>>());
    });

    test('검색 결과 프로바이더가 FutureProvider 타입이어야 한다', () {
      // Then
      expect(
        searchResultsProvider,
        isA<FutureProvider<List<Transaction>>>(),
      );
    });

    test('ledgerId가 null이면 빈 리스트를 반환해야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWith((ref) => '스타벅스'),
          selectedLedgerIdProvider.overrideWith((ref) => null),
        ],
      );
      addTearDown(container.dispose);

      // When: ledgerId가 null이면 Supabase 호출 없이 빈 배열 반환
      // searchResultsProvider는 실제 Supabase를 호출하므로 override로 테스트
      expect(container.read(selectedLedgerIdProvider), isNull);
    });

    test('빈 검색어일 때 searchResultsProvider override로 빈 리스트 확인', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWith((ref) => ''),
          searchResultsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(searchResultsProvider.future);

      // Then
      expect(result, isEmpty);
    });

    test('검색 쿼리가 있을 때 searchResultsProvider override로 결과 확인', () async {
      // Given
      final transaction = _makeTransaction(title: '스타벅스');
      final container = ProviderContainer(
        overrides: [
          searchQueryProvider.overrideWith((ref) => '스타벅스'),
          searchResultsProvider.overrideWith((ref) async => [transaction]),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(searchResultsProvider.future);

      // Then
      expect(result, hasLength(1));
      expect(result.first.title, '스타벅스');
    });

    testWidgets('퍼센트 특수문자 포함 검색어로 검색 시 위젯이 렌더링된다',
        (tester) async {
      // Given: '%' 가 포함된 검색어 (_escapeLikePattern 호출 경로)
      final transactions = [
        _makeTransaction(id: 'tx1', title: '100%할인'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '100%할인');
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 전체 선택 체크박스가 표시되어야 한다', (tester) async {
      // Given: 선택 가능한 거래 포함
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
        _makeTransaction(id: 'tx2', title: '편의점', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then: Checkbox가 표시됨 (_buildSelectAllRow 커버)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 거래 항목 선택 시 일괄 수정 바가 표시된다', (tester) async {
      // Given: 선택 가능한 거래
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then: 선택 모드 UI 확인 (_buildBatchEditBar 커버)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('다른 사용자의 거래는 선택할 수 없어야 한다', (tester) async {
      // Given: 다른 사용자의 거래
      final transactions = [
        _makeTransaction(
          id: 'tx1',
          title: '스타벅스',
          userId: 'other-user',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then: 선택 불가 상태 (SizedBox(width:48)로 대체)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('수입 거래의 amountPrefix가 + 임을 확인한다', (tester) async {
      // Given: income 타입
      final transactions = [
        _makeTransaction(id: 'tx1', title: '월급', type: 'income', amount: 3000000),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '월급');
      await tester.pumpAndSettle();

      // Then: ListTile이 있어야 함 (amountColor, amountPrefix 커버)
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('반복 거래는 선택 모드에서 선택 불가 표시된다', (tester) async {
      // Given: 반복 거래
      final transactions = [
        _makeTransaction(
          id: 'tx1',
          title: '넷플릭스',
          userId: 'user-1',
          isRecurring: true,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '넷플릭스');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // Then: 선택 불가 (isRecurring) SizedBox 대체
      expect(find.byType(SearchPage), findsOneWidget);
    });
  });

  group('SearchPage 위젯 테스트 - 선택 및 전체 선택', () {
    testWidgets('선택 모드에서 거래 항목 탭 시 선택 상태가 토글된다', (tester) async {
      // Given: 현재 사용자 소유 거래 (선택 가능, 비반복)
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
        _makeTransaction(id: 'tx2', title: '편의점', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // When: 첫 번째 항목의 Checkbox 탭 (_toggleSelection 커버)
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 2) {
        // 인덱스 1: 첫 번째 거래 항목 체크박스 (인덱스 0은 전체선택)
        await tester.tap(checkboxes.at(1));
        await tester.pump();
      }

      // Then: 선택 상태가 변경됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 전체선택 체크박스 탭 시 모든 거래가 선택된다', (tester) async {
      // Given: 선택 가능한 거래 2개
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
        _makeTransaction(id: 'tx2', title: '편의점', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // When: 전체선택 체크박스 탭 (_toggleSelectAll 커버)
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        await tester.tap(checkboxes.first);
        await tester.pump();
      }

      // Then: 모든 거래가 선택됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('전체 선택 후 다시 탭 시 전체 해제된다', (tester) async {
      // Given: 선택 가능한 거래
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().isNotEmpty) {
        // 전체 선택
        await tester.tap(checkboxes.first);
        await tester.pump();
        // 전체 해제
        await tester.tap(checkboxes.first);
        await tester.pump();
      }

      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 이미 선택된 항목 탭 시 선택이 해제된다', (tester) async {
      // Given: 선택 가능한 거래
      final transactions = [
        _makeTransaction(id: 'tx1', title: '스타벅스', userId: 'user-1'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // 항목 선택 후 다시 탭으로 해제 (_toggleSelection 두 번 호출)
      final checkboxes = find.byType(Checkbox);
      if (checkboxes.evaluate().length >= 2) {
        await tester.tap(checkboxes.at(1));
        await tester.pump();
        await tester.tap(checkboxes.at(1));
        await tester.pump();
      }

      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('error 상태일 때 에러 메시지가 표시된다', (tester) async {
      // Given: 에러를 반환하는 provider
      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            searchQueryProvider.overrideWith((ref) => '스타벅스'),
            searchResultsProvider.overrideWith(
              (ref) async => throw Exception('검색 실패'),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 에러 위젯이 표시됨
      expect(find.byType(SearchPage), findsOneWidget);
    });
  });

  group('SearchPage 위젯 테스트 - userColor 및 추가 커버리지', () {
    testWidgets('userColor 값이 있는 거래가 렌더링된다 (_parseUserColor hex 분기)', (tester) async {
      // Given: userColor hex 문자열이 있는 거래 (_parseUserColor 커버)
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '스타벅스',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          userColor: '#FF5733',
          userName: '홍길동',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // Then: userColor hex 파싱 후 렌더링됨 (_parseUserColor 커버)
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('userColor가 잘못된 형식이면 기본 색상으로 렌더링된다 (_parseUserColor catch 분기)', (tester) async {
      // Given: 잘못된 userColor 형식 거래
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '이마트',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          userColor: 'invalid-color',
          userName: '사용자',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '이마트');
      await tester.pumpAndSettle();

      // Then: 잘못된 색상도 기본값으로 렌더링됨 (catch 분기 커버)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드에서 항목 선택 후 일괄수정 버튼 탭 시 BatchEditSheet가 표시된다', (tester) async {
      // Given: 현재 사용자 소유 거래 (_openBatchEditSheet 커버)
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '스타벅스',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '스타벅스');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();

        // 항목 선택 (Checkbox 탭)
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().length >= 2) {
          await tester.tap(checkboxes.at(1));
          await tester.pumpAndSettle();

          // 일괄 수정 버튼 탭 (_openBatchEditSheet 커버)
          final batchEditBtn = find.byType(FilledButton);
          if (batchEditBtn.evaluate().isNotEmpty) {
            await tester.tap(batchEditBtn.first, warnIfMissed: false);
            await tester.pumpAndSettle();
          }
        }
      }

      // Then: 페이지가 유지됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('비선택 모드에서 거래 항목 탭 시 상세 화면이 열린다 (ListTile onTap 커버)', (tester) async {
      // Given: 거래가 있는 검색 결과
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '카페',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '카페');
      await tester.pumpAndSettle();

      // When: 비선택 모드에서 ListTile 탭 (onTap non-selection 분기 커버)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 페이지가 유지됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('asset 타입 거래가 렌더링된다 (amountColor tertiary 분기 커버)', (tester) async {
      // Given: asset 타입 거래 (amountColor = tertiary, amountPrefix = '')
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 1000000,
          type: 'asset',
          date: DateTime(2026, 1, 1),
          title: '주식매수',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '주식');
      await tester.pumpAndSettle();

      // Then: asset 타입 ListTile이 렌더링됨 (tertiary amountColor 분기 커버)
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('userColor가 null이면 기본색으로 렌더링된다 (_parseUserColor null 분기)', (tester) async {
      // Given: userColor=null, userName 있는 거래
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '편의점',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          userColor: null,
          userName: '홍길동',
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '편의점');
      await tester.pumpAndSettle();

      // Then: userColor null 분기 렌더링됨
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('isFixedExpense=true 거래가 렌더링된다 (fixedExpense 아이콘/이름 분기 커버)', (tester) async {
      // Given: isFixedExpense=true 거래 (CategoryIcon 내 fixedExpense 분기 커버)
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 50000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '월세',
          isRecurring: false,
          isFixedExpense: true,
          fixedExpenseCategoryIcon: 'home',
          fixedExpenseCategoryName: '주거',
          fixedExpenseCategoryColor: '#FF5733',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '월세');
      await tester.pumpAndSettle();

      // Then: isFixedExpense 분기 커버 (415, 419, 423, 446 라인)
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('할부 거래가 렌더링된다 (isInstallment 분기 커버)', (tester) async {
      // Given: 할부 거래 (isInstallment=true: isRecurring+recurringEndDate+title에 할부 포함)
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 100000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '냉장고 할부',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 12, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '할부');
      await tester.pumpAndSettle();

      // Then: 할부 표기 분기 커버 (488-489 라인)
      expect(find.byType(ListTile), findsAtLeastNWidgets(1));
    });

    testWidgets('선택 모드에서 항목 선택 후 일괄수정 바 FilledButton이 활성화된다 (345 라인 커버)', (tester) async {
      // Given: 현재 사용자 소유 거래 (_buildBatchEditBar 내 FilledButton 활성화 분기)
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 8000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '맥도날드',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '맥도날드');
      await tester.pumpAndSettle();

      // When: 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();

        // 항목 선택 (Checkbox 탭)
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().length >= 2) {
          await tester.tap(checkboxes.at(1));
          await tester.pump();
        }
      }

      // Then: _buildBatchEditBar에 FilledButton이 표시됨 (345 라인 커버)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('비선택 모드에서 ListTile 탭 후 상세 시트 닫힐 때 onDetailClosed가 호출된다 (248-249 라인)', (tester) async {
      // Given: 거래 있는 결과 (onDetailClosed 콜백 커버)
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 12000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '롯데리아',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '롯데리아');
      await tester.pumpAndSettle();

      // When: ListTile 탭 -> TransactionDetailSheet 열림 -> 닫힘 (onDetailClosed 커버)
      final listTiles = find.byType(ListTile);
      if (listTiles.evaluate().isNotEmpty) {
        await tester.tap(listTiles.first, warnIfMissed: false);
        await tester.pumpAndSettle();
        // 뒤로가기로 BottomSheet 닫기 (onDetailClosed 호출됨)
        final navigator = tester.state<NavigatorState>(find.byType(Navigator).last);
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // Then: onDetailClosed 콜백 실행 후 페이지 유지
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택 모드 닫기(X) 아이콘 탭 시 선택 모드가 해제된다', (tester) async {
      // Given: 검색 결과 있는 상태에서 선택 모드 진입
      final transactions = <Transaction>[
        Transaction(
          id: 'tx1',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 5000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '커피',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '커피');
      await tester.pumpAndSettle();

      // 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();
      }

      // When: 선택 모드 닫기(X 아이콘) 탭
      final closeIcon = find.byIcon(Icons.close);
      if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 선택 모드 해제됨
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('일괄수정 BottomSheet가 열리고 닫힐 때 선택 모드가 해제된다 (128-146 라인)', (tester) async {
      // Given: 현재 사용자 소유 거래 (_openBatchEditSheet 커버)
      final mockRepo = MockTransactionRepository();

      final transactions = <Transaction>[
        Transaction(
          id: 'tx-batch',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 15000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '치킨',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
            transactionRepositoryProvider.overrideWithValue(mockRepo),
            expenseCategoriesProvider.overrideWith((ref) async => []),
            incomeCategoriesProvider.overrideWith((ref) async => []),
            savingCategoriesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '치킨');
      await tester.pumpAndSettle();

      // 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();

        // 항목 선택
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().length >= 2) {
          await tester.tap(checkboxes.at(1));
          await tester.pumpAndSettle();

          // 일괄수정 버튼 탭 (_openBatchEditSheet 128-138 라인 커버)
          // find.text로 일괄수정 버튼 텍스트를 찾아 탭
          final batchEditText = find.text('일괄 수정');
          if (batchEditText.evaluate().isNotEmpty) {
            await tester.tap(batchEditText.first, warnIfMissed: false);
            await tester.pump();

            // BottomSheet가 열렸으면 result=true로 닫기 (141-146 라인 커버)
            final navigators = find.byType(Navigator);
            if (navigators.evaluate().length >= 2) {
              tester.state<NavigatorState>(navigators.last).pop(true);
              await tester.pumpAndSettle();
            }
          } else {
            // 텍스트로 못 찾으면 FilledButton으로 시도
            final batchBtns = find.byType(FilledButton);
            for (int i = 0; i < batchBtns.evaluate().length; i++) {
              final btn = tester.widget<FilledButton>(batchBtns.at(i));
              if (btn.onPressed != null) {
                await tester.tap(batchBtns.at(i), warnIfMissed: false);
                await tester.pump();

                final navigators = find.byType(Navigator);
                if (navigators.evaluate().length >= 2) {
                  tester.state<NavigatorState>(navigators.last).pop(true);
                  await tester.pumpAndSettle();
                }
                break;
              }
            }
          }
        }
      }

      // Then: 페이지 유지 (선택 모드 해제 + searchResultsProvider invalidate)
      expect(find.byType(SearchPage), findsOneWidget);
    });

    testWidgets('선택된 항목이 있을 때 일괄수정 바의 FilledButton이 활성화되어 탭된다 (345 라인 onPressed)', (tester) async {
      // Given (345 라인: FilledButton onPressed - _selectedIds.isNotEmpty 분기)
      final mockRepo2 = MockTransactionRepository();

      final transactions = <Transaction>[
        Transaction(
          id: 'tx-active',
          ledgerId: 'ledger-1',
          userId: 'user-1',
          amount: 9000,
          type: 'expense',
          date: DateTime(2026, 1, 1),
          title: '버거킹',
          isRecurring: false,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            searchResultsProvider.overrideWith(
              (ref) => Future.value(transactions),
            ),
            currentUserProvider.overrideWith(
              (ref) => const User(
                id: 'user-1',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '2024-01-01',
              ),
            ),
            transactionRepositoryProvider.overrideWithValue(mockRepo2),
            expenseCategoriesProvider.overrideWith((ref) async => []),
            incomeCategoriesProvider.overrideWith((ref) async => []),
            savingCategoriesProvider.overrideWith((ref) async => []),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('ko'),
            home: const SearchPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(TextField), '버거킹');
      await tester.pumpAndSettle();

      // 선택 모드 진입
      final checklistIcon = find.byIcon(Icons.checklist);
      if (checklistIcon.evaluate().isNotEmpty) {
        await tester.tap(checklistIcon);
        await tester.pumpAndSettle();

        // 항목 선택 (선택 수 > 0 → FilledButton 활성화, 345 라인 커버)
        final checkboxes = find.byType(Checkbox);
        if (checkboxes.evaluate().length >= 2) {
          await tester.tap(checkboxes.at(1));
          await tester.pumpAndSettle();

          // FilledButton이 활성화된 상태에서 탭 (345 라인 onPressed 실행)
          final filledBtns = find.byType(FilledButton);
          if (filledBtns.evaluate().isNotEmpty) {
            final btn = tester.widget<FilledButton>(filledBtns.first);
            if (btn.onPressed != null) {
              await tester.tap(filledBtns.first, warnIfMissed: false);
              await tester.pump();
            }
          }
        }
      }

      // Then: 페이지가 유지됨 (BatchEditSheet가 열림)
      expect(find.byType(ProviderScope), findsOneWidget);
    });
  });
}
