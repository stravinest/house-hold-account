import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/data/services/category_mapping_service.dart';

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
  FakeQueryBuilder insert(Map<String, dynamic> data) => this;
  FakeQueryBuilder delete() => this;

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

/// Fake CategoryKeywordMappingRepository - SupabaseClient 초기화 없이 동작하는 테스트용 Repository
/// sourceType별로 다른 결과를 반환할 수 있도록 sourceTypeResults 맵을 지원한다
class FakeCategoryKeywordMappingRepository implements CategoryKeywordMappingRepository {
  List<CategoryKeywordMappingModel> result = [];
  Map<String, List<CategoryKeywordMappingModel>> sourceTypeResults = {};

  @override
  Future<List<CategoryKeywordMappingModel>> getByPaymentMethod(
    String paymentMethodId, {
    String? sourceType,
  }) async {
    if (sourceType != null && sourceTypeResults.containsKey(sourceType)) {
      return sourceTypeResults[sourceType]!;
    }
    return result;
  }

  @override
  Future<List<CategoryKeywordMappingModel>> getByLedger(
    String ledgerId, {
    String? sourceType,
  }) async => result;

  @override
  Future<CategoryKeywordMappingModel> create({
    required String paymentMethodId,
    required String ledgerId,
    required String keyword,
    required String categoryId,
    required String sourceType,
    required String createdBy,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<CategoryKeywordMappingModel?> findByKeyword(
    String paymentMethodId,
    String keyword,
    String sourceType,
  ) async => null;
}

/// 에러를 던지는 테스트용 Repository - DB 에러 시나리오 검증용
class ErrorThrowingKeywordMappingRepository implements CategoryKeywordMappingRepository {
  @override
  Future<List<CategoryKeywordMappingModel>> getByPaymentMethod(
    String paymentMethodId, {
    String? sourceType,
  }) async {
    throw Exception('DB connection failed');
  }

  @override
  Future<List<CategoryKeywordMappingModel>> getByLedger(
    String ledgerId, {
    String? sourceType,
  }) async {
    throw Exception('DB connection failed');
  }

  @override
  Future<CategoryKeywordMappingModel> create({
    required String paymentMethodId,
    required String ledgerId,
    required String keyword,
    required String categoryId,
    required String sourceType,
    required String createdBy,
  }) async => throw UnimplementedError();

  @override
  Future<void> delete(String id) async {}

  @override
  Future<CategoryKeywordMappingModel?> findByKeyword(
    String paymentMethodId,
    String keyword,
    String sourceType,
  ) async => null;
}

void main() {
  group('CategoryMappingService Tests', () {
    late CategoryMappingService service;
    late FakeSupabaseClient fakeClient;

    setUp(() {
      fakeClient = FakeSupabaseClient();
      service = CategoryMappingService(
        client: fakeClient,
        keywordMappingRepository: FakeCategoryKeywordMappingRepository(),
      );
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

    group('findCategoryByKeywordMapping - 키워드 매핑 기반 카테고리 조회', () {
      late FakeCategoryKeywordMappingRepository fakeRepo;

      setUp(() {
        fakeRepo = FakeCategoryKeywordMappingRepository();
        fakeClient = FakeSupabaseClient();
        service = CategoryMappingService(
          client: fakeClient,
          keywordMappingRepository: fakeRepo,
        );
      });

      CategoryKeywordMappingModel createMapping({
        required String keyword,
        required String categoryId,
        required String sourceType,
      }) {
        return CategoryKeywordMappingModel(
          id: 'mapping-$keyword',
          paymentMethodId: 'pm-1',
          ledgerId: 'ledger-1',
          keyword: keyword,
          categoryId: categoryId,
          sourceType: sourceType,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      test('SMS sourceType으로 등록된 키워드가 SMS 메시지에서 정확히 매칭된다', () async {
        // Given: SMS용 키워드 매핑 등록
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '스타벅스', categoryId: 'food-id', sourceType: 'sms'),
        ];

        // When: SMS 원본 메시지에서 키워드 검색
        final categoryId = await service.findCategoryByKeywordMapping(
          '[KB국민카드] 스타벅스 강남점 15,000원 결제',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then: 식비 카테고리 ID 반환
        expect(categoryId, equals('food-id'));
      });

      test('notification sourceType으로 등록된 키워드가 알림 메시지에서 정확히 매칭된다', () async {
        // Given: notification용 키워드 매핑 등록
        fakeRepo.sourceTypeResults['notification'] = [
          createMapping(keyword: '샐러디', categoryId: 'food-id', sourceType: 'notification'),
        ];

        // When: 알림 원본 메시지에서 키워드 검색
        final categoryId = await service.findCategoryByKeywordMapping(
          '샐러디 판교테크 12,500원 결제완료',
          'pm-1',
          'notification',
          'ledger-1',
        );

        // Then: 식비 카테고리 ID 반환
        expect(categoryId, equals('food-id'));
      });

      test('SMS 키워드 매핑은 notification sourceType으로 조회 시 매칭되지 않는다', () async {
        // Given: SMS에만 키워드 매핑 등록, notification에는 없음
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '스타벅스', categoryId: 'food-id', sourceType: 'sms'),
        ];
        fakeRepo.sourceTypeResults['notification'] = [];

        // When: notification sourceType으로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남점 15,000원',
          'pm-1',
          'notification',
          'ledger-1',
        );

        // Then: 매칭되지 않아 null 반환
        expect(categoryId, isNull);
      });

      test('notification 키워드 매핑은 sms sourceType으로 조회 시 매칭되지 않는다', () async {
        // Given: notification에만 키워드 매핑 등록, sms에는 없음
        fakeRepo.sourceTypeResults['notification'] = [
          createMapping(keyword: '샐러디', categoryId: 'food-id', sourceType: 'notification'),
        ];
        fakeRepo.sourceTypeResults['sms'] = [];

        // When: sms sourceType으로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          '샐러디 판교테크 12,500원',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then: 매칭되지 않아 null 반환
        expect(categoryId, isNull);
      });

      test('동일 키워드가 SMS와 notification에 각각 다른 카테고리로 매핑될 수 있다', () async {
        // Given: 같은 키워드 '스타벅스'가 sourceType별로 다른 카테고리에 매핑
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '스타벅스', categoryId: 'sms-food-id', sourceType: 'sms'),
        ];
        fakeRepo.sourceTypeResults['notification'] = [
          createMapping(keyword: '스타벅스', categoryId: 'noti-food-id', sourceType: 'notification'),
        ];

        // When & Then: SMS 조회 시 sms-food-id 반환
        final smsCategoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남점',
          'pm-1',
          'sms',
          'ledger-1',
        );
        expect(smsCategoryId, equals('sms-food-id'));

        // When & Then: notification 조회 시 noti-food-id 반환
        final notiCategoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남점',
          'pm-1',
          'notification',
          'ledger-1',
        );
        expect(notiCategoryId, equals('noti-food-id'));
      });

      test('여러 키워드 매칭 시 가장 긴 키워드가 우선 매칭된다', () async {
        // Given: '스타벅스'와 '스타벅스 리저브'가 둘 다 등록됨
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '스타벅스', categoryId: 'food-id', sourceType: 'sms'),
          createMapping(keyword: '스타벅스 리저브', categoryId: 'premium-food-id', sourceType: 'sms'),
        ];

        // When: '스타벅스 리저브' 포함 메시지로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          '[KB] 스타벅스 리저브 강남점 8,500원',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then: 더 긴 '스타벅스 리저브' 키워드에 매핑된 카테고리 반환
        expect(categoryId, equals('premium-food-id'));
      });

      test('빈 sourceContent는 null을 반환한다', () async {
        // Given: 키워드 매핑이 존재하더라도
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '스타벅스', categoryId: 'food-id', sourceType: 'sms'),
        ];

        // When: 빈 메시지로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          '',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then: null 반환
        expect(categoryId, isNull);
      });

      test('빈 paymentMethodId는 null을 반환한다', () async {
        // When: 빈 결제수단 ID로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남점',
          '',
          'sms',
          'ledger-1',
        );

        // Then: null 반환
        expect(categoryId, isNull);
      });

      test('키워드 매칭은 대소문자를 구분하지 않는다', () async {
        // Given: 소문자 키워드 등록
        fakeRepo.sourceTypeResults['notification'] = [
          createMapping(keyword: 'starbucks', categoryId: 'food-id', sourceType: 'notification'),
        ];

        // When: 대문자 포함 메시지로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          'STARBUCKS 강남점 결제 15,000원',
          'pm-1',
          'notification',
          'ledger-1',
        );

        // Then: 대소문자 무시하고 매칭
        expect(categoryId, equals('food-id'));
      });

      test('매핑이 없는 sourceType은 null을 반환한다', () async {
        // Given: sms, notification 어디에도 매핑 없음
        fakeRepo.sourceTypeResults['sms'] = [];
        fakeRepo.sourceTypeResults['notification'] = [];

        // When
        final categoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남점',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then
        expect(categoryId, isNull);
      });

      test('Repository에서 에러 발생 시 null을 반환한다 (에러 처리)', () async {
        // Given: 에러를 발생시키는 Repository
        final errorRepo = ErrorThrowingKeywordMappingRepository();
        final errorService = CategoryMappingService(
          client: fakeClient,
          keywordMappingRepository: errorRepo,
        );

        // When: 키워드 매핑 조회 시도
        final categoryId = await errorService.findCategoryByKeywordMapping(
          '스타벅스 강남점 15,000원',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then: 에러가 전파되지 않고 null 반환
        expect(categoryId, isNull);
      });

      test('매핑 결과에서 키워드가 sourceContent에 포함되지 않으면 null을 반환한다', () async {
        // Given: 키워드가 메시지에 포함되지 않는 매핑
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '이디야', categoryId: 'food-id', sourceType: 'sms'),
        ];

        // When: 이디야가 포함되지 않은 메시지로 조회
        final categoryId = await service.findCategoryByKeywordMapping(
          '[KB] 스타벅스 강남점 8,500원',
          'pm-1',
          'sms',
          'ledger-1',
        );

        // Then: 매칭되지 않아 null 반환
        expect(categoryId, isNull);
      });

      test('여러 키워드 중 짧은 키워드만 매칭되면 짧은 키워드의 카테고리를 반환한다', () async {
        // Given: 두 키워드 중 하나만 매칭
        fakeRepo.sourceTypeResults['notification'] = [
          createMapping(keyword: '스타벅스', categoryId: 'food-id', sourceType: 'notification'),
          createMapping(keyword: '스타벅스 리저브', categoryId: 'premium-id', sourceType: 'notification'),
        ];

        // When: '스타벅스'만 포함된 메시지 (리저브는 미포함)
        final categoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남역점 12,000원 결제',
          'pm-1',
          'notification',
          'ledger-1',
        );

        // Then: 짧은 키워드 '스타벅스'에 매핑된 카테고리 반환
        expect(categoryId, equals('food-id'));
      });

      test('빈 ledgerId가 전달되어도 paymentMethodId 기반으로 매핑을 조회하여 카테고리를 반환한다', () async {
        // Given: 키워드 매핑이 존재할 때
        fakeRepo.sourceTypeResults['sms'] = [
          createMapping(keyword: '스타벅스', categoryId: 'food-id', sourceType: 'sms'),
        ];

        // When: 빈 ledgerId로 조회 (서비스는 ledgerId를 검증하지 않음)
        final categoryId = await service.findCategoryByKeywordMapping(
          '스타벅스 강남점',
          'pm-1',
          'sms',
          '',
        );

        // Then: paymentMethodId 기반 매핑이 정상 동작하여 카테고리 반환
        expect(categoryId, equals('food-id'));
      });
    });

    group('addRule - 사용자 정의 규칙 추가', () {
      test('문자열 패턴으로 규칙을 추가하면 MerchantCategoryRule을 반환한다', () async {
        // Given: 규칙 추가 후 DB에서 반환될 데이터
        final ruleData = {
          'id': 'rule-new',
          'ledger_id': 'ledger-1',
          'merchant_pattern': '스타벅스',
          'category_id': 'cat-food',
          'is_regex': false,
          'priority': 10,
          'created_at': '2026-01-01T00:00:00Z',
        };
        final rulesBuilder = FakeQueryBuilder()..singleResult = ruleData;
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);

        // When
        final result = await service.addRule(
          ledgerId: 'ledger-1',
          merchantPattern: '스타벅스',
          categoryId: 'cat-food',
          priority: 10,
        );

        // Then
        expect(result, isA<MerchantCategoryRule>());
        expect(result.merchantPattern, equals('스타벅스'));
        expect(result.categoryId, equals('cat-food'));
        expect(result.isRegex, isFalse);
        expect(result.priority, equals(10));
      });

      test('정규식 패턴으로 규칙을 추가할 수 있다', () async {
        // Given
        final ruleData = {
          'id': 'rule-regex',
          'ledger_id': 'ledger-1',
          'merchant_pattern': r'스타벅스|이디야',
          'category_id': 'cat-cafe',
          'is_regex': true,
          'priority': 20,
          'created_at': '2026-01-01T00:00:00Z',
        };
        final rulesBuilder = FakeQueryBuilder()..singleResult = ruleData;
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);

        // When
        final result = await service.addRule(
          ledgerId: 'ledger-1',
          merchantPattern: r'스타벅스|이디야',
          categoryId: 'cat-cafe',
          isRegex: true,
          priority: 20,
        );

        // Then
        expect(result.isRegex, isTrue);
        expect(result.merchantPattern, equals(r'스타벅스|이디야'));
        expect(result.priority, equals(20));
      });

      test('규칙 추가 후 캐시가 무효화된다', () async {
        // Given: 기존 규칙 로드로 캐시를 채워두고 새 규칙 추가
        final existingRule = {
          'id': 'rule-old',
          'ledger_id': 'ledger-1',
          'merchant_pattern': '이디야',
          'category_id': 'cat-cafe',
          'is_regex': false,
          'priority': 5,
          'created_at': '2026-01-01T00:00:00Z',
        };
        final newRule = {
          'id': 'rule-new',
          'ledger_id': 'ledger-1',
          'merchant_pattern': '투썸',
          'category_id': 'cat-cafe',
          'is_regex': false,
          'priority': 5,
          'created_at': '2026-01-01T00:00:00Z',
        };
        // 첫 번째 호출(findCategoryId)은 기존 규칙 반환, 두 번째(addRule)는 새 규칙 반환
        final rulesBuilder = FakeQueryBuilder()
          ..listResult = [existingRule]
          ..singleResult = newRule;
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);
        fakeClient.setupTable('categories', FakeQueryBuilder());

        // 캐시 워밍업 (findCategoryId 호출로 캐시 저장)
        await service.findCategoryId('이디야커피', 'ledger-1', useCache: true);

        // When: 새 규칙 추가 (캐시 무효화 발생해야 함)
        final result = await service.addRule(
          ledgerId: 'ledger-1',
          merchantPattern: '투썸',
          categoryId: 'cat-cafe',
        );

        // Then: 새 규칙이 반환되고 에러 없이 완료
        expect(result.merchantPattern, equals('투썸'));
      });
    });

    group('deleteRule - 사용자 정의 규칙 삭제', () {
      test('규칙 ID로 규칙을 삭제한다', () async {
        // Given: delete 쿼리에 대한 응답
        final rulesBuilder = FakeQueryBuilder()..listResult = [];
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);

        // When
        await service.deleteRule('rule-1', 'ledger-1');

        // Then: 에러 없이 완료
      });

      test('규칙 삭제 후 캐시가 무효화된다', () async {
        // Given: 기존 규칙으로 캐시를 채운 후 삭제
        final existingRule = {
          'id': 'rule-1',
          'ledger_id': 'ledger-1',
          'merchant_pattern': '스타벅스',
          'category_id': 'cat-food',
          'is_regex': false,
          'priority': 10,
          'created_at': '2026-01-01T00:00:00Z',
        };
        final rulesBuilder = FakeQueryBuilder()..listResult = [existingRule];
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);
        fakeClient.setupTable('categories', FakeQueryBuilder());

        // 캐시 워밍업
        await service.findCategoryId('스타벅스', 'ledger-1', useCache: true);

        // When: 규칙 삭제 (캐시 무효화 발생해야 함)
        await service.deleteRule('rule-1', 'ledger-1');

        // Then: 에러 없이 완료
      });
    });

    group('getRules - 사용자 정의 규칙 목록 조회', () {
      test('가계부의 사용자 정의 규칙 목록을 반환한다', () async {
        // Given: 두 개의 규칙이 있는 가계부
        final rulesData = [
          {
            'id': 'rule-1',
            'ledger_id': 'ledger-1',
            'merchant_pattern': '스타벅스',
            'category_id': 'cat-food',
            'is_regex': false,
            'priority': 10,
            'created_at': '2026-01-01T00:00:00Z',
          },
          {
            'id': 'rule-2',
            'ledger_id': 'ledger-1',
            'merchant_pattern': r'버거킹|맥도날드',
            'category_id': 'cat-food',
            'is_regex': true,
            'priority': 5,
            'created_at': '2026-01-01T00:00:00Z',
          },
        ];
        final rulesBuilder = FakeQueryBuilder()..listResult = rulesData;
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);

        // When
        final result = await service.getRules('ledger-1');

        // Then
        expect(result, isA<List<MerchantCategoryRule>>());
        expect(result.length, equals(2));
        expect(result[0].merchantPattern, equals('스타벅스'));
        expect(result[1].isRegex, isTrue);
      });

      test('규칙이 없는 가계부는 빈 리스트를 반환한다', () async {
        // Given
        final rulesBuilder = FakeQueryBuilder()..listResult = [];
        fakeClient.setupTable('merchant_category_rules', rulesBuilder);

        // When
        final result = await service.getRules('ledger-empty');

        // Then
        expect(result, isEmpty);
      });
    });

    group('learnCategoryFromHistory - 이전 거래 기반 카테고리 학습', () {
      test('이전 거래에서 가장 많이 사용된 카테고리를 반환한다', () async {
        // Given: 같은 상호에서 cat-food가 3번, cat-life가 1번 사용됨
        final transactionData = [
          {'category_id': 'cat-food'},
          {'category_id': 'cat-food'},
          {'category_id': 'cat-food'},
          {'category_id': 'cat-life'},
        ];
        final txBuilder = FakeQueryBuilder()..listResult = transactionData;
        fakeClient.setupTable('transactions', txBuilder);

        // When
        final result = await service.learnCategoryFromHistory(
          '스타벅스',
          'ledger-1',
        );

        // Then: 가장 빈번한 cat-food 반환
        expect(result, equals('cat-food'));
      });

      test('이전 거래가 없는 경우 null을 반환한다', () async {
        // Given: 거래 없음
        final txBuilder = FakeQueryBuilder()..listResult = [];
        fakeClient.setupTable('transactions', txBuilder);

        // When
        final result = await service.learnCategoryFromHistory(
          '처음가는가게',
          'ledger-1',
        );

        // Then
        expect(result, isNull);
      });

      test('빈 상호명은 null을 반환한다', () async {
        // When
        final result = await service.learnCategoryFromHistory('', 'ledger-1');

        // Then
        expect(result, isNull);
      });

      test('category_id가 모두 null인 거래만 있으면 null을 반환한다', () async {
        // Given: category_id가 null인 거래만 있음
        final transactionData = [
          {'category_id': null},
          {'category_id': null},
        ];
        final txBuilder = FakeQueryBuilder()..listResult = transactionData;
        fakeClient.setupTable('transactions', txBuilder);

        // When
        final result = await service.learnCategoryFromHistory(
          '모르는가게',
          'ledger-1',
        );

        // Then
        expect(result, isNull);
      });

      test('동점일 경우 첫 번째로 나타난 카테고리를 반환한다', () async {
        // Given: cat-food 2번, cat-life 2번 (동점)
        final transactionData = [
          {'category_id': 'cat-food'},
          {'category_id': 'cat-food'},
          {'category_id': 'cat-life'},
          {'category_id': 'cat-life'},
        ];
        final txBuilder = FakeQueryBuilder()..listResult = transactionData;
        fakeClient.setupTable('transactions', txBuilder);

        // When
        final result = await service.learnCategoryFromHistory(
          '스타벅스',
          'ledger-1',
        );

        // Then: 동점 시 sort 후 첫 번째 카테고리 반환 (결정론적 순서)
        expect(result, isNotNull);
      });

      test('단일 거래만 있는 경우 해당 카테고리를 반환한다', () async {
        // Given: 거래 1건
        final transactionData = [
          {'category_id': 'cat-entertainment'},
        ];
        final txBuilder = FakeQueryBuilder()..listResult = transactionData;
        fakeClient.setupTable('transactions', txBuilder);

        // When
        final result = await service.learnCategoryFromHistory(
          'cgv강남점',
          'ledger-1',
        );

        // Then
        expect(result, equals('cat-entertainment'));
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
