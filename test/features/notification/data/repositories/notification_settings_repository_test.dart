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

      when(() => mockClient.from('notification_settings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [mockData],
            maybeSingleData: mockData,
            hasMaybeSingleData: true,
          ));

      final result =
          await repository.getNotificationSettings('user-123');
      expect(result, isA<Map<NotificationType, bool>>());
      expect(result[NotificationType.transactionAdded], isTrue);
      expect(result[NotificationType.transactionUpdated], isFalse);
      expect(result[NotificationType.autoCollectSaved], isFalse);
    });

    test('알림 설정이 없는 경우 모든 알림이 활성화된 기본값을 반환한다', () async {
      when(() => mockClient.from('notification_settings')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [],
            maybeSingleData: null,
            hasMaybeSingleData: true,
          ));

      final result =
          await repository.getNotificationSettings('user-123');
      expect(result.length, NotificationType.values.length);
      expect(result.values.every((enabled) => enabled == true), isTrue);
    });
  });

  group('NotificationSettingsRepository - updateNotificationSetting', () {
    test('특정 알림 설정 업데이트 시 UPSERT로 컬럼을 업데이트한다', () async {
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.updateNotificationSetting(
        userId: 'user-123',
        type: NotificationType.autoCollectSuggested,
        enabled: false,
      );
      // 에러 없이 완료되면 성공
    });
  });

  group('NotificationSettingsRepository - initializeDefaultSettings', () {
    test('기본 설정 초기화 시 모든 알림 타입을 활성화 상태로 UPSERT한다', () async {
      when(() => mockClient.from('notification_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.initializeDefaultSettings('user-123');
      // 에러 없이 완료되면 성공
    });
  });
}
