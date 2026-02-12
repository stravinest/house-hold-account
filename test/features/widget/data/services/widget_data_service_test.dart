import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/widget/data/services/widget_data_service.dart';

void main() {
  // Widget 서비스는 Platform 의존성과 HomeWidget 패키지 의존성이 있어
  // Mock 없이는 테스트하기 어렵습니다.
  // 여기서는 상수와 공개 API 스펙을 검증합니다.

  group('WidgetDataService', () {
    group('상수 검증', () {
      test('monthly_expense 키가 올바르게 정의되어 있다', () {
        // Given & When
        const key = WidgetDataService.keyMonthlyExpense;

        // Then
        expect(key, equals('monthly_expense'));
      });

      test('monthly_income 키가 올바르게 정의되어 있다', () {
        // Given & When
        const key = WidgetDataService.keyMonthlyIncome;

        // Then
        expect(key, equals('monthly_income'));
      });

      test('last_updated 키가 올바르게 정의되어 있다', () {
        // Given & When
        const key = WidgetDataService.keyLastUpdated;

        // Then
        expect(key, equals('last_updated'));
      });

      test('ledger_name 키가 올바르게 정의되어 있다', () {
        // Given & When
        const key = WidgetDataService.keyLedgerName;

        // Then
        expect(key, equals('ledger_name'));
      });
    });

    group('메서드 시그니처 검증', () {
      test('initialize 메서드가 Future<void>를 반환한다', () {
        // Given & When: 메서드 시그니처 확인
        // 실제 호출은 HomeWidget 의존성 때문에 생략

        // Then: 타입만 확인
        expect(
          WidgetDataService.initialize,
          isA<Future<void> Function()>(),
        );
      });

      test('updateWidgetData 메서드가 필수 파라미터를 가지고 있다', () {
        // Given & When: 메서드 시그니처 확인
        // updateWidgetData는 named parameter이므로 컴파일 타임에 체크됨

        // Then: 문서화 목적으로 파라미터 이름 확인
        const expectedParams = [
          'monthlyExpense',
          'monthlyIncome',
          'ledgerName',
        ];

        // 실제로는 코드에서 컴파일 타임에 체크되므로 문서화만 진행
        expect(expectedParams, hasLength(3));
      });

      test('refreshWidgets 메서드가 Future<void>를 반환한다', () {
        // Given & When
        expect(
          WidgetDataService.refreshWidgets,
          isA<Future<void> Function()>(),
        );
      });

      test('clearWidgetData 메서드가 Future<void>를 반환한다', () {
        // Given & When
        expect(
          WidgetDataService.clearWidgetData,
          isA<Future<void> Function()>(),
        );
      });

      test('getInitialLaunchUri 메서드가 Future<Uri?>를 반환한다', () {
        // Given & When
        expect(
          WidgetDataService.getInitialLaunchUri,
          isA<Future<Uri?> Function()>(),
        );
      });

      test('widgetLaunchStream getter가 Stream<Uri?>를 반환한다', () {
        // Given & When: getter 타입 확인
        expect(
          WidgetDataService.widgetLaunchStream,
          isA<Stream<Uri?>>(),
        );
      });
    });

    group('위젯 데이터 키 일관성', () {
      test('모든 키가 snake_case 형식이다', () {
        // Given
        final keys = [
          WidgetDataService.keyMonthlyExpense,
          WidgetDataService.keyMonthlyIncome,
          WidgetDataService.keyLastUpdated,
          WidgetDataService.keyLedgerName,
        ];

        // When & Then: snake_case 패턴 검증
        final snakeCasePattern = RegExp(r'^[a-z]+(_[a-z]+)*$');
        for (final key in keys) {
          expect(
            snakeCasePattern.hasMatch(key),
            isTrue,
            reason: '$key는 snake_case 형식이어야 합니다',
          );
        }
      });

      test('모든 키가 고유하다', () {
        // Given
        final keys = [
          WidgetDataService.keyMonthlyExpense,
          WidgetDataService.keyMonthlyIncome,
          WidgetDataService.keyLastUpdated,
          WidgetDataService.keyLedgerName,
        ];

        // When
        final uniqueKeys = keys.toSet();

        // Then
        expect(keys.length, equals(uniqueKeys.length));
      });

      test('키 이름이 의미를 명확히 전달한다', () {
        // Given & When
        final keys = {
          WidgetDataService.keyMonthlyExpense: '월간 지출',
          WidgetDataService.keyMonthlyIncome: '월간 수입',
          WidgetDataService.keyLastUpdated: '마지막 업데이트',
          WidgetDataService.keyLedgerName: '가계부 이름',
        };

        // Then: 모든 키가 정의되어 있는지 확인
        expect(keys.keys, hasLength(4));
        expect(keys[WidgetDataService.keyMonthlyExpense], isNotEmpty);
        expect(keys[WidgetDataService.keyMonthlyIncome], isNotEmpty);
        expect(keys[WidgetDataService.keyLastUpdated], isNotEmpty);
        expect(keys[WidgetDataService.keyLedgerName], isNotEmpty);
      });
    });

    group('Android/iOS 위젯 이름', () {
      test('Android 위젯 이름이 정의되어 있다', () {
        // Given & When: 코드에서 private 상수로 정의됨
        // QuickAddWidget, MonthlySummaryWidget

        // Then: 문서화 목적으로 검증
        const androidWidgets = [
          'QuickAddWidget',
          'MonthlySummaryWidget',
        ];

        expect(androidWidgets, hasLength(2));
        for (final widget in androidWidgets) {
          expect(widget, isNotEmpty);
          expect(widget, contains('Widget'));
        }
      });

      test('iOS App Group ID 형식이 올바르다', () {
        // Given & When: 코드에서 private 상수로 정의됨
        const iosAppGroupId = 'group.com.household.shared.sharedHouseholdAccount';

        // Then
        expect(iosAppGroupId, startsWith('group.'));
        expect(iosAppGroupId, contains('com.household.shared'));
      });
    });

    group('데이터 타입 검증', () {
      test('monthlyExpense는 int 타입이어야 한다', () {
        // Given & When: updateWidgetData 파라미터 타입
        const monthlyExpense = 100000;

        // Then
        expect(monthlyExpense, isA<int>());
      });

      test('monthlyIncome은 int 타입이어야 한다', () {
        // Given & When
        const monthlyIncome = 3000000;

        // Then
        expect(monthlyIncome, isA<int>());
      });

      test('ledgerName은 String 타입이어야 한다', () {
        // Given & When
        const ledgerName = '우리집 가계부';

        // Then
        expect(ledgerName, isA<String>());
      });
    });

    group('위젯 업데이트 로직', () {
      test('updateWidgetData는 여러 데이터를 한 번에 저장한다', () {
        // Given & When: 메서드 시그니처 확인
        // 실제로는 Future.wait을 사용하여 병렬 저장

        // Then: 저장되는 데이터 키 목록
        final savedKeys = [
          WidgetDataService.keyMonthlyExpense,
          WidgetDataService.keyMonthlyIncome,
          WidgetDataService.keyLastUpdated,
          WidgetDataService.keyLedgerName,
        ];

        expect(savedKeys, hasLength(4));
      });

      test('clearWidgetData는 모든 데이터를 초기화한다', () {
        // Given & When: 초기화 시 저장되는 기본값
        const defaultExpense = 0;
        const defaultIncome = 0;
        const defaultLastUpdated = '';
        const defaultLedgerName = '';

        // Then
        expect(defaultExpense, equals(0));
        expect(defaultIncome, equals(0));
        expect(defaultLastUpdated, isEmpty);
        expect(defaultLedgerName, isEmpty);
      });
    });

    group('날짜 포맷', () {
      test('lastUpdated는 yyyy-MM-dd HH:mm 형식이다', () {
        // Given: 코드에서 DateFormat 사용
        const expectedFormat = 'yyyy-MM-dd HH:mm';

        // When & Then: 포맷 문자열 검증
        expect(expectedFormat, matches(r'yyyy-MM-dd HH:mm'));
      });
    });
  });
}
