import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/notification/data/models/fcm_token_model.dart';
import 'package:shared_household_account/features/notification/presentation/providers/fcm_token_provider.dart';

import '../../../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  group('FcmTokenProvider Tests', () {
    late MockFcmTokenRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockFcmTokenRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('FcmToken', () {
      test('사용자가 로그인하지 않은 경우 빈 리스트를 반환한다', () async {
        // Given: 로그인하지 않은 상태
        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            fcmTokenRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final tokens = await container.read(fcmTokenProvider.future);

        // Then
        expect(tokens, isEmpty);
        verifyNever(() => mockRepository.getFcmTokens(any()));
      });

      test('로그인한 사용자의 FCM 토큰 목록을 가져온다', () async {
        // Given
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        final now = DateTime.now();
        final mockTokens = <FcmTokenModel>[
          FcmTokenModel(
            id: 'token-1',
            userId: 'test-user-id',
            token: 'fcm-token-1',
            deviceType: 'android',
            createdAt: now,
            updatedAt: now,
          ),
          FcmTokenModel(
            id: 'token-2',
            userId: 'test-user-id',
            token: 'fcm-token-2',
            deviceType: 'ios',
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockRepository.getFcmTokens('test-user-id'))
            .thenAnswer((_) async => mockTokens);

        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            fcmTokenRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final tokens = await container.read(fcmTokenProvider.future);

        // Then
        expect(tokens.length, equals(2));
        expect(tokens[0].token, equals('fcm-token-1'));
        expect(tokens[1].token, equals('fcm-token-2'));
        verify(() => mockRepository.getFcmTokens('test-user-id')).called(1);
      });

      test('saveFcmToken은 토큰을 저장하고 목록을 갱신한다', () async {
        // Given
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        final now = DateTime.now();
        final savedToken = FcmTokenModel(
          id: 'token-new',
          userId: 'test-user-id',
          token: 'fcm-token-new',
          deviceType: 'android',
          createdAt: now,
          updatedAt: now,
        );

        when(
          () => mockRepository.saveFcmToken(
            userId: 'test-user-id',
            token: 'fcm-token-new',
            deviceType: 'android',
          ),
        ).thenAnswer((_) async => {});

        when(() => mockRepository.getFcmTokens('test-user-id'))
            .thenAnswer((_) async => [savedToken]);

        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            fcmTokenRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(fcmTokenProvider.notifier);

        // When
        await notifier.saveFcmToken(
          token: 'fcm-token-new',
          deviceType: 'android',
        );

        // Then
        verify(
          () => mockRepository.saveFcmToken(
            userId: 'test-user-id',
            token: 'fcm-token-new',
            deviceType: 'android',
          ),
        ).called(1);
        verify(() => mockRepository.getFcmTokens('test-user-id')).called(2);

        final state = notifier.state;
        expect(state.hasValue, isTrue);
        expect(state.value?.length, equals(1));
      });

      test('로그인하지 않은 상태에서 saveFcmToken 호출 시 예외를 발생시킨다', () async {
        // Given
        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            fcmTokenRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(fcmTokenProvider.notifier);

        // When & Then
        expect(
          () => notifier.saveFcmToken(
            token: 'fcm-token-new',
            deviceType: 'android',
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('deleteFcmToken은 토큰을 삭제하고 목록을 갱신한다', () async {
        // Given
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        when(() => mockRepository.deleteFcmToken('fcm-token-1'))
            .thenAnswer((_) async => {});

        when(() => mockRepository.getFcmTokens('test-user-id'))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            fcmTokenRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(fcmTokenProvider.notifier);

        // When
        await notifier.deleteFcmToken('fcm-token-1');

        // Then
        verify(() => mockRepository.deleteFcmToken('fcm-token-1')).called(1);
        verify(() => mockRepository.getFcmTokens('test-user-id')).called(2);

        final state = notifier.state;
        expect(state.hasValue, isTrue);
        expect(state.value, isEmpty);
      });

      test('로그인하지 않은 상태에서 deleteFcmToken 호출 시 예외를 발생시킨다', () async {
        // Given
        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            fcmTokenRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(fcmTokenProvider.notifier);

        // When & Then
        expect(
          () => notifier.deleteFcmToken('fcm-token-1'),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
