import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/push_notification.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

void main() {
  group('PushNotification', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testData = {'key1': 'value1', 'key2': 123};

    final pushNotification = PushNotification(
      id: 'test-id',
      userId: 'user-id',
      type: NotificationType.transactionAdded,
      title: '새로운 거래',
      message: '거래가 추가되었습니다',
      data: testData,
      isRead: false,
      createdAt: testCreatedAt,
    );

    test('생성자가 올바르게 작동한다', () {
      expect(pushNotification.id, 'test-id');
      expect(pushNotification.userId, 'user-id');
      expect(pushNotification.type, NotificationType.transactionAdded);
      expect(pushNotification.title, '새로운 거래');
      expect(pushNotification.message, '거래가 추가되었습니다');
      expect(pushNotification.data, testData);
      expect(pushNotification.isRead, false);
      expect(pushNotification.createdAt, testCreatedAt);
    });

    test('data가 null인 경우를 처리할 수 있다', () {
      final notification = PushNotification(
        id: 'test-id',
        userId: 'user-id',
        type: NotificationType.inviteReceived,
        title: '초대 받음',
        message: '초대를 받았습니다',
        data: null,
        isRead: false,
        createdAt: testCreatedAt,
      );

      expect(notification.data, null);
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = pushNotification.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.userId, 'user-id');
        expect(copied.type, NotificationType.transactionAdded);
        expect(copied.title, '새로운 거래');
        expect(copied.message, '거래가 추가되었습니다');
        expect(copied.data, testData);
        expect(copied.isRead, false);
        expect(copied.createdAt, testCreatedAt);
      });

      test('userId를 변경할 수 있다', () {
        final copied = pushNotification.copyWith(userId: 'new-user-id');

        expect(copied.userId, 'new-user-id');
      });

      test('type을 변경할 수 있다', () {
        final copied = pushNotification.copyWith(
          type: NotificationType.transactionDeleted,
        );

        expect(copied.type, NotificationType.transactionDeleted);
      });

      test('title을 변경할 수 있다', () {
        final copied = pushNotification.copyWith(title: '새 제목');

        expect(copied.title, '새 제목');
      });

      test('message를 변경할 수 있다', () {
        final copied = pushNotification.copyWith(message: '새 메시지');

        expect(copied.message, '새 메시지');
      });

      test('data를 변경할 수 있다', () {
        final newData = {'newKey': 'newValue'};
        final copied = pushNotification.copyWith(data: newData);

        expect(copied.data, newData);
      });

      test('isRead를 변경할 수 있다', () {
        final copied = pushNotification.copyWith(isRead: true);

        expect(copied.isRead, true);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = pushNotification.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = pushNotification.copyWith(
          title: '업데이트된 제목',
          message: '업데이트된 메시지',
          isRead: true,
        );

        expect(copied.title, '업데이트된 제목');
        expect(copied.message, '업데이트된 메시지');
        expect(copied.isRead, true);
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 객체를 반환한다', () {
        final copied = pushNotification.copyWith();

        expect(copied.id, pushNotification.id);
        expect(copied.userId, pushNotification.userId);
        expect(copied.type, pushNotification.type);
        expect(copied.title, pushNotification.title);
        expect(copied.message, pushNotification.message);
        expect(copied.data, pushNotification.data);
        expect(copied.isRead, pushNotification.isRead);
        expect(copied.createdAt, pushNotification.createdAt);
      });
    });

    group('Equatable', () {
      test('동일한 값을 가진 인스턴스는 같다', () {
        final notification1 = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          data: testData,
          isRead: false,
          createdAt: testCreatedAt,
        );

        final notification2 = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          data: testData,
          isRead: false,
          createdAt: testCreatedAt,
        );

        expect(notification1, equals(notification2));
        expect(notification1.hashCode, equals(notification2.hashCode));
      });

      test('다른 값을 가진 인스턴스는 다르다', () {
        final notification1 = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          data: testData,
          isRead: false,
          createdAt: testCreatedAt,
        );

        final notification2 = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          data: testData,
          isRead: true,
          createdAt: testCreatedAt,
        );

        expect(notification1, isNot(equals(notification2)));
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 제목과 메시지를 처리할 수 있다', () {
        final notification = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '',
          message: '',
          data: null,
          isRead: false,
          createdAt: testCreatedAt,
        );

        expect(notification.title, '');
        expect(notification.message, '');
      });

      test('매우 긴 제목과 메시지를 처리할 수 있다', () {
        final longText = '가' * 1000;
        final notification = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: longText,
          message: longText,
          data: null,
          isRead: false,
          createdAt: testCreatedAt,
        );

        expect(notification.title, longText);
        expect(notification.message, longText);
      });

      test('복잡한 data 구조를 처리할 수 있다', () {
        final complexData = {
          'nested': {'key': 'value'},
          'array': [1, 2, 3],
          'boolean': true,
          'null': null,
        };

        final notification = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.autoCollectSuggested,
          title: '제목',
          message: '메시지',
          data: complexData,
          isRead: false,
          createdAt: testCreatedAt,
        );

        expect(notification.data, complexData);
        expect(notification.data!['nested'], {'key': 'value'});
        expect(notification.data!['array'], [1, 2, 3]);
      });

      test('다양한 NotificationType을 처리할 수 있다', () {
        for (final type in NotificationType.values) {
          final notification = PushNotification(
            id: 'test-id',
            userId: 'user-id',
            type: type,
            title: '제목',
            message: '메시지',
            data: null,
            isRead: false,
            createdAt: testCreatedAt,
          );

          expect(notification.type, type);
        }
      });

      test('isRead가 true인 경우를 처리할 수 있다', () {
        final notification = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.inviteAccepted,
          title: '제목',
          message: '메시지',
          data: null,
          isRead: true,
          createdAt: testCreatedAt,
        );

        expect(notification.isRead, true);
      });

      test('빈 data 맵을 처리할 수 있다', () {
        final notification = PushNotification(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          data: {},
          isRead: false,
          createdAt: testCreatedAt,
        );

        expect(notification.data, {});
        expect(notification.data!.isEmpty, true);
      });
    });
  });
}
