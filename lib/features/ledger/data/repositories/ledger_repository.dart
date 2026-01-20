import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/supabase_error_handler.dart';
import '../models/ledger_model.dart';

class LedgerRepository {
  final _client = SupabaseConfig.client;

  // 사용자의 모든 가계부 조회 (멤버로 등록된 가계부만)
  Future<List<LedgerModel>> getLedgers() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('로그인이 필요합니다');

    // ledger_members를 통해 실제 멤버로 등록된 가계부만 조회
    // pending 초대 상태는 제외됨
    final response = await _client
        .from('ledger_members')
        .select('ledger:ledgers(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .where((item) => item['ledger'] != null)
        .map((item) => LedgerModel.fromJson(item['ledger']))
        .toList();
  }

  // 가계부 상세 조회
  Future<LedgerModel?> getLedger(String id) async {
    final response = await _client
        .from('ledgers')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return LedgerModel.fromJson(response);
  }

  // 가계부 생성
  // 참고: 기본 카테고리는 DB 트리거(on_ledger_created_categories)에서 자동 생성됨
  Future<LedgerModel> createLedger({
    required String name,
    String? description,
    required String currency,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('로그인이 필요합니다');

      final data = LedgerModel.toCreateJson(
        name: name,
        description: description,
        currency: currency,
        ownerId: userId,
      );

      final response = await _client
          .from('ledgers')
          .insert(data)
          .select()
          .single();

      return LedgerModel.fromJson(response);
    } catch (e) {
      if (SupabaseErrorHandler.isDuplicateError(e)) {
        throw DuplicateItemException(itemType: '가계부', itemName: name);
      }
      rethrow;
    }
  }

  // 가계부 수정
  Future<LedgerModel> updateLedger({
    required String id,
    String? name,
    String? description,
    String? currency,
    bool? isShared,
  }) async {
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (currency != null) updates['currency'] = currency;
    if (isShared != null) updates['is_shared'] = isShared;

    final response = await _client
        .from('ledgers')
        .update(updates)
        .eq('id', id)
        .select()
        .single();

    return LedgerModel.fromJson(response);
  }

  // 가계부 삭제
  Future<void> deleteLedger(String id) async {
    await _client.from('ledgers').delete().eq('id', id);
  }

  // 가계부 멤버 조회
  Future<List<LedgerMemberModel>> getMembers(String ledgerId) async {
    final response = await _client
        .from('ledger_members')
        .select('*, profiles(display_name, email, avatar_url)')
        .eq('ledger_id', ledgerId)
        .order('created_at');

    return (response as List)
        .map((json) => LedgerMemberModel.fromJson(json))
        .toList();
  }

  // 멤버 추가
  Future<void> addMember({
    required String ledgerId,
    required String userId,
    required String role,
  }) async {
    await _client.from('ledger_members').insert({
      'ledger_id': ledgerId,
      'user_id': userId,
      'role': role,
    });
  }

  // 멤버 역할 변경
  Future<void> updateMemberRole({
    required String memberId,
    required String role,
  }) async {
    await _client
        .from('ledger_members')
        .update({'role': role})
        .eq('id', memberId);
  }

  // 멤버 제거
  Future<void> removeMember(String memberId) async {
    await _client.from('ledger_members').delete().eq('id', memberId);
  }

  // 실시간 구독 - ledgers 테이블
  RealtimeChannel subscribeLedgers(void Function(List<LedgerModel>) onData) {
    return _client
        .channel('ledgers_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'ledgers',
          callback: (payload) async {
            final ledgers = await getLedgers();
            onData(ledgers);
          },
        )
        .subscribe();
  }

  // 실시간 구독 - ledger_members 테이블 (멤버 변경 감지)
  RealtimeChannel subscribeLedgerMembers(void Function() onMemberChanged) {
    return _client
        .channel('ledger_members_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'house',
          table: 'ledger_members',
          callback: (payload) {
            onMemberChanged();
          },
        )
        .subscribe();
  }
}
