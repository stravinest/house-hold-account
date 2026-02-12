import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/data/models/notification_settings_model.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_settings.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

void main() {
  group('NotificationSettingsModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final notificationSettingsModel = NotificationSettingsModel(
      id: 'test-id',
      userId: 'user-id',
      notificationType: NotificationType.transactionAdded,
      enabled: true,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('NotificationSettings 엔티티를 확장한다', () {
      expect(notificationSettingsModel, isA<NotificationSettings>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'user_id': 'user-id',
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = NotificationSettingsModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.userId, 'user-id');
        expect(result.notificationType, NotificationType.transactionAdded);
        expect(result.enabled, true);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
        expect(result.updatedAt, DateTime.parse('2026-02-12T11:00:00.000'));
      });

      test('enabled가 false인 경우를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'notification_type': 'invite_received',
          'enabled': false,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = NotificationSettingsModel.fromJson(json);

        expect(result.enabled, false);
        expect(result.notificationType, NotificationType.inviteReceived);
      });

      test('다양한 NotificationType을 역직렬화한다', () {
        final types = [
          'transaction_added',
          'transaction_updated',
          'transaction_deleted',
          'auto_collect_suggested',
          'auto_collect_saved',
          'invite_received',
          'invite_accepted',
        ];

        for (final typeValue in types) {
          final json = {
            'id': 'test-id',
            'user_id': 'user-id',
            'notification_type': typeValue,
            'enabled': true,
            'created_at': '2026-02-12T10:00:00.000',
            'updated_at': '2026-02-12T11:00:00.000',
          };

          final result = NotificationSettingsModel.fromJson(json);

          expect(result.notificationType.value, typeValue);
        }
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'user_id': 'user-id',
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final json2 = {
          'id': 'test-id',
          'user_id': 'user-id',
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': '2026-02-12T10:00:00',
          'updated_at': '2026-02-12T11:00:00',
        };

        final result1 = NotificationSettingsModel.fromJson(json1);
        final result2 = NotificationSettingsModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = notificationSettingsModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['user_id'], 'user-id');
        expect(json['notification_type'], 'transaction_added');
        expect(json['enabled'], true);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('created_at과 updated_at이 ISO 8601 형식으로 직렬화된다', () {
        final json = notificationSettingsModel.toJson();

        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['updated_at'], testUpdatedAt.toIso8601String());
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = notificationSettingsModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('user_id'), true);
        expect(json.containsKey('notification_type'), true);
        expect(json.containsKey('enabled'), true);
        expect(json.containsKey('created_at'), true);
        expect(json.containsKey('updated_at'), true);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = NotificationSettingsModel.toCreateJson(
          userId: 'new-user-id',
          notificationType: NotificationType.transactionUpdated,
          enabled: false,
        );

        expect(json['user_id'], 'new-user-id');
        expect(json['notification_type'], 'transaction_updated');
        expect(json['enabled'], false);
      });

      test('id, created_at, updated_at은 포함되지 않는다', () {
        final json = NotificationSettingsModel.toCreateJson(
          userId: 'user-id',
          notificationType: NotificationType.inviteReceived,
          enabled: true,
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });

      test('다양한 NotificationType으로 생성용 JSON을 만들 수 있다', () {
        for (final type in NotificationType.values) {
          final json = NotificationSettingsModel.toCreateJson(
            userId: 'user-id',
            notificationType: type,
            enabled: true,
          );

          expect(json['notification_type'], type.value);
        }
      });
    });

    group('toUpdateJson', () {
      test('업데이트용 JSON을 올바르게 만든다', () {
        final json = NotificationSettingsModel.toUpdateJson(enabled: false);

        expect(json['enabled'], false);
      });

      test('enabled만 포함된다', () {
        final json = NotificationSettingsModel.toUpdateJson(enabled: true);

        expect(json.containsKey('enabled'), true);
        expect(json.containsKey('id'), false);
        expect(json.containsKey('user_id'), false);
        expect(json.containsKey('notification_type'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });

      test('true와 false 값을 모두 처리할 수 있다', () {
        final trueJson = NotificationSettingsModel.toUpdateJson(enabled: true);
        final falseJson = NotificationSettingsModel.toUpdateJson(enabled: false);

        expect(trueJson['enabled'], true);
        expect(falseJson['enabled'], false);
      });
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = notificationSettingsModel.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.userId, 'user-id');
      });

      test('userId를 변경할 수 있다', () {
        final copied = notificationSettingsModel.copyWith(userId: 'new-user-id');

        expect(copied.userId, 'new-user-id');
      });

      test('notificationType을 변경할 수 있다', () {
        final copied = notificationSettingsModel.copyWith(
          notificationType: NotificationType.inviteReceived,
        );

        expect(copied.notificationType, NotificationType.inviteReceived);
      });

      test('enabled를 변경할 수 있다', () {
        final copied = notificationSettingsModel.copyWith(enabled: false);

        expect(copied.enabled, false);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = notificationSettingsModel.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('updatedAt을 변경할 수 있다', () {
        final newUpdatedAt = DateTime(2026, 2, 13, 11, 0, 0);
        final copied = notificationSettingsModel.copyWith(updatedAt: newUpdatedAt);

        expect(copied.updatedAt, newUpdatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = notificationSettingsModel.copyWith(
          userId: 'new-user-id',
          enabled: false,
        );

        expect(copied.userId, 'new-user-id');
        expect(copied.enabled, false);
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 값을 가진 객체를 반환한다', () {
        final copied = notificationSettingsModel.copyWith();

        expect(copied.id, notificationSettingsModel.id);
        expect(copied.userId, notificationSettingsModel.userId);
        expect(copied.notificationType, notificationSettingsModel.notificationType);
        expect(copied.enabled, notificationSettingsModel.enabled);
        expect(copied.createdAt, notificationSettingsModel.createdAt);
        expect(copied.updatedAt, notificationSettingsModel.updatedAt);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'user_id': 'user-id',
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final model = NotificationSettingsModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['user_id'], originalJson['user_id']);
        expect(convertedJson['notification_type'], originalJson['notification_type']);
        expect(convertedJson['enabled'], originalJson['enabled']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 ID를 처리할 수 있다', () {
        final json = {
          'id': '',
          'user_id': 'user-id',
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = NotificationSettingsModel.fromJson(json);

        expect(result.id, '');
      });

      test('매우 긴 userId를 처리할 수 있다', () {
        final longUserId = 'u' * 1000;
        final json = {
          'id': 'test-id',
          'user_id': longUserId,
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = NotificationSettingsModel.fromJson(json);

        expect(result.userId, longUserId);
      });

      test('createdAt과 updatedAt이 동일한 경우를 처리할 수 있다', () {
        final sameTime = '2026-02-12T10:00:00.000';
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'notification_type': 'transaction_added',
          'enabled': true,
          'created_at': sameTime,
          'updated_at': sameTime,
        };

        final result = NotificationSettingsModel.fromJson(json);

        expect(result.createdAt, result.updatedAt);
      });
    });
  });
}
