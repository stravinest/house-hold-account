import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/repositories/notification_settings_repository.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/notification/services/local_notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockNotificationSettingsRepo extends Mock
    implements NotificationSettingsRepository {}

class MockLocalNotifService extends Mock implements LocalNotificationService {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {}
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(NotificationType.autoCollectSuggested);
  });

  group('NotificationService 인스턴스 생성 테스트', () {
    test('커스텀 의존성으로 NotificationService를 생성할 수 있다', () {
      // Given
      final mockRepo = MockNotificationSettingsRepo();
      final mockLocal = MockLocalNotifService();

      // When
      final service = NotificationService(
        settingsRepository: mockRepo,
        localNotificationService: mockLocal,
      );

      // Then
      expect(service, isNotNull);
      expect(service, isA<NotificationService>());
    });

    test('기본 의존성으로도 NotificationService를 생성할 수 있다', () {
      // When
      final service = NotificationService();

      // Then
      expect(service, isNotNull);
    });
  });

  group('NotificationService.sendAutoCollectNotification 실제 호출 테스트', () {
    late MockNotificationSettingsRepo mockRepo;
    late MockLocalNotifService mockLocal;
    late NotificationService service;

    setUp(() {
      mockRepo = MockNotificationSettingsRepo();
      mockLocal = MockLocalNotifService();
      // client는 stub 없이 두어 _savePushNotification 실패를 catch로 처리
      service = NotificationService(
        settingsRepository: mockRepo,
        localNotificationService: mockLocal,
      );
    });

    test('알림이 비활성화된 경우 showNotification이 호출되지 않는다', () async {
      // Given
      when(() => mockRepo.getNotificationSettings('user-2')).thenAnswer(
        (_) async => {NotificationType.autoCollectSuggested: false},
      );

      // When
      await service.sendAutoCollectNotification(
        userId: 'user-2',
        type: NotificationType.autoCollectSuggested,
        title: '거래 감지',
        body: '5,000원 거래',
        data: {},
      );

      // Then
      verifyNever(
        () => mockLocal.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('설정에 타입이 없으면 기본값 false로 처리하여 알림을 표시하지 않는다', () async {
      // Given
      when(() => mockRepo.getNotificationSettings('user-3')).thenAnswer(
        (_) async => <NotificationType, bool>{},
      );

      // When
      await service.sendAutoCollectNotification(
        userId: 'user-3',
        type: NotificationType.autoCollectSaved,
        title: '자동 저장',
        body: '자동으로 저장되었습니다',
        data: {},
      );

      // Then
      verifyNever(
        () => mockLocal.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      );
    });

    test('설정 조회 실패 시 예외가 전파되지 않는다 (내부에서 catch)', () async {
      // Given
      when(() => mockRepo.getNotificationSettings(any())).thenThrow(
        Exception('DB 오류'),
      );

      // When & Then: 예외가 throw되지 않아야 한다
      await expectLater(
        service.sendAutoCollectNotification(
          userId: 'user-4',
          type: NotificationType.autoCollectSuggested,
          title: '제목',
          body: '내용',
          data: {},
        ),
        completes,
      );
    });

    test('알림이 활성화되어 showNotification이 호출되고 DB 저장 실패해도 예외가 전파되지 않는다', () async {
      // Given: 알림 활성화, showNotification 성공, DB 저장 실패
      when(() => mockRepo.getNotificationSettings('user-5')).thenAnswer(
        (_) async => {NotificationType.autoCollectSaved: true},
      );
      when(
        () => mockLocal.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async {});
      // mockClient.from()은 stub 없이 MissingStubError 발생 -> catch로 처리됨

      // When & Then: 예외가 전파되지 않아야 한다
      await expectLater(
        service.sendAutoCollectNotification(
          userId: 'user-5',
          type: NotificationType.autoCollectSaved,
          title: '자동 저장 완료',
          body: '10,000원이 자동으로 저장되었습니다.',
          data: {'transactionId': 'tx-1'},
        ),
        completes,
      );

      // showNotification은 호출됨
      verify(
        () => mockLocal.showNotification(
          title: '자동 저장 완료',
          body: '10,000원이 자동으로 저장되었습니다.',
          data: {'transactionId': 'tx-1'},
        ),
      ).called(1);
    });

    test('showNotification 실패 시에도 예외가 전파되지 않는다', () async {
      // Given
      when(() => mockRepo.getNotificationSettings('user-6')).thenAnswer(
        (_) async => {NotificationType.autoCollectSuggested: true},
      );
      when(
        () => mockLocal.showNotification(
          title: any(named: 'title'),
          body: any(named: 'body'),
          data: any(named: 'data'),
        ),
      ).thenThrow(Exception('알림 표시 실패'));

      // When & Then: 예외가 throw되지 않아야 한다
      await expectLater(
        service.sendAutoCollectNotification(
          userId: 'user-6',
          type: NotificationType.autoCollectSuggested,
          title: '제목',
          body: '내용',
          data: {},
        ),
        completes,
      );
    });
  });
}
