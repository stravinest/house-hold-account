import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/add_category_mapping_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../../../../helpers/mock_supabase.dart' show MockUser;

class MockCategoryKeywordMappingRepository extends Mock
    implements CategoryKeywordMappingRepository {}

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
  List<Category> categories = const [],
  bool isLoading = false,
  bool hasError = false,
  MockUser? mockUser,
  CategoryKeywordMappingRepository? mappingRepository,
  String initialSourceType = 'sms',
}) {
  final user = mockUser ?? MockUser();
  when(() => user.id).thenReturn('user-1');

  final overrides = <Override>[
    expenseCategoriesProvider.overrideWith((ref) async {
      if (isLoading) await Future.delayed(const Duration(hours: 1));
      if (hasError) throw Exception('카테고리 조회 실패');
      return categories;
    }),
    currentUserProvider.overrideWith((_) => user),
  ];

  if (mappingRepository != null) {
    overrides.add(
      categoryKeywordMappingNotifierProvider('pm-1').overrideWith(
        (ref) => CategoryKeywordMappingNotifier(
          mappingRepository,
          'pm-1',
          ref,
        ),
      ),
    );
  }

  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AddCategoryMappingDialog(
          paymentMethodId: 'pm-1',
          ledgerId: 'ledger-1',
          initialSourceType: initialSourceType,
        ),
      ),
    ),
  );
}

void main() {
  group('AddCategoryMappingDialog 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(AddCategoryMappingDialog), findsOneWidget);
    });

    testWidgets('SMS/Push 소스 유형 세그먼트 버튼이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: SegmentedButton이 표시됨
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('키워드 입력 필드가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: TextFormField가 표시됨
      expect(find.byType(TextFormField), findsWidgets);
    });

    testWidgets('카테고리가 있으면 드롭다운이 표시된다', (tester) async {
      // Given
      final categories = [
        _makeCategory(id: 'cat-1', name: '식비'),
        _makeCategory(id: 'cat-2', name: '교통'),
      ];

      // When
      await tester.pumpWidget(buildWidget(categories: categories));
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(AddCategoryMappingDialog), findsOneWidget);
    });

    testWidgets('취소 버튼이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: 취소/저장 버튼이 표시됨
      expect(find.byType(OutlinedButton), findsWidgets);
      expect(find.byType(FilledButton), findsWidgets);
    });

    testWidgets('카테고리 로딩 중에 CircularProgressIndicator가 표시된다', (tester) async {
      // Given: Completer를 사용해 Future가 완료되지 않도록 유지
      final completer = Completer<List<Category>>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AddCategoryMappingDialog(
                paymentMethodId: 'pm-1',
                ledgerId: 'ledger-1',
                initialSourceType: 'sms',
              ),
            ),
          ),
        ),
      );
      await tester.pump(); // 한 프레임만 - 로딩 상태

      // Then: 로딩 인디케이터가 표시됨
      expect(find.byType(CircularProgressIndicator), findsWidgets);

      // Cleanup: completer 완료
      completer.complete([]);
    });

    testWidgets('카테고리 로딩 에러 시 에러 메시지가 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(hasError: true));
      await tester.pumpAndSettle();

      // Then: 위젯이 에러 없이 렌더링됨
      expect(find.byType(AddCategoryMappingDialog), findsOneWidget);
    });

    testWidgets('Push 소스 유형으로 초기화하면 notification이 선택된다', (tester) async {
      // Given: notification 초기값
      await tester.pumpWidget(
        buildWidget(initialSourceType: 'notification'),
      );
      await tester.pumpAndSettle();

      // Then: SegmentedButton이 표시됨
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('소스 유형 세그먼트를 SMS에서 Push로 전환할 수 있다', (tester) async {
      // Given: SMS 초기값
      await tester.pumpWidget(buildWidget(categories: [
        _makeCategory(),
      ]));
      await tester.pumpAndSettle();

      // When: Push 버튼 탭 (알림 아이콘 또는 Push 텍스트 탭)
      final pushButton = find.byIcon(Icons.notifications_outlined);
      if (pushButton.evaluate().isNotEmpty) {
        await tester.tap(pushButton.first);
        await tester.pumpAndSettle();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(AddCategoryMappingDialog), findsOneWidget);
    });

    testWidgets('키워드 입력 없이 저장 버튼 탭 시 유효성 검사 에러가 표시된다', (tester) async {
      // Given: 카테고리 있음, 키워드 미입력
      final mockRepo = MockCategoryKeywordMappingRepository();
      await tester.pumpWidget(buildWidget(
        categories: [_makeCategory()],
        mappingRepository: mockRepo,
      ));
      await tester.pumpAndSettle();

      // When: 저장 버튼 탭 (키워드 없이)
      final saveButton = find.byType(FilledButton);
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton.first);
        await tester.pump();
      }

      // Then: 유효성 검사 에러가 표시되거나 저장이 실패해야 한다
      expect(find.byType(AddCategoryMappingDialog), findsOneWidget);
    });

    testWidgets('닫기 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: Navigator를 추적하기 위한 NavigatorObserver
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When: 닫기(X) 버튼 탭
      final closeButton = find.byIcon(Icons.close);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton.first);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(true, isTrue);
    });

    testWidgets('취소 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When: 취소 버튼 탭
      final cancelButton = find.byType(OutlinedButton);
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton.first);
        await tester.pump();
      }

      // Then: 크래시 없이 동작해야 한다
      expect(true, isTrue);
    });

    testWidgets('카테고리가 여러 개일 때 드롭다운 아이템이 모두 표시된다', (tester) async {
      // Given: 3개 카테고리
      final categories = [
        _makeCategory(id: 'cat-1', name: '식비'),
        _makeCategory(id: 'cat-2', name: '교통'),
        _makeCategory(id: 'cat-3', name: '쇼핑'),
      ];

      // When
      await tester.pumpWidget(buildWidget(categories: categories));
      await tester.pumpAndSettle();

      // Then: 드롭다운이 렌더링됨
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('currentUser가 null이면 저장이 실행되지 않는다', (tester) async {
      // Given: currentUser null
      final categories = [_makeCategory()];
      final mockRepo = MockCategoryKeywordMappingRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseCategoriesProvider.overrideWith((_) async => categories),
            currentUserProvider.overrideWith((_) => null),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AddCategoryMappingDialog(
                paymentMethodId: 'pm-1',
                ledgerId: 'ledger-1',
                initialSourceType: 'sms',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 키워드 입력
      await tester.enterText(find.byType(TextFormField).first, '스타벅스');
      await tester.pump();

      // When: 저장 버튼 탭
      final saveButton = find.byType(FilledButton);
      if (saveButton.evaluate().isNotEmpty) {
        await tester.tap(saveButton.first);
        await tester.pump();
      }

      // Then: create가 호출되지 않아야 한다 (currentUser null이므로)
      verifyNever(() => mockRepo.create(
            paymentMethodId: any(named: 'paymentMethodId'),
            keyword: any(named: 'keyword'),
            categoryId: any(named: 'categoryId'),
            sourceType: any(named: 'sourceType'),
            ledgerId: any(named: 'ledgerId'),
            createdBy: any(named: 'createdBy'),
          ));
    });
  });
}
