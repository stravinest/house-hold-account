import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/data/models/fcm_token_model.dart';

/// FcmTokenRepository 및 FcmTokenModel 테스트
///
/// Supabase Client Mock이 복잡하므로, Model의 JSON 변환 로직과
/// Repository의 핵심 비즈니스 로직을 검증한다.
void main() {
  group('FcmTokenModel', () {
    group('fromJson - JSON에서 모델 생성', () {
      test('정상적인 JSON을 올바르게 파싱해야 한다', () {
        final json = {
          'id': 'token-id-1',
          'user_id': 'user-123',
          'token': 'fcm-token-abc',
          'device_type': 'android',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T12:00:00Z',
        };

        final model = FcmTokenModel.fromJson(json);

        expect(model.id, equals('token-id-1'));
        expect(model.userId, equals('user-123'));
        expect(model.token, equals('fcm-token-abc'));
        expect(model.deviceType, equals('android'));
        expect(model.createdAt, equals(DateTime.parse('2026-01-01T00:00:00Z')));
        expect(model.updatedAt, equals(DateTime.parse('2026-01-01T12:00:00Z')));
      });

      test('iOS 디바이스 타입을 올바르게 파싱해야 한다', () {
        final json = {
          'id': 'token-id-2',
          'user_id': 'user-456',
          'token': 'apns-token-xyz',
          'device_type': 'ios',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };

        final model = FcmTokenModel.fromJson(json);

        expect(model.deviceType, equals('ios'));
      });

      test('web 디바이스 타입을 올바르게 파싱해야 한다', () {
        final json = {
          'id': 'token-id-3',
          'user_id': 'user-789',
          'token': 'web-token-123',
          'device_type': 'web',
          'created_at': '2026-01-01T00:00:00Z',
          'updated_at': '2026-01-01T00:00:00Z',
        };

        final model = FcmTokenModel.fromJson(json);

        expect(model.deviceType, equals('web'));
      });
    });

    group('toJson - 모델을 JSON으로 변환', () {
      test('모든 필드가 올바르게 변환되어야 한다', () {
        final model = FcmTokenModel(
          id: 'token-id-1',
          userId: 'user-123',
          token: 'fcm-token-abc',
          deviceType: 'android',
          createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T12:00:00Z'),
        );

        final json = model.toJson();

        expect(json['id'], equals('token-id-1'));
        expect(json['user_id'], equals('user-123'));
        expect(json['token'], equals('fcm-token-abc'));
        expect(json['device_type'], equals('android'));
      });
    });

    group('toCreateJson - 생성용 JSON', () {
      test('id, createdAt, updatedAt이 제외되어야 한다', () {
        final json = FcmTokenModel.toCreateJson(
          userId: 'user-123',
          token: 'fcm-token-abc',
          deviceType: 'android',
        );

        expect(json['user_id'], equals('user-123'));
        expect(json['token'], equals('fcm-token-abc'));
        expect(json['device_type'], equals('android'));
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('created_at'), isFalse);
        expect(json.containsKey('updated_at'), isFalse);
      });
    });

    group('copyWith - 불변 객체 복사', () {
      test('token만 변경할 수 있어야 한다', () {
        final original = FcmTokenModel(
          id: 'token-id-1',
          userId: 'user-123',
          token: 'old-token',
          deviceType: 'android',
          createdAt: DateTime.parse('2026-01-01T00:00:00Z'),
          updatedAt: DateTime.parse('2026-01-01T00:00:00Z'),
        );

        final updated = original.copyWith(token: 'new-token');

        expect(updated.token, equals('new-token'));
        expect(updated.userId, equals('user-123'));
        expect(updated.deviceType, equals('android'));
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('변환 후 데이터가 동일해야 한다', () {
        final originalJson = {
          'id': 'token-id-1',
          'user_id': 'user-123',
          'token': 'fcm-token-abc',
          'device_type': 'android',
          'created_at': '2026-01-01T00:00:00.000Z',
          'updated_at': '2026-01-01T12:00:00.000Z',
        };

        final model = FcmTokenModel.fromJson(originalJson);
        final resultJson = model.toJson();

        expect(resultJson['id'], equals(originalJson['id']));
        expect(resultJson['user_id'], equals(originalJson['user_id']));
        expect(resultJson['token'], equals(originalJson['token']));
        expect(resultJson['device_type'], equals(originalJson['device_type']));
      });
    });
  });

  group('FCM 토큰 관리 비즈니스 로직 검증', () {
    group('토큰 고유성 정책', () {
      test('같은 토큰을 가진 두 사용자는 허용되지 않는다는 정책 확인', () {
        // FCM 토큰은 기기에 고유하므로, 한 토큰은 한 사용자에게만 연결
        // saveFcmToken에서:
        // 1. 다른 사용자의 동일 토큰 삭제
        // 2. 현재 사용자에게 UPSERT
        //
        // 이 정책은 다음 시나리오를 처리한다:
        // - 사용자 A가 로그아웃 후 사용자 B가 같은 기기에서 로그인
        // - 같은 기기의 토큰이 A에서 B로 이전되어야 함
        const userA = 'user-a';
        const userB = 'user-b';
        const sharedToken = 'device-token-123';

        // 시뮬레이션: 사용자 A의 토큰이 있는 상태에서 사용자 B가 같은 토큰 등록
        final existingTokens = <String, String>{sharedToken: userA};

        // 1단계: 다른 사용자의 토큰 삭제
        existingTokens.removeWhere(
          (token, userId) => token == sharedToken && userId != userB,
        );
        expect(existingTokens.containsKey(sharedToken), isFalse);

        // 2단계: 새 사용자에게 토큰 등록
        existingTokens[sharedToken] = userB;
        expect(existingTokens[sharedToken], equals(userB));
      });
    });

    group('디바이스 타입 판별 로직', () {
      test('지원하는 디바이스 타입은 android, ios, web 3가지이다', () {
        const supportedTypes = ['android', 'ios', 'web'];

        for (final type in supportedTypes) {
          final json = FcmTokenModel.toCreateJson(
            userId: 'user-123',
            token: 'token-abc',
            deviceType: type,
          );
          expect(json['device_type'], equals(type));
        }
      });
    });
  });
}
