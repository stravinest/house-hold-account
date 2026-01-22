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
  final List<LedgerInvite> sentInvites;
  final bool canInvite;
  final bool isCurrentLedger;

  const LedgerWithInviteInfo({
    required this.ledger,
    required this.members,
    this.sentInvites = const [],
    required this.canInvite,
    this.isCurrentLedger = false,
  });

  // 초대 상태 확인 헬퍼
  bool get hasNoInvite => sentInvites.isEmpty;
  bool get hasPendingInvite => pendingInvites.isNotEmpty;
  bool get hasAcceptedInvite => acceptedInvites.isNotEmpty;
  bool get hasRejectedInvite => rejectedInvites.isNotEmpty;
  bool get isMemberFull => members.length >= AppConstants.maxMembersPerLedger;

  // 상태별 초대 목록
  List<LedgerInvite> get pendingInvites =>
      sentInvites.where((i) => i.isPending && !i.isExpired).toList();
  List<LedgerInvite> get acceptedInvites =>
      sentInvites.where((i) => i.isAccepted).toList();
  List<LedgerInvite> get rejectedInvites =>
      sentInvites.where((i) => i.isRejected).toList();

  // 표시할 초대 목록 (pending, accepted, rejected 순서)
  List<LedgerInvite> get displayableInvites {
    return [...pendingInvites, ...acceptedInvites, ...rejectedInvites];
  }
}

// Repository 프로바이더
final shareRepositoryProvider = Provider<ShareRepository>((ref) {
  return ShareRepository();
});

// 받은 초대 목록
final receivedInvitesProvider = FutureProvider.autoDispose<List<LedgerInvite>>((
  ref,
) async {
  final repository = ref.watch(shareRepositoryProvider);
  return repository.getReceivedInvites();
});

// 받은 초대 개수 (pending 상태만)
final pendingInviteCountProvider = Provider<int>((ref) {
  final invitesAsync = ref.watch(receivedInvitesProvider);
  return invitesAsync.valueOrNull?.where((invite) => invite.isPending).length ??
      0;
});

// 보낸 초대 목록
final sentInvitesProvider = FutureProvider.family<List<LedgerInvite>, String>((
  ref,
  ledgerId,
) async {
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
final currentLedgerMembersProvider = FutureProvider<List<LedgerMember>>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  // 가계부 정보나 멤버 변경 시(Realtime) 함께 갱신되도록 ledgerNotifierProvider 감시
  ref.watch(ledgerNotifierProvider);

  final repository = ref.watch(shareRepositoryProvider);
  return repository.getMembers(ledgerId);
});

// 현재 가계부의 멤버 수
// 로딩 중일 때 최소 1명(본인) 보장하여 UI 깜빡임 방지
final currentLedgerMemberCountProvider = Provider<int>((ref) {
  final membersAsync = ref.watch(currentLedgerMembersProvider);
  final currentLedger = ref.watch(currentLedgerProvider).valueOrNull;

  final memberCount = membersAsync.valueOrNull?.length ?? 1;

  // 가계부 자체가 공유 상태인 경우, 멤버 정보 로딩 중이라도 최소 2명으로 간주하여 공유 UI 유지
  if (currentLedger?.isShared == true && memberCount < 2) {
    return 2;
  }

  return memberCount;
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

  ShareNotifier(this._repository, this._ref)
    : super(const AsyncValue.data(null));

  // 초대 보내기
  Future<void> sendInvite({
    required String ledgerId,
    required String email,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repository.createInvite(ledgerId: ledgerId, inviteeEmail: email);
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
      _ref.invalidate(currentLedgerMembersProvider);
      _ref.invalidate(currentLedgerProvider);
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
      await _repository.removeMember(ledgerId: ledgerId, userId: userId);
      _ref.invalidate(ledgerMembersListProvider(ledgerId));
      _ref.invalidate(currentLedgerMembersProvider);
      _ref.invalidate(currentLedgerProvider);
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
      // 탈퇴 전 현재 선택된 가계부 확인
      final currentSelectedId = _ref.read(selectedLedgerIdProvider);

      await _repository.leaveLedger(ledgerId);
      _ref.invalidate(ledgersProvider);
      _ref.invalidate(receivedInvitesProvider);
      _ref.invalidate(currentLedgerMembersProvider);
      _ref.invalidate(currentLedgerProvider);

      // 탈퇴한 가계부가 현재 선택된 가계부일 때만 선택 해제
      if (currentSelectedId == ledgerId) {
        _ref.read(selectedLedgerIdProvider.notifier).state = null;
      }
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
    FutureProvider.autoDispose<List<LedgerWithInviteInfo>>((ref) async {
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

      // 모든 가계부의 멤버/초대 정보를 병렬로 조회 (N+1 쿼리 방지)
      final futures = ownedLedgers.map((ledger) async {
        final results = await Future.wait([
          repository.getMembers(ledger.id),
          repository.getSentInvites(ledger.id),
        ]);
        return (
          ledger,
          results[0] as List<LedgerMember>,
          results[1] as List<LedgerInvite>,
        );
      });

      final allData = await Future.wait(futures);

      final result = <LedgerWithInviteInfo>[];
      for (final (ledger, members, sentInvites) in allData) {
        // 표시할 초대 필터링 (pending, accepted, rejected - expired/left 제외)
        final displayableInvites = sentInvites.where((i) {
          if (i.isExpired || i.isLeft) return false;
          return i.isPending || i.isAccepted || i.isRejected;
        }).toList();

        // pending 초대가 없어야 새 초대 가능
        final hasPendingInvite = displayableInvites.any(
          (i) => i.isPending && !i.isExpired,
        );
        final canInvite =
            members.length < AppConstants.maxMembersPerLedger &&
            !hasPendingInvite;

        result.add(
          LedgerWithInviteInfo(
            ledger: ledger,
            members: members,
            sentInvites: displayableInvites,
            canInvite: canInvite,
            isCurrentLedger: ledger.id == selectedLedgerId,
          ),
        );
      }

      // 정렬: 현재 사용 중인 가계부 먼저, 그 다음 생성일 역순
      result.sort((a, b) {
        if (a.isCurrentLedger && !b.isCurrentLedger) return -1;
        if (!a.isCurrentLedger && b.isCurrentLedger) return 1;
        return b.ledger.createdAt.compareTo(a.ledger.createdAt);
      });

      return result;
    });
