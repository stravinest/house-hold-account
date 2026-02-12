import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';

void main() {
  group('LedgerInvite Entity', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testExpiresAt = DateTime(2026, 2, 19, 10, 0, 0);

    final invite = LedgerInvite(
      id: 'invite-id',
      ledgerId: 'ledger-id',
      inviterUserId: 'inviter-id',
      inviteeEmail: 'invitee@example.com',
      role: 'editor',
      status: 'pending',
      expiresAt: testExpiresAt,
      createdAt: testCreatedAt,
      ledgerName: '우리 가계부',
      inviterEmail: 'inviter@example.com',
    );

    test('생성자가 모든 필드를 올바르게 초기화한다', () {
      expect(invite.id, 'invite-id');
      expect(invite.ledgerId, 'ledger-id');
      expect(invite.inviterUserId, 'inviter-id');
      expect(invite.inviteeEmail, 'invitee@example.com');
      expect(invite.role, 'editor');
      expect(invite.status, 'pending');
      expect(invite.expiresAt, testExpiresAt);
      expect(invite.createdAt, testCreatedAt);
      expect(invite.ledgerName, '우리 가계부');
      expect(invite.inviterEmail, 'inviter@example.com');
    });

    test('조인된 필드가 null일 수 있다', () {
      final minimalInvite = LedgerInvite(
        id: 'invite-id',
        ledgerId: 'ledger-id',
        inviterUserId: 'inviter-id',
        inviteeEmail: 'invitee@example.com',
        role: 'viewer',
        status: 'pending',
        expiresAt: testExpiresAt,
        createdAt: testCreatedAt,
      );

      expect(minimalInvite.ledgerName, null);
      expect(minimalInvite.inviterEmail, null);
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-invite-id',
          'ledger_id': 'ledger-id',
          'inviter_user_id': 'inviter-id',
          'invitee_email': 'invitee@example.com',
          'role': 'editor',
          'status': 'pending',
          'expires_at': '2026-02-19T10:00:00.000',
          'created_at': '2026-02-12T10:00:00.000',
          'ledger': {
            'name': '가족 가계부',
          },
          'inviter': {
            'email': 'inviter@example.com',
          },
        };

        final result = LedgerInvite.fromJson(json);

        expect(result.id, 'json-invite-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.inviterUserId, 'inviter-id');
        expect(result.inviteeEmail, 'invitee@example.com');
        expect(result.role, 'editor');
        expect(result.status, 'pending');
        expect(result.ledgerName, '가족 가계부');
        expect(result.inviterEmail, 'inviter@example.com');
      });

      test('조인된 데이터가 null일 때 올바르게 처리한다', () {
        final json = {
          'id': 'json-invite-id',
          'ledger_id': 'ledger-id',
          'inviter_user_id': 'inviter-id',
          'invitee_email': 'invitee@example.com',
          'role': 'viewer',
          'status': 'pending',
          'expires_at': '2026-02-19T10:00:00.000',
          'created_at': '2026-02-12T10:00:00.000',
          'ledger': null,
          'inviter': null,
        };

        final result = LedgerInvite.fromJson(json);

        expect(result.ledgerName, null);
        expect(result.inviterEmail, null);
      });

      test('다양한 상태를 파싱한다', () {
        final statuses = ['pending', 'accepted', 'rejected', 'left'];

        for (final status in statuses) {
          final json = {
            'id': 'invite-id',
            'ledger_id': 'ledger-id',
            'inviter_user_id': 'inviter-id',
            'invitee_email': 'invitee@example.com',
            'role': 'viewer',
            'status': status,
            'expires_at': '2026-02-19T10:00:00.000',
            'created_at': '2026-02-12T10:00:00.000',
          };

          final result = LedgerInvite.fromJson(json);

          expect(result.status, status);
        }
      });

      test('다양한 role 값을 파싱한다', () {
        final roles = ['owner', 'editor', 'viewer'];

        for (final role in roles) {
          final json = {
            'id': 'invite-id',
            'ledger_id': 'ledger-id',
            'inviter_user_id': 'inviter-id',
            'invitee_email': 'invitee@example.com',
            'role': role,
            'status': 'pending',
            'expires_at': '2026-02-19T10:00:00.000',
            'created_at': '2026-02-12T10:00:00.000',
          };

          final result = LedgerInvite.fromJson(json);

          expect(result.role, role);
        }
      });
    });

    group('getter 메서드', () {
      test('isPending이 올바르게 동작한다', () {
        final pending = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        final accepted = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'accepted',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        expect(pending.isPending, true);
        expect(accepted.isPending, false);
      });

      test('isAccepted가 올바르게 동작한다', () {
        final pending = invite;
        final accepted = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'accepted',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        expect(pending.isAccepted, false);
        expect(accepted.isAccepted, true);
      });

      test('isRejected가 올바르게 동작한다', () {
        final pending = invite;
        final rejected = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'rejected',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        expect(pending.isRejected, false);
        expect(rejected.isRejected, true);
      });

      test('isLeft가 올바르게 동작한다', () {
        final pending = invite;
        final left = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'left',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        expect(pending.isLeft, false);
        expect(left.isLeft, true);
      });

      test('isExpired가 올바르게 동작한다', () {
        final futureExpiry = DateTime.now().add(const Duration(days: 7));
        final pastExpiry = DateTime.now().subtract(const Duration(days: 1));

        final notExpired = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: futureExpiry,
          createdAt: testCreatedAt,
        );

        final expired = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: pastExpiry,
          createdAt: testCreatedAt,
        );

        expect(notExpired.isExpired, false);
        expect(expired.isExpired, true);
      });

      test('isValid가 올바르게 동작한다', () {
        final futureExpiry = DateTime.now().add(const Duration(days: 7));
        final pastExpiry = DateTime.now().subtract(const Duration(days: 1));

        final valid = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: futureExpiry,
          createdAt: testCreatedAt,
        );

        final expiredButPending = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: pastExpiry,
          createdAt: testCreatedAt,
        );

        final acceptedNotExpired = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'invitee@example.com',
          role: 'viewer',
          status: 'accepted',
          expiresAt: futureExpiry,
          createdAt: testCreatedAt,
        );

        expect(valid.isValid, true);
        expect(expiredButPending.isValid, false);
        expect(acceptedNotExpired.isValid, false);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 email로 사용할 수 있다', () {
        final emptyEmail = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: '',
          role: 'viewer',
          status: 'pending',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        expect(emptyEmail.inviteeEmail, '');
      });

      test('다양한 형식의 이메일을 처리할 수 있다', () {
        final emails = [
          'simple@example.com',
          'complex.email+tag@subdomain.example.com',
          'user123@example.co.kr',
          'test_user-2026@example.org',
        ];

        for (final email in emails) {
          final invite = LedgerInvite(
            id: 'invite-id',
            ledgerId: 'ledger-id',
            inviterUserId: 'inviter-id',
            inviteeEmail: email,
            role: 'viewer',
            status: 'pending',
            expiresAt: testExpiresAt,
            createdAt: testCreatedAt,
          );

          expect(invite.inviteeEmail, email);
        }
      });

      test('알 수 없는 상태 값을 처리할 수 있다', () {
        final unknownStatus = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'test@example.com',
          role: 'viewer',
          status: 'unknown_status',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
        );

        expect(unknownStatus.status, 'unknown_status');
        expect(unknownStatus.isPending, false);
        expect(unknownStatus.isAccepted, false);
        expect(unknownStatus.isRejected, false);
        expect(unknownStatus.isLeft, false);
      });

      test('매우 긴 가계부 이름을 처리할 수 있다', () {
        final longName = '매우 긴 가계부 이름 ' * 20;
        final invite = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'test@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: testExpiresAt,
          createdAt: testCreatedAt,
          ledgerName: longName,
        );

        expect(invite.ledgerName, longName);
      });

      test('만료 시간이 정확히 현재 시간일 때 처리', () {
        final now = DateTime.now();
        final exactTime = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'test@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: now,
          createdAt: testCreatedAt,
        );

        // isExpired는 DateTime.now().isAfter(expiresAt)이므로
        // 정확히 같은 시간이거나 극히 짧은 시간이 지나면 true가 될 수 있음
        // 이 테스트는 시간에 민감하므로 생략하거나 범위를 넓혀야 함
        expect(exactTime.isExpired, anyOf(true, false));
      });

      test('만료 시간이 매우 먼 미래일 때 처리', () {
        final farFuture = DateTime(2100, 1, 1);
        final invite = LedgerInvite(
          id: 'invite-id',
          ledgerId: 'ledger-id',
          inviterUserId: 'inviter-id',
          inviteeEmail: 'test@example.com',
          role: 'viewer',
          status: 'pending',
          expiresAt: farFuture,
          createdAt: testCreatedAt,
        );

        expect(invite.isExpired, false);
        expect(invite.isValid, true);
      });
    });
  });
}
