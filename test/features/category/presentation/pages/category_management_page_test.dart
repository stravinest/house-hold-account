import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/presentation/pages/category_management_page.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

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
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CategoryManagementPage(),
          ),
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
        CategoryModel(
          id: '1',
          ledgerId: 'test-ledger-id',
          name: '식비',
          icon: 'restaurant',
          color: '#FF5722',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
        CategoryModel(
          id: '2',
          ledgerId: 'test-ledger-id',
          name: '교통비',
          icon: 'directions_car',
          color: '#2196F3',
          type: 'expense',
          isDefault: false,
          sortOrder: 1,
          createdAt: DateTime.now(),
        ),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CategoryManagementPage(),
          ),
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
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CategoryManagementPage(),
          ),
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
        CategoryModel(
          id: '1',
          ledgerId: 'test-ledger-id',
          name: '식비',
          icon: 'restaurant',
          color: '#FF5722',
          type: 'expense',
          isDefault: false,
          sortOrder: 0,
          createdAt: DateTime.now(),
        ),
      ];

      final repository = MockCategoryRepository();
      when(() => repository.getCategories(any()))
          .thenAnswer((_) async => categories);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
            categoryRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CategoryManagementPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // When & Then: 수정 및 삭제 아이콘 버튼이 표시되어야 함
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byIcon(Icons.delete), findsOneWidget);
    });
  });
}
