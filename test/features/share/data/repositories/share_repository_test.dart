import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/share/data/repositories/share_repository.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockFunctionsClient mockFunctions;
  late ShareRepository repository;

  const testLedgerId = 'ledger-123';
  const testUserId = 'user-123';
  const testUserEmail = 'owner@example.com';
  const testInviteeEmail = 'invitee@example.com';
  const testInviteId = 'invite-abc';

  Map<String, dynamic> buildInviteJson({
    String id = testInviteId,
    String ledgerId = testLedgerId,
    String inviterUserId = testUserId,
    String inviteeEmail = testInviteeEmail,
    String role = 'admin',
    String status = 'pending',
    String? expiresAt,
    String? createdAt,
  }) {
    return {
      'id': id,
      'ledger_id': ledgerId,
      'inviter_user_id': inviterUserId,
      'invitee_email': inviteeEmail,
      'role': role,
      'status': status,
      'expires_at': expiresAt ?? '2099-12-31T10:00:00.000',
      'created_at': createdAt ?? '2026-01-01T10:00:00.000',
      'ledger': {'name': '우리 가계부'},
      'inviter': {'email': testUserEmail},
    };
  }

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockFunctions = MockFunctionsClient();

    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn(testUserId);
    when(() => mockUser.email).thenReturn(testUserEmail);
    when(() => mockClient.functions).thenReturn(mockFunctions);
    when(
      () => mockFunctions.invoke(any(), body: any(named: 'body')),
    ).thenAnswer((_) async => MockFunctionResponse());

    repository = ShareRepository(client: mockClient);
  });

  // ================================================================
  // findUserByEmail
  // ================================================================
  group('ShareRepository - findUserByEmail', () {
    test('rpc 응답이 null이면 null을 반환한다', () async {
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(null));

      final result = await repository.findUserByEmail(testInviteeEmail);

      expect(result, isNull);
    });

    test('rpc 응답이 빈 리스트이면 null을 반환한다', () async {
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>([]));

      final result = await repository.findUserByEmail(testInviteeEmail);

      expect(result, isNull);
    });

    test('rpc 응답에 사용자가 존재하면 첫 번째 요소를 Map으로 반환한다', () async {
      final userData = {'id': 'user-456', 'email': testInviteeEmail};

      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(
            [userData, {'id': 'other', 'email': 'other@example.com'}],
          ));

      final result = await repository.findUserByEmail(testInviteeEmail);

      expect(result, isNotNull);
      expect(result!['id'], 'user-456');
      expect(result['email'], testInviteeEmail);
    });
  });

  // ================================================================
  // isAlreadyMember
  // ================================================================
  group('ShareRepository - isAlreadyMember', () {
    test('사용자가 해당 가계부의 멤버이면 true를 반환한다', () async {
      // findUserByEmail: 사용자 존재
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(
            [{'id': 'user-456', 'email': testInviteeEmail}],
          ));

      // ledger_members: 멤버 데이터 존재
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: {'id': 'member-1', 'role': 'admin'},
          hasMaybeSingleData: true,
        ),
      );

      final result = await repository.isAlreadyMember(
        ledgerId: testLedgerId,
        email: testInviteeEmail,
      );

      expect(result, isTrue);
    });

    test('이메일에 해당하는 사용자가 없으면 false를 반환한다', () async {
      // findUserByEmail: 사용자 없음
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(null));

      final result = await repository.isAlreadyMember(
        ledgerId: testLedgerId,
        email: 'unknown@example.com',
      );

      expect(result, isFalse);
    });
  });

  // ================================================================
  // getMemberCount
  // ================================================================
  group('ShareRepository - getMemberCount', () {
    test('가계부의 현재 멤버 수를 정확하게 반환한다', () async {
      final memberList = [
        {'id': 'member-1'},
        {'id': 'member-2'},
      ];

      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: memberList),
      );

      final count = await repository.getMemberCount(testLedgerId);

      expect(count, 2);
    });
  });

  // ================================================================
  // isMemberLimitReached
  // ================================================================
  group('ShareRepository - isMemberLimitReached', () {
    test('멤버 수가 최대 허용 인원(2명)에 도달하면 true를 반환한다', () async {
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          selectData: [{'id': 'member-1'}, {'id': 'member-2'}],
        ),
      );

      final result = await repository.isMemberLimitReached(testLedgerId);

      expect(result, isTrue);
    });

    test('멤버 수가 최대 허용 인원 미만이면 false를 반환한다', () async {
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          selectData: [{'id': 'member-1'}],
        ),
      );

      final result = await repository.isMemberLimitReached(testLedgerId);

      expect(result, isFalse);
    });
  });

  // ================================================================
  // createInvite
  // ================================================================
  group('ShareRepository - createInvite', () {
    test('자기 자신을 초대하려고 하면 예외가 발생한다', () async {
      // 초대 대상 이메일이 현재 사용자 이메일과 동일한 경우
      expect(
        () => repository.createInvite(
          ledgerId: testLedgerId,
          inviteeEmail: testUserEmail, // 자기 자신
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Cannot invite yourself'),
          ),
        ),
      );
    });

    test('가입되지 않은 이메일로 초대하면 예외가 발생한다', () async {
      // findUserByEmail: null 반환 (미가입 사용자)
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(null));

      expect(
        () => repository.createInvite(
          ledgerId: testLedgerId,
          inviteeEmail: 'notregistered@example.com',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Email not registered'),
          ),
        ),
      );
    });

    test('이미 멤버인 사용자를 초대하면 예외가 발생한다', () async {
      // findUserByEmail: 사용자 존재
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(
            [{'id': 'user-456', 'email': testInviteeEmail}],
          ));

      // isAlreadyMember -> ledger_members: 멤버 존재
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: {'id': 'member-1', 'role': 'admin'},
          hasMaybeSingleData: true,
        ),
      );

      expect(
        () => repository.createInvite(
          ledgerId: testLedgerId,
          inviteeEmail: testInviteeEmail,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Already a member'),
          ),
        ),
      );
    });
  });

  // ================================================================
  // acceptInvite
  // ================================================================
  group('ShareRepository - acceptInvite', () {
    test('초대 수락 rpc가 success:true를 반환하면 정상 완료된다', () async {
      when(
        () => mockClient.rpc(
          'accept_ledger_invite',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>({'success': true}));

      // _fetchAndSendAcceptNotification 내부 ledger_invites 조회 (백그라운드)
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: buildInviteJson(status: 'accepted'),
          hasMaybeSingleData: true,
        ),
      );

      await expectLater(
        repository.acceptInvite(testInviteId),
        completes,
      );
    });

    test('초대 수락 rpc가 NOT_FOUND 오류를 반환하면 적절한 에러 메시지와 함께 예외가 발생한다', () async {
      when(
        () => mockClient.rpc(
          'accept_ledger_invite',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>({
            'success': false,
            'error_code': 'NOT_FOUND',
          }));

      expect(
        () => repository.acceptInvite(testInviteId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Invitation not found'),
          ),
        ),
      );
    });

    test('초대 수락 rpc가 MEMBER_LIMIT_REACHED 오류를 반환하면 적절한 에러 메시지와 함께 예외가 발생한다', () async {
      when(
        () => mockClient.rpc(
          'accept_ledger_invite',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>({
            'success': false,
            'error_code': 'MEMBER_LIMIT_REACHED',
          }));

      expect(
        () => repository.acceptInvite(testInviteId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('member limit'),
          ),
        ),
      );
    });

    test('초대 수락 rpc가 INVALID_STATUS 오류를 반환하면 적절한 에러 메시지와 함께 예외가 발생한다', () async {
      when(
        () => mockClient.rpc(
          'accept_ledger_invite',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>({
            'success': false,
            'error_code': 'INVALID_STATUS',
          }));

      expect(
        () => repository.acceptInvite(testInviteId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('already processed'),
          ),
        ),
      );
    });
  });

  // ================================================================
  // cancelInvite
  // ================================================================
  group('ShareRepository - cancelInvite', () {
    test('초대 취소 시 ledger_invites 테이블에서 해당 레코드가 삭제된다', () async {
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(),
      );

      await expectLater(
        repository.cancelInvite(testInviteId),
        completes,
      );

      verify(() => mockClient.from('ledger_invites')).called(1);
    });
  });

  // ================================================================
  // getReceivedInvites
  // ================================================================
  group('ShareRepository - getReceivedInvites', () {
    test('현재 사용자 이메일로 pending/accepted 초대 목록을 반환한다', () async {
      final inviteList = [
        buildInviteJson(status: 'pending'),
        buildInviteJson(id: 'invite-def', status: 'accepted'),
      ];

      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: inviteList),
      );

      final result = await repository.getReceivedInvites();

      expect(result, isA<List<LedgerInvite>>());
      expect(result.length, 2);
      expect(result[0].status, 'pending');
      expect(result[1].status, 'accepted');
    });

    test('로그인된 사용자가 없으면 빈 리스트를 반환한다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.getReceivedInvites();

      expect(result, isEmpty);
    });
  });

  // ================================================================
  // getSentInvites
  // ================================================================
  group('ShareRepository - getSentInvites', () {
    test('특정 가계부의 left 상태를 제외한 초대 목록을 반환한다', () async {
      final inviteList = [
        buildInviteJson(status: 'pending'),
        buildInviteJson(id: 'invite-def', status: 'rejected'),
      ];

      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: inviteList),
      );

      final result = await repository.getSentInvites(testLedgerId);

      expect(result, isA<List<LedgerInvite>>());
      expect(result.length, 2);
    });

    test('초대 목록이 없으면 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      final result = await repository.getSentInvites(testLedgerId);

      expect(result, isEmpty);
    });
  });

  // ================================================================
  // hasPendingInvite
  // ================================================================
  group('ShareRepository - hasPendingInvite', () {
    test('대기 중인 초대가 존재하면 true를 반환한다', () async {
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: {'id': testInviteId},
          hasMaybeSingleData: true,
        ),
      );

      final result = await repository.hasPendingInvite(
        ledgerId: testLedgerId,
        email: testInviteeEmail,
      );

      expect(result, isTrue);
    });

    test('대기 중인 초대가 없으면 false를 반환한다', () async {
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          hasMaybeSingleData: true,
          maybeSingleData: null,
        ),
      );

      final result = await repository.hasPendingInvite(
        ledgerId: testLedgerId,
        email: testInviteeEmail,
      );

      expect(result, isFalse);
    });
  });

  // ================================================================
  // getMembers
  // ================================================================
  group('ShareRepository - getMembers', () {
    test('가계부의 멤버 목록을 반환한다', () async {
      final memberList = [
        {
          'id': 'member-1',
          'ledger_id': testLedgerId,
          'user_id': testUserId,
          'role': 'owner',
          'created_at': '2026-01-01T00:00:00.000',
          'profiles': {
            'email': testUserEmail,
            'display_name': '홍길동',
            'avatar_url': null,
            'color': null,
          },
        },
        {
          'id': 'member-2',
          'ledger_id': testLedgerId,
          'user_id': 'user-456',
          'role': 'admin',
          'created_at': '2026-01-02T00:00:00.000',
          'profiles': {
            'email': testInviteeEmail,
            'display_name': '김철수',
            'avatar_url': null,
            'color': '#FF0000',
          },
        },
      ];

      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: memberList),
      );

      final result = await repository.getMembers(testLedgerId);

      expect(result.length, 2);
      expect(result[0].role, 'owner');
      expect(result[0].email, testUserEmail);
      expect(result[1].role, 'admin');
      expect(result[1].color, '#FF0000');
    });

    test('멤버가 없으면 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      final result = await repository.getMembers(testLedgerId);

      expect(result, isEmpty);
    });
  });

  // ================================================================
  // updateMemberRole
  // ================================================================
  group('ShareRepository - updateMemberRole', () {
    test('멤버 역할 변경이 정상적으로 완료된다', () async {
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(),
      );

      await expectLater(
        repository.updateMemberRole(
          ledgerId: testLedgerId,
          userId: 'user-456',
          role: 'admin',
        ),
        completes,
      );

      verify(() => mockClient.from('ledger_members')).called(1);
    });
  });

  // ================================================================
  // removeMember
  // ================================================================
  group('ShareRepository - removeMember', () {
    test('멤버 제거 시 ledger_members에서 삭제하고 초대 상태를 left로 변경한다', () async {
      // ledger_members 삭제 + profiles 조회 + ledger_invites 업데이트
      var fromCallCount = 0;

      when(() => mockClient.from('ledger_members')).thenAnswer((_) {
        fromCallCount++;
        return FakeSupabaseQueryBuilder();
      });

      when(() => mockClient.from('profiles')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: {'email': testInviteeEmail},
          hasMaybeSingleData: true,
        ),
      );

      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(),
      );

      await expectLater(
        repository.removeMember(
          ledgerId: testLedgerId,
          userId: 'user-456',
        ),
        completes,
      );
    });

    test('프로필 조회 결과가 null이어도 정상 완료된다', () async {
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(),
      );

      when(() => mockClient.from('profiles')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          hasMaybeSingleData: true,
          maybeSingleData: null,
        ),
      );

      await expectLater(
        repository.removeMember(
          ledgerId: testLedgerId,
          userId: 'user-456',
        ),
        completes,
      );
    });
  });

  // ================================================================
  // rejectInvite
  // ================================================================
  group('ShareRepository - rejectInvite', () {
    test('초대 거부 시 상태를 rejected로 업데이트한다', () async {
      final inviteJson = buildInviteJson(status: 'pending');

      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          singleData: inviteJson,
          selectData: [inviteJson],
        ),
      );

      await expectLater(
        repository.rejectInvite(testInviteId),
        completes,
      );

      verify(() => mockClient.from('ledger_invites')).called(greaterThan(0));
    });
  });

  // ================================================================
  // leaveLedger
  // ================================================================
  group('ShareRepository - leaveLedger', () {
    test('현재 로그인 사용자가 가계부를 탈퇴한다', () async {
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(),
      );

      when(() => mockClient.from('profiles')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: {'email': testUserEmail},
          hasMaybeSingleData: true,
        ),
      );

      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(),
      );

      await expectLater(
        repository.leaveLedger(testLedgerId),
        completes,
      );
    });

    test('로그인된 사용자가 없으면 예외가 발생한다', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => repository.leaveLedger(testLedgerId),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Login required'),
          ),
        ),
      );
    });
  });

  // ================================================================
  // getReceivedInvites - 이메일이 빈 문자열인 경우
  // ================================================================
  group('ShareRepository - getReceivedInvites 추가 케이스', () {
    test('사용자 이메일이 빈 문자열이면 빈 리스트를 반환한다', () async {
      when(() => mockUser.email).thenReturn('');

      final result = await repository.getReceivedInvites();

      expect(result, isEmpty);
    });
  });

  // ================================================================
  // createInvite - 추가 케이스
  // ================================================================
  group('ShareRepository - createInvite 추가 케이스', () {
    test('이미 대기 중인 초대가 있으면 예외가 발생한다', () async {
      // findUserByEmail: 사용자 존재
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(
            [{'id': 'user-456', 'email': testInviteeEmail}],
          ));

      // isAlreadyMember -> 멤버 아님
      when(() => mockClient.from('ledger_members')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          hasMaybeSingleData: true,
          maybeSingleData: null,
        ),
      );

      // hasPendingInvite -> 대기 중인 초대 존재
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: {'id': testInviteId},
          hasMaybeSingleData: true,
        ),
      );

      expect(
        () => repository.createInvite(
          ledgerId: testLedgerId,
          inviteeEmail: testInviteeEmail,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Invitation already sent'),
          ),
        ),
      );
    });

    test('멤버 수가 최대치에 도달하면 예외가 발생한다', () async {
      // findUserByEmail: 사용자 존재
      when(
        () => mockClient.rpc(
          'check_user_exists_by_email',
          params: any(named: 'params'),
        ),
      ).thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(
            [{'id': 'user-456', 'email': testInviteeEmail}],
          ));

      var ledgerMembersCallCount = 0;

      when(() => mockClient.from('ledger_members')).thenAnswer((_) {
        ledgerMembersCallCount++;
        if (ledgerMembersCallCount == 1) {
          // isAlreadyMember -> 멤버 아님
          return FakeSupabaseQueryBuilder(
            hasMaybeSingleData: true,
            maybeSingleData: null,
          );
        }
        // getMemberCount -> 최대 멤버 수
        return FakeSupabaseQueryBuilder(
          selectData: [{'id': 'member-1'}, {'id': 'member-2'}],
        );
      });

      // hasPendingInvite -> 대기 중인 초대 없음
      when(() => mockClient.from('ledger_invites')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          hasMaybeSingleData: true,
          maybeSingleData: null,
        ),
      );

      expect(
        () => repository.createInvite(
          ledgerId: testLedgerId,
          inviteeEmail: testInviteeEmail,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            '예외 메시지',
            contains('Maximum'),
          ),
        ),
      );
    });
  });
}
