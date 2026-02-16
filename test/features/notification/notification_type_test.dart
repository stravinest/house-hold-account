import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

void main() {
  group('NotificationType', () {
    group('fromString - 문자열에서 알림 타입으로 변환', () {
      test('공유 가계부 알림 타입들을 올바르게 변환해야 한다', () {
        expect(
          NotificationType.fromString('transaction_added'),
          equals(NotificationType.transactionAdded),
        );
        expect(
          NotificationType.fromString('transaction_updated'),
          equals(NotificationType.transactionUpdated),
        );
        expect(
          NotificationType.fromString('transaction_deleted'),
          equals(NotificationType.transactionDeleted),
        );
      });

      test('자동수집 알림 타입들을 올바르게 변환해야 한다', () {
        expect(
          NotificationType.fromString('auto_collect_suggested'),
          equals(NotificationType.autoCollectSuggested),
        );
        expect(
          NotificationType.fromString('auto_collect_saved'),
          equals(NotificationType.autoCollectSaved),
        );
      });

      test('초대 알림 타입들을 올바르게 변환해야 한다', () {
        expect(
          NotificationType.fromString('invite_received'),
          equals(NotificationType.inviteReceived),
        );
        expect(
          NotificationType.fromString('invite_accepted'),
          equals(NotificationType.inviteAccepted),
        );
      });

      test('deprecated된 shared_ledger_change 타입도 변환되어야 한다', () {
        // ignore: deprecated_member_use_from_same_package
        expect(
          NotificationType.fromString('shared_ledger_change'),
          // ignore: deprecated_member_use_from_same_package
          equals(NotificationType.sharedLedgerChange),
        );
      });

      test('존재하지 않는 알림 타입은 ArgumentError를 발생시켜야 한다', () {
        expect(
          () => NotificationType.fromString('unknown_type'),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('빈 문자열은 ArgumentError를 발생시켜야 한다', () {
        expect(
          () => NotificationType.fromString(''),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('value - 알림 타입의 문자열 값', () {
      test('모든 알림 타입이 고유한 문자열 값을 가져야 한다', () {
        final values = NotificationType.values.map((t) => t.value).toList();
        final uniqueValues = values.toSet();
        expect(
          values.length,
          equals(uniqueValues.length),
          reason: '중복된 value가 존재합니다',
        );
      });

      test('모든 알림 타입의 value가 snake_case 형식이어야 한다', () {
        for (final type in NotificationType.values) {
          expect(
            type.value,
            matches(RegExp(r'^[a-z]+(_[a-z]+)*$')),
            reason: '${type.name}의 value "${type.value}"가 snake_case가 아닙니다',
          );
        }
      });
    });

    group('icon - 알림 타입별 아이콘', () {
      test('모든 알림 타입이 아이콘을 가져야 한다', () {
        for (final type in NotificationType.values) {
          expect(
            type.icon,
            isNotNull,
            reason: '${type.name}에 아이콘이 지정되지 않았습니다',
          );
        }
      });
    });

    group('알림 타입 그룹 분류', () {
      test('공유 가계부 알림 타입이 3개여야 한다 (deprecated 제외)', () {
        final sharedLedgerTypes = [
          NotificationType.transactionAdded,
          NotificationType.transactionUpdated,
          NotificationType.transactionDeleted,
        ];
        expect(sharedLedgerTypes.length, equals(3));
      });

      test('자동수집 알림 타입이 2개여야 한다', () {
        final autoCollectTypes = [
          NotificationType.autoCollectSuggested,
          NotificationType.autoCollectSaved,
        ];
        expect(autoCollectTypes.length, equals(2));
      });

      test('초대 알림 타입이 2개여야 한다', () {
        final inviteTypes = [
          NotificationType.inviteReceived,
          NotificationType.inviteAccepted,
        ];
        expect(inviteTypes.length, equals(2));
      });

      test('전체 알림 타입이 8개여야 한다 (deprecated 포함)', () {
        expect(NotificationType.values.length, equals(8));
      });
    });
  });
}
