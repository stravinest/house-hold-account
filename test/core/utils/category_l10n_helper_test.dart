import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/category_l10n_helper.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockAppLocalizations extends Mock implements AppLocalizations {}

void main() {
  group('CategoryL10nHelper', () {
    late MockAppLocalizations mockL10n;

    setUp(() {
      mockL10n = MockAppLocalizations();
    });

    group('translate - 지출 카테고리', () {
      test('식비를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryFood).thenReturn('Food');

        // When
        final result = CategoryL10nHelper.translate('식비', mockL10n);

        // Then
        expect(result, equals('Food'));
        verify(() => mockL10n.defaultCategoryFood).called(1);
      });

      test('교통을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryTransport).thenReturn('Transport');

        // When
        final result = CategoryL10nHelper.translate('교통', mockL10n);

        // Then
        expect(result, equals('Transport'));
        verify(() => mockL10n.defaultCategoryTransport).called(1);
      });

      test('쇼핑을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryShopping).thenReturn('Shopping');

        // When
        final result = CategoryL10nHelper.translate('쇼핑', mockL10n);

        // Then
        expect(result, equals('Shopping'));
        verify(() => mockL10n.defaultCategoryShopping).called(1);
      });

      test('생활을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryLiving).thenReturn('Living');

        // When
        final result = CategoryL10nHelper.translate('생활', mockL10n);

        // Then
        expect(result, equals('Living'));
        verify(() => mockL10n.defaultCategoryLiving).called(1);
      });

      test('통신을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryTelecom).thenReturn('Telecom');

        // When
        final result = CategoryL10nHelper.translate('통신', mockL10n);

        // Then
        expect(result, equals('Telecom'));
        verify(() => mockL10n.defaultCategoryTelecom).called(1);
      });

      test('의료를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryMedical).thenReturn('Medical');

        // When
        final result = CategoryL10nHelper.translate('의료', mockL10n);

        // Then
        expect(result, equals('Medical'));
        verify(() => mockL10n.defaultCategoryMedical).called(1);
      });

      test('문화를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryCulture).thenReturn('Culture');

        // When
        final result = CategoryL10nHelper.translate('문화', mockL10n);

        // Then
        expect(result, equals('Culture'));
        verify(() => mockL10n.defaultCategoryCulture).called(1);
      });

      test('교육을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryEducation).thenReturn('Education');

        // When
        final result = CategoryL10nHelper.translate('교육', mockL10n);

        // Then
        expect(result, equals('Education'));
        verify(() => mockL10n.defaultCategoryEducation).called(1);
      });

      test('기타 지출을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryOtherExpense)
            .thenReturn('Other Expense');

        // When
        final result = CategoryL10nHelper.translate('기타 지출', mockL10n);

        // Then
        expect(result, equals('Other Expense'));
        verify(() => mockL10n.defaultCategoryOtherExpense).called(1);
      });
    });

    group('translate - 수입 카테고리', () {
      test('급여를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategorySalary).thenReturn('Salary');

        // When
        final result = CategoryL10nHelper.translate('급여', mockL10n);

        // Then
        expect(result, equals('Salary'));
        verify(() => mockL10n.defaultCategorySalary).called(1);
      });

      test('부업을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategorySideJob).thenReturn('Side Job');

        // When
        final result = CategoryL10nHelper.translate('부업', mockL10n);

        // Then
        expect(result, equals('Side Job'));
        verify(() => mockL10n.defaultCategorySideJob).called(1);
      });

      test('용돈을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryAllowance).thenReturn('Allowance');

        // When
        final result = CategoryL10nHelper.translate('용돈', mockL10n);

        // Then
        expect(result, equals('Allowance'));
        verify(() => mockL10n.defaultCategoryAllowance).called(1);
      });

      test('이자를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryInterest).thenReturn('Interest');

        // When
        final result = CategoryL10nHelper.translate('이자', mockL10n);

        // Then
        expect(result, equals('Interest'));
        verify(() => mockL10n.defaultCategoryInterest).called(1);
      });

      test('기타 수입을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryOtherIncome)
            .thenReturn('Other Income');

        // When
        final result = CategoryL10nHelper.translate('기타 수입', mockL10n);

        // Then
        expect(result, equals('Other Income'));
        verify(() => mockL10n.defaultCategoryOtherIncome).called(1);
      });
    });

    group('translate - 자산 카테고리', () {
      test('정기예금을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryFixedDeposit)
            .thenReturn('Fixed Deposit');

        // When
        final result = CategoryL10nHelper.translate('정기예금', mockL10n);

        // Then
        expect(result, equals('Fixed Deposit'));
        verify(() => mockL10n.defaultCategoryFixedDeposit).called(1);
      });

      test('적금을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategorySavings).thenReturn('Savings');

        // When
        final result = CategoryL10nHelper.translate('적금', mockL10n);

        // Then
        expect(result, equals('Savings'));
        verify(() => mockL10n.defaultCategorySavings).called(1);
      });

      test('주식을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryStock).thenReturn('Stock');

        // When
        final result = CategoryL10nHelper.translate('주식', mockL10n);

        // Then
        expect(result, equals('Stock'));
        verify(() => mockL10n.defaultCategoryStock).called(1);
      });

      test('펀드를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryFund).thenReturn('Fund');

        // When
        final result = CategoryL10nHelper.translate('펀드', mockL10n);

        // Then
        expect(result, equals('Fund'));
        verify(() => mockL10n.defaultCategoryFund).called(1);
      });

      test('부동산을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryRealEstate)
            .thenReturn('Real Estate');

        // When
        final result = CategoryL10nHelper.translate('부동산', mockL10n);

        // Then
        expect(result, equals('Real Estate'));
        verify(() => mockL10n.defaultCategoryRealEstate).called(1);
      });

      test('암호화폐를 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryCrypto).thenReturn('Crypto');

        // When
        final result = CategoryL10nHelper.translate('암호화폐', mockL10n);

        // Then
        expect(result, equals('Crypto'));
        verify(() => mockL10n.defaultCategoryCrypto).called(1);
      });

      test('기타 자산을 번역한다', () {
        // Given
        when(() => mockL10n.defaultCategoryOtherAsset)
            .thenReturn('Other Asset');

        // When
        final result = CategoryL10nHelper.translate('기타 자산', mockL10n);

        // Then
        expect(result, equals('Other Asset'));
        verify(() => mockL10n.defaultCategoryOtherAsset).called(1);
      });
    });

    group('translate - 특수 카테고리', () {
      test('미지정을 번역한다', () {
        // Given
        when(() => mockL10n.categoryUncategorized).thenReturn('Uncategorized');

        // When
        final result = CategoryL10nHelper.translate('미지정', mockL10n);

        // Then
        expect(result, equals('Uncategorized'));
        verify(() => mockL10n.categoryUncategorized).called(1);
      });

      test('고정비를 번역한다', () {
        // Given
        when(() => mockL10n.categoryFixedExpense).thenReturn('Fixed Expense');

        // When
        final result = CategoryL10nHelper.translate('고정비', mockL10n);

        // Then
        expect(result, equals('Fixed Expense'));
        verify(() => mockL10n.categoryFixedExpense).called(1);
      });

      test('미분류를 번역한다', () {
        // Given
        when(() => mockL10n.categoryUnknown).thenReturn('Unknown');

        // When
        final result = CategoryL10nHelper.translate('미분류', mockL10n);

        // Then
        expect(result, equals('Unknown'));
        verify(() => mockL10n.categoryUnknown).called(1);
      });
    });

    group('translate - 커스텀 카테고리', () {
      test('커스텀 카테고리는 원래 이름을 그대로 반환한다', () {
        // Given
        const customCategoryName = '내 커스텀 카테고리';

        // When
        final result = CategoryL10nHelper.translate(customCategoryName, mockL10n);

        // Then
        expect(result, equals(customCategoryName));
        verifyNever(() => mockL10n.defaultCategoryFood);
      });

      test('알 수 없는 한글 카테고리는 원래 이름을 반환한다', () {
        // Given
        const unknownName = '알 수 없는 카테고리';

        // When
        final result = CategoryL10nHelper.translate(unknownName, mockL10n);

        // Then
        expect(result, equals(unknownName));
      });

      test('영문 카테고리는 원래 이름을 반환한다', () {
        // Given
        const englishName = 'Custom Category';

        // When
        final result = CategoryL10nHelper.translate(englishName, mockL10n);

        // Then
        expect(result, equals(englishName));
      });

      test('빈 문자열은 그대로 반환한다', () {
        // Given
        const emptyName = '';

        // When
        final result = CategoryL10nHelper.translate(emptyName, mockL10n);

        // Then
        expect(result, equals(emptyName));
      });
    });

    group('translate - 경계값 테스트', () {
      test('공백이 포함된 기본 카테고리를 정확히 매칭한다', () {
        // Given
        when(() => mockL10n.defaultCategoryOtherExpense)
            .thenReturn('Other Expense');

        // When
        final result = CategoryL10nHelper.translate('기타 지출', mockL10n);

        // Then
        expect(result, equals('Other Expense'));
      });

      test('앞뒤 공백이 있는 카테고리는 매칭하지 않는다', () {
        // Given
        const nameWithSpace = ' 식비 ';

        // When
        final result = CategoryL10nHelper.translate(nameWithSpace, mockL10n);

        // Then
        expect(result, equals(nameWithSpace));
        verifyNever(() => mockL10n.defaultCategoryFood);
      });

      test('대소문자가 다른 카테고리는 매칭하지 않는다', () {
        // Given
        const upperCaseName = 'FOOD';

        // When
        final result = CategoryL10nHelper.translate(upperCaseName, mockL10n);

        // Then
        expect(result, equals(upperCaseName));
      });
    });
  });
}
