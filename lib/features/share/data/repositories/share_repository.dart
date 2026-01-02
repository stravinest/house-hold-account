import '../../../../config/supabase_config.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../domain/entities/ledger_invite.dart';

class ShareRepository {
  final _client = SupabaseConfig.client;

  // 초대 생성
  Future<LedgerInvite> createInvite({
    required String ledgerId,
    required String inviteeEmail,
    String role = 'member',
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    // 만료일: 7일 후
    final expiresAt = DateTime.now().add(const Duration(days: 7));

    final response = await _client
        .from('ledger_invites')
        .insert({
          'ledger_id': ledgerId,
          'inviter_user_id': userId,
          'invitee_email': inviteeEmail,
          'role': role,
          'expires_at': expiresAt.toIso8601String(),
        })
        .select('*, ledgers(name), profiles(email)')
        .single();

    return LedgerInvite.fromJson(response);
  }

  // 받은 초대 목록 조회
  Future<List<LedgerInvite>> getReceivedInvites() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final response = await _client
        .from('ledger_invites')
        .select('*, ledgers(name), profiles(email)')
        .eq('invitee_email', user.email ?? '')
        .eq('status', 'pending')
        .gt('expires_at', DateTime.now().toIso8601String())
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LedgerInvite.fromJson(json))
        .toList();
  }

  // 보낸 초대 목록 조회
  Future<List<LedgerInvite>> getSentInvites(String ledgerId) async {
    final response = await _client
        .from('ledger_invites')
        .select('*, ledgers(name), profiles(email)')
        .eq('ledger_id', ledgerId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LedgerInvite.fromJson(json))
        .toList();
  }

  // 초대 수락
  Future<void> acceptInvite(String inviteId) async {
    final invite = await _client
        .from('ledger_invites')
        .select()
        .eq('id', inviteId)
        .single();

    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    // 초대 상태 업데이트
    await _client
        .from('ledger_invites')
        .update({'status': 'accepted'})
        .eq('id', inviteId);

    // 멤버로 추가
    await _client.from('ledger_members').insert({
      'ledger_id': invite['ledger_id'],
      'user_id': userId,
      'role': invite['role'],
    });

    // 가계부를 공유 상태로 변경
    await _client
        .from('ledgers')
        .update({'is_shared': true})
        .eq('id', invite['ledger_id']);
  }

  // 초대 거절
  Future<void> rejectInvite(String inviteId) async {
    await _client
        .from('ledger_invites')
        .update({'status': 'rejected'})
        .eq('id', inviteId);
  }

  // 초대 취소
  Future<void> cancelInvite(String inviteId) async {
    await _client.from('ledger_invites').delete().eq('id', inviteId);
  }

  // 멤버 목록 조회
  Future<List<LedgerMember>> getMembers(String ledgerId) async {
    final response = await _client
        .from('ledger_members')
        .select('*, profiles(email, display_name, avatar_url)')
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

    // 남은 멤버 수 확인
    final remainingMembers = await _client
        .from('ledger_members')
        .select()
        .eq('ledger_id', ledgerId);

    // 멤버가 1명(소유자)만 남으면 공유 상태 해제
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

    await removeMember(ledgerId: ledgerId, userId: userId);
  }
}
