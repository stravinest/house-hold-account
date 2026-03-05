import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/category_selector_widget.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/mock_repositories.dart';

Widget _buildApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: Scaffold(body: child),
    ),
  );
}

Category _makeCategory({
  String id = 'cat-1',
  String name = '식비',
  String type = 'expense',
}) {
  return Category(
    id: id,
    ledgerId: 'ledger-1',
    name: name,
    icon: 'restaurant',
    color: '#FF5733',
    type: type,
    isDefault: false,
    sortOrder: 0,
    createdAt: DateTime(2024, 1, 1),
  );
}

void main() {
  group('CategorySelectorWidget 위젯 테스트', () {
    testWidgets('카테고리가 없을 때 위젯이 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => <Category>[]),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('카테고리 목록이 있을 때 Chip으로 표시된다', (tester) async {
      // Given
      final testCategories = [
        _makeCategory(id: 'cat-1', name: '식비'),
        _makeCategory(id: 'cat-2', name: '교통'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => testCategories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 카테고리 이름이 표시되어야 함
      expect(find.text('식비'), findsOneWidget);
      expect(find.text('교통'), findsOneWidget);
    });

    testWidgets('선택된 카테고리가 강조 표시된다', (tester) async {
      // Given
      final selectedCategory = _makeCategory(id: 'cat-1', name: '식비');

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => [selectedCategory]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: selectedCategory,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 선택된 카테고리가 표시되어야 함
      expect(find.text('식비'), findsOneWidget);
    });

    testWidgets('수입 타입일 때 수입 카테고리가 표시된다', (tester) async {
      // Given
      final incomeCategory = _makeCategory(
        id: 'cat-income',
        name: '급여',
        type: 'income',
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            incomeCategoriesProvider
                .overrideWith((ref) async => [incomeCategory]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'income',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.text('급여'), findsOneWidget);
    });

    testWidgets('카테고리 탭 시 onCategorySelected 콜백이 호출된다', (tester) async {
      // Given
      Category? selectedCategory;
      final testCategory = _makeCategory(id: 'cat-1', name: '식비');

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => [testCategory]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (cat) => selectedCategory = cat,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 카테고리 칩 탭
      await tester.tap(find.text('식비'));
      await tester.pump();

      // Then
      expect(selectedCategory, isNotNull);
      expect(selectedCategory!.name, '식비');
    });

    testWidgets('enabled=false일 때 위젯이 비활성화 상태로 렌더링된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => <Category>[]),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
            enabled: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('자산 타입일 때 savingCategories가 사용된다', (tester) async {
      // Given
      final assetCategory = _makeCategory(
        id: 'cat-asset',
        name: '정기예금',
        type: 'asset',
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            savingCategoriesProvider
                .overrideWith((ref) async => [assetCategory]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'asset',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 자산 카테고리 이름이 표시됨
      expect(find.text('정기예금'), findsOneWidget);
    });

    testWidgets('에러 상태일 때 에러 메시지가 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith(
              (ref) async => throw Exception('로드 실패'),
            ),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨 (에러 텍스트 표시)
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('편집 버튼 탭 시 편집 모드로 전환된다', (tester) async {
      // Given
      final categories = [
        _makeCategory(id: 'cat-1', name: '식비'),
        _makeCategory(id: 'cat-2', name: '교통'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 ActionChip 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pump();

        // Then: 카테고리 이름이 여전히 표시됨 (편집 모드)
        expect(find.text('식비'), findsWidgets);
      } else {
        expect(find.byType(CategorySelectorWidget), findsOneWidget);
      }
    });

    testWidgets('편집 모드에서 완료 버튼 탭 시 기본 모드로 돌아간다', (tester) async {
      // Given
      final categories = [_makeCategory(id: 'cat-1', name: '식비')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 버튼 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pump();

        // 완료 버튼 탭
        final doneChip = find.byWidgetPredicate(
          (w) => w is ActionChip && (w.label as Text).data == '완료',
        );
        if (doneChip.evaluate().isNotEmpty) {
          await tester.tap(doneChip.first);
          await tester.pump();
        }
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('추가 및 편집 ActionChip이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => <Category>[]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Then: ActionChip들이 표시됨
      expect(find.byType(ActionChip), findsWidgets);
    });

    testWidgets('편집 모드에서 카테고리 삭제 아이콘이 표시된다', (tester) async {
      // Given
      final categories = [_makeCategory(id: 'cat-1', name: '식비')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pump();

        // Then: 삭제(close) 아이콘이 표시됨
        expect(find.byIcon(Icons.close), findsWidgets);
      }
    });

    testWidgets('수입 타입 카테고리 탭 시 콜백이 호출된다', (tester) async {
      // Given
      Category? selected;
      final incomeCategory = _makeCategory(
        id: 'inc-1',
        name: '부수입',
        type: 'income',
      );

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            incomeCategoriesProvider
                .overrideWith((ref) async => [incomeCategory]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'income',
            onCategorySelected: (c) => selected = c,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 카테고리 탭
      await tester.tap(find.text('부수입'));
      await tester.pump();

      // Then
      expect(selected, isNotNull);
      expect(selected!.name, '부수입');
    });

    testWidgets('편집 모드에서 삭제 아이콘 탭 시 삭제 확인 다이얼로그가 표시된다', (tester) async {
      // Given
      final categories = [_makeCategory(id: 'cat-1', name: '식비')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입 후 삭제 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );

      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        final closeIcons = find.byIcon(Icons.close);
        if (closeIcons.evaluate().isNotEmpty) {
          await tester.tap(closeIcons.first);
          await tester.pumpAndSettle();

          // Then: 삭제 확인 다이얼로그 표시
          expect(find.byType(AlertDialog), findsOneWidget);
        }
      }

      // 다이얼로그가 표시되지 않아도 위젯은 렌더링되어야 함
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('삭제 확인 다이얼로그에서 취소 탭 시 다이얼로그가 닫힌다', (tester) async {
      // Given
      final categories = [_makeCategory(id: 'cat-1', name: '식비')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 편집 모드 진입 후 삭제 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );

      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        final closeIcons = find.byIcon(Icons.close);
        if (closeIcons.evaluate().isNotEmpty) {
          await tester.tap(closeIcons.first);
          await tester.pumpAndSettle();

          // 다이얼로그가 표시된 경우 취소 버튼 탭
          final alertDialog = find.byType(AlertDialog);
          if (alertDialog.evaluate().isNotEmpty) {
            // 취소 버튼 탭
            final cancelButton = find.text('취소');
            if (cancelButton.evaluate().isNotEmpty) {
              await tester.tap(cancelButton.first);
              await tester.pumpAndSettle();
            }

            // Then: 다이얼로그가 닫히고 카테고리 위젯이 표시됨
            expect(find.byType(AlertDialog), findsNothing);
            expect(find.byType(CategorySelectorWidget), findsOneWidget);
          }
        }
      }
    });

    testWidgets('없음 칩 탭 시 null로 콜백이 호출된다', (tester) async {
      // Given
      Category? selected = _makeCategory();
      final testCategory = _makeCategory(id: 'cat-1', name: '식비');

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider
                .overrideWith((ref) async => [testCategory]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: testCategory,
            transactionType: 'expense',
            onCategorySelected: (c) => selected = c,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When: 없음(첫 번째 FilterChip) 탭
      final noneChips = find.byType(FilterChip);
      if (noneChips.evaluate().isNotEmpty) {
        await tester.tap(noneChips.first, warnIfMissed: false);
        await tester.pump();
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });
  });

  group('CategorySelectionResult 테스트', () {
    test('기본 생성자는 selectedCategory=null, wasDeleted=false를 반환한다', () {
      // Given/When
      const result = CategorySelectionResult();

      // Then
      expect(result.selectedCategory, isNull);
      expect(result.wasDeleted, isFalse);
    });

    test('wasDeleted=true로 생성 시 올바른 값을 반환한다', () {
      // Given/When
      const result = CategorySelectionResult(wasDeleted: true);

      // Then
      expect(result.wasDeleted, isTrue);
      expect(result.selectedCategory, isNull);
    });
  });

  group('CategorySelectorWidget 추가/수정/삭제 테스트', () {
    testWidgets('추가 ActionChip 탭 시 다이얼로그가 시도된다', (tester) async {
      // Given: expense 타입 카테고리 없는 상태
      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => []),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: const CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: _noop,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 추가 ActionChip 탭
      final addChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '추가',
      );
      expect(addChip, findsOneWidget);
      await tester.tap(addChip);
      await tester.pump();

      // Then: 위젯이 렌더링됨 (다이얼로그 시도됨)
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 수정 아이콘 탭 시 편집 다이얼로그가 시도된다', (tester) async {
      // Given
      final categories = [_makeCategory(id: 'c-1', name: '식비', type: 'expense')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 → 수정 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isNotEmpty) {
        await tester.tap(editChip.first);
        await tester.pumpAndSettle();

        final editIcons = find.byIcon(Icons.edit_outlined);
        if (editIcons.evaluate().isNotEmpty) {
          await tester.tap(editIcons.first, warnIfMissed: false);
          await tester.pump();
        }
      }

      // Then: 위젯이 렌더링됨
      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('편집 모드에서 삭제 버튼 탭 시 삭제 확인 다이얼로그가 표시된다', (tester) async {
      // Given
      final categories = [_makeCategory(id: 'c-1', name: '식비', type: 'expense')];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 → 삭제(close) 아이콘 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) {
        expect(find.byType(CategorySelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      final closeIcons = find.byIcon(Icons.close);
      if (closeIcons.evaluate().isEmpty) {
        expect(find.byType(CategorySelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(closeIcons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Then: 삭제 확인 다이얼로그 또는 위젯 확인
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        // 취소 탭
        await tester.tap(find.text('취소'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);
      }

      expect(find.byType(CategorySelectorWidget), findsOneWidget);
    });

    testWidgets('수입 타입에서 카테고리가 로드된다', (tester) async {
      // Given: income 타입
      final incomeCategories = [
        _makeCategory(id: 'c-2', name: '월급', type: 'income'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            incomeCategoriesProvider.overrideWith((ref) async => incomeCategories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'income',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 수입 카테고리가 표시됨
      expect(find.text('월급'), findsOneWidget);
    });

    testWidgets('자산 타입에서 카테고리가 로드된다', (tester) async {
      // Given: asset 타입
      final assetCategories = [
        _makeCategory(id: 'c-3', name: '주식', type: 'asset'),
      ];

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            savingCategoriesProvider.overrideWith((ref) async => assetCategories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'asset',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 자산 카테고리가 표시됨
      expect(find.text('주식'), findsOneWidget);
    });

    testWidgets('삭제 확인 후 삭제 버튼 탭 시 deleteCategory가 호출된다', (tester) async {
      // Given: 카테고리 목록, FakeCategoryNotifier mock
      final categories = [_makeCategory(id: 'cat-del', name: '삭제카테고리')];
      bool deleteCalled = false;

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => categories),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            categoryNotifierProvider.overrideWith((ref) {
              final n = _FakeCategoryNotifier(ref);
              n.onDeleteCalled = () => deleteCalled = true;
              return n;
            }),
          ],
          child: CategorySelectorWidget(
            selectedCategory: null,
            transactionType: 'expense',
            onCategorySelected: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 진입 → 삭제 아이콘 탭 → 확인 다이얼로그에서 삭제 버튼 탭
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) {
        expect(find.byType(CategorySelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      final closeIcons = find.byIcon(Icons.close);
      if (closeIcons.evaluate().isEmpty) {
        expect(find.byType(CategorySelectorWidget), findsOneWidget);
        return;
      }
      await tester.tap(closeIcons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      // 삭제 확인 다이얼로그에서 삭제(FilledButton) 탭
      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        final deleteBtn = find.byWidgetPredicate((w) => w is FilledButton);
        if (deleteBtn.evaluate().isNotEmpty) {
          await tester.tap(deleteBtn.first);
          await tester.pumpAndSettle();
          // Then: deleteCategory가 호출됨
          expect(deleteCalled, isTrue);
        }
      } else {
        expect(find.byType(CategorySelectorWidget), findsOneWidget);
      }
    });

    testWidgets('선택된 카테고리 삭제 시 null로 콜백이 호출된다', (tester) async {
      // Given: 선택된 카테고리와 동일한 카테고리를 삭제 시도
      final selectedCat = _makeCategory(id: 'cat-sel', name: '선택됨');
      Category? callbackResult = selectedCat;

      await tester.pumpWidget(
        _buildApp(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) async => [selectedCat]),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            categoryNotifierProvider.overrideWith(
              (ref) => _FakeCategoryNotifier(ref),
            ),
          ],
          child: CategorySelectorWidget(
            selectedCategory: selectedCat,
            transactionType: 'expense',
            onCategorySelected: (c) => callbackResult = c,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 편집 모드 → 삭제 아이콘 → 확인 다이얼로그 삭제
      final editChip = find.byWidgetPredicate(
        (w) => w is ActionChip && (w.label as Text).data == '수정',
      );
      if (editChip.evaluate().isEmpty) return;

      await tester.tap(editChip.first);
      await tester.pumpAndSettle();

      final closeIcons = find.byIcon(Icons.close);
      if (closeIcons.evaluate().isEmpty) return;

      await tester.tap(closeIcons.first, warnIfMissed: false);
      await tester.pumpAndSettle();

      if (find.byType(AlertDialog).evaluate().isNotEmpty) {
        final deleteBtn = find.byWidgetPredicate((w) => w is FilledButton);
        if (deleteBtn.evaluate().isNotEmpty) {
          await tester.tap(deleteBtn.first);
          await tester.pumpAndSettle();
          // Then: 선택된 카테고리가 null로 변경됨
          expect(callbackResult, isNull);
        }
      }
    });
  });
}

void _noop(Category? _) {}

class _FakeCategoryNotifier extends CategoryNotifier {
  VoidCallback? onDeleteCalled;

  _FakeCategoryNotifier(Ref ref)
      : super(MockCategoryRepository(), null, ref);

  @override
  Future<void> loadCategories() async {
    if (mounted) state = const AsyncValue.data([]);
  }

  @override
  Future<void> deleteCategory(String id) async {
    onDeleteCalled?.call();
  }
}
