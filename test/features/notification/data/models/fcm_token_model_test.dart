import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/data/models/fcm_token_model.dart';
import 'package:shared_household_account/features/notification/domain/entities/fcm_token.dart';

void main() {
  group('FcmTokenModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final fcmTokenModel = FcmTokenModel(
      id: 'test-id',
      userId: 'user-id',
      token: 'fcm-token-123',
      deviceType: 'android',
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('FcmToken 엔티티를 확장한다', () {
      expect(fcmTokenModel, isA<FcmToken>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'user_id': 'user-id',
          'token': 'fcm-token-456',
          'device_type': 'ios',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.userId, 'user-id');
        expect(result.token, 'fcm-token-456');
        expect(result.deviceType, 'ios');
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
        expect(result.updatedAt, DateTime.parse('2026-02-12T11:00:00.000'));
      });

      test('android 기기 타입을 역직렬화한다', () {
        final json = {
          'id': 'android-id',
          'user_id': 'user-id',
          'token': 'android-token',
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.deviceType, 'android');
        expect(result.isAndroid, true);
        expect(result.isIos, false);
        expect(result.isWeb, false);
      });

      test('ios 기기 타입을 역직렬화한다', () {
        final json = {
          'id': 'ios-id',
          'user_id': 'user-id',
          'token': 'ios-token',
          'device_type': 'ios',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.deviceType, 'ios');
        expect(result.isAndroid, false);
        expect(result.isIos, true);
        expect(result.isWeb, false);
      });

      test('web 기기 타입을 역직렬화한다', () {
        final json = {
          'id': 'web-id',
          'user_id': 'user-id',
          'token': 'web-token',
          'device_type': 'web',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.deviceType, 'web');
        expect(result.isAndroid, false);
        expect(result.isIos, false);
        expect(result.isWeb, true);
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': 'token',
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
        };

        final json2 = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': 'token',
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00',
          'updated_at': '2026-02-12T11:00:00',
        };

        final result1 = FcmTokenModel.fromJson(json1);
        final result2 = FcmTokenModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = fcmTokenModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['user_id'], 'user-id');
        expect(json['token'], 'fcm-token-123');
        expect(json['device_type'], 'android');
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
      });

      test('created_at과 updated_at이 ISO 8601 형식으로 직렬화된다', () {
        final json = fcmTokenModel.toJson();

        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['updated_at'], testUpdatedAt.toIso8601String());
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = fcmTokenModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('user_id'), true);
        expect(json.containsKey('token'), true);
        expect(json.containsKey('device_type'), true);
        expect(json.containsKey('created_at'), true);
        expect(json.containsKey('updated_at'), true);
      });
    });

    group('toCreateJson', () {
      test('생성용 JSON을 올바르게 만든다', () {
        final json = FcmTokenModel.toCreateJson(
          userId: 'new-user-id',
          token: 'new-token',
          deviceType: 'android',
        );

        expect(json['user_id'], 'new-user-id');
        expect(json['token'], 'new-token');
        expect(json['device_type'], 'android');
      });

      test('id, created_at, updated_at은 포함되지 않는다', () {
        final json = FcmTokenModel.toCreateJson(
          userId: 'user-id',
          token: 'token',
          deviceType: 'ios',
        );

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });

      test('다양한 기기 타입으로 생성용 JSON을 만들 수 있다', () {
        final androidJson = FcmTokenModel.toCreateJson(
          userId: 'user-id',
          token: 'android-token',
          deviceType: 'android',
        );

        final iosJson = FcmTokenModel.toCreateJson(
          userId: 'user-id',
          token: 'ios-token',
          deviceType: 'ios',
        );

        final webJson = FcmTokenModel.toCreateJson(
          userId: 'user-id',
          token: 'web-token',
          deviceType: 'web',
        );

        expect(androidJson['device_type'], 'android');
        expect(iosJson['device_type'], 'ios');
        expect(webJson['device_type'], 'web');
      });
    });

    group('copyWith', () {
      test('id를 변경할 수 있다', () {
        final copied = fcmTokenModel.copyWith(id: 'new-id');

        expect(copied.id, 'new-id');
        expect(copied.userId, 'user-id');
        expect(copied.token, 'fcm-token-123');
        expect(copied.deviceType, 'android');
      });

      test('userId를 변경할 수 있다', () {
        final copied = fcmTokenModel.copyWith(userId: 'new-user-id');

        expect(copied.userId, 'new-user-id');
      });

      test('token을 변경할 수 있다', () {
        final copied = fcmTokenModel.copyWith(token: 'new-token');

        expect(copied.token, 'new-token');
      });

      test('deviceType을 변경할 수 있다', () {
        final copied = fcmTokenModel.copyWith(deviceType: 'ios');

        expect(copied.deviceType, 'ios');
        expect(copied.isIos, true);
      });

      test('createdAt을 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 2, 13, 10, 0, 0);
        final copied = fcmTokenModel.copyWith(createdAt: newCreatedAt);

        expect(copied.createdAt, newCreatedAt);
      });

      test('updatedAt을 변경할 수 있다', () {
        final newUpdatedAt = DateTime(2026, 2, 13, 11, 0, 0);
        final copied = fcmTokenModel.copyWith(updatedAt: newUpdatedAt);

        expect(copied.updatedAt, newUpdatedAt);
      });

      test('여러 필드를 동시에 변경할 수 있다', () {
        final copied = fcmTokenModel.copyWith(
          token: 'updated-token',
          deviceType: 'web',
        );

        expect(copied.token, 'updated-token');
        expect(copied.deviceType, 'web');
        expect(copied.id, 'test-id');
      });

      test('인자 없이 호출하면 동일한 값을 가진 객체를 반환한다', () {
        final copied = fcmTokenModel.copyWith();

        expect(copied.id, fcmTokenModel.id);
        expect(copied.userId, fcmTokenModel.userId);
        expect(copied.token, fcmTokenModel.token);
        expect(copied.deviceType, fcmTokenModel.deviceType);
        expect(copied.createdAt, fcmTokenModel.createdAt);
        expect(copied.updatedAt, fcmTokenModel.updatedAt);
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': 'fcm-token-123',
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final model = FcmTokenModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['user_id'], originalJson['user_id']);
        expect(convertedJson['token'], originalJson['token']);
        expect(convertedJson['device_type'], originalJson['device_type']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 토큰을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': '',
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.token, '');
      });

      test('매우 긴 토큰을 처리할 수 있다', () {
        final longToken = 'a' * 1000;
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': longToken,
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.token, longToken);
      });

      test('특수문자가 포함된 토큰을 처리할 수 있다', () {
        final specialToken = 'abc-123_xyz:456.789';
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': specialToken,
          'device_type': 'android',
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.token, specialToken);
      });

      test('createdAt과 updatedAt이 동일한 경우를 처리할 수 있다', () {
        final sameTime = '2026-02-12T10:00:00.000';
        final json = {
          'id': 'test-id',
          'user_id': 'user-id',
          'token': 'token',
          'device_type': 'android',
          'created_at': sameTime,
          'updated_at': sameTime,
        };

        final result = FcmTokenModel.fromJson(json);

        expect(result.createdAt, result.updatedAt);
      });
    });
  });
}
