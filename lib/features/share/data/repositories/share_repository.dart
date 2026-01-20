import '../../../../config/supabase_config.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../domain/entities/ledger_invite.dart';

class ShareRepository {
  final _client = SupabaseConfig.client;

  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final response = await _client.rpc(
      'check_user_exists_by_email',
      params: {'target_email': email},
    );
    if (response == null || (response as List).isEmpty) {
      return null;
    }
    return response[0] as Map<String, dynamic>;
  }

  // 이미 멤버인지 확인
  Future<bool> isAlreadyMember({
    required String ledgerId,
    required String email,
  }) async {
    // 먼저 해당 이메일의 사용자 조회
    final user = await findUserByEmail(email);
    if (user == null) return false;

    final userId = user['id'] as String;

    // ledger_members 테이블에서 소유자(role='owner') 또는 일반 멤버 확인
    // RLS 정책을 우회하지 않고 ledger_members 테이블만 사용
    final member = await _client
        .from('ledger_members')
        .select('id, role')
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId)
        .maybeSingle();

    return member != null;
  }

  // 이미 대기 중인 초대가 있는지 확인
  Future<bool> hasPendingInvite({
    required String ledgerId,
    required String email,
  }) async {
    final invite = await _client
        .from('ledger_invites')
        .select('id')
        .eq('ledger_id', ledgerId)
        .eq('invitee_email', email.toLowerCase().trim())
        .eq('status', 'pending')
        .gt('expires_at', DateTime.now().toIso8601String())
        .maybeSingle();

    return invite != null;
  }

  // 현재 멤버 수 확인
  Future<int> getMemberCount(String ledgerId) async {
    final response = await _client
        .from('ledger_members')
        .select('id')
        .eq('ledger_id', ledgerId);
    return (response as List).length;
  }

  // 멤버 수 제한 확인
  Future<bool> isMemberLimitReached(String ledgerId) async {
    final memberCount = await getMemberCount(ledgerId);
    return memberCount >= AppConstants.maxMembersPerLedger;
  }

  // 초대 생성 (모든 멤버는 동일한 admin 권한)
  Future<LedgerInvite> createInvite({
    required String ledgerId,
    required String inviteeEmail,
  }) async {
    const role = 'admin'; // 모든 멤버는 동일한 권한
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final normalizedEmail = inviteeEmail.toLowerCase().trim();

    // 1. 자기 자신에게 초대 방지
    final currentUserEmail = _client.auth.currentUser?.email;
    if (currentUserEmail?.toLowerCase() == normalizedEmail) {
      throw Exception('자기 자신에게는 초대를 보낼 수 없습니다');
    }

    // 2. 가입된 사용자인지 확인
    final targetUser = await findUserByEmail(normalizedEmail);
    if (targetUser == null) {
      throw Exception('가입되지 않은 이메일입니다. 가입된 사용자만 초대할 수 있습니다.');
    }

    // 3. 이미 멤버인지 확인
    if (await isAlreadyMember(ledgerId: ledgerId, email: normalizedEmail)) {
      throw Exception('이미 가계부의 멤버입니다');
    }

    // 4. 이미 대기 중인 초대가 있는지 확인
    if (await hasPendingInvite(ledgerId: ledgerId, email: normalizedEmail)) {
      throw Exception('이미 초대를 보냈습니다. 상대방의 수락을 기다려주세요.');
    }

    // 5. 멤버 수 제한 확인
    if (await isMemberLimitReached(ledgerId)) {
      throw Exception(
        '가계부 멤버는 최대 ${AppConstants.maxMembersPerLedger}명까지만 가능합니다.',
      );
    }

    // 만료일: 7일 후
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    final response = await _client
        .from('ledger_invites')
        .insert({
          'ledger_id': ledgerId,
          'inviter_user_id': userId,
          'invitee_email': normalizedEmail,
          'role': role,
          'expires_at': expiresAt.toIso8601String(),
        })
        .select(
          '*, ledger:ledgers!ledger_invites_ledger_id_fkey(name), inviter:profiles!ledger_invites_inviter_user_id_fkey(email)',
        )
        .single();

    final invite = LedgerInvite.fromJson(response);

    _sendInviteNotification(
      type: 'invite_received',
      targetUserId: targetUser['id'] as String,
      actorName: _client.auth.currentUser?.email ?? 'Unknown',
      ledgerName: invite.ledgerName ?? 'Ledger',
    );

    return invite;
  }

  Future<void> _sendInviteNotification({
    required String type,
    required String targetUserId,
    required String actorName,
    required String ledgerName,
  }) async {
    try {
      await _client.functions.invoke(
        'send-invite-notification',
        body: {
          'type': type,
          'target_user_id': targetUserId,
          'actor_name': actorName,
          'ledger_name': ledgerName,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Failed to send invite notification: $e');
      }
    }
  }

  Future<List<LedgerInvite>> getReceivedInvites() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final userEmail = user.email?.toLowerCase().trim() ?? '';
    if (userEmail.isEmpty) return [];

    final response = await _client
        .from('ledger_invites')
        .select(
          '*, ledger:ledgers!ledger_invites_ledger_id_fkey(name), inviter:profiles!ledger_invites_inviter_user_id_fkey(email)',
        )
        .eq('invitee_email', userEmail)
        .inFilter('status', ['pending', 'accepted'])
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LedgerInvite.fromJson(json))
        .toList();
  }

  // 보낸 초대 목록 조회
  Future<List<LedgerInvite>> getSentInvites(String ledgerId) async {
    final response = await _client
        .from('ledger_invites')
        .select(
          '*, ledger:ledgers!ledger_invites_ledger_id_fkey(name), inviter:profiles!ledger_invites_inviter_user_id_fkey(email)',
        )
        .eq('ledger_id', ledgerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LedgerInvite.fromJson(json))
        .toList();
  }

  Future<void> acceptInvite(String inviteId) async {
    final invite = await _client
        .from('ledger_invites')
        .select('*, ledger:ledgers!ledger_invites_ledger_id_fkey(name)')
        .eq('id', inviteId)
        .single();

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final ledgerId = invite['ledger_id'] as String;
    if (await isMemberLimitReached(ledgerId)) {
      throw Exception('이 가계부는 이미 멤버가 가득 찼습니다.');
    }

    await _client.from('ledger_members').insert({
      'ledger_id': invite['ledger_id'],
      'user_id': userId,
      'role': invite['role'],
    });

    await _client
        .from('ledger_invites')
        .update({'status': 'accepted'})
        .eq('id', inviteId);

    await _client
        .from('ledgers')
        .update({'is_shared': true})
        .eq('id', invite['ledger_id']);

    final inviterUserId = invite['inviter_user_id'] as String;
    final ledgerData = invite['ledger'] as Map<String, dynamic>?;
    final ledgerName = ledgerData?['name'] as String? ?? 'Ledger';

    _sendInviteNotification(
      type: 'invite_accepted',
      targetUserId: inviterUserId,
      actorName: _client.auth.currentUser?.email ?? 'Unknown',
      ledgerName: ledgerName,
    );
  }

  Future<void> rejectInvite(String inviteId) async {
    final invite = await _client
        .from('ledger_invites')
        .select('*, ledger:ledgers!ledger_invites_ledger_id_fkey(name)')
        .eq('id', inviteId)
        .single();

    await _client
        .from('ledger_invites')
        .update({'status': 'rejected'})
        .eq('id', inviteId);

    final inviterUserId = invite['inviter_user_id'] as String;
    final ledgerData = invite['ledger'] as Map<String, dynamic>?;
    final ledgerName = ledgerData?['name'] as String? ?? 'Ledger';

    _sendInviteNotification(
      type: 'invite_rejected',
      targetUserId: inviterUserId,
      actorName: _client.auth.currentUser?.email ?? 'Unknown',
      ledgerName: ledgerName,
    );
  }

  // 초대 취소
  Future<void> cancelInvite(String inviteId) async {
    await _client.from('ledger_invites').delete().eq('id', inviteId);
  }

  // 멤버 목록 조회
  Future<List<LedgerMember>> getMembers(String ledgerId) async {
    final response = await _client
        .from('ledger_members')
        .select('*, profiles(email, display_name, avatar_url, color)')
        .eq('ledger_id', ledgerId)
        .order('created_at');

    return (response as List)
        .map((json) => LedgerMember.fromJson(json))
        .toList();
  }

  // 멤버 역할 변경
  Future<void> updateMemberRole({
    required String ledgerId,
    required String userId,
    required String role,
  }) async {
    await _client
        .from('ledger_members')
        .update({'role': role})
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId);
  }

  // 멤버 제거
  Future<void> removeMember({
    required String ledgerId,
    required String userId,
  }) async {
    await _client
        .from('ledger_members')
        .delete()
        .eq('ledger_id', ledgerId)
        .eq('user_id', userId);

    // 남은 멤버 수 확인 (count만 필요하므로 id만 조회)
    final remainingMembers = await _client
        .from('ledger_members')
        .select('id')
        .eq('ledger_id', ledgerId);

    if ((remainingMembers as List).length <= 1) {
      await _client
          .from('ledgers')
          .update({'is_shared': false})
          .eq('id', ledgerId);
    }
  }

  // 가계부 나가기
  Future<void> leaveLedger(String ledgerId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    final userEmail = _client.auth.currentUser?.email?.toLowerCase().trim();

    // 멤버에서 제거
    await removeMember(ledgerId: ledgerId, userId: userId);

    // 초대 상태를 'left'로 변경 (기록 유지, 다시 초대 가능)
    if (userEmail != null) {
      await _client
          .from('ledger_invites')
          .update({'status': 'left'})
          .eq('ledger_id', ledgerId)
          .eq('invitee_email', userEmail)
          .eq('status', 'accepted');
    }
  }
}
