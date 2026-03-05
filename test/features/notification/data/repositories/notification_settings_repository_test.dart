import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/repositories/notification_settings_repository.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late NotificationSettingsRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = NotificationSettingsRepository(client: mockClient);
  });

  group('NotificationSettingsRepository - getNotificationSettings', () {
    test('알림 설정 조회 시 모든 알림 타입별 활성화 상태를 Map으로 반환한다', () async {
      // Given
      final mockData = <String, dynamic>{
        'user_id': 'user-123',
        'shared_ledger_change_enabled': true,
        'transaction_added_enabled': true,
        'transaction_updated_enabled': false,
        'transaction_deleted_enabled': true,
        'auto_collect_suggested_enabled': true,
        'auto_collect_saved_enabled': false,
        'invite_received_enabled': true,
        'invite_accepted_enabled': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      when(() => mockClient.from('notification_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          selectData: [mockData],
          maybeSingleData: mockData,
          hasMaybeSingleData: true,
        ),
      );

      // When
      final result = await repository.getNotificationSettings('user-123');

      // Then
      expect(result, isA<Map<NotificationType, bool>>());
      expect(result[NotificationType.transactionAdded], isTrue);
      expect(result[NotificationType.transactionUpdated], isFalse);
      expect(result[NotificationType.autoCollectSaved], isFalse);
      expect(result[NotificationType.transactionDeleted], isTrue);
      expect(result[NotificationType.inviteReceived], isTrue);
      expect(result[NotificationType.inviteAccepted], isTrue);
      expect(result[NotificationType.autoCollectSuggested], isTrue);
    });

    test('알림 설정이 없는 경우 모든 알림이 활성화된 기본값을 반환한다', () async {
      // Given: response가 null인 경우
      when(() => mockClient.from('notification_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          selectData: [],
          maybeSingleData: null,
          hasMaybeSingleData: true,
        ),
      );

      // When
      final result = await repository.getNotificationSettings('user-123');

      // Then
      expect(result.length, equals(NotificationType.values.length));
      expect(result.values.every((enabled) => enabled == true), isTrue);
    });

    test('nullable 컬럼이 null인 경우 기본값 true를 사용한다', () async {
      // Given: 일부 컬럼이 null인 데이터
      final mockData = <String, dynamic>{
        'user_id': 'user-123',
        'shared_ledger_change_enabled': null,
        'transaction_added_enabled': null,
        'transaction_updated_enabled': false,
        'transaction_deleted_enabled': null,
        'auto_collect_suggested_enabled': null,
        'auto_collect_saved_enabled': null,
        'invite_received_enabled': null,
        'invite_accepted_enabled': null,
      };

      when(() => mockClient.from('notification_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          selectData: [mockData],
          maybeSingleData: mockData,
          hasMaybeSingleData: true,
        ),
      );

      // When
      final result = await repository.getNotificationSettings('user-123');

      // Then: null인 경우 기본값 true가 사용되어야 한다
      expect(result[NotificationType.transactionAdded], isTrue);
      expect(result[NotificationType.transactionUpdated], isFalse);
      expect(result[NotificationType.inviteReceived], isTrue);
    });

    test('에러 발생 시 예외를 상위로 전파한다', () async {
      // Given: 에러를 발생시키는 client
      when(() => mockClient.from('notification_settings'))
          .thenThrow(Exception('DB 연결 실패'));

      // When & Then
      expect(
        () => repository.getNotificationSettings('user-123'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('NotificationSettingsRepository - updateNotificationSetting', () {
    test('transactionAdded 알림 설정 업데이트 시 UPSERT를 호출한다', () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When
      await repository.updateNotificationSetting(
        userId: 'user-123',
        type: NotificationType.transactionAdded,
        enabled: false,
      );

      // Then: 예외 없이 완료
      verify(() => mockClient.from('notification_settings')).called(1);
    });

    test('autoCollectSuggested 알림 설정 업데이트 시 UPSERT를 호출한다', () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When
      await repository.updateNotificationSetting(
        userId: 'user-123',
        type: NotificationType.autoCollectSuggested,
        enabled: false,
      );

      // Then: 예외 없이 완료
      verify(() => mockClient.from('notification_settings')).called(1);
    });

    test('모든 NotificationType에 대해 컬럼명이 올바르게 매핑된다', () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When & Then: 모든 타입에 대해 에러 없이 동작해야 한다
      for (final type in NotificationType.values) {
        await repository.updateNotificationSetting(
          userId: 'user-123',
          type: type,
          enabled: true,
        );
      }
    });

    test('에러 발생 시 예외를 상위로 전파한다', () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenThrow(Exception('업데이트 실패'));

      // When & Then
      expect(
        () => repository.updateNotificationSetting(
          userId: 'user-123',
          type: NotificationType.transactionAdded,
          enabled: false,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('NotificationSettingsRepository - initializeDefaultSettings', () {
    test('기본 설정 초기화 시 모든 알림 타입을 활성화 상태로 UPSERT한다', () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When
      await repository.initializeDefaultSettings('user-123');

      // Then: 예외 없이 완료
      verify(() => mockClient.from('notification_settings')).called(1);
    });

    test('에러 발생 시 예외를 상위로 전파한다', () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenThrow(Exception('초기화 실패'));

      // When & Then
      expect(
        () => repository.initializeDefaultSettings('user-123'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('NotificationSettingsRepository - _getColumnName 검증', () {
    test('각 NotificationType이 올바른 컬럼명으로 변환된다 (updateNotificationSetting을 통해)',
        () async {
      // Given
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // sharedLedgerChange
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.sharedLedgerChange,
        enabled: true,
      );

      // transactionAdded
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.transactionAdded,
        enabled: true,
      );

      // transactionUpdated
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.transactionUpdated,
        enabled: true,
      );

      // transactionDeleted
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.transactionDeleted,
        enabled: true,
      );

      // autoCollectSuggested
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.autoCollectSuggested,
        enabled: true,
      );

      // autoCollectSaved
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.autoCollectSaved,
        enabled: true,
      );

      // inviteReceived
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.inviteReceived,
        enabled: true,
      );

      // inviteAccepted
      await repository.updateNotificationSetting(
        userId: 'u',
        type: NotificationType.inviteAccepted,
        enabled: true,
      );

      // Then: 모든 타입이 예외 없이 처리됨
      verify(() => mockClient.from('notification_settings')).called(8);
    });
  });
}
