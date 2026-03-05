import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/category_keyword_mapping.dart';

void main() {
  group('CategoryKeywordMappingModel 테스트', () {
    final testJson = {
      'id': 'mapping-1',
      'payment_method_id': 'pm-1',
      'ledger_id': 'ledger-1',
      'keyword': '스타벅스',
      'category_id': 'cat-1',
      'source_type': 'sms',
      'created_by': 'user-1',
      'created_at': '2024-01-01T00:00:00.000',
      'updated_at': '2024-01-02T00:00:00.000',
    };

    test('fromJson으로 올바르게 파싱된다', () {
      final model = CategoryKeywordMappingModel.fromJson(testJson);

      expect(model.id, 'mapping-1');
      expect(model.paymentMethodId, 'pm-1');
      expect(model.ledgerId, 'ledger-1');
      expect(model.keyword, '스타벅스');
      expect(model.categoryId, 'cat-1');
      expect(model.sourceType, 'sms');
      expect(model.createdBy, 'user-1');
      expect(model.createdAt, DateTime(2024, 1, 1));
      expect(model.updatedAt, DateTime(2024, 1, 2));
    });

    test('toJson으로 올바르게 직렬화된다', () {
      final model = CategoryKeywordMappingModel.fromJson(testJson);
      final json = model.toJson();

      expect(json['id'], 'mapping-1');
      expect(json['payment_method_id'], 'pm-1');
      expect(json['ledger_id'], 'ledger-1');
      expect(json['keyword'], '스타벅스');
      expect(json['category_id'], 'cat-1');
      expect(json['source_type'], 'sms');
      expect(json['created_by'], 'user-1');
    });

    test('fromEntity로 엔티티에서 모델로 변환된다', () {
      final entity = CategoryKeywordMapping(
        id: 'mapping-2',
        paymentMethodId: 'pm-2',
        ledgerId: 'ledger-2',
        keyword: '맥도날드',
        categoryId: 'cat-food',
        sourceType: 'notification',
        createdBy: 'user-2',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 2),
      );

      final model = CategoryKeywordMappingModel.fromEntity(entity);

      expect(model.id, 'mapping-2');
      expect(model.paymentMethodId, 'pm-2');
      expect(model.keyword, '맥도날드');
      expect(model.sourceType, 'notification');
    });

    test('toEntity로 모델에서 엔티티로 변환된다', () {
      final model = CategoryKeywordMappingModel.fromJson(testJson);
      final entity = model.toEntity();

      expect(entity, isA<CategoryKeywordMapping>());
      expect(entity.id, 'mapping-1');
      expect(entity.keyword, '스타벅스');
      expect(entity.sourceType, 'sms');
    });

    test('toCreateJson이 id 없이 생성 데이터를 반환한다', () {
      final json = CategoryKeywordMappingModel.toCreateJson(
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '배스킨라빈스',
        categoryId: 'cat-dessert',
        sourceType: 'sms',
        createdBy: 'user-1',
      );

      expect(json.containsKey('id'), isFalse);
      expect(json['payment_method_id'], 'pm-1');
      expect(json['ledger_id'], 'ledger-1');
      expect(json['keyword'], '배스킨라빈스');
      expect(json['category_id'], 'cat-dessert');
      expect(json['source_type'], 'sms');
      expect(json['created_by'], 'user-1');
    });

    test('fromJson -> toJson 왕복 변환이 올바르다', () {
      final model = CategoryKeywordMappingModel.fromJson(testJson);
      final json = model.toJson();
      final model2 = CategoryKeywordMappingModel.fromJson(json);

      expect(model2.id, model.id);
      expect(model2.keyword, model.keyword);
      expect(model2.categoryId, model.categoryId);
      expect(model2.sourceType, model.sourceType);
    });
  });
}
