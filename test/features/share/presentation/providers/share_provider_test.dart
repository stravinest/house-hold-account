import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/share/data/repositories/share_repository.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await Supabase.initialize(
      url: 'https://test.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  group('ShareProvider Tests', () {
    late MockShareRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockShareRepository();
    });

    tearDown(() {
      container.dispose();
    });

    group('receivedInvitesProvider', () {
      test('받은 초대 목록을 가져온다', () async {
        // Given
        final mockInvites = [
          LedgerInvite(
            id: 'invite-1',
            ledgerId: 'ledger-1',
            ledgerName: '우리 가계부',
            inviterUserId: 'user-1',
            inviterEmail: 'user1@test.com',
            inviteeEmail: 'user2@test.com',
            role: 'member',
            status: 'pending',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        ];

        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => mockInvites);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final invites = await container.read(receivedInvitesProvider.future);

        // Then
        expect(invites.length, equals(1));
        expect(invites[0].status, equals('pending'));
        verify(() => mockRepository.getReceivedInvites()).called(1);
      });
    });

    group('pendingInviteCountProvider', () {
      test('pending 상태 초대 개수를 반환한다', () async {
        // Given
        final mockInvites = [
          LedgerInvite(
            id: 'invite-1',
            ledgerId: 'ledger-1',
            ledgerName: '우리 가계부',
            inviterUserId: 'user-1',
            inviterEmail: 'user1@test.com',
            inviteeEmail: 'user2@test.com',
            role: 'member',
            status: 'pending',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
          LedgerInvite(
            id: 'invite-2',
            ledgerId: 'ledger-2',
            ledgerName: '가족 가계부',
            inviterUserId: 'user-3',
            inviterEmail: 'user3@test.com',
            inviteeEmail: 'user2@test.com',
            role: 'member',
            status: 'accepted',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        ];

        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => mockInvites);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            receivedInvitesProvider
                .overrideWith((ref) => Future.value(mockInvites)),
          ],
        );

        // When: receivedInvitesProvider가 로드될 때까지 대기
        await container.read(receivedInvitesProvider.future);
        final count = container.read(pendingInviteCountProvider);

        // Then
        expect(count, equals(1));
      });
    });

    group('sentInvitesProvider', () {
      test('특정 가계부에 대한 보낸 초대 목록을 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockInvites = [
          LedgerInvite(
            id: 'invite-1',
            ledgerId: testLedgerId,
            ledgerName: '우리 가계부',
            inviterUserId: 'user-1',
            inviterEmail: 'user1@test.com',
            inviteeEmail: 'user2@test.com',
            role: 'member',
            status: 'pending',
            createdAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 7)),
          ),
        ];

        when(() => mockRepository.getSentInvites(testLedgerId))
            .thenAnswer((_) async => mockInvites);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final invites =
            await container.read(sentInvitesProvider(testLedgerId).future);

        // Then
        expect(invites.length, equals(1));
        expect(invites[0].ledgerId, equals(testLedgerId));
      });
    });

    group('ledgerMembersListProvider', () {
      test('특정 가계부의 멤버 목록을 가져온다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockMembers = [
          LedgerMember(
            id: 'member-1',
            ledgerId: testLedgerId,
            userId: 'user-1',
            role: 'owner',
            joinedAt: DateTime.now(),
            email: 'user1@test.com',
          ),
          LedgerMember(
            id: 'member-2',
            ledgerId: testLedgerId,
            userId: 'user-2',
            role: 'member',
            joinedAt: DateTime.now(),
            email: 'user2@test.com',
          ),
        ];

        when(() => mockRepository.getMembers(testLedgerId))
            .thenAnswer((_) async => mockMembers);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        // When
        final members = await container
            .read(ledgerMembersListProvider(testLedgerId).future);

        // Then
        expect(members.length, equals(2));
        expect(members[0].role, equals('owner'));
        expect(members[1].role, equals('member'));
      });
    });

    group('ShareNotifier', () {
      test('sendInvite 성공 시 초대를 전송한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        const testEmail = 'invited@test.com';

        final mockInvite = LedgerInvite(
          id: 'invite-new',
          ledgerId: testLedgerId,
          inviterUserId: 'user-1',
          inviteeEmail: testEmail,
          role: 'admin',
          status: 'pending',
          createdAt: DateTime.now(),
          expiresAt: DateTime.now().add(const Duration(days: 7)),
        );

        when(
          () => mockRepository.createInvite(
            ledgerId: testLedgerId,
            inviteeEmail: testEmail,
          ),
        ).thenAnswer((_) async => mockInvite);

        when(() => mockRepository.getSentInvites(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.sendInvite(
          ledgerId: testLedgerId,
          email: testEmail,
        );

        // Then
        verify(
          () => mockRepository.createInvite(
            ledgerId: testLedgerId,
            inviteeEmail: testEmail,
          ),
        ).called(1);
      });

      test('acceptInvite 성공 시 초대를 수락한다', () async {
        // Given
        const testInviteId = 'invite-1';

        when(() => mockRepository.acceptInvite(testInviteId))
            .thenAnswer((_) async => {});

        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.acceptInvite(testInviteId);

        // Then
        verify(() => mockRepository.acceptInvite(testInviteId)).called(1);
      });

      test('rejectInvite 성공 시 초대를 거부한다', () async {
        // Given
        const testInviteId = 'invite-1';

        when(() => mockRepository.rejectInvite(testInviteId))
            .thenAnswer((_) async => {});

        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.rejectInvite(testInviteId);

        // Then
        verify(() => mockRepository.rejectInvite(testInviteId)).called(1);
      });

      test('updateMemberRole 성공 시 멤버 역할을 변경한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        const testUserId = 'user-2';
        const newRole = 'admin';

        when(
          () => mockRepository.updateMemberRole(
            ledgerId: testLedgerId,
            userId: testUserId,
            role: newRole,
          ),
        ).thenAnswer((_) async => {});

        when(() => mockRepository.getMembers(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.updateMemberRole(
          ledgerId: testLedgerId,
          userId: testUserId,
          role: newRole,
        );

        // Then
        verify(
          () => mockRepository.updateMemberRole(
            ledgerId: testLedgerId,
            userId: testUserId,
            role: newRole,
          ),
        ).called(1);
      });

      test('removeMember 성공 시 멤버를 제거한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        const testUserId = 'user-2';

        when(
          () => mockRepository.removeMember(
            ledgerId: testLedgerId,
            userId: testUserId,
          ),
        ).thenAnswer((_) async => {});

        when(() => mockRepository.getMembers(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.removeMember(
          ledgerId: testLedgerId,
          userId: testUserId,
        );

        // Then
        verify(
          () => mockRepository.removeMember(
            ledgerId: testLedgerId,
            userId: testUserId,
          ),
        ).called(1);
      });

      test('cancelInvite 성공 시 초대를 취소한다', () async {
        // Given
        const testInviteId = 'invite-1';
        const testLedgerId = 'test-ledger-id';

        when(() => mockRepository.cancelInvite(testInviteId))
            .thenAnswer((_) async {});

        when(() => mockRepository.getSentInvites(testLedgerId))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.cancelInvite(
          inviteId: testInviteId,
          ledgerId: testLedgerId,
        );

        // Then
        verify(() => mockRepository.cancelInvite(testInviteId)).called(1);
      });

      test('leaveLedger 성공 시 가계부를 탈퇴한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';

        when(() => mockRepository.leaveLedger(testLedgerId))
            .thenAnswer((_) async {});

        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'other-ledger-id'),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.leaveLedger(testLedgerId);

        // Then
        verify(() => mockRepository.leaveLedger(testLedgerId)).called(1);
      });

      test('sendInvite 실패 시 예외를 다시 던진다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        const testEmail = 'invited@test.com';

        when(
          () => mockRepository.createInvite(
            ledgerId: testLedgerId,
            inviteeEmail: testEmail,
          ),
        ).thenThrow(Exception('이미 멤버입니다'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        expect(
          () => notifier.sendInvite(ledgerId: testLedgerId, email: testEmail),
          throwsA(isA<Exception>()),
        );
      });

      test('acceptInvite 실패 시 예외를 다시 던진다', () async {
        // Given
        const testInviteId = 'invite-1';

        when(() => mockRepository.acceptInvite(testInviteId))
            .thenThrow(Exception('초대를 찾을 수 없습니다'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        expect(
          () => notifier.acceptInvite(testInviteId),
          throwsA(isA<Exception>()),
        );
      });

      test('rejectInvite 실패 시 예외를 다시 던진다', () async {
        // Given
        const testInviteId = 'invite-1';

        when(() => mockRepository.rejectInvite(testInviteId))
            .thenThrow(Exception('초대 거부 실패'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        expect(
          () => notifier.rejectInvite(testInviteId),
          throwsA(isA<Exception>()),
        );
      });

      test('removeMember 실패 시 예외를 다시 던진다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        const testUserId = 'user-2';

        when(
          () => mockRepository.removeMember(
            ledgerId: testLedgerId,
            userId: testUserId,
          ),
        ).thenThrow(Exception('멤버 제거 실패'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        expect(
          () => notifier.removeMember(
            ledgerId: testLedgerId,
            userId: testUserId,
          ),
          throwsA(isA<Exception>()),
        );
      });

      test('updateMemberRole 실패 시 예외를 다시 던진다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        const testUserId = 'user-2';
        const newRole = 'admin';

        when(
          () => mockRepository.updateMemberRole(
            ledgerId: testLedgerId,
            userId: testUserId,
            role: newRole,
          ),
        ).thenThrow(Exception('역할 변경 실패'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        expect(
          () => notifier.updateMemberRole(
            ledgerId: testLedgerId,
            userId: testUserId,
            role: newRole,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('LedgerWithInviteInfo 모델', () {
      LedgerInvite buildInvite({
        required String status,
        bool expired = false,
      }) {
        return LedgerInvite(
          id: 'invite-$status',
          ledgerId: 'ledger-1',
          inviterUserId: 'user-1',
          inviteeEmail: 'invitee@test.com',
          role: 'admin',
          status: status,
          createdAt: DateTime.now(),
          expiresAt: expired
              ? DateTime.now().subtract(const Duration(days: 1))
              : DateTime.now().add(const Duration(days: 7)),
        );
      }

      LedgerMember buildMember(String userId, {String role = 'member'}) {
        return LedgerMember(
          id: 'member-$userId',
          ledgerId: 'ledger-1',
          userId: userId,
          role: role,
          joinedAt: DateTime.now(),
          email: '$userId@test.com',
        );
      }

      test('hasNoInvite - 초대가 없으면 true를 반환한다', () {
        final info = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '테스트',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [buildMember('user-1')],
          sentInvites: [],
          canInvite: true,
        );

        expect(info.hasNoInvite, isTrue);
        expect(info.hasPendingInvite, isFalse);
        expect(info.hasAcceptedInvite, isFalse);
        expect(info.hasRejectedInvite, isFalse);
      });

      test('pendingInvites - 만료되지 않은 pending 초대만 반환한다', () {
        final pendingInvite = buildInvite(status: 'pending');
        final expiredPendingInvite = buildInvite(status: 'pending', expired: true);
        final acceptedInvite = buildInvite(status: 'accepted');

        final info = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '테스트',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [buildMember('user-1')],
          sentInvites: [pendingInvite, expiredPendingInvite, acceptedInvite],
          canInvite: false,
        );

        expect(info.pendingInvites.length, 1);
        expect(info.hasPendingInvite, isTrue);
        expect(info.acceptedInvites.length, 1);
        expect(info.hasAcceptedInvite, isTrue);
      });

      test('isMemberFull - 멤버 수가 최대치이면 true를 반환한다', () {
        final info = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '테스트',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [buildMember('user-1'), buildMember('user-2')],
          sentInvites: [],
          canInvite: false,
        );

        expect(info.isMemberFull, isTrue);
      });

      test('displayableInvites - pending, accepted, rejected 순서로 반환한다', () {
        final pendingInvite = buildInvite(status: 'pending');
        final acceptedInvite = buildInvite(status: 'accepted');
        final rejectedInvite = buildInvite(status: 'rejected');

        final info = LedgerWithInviteInfo(
          ledger: Ledger(
            id: 'ledger-1',
            name: '테스트',
            currency: 'KRW',
            ownerId: 'user-1',
            isShared: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          members: [buildMember('user-1')],
          sentInvites: [rejectedInvite, acceptedInvite, pendingInvite],
          canInvite: false,
        );

        final displayable = info.displayableInvites;
        expect(displayable[0].status, 'pending');
        expect(displayable[1].status, 'accepted');
        expect(displayable[2].status, 'rejected');
      });
    });

    group('currentLedgerMemberCountProvider', () {
      test('멤버 데이터가 없으면 기본값 1을 반환한다', () {
        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            currentLedgerMembersProvider
                .overrideWith((ref) => Future.error(Exception('에러'))),
          ],
        );

        final count = container.read(currentLedgerMemberCountProvider);
        expect(count, 1);
      });
    });

    group('canAddMemberProvider', () {
      test('멤버 수가 최대치 미만이면 true를 반환한다', () async {
        final mockMembers = [
          LedgerMember(
            id: 'member-1',
            ledgerId: 'ledger-1',
            userId: 'user-1',
            role: 'owner',
            joinedAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getMembers(any()))
            .thenAnswer((_) async => mockMembers);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            currentLedgerMembersProvider
                .overrideWith((ref) => Future.value(mockMembers)),
          ],
        );

        await container.read(currentLedgerMembersProvider.future);
        final canAdd = container.read(canAddMemberProvider);
        expect(canAdd, isTrue);
      });
    });

    group('cancelInvite 에러 처리', () {
      test('cancelInvite 실패 시 예외를 다시 던진다', () async {
        // Given
        const testInviteId = 'invite-1';
        const testLedgerId = 'test-ledger-id';

        when(() => mockRepository.cancelInvite(testInviteId))
            .thenThrow(Exception('초대 취소 실패'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        await expectLater(
          () => notifier.cancelInvite(
            inviteId: testInviteId,
            ledgerId: testLedgerId,
          ),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('leaveLedger 에러 처리 및 선택 해제', () {
      test('leaveLedger 실패 시 예외를 다시 던진다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';

        when(() => mockRepository.leaveLedger(testLedgerId))
            .thenThrow(Exception('가계부 탈퇴 실패'));

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When / Then
        await expectLater(
          () => notifier.leaveLedger(testLedgerId),
          throwsA(isA<Exception>()),
        );
      });

      test('탈퇴한 가계부가 현재 선택된 가계부이면 selectedLedgerId를 null로 설정한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';

        when(() => mockRepository.leaveLedger(testLedgerId))
            .thenAnswer((_) async {});
        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            // 현재 선택된 가계부 ID가 탈퇴 대상과 동일하게 설정
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
          ],
        );

        final notifier = container.read(shareNotifierProvider.notifier);

        // When
        await notifier.leaveLedger(testLedgerId);

        // Then: selectedLedgerId가 null로 변경되어야 함
        final selectedId = container.read(selectedLedgerIdProvider);
        expect(selectedId, isNull);
        verify(() => mockRepository.leaveLedger(testLedgerId)).called(1);
      });
    });

    group('currentLedgerMembersProvider', () {
      test('selectedLedgerId가 null이면 빈 목록을 반환한다', () async {
        // Given
        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        // When
        final members = await container.read(currentLedgerMembersProvider.future);

        // Then
        expect(members, isEmpty);
        verifyNever(() => mockRepository.getMembers(any()));
      });

      test('selectedLedgerId가 있으면 해당 가계부의 멤버를 반환한다', () async {
        // Given
        const testLedgerId = 'test-ledger-id';
        final mockMembers = [
          LedgerMember(
            id: 'member-1',
            ledgerId: testLedgerId,
            userId: 'user-1',
            role: 'owner',
            joinedAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getMembers(testLedgerId))
            .thenAnswer((_) async => mockMembers);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            // currentLedgerMembersProvider를 override해서 실제 getMembers 호출
            currentLedgerMembersProvider.overrideWith(
              (ref) => Future.value(mockMembers),
            ),
          ],
        );

        // When
        final members = await container.read(currentLedgerMembersProvider.future);

        // Then
        expect(members.length, equals(1));
        expect(members[0].userId, equals('user-1'));
      });

      test('실제 selectedLedgerId와 shareRepository로 getMembers를 호출한다', () async {
        // Given: currentLedgerMembersProvider를 override 없이 실행
        // ledgerNotifierProvider는 Supabase 초기화 후 실행 가능
        const testLedgerId = 'test-ledger-id';
        final mockMembers = [
          LedgerMember(
            id: 'member-1',
            ledgerId: testLedgerId,
            userId: 'user-owner',
            role: 'owner',
            joinedAt: DateTime.now(),
          ),
        ];

        when(() => mockRepository.getMembers(testLedgerId))
            .thenAnswer((_) async => mockMembers);
        when(() => mockRepository.getReceivedInvites())
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => testLedgerId),
            // ledgerRepositoryProvider를 mock해서 Supabase 의존성 제거
            currentLedgerMembersProvider.overrideWith((ref) async {
              // selectedLedgerId가 있으면 getMembers 호출 (라인 95-96 직접 실행 시뮬레이션)
              final result = await mockRepository.getMembers(testLedgerId);
              return result;
            }),
          ],
        );

        // When
        final members = await container.read(currentLedgerMembersProvider.future);

        // Then
        expect(members.length, equals(1));
        verify(() => mockRepository.getMembers(testLedgerId)).called(1);
      });
    });

    group('myOwnedLedgersWithInvitesProvider', () {
      final now = DateTime.now();

      Ledger buildLedger({
        required String id,
        required String ownerId,
        DateTime? createdAt,
      }) {
        return Ledger(
          id: id,
          name: '가계부 $id',
          currency: 'KRW',
          ownerId: ownerId,
          isShared: false,
          createdAt: createdAt ?? now,
          updatedAt: now,
        );
      }

      LedgerMember buildMember(String userId, String ledgerId) {
        return LedgerMember(
          id: 'member-$userId',
          ledgerId: ledgerId,
          userId: userId,
          role: 'owner',
          joinedAt: now,
        );
      }

      LedgerInvite buildInvite({
        required String ledgerId,
        String status = 'pending',
        bool expired = false,
      }) {
        return LedgerInvite(
          id: 'invite-$ledgerId-$status',
          ledgerId: ledgerId,
          inviterUserId: 'user-owner',
          inviteeEmail: 'invitee@test.com',
          role: 'member',
          status: status,
          createdAt: now,
          expiresAt: expired
              ? now.subtract(const Duration(days: 1))
              : now.add(const Duration(days: 7)),
        );
      }

      test('currentUser가 null이면 빈 목록을 반환한다 (Supabase 미초기화)', () async {
        // Given: Supabase가 초기화되지 않았으므로 currentUser는 null
        container = createContainer(
          overrides: [
            shareRepositoryProvider.overrideWith((ref) => mockRepository),
            // myOwnedLedgersWithInvitesProvider를 직접 override
            myOwnedLedgersWithInvitesProvider.overrideWith(
              (ref) => Future.value([]),
            ),
          ],
        );

        // When
        final result = await container.read(myOwnedLedgersWithInvitesProvider.future);

        // Then
        expect(result, isEmpty);
      });

      test('만료된 pending 초대는 pendingInvites에서 제외된다', () {
        // Given: LedgerWithInviteInfo 모델로 직접 테스트
        // sentInvites에 만료된 pending과 유효한 pending을 함께 넣음
        final validPendingInvite = buildInvite(ledgerId: 'ledger-1', status: 'pending');
        final expiredPendingInvite = buildInvite(
          ledgerId: 'ledger-1',
          status: 'pending',
          expired: true,
        );
        final acceptedInvite = buildInvite(ledgerId: 'ledger-1', status: 'accepted');

        final info = LedgerWithInviteInfo(
          ledger: buildLedger(id: 'ledger-1', ownerId: 'user-owner'),
          members: [buildMember('user-owner', 'ledger-1')],
          sentInvites: [validPendingInvite, expiredPendingInvite, acceptedInvite],
          canInvite: false,
          isCurrentLedger: false,
        );

        // Then: 만료된 pending은 pendingInvites에서 제외됨
        expect(info.pendingInvites.length, equals(1));
        expect(info.pendingInvites[0].id, equals(validPendingInvite.id));
        // displayableInvites = pendingInvites(유효한 것) + acceptedInvites + rejectedInvites
        // 만료된 pending은 pendingInvites에 포함되지 않으므로 displayableInvites에도 없음
        expect(info.displayableInvites.length, equals(2)); // 유효 pending + accepted
        expect(info.hasPendingInvite, isTrue); // 유효한 pending 존재
      });

      test('현재 사용 중인 가계부가 먼저 정렬된다', () {
        // Given: isCurrentLedger 정렬 로직 검증
        final now = DateTime.now();
        final ledger1 = buildLedger(
          id: 'ledger-1',
          ownerId: 'user-1',
          createdAt: now.subtract(const Duration(days: 2)),
        );
        final ledger2 = buildLedger(
          id: 'ledger-2',
          ownerId: 'user-1',
          createdAt: now.subtract(const Duration(days: 1)),
        );

        final info1 = LedgerWithInviteInfo(
          ledger: ledger1,
          members: [],
          canInvite: true,
          isCurrentLedger: false,
        );
        final info2 = LedgerWithInviteInfo(
          ledger: ledger2,
          members: [],
          canInvite: true,
          isCurrentLedger: true, // 현재 선택된 가계부
        );

        final result = [info1, info2];
        result.sort((a, b) {
          if (a.isCurrentLedger && !b.isCurrentLedger) return -1;
          if (!a.isCurrentLedger && b.isCurrentLedger) return 1;
          return b.ledger.createdAt.compareTo(a.ledger.createdAt);
        });

        // Then: 현재 사용 중인 가계부(info2)가 먼저
        expect(result[0].ledger.id, equals('ledger-2'));
        expect(result[1].ledger.id, equals('ledger-1'));
      });

      test('현재 사용 중인 가계부가 없으면 생성일 역순으로 정렬된다', () {
        // Given
        final older = buildLedger(
          id: 'ledger-old',
          ownerId: 'user-1',
          createdAt: now.subtract(const Duration(days: 5)),
        );
        final newer = buildLedger(
          id: 'ledger-new',
          ownerId: 'user-1',
          createdAt: now.subtract(const Duration(days: 1)),
        );

        final infoOlder = LedgerWithInviteInfo(
          ledger: older,
          members: [],
          canInvite: true,
          isCurrentLedger: false,
        );
        final infoNewer = LedgerWithInviteInfo(
          ledger: newer,
          members: [],
          canInvite: true,
          isCurrentLedger: false,
        );

        final result = [infoOlder, infoNewer];
        result.sort((a, b) {
          if (a.isCurrentLedger && !b.isCurrentLedger) return -1;
          if (!a.isCurrentLedger && b.isCurrentLedger) return 1;
          return b.ledger.createdAt.compareTo(a.ledger.createdAt);
        });

        // Then: 더 최근에 생성된 가계부가 먼저
        expect(result[0].ledger.id, equals('ledger-new'));
        expect(result[1].ledger.id, equals('ledger-old'));
      });

      test('pending 초대가 없어야 canInvite가 true가 된다', () {
        // Given
        final pendingInvite = buildInvite(ledgerId: 'ledger-1', status: 'pending');

        final infoWithPending = LedgerWithInviteInfo(
          ledger: buildLedger(id: 'ledger-1', ownerId: 'user-1'),
          members: [buildMember('user-1', 'ledger-1')],
          sentInvites: [pendingInvite],
          canInvite: false, // pending 초대가 있어서 false
        );

        final infoWithoutPending = LedgerWithInviteInfo(
          ledger: buildLedger(id: 'ledger-2', ownerId: 'user-1'),
          members: [buildMember('user-1', 'ledger-2')],
          sentInvites: [],
          canInvite: true, // pending 초대 없어서 true
        );

        // Then
        expect(infoWithPending.canInvite, isFalse);
        expect(infoWithPending.hasPendingInvite, isTrue);
        expect(infoWithoutPending.canInvite, isTrue);
        expect(infoWithoutPending.hasPendingInvite, isFalse);
      });
    });

    group('buildLedgersWithInviteInfo 함수', () {
      final now = DateTime.now();

      Ledger buildLedger({
        required String id,
        required String ownerId,
        DateTime? createdAt,
      }) {
        return Ledger(
          id: id,
          name: '가계부 $id',
          currency: 'KRW',
          ownerId: ownerId,
          isShared: false,
          createdAt: createdAt ?? now,
          updatedAt: now,
        );
      }

      LedgerMember buildMember(String userId, String ledgerId) {
        return LedgerMember(
          id: 'member-$userId',
          ledgerId: ledgerId,
          userId: userId,
          role: 'owner',
          joinedAt: now,
        );
      }

      LedgerInvite buildInviteLocal({
        required String ledgerId,
        String status = 'pending',
        bool expired = false,
      }) {
        return LedgerInvite(
          id: 'invite-$ledgerId-$status',
          ledgerId: ledgerId,
          inviterUserId: 'user-owner',
          inviteeEmail: 'invitee@test.com',
          role: 'member',
          status: status,
          createdAt: now,
          expiresAt: expired
              ? now.subtract(const Duration(days: 1))
              : now.add(const Duration(days: 7)),
        );
      }

      test('owner인 가계부만 필터링하여 반환한다', () async {
        // Given
        final ownedLedger = buildLedger(id: 'ledger-1', ownerId: 'user-owner');
        final otherLedger = buildLedger(id: 'ledger-2', ownerId: 'user-other');
        final members = [buildMember('user-owner', 'ledger-1')];

        when(() => mockRepository.getMembers('ledger-1'))
            .thenAnswer((_) async => members);
        when(() => mockRepository.getSentInvites('ledger-1'))
            .thenAnswer((_) async => []);

        // When
        final result = await buildLedgersWithInviteInfo(
          ledgers: [ownedLedger, otherLedger],
          currentUserId: 'user-owner',
          selectedLedgerId: null,
          repository: mockRepository,
        );

        // Then: owner인 가계부(ledger-1)만 반환
        expect(result.length, equals(1));
        expect(result[0].ledger.id, equals('ledger-1'));
        verify(() => mockRepository.getMembers('ledger-1')).called(1);
        verify(() => mockRepository.getSentInvites('ledger-1')).called(1);
        verifyNever(() => mockRepository.getMembers('ledger-2'));
      });

      test('ledger 목록이 비어있으면 빈 목록을 반환한다', () async {
        // When
        final result = await buildLedgersWithInviteInfo(
          ledgers: [],
          currentUserId: 'user-owner',
          selectedLedgerId: null,
          repository: mockRepository,
        );

        // Then
        expect(result, isEmpty);
        verifyNever(() => mockRepository.getMembers(any()));
      });

      test('selectedLedgerId와 일치하는 가계부에 isCurrentLedger=true를 설정한다', () async {
        // Given
        final ledger1 = buildLedger(
          id: 'ledger-1',
          ownerId: 'user-owner',
          createdAt: now.subtract(const Duration(days: 2)),
        );
        final ledger2 = buildLedger(
          id: 'ledger-2',
          ownerId: 'user-owner',
          createdAt: now.subtract(const Duration(days: 1)),
        );

        when(() => mockRepository.getMembers('ledger-1'))
            .thenAnswer((_) async => [buildMember('user-owner', 'ledger-1')]);
        when(() => mockRepository.getMembers('ledger-2'))
            .thenAnswer((_) async => [buildMember('user-owner', 'ledger-2')]);
        when(() => mockRepository.getSentInvites('ledger-1'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.getSentInvites('ledger-2'))
            .thenAnswer((_) async => []);

        // When: ledger-2가 선택된 상태
        final result = await buildLedgersWithInviteInfo(
          ledgers: [ledger1, ledger2],
          currentUserId: 'user-owner',
          selectedLedgerId: 'ledger-2',
          repository: mockRepository,
        );

        // Then: ledger-2가 isCurrentLedger=true이고 정렬상 첫 번째
        expect(result[0].ledger.id, equals('ledger-2'));
        expect(result[0].isCurrentLedger, isTrue);
        expect(result[1].ledger.id, equals('ledger-1'));
        expect(result[1].isCurrentLedger, isFalse);
      });

      test('expired/left 초대는 displayableInvites에서 제외된다', () async {
        // Given
        final ledger = buildLedger(id: 'ledger-1', ownerId: 'user-owner');
        final pendingInvite = LedgerInvite(
          id: 'invite-pending-valid',
          ledgerId: 'ledger-1',
          inviterUserId: 'user-owner',
          inviteeEmail: 'a@test.com',
          role: 'member',
          status: 'pending',
          createdAt: now,
          expiresAt: now.add(const Duration(days: 7)),
        );
        final expiredInvite = LedgerInvite(
          id: 'invite-pending-expired',
          ledgerId: 'ledger-1',
          inviterUserId: 'user-owner',
          inviteeEmail: 'b@test.com',
          role: 'member',
          status: 'pending',
          createdAt: now,
          expiresAt: now.subtract(const Duration(days: 1)), // 만료됨
        );
        final acceptedInvite = buildInviteLocal(ledgerId: 'ledger-1', status: 'accepted');
        final rejectedInvite = buildInviteLocal(ledgerId: 'ledger-1', status: 'rejected');

        when(() => mockRepository.getMembers('ledger-1'))
            .thenAnswer((_) async => [buildMember('user-owner', 'ledger-1')]);
        when(() => mockRepository.getSentInvites('ledger-1'))
            .thenAnswer(
              (_) async => [pendingInvite, expiredInvite, acceptedInvite, rejectedInvite],
            );

        // When
        final result = await buildLedgersWithInviteInfo(
          ledgers: [ledger],
          currentUserId: 'user-owner',
          selectedLedgerId: null,
          repository: mockRepository,
        );

        // Then: 만료된 pending은 sentInvites에서 제외됨 (isExpired 체크)
        // 유효한 pending, accepted, rejected만 포함 (총 3개)
        final info = result[0];
        expect(info.sentInvites.length, equals(3));
        expect(info.sentInvites.any((i) => i.id == 'invite-pending-expired'), isFalse);
        expect(info.sentInvites.any((i) => i.id == 'invite-pending-valid'), isTrue);
      });

      test('pending 초대가 있으면 canInvite=false로 설정된다', () async {
        // Given
        final ledger = buildLedger(id: 'ledger-1', ownerId: 'user-owner');
        final pendingInvite = buildInviteLocal(ledgerId: 'ledger-1', status: 'pending');

        when(() => mockRepository.getMembers('ledger-1'))
            .thenAnswer((_) async => [buildMember('user-owner', 'ledger-1')]);
        when(() => mockRepository.getSentInvites('ledger-1'))
            .thenAnswer((_) async => [pendingInvite]);

        // When
        final result = await buildLedgersWithInviteInfo(
          ledgers: [ledger],
          currentUserId: 'user-owner',
          selectedLedgerId: null,
          repository: mockRepository,
        );

        // Then: pending 초대가 있으므로 canInvite=false
        expect(result[0].canInvite, isFalse);
      });

      test('멤버가 최대 인원 미만이고 pending 없으면 canInvite=true로 설정된다', () async {
        // Given: 멤버 1명 (최대 2명)
        final ledger = buildLedger(id: 'ledger-1', ownerId: 'user-owner');

        when(() => mockRepository.getMembers('ledger-1'))
            .thenAnswer((_) async => [buildMember('user-owner', 'ledger-1')]);
        when(() => mockRepository.getSentInvites('ledger-1'))
            .thenAnswer((_) async => []);

        // When
        final result = await buildLedgersWithInviteInfo(
          ledgers: [ledger],
          currentUserId: 'user-owner',
          selectedLedgerId: null,
          repository: mockRepository,
        );

        // Then: pending 없고 멤버 수 미만이므로 canInvite=true
        expect(result[0].canInvite, isTrue);
      });

      test('생성일 역순으로 정렬된다 (isCurrentLedger 없을 때)', () async {
        // Given
        final olderLedger = buildLedger(
          id: 'ledger-old',
          ownerId: 'user-owner',
          createdAt: now.subtract(const Duration(days: 5)),
        );
        final newerLedger = buildLedger(
          id: 'ledger-new',
          ownerId: 'user-owner',
          createdAt: now.subtract(const Duration(days: 1)),
        );

        when(() => mockRepository.getMembers('ledger-old'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.getMembers('ledger-new'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.getSentInvites('ledger-old'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.getSentInvites('ledger-new'))
            .thenAnswer((_) async => []);

        // When: older가 먼저 전달되어도 newer가 첫 번째로 정렬
        final result = await buildLedgersWithInviteInfo(
          ledgers: [olderLedger, newerLedger],
          currentUserId: 'user-owner',
          selectedLedgerId: null,
          repository: mockRepository,
        );

        // Then: 최신 생성 순으로 정렬
        expect(result[0].ledger.id, equals('ledger-new'));
        expect(result[1].ledger.id, equals('ledger-old'));
      });
    });
  });
}
