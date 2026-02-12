import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../models/fcm_token_model.dart';

/// FCM 토큰 Repository
/// Supabase fcm_tokens 테이블과 상호작용하여 FCM 토큰을 관리합니다.
class FcmTokenRepository {
  final SupabaseClient _client;

  FcmTokenRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.client;

  /// 사용자의 모든 FCM 토큰 조회
  ///
  /// [userId] 사용자 ID
  /// Returns: 사용자의 모든 FCM 토큰 목록
  Future<List<FcmTokenModel>> getFcmTokens(String userId) async {
    try {
      final response = await _client
          .from('fcm_tokens')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => FcmTokenModel.fromJson(json))
          .toList();
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }

  /// FCM 토큰 저장
  ///
  /// FCM 토큰은 기기에 고유하므로, 같은 토큰이 다른 사용자에게 등록되어 있으면
  /// 먼저 삭제한 후 현재 사용자에게 등록합니다.
  ///
  /// [userId] 사용자 ID
  /// [token] FCM 토큰
  /// [deviceType] 디바이스 타입 (android/ios/web)
  Future<void> saveFcmToken({
    required String userId,
    required String token,
    required String deviceType,
  }) async {
    try {
      // 1. 이 토큰이 다른 사용자에게 등록되어 있으면 삭제
      // FCM 토큰은 기기에 고유하므로, 한 토큰은 한 사용자에게만 연결되어야 함
      await _client
          .from('fcm_tokens')
          .delete()
          .eq('token', token)
          .neq('user_id', userId);

      final data = FcmTokenModel.toCreateJson(
        userId: userId,
        token: token,
        deviceType: deviceType,
      );

      // 2. 현재 사용자에게 토큰 저장 (UPSERT)
      await _client.from('fcm_tokens').upsert({
        ...data,
        'updated_at': DateTimeUtils.nowUtcIso(),
      }, onConflict: 'user_id,token');
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }

  /// FCM 토큰 삭제
  ///
  /// [token] 삭제할 FCM 토큰
  Future<void> deleteFcmToken(String token) async {
    try {
      await _client.from('fcm_tokens').delete().eq('token', token);
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }

  /// 사용자의 모든 FCM 토큰 삭제
  ///
  /// 로그아웃 시 사용자의 모든 디바이스에서 푸시 알림을 받지 않도록 합니다.
  ///
  /// [userId] 사용자 ID
  Future<void> deleteAllUserTokens(String userId) async {
    try {
      await _client.from('fcm_tokens').delete().eq('user_id', userId);
    } catch (e) {
      // 에러를 호출자에게 전파
      rethrow;
    }
  }
}
