import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/config/supabase_config.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/share/data/repositories/share_repository.dart';
import 'package:shared_household_account/features/share/domain/entities/ledger_invite.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
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
    });
  });
}
