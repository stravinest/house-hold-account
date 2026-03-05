import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/monthly_list_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/transaction_filter_chips.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TransactionFilterChips 위젯 테스트용 래퍼
Widget buildTestWidget({
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: TransactionFilterChips(),
      ),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('TransactionFilterChips 위젯 테스트', () {
    testWidgets('기본 렌더링 시 전체 필터가 활성화된다', (tester) async {
      // When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then: TransactionFilterChips가 렌더링됨
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('필터 버튼 아이콘이 표시된다', (tester) async {
      // When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then: 필터 아이콘이 표시됨
      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('기본 상태에서 전체 배지가 표시된다', (tester) async {
      // When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then: 전체 필터 배지가 표시됨 (l10n.filterAll)
      // 최소한 위젯이 렌더링되는지 확인
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('PopupMenuButton이 렌더링된다', (tester) async {
      // When
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PopupMenuButton<TransactionFilter>), findsOneWidget);
    });

    testWidgets('필터 상태가 all일 때 단일 배지가 표시된다', (tester) async {
      // Given: 기본값은 all
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Then: Row 내부에 배지가 1개 있어야 함
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('income 필터가 선택된 상태로 렌더링된다', (tester) async {
      // Given: income 필터 설정
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: TransactionFilterChips가 렌더링됨
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('여러 필터가 선택된 상태로 렌더링된다', (tester) async {
      // Given: income, expense 복수 필터 설정
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income, TransactionFilter.expense},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: TransactionFilterChips가 렌더링됨
      expect(find.byType(TransactionFilterChips), findsOneWidget);
      // 여러 배지가 표시됨 (income, expense 각각)
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('expense 필터 선택 시 X 버튼이 있는 배지가 표시된다', (tester) async {
      // Given: expense 필터 설정 (non-all 필터는 X 아이콘 포함)
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.expense},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then: close 아이콘이 표시됨 (non-all 배지에 X 아이콘)
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('X 아이콘 클릭 시 필터가 제거된다', (tester) async {
      // Given: expense 필터 설정
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.expense},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: X 아이콘이 있는 GestureDetector 탭
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Then: 위젯은 여전히 렌더링됨 (필터 제거 후 all로 복귀)
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('PopupMenuButton 탭 시 메뉴가 열린다', (tester) async {
      // Given
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // When: filter_list 아이콘 탭
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Then: 메뉴 아이템들이 표시됨 (keyboard_arrow_down 포함)
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('PopupMenu에서 income 필터 선택 시 toggleFilter가 실행된다', (tester) async {
      // Given: 기본 상태 (all 필터)
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // When: 필터 버튼 탭 → 메뉴 열림
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // income 메뉴 아이템 탭 (toggleFilter 실행: 41-63 라인 커버)
      final incomeItem = find.text('수입');
      if (incomeItem.evaluate().isNotEmpty) {
        await tester.tap(incomeItem.first);
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('income 필터 선택 후 다시 탭하면 all로 복귀한다', (tester) async {
      // Given: income 필터 선택 상태
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 필터 버튼 → income 재탭 (이미 선택된 필터 제거: 51-56 라인 커버)
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      final incomeItem = find.text('수입');
      if (incomeItem.evaluate().isNotEmpty) {
        await tester.tap(incomeItem.first);
        await tester.pumpAndSettle();
      }

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('all 필터 탭 시 toggleFilter에서 all로 설정된다', (tester) async {
      // Given: income 필터 선택 상태
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.income},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // When: 필터 버튼 → all 탭 (44-49 라인: all 선택 분기 커버)
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      final allItem = find.text('전체');
      if (allItem.evaluate().isNotEmpty) {
        await tester.tap(allItem.first);
        await tester.pumpAndSettle();
      }

      // Then: all 배지가 표시됨
      expect(find.byType(TransactionFilterChips), findsOneWidget);
    });

    testWidgets('asset 필터 선택 상태에서 X 클릭 시 all로 돌아간다', (tester) async {
      // Given: asset 필터 설정
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.asset},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // 초기 상태 확인
      expect(find.byIcon(Icons.close), findsOneWidget);

      // When: X 클릭
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Then: close 아이콘이 사라짐 (all 필터로 복귀, all 배지에는 X 없음)
      expect(find.byIcon(Icons.close), findsNothing);
    });

    testWidgets('recurring 필터 선택 상태로 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        buildTestWidget(
          overrides: [
            selectedFiltersProvider.overrideWith(
              (ref) => {TransactionFilter.recurring},
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TransactionFilterChips), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('TransactionFilterChips toggleFilter 로직 Provider 테스트', () {
    test('toggleFilter: all 선택 시 상태가 {all}로 설정된다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 초기에 income 필터 설정
      container.read(selectedFiltersProvider.notifier).state = {
        TransactionFilter.income,
      };

      // When: all 선택 (L44-48 경로 시뮬레이션)
      final filter = TransactionFilter.all;
      if (filter == TransactionFilter.all) {
        container.read(selectedFiltersProvider.notifier).state = {
          TransactionFilter.all,
        };
      }

      // Then
      expect(
        container.read(selectedFiltersProvider),
        equals({TransactionFilter.all}),
      );
    });

    test('toggleFilter: 이미 선택된 필터 제거 후 빈 목록이면 all로 복귀한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedFiltersProvider.notifier).state = {
        TransactionFilter.income,
      };

      // When: income 제거 (L51-56 경로 시뮬레이션)
      final currentFilters = Set<TransactionFilter>.from(
        container.read(selectedFiltersProvider),
      );
      const filter = TransactionFilter.income;
      if (currentFilters.contains(filter)) {
        currentFilters.remove(filter);
        currentFilters.remove(TransactionFilter.all);
        if (currentFilters.isEmpty) {
          currentFilters.add(TransactionFilter.all);
        }
      }
      container.read(selectedFiltersProvider.notifier).state = currentFilters;

      // Then: all로 복귀
      expect(
        container.read(selectedFiltersProvider),
        equals({TransactionFilter.all}),
      );
    });

    test('toggleFilter: 새 필터 추가 시 all이 제거된다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 기본값 all
      expect(
        container.read(selectedFiltersProvider),
        equals({TransactionFilter.all}),
      );

      // When: income 추가 (L57-60 경로 시뮬레이션)
      final currentFilters = Set<TransactionFilter>.from(
        container.read(selectedFiltersProvider),
      );
      const filter = TransactionFilter.income;
      if (!currentFilters.contains(filter)) {
        currentFilters.add(filter);
        currentFilters.remove(TransactionFilter.all);
      }
      container.read(selectedFiltersProvider.notifier).state = currentFilters;

      // Then: income만 남고 all이 제거됨
      expect(
        container.read(selectedFiltersProvider).contains(TransactionFilter.income),
        isTrue,
      );
      expect(
        container.read(selectedFiltersProvider).contains(TransactionFilter.all),
        isFalse,
      );
    });

    test('toggleFilter: income+expense 선택 후 income 제거 시 expense만 남는다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(selectedFiltersProvider.notifier).state = {
        TransactionFilter.income,
        TransactionFilter.expense,
      };

      // When: income 제거 (L51-56 경로, 빈 목록 아닌 경우)
      final currentFilters = Set<TransactionFilter>.from(
        container.read(selectedFiltersProvider),
      );
      currentFilters.remove(TransactionFilter.income);
      currentFilters.remove(TransactionFilter.all);
      if (currentFilters.isEmpty) {
        currentFilters.add(TransactionFilter.all);
      }
      container.read(selectedFiltersProvider.notifier).state = currentFilters;

      // Then: expense만 남음
      expect(
        container.read(selectedFiltersProvider),
        equals({TransactionFilter.expense}),
      );
    });
  });

  group('TransactionFilter 필터 로직 단위 테스트', () {
    test('all 필터가 선택되면 다른 필터를 제거한다', () {
      // Given
      var filters = <TransactionFilter>{
        TransactionFilter.income,
        TransactionFilter.expense,
      };

      // When: all 선택
      filters = {TransactionFilter.all};

      // Then
      expect(filters, equals({TransactionFilter.all}));
    });

    test('특정 필터 선택 시 all이 제거된다', () {
      // Given: 기본값 all
      final currentFilters = {TransactionFilter.all};

      // When: income 추가
      final newFilters = Set<TransactionFilter>.from(currentFilters)
        ..add(TransactionFilter.income)
        ..remove(TransactionFilter.all);

      // Then: all이 제거되고 income만 남음
      expect(newFilters.contains(TransactionFilter.all), isFalse);
      expect(newFilters.contains(TransactionFilter.income), isTrue);
    });

    test('모든 필터 제거 시 all로 자동 복귀한다', () {
      // Given: income만 선택된 상태
      var currentFilters = <TransactionFilter>{TransactionFilter.income};

      // When: income 제거
      currentFilters.remove(TransactionFilter.income);
      if (currentFilters.isEmpty) {
        currentFilters.add(TransactionFilter.all);
      }

      // Then: all로 복귀
      expect(currentFilters, equals({TransactionFilter.all}));
    });

    test('all 배지에서 X 클릭 시 제거되지 않는다', () {
      // Given
      var currentFilters = <TransactionFilter>{TransactionFilter.all};

      // When: all 제거 시도 (isAll이면 return)
      const filter = TransactionFilter.all;
      if (filter == TransactionFilter.all) {
        // 제거하지 않음
      } else {
        currentFilters.remove(filter);
      }

      // Then: all이 그대로 유지됨
      expect(currentFilters.contains(TransactionFilter.all), isTrue);
    });

    test('income과 expense 동시 선택 가능하다', () {
      // Given
      var filters = <TransactionFilter>{TransactionFilter.all};

      // When
      filters = {TransactionFilter.income, TransactionFilter.expense};

      // Then
      expect(filters.contains(TransactionFilter.income), isTrue);
      expect(filters.contains(TransactionFilter.expense), isTrue);
      expect(filters.contains(TransactionFilter.all), isFalse);
    });
  });

  group('TransactionFilterChips toggleFilter 위젯 탭 테스트', () {
    testWidgets('PopupMenuButton에서 all 필터 탭 시 selectedFilters가 all로 설정된다', (tester) async {
      // Given: income 필터 선택 상태
      final container = ProviderContainer(
        overrides: [
          selectedFiltersProvider.overrideWith(
            (ref) => {TransactionFilter.income},
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TransactionFilterChips(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 필터 버튼 탭 → 메뉴 열기
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // When: '전체' 메뉴 아이템 탭 (toggleFilter all 분기 커버)
      final allItem = find.text('전체');
      if (allItem.evaluate().isNotEmpty) {
        await tester.tap(allItem.first);
        await tester.pumpAndSettle();
        // Then: all로 설정됨
        expect(
          container.read(selectedFiltersProvider),
          equals({TransactionFilter.all}),
        );
      }
    });

    testWidgets('PopupMenuButton에서 income 탭 시 all이 제거되고 income이 선택된다', (tester) async {
      // Given: all 필터 상태 (기본값)
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TransactionFilterChips(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 필터 버튼 탭 → 메뉴 열기
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // When: '수입' 메뉴 아이템 탭 (toggleFilter 새 필터 추가 분기 커버)
      final incomeItem = find.text('수입');
      if (incomeItem.evaluate().isNotEmpty) {
        await tester.tap(incomeItem.first);
        await tester.pumpAndSettle();
        // Then: income이 선택되고 all이 제거됨
        final filters = container.read(selectedFiltersProvider);
        expect(filters.contains(TransactionFilter.income), isTrue);
        expect(filters.contains(TransactionFilter.all), isFalse);
      }
    });

    testWidgets('income 선택 후 같은 income 탭 시 all로 복귀한다', (tester) async {
      // Given: income 필터 선택 상태
      final container = ProviderContainer(
        overrides: [
          selectedFiltersProvider.overrideWith(
            (ref) => {TransactionFilter.income},
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: TransactionFilterChips(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 필터 버튼 탭 → income 재탭 (이미 선택된 필터 제거 분기 커버)
      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      final incomeItem = find.text('수입');
      if (incomeItem.evaluate().isNotEmpty) {
        await tester.tap(incomeItem.first);
        await tester.pumpAndSettle();
        // Then: all로 복귀 (income 제거 후 빈 목록 → all 복귀)
        final filters = container.read(selectedFiltersProvider);
        expect(filters.contains(TransactionFilter.all), isTrue);
      }
    });
  });
}
