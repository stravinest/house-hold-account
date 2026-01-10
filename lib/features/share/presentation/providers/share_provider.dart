import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/share_repository.dart';
import '../../domain/entities/ledger_invite.dart';

// Repository 프로바이더
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepository();
});

// 받은 초대 목록
final receivedInvitesProvider = FutureProvider<List<LedgerInvite>>((ref) async {
  final repository = ref.watch(shareRepositoryProvider);
  return repository.getReceivedInvites();
});

// 받은 초대 개수 (pending 상태만)
final pendingInviteCountProvider = Provider<int>((ref) {
  final invitesAsync = ref.watch(receivedInvitesProvider);
  return invitesAsync.valueOrNull?.where((invite) => invite.isPending).length ?? 0;
});

// 보낸 초대 목록
final sentInvitesProvider =
    FutureProvider.family<List<LedgerInvite>, String>((ref, ledgerId) async {
  final repository = ref.watch(shareRepositoryProvider);
  return repository.getSentInvites(ledgerId);
});

// 현재 가계부의 멤버 목록
final ledgerMembersListProvider =
    FutureProvider.family<List<LedgerMember>, String>((ref, ledgerId) async {
  final repository = ref.watch(shareRepositoryProvider);
  return repository.getMembers(ledgerId);
});

// 현재 선택된 가계부의 멤버 목록
final currentLedgerMembersProvider = FutureProvider<List<LedgerMember>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(shareRepositoryProvider);
  return repository.getMembers(ledgerId);
});

// 현재 가계부의 멤버 수
final currentLedgerMemberCountProvider = Provider<int>((ref) {
  final membersAsync = ref.watch(currentLedgerMembersProvider);
  return membersAsync.valueOrNull?.length ?? 0;
});

// 멤버 추가 가능 여부
final canAddMemberProvider = Provider<bool>((ref) {
  final memberCount = ref.watch(currentLedgerMemberCountProvider);
  return memberCount < AppConstants.maxMembersPerLedger;
});

// 공유 관리 노티파이어
class ShareNotifier extends StateNotifier<AsyncValue<void>> {
  final ShareRepository _repository;
  final Ref _ref;

  ShareNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));

  // 초대 보내기
  Future<void> sendInvite({
    required String ledgerId,
    required String email,
    String role = 'member',
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createInvite(
        ledgerId: ledgerId,
        inviteeEmail: email,
        role: role,
      );
      _ref.invalidate(sentInvitesProvider(ledgerId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 초대 수락
  Future<void> acceptInvite(String inviteId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.acceptInvite(inviteId);
      _ref.invalidate(receivedInvitesProvider);
      _ref.invalidate(ledgersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 초대 거절
  Future<void> rejectInvite(String inviteId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.rejectInvite(inviteId);
      _ref.invalidate(receivedInvitesProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 초대 취소
  Future<void> cancelInvite({
    required String inviteId,
    required String ledgerId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.cancelInvite(inviteId);
      _ref.invalidate(sentInvitesProvider(ledgerId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 멤버 역할 변경
  Future<void> updateMemberRole({
    required String ledgerId,
    required String userId,
    required String role,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updateMemberRole(
        ledgerId: ledgerId,
        userId: userId,
        role: role,
      );
      _ref.invalidate(ledgerMembersListProvider(ledgerId));
      _ref.invalidate(currentLedgerMembersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 멤버 제거
  Future<void> removeMember({
    required String ledgerId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.removeMember(
        ledgerId: ledgerId,
        userId: userId,
      );
      _ref.invalidate(ledgerMembersListProvider(ledgerId));
      _ref.invalidate(currentLedgerMembersProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // 가계부 나가기
  Future<void> leaveLedger(String ledgerId) async {
    state = const AsyncValue.loading();
    try {
      await _repository.leaveLedger(ledgerId);
      _ref.invalidate(ledgersProvider);
      _ref.read(selectedLedgerIdProvider.notifier).state = null;
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final shareNotifierProvider =
    StateNotifierProvider<ShareNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(shareRepositoryProvider);
  return ShareNotifier(repository, ref);
});
