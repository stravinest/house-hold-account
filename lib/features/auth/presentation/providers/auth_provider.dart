import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';

// 현재 인증 상태를 관찰하는 프로바이더
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.auth.onAuthStateChange.map((event) => event.session?.user);
});

// 현재 사용자 프로바이더
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

// 인증 서비스 프로바이더
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _client = SupabaseConfig.client;

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 이메일/비밀번호 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('[AuthService] signUpWithEmail 시작');
    debugPrint('[AuthService] 이메일: $email');
    debugPrint('[AuthService] 비밀번호 길이: ${password.length}');
    debugPrint('[AuthService] 표시 이름: $displayName');
    debugPrint('[AuthService] Supabase URL: ${SupabaseConfig.supabaseUrl}');

    try {
      debugPrint('[AuthService] _auth.signUp 호출 시작');
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      debugPrint('[AuthService] signUp 응답 받음');
      debugPrint('[AuthService] user id: ${response.user?.id}');
      debugPrint('[AuthService] user email: ${response.user?.email}');
      debugPrint('[AuthService] session 존재: ${response.session != null}');
      debugPrint('[AuthService] session access_token: ${response.session?.accessToken.substring(0, 20)}...');

      // 트리거가 자동으로 profiles 테이블에 데이터를 생성하므로
      // 여기서는 추가 작업 불필요 (handle_new_user 트리거)

      return response;
    } catch (e, st) {
      debugPrint('[AuthService] signUpWithEmail 에러: $e');
      debugPrint('[AuthService] 에러 타입: ${e.runtimeType}');
      debugPrint('[AuthService] 스택 트레이스: $st');
      rethrow;
    }
  }

  // 이메일/비밀번호 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] signInWithEmail 시작');
    debugPrint('[AuthService] 이메일: $email');
    debugPrint('[AuthService] 비밀번호 길이: ${password.length}');
    debugPrint('[AuthService] Supabase URL: ${SupabaseConfig.supabaseUrl}');
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] 로그인 성공: user=${response.user?.id}');
      return response;
    } catch (e, st) {
      debugPrint('[AuthService] 로그인 에러: $e');
      debugPrint('[AuthService] 스택 트레이스: $st');
      rethrow;
    }
  }

  // Google 로그인
  Future<bool> signInWithGoogle() async {
    return await _auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: 'io.supabase.sharedaccount://login-callback/',
    );
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // 비밀번호 변경
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _client.from('profiles').update(updates).eq('id', currentUser!.id);
  }

  // 프로필 조회
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', currentUser!.id)
        .single();

    return response;
  }

  // 계정 삭제
  Future<void> deleteAccount() async {
    // 관련 데이터 삭제는 Supabase의 CASCADE 설정에 의해 자동 처리됨
    await _auth.signOut();
  }
}

// 인증 상태 노티파이어 (로그인/회원가입/로그아웃 액션용)
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    state = AsyncValue.data(_authService.currentUser);
  }

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signUpWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // 에러를 다시 throw하여 호출자가 catch할 수 있도록 함
    }
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // 에러를 다시 throw하여 호출자가 catch할 수 있도록 함
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signInWithGoogle();
      // OAuth 로그인은 리다이렉트 방식으로 처리됨
      // 인증 상태는 authStateProvider에서 자동으로 업데이트됨
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
