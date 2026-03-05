import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    group('앱 정보', () {
      test('앱 이름이 공유 가계부이다', () {
        expect(AppConstants.appName, equals('공유 가계부'));
      });

      test('앱 버전이 올바른 형식이다', () {
        expect(AppConstants.appVersion, isNotEmpty);
        // x.y.z 형식 검증
        expect(AppConstants.appVersion, matches(r'^\d+\.\d+\.\d+$'));
      });
    });

    group('통화', () {
      test('기본 통화가 KRW이다', () {
        expect(AppConstants.defaultCurrency, equals('KRW'));
      });

      test('지원 통화 목록에 KRW가 포함된다', () {
        expect(AppConstants.supportedCurrencies, contains('KRW'));
      });

      test('지원 통화 목록에 USD가 포함된다', () {
        expect(AppConstants.supportedCurrencies, contains('USD'));
      });

      test('지원 통화 목록에 JPY가 포함된다', () {
        expect(AppConstants.supportedCurrencies, contains('JPY'));
      });

      test('지원 통화 목록에 EUR가 포함된다', () {
        expect(AppConstants.supportedCurrencies, contains('EUR'));
      });

      test('지원 통화 목록이 비어있지 않다', () {
        expect(AppConstants.supportedCurrencies, isNotEmpty);
      });

      test('기본 통화가 지원 통화 목록에 포함된다', () {
        expect(
          AppConstants.supportedCurrencies,
          contains(AppConstants.defaultCurrency),
        );
      });
    });

    group('거래 타입', () {
      test('수입 타입 상수가 income이다', () {
        expect(AppConstants.transactionTypeIncome, equals('income'));
      });

      test('지출 타입 상수가 expense이다', () {
        expect(AppConstants.transactionTypeExpense, equals('expense'));
      });

      test('자산 타입 상수가 asset이다', () {
        expect(AppConstants.transactionTypeAsset, equals('asset'));
      });

      test('세 가지 거래 타입이 모두 다르다', () {
        final types = [
          AppConstants.transactionTypeIncome,
          AppConstants.transactionTypeExpense,
          AppConstants.transactionTypeAsset,
        ];
        expect(types.toSet().length, equals(3), reason: '거래 타입이 모두 고유해야 한다');
      });
    });

    group('멤버 권한', () {
      test('소유자 권한 상수가 owner이다', () {
        expect(AppConstants.roleOwner, equals('owner'));
      });

      test('편집자 권한 상수가 editor이다', () {
        expect(AppConstants.roleEditor, equals('editor'));
      });

      test('뷰어 권한 상수가 viewer이다', () {
        expect(AppConstants.roleViewer, equals('viewer'));
      });

      test('세 가지 권한 타입이 모두 다르다', () {
        final roles = [
          AppConstants.roleOwner,
          AppConstants.roleEditor,
          AppConstants.roleViewer,
        ];
        expect(roles.toSet().length, equals(3), reason: '권한 타입이 모두 고유해야 한다');
      });
    });

    group('공유 가계부 제한', () {
      test('가계부당 최대 멤버 수가 2이다', () {
        expect(AppConstants.maxMembersPerLedger, equals(2));
      });

      test('최대 멤버 수가 양수이다', () {
        expect(AppConstants.maxMembersPerLedger, greaterThan(0));
      });
    });

    group('반복 타입', () {
      test('매일 반복 타입 상수가 daily이다', () {
        expect(AppConstants.recurringDaily, equals('daily'));
      });

      test('매주 반복 타입 상수가 weekly이다', () {
        expect(AppConstants.recurringWeekly, equals('weekly'));
      });

      test('매월 반복 타입 상수가 monthly이다', () {
        expect(AppConstants.recurringMonthly, equals('monthly'));
      });

      test('세 가지 반복 타입이 모두 다르다', () {
        final types = [
          AppConstants.recurringDaily,
          AppConstants.recurringWeekly,
          AppConstants.recurringMonthly,
        ];
        expect(types.toSet().length, equals(3), reason: '반복 타입이 모두 고유해야 한다');
      });
    });

    group('이미지 관련 설정', () {
      test('최대 이미지 크기가 500KB이다', () {
        expect(AppConstants.maxImageSizeKB, equals(500));
      });

      test('최대 이미지 크기가 양수이다', () {
        expect(AppConstants.maxImageSizeKB, greaterThan(0));
      });

      test('이미지 품질이 0.7이다', () {
        expect(AppConstants.imageQuality, equals(0.7));
      });

      test('이미지 품질이 0에서 1 사이 값이다', () {
        expect(AppConstants.imageQuality, greaterThan(0.0));
        expect(AppConstants.imageQuality, lessThanOrEqualTo(1.0));
      });
    });

    group('페이지네이션 설정', () {
      test('기본 페이지 크기가 20이다', () {
        expect(AppConstants.defaultPageSize, equals(20));
      });

      test('기본 페이지 크기가 양수이다', () {
        expect(AppConstants.defaultPageSize, greaterThan(0));
      });
    });

    group('캐시 설정', () {
      test('캐시 유효 기간이 5분이다', () {
        expect(AppConstants.cacheDuration, equals(const Duration(minutes: 5)));
      });

      test('캐시 유효 기간이 양수이다', () {
        expect(AppConstants.cacheDuration.isNegative, isFalse);
        expect(AppConstants.cacheDuration.inSeconds, greaterThan(0));
      });
    });
  });
}
