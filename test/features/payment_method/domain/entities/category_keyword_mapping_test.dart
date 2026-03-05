import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/category_keyword_mapping.dart';

void main() {
  group('CategoryKeywordMapping 엔티티 테스트', () {
    final baseMapping = CategoryKeywordMapping(
      id: 'mapping-1',
      paymentMethodId: 'pm-1',
      ledgerId: 'ledger-1',
      keyword: '스타벅스',
      categoryId: 'cat-1',
      sourceType: 'sms',
      createdBy: 'user-1',
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 1, 2),
    );

    test('모든 필드가 올바르게 초기화된다', () {
      expect(baseMapping.id, 'mapping-1');
      expect(baseMapping.paymentMethodId, 'pm-1');
      expect(baseMapping.ledgerId, 'ledger-1');
      expect(baseMapping.keyword, '스타벅스');
      expect(baseMapping.categoryId, 'cat-1');
      expect(baseMapping.sourceType, 'sms');
      expect(baseMapping.createdBy, 'user-1');
      expect(baseMapping.createdAt, DateTime(2024, 1, 1));
      expect(baseMapping.updatedAt, DateTime(2024, 1, 2));
    });

    test('notification sourceType으로 초기화된다', () {
      final mapping = CategoryKeywordMapping(
        id: 'mapping-2',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '맥도날드',
        categoryId: 'cat-2',
        sourceType: 'notification',
        createdBy: 'user-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(mapping.sourceType, 'notification');
    });

    test('copyWith로 keyword를 변경할 수 있다', () {
      final updated = baseMapping.copyWith(keyword: '이디야');

      expect(updated.keyword, '이디야');
      expect(updated.id, 'mapping-1'); // 기존 값 유지
      expect(updated.categoryId, 'cat-1'); // 기존 값 유지
    });

    test('copyWith로 categoryId를 변경할 수 있다', () {
      final updated = baseMapping.copyWith(categoryId: 'cat-99');

      expect(updated.categoryId, 'cat-99');
      expect(updated.keyword, '스타벅스'); // 기존 값 유지
    });

    test('copyWith로 sourceType을 변경할 수 있다', () {
      final updated = baseMapping.copyWith(sourceType: 'notification');

      expect(updated.sourceType, 'notification');
      expect(updated.id, 'mapping-1'); // 기존 값 유지
    });

    test('copyWith로 여러 필드를 동시에 변경할 수 있다', () {
      final updated = baseMapping.copyWith(
        keyword: '할리스',
        categoryId: 'cat-drink',
        sourceType: 'notification',
      );

      expect(updated.keyword, '할리스');
      expect(updated.categoryId, 'cat-drink');
      expect(updated.sourceType, 'notification');
      expect(updated.id, 'mapping-1'); // 기존 값 유지
      expect(updated.paymentMethodId, 'pm-1'); // 기존 값 유지
    });

    test('동일한 필드를 가진 두 인스턴스는 동등하다 (Equatable)', () {
      final mapping1 = CategoryKeywordMapping(
        id: 'mapping-1',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      final mapping2 = CategoryKeywordMapping(
        id: 'mapping-1',
        paymentMethodId: 'pm-1',
        ledgerId: 'ledger-1',
        keyword: '스타벅스',
        categoryId: 'cat-1',
        sourceType: 'sms',
        createdBy: 'user-1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
      );

      expect(mapping1, equals(mapping2));
    });

    test('다른 keyword를 가진 두 인스턴스는 동등하지 않다', () {
      final mapping2 = baseMapping.copyWith(keyword: '투썸');

      expect(baseMapping, isNot(equals(mapping2)));
    });

    test('props 리스트가 모든 필드를 포함한다', () {
      expect(baseMapping.props.length, 9);
      expect(baseMapping.props, contains('mapping-1'));
      expect(baseMapping.props, contains('스타벅스'));
      expect(baseMapping.props, contains('sms'));
    });
  });
}
