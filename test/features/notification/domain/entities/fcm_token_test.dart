import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/fcm_token.dart';

void main() {
  group('FcmToken', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final fcmToken = FcmToken(
      id: 'test-id',
      userId: 'user-id',
      token: 'fcm-token-12345',
      deviceType: 'android',
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    group('getter 테스트', () {
      test('isAndroid는 deviceType이 android일 때 true를 반환한다', () {
        final androidToken = FcmToken(
          id: 'test-id',
          userId: 'user-id',
          token: 'token',
          deviceType: 'android',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(androidToken.isAndroid, true);
        expect(androidToken.isIos, false);
        expect(androidToken.isWeb, false);
      });

      test('isIos는 deviceType이 ios일 때 true를 반환한다', () {
        final iosToken = fcmToken.copyWith(deviceType: 'ios');

        expect(iosToken.isIos, true);
        expect(iosToken.isAndroid, false);
        expect(iosToken.isWeb, false);
      });

      test('isWeb은 deviceType이 web일 때 true를 반환한다', () {
        final webToken = fcmToken.copyWith(deviceType: 'web');

        expect(webToken.isWeb, true);
        expect(webToken.isAndroid, false);
        expect(webToken.isIos, false);
      });
    });

    group('copyWith', () {
      test('특정 필드만 변경할 수 있다', () {
        final updated = fcmToken.copyWith(
          token: 'new-token-67890',
          deviceType: 'ios',
        );

        expect(updated.token, 'new-token-67890');
        expect(updated.deviceType, 'ios');
        expect(updated.id, fcmToken.id);
        expect(updated.userId, fcmToken.userId);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 3, 1);
        final newUpdatedAt = DateTime(2026, 3, 2);

        final updated = fcmToken.copyWith(
          id: 'new-id',
          userId: 'new-user-id',
          token: 'new-token',
          deviceType: 'web',
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
        );

        expect(updated.id, 'new-id');
        expect(updated.userId, 'new-user-id');
        expect(updated.token, 'new-token');
        expect(updated.deviceType, 'web');
        expect(updated.createdAt, newCreatedAt);
        expect(updated.updatedAt, newUpdatedAt);
      });

      test('인자를 제공하지 않으면 원본과 동일한 값을 유지한다', () {
        final copied = fcmToken.copyWith();

        expect(copied.id, fcmToken.id);
        expect(copied.userId, fcmToken.userId);
        expect(copied.token, fcmToken.token);
        expect(copied.deviceType, fcmToken.deviceType);
      });
    });

    group('Equatable', () {
      test('동일한 값을 가진 인스턴스는 같다', () {
        final token1 = FcmToken(
          id: 'test-id',
          userId: 'user-id',
          token: 'token',
          deviceType: 'android',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final token2 = FcmToken(
          id: 'test-id',
          userId: 'user-id',
          token: 'token',
          deviceType: 'android',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(token1, token2);
      });

      test('다른 값을 가진 인스턴스는 다르다', () {
        final token1 = fcmToken;
        final token2 = fcmToken.copyWith(id: 'different-id');

        expect(token1, isNot(token2));
      });
    });

    group('엣지 케이스', () {
      test('다양한 deviceType을 지원한다', () {
        final androidToken = fcmToken.copyWith(deviceType: 'android');
        final iosToken = fcmToken.copyWith(deviceType: 'ios');
        final webToken = fcmToken.copyWith(deviceType: 'web');

        expect(androidToken.deviceType, 'android');
        expect(iosToken.deviceType, 'ios');
        expect(webToken.deviceType, 'web');
      });

      test('매우 긴 토큰을 처리할 수 있다', () {
        final longToken = 'a' * 1000;
        final token = fcmToken.copyWith(token: longToken);

        expect(token.token, longToken);
      });

      test('빈 문자열 토큰을 처리할 수 있다', () {
        final token = fcmToken.copyWith(token: '');

        expect(token.token, '');
      });
    });
  });
}
