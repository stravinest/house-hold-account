import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/notification/presentation/providers/notification_settings_provider.dart';

import '../../../../helpers/test_helpers.dart';

class MockUser extends Mock implements User {}

void main() {
  group('NotificationSettingsProvider Tests', () {
    late MockNotificationSettingsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockNotificationSettingsRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('NotificationSettings', () {
      test('사용자가 로그인하지 않은 경우 기본값을 반환한다', () async {
        // Given: 로그인하지 않은 상태
        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            notificationSettingsRepositoryProvider
                .overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final settings =
            await container.read(notificationSettingsProvider.future);

        // Then: 모든 알림 타입이 true로 기본 설정됨
        expect(settings.length, equals(NotificationType.values.length));
        for (final type in NotificationType.values) {
          expect(settings[type], isTrue);
        }
        verifyNever(() => mockRepository.getNotificationSettings(any()));
      });

      test('로그인한 사용자의 알림 설정을 가져온다', () async {
        // Given
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        final mockSettings = <NotificationType, bool>{
          NotificationType.transactionAdded: true,
          NotificationType.transactionUpdated: false,
          NotificationType.inviteReceived: true,
          NotificationType.autoCollectSuggested: false,
        };

        when(() => mockRepository.getNotificationSettings('test-user-id'))
            .thenAnswer((_) async => mockSettings);

        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            notificationSettingsRepositoryProvider
                .overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final settings =
            await container.read(notificationSettingsProvider.future);

        // Then
        expect(settings[NotificationType.transactionAdded], isTrue);
        expect(settings[NotificationType.transactionUpdated], isFalse);
        expect(settings[NotificationType.inviteReceived], isTrue);
        expect(settings[NotificationType.autoCollectSuggested], isFalse);
        verify(() => mockRepository.getNotificationSettings('test-user-id'))
            .called(1);
      });

      test('updateNotificationSetting은 알림 설정을 업데이트하고 상태를 갱신한다',
          () async {
        // Given
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        final initialSettings = <NotificationType, bool>{
          NotificationType.transactionAdded: true,
          NotificationType.inviteReceived: false,
        };

        final updatedSettings = <NotificationType, bool>{
          NotificationType.transactionAdded: true,
          NotificationType.inviteReceived: true,
        };

        when(
          () => mockRepository.updateNotificationSetting(
            userId: 'test-user-id',
            type: NotificationType.inviteReceived,
            enabled: true,
          ),
        ).thenAnswer((_) async => {});

        when(() => mockRepository.getNotificationSettings('test-user-id'))
            .thenAnswer((_) async => initialSettings);

        when(() => mockRepository.getNotificationSettings('test-user-id'))
            .thenAnswer((_) async => updatedSettings);

        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            notificationSettingsRepositoryProvider
                .overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(notificationSettingsProvider.notifier);

        // When
        await notifier.updateNotificationSetting(
          NotificationType.inviteReceived,
          true,
        );

        // Then
        verify(
          () => mockRepository.updateNotificationSetting(
            userId: 'test-user-id',
            type: NotificationType.inviteReceived,
            enabled: true,
          ),
        ).called(1);
        verify(() => mockRepository.getNotificationSettings('test-user-id'))
            .called(2);

        final state = notifier.state;
        expect(state.hasValue, isTrue);
        expect(state.value?[NotificationType.inviteReceived], isTrue);
      });

      test('로그인하지 않은 상태에서 updateNotificationSetting 호출 시 예외를 발생시킨다',
          () async {
        // Given
        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            notificationSettingsRepositoryProvider
                .overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(notificationSettingsProvider.notifier);

        // When & Then
        expect(
          () => notifier.updateNotificationSetting(
            NotificationType.transactionAdded,
            false,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('initializeDefaultSettings는 기본 알림 설정을 초기화한다', () async {
        // Given
        final testUser = MockUser();
        when(() => testUser.id).thenReturn('test-user-id');

        final defaultSettings = <NotificationType, bool>{
          for (var type in NotificationType.values) type: true
        };

        when(() => mockRepository.initializeDefaultSettings('test-user-id'))
            .thenAnswer((_) async => {});

        when(() => mockRepository.getNotificationSettings('test-user-id'))
            .thenAnswer((_) async => <NotificationType, bool>{});

        when(() => mockRepository.getNotificationSettings('test-user-id'))
            .thenAnswer((_) async => defaultSettings);

        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => testUser),
            notificationSettingsRepositoryProvider
                .overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(notificationSettingsProvider.notifier);

        // When
        await notifier.initializeDefaultSettings();

        // Then
        verify(() => mockRepository.initializeDefaultSettings('test-user-id'))
            .called(1);
        verify(() => mockRepository.getNotificationSettings('test-user-id'))
            .called(2);

        final state = notifier.state;
        expect(state.hasValue, isTrue);
        for (final type in NotificationType.values) {
          expect(state.value?[type], isTrue);
        }
      });

      test('로그인하지 않은 상태에서 initializeDefaultSettings 호출 시 예외를 발생시킨다',
          () async {
        // Given
        container = createContainer(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            notificationSettingsRepositoryProvider
                .overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(notificationSettingsProvider.notifier);

        // When & Then
        expect(
          () => notifier.initializeDefaultSettings(),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
