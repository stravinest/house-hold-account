import '../../../../config/supabase_config.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../domain/entities/ledger_invite.dart';

class ShareRepository {
  final _client = SupabaseConfig.client;

  // 이메일로 사용자 조회 (가입 여부 확인)
  Future<Map<String, dynamic>?> findUserByEmail(String email) async {
    final response = await _client
        .from('profiles')
        .select('id, email, display_name')
        .eq('email', email.toLowerCase().trim())
        .maybeSingle();
    return response;
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

  // 초대 생성
  Future<LedgerInvite> createInvite({
    required String ledgerId,
    required String inviteeEmail,
    String role = 'member',
  }) async {
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
        .select('*, ledger:ledgers!ledger_invites_ledger_id_fkey(name), inviter:profiles!ledger_invites_inviter_user_id_fkey(email)')
        .single();

    return LedgerInvite.fromJson(response);
  }

  // 받은 초대 목록 조회 (pending, accepted, rejected 모두 포함)
  Future<List<LedgerInvite>> getReceivedInvites() async {
    final user = _client.auth.currentUser;
    if (user == null) return [];

    final userEmail = user.email?.toLowerCase().trim() ?? '';
    if (userEmail.isEmpty) return [];

    // RLS 정책으로 초대받은 사용자도 ledgers 테이블 조회 가능
    // 조인 쿼리로 가계부 이름과 초대자 정보를 한 번에 조회
    // pending, accepted, rejected 모두 표시 (만료되지 않은 것만)
    final response = await _client
        .from('ledger_invites')
        .select('*, ledger:ledgers!ledger_invites_ledger_id_fkey(name), inviter:profiles!ledger_invites_inviter_user_id_fkey(email)')
        .eq('invitee_email', userEmail)
        .inFilter('status', ['pending', 'accepted', 'rejected'])
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => LedgerInvite.fromJson(json))
        .toList();
  }

  // 보낸 초대 목록 조회
  Future<List<LedgerInvite>> getSentInvites(String ledgerId) async {
    final response = await _client
        .from('ledger_invites')
        .select('*, ledger:ledgers!ledger_invites_ledger_id_fkey(name), inviter:profiles!ledger_invites_inviter_user_id_fkey(email)')
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

    // 중요: 멤버로 먼저 추가 (RLS 정책이 pending 상태 초대를 확인하므로)
    await _client.from('ledger_members').insert({
      'ledger_id': invite['ledger_id'],
      'user_id': userId,
      'role': invite['role'],
    });

    // 초대 상태 업데이트
    await _client
        .from('ledger_invites')
        .update({'status': 'accepted'})
        .eq('id', inviteId);

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
