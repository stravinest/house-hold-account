import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

/// NotificationSettingsRepository 비즈니스 로직 테스트
///
/// Supabase Client Mock이 복잡하므로, Repository의 핵심 비즈니스 로직인
/// DB 응답 -> Map<NotificationType, bool> 변환 로직을 검증한다.
///
/// 실제 Repository 코드의 변환 로직을 추출하여 테스트:
/// - DB 응답이 있을 때: 각 컬럼값을 NotificationType에 매핑
/// - DB 응답이 없을 때: 모든 타입에 대해 true 반환
/// - DB 응답에 null 컬럼이 있을 때: 기본값 true 사용
void main() {
  /// Repository의 getNotificationSettings가 DB 응답을 파싱하는 로직 재현
  ///
  /// 실제 코드 위치: notification_settings_repository.dart:54-75
  Map<NotificationType, bool> parseSettingsResponse(
    Map<String, dynamic>? response,
  ) {
    if (response == null) {
      return {for (var type in NotificationType.values) type: true};
    }

    return {
      // ignore: deprecated_member_use_from_same_package
      NotificationType.sharedLedgerChange:
          response['shared_ledger_change_enabled'] as bool? ?? true,
      NotificationType.transactionAdded:
          response['transaction_added_enabled'] as bool? ?? true,
      NotificationType.transactionUpdated:
          response['transaction_updated_enabled'] as bool? ?? true,
      NotificationType.transactionDeleted:
          response['transaction_deleted_enabled'] as bool? ?? true,
      NotificationType.autoCollectSuggested:
          response['auto_collect_suggested_enabled'] as bool? ?? true,
      NotificationType.autoCollectSaved:
          response['auto_collect_saved_enabled'] as bool? ?? true,
      NotificationType.inviteReceived:
          response['invite_received_enabled'] as bool? ?? true,
      NotificationType.inviteAccepted:
          response['invite_accepted_enabled'] as bool? ?? true,
    };
  }

  /// 알림 설정 DB 응답 데이터 생성 헬퍼
  Map<String, dynamic> createSettingsResponse([
    Map<String, dynamic>? overrides,
  ]) {
    final defaults = <String, dynamic>{
      'shared_ledger_change_enabled': true,
      'transaction_added_enabled': true,
      'transaction_updated_enabled': true,
      'transaction_deleted_enabled': true,
      'auto_collect_suggested_enabled': true,
      'auto_collect_saved_enabled': true,
      'invite_received_enabled': true,
      'invite_accepted_enabled': true,
    };
    if (overrides != null) {
      defaults.addAll(overrides);
    }
    return defaults;
  }

  group('NotificationSettingsRepository - DB 응답 파싱 로직', () {
    group('공유 가계부 알림 설정 (활성/비활성)', () {
      test('거래 추가 알림 - 활성화 상태', () {
        final settings = parseSettingsResponse(createSettingsResponse());
        expect(settings[NotificationType.transactionAdded], isTrue);
      });

      test('거래 추가 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'transaction_added_enabled': false}),
        );
        expect(settings[NotificationType.transactionAdded], isFalse);
      });

      test('거래 수정 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'transaction_updated_enabled': false}),
        );
        expect(settings[NotificationType.transactionUpdated], isFalse);
      });

      test('거래 삭제 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'transaction_deleted_enabled': false}),
        );
        expect(settings[NotificationType.transactionDeleted], isFalse);
      });

      test('공유 가계부 알림 3개를 독립적으로 설정할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'transaction_added_enabled': false,
            'transaction_updated_enabled': true,
            'transaction_deleted_enabled': false,
          }),
        );
        expect(settings[NotificationType.transactionAdded], isFalse);
        expect(settings[NotificationType.transactionUpdated], isTrue);
        expect(settings[NotificationType.transactionDeleted], isFalse);
      });
    });

    group('자동수집 알림 설정 (활성/비활성)', () {
      test('자동수집 제안 알림 - 활성화 상태', () {
        final settings = parseSettingsResponse(createSettingsResponse());
        expect(settings[NotificationType.autoCollectSuggested], isTrue);
      });

      test('자동수집 제안 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'auto_collect_suggested_enabled': false}),
        );
        expect(settings[NotificationType.autoCollectSuggested], isFalse);
      });

      test('자동수집 저장 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'auto_collect_saved_enabled': false}),
        );
        expect(settings[NotificationType.autoCollectSaved], isFalse);
      });

      test('자동수집 알림 2개를 독립적으로 설정할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'auto_collect_suggested_enabled': false,
            'auto_collect_saved_enabled': true,
          }),
        );
        expect(settings[NotificationType.autoCollectSuggested], isFalse);
        expect(settings[NotificationType.autoCollectSaved], isTrue);
      });
    });

    group('초대 알림 설정 (활성/비활성)', () {
      test('초대 받음 알림 - 활성화 상태', () {
        final settings = parseSettingsResponse(createSettingsResponse());
        expect(settings[NotificationType.inviteReceived], isTrue);
      });

      test('초대 받음 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'invite_received_enabled': false}),
        );
        expect(settings[NotificationType.inviteReceived], isFalse);
      });

      test('초대 수락 알림 - 비활성화 상태', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({'invite_accepted_enabled': false}),
        );
        expect(settings[NotificationType.inviteAccepted], isFalse);
      });

      test('초대 알림 2개를 독립적으로 설정할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'invite_received_enabled': true,
            'invite_accepted_enabled': false,
          }),
        );
        expect(settings[NotificationType.inviteReceived], isTrue);
        expect(settings[NotificationType.inviteAccepted], isFalse);
      });
    });

    group('기본값 처리', () {
      test('DB 응답이 null이면 모든 알림이 활성화된 기본값을 반환해야 한다', () {
        final settings = parseSettingsResponse(null);

        for (final type in NotificationType.values) {
          expect(
            settings[type],
            isTrue,
            reason: '${type.name}의 기본값이 true여야 합니다',
          );
        }
      });

      test('DB 응답에서 특정 컬럼이 null이면 기본값 true를 사용해야 한다', () {
        final settings = parseSettingsResponse({
          'shared_ledger_change_enabled': true,
          'transaction_added_enabled': null,
          'transaction_updated_enabled': true,
          'transaction_deleted_enabled': null,
          'auto_collect_suggested_enabled': null,
          'auto_collect_saved_enabled': true,
          'invite_received_enabled': null,
          'invite_accepted_enabled': true,
        });

        // null 컬럼은 기본값 true
        expect(settings[NotificationType.transactionAdded], isTrue);
        expect(settings[NotificationType.transactionDeleted], isTrue);
        expect(settings[NotificationType.autoCollectSuggested], isTrue);
        expect(settings[NotificationType.inviteReceived], isTrue);
      });
    });

    group('전체 비활성화 시나리오', () {
      test('모든 알림을 비활성화할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'shared_ledger_change_enabled': false,
            'transaction_added_enabled': false,
            'transaction_updated_enabled': false,
            'transaction_deleted_enabled': false,
            'auto_collect_suggested_enabled': false,
            'auto_collect_saved_enabled': false,
            'invite_received_enabled': false,
            'invite_accepted_enabled': false,
          }),
        );

        for (final type in NotificationType.values) {
          expect(
            settings[type],
            isFalse,
            reason: '${type.name}이 false여야 합니다',
          );
        }
      });
    });

    group('혼합 설정 시나리오', () {
      test('공유 가계부 알림만 비활성화할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'transaction_added_enabled': false,
            'transaction_updated_enabled': false,
            'transaction_deleted_enabled': false,
          }),
        );

        expect(settings[NotificationType.transactionAdded], isFalse);
        expect(settings[NotificationType.transactionUpdated], isFalse);
        expect(settings[NotificationType.transactionDeleted], isFalse);
        expect(settings[NotificationType.autoCollectSuggested], isTrue);
        expect(settings[NotificationType.autoCollectSaved], isTrue);
        expect(settings[NotificationType.inviteReceived], isTrue);
        expect(settings[NotificationType.inviteAccepted], isTrue);
      });

      test('자동수집 알림만 비활성화할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'auto_collect_suggested_enabled': false,
            'auto_collect_saved_enabled': false,
          }),
        );

        expect(settings[NotificationType.autoCollectSuggested], isFalse);
        expect(settings[NotificationType.autoCollectSaved], isFalse);
        expect(settings[NotificationType.transactionAdded], isTrue);
        expect(settings[NotificationType.inviteReceived], isTrue);
      });

      test('초대 알림만 비활성화할 수 있어야 한다', () {
        final settings = parseSettingsResponse(
          createSettingsResponse({
            'invite_received_enabled': false,
            'invite_accepted_enabled': false,
          }),
        );

        expect(settings[NotificationType.inviteReceived], isFalse);
        expect(settings[NotificationType.inviteAccepted], isFalse);
        expect(settings[NotificationType.transactionAdded], isTrue);
        expect(settings[NotificationType.autoCollectSuggested], isTrue);
      });
    });

    group('반환값 완전성 검증', () {
      test('반환된 Map이 모든 NotificationType을 포함해야 한다', () {
        final settings = parseSettingsResponse(createSettingsResponse());

        for (final type in NotificationType.values) {
          expect(
            settings.containsKey(type),
            isTrue,
            reason: '${type.name}이 반환 Map에 포함되어야 합니다',
          );
        }
      });

      test('null 응답일 때도 모든 NotificationType을 포함해야 한다', () {
        final settings = parseSettingsResponse(null);

        for (final type in NotificationType.values) {
          expect(
            settings.containsKey(type),
            isTrue,
            reason: '기본값에서도 ${type.name}이 포함되어야 합니다',
          );
        }
      });
    });
  });
}
