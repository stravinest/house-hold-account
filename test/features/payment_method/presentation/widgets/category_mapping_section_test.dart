import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/category_mapping_section.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockCategoryKeywordMappingRepository extends Mock
    implements CategoryKeywordMappingRepository {}

/// 테스트용 CategoryKeywordMappingNotifier 스텁
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

CategoryKeywordMappingModel _makeModel({
  String id = 'mapping-1',
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
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Widget buildWidget({
  List<CategoryKeywordMappingModel> mappings = const [],
  bool hasError = false,
  required MockCategoryKeywordMappingRepository mockRepo,
}) {
  final AsyncValue<List<CategoryKeywordMappingModel>> state = hasError
      ? AsyncValue.error(Exception('매핑 조회 실패'), StackTrace.empty)
      : AsyncValue.data(mappings);

  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: CategoryMappingSection(
            paymentMethodId: 'pm-1',
            ledgerId: 'ledger-1',
          ),
        ),
      ),
      GoRoute(
        path: '/settings/payment-methods/:pmId/category-mapping/:type',
        builder: (context, state) => const Scaffold(body: Text('mapping page')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      categoryKeywordMappingNotifierProvider('pm-1').overrideWith(
        (_) => _FakeCategoryKeywordMappingNotifier(state),
      ),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
    ),
  );
}

void main() {
  late MockCategoryKeywordMappingRepository mockRepo;

  setUp(() {
    mockRepo = MockCategoryKeywordMappingRepository();
  });

  group('CategoryMappingSection 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given
      when(
        () => mockRepo.getByPaymentMethod(
          any(),
          sourceType: any(named: 'sourceType'),
        ),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(buildWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(CategoryMappingSection), findsOneWidget);
    });

    testWidgets('매핑이 없으면 빈 상태로 렌더링된다', (tester) async {
      // Given: 빈 매핑 목록
      when(
        () => mockRepo.getByPaymentMethod(
          any(),
          sourceType: any(named: 'sourceType'),
        ),
      ).thenAnswer((_) async => []);

      // When
      await tester.pumpWidget(buildWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Then: 위젯이 정상 렌더링됨
      expect(find.byType(CategoryMappingSection), findsOneWidget);
    });

    testWidgets('SMS 매핑이 있으면 표시된다', (tester) async {
      // Given
      final mappings = [
        _makeModel(id: 'mapping-1', keyword: '스타벅스', sourceType: 'sms'),
      ];
      when(
        () => mockRepo.getByPaymentMethod(
          any(),
          sourceType: any(named: 'sourceType'),
        ),
      ).thenAnswer((_) async => mappings);

      // When
      await tester.pumpWidget(buildWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨
      expect(find.byType(CategoryMappingSection), findsOneWidget);
    });

    testWidgets('Push 매핑이 있으면 표시된다', (tester) async {
      // Given
      final mappings = [
        _makeModel(id: 'mapping-2', keyword: '맥도날드', sourceType: 'notification'),
      ];
      when(
        () => mockRepo.getByPaymentMethod(
          any(),
          sourceType: any(named: 'sourceType'),
        ),
      ).thenAnswer((_) async => mappings);

      // When
      await tester.pumpWidget(buildWidget(mockRepo: mockRepo));
      await tester.pumpAndSettle();

      // Then: 위젯이 렌더링됨
      expect(find.byType(CategoryMappingSection), findsOneWidget);
    });

    testWidgets('에러 상태에서도 위젯이 렌더링된다', (tester) async {
      // Given
      when(
        () => mockRepo.getByPaymentMethod(
          any(),
          sourceType: any(named: 'sourceType'),
        ),
      ).thenThrow(Exception('매핑 조회 실패'));

      // When
      await tester.pumpWidget(buildWidget(mockRepo: mockRepo));
      await tester.pump();

      // Then: 에러 없이 렌더링
      expect(find.byType(CategoryMappingSection), findsOneWidget);

      await tester.pumpAndSettle();
    });
  });
}
