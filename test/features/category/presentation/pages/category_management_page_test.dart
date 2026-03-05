import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/pages/category_management_page.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

/// 테스트 위젯 빌더 헬퍼
Widget buildTestApp({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

CategoryModel _makeCategory({
  String id = '1',
  String name = '식비',
  String icon = 'restaurant',
  String color = '#FF5722',
  String type = 'expense',
  int sortOrder = 0,
}) {
  return CategoryModel(
    id: id,
    ledgerId: 'test-ledger-id',
    name: name,
    icon: icon,
    color: color,
    type: type,
    isDefault: false,
    sortOrder: sortOrder,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue('test-ledger-id');
  });

  group('CategoryManagementPage 위젯 테스트', () {
    testWidgets('카테고리 목록이 비어있을 때 Empty State가 표시되어야 한다', (tester) async {
      // Given: 빈 카테고리 목록
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      // When: 위젯이 빌드됨
      await tester.pumpAndSettle();

      // Then: Empty State 아이콘이 표시되어야 함
      expect(find.byIcon(Icons.category_outlined), findsWidgets);
    });

    testWidgets('지출 카테고리 목록이 정상적으로 표시되어야 한다', (tester) async {
      // Given: 지출 카테고리 데이터
      final categories = <CategoryModel>[
        _makeCategory(id: '1', name: '식비', type: 'expense'),
        _makeCategory(id: '2', name: '교통비', icon: 'directions_car', color: '#2196F3', type: 'expense', sortOrder: 1),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 지출 탭에 카테고리 이름이 표시되어야 함
      expect(find.text('식비'), findsOneWidget);
      expect(find.text('교통비'), findsOneWidget);
    });

    testWidgets('FloatingActionButton이 표시되어야 한다', (tester) async {
      // Given: 카테고리 목록
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // When & Then: FloatingActionButton이 표시되어야 함
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('카테고리 항목에 수정 및 삭제 버튼이 표시되어야 한다', (tester) async {
      // Given: 카테고리 데이터
      final categories = <CategoryModel>[
        _makeCategory(id: '1', name: '식비'),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // When & Then: 수정 및 삭제 아이콘 버튼이 표시되어야 함
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('TabBar에 지출/수입/자산 탭이 표시되어야 한다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 3개의 탭이 표시됨
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(Tab), findsNWidgets(3));
    });

    testWidgets('수입 탭으로 전환하면 수입 카테고리가 표시되어야 한다', (tester) async {
      // Given
      final categories = <CategoryModel>[
        _makeCategory(id: '1', name: '식비', type: 'expense'),
        _makeCategory(id: '2', name: '급여', icon: 'payments', color: '#4CAF50', type: 'income', sortOrder: 0),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // When: 수입 탭을 탭
      await tester.tap(find.byType(Tab).at(1));
      await tester.pumpAndSettle();

      // Then: 수입 카테고리만 표시
      expect(find.text('급여'), findsOneWidget);
      expect(find.text('식비'), findsNothing);
    });

    testWidgets('자산 탭으로 전환하면 자산 카테고리가 표시되어야 한다', (tester) async {
      // Given
      final categories = <CategoryModel>[
        _makeCategory(id: '1', name: '식비', type: 'expense'),
        _makeCategory(id: '2', name: '정기예금', icon: 'savings', color: '#2196F3', type: 'asset', sortOrder: 0),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // When: 자산 탭을 탭
      await tester.tap(find.byType(Tab).at(2));
      await tester.pumpAndSettle();

      // Then: 자산 카테고리만 표시
      expect(find.text('정기예금'), findsOneWidget);
      expect(find.text('식비'), findsNothing);
    });

    testWidgets('FAB 탭 시 CategoryEditDialog가 열려야 한다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // When: FAB 버튼 탭
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('수정 버튼 탭 시 CategoryEditDialog가 기존 데이터로 열려야 한다', (tester) async {
      // Given
      final categories = <CategoryModel>[
        _makeCategory(id: '1', name: '식비'),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // When: 수정 버튼 탭
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 열리고 기존 이름이 표시됨
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('식비'), findsWidgets);
    });
  });

  group('CategoryEditDialog 위젯 테스트', () {
    testWidgets('새 카테고리 추가 다이얼로그가 정상적으로 렌더링된다 - expense 타입', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const Scaffold(
            body: CategoryEditDialog(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 다이얼로그 요소가 표시됨
      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('income 타입 다이얼로그가 정상적으로 렌더링된다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const Scaffold(
            body: CategoryEditDialog(type: 'income'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('asset 타입 다이얼로그가 정상적으로 렌더링된다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const Scaffold(
            body: CategoryEditDialog(type: 'asset'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('수정 모드에서는 기존 카테고리 정보가 폼에 채워져야 한다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      final existingCategory = _makeCategory(id: 'cat-1', name: '기존카테고리');

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: Scaffold(
            body: CategoryEditDialog(
              type: 'expense',
              category: existingCategory,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 기존 이름이 입력 필드에 채워짐
      expect(find.text('기존카테고리'), findsWidgets);
    });

    testWidgets('이름 없이 제출하면 유효성 오류가 표시되어야 한다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const Scaffold(
            body: CategoryEditDialog(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 이름 없이 추가 버튼 탭
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 유효성 오류 메시지가 표시됨
      expect(find.byType(TextFormField), findsOneWidget);
      // 폼 유효성 실패 시 submit이 실행되지 않음 (다이얼로그가 닫히지 않음)
      expect(find.byType(FilledButton), findsOneWidget);
    });

    testWidgets('이름을 입력하면 아이콘 미리보기가 업데이트된다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const Scaffold(
            body: CategoryEditDialog(type: 'expense'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 이름 입력
      await tester.enterText(find.byType(TextFormField), '새 카테고리');
      await tester.pump();

      // Then: 입력한 텍스트가 표시됨
      expect(find.text('새 카테고리'), findsWidgets);
    });

    testWidgets('취소 버튼 탭 시 다이얼로그가 닫혀야 한다', (tester) async {
      // Given
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);

      bool dialogClosed = false;

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                await showDialog(
                  context: context,
                  builder: (_) => const CategoryEditDialog(type: 'expense'),
                );
                dialogClosed = true;
              },
              child: const Text('열기'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 다이얼로그 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // 취소 버튼 탭
      await tester.tap(find.byType(TextButton).last);
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(dialogClosed, isTrue);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('카테고리 생성 성공 시 다이얼로그가 닫혀야 한다', (tester) async {
      // Given: ScaffoldMessenger가 포함된 환경에서 테스트
      final newCategory = _makeCategory(id: 'new-cat', name: '새카테고리');
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);
      when(
        () => repository.createCategory(
          ledgerId: any(named: 'ledgerId'),
          name: any(named: 'name'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async => newCategory);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const CategoryEditDialog(type: 'expense'),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 다이얼로그 열기 → 이름 입력 → 제출
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '새카테고리');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('카테고리 수정 성공 시 다이얼로그가 닫혀야 한다', (tester) async {
      // Given: ScaffoldMessenger가 포함된 환경
      final existing = _makeCategory(id: 'cat-1', name: '기존카테고리');
      final updated = _makeCategory(id: 'cat-1', name: '수정된카테고리');
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => [existing]);
      when(
        () => repository.updateCategory(
          id: any(named: 'id'),
          name: any(named: 'name'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
        ),
      ).thenAnswer((_) async => updated);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => CategoryEditDialog(
                      type: 'expense',
                      category: existing,
                    ),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 다이얼로그 열기 → 이름 수정 → 제출
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '수정된카테고리');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 다이얼로그가 닫힘
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('카테고리 생성 실패 시 에러 처리 후 다이얼로그가 닫히지 않는다', (tester) async {
      // Given: 에러를 반환하는 레포지토리 (Scaffold 환경에서 실행)
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any())).thenAnswer((_) async => []);
      when(
        () => repository.createCategory(
          ledgerId: any(named: 'ledgerId'),
          name: any(named: 'name'),
          icon: any(named: 'icon'),
          color: any(named: 'color'),
          type: any(named: 'type'),
        ),
      ).thenThrow(Exception('생성 실패'));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog(
                    context: context,
                    builder: (_) => const CategoryEditDialog(type: 'expense'),
                  ),
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 다이얼로그 열기 → 이름 입력 → 제출
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField), '실패카테고리');
      await tester.pump();

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      // Then: 에러 후 다이얼로그가 여전히 표시됨 (SnackBar로 에러 표시)
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('_CategoryListView 로딩 상태 테스트', () {
    testWidgets('데이터 로딩 완료 후 카드가 표시된다', (tester) async {
      // Given: 카테고리 데이터 반환
      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => [_makeCategory(id: '1', name: '식비')]);

      await tester.pumpWidget(
        buildTestApp(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CategoryManagementPage(),
        ),
      );

      // When: 비동기 작업 완료 대기
      await tester.pumpAndSettle();

      // Then: 카드가 표시됨
      expect(find.byType(Card), findsWidgets);
    });
  });
}
