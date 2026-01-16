import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/share_repository.dart';
import '../../domain/entities/ledger_invite.dart';

// 가계부 + 초대 정보를 함께 담는 모델
class LedgerWithInviteInfo {
  final Ledger ledger;
  final List<LedgerMember> members;
  final LedgerInvite? sentInvite;
  final bool canInvite;
  final bool isCurrentLedger;

  const LedgerWithInviteInfo({
    required this.ledger,
    required this.members,
    this.sentInvite,
    required this.canInvite,
    this.isCurrentLedger = false,
  });

  // 초대 상태 확인 헬퍼
  bool get hasNoInvite => sentInvite == null;
  bool get hasPendingInvite => sentInvite?.isPending ?? false;
  bool get hasAcceptedInvite => sentInvite?.isAccepted ?? false;
  bool get hasRejectedInvite => sentInvite?.isRejected ?? false;
  bool get isMemberFull => members.length >= AppConstants.maxMembersPerLedger;
}

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

// 내가 owner인 가계부 목록 (+ 각 가계부의 초대/멤버 정보 포함)
final myOwnedLedgersWithInvitesProvider =
    FutureProvider<List<LedgerWithInviteInfo>>((ref) async {
  final currentUserId = SupabaseConfig.auth.currentUser?.id;
  if (currentUserId == null) return [];

  final ledgersAsync = ref.watch(ledgersProvider);
  final selectedLedgerId = ref.watch(selectedLedgerIdProvider);
  final repository = ref.watch(shareRepositoryProvider);

  // ledgersProvider가 아직 데이터를 가지고 있지 않으면 빈 리스트 반환
  // isLoading/hasError는 FutureProvider가 자동으로 처리
  final ledgers = ledgersAsync.valueOrNull;
  if (ledgers == null) return [];

  // owner인 가계부만 필터링 (ownerId 사용)
  final ownedLedgers = ledgers.where((ledger) {
    return ledger.ownerId == currentUserId;
  }).toList();

  // 각 가계부에 대해 초대/멤버 정보 조회
  final result = <LedgerWithInviteInfo>[];

  for (final ledger in ownedLedgers) {
    final members = await repository.getMembers(ledger.id);
    final sentInvites = await repository.getSentInvites(ledger.id);

    // 가장 최근 초대 (pending 우선, 그 다음 최신순)
    LedgerInvite? latestInvite;
    if (sentInvites.isNotEmpty) {
      // pending 상태가 있으면 우선
      final pendingInvites =
          sentInvites.where((i) => i.isPending && !i.isExpired).toList();
      if (pendingInvites.isNotEmpty) {
        latestInvite = pendingInvites.first;
      } else {
        // 그 외 최신 초대
        latestInvite = sentInvites.first;
      }
    }

    final canInvite = members.length < AppConstants.maxMembersPerLedger &&
        (latestInvite == null ||
            latestInvite.isRejected ||
            latestInvite.isExpired);

    result.add(LedgerWithInviteInfo(
      ledger: ledger,
      members: members,
      sentInvite: latestInvite,
      canInvite: canInvite,
      isCurrentLedger: ledger.id == selectedLedgerId,
    ));
  }

  // 정렬: 현재 사용 중인 가계부 먼저, 그 다음 생성일 역순
  result.sort((a, b) {
    if (a.isCurrentLedger && !b.isCurrentLedger) return -1;
    if (!a.isCurrentLedger && b.isCurrentLedger) return 1;
    return b.ledger.createdAt.compareTo(a.ledger.createdAt);
  });

  return result;
});
