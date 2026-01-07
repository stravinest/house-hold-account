import '../../../../config/supabase_config.dart';
import '../models/fcm_token_model.dart';

/// FCM 토큰 Repository
/// Supabase fcm_tokens 테이블과 상호작용하여 FCM 토큰을 관리합니다.
class FcmTokenRepository {
  final _client = SupabaseConfig.client;

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

  /// FCM 토큰 저장 (UPSERT)
  ///
  /// 동일한 user_id와 token 조합이 이미 존재하면 업데이트, 없으면 삽입합니다.
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
      final data = FcmTokenModel.toCreateJson(
        userId: userId,
        token: token,
        deviceType: deviceType,
      );

      // UPSERT: user_id와 token이 같으면 updated_at만 갱신
      await _client.from('fcm_tokens').upsert(
        {
          ...data,
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,token',
      );
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
