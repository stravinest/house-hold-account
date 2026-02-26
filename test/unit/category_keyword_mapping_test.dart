import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/category_keyword_mapping.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';

void main() {
  final now = DateTime(2026, 2, 25, 12, 0, 0);

  group('CategoryKeywordMapping Entity 테스트', () {
    test('동일한 속성을 가진 두 엔티티는 같다고 판단해야 한다', () {
      final mapping1 = CategoryKeywordMapping(
        id: 'test-id',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      final mapping2 = CategoryKeywordMapping(
        id: 'test-id',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(mapping1, equals(mapping2));
    });

    test('다른 속성을 가진 두 엔티티는 다르다고 판단해야 한다', () {
      final mapping1 = CategoryKeywordMapping(
        id: 'test-id-1',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      final mapping2 = CategoryKeywordMapping(
        id: 'test-id-2',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: 'GS25',
        categoryId: 'cat-2',
        sourceType: 'push',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(mapping1, isNot(equals(mapping2)));
    });

    test('copyWith으로 특정 필드만 변경할 수 있어야 한다', () {
      final original = CategoryKeywordMapping(
        id: 'test-id',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      final updated = original.copyWith(
        keyword: 'GS25',
        categoryId: 'cat-2',
      );

      expect(updated.keyword, 'GS25');
      expect(updated.categoryId, 'cat-2');
      // 나머지 필드는 원본과 동일해야 한다
      expect(updated.id, original.id);
      expect(updated.paymentMethodId, original.paymentMethodId);
      expect(updated.sourceType, original.sourceType);
    });

    test('sourceType은 sms 또는 push 값을 가져야 한다', () {
      final smsMapping = CategoryKeywordMapping(
        id: 'id-1',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      final pushMapping = CategoryKeywordMapping(
        id: 'id-2',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: 'CU편의점',
        categoryId: 'cat-2',
        sourceType: 'push',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      expect(smsMapping.sourceType, 'sms');
      expect(pushMapping.sourceType, 'push');
    });
  });

  group('CategoryKeywordMappingModel JSON 변환 테스트', () {
    final sampleJson = {
      'id': 'test-id',
      'payment_method_id': 'pm-1',
      'ledger_id': 'ledger-1',
      'keyword': '스타벅스',
      'category_id': 'cat-1',
      'source_type': 'sms',
      'created_by': 'user-1',
      'created_at': '2026-02-25T12:00:00.000',
      'updated_at': '2026-02-25T12:00:00.000',
    };

    test('fromJson으로 JSON에서 모델을 올바르게 생성해야 한다', () {
      final model = CategoryKeywordMappingModel.fromJson(sampleJson);

      expect(model.id, 'test-id');
      expect(model.paymentMethodId, 'pm-1');
      expect(model.ledgerId, 'ledger-1');
      expect(model.keyword, '스타벅스');
      expect(model.categoryId, 'cat-1');
      expect(model.sourceType, 'sms');
      expect(model.createdBy, 'user-1');
    });

    test('toJson으로 모델을 JSON으로 올바르게 변환해야 한다', () {
      final model = CategoryKeywordMappingModel.fromJson(sampleJson);
      final json = model.toJson();

      expect(json['id'], 'test-id');
      expect(json['payment_method_id'], 'pm-1');
      expect(json['ledger_id'], 'ledger-1');
      expect(json['keyword'], '스타벅스');
      expect(json['category_id'], 'cat-1');
      expect(json['source_type'], 'sms');
      expect(json['created_by'], 'user-1');
    });

    test('toCreateJson은 id와 timestamp 없이 생성용 JSON을 반환해야 한다', () {
      final json = CategoryKeywordMappingModel.toCreateJson(
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
      );

      expect(json.containsKey('id'), false);
      expect(json.containsKey('created_at'), false);
      expect(json.containsKey('updated_at'), false);
      expect(json['payment_method_id'], 'pm-1');
      expect(json['keyword'], '스타벅스');
      expect(json['source_type'], 'sms');
    });

    test('fromEntity와 toEntity로 Entity-Model 간 변환이 올바르게 되어야 한다', () {
      final entity = CategoryKeywordMapping(
        id: 'test-id',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: 'GS25',
        categoryId: 'cat-2',
        sourceType: 'push',
        createdBy: 'user-1',
        createdAt: now,
        updatedAt: now,
      );

      // Entity -> Model
      final model = CategoryKeywordMappingModel.fromEntity(entity);
      expect(model.id, entity.id);
      expect(model.keyword, entity.keyword);
      expect(model.sourceType, entity.sourceType);

      // Model -> Entity
      final backToEntity = model.toEntity();
      expect(backToEntity, equals(entity));
    });

    test('fromJson에서 한글 키워드를 올바르게 처리해야 한다', () {
      final koreanJson = {
        ...sampleJson,
        'keyword': 'CU편의점',
      };

      final model = CategoryKeywordMappingModel.fromJson(koreanJson);
      expect(model.keyword, 'CU편의점');
    });

    test('toCreateJson에서 sourceType이 sms일 때 올바른 JSON을 생성해야 한다', () {
      final json = CategoryKeywordMappingModel.toCreateJson(
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
      );

      expect(json['source_type'], 'sms');
      expect(json['keyword'], '스타벅스');
      expect(json['payment_method_id'], 'pm-1');
      expect(json['ledger_id'], 'ledger-1');
      expect(json['category_id'], 'cat-1');
      expect(json['created_by'], 'user-1');
    });

    test('toCreateJson에서 sourceType이 push일 때 올바른 JSON을 생성해야 한다', () {
      final json = CategoryKeywordMappingModel.toCreateJson(
        paymentMethodId: 'pm-2',
        ledgerId: 'ledger-2',
        keyword: 'GS25',
        categoryId: 'cat-3',
        sourceType: 'push',
        createdBy: 'user-2',
      );

      expect(json['source_type'], 'push');
      expect(json['keyword'], 'GS25');
      expect(json['payment_method_id'], 'pm-2');
    });

    test('fromJson에서 id 필드가 누락되면 TypeError가 발생해야 한다', () {
      final missingIdJson = {
        'payment_method_id': 'pm-1',
        'ledger_id': 'ledger-1',
        'keyword': '스타벅스',
        'category_id': 'cat-1',
        'source_type': 'sms',
        'created_by': 'user-1',
        'created_at': '2026-02-25T12:00:00.000',
        'updated_at': '2026-02-25T12:00:00.000',
      };

      expect(
        () => CategoryKeywordMappingModel.fromJson(missingIdJson),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson에서 keyword 필드가 누락되면 TypeError가 발생해야 한다', () {
      final missingKeywordJson = {
        'id': 'test-id',
        'payment_method_id': 'pm-1',
        'ledger_id': 'ledger-1',
        'category_id': 'cat-1',
        'source_type': 'sms',
        'created_by': 'user-1',
        'created_at': '2026-02-25T12:00:00.000',
        'updated_at': '2026-02-25T12:00:00.000',
      };

      expect(
        () => CategoryKeywordMappingModel.fromJson(missingKeywordJson),
        throwsA(isA<TypeError>()),
      );
    });

    test('fromJson에서 created_at 필드가 누락되면 에러가 발생해야 한다', () {
      final missingCreatedAtJson = {
        'id': 'test-id',
        'payment_method_id': 'pm-1',
        'ledger_id': 'ledger-1',
        'keyword': '스타벅스',
        'category_id': 'cat-1',
        'source_type': 'sms',
        'created_by': 'user-1',
        'updated_at': '2026-02-25T12:00:00.000',
      };

      expect(
        () => CategoryKeywordMappingModel.fromJson(missingCreatedAtJson),
        throwsA(anything),
      );
    });
  });
}
