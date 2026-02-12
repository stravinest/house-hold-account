import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/data/models/push_notification_model.dart';
import 'package:shared_household_account/features/notification/domain/entities/push_notification.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

void main() {
  group('PushNotificationModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testData = {'key1': 'value1', 'key2': 123};

    final pushNotificationModel = PushNotificationModel(
      id: 'test-id',
      userId: 'user-id',
      type: NotificationType.transactionAdded,
      title: '새로운 거래',
      message: '거래가 추가되었습니다',
      data: testData,
      isRead: false,
      createdAt: testCreatedAt,
    );

    test('PushNotification 엔티티를 확장한다', () {
      expect(pushNotificationModel, isA<PushNotification>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.userId, 'user-id');
        expect(result.type, NotificationType.transactionAdded);
        expect(result.title, '제목');
        expect(result.message, '본문');
        expect(result.data, null);
        expect(result.isRead, false);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
      });

      test('data가 JSON 문자열인 경우 파싱한다', () {
        final dataMap = {'key': 'value', 'number': 42};
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': jsonEncode(dataMap),
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.data, dataMap);
        expect(result.data!['key'], 'value');
        expect(result.data!['number'], 42);
      });

      test('data가 Map인 경우 그대로 사용한다', () {
        final dataMap = {'key': 'value', 'number': 42};
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': dataMap,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.data, dataMap);
      });

      test('data가 null인 경우를 처리한다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'invite_received',
          'title': '제목',
          'body': '본문',
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.data, null);
      });

      test('isRead가 true인 경우를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_updated',
          'title': '제목',
          'body': '본문',
          'data': null,
          'is_read': true,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.isRead, true);
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
            'type': typeValue,
            'title': '제목',
            'body': '본문',
            'data': null,
            'is_read': false,
            'created_at': '2026-02-12T10:00:00.000',
          };

          final result = PushNotificationModel.fromJson(json);

          expect(result.type.value, typeValue);
        }
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000Z',
        };

        final json2 = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00',
        };

        final result1 = PushNotificationModel.fromJson(json1);
        final result2 = PushNotificationModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = pushNotificationModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['user_id'], 'user-id');
        expect(json['type'], 'transaction_added');
        expect(json['title'], '새로운 거래');
        expect(json['body'], '거래가 추가되었습니다');
        expect(json['data'], isA<String>());
        expect(json['is_read'], false);
        expect(json['created_at'], isA<String>());
      });

      test('data가 JSON 문자열로 인코딩된다', () {
        final json = pushNotificationModel.toJson();

        expect(json['data'], jsonEncode(testData));
        final decodedData = jsonDecode(json['data']) as Map<String, dynamic>;
        expect(decodedData['key1'], 'value1');
        expect(decodedData['key2'], 123);
      });

      test('data가 null인 경우 null로 직렬화된다', () {
        final notification = PushNotificationModel(
          id: 'test-id',
          userId: 'user-id',
          type: NotificationType.inviteReceived,
          title: '제목',
          message: '본문',
          data: null,
          isRead: false,
          createdAt: testCreatedAt,
        );

        final json = notification.toJson();

        expect(json['data'], null);
      });

      test('created_at이 ISO 8601 형식으로 직렬화된다', () {
        final json = pushNotificationModel.toJson();

        expect(json['created_at'], testCreatedAt.toIso8601String());
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = pushNotificationModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('user_id'), true);
        expect(json.containsKey('type'), true);
        expect(json.containsKey('title'), true);
        expect(json.containsKey('body'), true);
        expect(json.containsKey('data'), true);
        expect(json.containsKey('is_read'), true);
        expect(json.containsKey('created_at'), true);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = PushNotificationModel.toCreateJson(
          userId: 'new-user-id',
          type: NotificationType.transactionUpdated,
          title: '새 제목',
          message: '새 메시지',
          data: {'key': 'value'},
        );

        expect(json['user_id'], 'new-user-id');
        expect(json['type'], 'transaction_updated');
        expect(json['title'], '새 제목');
        expect(json['body'], '새 메시지');
        expect(json['data'], isA<String>());
        expect(json['is_read'], false);
      });

      test('data를 JSON 문자열로 인코딩한다', () {
        final dataMap = {'key': 'value', 'number': 42};
        final json = PushNotificationModel.toCreateJson(
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          data: dataMap,
        );

        expect(json['data'], jsonEncode(dataMap));
      });

      test('data가 null인 경우 null로 설정한다', () {
        final json = PushNotificationModel.toCreateJson(
          userId: 'user-id',
          type: NotificationType.inviteReceived,
          title: '제목',
          message: '메시지',
          data: null,
        );

        expect(json['data'], null);
      });

      test('isRead 기본값이 false이다', () {
        final json = PushNotificationModel.toCreateJson(
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
        );

        expect(json['is_read'], false);
      });

      test('isRead를 true로 설정할 수 있다', () {
        final json = PushNotificationModel.toCreateJson(
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
          isRead: true,
        );

        expect(json['is_read'], true);
      });

      test('id와 created_at은 포함되지 않는다', () {
        final json = PushNotificationModel.toCreateJson(
          userId: 'user-id',
          type: NotificationType.transactionAdded,
          title: '제목',
          message: '메시지',
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('toReadJson', () {
      test('읽음 상태 업데이트용 JSON을 올바르게 만든다', () {
        final json = PushNotificationModel.toReadJson();

        expect(json['is_read'], true);
      });

      test('is_read만 포함된다', () {
        final json = PushNotificationModel.toReadJson();

        expect(json.containsKey('is_read'), true);
        expect(json.containsKey('id'), false);
        expect(json.containsKey('user_id'), false);
        expect(json.containsKey('type'), false);
        expect(json.containsKey('title'), false);
        expect(json.containsKey('body'), false);
        expect(json.containsKey('data'), false);
        expect(json.containsKey('created_at'), false);
      });
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.userId, 'user-id');
      });

      test('userId를 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(userId: 'new-user-id');

        expect(copied.userId, 'new-user-id');
      });

      test('type을 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(
          type: NotificationType.inviteReceived,
        );

        expect(copied.type, NotificationType.inviteReceived);
      });

      test('title을 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(title: '새 제목');

        expect(copied.title, '새 제목');
      });

      test('message를 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(message: '새 메시지');

        expect(copied.message, '새 메시지');
      });

      test('data를 변경할 수 있다', () {
        final newData = {'newKey': 'newValue'};
        final copied = pushNotificationModel.copyWith(data: newData);

        expect(copied.data, newData);
      });

      test('isRead를 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(isRead: true);

        expect(copied.isRead, true);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = pushNotificationModel.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = pushNotificationModel.copyWith(
          title: '업데이트된 제목',
          isRead: true,
        );

        expect(copied.title, '업데이트된 제목');
        expect(copied.isRead, true);
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 값을 가진 객체를 반환한다', () {
        final copied = pushNotificationModel.copyWith();

        expect(copied.id, pushNotificationModel.id);
        expect(copied.userId, pushNotificationModel.userId);
        expect(copied.type, pushNotificationModel.type);
        expect(copied.title, pushNotificationModel.title);
        expect(copied.message, pushNotificationModel.message);
        expect(copied.data, pushNotificationModel.data);
        expect(copied.isRead, pushNotificationModel.isRead);
        expect(copied.createdAt, pushNotificationModel.createdAt);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다 (data가 null인 경우)', () {
        final originalJson = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final model = PushNotificationModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['user_id'], originalJson['user_id']);
        expect(convertedJson['type'], originalJson['type']);
        expect(convertedJson['title'], originalJson['title']);
        expect(convertedJson['body'], originalJson['body']);
        expect(convertedJson['data'], originalJson['data']);
        expect(convertedJson['is_read'], originalJson['is_read']);
      });

      test('데이터가 손실 없이 변환된다 (data가 Map인 경우)', () {
        final dataMap = {'key': 'value', 'number': 42};
        final originalJson = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': dataMap,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final model = PushNotificationModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        final decodedData = jsonDecode(convertedJson['data']) as Map<String, dynamic>;
        expect(decodedData, dataMap);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 제목과 메시지를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '',
          'body': '',
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.title, '');
        expect(result.message, '');
      });

      test('매우 긴 제목과 메시지를 처리할 수 있다', () {
        final longText = '가' * 1000;
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': longText,
          'body': longText,
          'data': null,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.title, longText);
        expect(result.message, longText);
      });

      test('복잡한 중첩 data 구조를 처리할 수 있다', () {
        final complexData = {
          'nested': {'key': 'value'},
          'array': [1, 2, 3],
          'boolean': true,
          'null': null,
        };

        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'auto_collect_suggested',
          'title': '제목',
          'body': '본문',
          'data': complexData,
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.data!['nested'], {'key': 'value'});
        expect(result.data!['array'], [1, 2, 3]);
        expect(result.data!['boolean'], true);
        expect(result.data!['null'], null);
      });

      test('빈 data 맵을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': <String, dynamic>{},
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.data, isNotNull);
        expect(result.data, isA<Map<String, dynamic>>());
        expect(result.data!.isEmpty, true);
      });

      test('data가 JSON 문자열 "{}"인 경우를 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'type': 'transaction_added',
          'title': '제목',
          'body': '본문',
          'data': '{}',
          'is_read': false,
          'created_at': '2026-02-12T10:00:00.000',
        };

        final result = PushNotificationModel.fromJson(json);

        expect(result.data, {});
        expect(result.data!.isEmpty, true);
      });
    });
  });
}
