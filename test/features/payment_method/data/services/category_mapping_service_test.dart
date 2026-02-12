import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/category_mapping_service.dart';

import '../../../../helpers/test_helpers.dart';

/// Fake Supabase Client - 테이블별 Fake 쿼리 빌더 반환
class FakeSupabaseClient {
  final Map<String, FakeQueryBuilder> _builders = {};

  /// 테이블별 쿼리 빌더를 설정한다
  void setupTable(String table, FakeQueryBuilder builder) {
    _builders[table] = builder;
  }

  FakeQueryBuilder from(String table) {
    return _builders[table] ?? FakeQueryBuilder();
  }
}

/// Fake Query Builder - Supabase 쿼리 체이닝을 시뮬레이션한다
/// await 시 listResult를 반환하고, maybeSingle() 호출 시 singleResult를 반환한다
class FakeQueryBuilder implements Future<List<Map<String, dynamic>>> {
  List<Map<String, dynamic>> listResult = [];
  Map<String, dynamic>? singleResult;

  FakeQueryBuilder select([String columns = '*']) => this;
  FakeQueryBuilder eq(String column, dynamic value) => this;
  FakeQueryBuilder ilike(String column, String pattern) => this;
  FakeQueryBuilder limit(int count) => this;
  FakeQueryBuilder order(String column, {bool ascending = false}) => this;
  FakeQueryBuilder not(String column, String operator, dynamic value) => this;

  Future<dynamic> maybeSingle() async => singleResult;
  Future<Map<String, dynamic>> single() async => singleResult ?? {};

  // Future<List<Map<String, dynamic>>> 구현
  @override
  Stream<List<Map<String, dynamic>>> asStream() =>
      Stream.value(listResult);

  @override
  Future<List<Map<String, dynamic>>> catchError(
    Function onError, {
    bool Function(Object error)? test,
  }) =>
      Future.value(listResult).catchError(onError, test: test);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) =>
      Future.value(listResult).then(onValue, onError: onError);

  @override
  Future<List<Map<String, dynamic>>> timeout(
    Duration timeLimit, {
    FutureOr<List<Map<String, dynamic>>> Function()? onTimeout,
  }) =>
      Future.value(listResult).timeout(timeLimit, onTimeout: onTimeout);

  @override
  Future<List<Map<String, dynamic>>> whenComplete(
    FutureOr<void> Function() action,
  ) =>
      Future.value(listResult).whenComplete(action);
}

void main() {
  group('CategoryMappingService Tests', () {
    late CategoryMappingService service;
    late FakeSupabaseClient fakeClient;

    setUp(() {
      fakeClient = FakeSupabaseClient();
      service = CategoryMappingService(client: fakeClient);
    });

    group('MerchantCategoryRule', () {
      test('JSON에서 MerchantCategoryRule을 생성할 수 있다', () {
        // Given
        final json = {
          'id': 'rule-1',
          'ledger_id': 'ledger-1',
          'merchant_pattern': '스타벅스',
          'category_id': 'cat-1',
          'is_regex': false,
          'priority': 10,
          'created_at': '2026-02-12T10:00:00Z',
        };

        // When
        final rule = MerchantCategoryRule.fromJson(json);

        // Then
        expect(rule.id, equals('rule-1'));
        expect(rule.ledgerId, equals('ledger-1'));
        expect(rule.merchantPattern, equals('스타벅스'));
        expect(rule.categoryId, equals('cat-1'));
        expect(rule.isRegex, isFalse);
        expect(rule.priority, equals(10));
      });

      test('문자열 패턴 매칭을 정확하게 수행한다', () {
        // Given
        final rule = MerchantCategoryRule(
          id: 'rule-1',
          ledgerId: 'ledger-1',
          merchantPattern: '스타벅스',
          categoryId: 'cat-1',
          isRegex: false,
          priority: 10,
          createdAt: DateTime.now(),
        );

        // When & Then
        expect(rule.matches('스타벅스 강남점'), isTrue);
        expect(rule.matches('STARBUCKS'), isFalse); // 한글 패턴은 영문과 매칭되지 않음
        expect(rule.matches('이디야커피'), isFalse);
      });

      test('정규식 패턴 매칭을 정확하게 수행한다', () {
        // Given
        final rule = MerchantCategoryRule(
          id: 'rule-1',
          ledgerId: 'ledger-1',
          merchantPattern: r'스타벅스|이디야',
          categoryId: 'cat-1',
          isRegex: true,
          priority: 10,
          createdAt: DateTime.now(),
        );

        // When & Then
        expect(rule.matches('스타벅스 강남점'), isTrue);
        expect(rule.matches('이디야커피'), isTrue);
        expect(rule.matches('투썸플레이스'), isFalse);
      });

      test('빈 상호명은 매칭되지 않는다', () {
        // Given
        final rule = MerchantCategoryRule(
          id: 'rule-1',
          ledgerId: 'ledger-1',
          merchantPattern: '스타벅스',
          categoryId: 'cat-1',
          createdAt: DateTime.now(),
        );

        // When & Then
        expect(rule.matches(''), isFalse);
      });
    });

    group('SystemCategoryRules', () {
      test('음식점 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.foodPatterns, isNotEmpty);
        expect(SystemCategoryRules.foodPatterns, contains('스타벅스'));
        expect(SystemCategoryRules.foodPatterns, contains('맥도날드'));
      });

      test('마트 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.martPatterns, isNotEmpty);
        expect(SystemCategoryRules.martPatterns, contains('cu'));
        expect(SystemCategoryRules.martPatterns, contains('이마트'));
      });

      test('교통 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.transportPatterns, isNotEmpty);
        expect(SystemCategoryRules.transportPatterns, contains('택시'));
        expect(SystemCategoryRules.transportPatterns, contains('주유소'));
      });

      test('쇼핑 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.shoppingPatterns, isNotEmpty);
        expect(SystemCategoryRules.shoppingPatterns, contains('쿠팡'));
        expect(SystemCategoryRules.shoppingPatterns, contains('무신사'));
      });

      test('의료/건강 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.healthPatterns, isNotEmpty);
        expect(SystemCategoryRules.healthPatterns, contains('병원'));
        expect(SystemCategoryRules.healthPatterns, contains('헬스'));
      });

      test('문화/여가 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.culturePatterns, isNotEmpty);
        expect(SystemCategoryRules.culturePatterns, contains('cgv'));
        expect(SystemCategoryRules.culturePatterns, contains('넷플릭스'));
      });

      test('교육 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.educationPatterns, isNotEmpty);
        expect(SystemCategoryRules.educationPatterns, contains('학원'));
      });

      test('통신/유틸리티 패턴이 정의되어 있다', () {
        expect(SystemCategoryRules.utilityPatterns, isNotEmpty);
        expect(SystemCategoryRules.utilityPatterns, contains('skt'));
        expect(SystemCategoryRules.utilityPatterns, contains('전기요금'));
      });

      test('모든 규칙이 카테고리명에 매핑되어 있다', () {
        expect(SystemCategoryRules.allRules, isNotEmpty);
        expect(SystemCategoryRules.allRules.keys, contains('식비'));
        expect(SystemCategoryRules.allRules.keys, contains('교통'));
        expect(SystemCategoryRules.allRules.keys, contains('문화'));
      });
    });

    group('findCategoryId - System Rules', () {
      test('스타벅스는 식비 카테고리로 매핑된다', () async {
        // Given: 사용자 규칙 없음, 카테고리 테이블에 식비 존재
        final rulesBuilder = FakeQueryBuilder()..listResult = [];
        final categoriesBuilder = FakeQueryBuilder()
          ..singleResult = {'id': 'food-category-id'};

        fakeClient.setupTable('merchant_category_rules', rulesBuilder);
        fakeClient.setupTable('categories', categoriesBuilder);

        // When
        final categoryId = await service.findCategoryId(
          '스타벅스 강남점',
          'ledger-1',
          useCache: false,
        );

        // Then
        expect(categoryId, equals('food-category-id'));
      });

      test('CU 편의점은 마트 카테고리로 매핑된다', () async {
        // Given
        final rulesBuilder = FakeQueryBuilder()..listResult = [];
        final categoriesBuilder = FakeQueryBuilder()
          ..singleResult = {'id': 'mart-category-id'};

        fakeClient.setupTable('merchant_category_rules', rulesBuilder);
        fakeClient.setupTable('categories', categoriesBuilder);

        // When
        final categoryId = await service.findCategoryId(
          'CU편의점',
          'ledger-1',
          useCache: false,
        );

        // Then
        expect(categoryId, equals('mart-category-id'));
      });

      test('택시는 교통 카테고리로 매핑된다', () async {
        // Given
        final rulesBuilder = FakeQueryBuilder()..listResult = [];
        final categoriesBuilder = FakeQueryBuilder()
          ..singleResult = {'id': 'transport-category-id'};

        fakeClient.setupTable('merchant_category_rules', rulesBuilder);
        fakeClient.setupTable('categories', categoriesBuilder);

        // When
        final categoryId = await service.findCategoryId(
          '카카오택시',
          'ledger-1',
          useCache: false,
        );

        // Then
        expect(categoryId, equals('transport-category-id'));
      });

      test('매칭되지 않는 상호명은 null을 반환한다', () async {
        // Given: 사용자 규칙 없음, 시스템 규칙에도 매칭 안됨
        final rulesBuilder = FakeQueryBuilder()..listResult = [];
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);

        // When
        final categoryId = await service.findCategoryId(
          '알수없는상점123',
          'ledger-1',
          useCache: false,
        );

        // Then
        expect(categoryId, isNull);
      });

      test('빈 상호명은 null을 반환한다', () async {
        // When
        final categoryId = await service.findCategoryId('', 'ledger-1');

        // Then
        expect(categoryId, isNull);
      });
    });

    group('clearCache', () {
      test('특정 ledgerId의 캐시를 삭제할 수 있다', () {
        // Given
        service.clearCache('ledger-1');

        // When & Then
        expect(() => service.clearCache('ledger-1'), returnsNormally);
      });

      test('전체 캐시를 삭제할 수 있다', () {
        // Given & When
        service.clearCache();

        // Then
        expect(() => service.clearCache(), returnsNormally);
      });
    });
  });
}
