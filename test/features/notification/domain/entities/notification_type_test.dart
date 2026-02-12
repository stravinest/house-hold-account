import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';

void main() {
  group('NotificationType', () {
    test('fromString은 올바른 타입을 반환한다', () {
      expect(
        NotificationType.fromString('shared_ledger_change'),
        NotificationType.sharedLedgerChange,
      );
      expect(
        NotificationType.fromString('invite_received'),
        NotificationType.inviteReceived,
      );
      expect(
        NotificationType.fromString('invite_accepted'),
        NotificationType.inviteAccepted,
      );
      expect(
        NotificationType.fromString('transaction_added'),
        NotificationType.transactionAdded,
      );
      expect(
        NotificationType.fromString('transaction_updated'),
        NotificationType.transactionUpdated,
      );
      expect(
        NotificationType.fromString('transaction_deleted'),
        NotificationType.transactionDeleted,
      );
      expect(
        NotificationType.fromString('auto_collect_suggested'),
        NotificationType.autoCollectSuggested,
      );
      expect(
        NotificationType.fromString('auto_collect_saved'),
        NotificationType.autoCollectSaved,
      );
    });

    test('fromString은 알 수 없는 값에 대해 ArgumentError를 throw한다', () {
      expect(
        () => NotificationType.fromString('unknown_type'),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => NotificationType.fromString(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('value는 문자열 값을 반환한다', () {
      expect(NotificationType.transactionAdded.value, 'transaction_added');
      expect(NotificationType.transactionUpdated.value, 'transaction_updated');
      expect(NotificationType.transactionDeleted.value, 'transaction_deleted');
      expect(
        NotificationType.autoCollectSuggested.value,
        'auto_collect_suggested',
      );
      expect(NotificationType.autoCollectSaved.value, 'auto_collect_saved');
      expect(NotificationType.inviteReceived.value, 'invite_received');
      expect(NotificationType.inviteAccepted.value, 'invite_accepted');
      expect(
        NotificationType.sharedLedgerChange.value,
        'shared_ledger_change',
      );
    });

    group('icon getter', () {
      test('각 타입마다 적절한 아이콘을 반환한다', () {
        expect(
          NotificationType.transactionAdded.icon,
          Icons.add_circle_outline,
        );
        expect(NotificationType.transactionUpdated.icon, Icons.edit_outlined);
        expect(NotificationType.transactionDeleted.icon, Icons.delete_outline);
        expect(
          NotificationType.autoCollectSuggested.icon,
          Icons.notifications_outlined,
        );
        expect(NotificationType.autoCollectSaved.icon, Icons.save_outlined);
        expect(NotificationType.inviteReceived.icon, Icons.mail_outline);
        expect(
          NotificationType.inviteAccepted.icon,
          Icons.check_circle_outline,
        );
        expect(NotificationType.sharedLedgerChange.icon, Icons.people_outline);
      });

      test('모든 아이콘은 IconData 타입이다', () {
        for (final type in NotificationType.values) {
          expect(type.icon, isA<IconData>());
        }
      });
    });

    test('모든 enum 값은 고유한 value를 가진다', () {
      final values = NotificationType.values.map((t) => t.value).toList();
      final uniqueValues = values.toSet();

      expect(values.length, uniqueValues.length);
    });
  });
}
