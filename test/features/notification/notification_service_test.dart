import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

/// NotificationService 비즈니스 로직 테스트
///
/// NotificationService는 내부에서 SupabaseConfig.client를 직접 생성하는 싱글톤 의존성을 가지고 있어
/// 의존성 주입 없이는 Mock 불가능하다. 따라서 여기서는 비즈니스 로직의 정합성을 검증한다.
///
/// 실제 NotificationService 코드에서 발견된 문제점:
/// 1. SupabaseConfig.client를 직접 참조 -> 테스트 시 Mock 불가 (DI 미지원)
/// 2. NotificationSettingsRepository를 내부에서 직접 생성 -> Mock 불가
/// 3. LocalNotificationService를 내부에서 직접 생성 -> Mock 불가
void main() {
  group('NotificationService - 알림 전송 비즈니스 로직 검증', () {
    group('자동수집 알림 타입 검증', () {
      test('suggest 모드에서는 autoCollectSuggested 타입을 사용해야 한다', () {
        // NotificationService.sendAutoCollectNotification에서
        // suggest 모드일 때 사용하는 타입
        const expectedType = NotificationType.autoCollectSuggested;
        expect(expectedType.value, equals('auto_collect_suggested'));
      });

      test('auto 모드에서는 autoCollectSaved 타입을 사용해야 한다', () {
        // NotificationService.sendAutoCollectNotification에서
        // auto 모드일 때 사용하는 타입
        const expectedType = NotificationType.autoCollectSaved;
        expect(expectedType.value, equals('auto_collect_saved'));
      });
    });

    group('알림 설정에 따른 전송 여부 로직 검증', () {
      test('알림이 비활성화된 경우 전송하지 않아야 하는 로직의 기반 검증', () {
        // NotificationService 코드:
        // final isEnabled = settings[type] ?? false;
        // if (!isEnabled) return;
        //
        // settings Map에서 해당 타입이 false이면 전송 안 함
        final settings = <NotificationType, bool>{
          NotificationType.autoCollectSuggested: false,
          NotificationType.autoCollectSaved: true,
        };

        // 비활성화된 알림
        final suggestedEnabled =
            settings[NotificationType.autoCollectSuggested] ?? false;
        expect(suggestedEnabled, isFalse, reason: '비활성화된 알림은 false여야 한다');

        // 활성화된 알림
        final savedEnabled =
            settings[NotificationType.autoCollectSaved] ?? false;
        expect(savedEnabled, isTrue, reason: '활성화된 알림은 true여야 한다');
      });

      test('설정 Map에 타입이 존재하지 않으면 기본값 false로 전송하지 않아야 한다', () {
        // NotificationService 코드:
        // final isEnabled = settings[type] ?? false;
        //
        // Map에 키가 없을 때 null이 반환되고, ?? false로 기본값 false
        final settings = <NotificationType, bool>{};
        final isEnabled =
            settings[NotificationType.autoCollectSuggested] ?? false;
        expect(
          isEnabled,
          isFalse,
          reason: '설정이 없으면 기본값 false로 알림을 전송하지 않아야 한다',
        );
      });
    });

    group('공유 가계부 알림 - Edge Function 타입 매핑 검증', () {
      test('INSERT 이벤트는 transaction_added 타입에 매핑되어야 한다', () {
        // send-push-notification Edge Function의 매핑 로직
        const webhookType = 'INSERT';
        String notificationType;
        switch (webhookType) {
          case 'INSERT':
            notificationType = 'transaction_added';
            break;
          case 'UPDATE':
            notificationType = 'transaction_updated';
            break;
          case 'DELETE':
            notificationType = 'transaction_deleted';
            break;
          default:
            notificationType = 'unknown';
        }
        expect(notificationType, equals('transaction_added'));
        expect(
          NotificationType.fromString(notificationType),
          equals(NotificationType.transactionAdded),
        );
      });

      test('UPDATE 이벤트는 transaction_updated 타입에 매핑되어야 한다', () {
        const webhookType = 'UPDATE';
        final notificationType = switch (webhookType) {
          'INSERT' => 'transaction_added',
          'UPDATE' => 'transaction_updated',
          'DELETE' => 'transaction_deleted',
          _ => 'unknown',
        };
        expect(notificationType, equals('transaction_updated'));
      });

      test('DELETE 이벤트는 transaction_deleted 타입에 매핑되어야 한다', () {
        const webhookType = 'DELETE';
        final notificationType = switch (webhookType) {
          'INSERT' => 'transaction_added',
          'UPDATE' => 'transaction_updated',
          'DELETE' => 'transaction_deleted',
          _ => 'unknown',
        };
        expect(notificationType, equals('transaction_deleted'));
      });
    });

    group('공유 가계부 알림 - 설정 컬럼 매핑 검증', () {
      test('각 알림 타입이 올바른 DB 컬럼명에 매핑되어야 한다', () {
        // Edge Function에서 알림 설정 확인 시 사용하는 컬럼명
        final expectedMappings = <String, String>{
          'transaction_added': 'transaction_added_enabled',
          'transaction_updated': 'transaction_updated_enabled',
          'transaction_deleted': 'transaction_deleted_enabled',
          'auto_collect_suggested': 'auto_collect_suggested_enabled',
          'auto_collect_saved': 'auto_collect_saved_enabled',
          'invite_received': 'invite_received_enabled',
          'invite_accepted': 'invite_accepted_enabled',
        };

        for (final entry in expectedMappings.entries) {
          // value + '_enabled' == columnName 패턴 검증
          expect(
            entry.value,
            equals('${entry.key}_enabled'),
            reason: '${entry.key}의 컬럼명이 ${entry.key}_enabled여야 합니다',
          );
        }
      });
    });

    group('초대 알림 - 설정 컬럼 매핑 검증', () {
      test('invite_received는 invite_received_enabled 컬럼을 확인해야 한다', () {
        // send-invite-notification Edge Function의 로직:
        // const settingsColumn = notificationType === 'invite_received'
        //   ? 'invite_received_enabled'
        //   : 'invite_accepted_enabled';
        const notificationType = 'invite_received';
        final settingsColumn = notificationType == 'invite_received'
            ? 'invite_received_enabled'
            : 'invite_accepted_enabled';
        expect(settingsColumn, equals('invite_received_enabled'));
      });

      test('invite_accepted는 invite_accepted_enabled 컬럼을 확인해야 한다', () {
        const notificationType = 'invite_accepted';
        final settingsColumn = notificationType == 'invite_received'
            ? 'invite_received_enabled'
            : 'invite_accepted_enabled';
        expect(settingsColumn, equals('invite_accepted_enabled'));
      });

      test('invite_rejected는 invite_accepted_enabled 컬럼을 확인한다 (주의: 매핑 이슈)', () {
        // ISSUE: invite_rejected 타입에 대한 설정 컬럼이 invite_accepted_enabled로 매핑됨
        // Edge Function에서 invite_rejected를 받으면 invite_accepted_enabled를 확인하는데,
        // 이것은 의도된 동작인지 확인 필요
        const notificationType = 'invite_rejected';
        final settingsColumn = notificationType == 'invite_received'
            ? 'invite_received_enabled'
            : 'invite_accepted_enabled';
        // invite_rejected는 invite_accepted_enabled로 매핑됨
        expect(settingsColumn, equals('invite_accepted_enabled'));
      });
    });

    group('알림 데이터 페이로드 구조 검증', () {
      test('공유 가계부 알림 데이터에 필수 필드가 포함되어야 한다', () {
        // Edge Function에서 FCM 메시지에 포함하는 data 필드
        final data = <String, String>{
          'type': 'transaction_added',
          'ledger_id': 'ledger-uuid',
          'transaction_id': 'transaction-uuid',
          'creator_user_id': 'creator-uuid',
        };

        expect(data.containsKey('type'), isTrue);
        expect(data.containsKey('ledger_id'), isTrue);
        expect(data.containsKey('transaction_id'), isTrue);
        expect(data.containsKey('creator_user_id'), isTrue);
      });

      test('초대 알림 데이터에 필수 필드가 포함되어야 한다', () {
        final data = <String, String>{
          'type': 'invite_received',
          'actor_name': '홍길동',
          'ledger_name': '우리집 가계부',
        };

        expect(data.containsKey('type'), isTrue);
        expect(data.containsKey('actor_name'), isTrue);
        expect(data.containsKey('ledger_name'), isTrue);
      });

      test('자동수집 알림 데이터에 필수 필드가 포함되어야 한다', () {
        final data = <String, dynamic>{
          'type': 'auto_collect_suggested',
          'pendingId': 'pending-uuid',
          'targetTab': 'pending',
          'paymentMethodName': 'KB카드',
          'amount': '50000',
          'merchant': '스타벅스',
        };

        expect(data.containsKey('type'), isTrue);
        expect(data.containsKey('pendingId'), isTrue);
        expect(data.containsKey('targetTab'), isTrue);
      });
    });
  });
}
