import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late CategoryKeywordMappingRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = CategoryKeywordMappingRepository(client: mockClient);
  });

  Map<String, dynamic> _makeMappingData({
    String id = 'mapping-1',
    String keyword = '스타벅스',
    String categoryId = 'cat-food',
    String sourceType = 'sms',
    String paymentMethodId = 'pm-1',
    String ledgerId = 'ledger-1',
  }) {
    return {
      'id': id,
      'payment_method_id': paymentMethodId,
      'ledger_id': ledgerId,
      'keyword': keyword,
      'category_id': categoryId,
      'source_type': sourceType,
      'created_by': 'user-123',
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
  }

  group('CategoryKeywordMappingRepository - getByPaymentMethod', () {
    test('결제수단별 키워드 매핑 조회 시 리스트를 반환한다', () async {
      final mockData = [_makeMappingData()];

      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByPaymentMethod('pm-1');
      expect(result, isA<List<CategoryKeywordMappingModel>>());
      expect(result.length, 1);
      expect(result[0].keyword, '스타벅스');
    });

    test('sourceType 필터를 적용하여 조회한다', () async {
      final mockData = [_makeMappingData(sourceType: 'sms')];

      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByPaymentMethod(
        'pm-1',
        sourceType: 'sms',
      );
      expect(result.length, 1);
      expect(result[0].sourceType, 'sms');
    });

    test('매핑이 없는 경우 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getByPaymentMethod('pm-no-mapping');
      expect(result, isEmpty);
    });

    test('notification sourceType으로 필터링하여 조회한다', () async {
      final mockData = [_makeMappingData(sourceType: 'notification')];

      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByPaymentMethod(
        'pm-1',
        sourceType: 'notification',
      );
      expect(result.length, 1);
      expect(result[0].sourceType, 'notification');
    });
  });

  group('CategoryKeywordMappingRepository - getByLedger', () {
    test('가계부별 키워드 매핑 전체 조회 시 리스트를 반환한다', () async {
      final mockData = [
        _makeMappingData(),
        _makeMappingData(id: 'mapping-2', keyword: 'GS25', categoryId: 'cat-mart'),
      ];

      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByLedger('ledger-1');
      expect(result, isA<List<CategoryKeywordMappingModel>>());
      expect(result.length, 2);
    });

    test('sourceType 필터를 적용하여 가계부별 조회한다', () async {
      final mockData = [_makeMappingData(sourceType: 'notification')];

      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByLedger(
        'ledger-1',
        sourceType: 'notification',
      );
      expect(result.length, 1);
    });

    test('매핑이 없는 가계부 조회 시 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getByLedger('ledger-empty');
      expect(result, isEmpty);
    });
  });

  group('CategoryKeywordMappingRepository - create', () {
    test('키워드 매핑 생성(upsert) 시 생성된 매핑을 반환한다', () async {
      final mockResponse = _makeMappingData(id: 'mapping-new');

      when(() => mockClient.from('category_keyword_mappings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.create(
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-food',
        sourceType: 'sms',
        createdBy: 'user-123',
      );
      expect(result, isA<CategoryKeywordMappingModel>());
      expect(result.keyword, '스타벅스');
    });

    test('notification sourceType으로 키워드 매핑을 생성한다', () async {
      final mockResponse = _makeMappingData(sourceType: 'notification');

      when(() => mockClient.from('category_keyword_mappings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.create(
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '샐러디',
        categoryId: 'cat-food',
        sourceType: 'notification',
        createdBy: 'user-123',
      );
      expect(result.sourceType, 'notification');
    });

    test('중복된 키워드는 upsert로 덮어씌운다', () async {
      final mockResponse = _makeMappingData(categoryId: 'cat-new');

      when(() => mockClient.from('category_keyword_mappings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      // 동일한 keyword + sourceType으로 다른 category 생성
      final result = await repository.create(
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-new',
        sourceType: 'sms',
        createdBy: 'user-123',
      );
      expect(result.categoryId, 'cat-new');
    });
  });

  group('CategoryKeywordMappingRepository - delete', () {
    test('ID로 키워드 매핑을 삭제한다', () async {
      when(() => mockClient.from('category_keyword_mappings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.delete('mapping-1');
      // 에러 없이 완료되면 성공
    });
  });

  group('CategoryKeywordMappingRepository - findByKeyword', () {
    test('키워드, 결제수단, sourceType으로 매핑을 찾아 반환한다', () async {
      final mockResponse = _makeMappingData();

      when(() => mockClient.from('category_keyword_mappings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [mockResponse],
            maybeSingleData: mockResponse,
            hasMaybeSingleData: true,
          ));

      final result = await repository.findByKeyword('pm-1', '스타벅스', 'sms');
      expect(result, isA<CategoryKeywordMappingModel>());
      expect(result!.keyword, '스타벅스');
    });

    test('매핑이 없는 경우 null을 반환한다', () async {
      when(() => mockClient.from('category_keyword_mappings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [],
            hasMaybeSingleData: true,
            maybeSingleData: null,
          ));

      final result = await repository.findByKeyword('pm-1', '없는키워드', 'sms');
      expect(result, isNull);
    });

    test('notification sourceType으로 매핑을 찾는다', () async {
      final mockResponse = _makeMappingData(sourceType: 'notification');

      when(() => mockClient.from('category_keyword_mappings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [mockResponse],
            maybeSingleData: mockResponse,
            hasMaybeSingleData: true,
          ));

      final result = await repository.findByKeyword('pm-1', '샐러디', 'notification');
      expect(result, isA<CategoryKeywordMappingModel>());
      expect(result!.sourceType, 'notification');
    });
  });
}
