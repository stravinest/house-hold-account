import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/domain/entities/category.dart';
import 'package:shared_household_account/features/category/presentation/providers/category_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';
import 'package:shared_household_account/features/payment_method/presentation/widgets/add_category_mapping_dialog.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// SupabaseClient mock (Supabase.instance 초기화 없이 사용하기 위함)
class _MockSupabaseClient extends Mock implements SupabaseClient {}

// 테스트용 더미 카테고리 목록
List<Category> _buildDummyCategories() {
  final now = DateTime(2026, 2, 25);
  return [
    Category(
      id: 'cat-1',
      ledgerId: 'ledger-1',
      name: '식비',
      icon: 'restaurant',
      color: '#FF5252',
      type: 'expense',
      isDefault: true,
      sortOrder: 0,
      createdAt: now,
    ),
    Category(
      id: 'cat-2',
      ledgerId: 'ledger-1',
      name: '교통',
      icon: 'directions_bus',
      color: '#448AFF',
      type: 'expense',
      isDefault: true,
      sortOrder: 1,
      createdAt: now,
    ),
  ];
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

/// 테스트용 앱 래퍼 위젯
///
/// AddCategoryMappingDialog는 Dialog 위젯이므로
/// 버튼 클릭으로 showDialog를 호출하는 방식으로 테스트합니다.
Widget _buildTestApp({
  required List<Override> overrides,
  required String initialSourceType,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('ko')],
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => AddCategoryMappingDialog(
                    paymentMethodId: 'pm-1',
                    ledgerId: 'ledger-1',
                    initialSourceType: initialSourceType,
                  ),
                );
              },
              child: const Text('다이얼로그 열기'),
            );
          },
        ),
      ),
    ),
  );
}

/// 공통 override 목록 생성 헬퍼
List<Override> _buildOverrides({
  List<Category>? categories,
  List<CategoryKeywordMappingModel>? mappings,
}) {
  final dummyCategories = categories ?? _buildDummyCategories();
  final dummyMappings = mappings ?? [];

  return [
    expenseCategoriesProvider.overrideWith(
      (_) async => dummyCategories,
    ),
    categoryKeywordMappingNotifierProvider('pm-1').overrideWith(
      (ref) => _FakeMappingNotifier(dummyMappings, ref),
    ),
  ];
}

void main() {
  group('AddCategoryMappingDialog 위젯 테스트', () {
    testWidgets(
      '다이얼로그가 열리면 수집 유형 선택기, 키워드 입력 필드, 취소 버튼, 저장 버튼이 렌더링되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _buildOverrides(),
            initialSourceType: 'sms',
          ),
        );

        await tester.tap(find.text('다이얼로그 열기'));
        await tester.pumpAndSettle();

        // 수집 유형 SegmentedButton이 존재해야 한다
        expect(find.byType(SegmentedButton<String>), findsOneWidget);

        // SMS / Push 알림 세그먼트 레이블이 보여야 한다
        expect(find.text('SMS'), findsOneWidget);
        expect(find.text('Push 알림'), findsOneWidget);

        // 키워드 입력 필드가 존재해야 한다
        expect(find.byType(TextFormField), findsOneWidget);

        // 취소 버튼이 존재해야 한다
        expect(find.text('취소'), findsOneWidget);

        // 저장 버튼이 존재해야 한다
        expect(find.text('저장'), findsOneWidget);
      },
    );

    testWidgets(
      'initialSourceType이 sms이면 SegmentedButton의 초기 선택값이 sms로 설정되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _buildOverrides(),
            initialSourceType: 'sms',
          ),
        );

        await tester.tap(find.text('다이얼로그 열기'));
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );
        expect(segmentedButton.selected, {'sms'});
      },
    );

    testWidgets(
      'initialSourceType이 push이면 SegmentedButton의 초기 선택값이 push로 설정되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _buildOverrides(),
            initialSourceType: 'push',
          ),
        );

        await tester.tap(find.text('다이얼로그 열기'));
        await tester.pumpAndSettle();

        final segmentedButton = tester.widget<SegmentedButton<String>>(
          find.byType(SegmentedButton<String>),
        );
        expect(segmentedButton.selected, {'push'});
      },
    );

    testWidgets(
      '키워드를 입력하지 않고 저장 버튼을 누르면 키워드 필수 입력 validator 에러 메시지가 표시되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _buildOverrides(),
            initialSourceType: 'sms',
          ),
        );

        await tester.tap(find.text('다이얼로그 열기'));
        await tester.pumpAndSettle();

        // 키워드 입력 없이 저장 버튼 탭
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        // 키워드 필수 입력 에러 메시지가 표시되어야 한다
        expect(find.text('키워드를 입력해주세요.'), findsOneWidget);
      },
    );

    testWidgets(
      '카테고리를 선택하지 않고 키워드만 입력한 후 저장 버튼을 누르면 카테고리 필수 선택 validator 에러 메시지가 표시되어야 한다',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _buildTestApp(
            overrides: _buildOverrides(),
            initialSourceType: 'sms',
          ),
        );

        await tester.tap(find.text('다이얼로그 열기'));
        await tester.pumpAndSettle();

        // 키워드 입력
        await tester.enterText(find.byType(TextFormField), '스타벅스');
        await tester.pumpAndSettle();

        // 카테고리 선택 없이 저장 버튼 탭
        await tester.tap(find.text('저장'));
        await tester.pumpAndSettle();

        // 카테고리 필수 선택 에러 메시지가 표시되어야 한다
        expect(find.text('카테고리를 선택해주세요.'), findsOneWidget);
      },
    );
  });
}
