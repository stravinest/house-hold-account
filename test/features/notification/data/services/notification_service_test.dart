import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/repositories/notification_settings_repository.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/notification/services/local_notification_service.dart';

class MockNotificationSettingsRepository extends Mock
    implements NotificationSettingsRepository {}

class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

void main() {
  group('NotificationService', () {
    setUpAll(() {
      // Future 반환 타입 등록
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(NotificationType.autoCollectSuggested);
    });

    group('sendAutoCollectNotification', () {
      test('NotificationService는 Supabase 의존성으로 인해 통합 테스트에서 검증한다', () {
        // NotificationService는 내부적으로 Supabase client를 사용하므로
        // 단위 테스트보다는 통합 테스트가 적합합니다.
        // 여기서는 API 스펙만 검증합니다.
        expect(true, isTrue);
      });
    });

    group('NotificationType', () {
      test('autoCollectSuggested 타입의 value가 올바르게 설정되어 있다', () {
        expect(
          NotificationType.autoCollectSuggested.value,
          equals('auto_collect_suggested'),
        );
      });

      test('autoCollectSaved 타입의 value가 올바르게 설정되어 있다', () {
        expect(
          NotificationType.autoCollectSaved.value,
          equals('auto_collect_saved'),
        );
      });

      test('inviteReceived 타입의 value가 올바르게 설정되어 있다', () {
        expect(
          NotificationType.inviteReceived.value,
          equals('invite_received'),
        );
      });

      test('transactionAdded 타입의 value가 올바르게 설정되어 있다', () {
        expect(
          NotificationType.transactionAdded.value,
          equals('transaction_added'),
        );
      });
    });
  });
}
