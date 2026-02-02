import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/financial_service_template.dart';

void main() {
  group('FinancialServiceTemplate', () {
    group('templates list', () {
      test('모든 템플릿이 유효한 데이터를 가지고 있어야 한다', () {
        for (final template in FinancialServiceTemplate.templates) {
          // ID가 비어있지 않아야 함
          expect(
            template.id,
            isNotEmpty,
            reason: 'ID should not be empty for ${template.name}',
          );

          // 이름이 비어있지 않아야 함
          expect(
            template.name,
            isNotEmpty,
            reason: 'Name should not be empty for ${template.id}',
          );

          // 색상이 유효한 HEX 형식이어야 함
          expect(
            template.color.startsWith('#'),
            isTrue,
            reason: 'Color should start with # for ${template.name}',
          );
          expect(
            template.color.length,
            equals(7),
            reason:
                'Color should be 7 characters (#RRGGBB) for ${template.name}',
          );

          // 기본 SMS 샘플이 비어있지 않아야 함
          expect(
            template.defaultSampleSms,
            isNotEmpty,
            reason:
                'Default SMS sample should not be empty for ${template.name}',
          );

          // 기본 키워드가 최소 1개 이상이어야 함
          expect(
            template.defaultKeywords,
            isNotEmpty,
            reason: 'Default keywords should not be empty for ${template.name}',
          );

          // 카테고리가 유효해야 함
          expect(
            template.category,
            isIn([
              FinancialServiceCategory.card,
              FinancialServiceCategory.localCurrency,
              FinancialServiceCategory.manual,
            ]),
            reason: 'Category should be valid for ${template.name}',
          );
        }
      });

      test('카드 템플릿이 최소 1개 이상 존재해야 한다', () {
        final cards = FinancialServiceTemplate.templates
            .where((t) => t.category == FinancialServiceCategory.card)
            .toList();

        expect(cards, isNotEmpty, reason: 'Card templates should exist');
      });

      test('지역화폐 템플릿이 최소 1개 이상 존재해야 한다', () {
        final localCurrencies = FinancialServiceTemplate.templates
            .where((t) => t.category == FinancialServiceCategory.localCurrency)
            .toList();

        expect(
          localCurrencies,
          isNotEmpty,
          reason: 'Local currency templates should exist',
        );
      });

      test('모든 템플릿 ID가 고유해야 한다', () {
        final ids = FinancialServiceTemplate.templates
            .map((t) => t.id)
            .toList();
        final uniqueIds = ids.toSet();

        expect(
          ids.length,
          equals(uniqueIds.length),
          reason: 'All template IDs should be unique',
        );
      });

      test('모든 템플릿 이름이 고유해야 한다', () {
        final names = FinancialServiceTemplate.templates
            .map((t) => t.name)
            .toList();
        final uniqueNames = names.toSet();

        expect(
          names.length,
          equals(uniqueNames.length),
          reason: 'All template names should be unique',
        );
      });

      test('색상 코드가 유효한 HEX 색상이어야 한다', () {
        final hexColorRegex = RegExp(r'^#[0-9A-Fa-f]{6}$');

        for (final template in FinancialServiceTemplate.templates) {
          expect(
            hexColorRegex.hasMatch(template.color),
            isTrue,
            reason:
                'Color ${template.color} should be valid HEX for ${template.name}',
          );
        }
      });
    });

    group('카드 템플릿', () {
      test('주요 한국 카드사가 포함되어 있어야 한다', () {
        final cardNames = FinancialServiceTemplate.templates
            .where((t) => t.category == FinancialServiceCategory.card)
            .map((t) => t.name)
            .toList();

        // 주요 카드사 목록
        final majorCards = ['KB국민카드', '신한카드', '삼성카드', '현대카드', '롯데카드'];

        for (final card in majorCards) {
          expect(
            cardNames,
            contains(card),
            reason: '$card should be in the template list',
          );
        }
      });

      test('카드 템플릿의 SMS 샘플에 승인 정보가 포함되어 있어야 한다', () {
        final cards = FinancialServiceTemplate.templates.where(
          (t) => t.category == FinancialServiceCategory.card,
        );

        for (final card in cards) {
          // SMS 샘플에 금액 정보(원)가 포함되어야 함
          expect(
            card.defaultSampleSms.contains('원'),
            isTrue,
            reason: '${card.name} SMS should contain amount info',
          );
        }
      });
    });

    group('지역화폐 템플릿', () {
      test('주요 지역화폐가 포함되어 있어야 한다', () {
        final localCurrencyNames = FinancialServiceTemplate.templates
            .where((t) => t.category == FinancialServiceCategory.localCurrency)
            .map((t) => t.name)
            .toList();

        // 최소 1개 이상의 지역화폐가 있어야 함
        expect(localCurrencyNames.length, greaterThanOrEqualTo(1));
      });

      test('지역화폐 템플릿의 SMS 샘플에 결제 정보가 포함되어 있어야 한다', () {
        final localCurrencies = FinancialServiceTemplate.templates.where(
          (t) => t.category == FinancialServiceCategory.localCurrency,
        );

        for (final lc in localCurrencies) {
          // SMS 샘플에 금액 정보(원)가 포함되어야 함
          expect(
            lc.defaultSampleSms.contains('원'),
            isTrue,
            reason: '${lc.name} SMS should contain amount info',
          );
        }
      });
    });

    group('Equatable', () {
      test('동일한 속성을 가진 두 템플릿은 같아야 한다', () {
        const template1 = FinancialServiceTemplate(
          id: 'test_id',
          name: 'Test Card',
          logoIcon: 'assets/test.png',
          color: '#FF0000',
          defaultSampleSms: 'Test SMS',
          defaultKeywords: ['test'],
          category: FinancialServiceCategory.card,
        );

        const template2 = FinancialServiceTemplate(
          id: 'test_id',
          name: 'Test Card',
          logoIcon: 'assets/test.png',
          color: '#FF0000',
          defaultSampleSms: 'Test SMS',
          defaultKeywords: ['test'],
          category: FinancialServiceCategory.card,
        );

        expect(template1, equals(template2));
        expect(template1.hashCode, equals(template2.hashCode));
      });

      test('다른 속성을 가진 두 템플릿은 달라야 한다', () {
        const template1 = FinancialServiceTemplate(
          id: 'test_id_1',
          name: 'Test Card 1',
          logoIcon: 'assets/test.png',
          color: '#FF0000',
          defaultSampleSms: 'Test SMS',
          defaultKeywords: ['test'],
          category: FinancialServiceCategory.card,
        );

        const template2 = FinancialServiceTemplate(
          id: 'test_id_2',
          name: 'Test Card 2',
          logoIcon: 'assets/test.png',
          color: '#00FF00',
          defaultSampleSms: 'Test SMS 2',
          defaultKeywords: ['test2'],
          category: FinancialServiceCategory.card,
        );

        expect(template1, isNot(equals(template2)));
      });
    });
  });
}
