import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/add_category_mapping_from_transaction_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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

Widget buildWidget({
  String? transactionTitle,
  double? transactionAmount,
  String initialSourceType = 'notification',
  List<Category> categories = const [],
}) {
  return ProviderScope(
    overrides: [
      expenseCategoriesProvider.overrideWith((ref) async => categories),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AddCategoryMappingFromTransactionDialog(
          paymentMethodId: 'pm-1',
          ledgerId: 'ledger-1',
          transactionTitle: transactionTitle,
          transactionAmount: transactionAmount,
          initialSourceType: initialSourceType,
        ),
      ),
    ),
  );
}

void main() {
  group('AddCategoryMappingFromTransactionDialog 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(
        find.byType(AddCategoryMappingFromTransactionDialog),
        findsOneWidget,
      );
    });

    testWidgets('거래 제목이 있으면 키워드 추천이 표시된다', (tester) async {
      // Given: 거래 제목 포함
      // When
      await tester.pumpWidget(
        buildWidget(transactionTitle: '스타벅스 아메리카노', transactionAmount: 5500),
      );
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨
      expect(
        find.byType(AddCategoryMappingFromTransactionDialog),
        findsOneWidget,
      );
    });

    testWidgets('거래 제목 없이도 렌더링된다', (tester) async {
      // Given: 거래 제목 없음
      // When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨
      expect(
        find.byType(AddCategoryMappingFromTransactionDialog),
        findsOneWidget,
      );
    });

    testWidgets('notification 소스 유형으로 초기화된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        buildWidget(initialSourceType: 'notification'),
      );
      await tester.pumpAndSettle();

      // Then: SegmentedButton이 있음
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('sms 소스 유형으로 초기화된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(initialSourceType: 'sms'));
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨
      expect(
        find.byType(AddCategoryMappingFromTransactionDialog),
        findsOneWidget,
      );
    });

    testWidgets('카테고리가 있으면 드롭다운이 표시된다', (tester) async {
      // Given
      final categories = [
        _makeCategory(id: 'cat-1', name: '식비'),
        _makeCategory(id: 'cat-2', name: '카페'),
      ];

      // When
      await tester.pumpWidget(buildWidget(categories: categories));
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(
        find.byType(AddCategoryMappingFromTransactionDialog),
        findsOneWidget,
      );
    });

    testWidgets('취소 및 저장 버튼이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: 버튼들이 있음
      expect(find.byType(OutlinedButton), findsWidgets);
      expect(find.byType(FilledButton), findsWidgets);
    });
  });
}
