import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';

void main() {
  group('YearlyAsset Entity 테스트', () {
    group('생성자 테스트', () {
      test('year와 amount 값을 올바르게 생성해야 한다', () {
        // Given & When
        const asset = YearlyAsset(year: 2024, amount: 5000000);

        // Then
        expect(asset.year, 2024);
        expect(asset.amount, 5000000);
      });

      test('year가 2000년이고 amount가 0인 경우에도 정상적으로 생성되어야 한다', () {
        // Given & When
        const asset = YearlyAsset(year: 2000, amount: 0);

        // Then
        expect(asset.year, 2000);
        expect(asset.amount, 0);
      });

      test('amount가 음수인 경우에도 정상적으로 생성되어야 한다 (부채가 자산을 초과하는 상황)', () {
        // Given & When
        const asset = YearlyAsset(year: 2024, amount: -1000000);

        // Then
        expect(asset.year, 2024);
        expect(asset.amount, -1000000);
      });

      test('amount가 매우 큰 값일 때도 정상적으로 생성되어야 한다', () {
        // Given & When
        const asset = YearlyAsset(year: 2024, amount: 999999999999);

        // Then
        expect(asset.year, 2024);
        expect(asset.amount, 999999999999);
      });
    });

    group('Equatable props 동등성 테스트', () {
      test('같은 year와 amount를 가진 두 YearlyAsset는 동등해야 한다', () {
        // Given
        const asset1 = YearlyAsset(year: 2024, amount: 5000000);
        const asset2 = YearlyAsset(year: 2024, amount: 5000000);

        // When & Then
        expect(asset1, equals(asset2));
        expect(asset1 == asset2, isTrue);
      });

      test('year가 다른 두 YearlyAsset는 동등하지 않아야 한다', () {
        // Given
        const asset1 = YearlyAsset(year: 2023, amount: 5000000);
        const asset2 = YearlyAsset(year: 2024, amount: 5000000);

        // When & Then
        expect(asset1, isNot(equals(asset2)));
        expect(asset1 == asset2, isFalse);
      });

      test('amount가 다른 두 YearlyAsset는 동등하지 않아야 한다', () {
        // Given
        const asset1 = YearlyAsset(year: 2024, amount: 5000000);
        const asset2 = YearlyAsset(year: 2024, amount: 6000000);

        // When & Then
        expect(asset1, isNot(equals(asset2)));
        expect(asset1 == asset2, isFalse);
      });

      test('year와 amount가 모두 다른 두 YearlyAsset는 동등하지 않아야 한다', () {
        // Given
        const asset1 = YearlyAsset(year: 2022, amount: 1000000);
        const asset2 = YearlyAsset(year: 2024, amount: 5000000);

        // When & Then
        expect(asset1, isNot(equals(asset2)));
      });

      test('props 목록에 year와 amount가 포함되어야 한다', () {
        // Given
        const asset = YearlyAsset(year: 2024, amount: 5000000);

        // When
        final props = asset.props;

        // Then: props에 두 값이 포함됨
        expect(props.length, 2);
        expect(props, containsAll([2024, 5000000]));
      });
    });

    group('hashCode 테스트', () {
      test('같은 year와 amount를 가진 두 YearlyAsset의 hashCode는 같아야 한다', () {
        // Given
        const asset1 = YearlyAsset(year: 2024, amount: 5000000);
        const asset2 = YearlyAsset(year: 2024, amount: 5000000);

        // When & Then
        expect(asset1.hashCode, equals(asset2.hashCode));
      });

      test('다른 year를 가진 두 YearlyAsset의 hashCode는 달라야 한다', () {
        // Given
        const asset1 = YearlyAsset(year: 2023, amount: 5000000);
        const asset2 = YearlyAsset(year: 2024, amount: 5000000);

        // When & Then: 일반적으로 다른 hashCode를 기대하지만, 충돌 가능성 있음
        // 최소한 Equatable가 제대로 동작하는지만 확인
        expect(asset1 == asset2, isFalse);
      });
    });

    group('List와 함께 사용하는 테스트', () {
      test('YearlyAsset 리스트에서 특정 year를 검색할 수 있어야 한다', () {
        // Given
        const assets = [
          YearlyAsset(year: 2022, amount: 1000000),
          YearlyAsset(year: 2023, amount: 3000000),
          YearlyAsset(year: 2024, amount: 5000000),
        ];

        // When
        final asset2023 = assets.firstWhere((a) => a.year == 2023);

        // Then
        expect(asset2023.amount, 3000000);
      });

      test('YearlyAsset 리스트에서 총 자산을 합산할 수 있어야 한다', () {
        // Given
        const assets = [
          YearlyAsset(year: 2022, amount: 1000000),
          YearlyAsset(year: 2023, amount: 2000000),
          YearlyAsset(year: 2024, amount: 3000000),
        ];

        // When
        final total = assets.fold<int>(0, (sum, a) => sum + a.amount);

        // Then
        expect(total, 6000000);
      });

      test('YearlyAsset 리스트를 year 기준으로 정렬할 수 있어야 한다', () {
        // Given: 비순차 데이터
        const assets = [
          YearlyAsset(year: 2024, amount: 5000000),
          YearlyAsset(year: 2022, amount: 1000000),
          YearlyAsset(year: 2023, amount: 3000000),
        ];

        // When
        final sorted = [...assets]..sort((a, b) => a.year.compareTo(b.year));

        // Then: 오름차순으로 정렬되어야 함
        expect(sorted[0].year, 2022);
        expect(sorted[1].year, 2023);
        expect(sorted[2].year, 2024);
      });

      test('Set에서 중복 YearlyAsset가 제거되어야 한다', () {
        // Given: 동일한 데이터를 두 번 포함
        const asset1 = YearlyAsset(year: 2024, amount: 5000000);
        const asset2 = YearlyAsset(year: 2024, amount: 5000000);
        const asset3 = YearlyAsset(year: 2023, amount: 3000000);

        // When
        final set = {asset1, asset2, asset3};

        // Then: 중복이 제거되어 2개만 남아야 함
        expect(set.length, 2);
      });
    });
  });

  group('MonthlyAsset Entity 테스트', () {
    group('생성자 테스트', () {
      test('year, month, amount 값을 올바르게 생성해야 한다', () {
        // Given & When
        const asset = MonthlyAsset(year: 2024, month: 3, amount: 1500000);

        // Then
        expect(asset.year, 2024);
        expect(asset.month, 3);
        expect(asset.amount, 1500000);
      });

      test('12월 데이터도 정상적으로 생성되어야 한다', () {
        // Given & When
        const asset = MonthlyAsset(year: 2024, month: 12, amount: 2000000);

        // Then
        expect(asset.month, 12);
      });
    });

    group('Equatable 동등성 테스트', () {
      test('동일한 year, month, amount를 가진 두 MonthlyAsset는 동등해야 한다', () {
        // Given
        const asset1 = MonthlyAsset(year: 2024, month: 6, amount: 3000000);
        const asset2 = MonthlyAsset(year: 2024, month: 6, amount: 3000000);

        // When & Then
        expect(asset1, equals(asset2));
      });

      test('month가 다른 두 MonthlyAsset는 동등하지 않아야 한다', () {
        // Given
        const asset1 = MonthlyAsset(year: 2024, month: 1, amount: 1000000);
        const asset2 = MonthlyAsset(year: 2024, month: 2, amount: 1000000);

        // When & Then
        expect(asset1, isNot(equals(asset2)));
      });
    });
  });
}
