import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';

void main() {
  group('AutoSaveMode Enum', () {
    test('fromString이 올바른 enum 값을 반환한다', () {
      expect(AutoSaveMode.fromString('manual'), AutoSaveMode.manual);
      expect(AutoSaveMode.fromString('suggest'), AutoSaveMode.suggest);
      expect(AutoSaveMode.fromString('auto'), AutoSaveMode.auto);
    });

    test('알 수 없는 값은 manual로 기본 설정된다', () {
      expect(AutoSaveMode.fromString('unknown'), AutoSaveMode.manual);
      expect(AutoSaveMode.fromString(''), AutoSaveMode.manual);
      expect(AutoSaveMode.fromString('MANUAL'), AutoSaveMode.manual);
    });

    test('toJson이 올바른 문자열을 반환한다', () {
      expect(AutoSaveMode.manual.toJson(), 'manual');
      expect(AutoSaveMode.suggest.toJson(), 'suggest');
      expect(AutoSaveMode.auto.toJson(), 'auto');
    });
  });

  group('AutoCollectSource Enum', () {
    test('fromString이 올바른 enum 값을 반환한다', () {
      expect(AutoCollectSource.fromString('sms'), AutoCollectSource.sms);
      expect(AutoCollectSource.fromString('push'), AutoCollectSource.push);
    });

    test('알 수 없는 값은 sms로 기본 설정된다', () {
      expect(AutoCollectSource.fromString('unknown'), AutoCollectSource.sms);
      expect(AutoCollectSource.fromString(''), AutoCollectSource.sms);
      expect(AutoCollectSource.fromString('SMS'), AutoCollectSource.sms);
    });

    test('toJson이 올바른 문자열을 반환한다', () {
      expect(AutoCollectSource.sms.toJson(), 'sms');
      expect(AutoCollectSource.push.toJson(), 'push');
    });
  });

  group('PaymentMethod Entity', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final paymentMethod = PaymentMethod(
      id: 'payment-id',
      ledgerId: 'ledger-id',
      ownerUserId: 'owner-id',
      name: '신한카드',
      icon: '💳',
      color: '#4A90E2',
      isDefault: false,
      sortOrder: 0,
      createdAt: testCreatedAt,
      autoSaveMode: AutoSaveMode.suggest,
      defaultCategoryId: 'category-id',
      canAutoSave: true,
      autoCollectSource: AutoCollectSource.sms,
    );

    test('생성자가 모든 필드를 올바르게 초기화한다', () {
      expect(paymentMethod.id, 'payment-id');
      expect(paymentMethod.ledgerId, 'ledger-id');
      expect(paymentMethod.ownerUserId, 'owner-id');
      expect(paymentMethod.name, '신한카드');
      expect(paymentMethod.icon, '💳');
      expect(paymentMethod.color, '#4A90E2');
      expect(paymentMethod.isDefault, false);
      expect(paymentMethod.sortOrder, 0);
      expect(paymentMethod.createdAt, testCreatedAt);
      expect(paymentMethod.autoSaveMode, AutoSaveMode.suggest);
      expect(paymentMethod.defaultCategoryId, 'category-id');
      expect(paymentMethod.canAutoSave, true);
      expect(paymentMethod.autoCollectSource, AutoCollectSource.sms);
    });

    test('기본값이 올바르게 설정된다', () {
      final minimal = PaymentMethod(
        id: 'payment-id',
        ledgerId: 'ledger-id',
        ownerUserId: 'owner-id',
        name: '현금',
        icon: '💵',
        color: '#00FF00',
        isDefault: true,
        sortOrder: 0,
        createdAt: testCreatedAt,
      );

      expect(minimal.autoSaveMode, AutoSaveMode.manual);
      expect(minimal.defaultCategoryId, null);
      expect(minimal.canAutoSave, true);
      expect(minimal.autoCollectSource, AutoCollectSource.sms);
    });

    group('getter 메서드', () {
      test('isAutoSaveEnabled가 올바르게 동작한다', () {
        final manual = paymentMethod.copyWith(autoSaveMode: AutoSaveMode.manual);
        final suggest = paymentMethod.copyWith(autoSaveMode: AutoSaveMode.suggest);
        final auto = paymentMethod.copyWith(autoSaveMode: AutoSaveMode.auto);

        expect(manual.isAutoSaveEnabled, false);
        expect(suggest.isAutoSaveEnabled, true);
        expect(auto.isAutoSaveEnabled, true);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경된다', () {
        final updated = paymentMethod.copyWith(
          name: 'KB카드',
          color: '#FF0000',
        );

        expect(updated.name, 'KB카드');
        expect(updated.color, '#FF0000');
        expect(updated.id, paymentMethod.id);
        expect(updated.ledgerId, paymentMethod.ledgerId);
        expect(updated.autoSaveMode, paymentMethod.autoSaveMode);
      });

      test('모든 필드를 변경할 수 있다', () {
        final updated = paymentMethod.copyWith(
          id: 'new-id',
          ledgerId: 'new-ledger',
          ownerUserId: 'new-owner',
          name: '새 카드',
          icon: '🏦',
          color: '#00FF00',
          isDefault: true,
          sortOrder: 5,
          createdAt: DateTime(2026, 3, 1),
          autoSaveMode: AutoSaveMode.auto,
          defaultCategoryId: 'new-category',
          canAutoSave: false,
          autoCollectSource: AutoCollectSource.push,
        );

        expect(updated.id, 'new-id');
        expect(updated.ledgerId, 'new-ledger');
        expect(updated.ownerUserId, 'new-owner');
        expect(updated.name, '새 카드');
        expect(updated.icon, '🏦');
        expect(updated.color, '#00FF00');
        expect(updated.isDefault, true);
        expect(updated.sortOrder, 5);
        expect(updated.autoSaveMode, AutoSaveMode.auto);
        expect(updated.defaultCategoryId, 'new-category');
        expect(updated.canAutoSave, false);
        expect(updated.autoCollectSource, AutoCollectSource.push);
      });

      test('인자가 없으면 원본과 동일한 객체를 반환한다', () {
        final copied = paymentMethod.copyWith();

        expect(copied.id, paymentMethod.id);
        expect(copied.name, paymentMethod.name);
        expect(copied.autoSaveMode, paymentMethod.autoSaveMode);
      });
    });

    group('Equatable', () {
      test('동일한 속성을 가진 객체는 같다고 판단된다', () {
        final method1 = PaymentMethod(
          id: 'payment-id',
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '신한카드',
          icon: '💳',
          color: '#4A90E2',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        final method2 = PaymentMethod(
          id: 'payment-id',
          ledgerId: 'ledger-id',
          ownerUserId: 'owner-id',
          name: '신한카드',
          icon: '💳',
          color: '#4A90E2',
          isDefault: false,
          sortOrder: 0,
          createdAt: testCreatedAt,
        );

        expect(method1, method2);
      });

      test('다른 속성을 가진 객체는 다르다고 판단된다', () {
        final method1 = paymentMethod.copyWith(id: 'id-1');
        final method2 = paymentMethod.copyWith(id: 'id-2');

        expect(method1, isNot(method2));
      });
    });

    group('엣지 케이스', () {
      test('다양한 AutoSaveMode를 지원한다', () {
        final manual = paymentMethod.copyWith(autoSaveMode: AutoSaveMode.manual);
        final suggest = paymentMethod.copyWith(autoSaveMode: AutoSaveMode.suggest);
        final auto = paymentMethod.copyWith(autoSaveMode: AutoSaveMode.auto);

        expect(manual.autoSaveMode, AutoSaveMode.manual);
        expect(suggest.autoSaveMode, AutoSaveMode.suggest);
        expect(auto.autoSaveMode, AutoSaveMode.auto);
      });

      test('다양한 AutoCollectSource를 지원한다', () {
        final sms = paymentMethod.copyWith(autoCollectSource: AutoCollectSource.sms);
        final push = paymentMethod.copyWith(autoCollectSource: AutoCollectSource.push);

        expect(sms.autoCollectSource, AutoCollectSource.sms);
        expect(push.autoCollectSource, AutoCollectSource.push);
      });

      test('빈 문자열을 이름으로 사용할 수 있다', () {
        final empty = paymentMethod.copyWith(name: '');

        expect(empty.name, '');
      });

      test('매우 큰 sortOrder 값을 가질 수 있다', () {
        final largeSort = paymentMethod.copyWith(sortOrder: 999999);

        expect(largeSort.sortOrder, 999999);
      });

      test('음수 sortOrder 값을 가질 수 있다', () {
        final negativeSort = paymentMethod.copyWith(sortOrder: -1);

        expect(negativeSort.sortOrder, -1);
      });

      test('canAutoSave가 false일 때도 동작한다', () {
        final noAutoSave = paymentMethod.copyWith(canAutoSave: false);

        expect(noAutoSave.canAutoSave, false);
        expect(noAutoSave.autoSaveMode, AutoSaveMode.suggest);
      });
    });
  });
}
