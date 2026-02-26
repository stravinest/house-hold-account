import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/category_mapping_section.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SupabaseClient mock (Supabase.instance 초기화 없이 사용하기 위함)
class _MockSupabaseClient extends Mock implements SupabaseClient {}

// 테스트용 매핑 데이터 생성 헬퍼
CategoryKeywordMappingModel _buildMapping({
  required String id,
  required String sourceType,
  required String keyword,
}) {
  final now = DateTime(2026, 2, 25);
  return CategoryKeywordMappingModel(
    id: id,
    paymentMethodId: 'pm-1',
    ledgerId: 'ledger-1',
    keyword: keyword,
    categoryId: 'cat-1',
    sourceType: sourceType,
    createdBy: 'user-1',
    createdAt: now,
    updatedAt: now,
  );
}

/// 테스트용 가짜 Repository
///
/// mock SupabaseClient를 주입하여 Supabase.instance 초기화 없이 생성 가능합니다.
/// getByPaymentMethod를 override하여 네트워크 호출 없이 데이터를 반환합니다.
class _FakeRepository extends CategoryKeywordMappingRepository {
  final List<CategoryKeywordMappingModel> _data;

  _FakeRepository(this._data) : super(client: _MockSupabaseClient());

  @override
  Future<List<CategoryKeywordMappingModel>> getByPaymentMethod(
    String paymentMethodId, {
    String? sourceType,
  }) async =>
      _data;
}

/// 테스트용 가짜 Notifier
///
/// CategoryKeywordMappingNotifier를 상속하여 타입 호환성을 유지하면서
/// FakeRepository를 통해 실제 Supabase 호출을 차단합니다.
class _FakeMappingNotifier extends CategoryKeywordMappingNotifier {
  _FakeMappingNotifier(
    List<CategoryKeywordMappingModel> data,
    Ref ref,
  ) : super(_FakeRepository(data), 'pm-1', ref);
}

/// CategoryMappingSection 위젯을 감싸는 테스트 앱 빌더
///
/// CategoryMappingSection은 go_router의 context.push를 사용하므로
/// 관리 버튼 탭 동작은 테스트하지 않고 렌더링과 텍스트 표시만 검증합니다.
Widget _buildTestApp({
  required List<CategoryKeywordMappingModel> mappings,
}) {
  return ProviderScope(
    overrides: [
      categoryKeywordMappingNotifierProvider('pm-1').overrideWith(
        (ref) => _FakeMappingNotifier(mappings, ref),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko')],
      home: const Scaffold(
        body: SingleChildScrollView(
          child: CategoryMappingSection(
            paymentMethodId: 'pm-1',
            ledgerId: 'ledger-1',
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('CategoryMappingSection 위젯 테스트', () {
    testWidgets(
      '섹션 타이틀 "카테고리 자동연결" 텍스트가 화면에 표시되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp(mappings: []));
        await tester.pumpAndSettle();

        expect(find.text('카테고리 자동연결'), findsOneWidget);
      },
    );

    testWidgets(
      '매핑 데이터가 없을 때 SMS 배지와 Push 배지가 모두 표시되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp(mappings: []));
        await tester.pumpAndSettle();

        expect(find.text('SMS'), findsOneWidget);
        expect(find.text('Push'), findsOneWidget);
      },
    );

    testWidgets(
      '매핑 데이터가 없을 때 SMS와 Push 각각 "0개 연결됨" 텍스트가 표시되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp(mappings: []));
        await tester.pumpAndSettle();

        // 0개 연결됨 텍스트가 두 개(SMS행, Push행) 표시되어야 한다
        expect(find.text('0개 연결됨'), findsNWidgets(2));
      },
    );

    testWidgets(
      'SMS 매핑이 2개 있을 때 "2개 연결됨" 텍스트가 SMS 행에 표시되어야 한다',
      (WidgetTester tester) async {
        final smsMappings = [
          _buildMapping(id: 'id-1', sourceType: 'sms', keyword: '스타벅스'),
          _buildMapping(id: 'id-2', sourceType: 'sms', keyword: 'GS25'),
        ];

        await tester.pumpWidget(_buildTestApp(mappings: smsMappings));
        await tester.pumpAndSettle();

        // SMS 행에 2개 연결됨이 표시되어야 한다
        expect(find.text('2개 연결됨'), findsOneWidget);

        // Push 행은 0개 연결됨이 표시되어야 한다
        expect(find.text('0개 연결됨'), findsOneWidget);
      },
    );

    testWidgets(
      'Push 매핑이 1개 있을 때 "1개 연결됨" 텍스트가 Push 행에 표시되어야 한다',
      (WidgetTester tester) async {
        final pushMappings = [
          _buildMapping(id: 'id-3', sourceType: 'push', keyword: 'KB Pay'),
        ];

        await tester.pumpWidget(_buildTestApp(mappings: pushMappings));
        await tester.pumpAndSettle();

        // SMS 행은 0개 연결됨
        expect(find.text('0개 연결됨'), findsOneWidget);

        // Push 행에 1개 연결됨이 표시되어야 한다
        expect(find.text('1개 연결됨'), findsOneWidget);
      },
    );

    testWidgets(
      'SMS 행과 Push 행 각각에 "관리" 버튼이 표시되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(_buildTestApp(mappings: []));
        await tester.pumpAndSettle();

        // 관리 텍스트가 SMS/Push 두 행에 각각 표시되어야 한다
        expect(find.text('관리'), findsNWidgets(2));
      },
    );
  });
}
