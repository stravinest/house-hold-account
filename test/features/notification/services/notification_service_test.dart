import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/repositories/notification_settings_repository.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/notification/services/local_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockNotificationSettingsRepository extends Mock
    implements NotificationSettingsRepository {}

class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockNotificationSettingsRepository mockSettingsRepository;
  late MockLocalNotificationService mockLocalNotificationService;
  late MockSupabaseClient mockClient;
  late NotificationService notificationService;

  const testUserId = 'test-user-id';

  // 모든 NotificationType이 활성화된 설정
  final allEnabledSettings = {
    for (final type in NotificationType.values) type: true,
  };

  setUp(() {
    mockSettingsRepository = MockNotificationSettingsRepository();
    mockLocalNotificationService = MockLocalNotificationService();
    mockClient = MockSupabaseClient();

    notificationService = NotificationService(
      client: mockClient,
      settingsRepository: mockSettingsRepository,
      localNotificationService: mockLocalNotificationService,
    );

    // push_notifications from() 호출 시 예외 발생
    // NotificationService._savePushNotification 내부에서 catch하므로 무해함
    when(() => mockClient.from(any()))
        .thenThrow(Exception('test: supabase not available'));
  });

  group('NotificationService.sendAutoCollectNotification', () {
    test('알림이 활성화된 경우 로컬 알림을 표시한다', () async {
      // Given
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenAnswer((_) async => allEnabledSettings);
      when(
        () => mockLocalNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      // When
      await notificationService.sendAutoCollectNotification(
        userId: testUserId,
        type: NotificationType.autoCollectSuggested,
        title: '자동수집 알림',
        body: '거래가 수집되었습니다',
        data: {'pending_id': 'abc123'},
      );

      // Then: 로컬 알림이 정확한 인자로 호출되어야 한다
      verify(
        () => mockLocalNotificationService.showNotification(
          title: '자동수집 알림',
          body: '거래가 수집되었습니다',
          data: {'pending_id': 'abc123'},
        ),
      ).called(1);
    });

    test('알림이 비활성화된 경우 로컬 알림을 표시하지 않는다', () async {
      // Given: 모든 알림 비활성화
      final allDisabledSettings = {
        for (final type in NotificationType.values) type: false,
      };
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenAnswer((_) async => allDisabledSettings);

      // When
      await notificationService.sendAutoCollectNotification(
        userId: testUserId,
        type: NotificationType.autoCollectSuggested,
        title: '자동수집 알림',
        body: '거래가 수집되었습니다',
        data: {},
      );

      // Then: 로컬 알림이 전혀 호출되지 않아야 한다
      verifyNever(
        () => mockLocalNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('특정 타입만 비활성화된 경우 해당 타입 알림은 표시하지 않는다', () async {
      // Given: autoCollectSuggested만 비활성화
      final partialSettings = Map<NotificationType, bool>.from(
        allEnabledSettings,
      )..[NotificationType.autoCollectSuggested] = false;
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenAnswer((_) async => partialSettings);

      // When
      await notificationService.sendAutoCollectNotification(
        userId: testUserId,
        type: NotificationType.autoCollectSuggested,
        title: '자동수집 알림',
        body: '거래가 수집되었습니다',
        data: {},
      );

      // Then
      verifyNever(
        () => mockLocalNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('설정 조회 실패 시 예외를 삼킨다 (치명적이지 않은 에러)', () async {
      // Given
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenThrow(Exception('네트워크 오류'));

      // When / Then - 예외가 throw되지 않아야 함
      await expectLater(
        notificationService.sendAutoCollectNotification(
          userId: testUserId,
          type: NotificationType.autoCollectSuggested,
          title: '알림',
          body: '내용',
          data: {},
        ),
        completes,
      );
    });

    test('로컬 알림 표시 실패 시 예외를 삼킨다', () async {
      // Given
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenAnswer((_) async => allEnabledSettings);
      when(
        () => mockLocalNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('알림 표시 실패'));

      // When / Then: 알림 표시 실패도 내부에서 catch됨
      await expectLater(
        notificationService.sendAutoCollectNotification(
          userId: testUserId,
          type: NotificationType.autoCollectSuggested,
          title: '알림',
          body: '내용',
          data: {},
        ),
        completes,
      );
    });

    test('autoCollectSaved 타입 알림이 활성화된 경우 로컬 알림을 표시한다', () async {
      // Given
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenAnswer((_) async => allEnabledSettings);
      when(
        () => mockLocalNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      // When
      await notificationService.sendAutoCollectNotification(
        userId: testUserId,
        type: NotificationType.autoCollectSaved,
        title: '자동 저장 완료',
        body: '거래가 자동으로 저장되었습니다',
        data: {'transaction_id': 'tx123'},
      );

      // Then
      verify(
        () => mockLocalNotificationService.showNotification(
          title: '자동 저장 완료',
          body: '거래가 자동으로 저장되었습니다',
          data: {'transaction_id': 'tx123'},
        ),
      ).called(1);
    });

    test('히스토리 저장 실패 시에도 정상 완료된다', () async {
      // Given: 로컬 알림은 성공, DB(Supabase) 저장은 setUp에서 throw로 실패
      when(
        () => mockSettingsRepository.getNotificationSettings(testUserId),
      ).thenAnswer((_) async => allEnabledSettings);
      when(
        () => mockLocalNotificationService.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});

      // When / Then: DB 저장 실패해도 예외 전파 없음
      await expectLater(
        notificationService.sendAutoCollectNotification(
          userId: testUserId,
          type: NotificationType.autoCollectSuggested,
          title: '알림',
          body: '내용',
          data: {'key': 'value'},
        ),
        completes,
      );

      // 로컬 알림은 정상 호출됨
      verify(
        () => mockLocalNotificationService.showNotification(
          title: '알림',
          body: '내용',
          data: {'key': 'value'},
        ),
      ).called(1);
    });
  });
}
