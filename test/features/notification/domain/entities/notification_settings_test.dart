import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_settings.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

void main() {
  group('NotificationSettings', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final notificationSettings = NotificationSettings(
      id: 'test-id',
      userId: 'user-id',
      notificationType: NotificationType.transactionAdded,
      enabled: true,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('생성자가 올바르게 작동한다', () {
      expect(notificationSettings.id, 'test-id');
      expect(notificationSettings.userId, 'user-id');
      expect(notificationSettings.notificationType, NotificationType.transactionAdded);
      expect(notificationSettings.enabled, true);
      expect(notificationSettings.createdAt, testCreatedAt);
      expect(notificationSettings.updatedAt, testUpdatedAt);
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = notificationSettings.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.userId, 'user-id');
        expect(copied.notificationType, NotificationType.transactionAdded);
        expect(copied.enabled, true);
        expect(copied.createdAt, testCreatedAt);
        expect(copied.updatedAt, testUpdatedAt);
      });

      test('userId를 변경할 수 있다', () {
        final copied = notificationSettings.copyWith(userId: 'new-user-id');

        expect(copied.id, 'test-id');
        expect(copied.userId, 'new-user-id');
      });

      test('notificationType을 변경할 수 있다', () {
        final copied = notificationSettings.copyWith(
          notificationType: NotificationType.inviteReceived,
        );

        expect(copied.notificationType, NotificationType.inviteReceived);
      });

      test('enabled를 변경할 수 있다', () {
        final copied = notificationSettings.copyWith(enabled: false);

        expect(copied.enabled, false);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = notificationSettings.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('updatedAt을 변경할 수 있다', () {
        final newUpdatedAt = DateTime(2026, 2, 13, 11, 0, 0);
        final copied = notificationSettings.copyWith(updatedAt: newUpdatedAt);

        expect(copied.updatedAt, newUpdatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = notificationSettings.copyWith(
          userId: 'new-user-id',
          enabled: false,
          notificationType: NotificationType.autoCollectSuggested,
        );

        expect(copied.userId, 'new-user-id');
        expect(copied.enabled, false);
        expect(copied.notificationType, NotificationType.autoCollectSuggested);
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 객체를 반환한다', () {
        final copied = notificationSettings.copyWith();

        expect(copied.id, notificationSettings.id);
        expect(copied.userId, notificationSettings.userId);
        expect(copied.notificationType, notificationSettings.notificationType);
        expect(copied.enabled, notificationSettings.enabled);
        expect(copied.createdAt, notificationSettings.createdAt);
        expect(copied.updatedAt, notificationSettings.updatedAt);
      });
    });

    group('Equatable', () {
      test('동일한 값을 가진 인스턴스는 같다', () {
        final settings1 = NotificationSettings(
          id: 'test-id',
          userId: 'user-id',
          notificationType: NotificationType.transactionAdded,
          enabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final settings2 = NotificationSettings(
          id: 'test-id',
          userId: 'user-id',
          notificationType: NotificationType.transactionAdded,
          enabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(settings1, equals(settings2));
        expect(settings1.hashCode, equals(settings2.hashCode));
      });

      test('다른 값을 가진 인스턴스는 다르다', () {
        final settings1 = NotificationSettings(
          id: 'test-id',
          userId: 'user-id',
          notificationType: NotificationType.transactionAdded,
          enabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final settings2 = NotificationSettings(
          id: 'test-id',
          userId: 'user-id',
          notificationType: NotificationType.inviteReceived,
          enabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(settings1, isNot(equals(settings2)));
      });
    });

    group('엣지 케이스', () {
      test('enabled가 false인 경우를 처리할 수 있다', () {
        final settings = NotificationSettings(
          id: 'test-id',
          userId: 'user-id',
          notificationType: NotificationType.transactionDeleted,
          enabled: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(settings.enabled, false);
      });

      test('다양한 NotificationType을 처리할 수 있다', () {
        for (final type in NotificationType.values) {
          final settings = NotificationSettings(
            id: 'test-id',
            userId: 'user-id',
            notificationType: type,
            enabled: true,
            createdAt: testCreatedAt,
            updatedAt: testUpdatedAt,
          );

          expect(settings.notificationType, type);
        }
      });

      test('createdAt과 updatedAt이 동일한 경우를 처리할 수 있다', () {
        final sameTime = DateTime(2026, 2, 12, 10, 0, 0);
        final settings = NotificationSettings(
          id: 'test-id',
          userId: 'user-id',
          notificationType: NotificationType.transactionAdded,
          enabled: true,
          createdAt: sameTime,
          updatedAt: sameTime,
        );

        expect(settings.createdAt, settings.updatedAt);
      });

      test('빈 문자열 ID를 처리할 수 있다', () {
        final settings = NotificationSettings(
          id: '',
          userId: 'user-id',
          notificationType: NotificationType.transactionAdded,
          enabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(settings.id, '');
      });

      test('매우 긴 ID를 처리할 수 있다', () {
        final longId = 'a' * 1000;
        final settings = NotificationSettings(
          id: longId,
          userId: 'user-id',
          notificationType: NotificationType.transactionAdded,
          enabled: true,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(settings.id, longId);
      });
    });
  });
}
