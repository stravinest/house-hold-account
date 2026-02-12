import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';

void main() {
  group('Ledger Entity', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);

    final ledger = Ledger(
      id: 'test-id',
      name: '우리 가족 가계부',
      description: '가족 공용 가계부입니다',
      currency: 'KRW',
      ownerId: 'owner-id',
      isShared: true,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
    );

    test('생성자가 모든 필드를 올바르게 초기화한다', () {
      expect(ledger.id, 'test-id');
      expect(ledger.name, '우리 가족 가계부');
      expect(ledger.description, '가족 공용 가계부입니다');
      expect(ledger.currency, 'KRW');
      expect(ledger.ownerId, 'owner-id');
      expect(ledger.isShared, true);
      expect(ledger.createdAt, testCreatedAt);
      expect(ledger.updatedAt, testUpdatedAt);
    });

    test('description이 null일 수 있다', () {
      final ledgerWithoutDesc = Ledger(
        id: 'test-id',
        name: '개인 가계부',
        currency: 'KRW',
        ownerId: 'owner-id',
        isShared: false,
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(ledgerWithoutDesc.description, null);
    });

    group('copyWith', () {
      test('특정 필드만 변경된다', () {
        final updated = ledger.copyWith(
          name: '회사 경비',
          currency: 'USD',
        );

        expect(updated.name, '회사 경비');
        expect(updated.currency, 'USD');
        expect(updated.id, ledger.id);
        expect(updated.ownerId, ledger.ownerId);
        expect(updated.description, ledger.description);
      });

      test('모든 필드를 변경할 수 있다', () {
        final newCreatedAt = DateTime(2026, 3, 1);
        final newUpdatedAt = DateTime(2026, 3, 2);

        final updated = ledger.copyWith(
          id: 'new-id',
          name: '새 가계부',
          description: '새 설명',
          currency: 'USD',
          ownerId: 'new-owner',
          isShared: false,
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
        );

        expect(updated.id, 'new-id');
        expect(updated.name, '새 가계부');
        expect(updated.description, '새 설명');
        expect(updated.currency, 'USD');
        expect(updated.ownerId, 'new-owner');
        expect(updated.isShared, false);
        expect(updated.createdAt, newCreatedAt);
        expect(updated.updatedAt, newUpdatedAt);
      });

      test('인자가 없으면 원본과 동일한 객체를 반환한다', () {
        final copied = ledger.copyWith();

        expect(copied.id, ledger.id);
        expect(copied.name, ledger.name);
        expect(copied.currency, ledger.currency);
        expect(copied.isShared, ledger.isShared);
      });
    });

    group('Equatable', () {
      test('동일한 속성을 가진 객체는 같다고 판단된다', () {
        final ledger1 = Ledger(
          id: 'test-id',
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final ledger2 = Ledger(
          id: 'test-id',
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(ledger1, ledger2);
      });

      test('다른 속성을 가진 객체는 다르다고 판단된다', () {
        final ledger1 = Ledger(
          id: 'test-id-1',
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final ledger2 = Ledger(
          id: 'test-id-2',
          name: '가계부',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(ledger1, isNot(ledger2));
      });
    });

    group('엣지 케이스', () {
      test('다양한 화폐 단위를 지원한다', () {
        final krw = ledger.copyWith(currency: 'KRW');
        final usd = ledger.copyWith(currency: 'USD');
        final jpy = ledger.copyWith(currency: 'JPY');
        final eur = ledger.copyWith(currency: 'EUR');

        expect(krw.currency, 'KRW');
        expect(usd.currency, 'USD');
        expect(jpy.currency, 'JPY');
        expect(eur.currency, 'EUR');
      });

      test('빈 문자열을 이름으로 사용할 수 있다', () {
        final emptyName = Ledger(
          id: 'test-id',
          name: '',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(emptyName.name, '');
      });

      test('빈 문자열을 설명으로 사용할 수 있다', () {
        final emptyDesc = Ledger(
          id: 'test-id',
          name: '가계부',
          description: '',
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(emptyDesc.description, '');
      });

      test('매우 긴 이름을 처리할 수 있다', () {
        final longName = '아주 긴 가계부 이름 ' * 20;
        final longNameLedger = Ledger(
          id: 'test-id',
          name: longName,
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(longNameLedger.name, longName);
      });

      test('매우 긴 설명을 처리할 수 있다', () {
        final longDesc = '아주 긴 설명 ' * 50;
        final longDescLedger = Ledger(
          id: 'test-id',
          name: '가계부',
          description: longDesc,
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(longDescLedger.description, longDesc);
      });

      test('특수 문자가 포함된 이름을 처리할 수 있다', () {
        final specialName = '가계부 @#\$%^&*() 2026년';
        final specialLedger = Ledger(
          id: 'test-id',
          name: specialName,
          currency: 'KRW',
          ownerId: 'owner-id',
          isShared: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(specialLedger.name, specialName);
      });
    });
  });

  group('LedgerMember Entity', () {
    final testJoinedAt = DateTime(2026, 2, 12, 10, 0, 0);

    final member = LedgerMember(
      id: 'member-id',
      ledgerId: 'ledger-id',
      userId: 'user-id',
      role: 'owner',
      joinedAt: testJoinedAt,
      displayName: '홍길동',
      email: 'hong@example.com',
      avatarUrl: 'https://example.com/avatar.jpg',
      color: '#FF5733',
    );

    test('생성자가 모든 필드를 올바르게 초기화한다', () {
      expect(member.id, 'member-id');
      expect(member.ledgerId, 'ledger-id');
      expect(member.userId, 'user-id');
      expect(member.role, 'owner');
      expect(member.joinedAt, testJoinedAt);
      expect(member.displayName, '홍길동');
      expect(member.email, 'hong@example.com');
      expect(member.avatarUrl, 'https://example.com/avatar.jpg');
      expect(member.color, '#FF5733');
    });

    test('선택적 필드들이 null일 수 있다', () {
      final minimalMember = LedgerMember(
        id: 'member-id',
        ledgerId: 'ledger-id',
        userId: 'user-id',
        role: 'viewer',
        joinedAt: testJoinedAt,
      );

      expect(minimalMember.displayName, null);
      expect(minimalMember.email, null);
      expect(minimalMember.avatarUrl, null);
      expect(minimalMember.color, null);
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'editor',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'display_name': '김철수',
            'email': 'kim@example.com',
            'avatar_url': 'https://example.com/kim.jpg',
            'color': '#00FF00',
          },
        };

        final result = LedgerMember.fromJson(json);

        expect(result.id, 'member-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.userId, 'user-id');
        expect(result.role, 'editor');
        expect(result.displayName, '김철수');
        expect(result.email, 'kim@example.com');
        expect(result.avatarUrl, 'https://example.com/kim.jpg');
        expect(result.color, '#00FF00');
      });

      test('프로필이 null일 때 올바르게 처리한다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'viewer',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': null,
        };

        final result = LedgerMember.fromJson(json);

        expect(result.displayName, null);
        expect(result.email, null);
        expect(result.avatarUrl, null);
        expect(result.color, null);
      });

      test('프로필 필드가 부분적으로 null일 때 처리한다', () {
        final json = {
          'id': 'member-id',
          'ledger_id': 'ledger-id',
          'user_id': 'user-id',
          'role': 'editor',
          'created_at': '2026-02-12T10:00:00.000',
          'profiles': {
            'email': 'test@example.com',
          },
        };

        final result = LedgerMember.fromJson(json);

        expect(result.displayName, null);
        expect(result.email, 'test@example.com');
        expect(result.avatarUrl, null);
        expect(result.color, null);
      });
    });

    group('getter 메서드', () {
      test('isOwner가 올바르게 동작한다', () {
        final owner = member.copyWith(role: 'owner');
        final editor = member.copyWith(role: 'editor');
        final viewer = member.copyWith(role: 'viewer');

        expect(owner.isOwner, true);
        expect(editor.isOwner, false);
        expect(viewer.isOwner, false);
      });

      test('isEditor가 올바르게 동작한다', () {
        final owner = member.copyWith(role: 'owner');
        final editor = member.copyWith(role: 'editor');
        final viewer = member.copyWith(role: 'viewer');

        expect(owner.isEditor, false);
        expect(editor.isEditor, true);
        expect(viewer.isEditor, false);
      });

      test('isViewer가 올바르게 동작한다', () {
        final owner = member.copyWith(role: 'owner');
        final editor = member.copyWith(role: 'editor');
        final viewer = member.copyWith(role: 'viewer');

        expect(owner.isViewer, false);
        expect(editor.isViewer, false);
        expect(viewer.isViewer, true);
      });

      test('canEdit이 올바르게 동작한다', () {
        final owner = member.copyWith(role: 'owner');
        final editor = member.copyWith(role: 'editor');
        final viewer = member.copyWith(role: 'viewer');

        expect(owner.canEdit, true);
        expect(editor.canEdit, true);
        expect(viewer.canEdit, false);
      });
    });

    group('Equatable', () {
      test('동일한 속성을 가진 객체는 같다고 판단된다', () {
        final member1 = LedgerMember(
          id: 'member-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          role: 'owner',
          joinedAt: testJoinedAt,
        );

        final member2 = LedgerMember(
          id: 'member-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          role: 'owner',
          joinedAt: testJoinedAt,
        );

        expect(member1, member2);
      });

      test('다른 속성을 가진 객체는 다르다고 판단된다', () {
        final member1 = LedgerMember(
          id: 'member-id-1',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          role: 'owner',
          joinedAt: testJoinedAt,
        );

        final member2 = LedgerMember(
          id: 'member-id-2',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          role: 'owner',
          joinedAt: testJoinedAt,
        );

        expect(member1, isNot(member2));
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열을 displayName으로 사용할 수 있다', () {
        final emptyName = LedgerMember(
          id: 'member-id',
          ledgerId: 'ledger-id',
          userId: 'user-id',
          role: 'viewer',
          joinedAt: testJoinedAt,
          displayName: '',
        );

        expect(emptyName.displayName, '');
      });

      test('다양한 role 값을 지원한다', () {
        final owner = member.copyWith(role: 'owner');
        final editor = member.copyWith(role: 'editor');
        final viewer = member.copyWith(role: 'viewer');

        expect(owner.role, 'owner');
        expect(editor.role, 'editor');
        expect(viewer.role, 'viewer');
      });

      test('알 수 없는 role 값을 처리할 수 있다', () {
        final unknownRole = member.copyWith(role: 'unknown');

        expect(unknownRole.role, 'unknown');
        expect(unknownRole.isOwner, false);
        expect(unknownRole.isEditor, false);
        expect(unknownRole.isViewer, false);
        expect(unknownRole.canEdit, false);
      });
    });
  });
}

extension on LedgerMember {
  LedgerMember copyWith({
    String? id,
    String? ledgerId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    String? displayName,
    String? email,
    String? avatarUrl,
    String? color,
  }) {
    return LedgerMember(
      id: id ?? this.id,
      ledgerId: ledgerId ?? this.ledgerId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      color: color ?? this.color,
    );
  }
}
