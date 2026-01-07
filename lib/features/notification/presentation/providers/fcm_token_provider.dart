import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/fcm_token_model.dart';
import '../../data/repositories/fcm_token_repository.dart';

part 'fcm_token_provider.g.dart';

/// FCM 토큰 Repository Provider
@riverpod
FcmTokenRepository fcmTokenRepository(Ref ref) {
  return FcmTokenRepository();
}

/// FCM 토큰 목록 Provider
///
/// 현재 로그인한 사용자의 FCM 토큰 목록을 관리합니다.
@riverpod
class FcmToken extends _$FcmToken {
  @override
  Future<List<FcmTokenModel>> build() async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      return [];
    }

    final repository = ref.watch(fcmTokenRepositoryProvider);
    try {
      return await repository.getFcmTokens(user.id);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// FCM 토큰 저장
  ///
  /// [token] FCM 토큰
  /// [deviceType] 디바이스 타입 (android/ios/web)
  Future<void> saveFcmToken({
    required String token,
    required String deviceType,
  }) async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    final repository = ref.read(fcmTokenRepositoryProvider);
    try {
      await repository.saveFcmToken(
        userId: user.id,
        token: token,
        deviceType: deviceType,
      );

      // 상태 갱신
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => repository.getFcmTokens(user.id));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// FCM 토큰 삭제
  ///
  /// [token] 삭제할 FCM 토큰
  Future<void> deleteFcmToken(String token) async {
    // 현재 로그인한 사용자 정보 가져오기
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    final repository = ref.read(fcmTokenRepositoryProvider);
    try {
      await repository.deleteFcmToken(token);

      // 상태 갱신
      state = const AsyncValue.loading();
      state = await AsyncValue.guard(() => repository.getFcmTokens(user.id));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
