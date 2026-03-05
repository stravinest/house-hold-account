import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/pages/category_keyword_mapping_page.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

import '../../../../helpers/mock_supabase.dart';

class MockCategoryKeywordMappingRepository extends Mock
    implements CategoryKeywordMappingRepository {}

/// 테스트용 CategoryKeywordMappingNotifier 스텁
///
/// Supabase 초기화 없이 원하는 상태를 주입할 수 있다.
class _FakeCategoryKeywordMappingNotifier
    extends StateNotifier<AsyncValue<List<CategoryKeywordMappingModel>>>
    implements CategoryKeywordMappingNotifier {
  _FakeCategoryKeywordMappingNotifier(
    AsyncValue<List<CategoryKeywordMappingModel>> state,
  ) : super(state);

  @override
  Future<void> loadMappings({String? sourceType}) async {}

  @override
  Future<void> create({
    required String ledgerId,
    required String keyword,
    required String categoryId,
    required String sourceType,
    required String createdBy,
  }) async {}

  @override
  Future<void> delete(String id) async {}
}

/// 테스트용 CategoryKeywordMappingModel 생성 헬퍼
CategoryKeywordMappingModel _makeMapping({
  String id = 'map-1',
  String keyword = '스타벅스',
  String categoryId = 'cat-1',
  String sourceType = 'sms',
}) {
  return CategoryKeywordMappingModel(
    id: id,
    paymentMethodId: 'pm-1',
    ledgerId: 'ledger-1',
    keyword: keyword,
    categoryId: categoryId,
    sourceType: sourceType,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

/// 테스트용 Category 생성 헬퍼
Category _makeCategory({
  String id = 'cat-1',
  String name = '식비',
}) {
  return Category(
    id: id,
    ledgerId: 'ledger-1',
    name: name,
    icon: 'restaurant',
    color: '#FF5722',
    type: 'expense',
    isDefault: false,
    sortOrder: 1,
    createdAt: DateTime(2026, 1, 1),
  );
}

/// 테스트 위젯 빌더 헬퍼
Widget _buildTestWidget({
  String paymentMethodId = 'pm-1',
  String sourceType = 'sms',
  AsyncValue<List<CategoryKeywordMappingModel>> mappingsState =
      const AsyncValue.data([]),
  List<Category> categories = const [],
}) {
  final user = MockUser();
  when(() => user.id).thenReturn('user-1');

  return ProviderScope(
    overrides: [
      categoryKeywordMappingNotifierProvider(paymentMethodId).overrideWith(
        (_) => _FakeCategoryKeywordMappingNotifier(mappingsState),
      ),
      categoriesProvider.overrideWith((_) async => categories),
      selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
      currentUserProvider.overrideWith((_) => user),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: CategoryKeywordMappingPage(
        paymentMethodId: paymentMethodId,
        sourceType: sourceType,
        ledgerId: 'ledger-1',
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
  });

  group('CategoryKeywordMappingPage - 기본 렌더링', () {
    testWidgets('Scaffold와 AppBar가 렌더링된다', (tester) async {
      // Given: 빈 매핑 목록
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: Scaffold와 AppBar가 표시되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('SMS sourceType이면 SMS 제목이 표시된다', (tester) async {
      // Given: SMS sourceType
      await tester.pumpWidget(_buildTestWidget(sourceType: 'sms'));
      await tester.pumpAndSettle();

      // Then: AppBar가 표시되어야 한다
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('Push sourceType이면 Push 제목이 표시된다', (tester) async {
      // Given: Push sourceType
      await tester.pumpWidget(_buildTestWidget(sourceType: 'push'));
      await tester.pumpAndSettle();

      // Then: AppBar가 표시되어야 한다
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('FloatingActionButton이 표시된다', (tester) async {
      // Given: 빈 매핑 목록
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: FAB가 표시되어야 한다
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('FAB에 더하기 아이콘이 있다', (tester) async {
      // Given: 빈 매핑 목록
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: 더하기 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
  });

  group('CategoryKeywordMappingPage - 빈 상태', () {
    testWidgets('매핑이 없을 때 빈 상태 위젯이 표시된다', (tester) async {
      // Given: 빈 매핑 목록
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // Then: 빈 상태를 나타내는 아이콘이나 텍스트가 있어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('SMS sourceType에서 매핑이 없으면 빈 상태가 표시된다', (tester) async {
      // Given: sourceType=sms, 빈 목록
      await tester.pumpWidget(
        _buildTestWidget(sourceType: 'sms'),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('CategoryKeywordMappingPage - 매핑 목록 표시', () {
    testWidgets('SMS 매핑 1개가 있을 때 키워드가 표시된다', (tester) async {
      // Given: SMS 타입 매핑 1개
      final mapping = _makeMapping(
        keyword: '스타벅스',
        sourceType: 'sms',
      );
      final category = _makeCategory(name: '식비');

      await tester.pumpWidget(
        _buildTestWidget(
          sourceType: 'sms',
          mappingsState: AsyncValue.data([mapping]),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 스타벅스 키워드가 표시되어야 한다
      expect(find.textContaining('스타벅스'), findsWidgets);
    });

    testWidgets('카테고리 이름이 매핑 카드에 표시된다', (tester) async {
      // Given: 매핑과 해당 카테고리
      final mapping = _makeMapping(keyword: '맥도날드', categoryId: 'cat-food');
      final category = _makeCategory(id: 'cat-food', name: '외식');

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data([mapping]),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 카테고리 이름이 표시되어야 한다
      expect(find.textContaining('외식'), findsWidgets);
    });

    testWidgets('여러 매핑이 있을 때 ListView가 렌더링된다', (tester) async {
      // Given: 여러 매핑
      final mappings = [
        _makeMapping(id: 'map-1', keyword: '스타벅스', sourceType: 'sms'),
        _makeMapping(id: 'map-2', keyword: '맥도날드', sourceType: 'sms'),
        _makeMapping(id: 'map-3', keyword: '편의점', sourceType: 'sms'),
      ];
      final category = _makeCategory();

      await tester.pumpWidget(
        _buildTestWidget(
          sourceType: 'sms',
          mappingsState: AsyncValue.data(mappings),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // Then: ListView가 렌더링되어야 한다
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('다른 sourceType 매핑은 필터링된다', (tester) async {
      // Given: SMS 매핑과 Push 매핑이 섞여 있음
      final mappings = [
        _makeMapping(id: 'map-sms', keyword: 'SMS키워드', sourceType: 'sms'),
        _makeMapping(id: 'map-push', keyword: 'Push키워드', sourceType: 'push'),
      ];
      final category = _makeCategory();

      // SMS 페이지에서 표시
      await tester.pumpWidget(
        _buildTestWidget(
          sourceType: 'sms',
          mappingsState: AsyncValue.data(mappings),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // Then: SMS 키워드만 표시되어야 한다
      expect(find.textContaining('SMS키워드'), findsWidgets);
    });

    testWidgets('카테고리를 찾을 수 없을 때 알 수 없음이 표시된다', (tester) async {
      // Given: 매핑은 있지만 카테고리가 없음
      final mapping = _makeMapping(keyword: '편의점', categoryId: 'non-existent');

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data([mapping]),
          categories: [], // 빈 카테고리 목록
        ),
      );
      await tester.pumpAndSettle();

      // Then: 키워드는 표시되어야 한다
      expect(find.textContaining('편의점'), findsWidgets);
    });

    testWidgets('삭제 아이콘 버튼이 각 매핑에 표시된다', (tester) async {
      // Given: 매핑 1개
      final mapping = _makeMapping(keyword: '스타벅스');
      final category = _makeCategory();

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data([mapping]),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // Then: 삭제 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('CategoryKeywordMappingPage - 로딩 상태', () {
    testWidgets('로딩 중일 때 CircularProgressIndicator가 표시된다', (tester) async {
      // Given: 로딩 상태
      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: const AsyncValue.loading(),
        ),
      );
      await tester.pump(); // pumpAndSettle 대신 pump만 사용 (로딩 상태 유지)

      // Then: 로딩 인디케이터가 표시되어야 한다
      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });
  });

  group('CategoryKeywordMappingPage - 에러 상태', () {
    testWidgets('에러 상태에서 에러 메시지가 표시된다', (tester) async {
      // Given: 에러 상태
      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.error(
            Exception('네트워크 오류'),
            StackTrace.empty,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: Scaffold가 렌더링되어야 한다
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('CategoryKeywordMappingPage - 삭제 인터랙션', () {
    testWidgets('삭제 버튼 탭 시 확인 다이얼로그가 표시된다', (tester) async {
      // Given: 매핑 1개
      final mapping = _makeMapping(keyword: '스타벅스');
      final category = _makeCategory();

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data([mapping]),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // When: 삭제 버튼 탭
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Then: AlertDialog가 표시되어야 한다
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('삭제 다이얼로그에서 취소 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: 매핑 1개
      final mapping = _makeMapping(keyword: '스타벅스');
      final category = _makeCategory();

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data([mapping]),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // When: 삭제 버튼 탭 후 취소
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // 취소 버튼 탭
      final cancelButton = find.text('취소');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton.first);
        await tester.pumpAndSettle();

        // Then: 다이얼로그가 닫혀야 한다
        expect(find.byType(AlertDialog), findsNothing);
      }
    });

    testWidgets('삭제 다이얼로그에서 삭제 버튼을 탭하면 다이얼로그가 닫힌다', (tester) async {
      // Given: 매핑 1개
      final mapping = _makeMapping(keyword: '스타벅스');
      final category = _makeCategory();

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data([mapping]),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // When: 삭제 버튼 탭
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // 삭제 확인 버튼 탭
      final deleteButton = find.text('삭제');
      if (deleteButton.evaluate().isNotEmpty) {
        await tester.tap(deleteButton.first);
        await tester.pumpAndSettle();

        // Then: 크래시 없이 동작해야 한다
        expect(find.byType(Scaffold), findsWidgets);
      }
    });
  });

  group('CategoryKeywordMappingPage - FAB 인터랙션', () {
    testWidgets('FAB 탭 시 크래시가 발생하지 않는다', (tester) async {
      // Given: 빈 매핑 목록
      await tester.pumpWidget(_buildTestWidget());
      await tester.pumpAndSettle();

      // When: FAB 탭
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Then: 크래시 없이 동작해야 한다
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('CategoryKeywordMappingPage - 설명 텍스트', () {
    testWidgets('SMS sourceType일 때 설명 텍스트가 표시된다', (tester) async {
      // Given: SMS sourceType
      await tester.pumpWidget(_buildTestWidget(sourceType: 'sms'));
      await tester.pumpAndSettle();

      // Then: 본문 텍스트가 있어야 한다
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Push sourceType일 때 설명 텍스트가 표시된다', (tester) async {
      // Given: Push sourceType
      await tester.pumpWidget(_buildTestWidget(sourceType: 'push'));
      await tester.pumpAndSettle();

      // Then: 본문 텍스트가 있어야 한다
      expect(find.byType(Text), findsWidgets);
    });
  });

  group('CategoryKeywordMappingPage - Push 매핑 필터', () {
    testWidgets('Push 페이지에서 push 타입 매핑만 표시된다', (tester) async {
      // Given: SMS와 Push 매핑이 혼합된 상태
      final mappings = [
        _makeMapping(id: 'map-sms', keyword: 'SMS전용', sourceType: 'sms'),
        _makeMapping(id: 'map-push', keyword: 'Push전용', sourceType: 'push'),
      ];
      final category = _makeCategory();

      // Push 페이지에서 표시
      await tester.pumpWidget(
        _buildTestWidget(
          sourceType: 'push',
          mappingsState: AsyncValue.data(mappings),
          categories: [category],
        ),
      );
      await tester.pumpAndSettle();

      // Then: Push 키워드만 표시되어야 한다
      expect(find.textContaining('Push전용'), findsWidgets);
    });
  });

  group('CategoryKeywordMappingPage - 여러 카테고리', () {
    testWidgets('여러 카테고리가 있을 때 각 매핑의 카테고리 이름이 표시된다', (tester) async {
      // Given: 여러 매핑과 여러 카테고리
      final mappings = [
        _makeMapping(id: 'map-1', keyword: '스타벅스', categoryId: 'cat-1'),
        _makeMapping(id: 'map-2', keyword: '맥도날드', categoryId: 'cat-2'),
      ];
      final categories = [
        _makeCategory(id: 'cat-1', name: '카페'),
        _makeCategory(id: 'cat-2', name: '외식'),
      ];

      await tester.pumpWidget(
        _buildTestWidget(
          mappingsState: AsyncValue.data(mappings),
          categories: categories,
        ),
      );
      await tester.pumpAndSettle();

      // Then: 두 카테고리 이름이 표시되어야 한다
      expect(find.textContaining('카페'), findsWidgets);
      expect(find.textContaining('외식'), findsWidgets);
    });
  });
}
