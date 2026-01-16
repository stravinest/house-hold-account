import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../ledger/data/repositories/ledger_repository.dart';
import '../../../notification/services/firebase_messaging_service.dart';

// 현재 인증 상태를 관찰하는 프로바이더
final authStateProvider = StreamProvider<User?>((ref) {
  return SupabaseConfig.auth.onAuthStateChange.map(
    (event) => event.session?.user,
  );
});

// 현재 사용자 프로바이더
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

// LedgerRepository 프로바이더
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository();
});

// 인증 서비스 프로바이더
final authServiceProvider = Provider<AuthService>((ref) {
  final ledgerRepository = ref.watch(ledgerRepositoryProvider);
  return AuthService(ledgerRepository);
});

class AuthService {
  final _auth = SupabaseConfig.auth;
  final _client = SupabaseConfig.client;
  final LedgerRepository _ledgerRepository;
  final FirebaseMessagingService _firebaseMessaging =
      FirebaseMessagingService();

  AuthService(this._ledgerRepository);

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
      debugPrint(
        '[AuthService] session access_token: ${response.session?.accessToken?.substring(0, 20)}...',
      );

      // 트리거가 자동으로 profiles 테이블에 데이터를 생성하므로
      // 여기서는 추가 작업 불필요 (handle_new_user 트리거)

      // 이메일 확인이 필요한 경우 세션이 null
      // 세션이 있을 때만 가계부 확인 및 FCM 초기화 진행
      if (response.session != null) {
        // 백업 안전장치: DB 트리거가 실패했을 경우를 대비
        await _ensureDefaultLedgerExists();

        // FCM 토큰 등록
        try {
          await _firebaseMessaging.initialize(response.user!.id);
          debugPrint('[AuthService] FCM 초기화 성공');
        } catch (e) {
          debugPrint('[AuthService] FCM 초기화 실패 (무시됨): $e');
        }
      } else {
        debugPrint('[AuthService] 이메일 확인 필요 - 가계부/FCM 초기화 건너뜀');
      }

      return response;
    } catch (e, st) {
      debugPrint('[AuthService] signUpWithEmail 에러: $e');
      debugPrint('[AuthService] 에러 타입: ${e.runtimeType}');
      debugPrint('[AuthService] 스택 트레이스: $st');
      rethrow;
    }
  }

  // 백업 안전장치: 가계부가 0개면 기본 가계부 생성
  Future<void> _ensureDefaultLedgerExists() async {
    // DB 트리거 완료 대기 (최대 3초, 재시도 6회)
    for (int i = 0; i < 6; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      try {
        final ledgers = await _ledgerRepository.getLedgers();

        if (ledgers.isNotEmpty) {
          debugPrint('[AuthService] 기본 가계부 확인됨: ${ledgers.length}개');
          return;
        }
      } catch (e) {
        // getLedgers 실패는 계속 재시도
        debugPrint('[AuthService] 가계부 조회 실패 (재시도 ${i + 1}/6): $e');
        if (i == 5) {
          debugPrint('[AuthService] 가계부 조회 최종 실패');
          rethrow;
        }
        continue;
      }
    }

    // 여전히 0개면 생성 시도 (트리거 실패 추정)
    debugPrint('[AuthService] 트리거 실패 추정, 백업 가계부 생성 시작');
    try {
      await _ledgerRepository.createLedger(name: '내 가계부', currency: 'KRW');
      debugPrint('[AuthService] 백업 가계부 생성 완료');
    } catch (e, st) {
      debugPrint('[AuthService] 백업 가계부 생성 실패: $e');
      debugPrint('[AuthService] 스택 트레이스: $st');
      // CLAUDE.md 원칙: 데이터베이스 에러는 절대 무시하지 않는다
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

      try {
        debugPrint('');
        debugPrint('════════════════════════════════');
        debugPrint('[AuthService] FCM 초기화 시작...');
        debugPrint('User ID: ${response.user!.id}');
        debugPrint('════════════════════════════════');

        await _firebaseMessaging.initialize(response.user!.id);

        debugPrint('════════════════════════════════');
        debugPrint('[AuthService] ✅ FCM 초기화 성공!');
        debugPrint('════════════════════════════════');
        debugPrint('');
      } catch (e, st) {
        debugPrint('');
        debugPrint('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
        debugPrint('[AuthService] FCM 초기화 실패!');
        debugPrint('에러: $e');
        debugPrint('타입: ${e.runtimeType}');
        debugPrint('스택 트레이스:');
        debugPrint('$st');
        debugPrint('❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌❌');
        debugPrint('');
      }

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
    // 로그아웃 전에 FCM 토큰 삭제
    final userId = currentUser?.id;
    if (userId != null) {
      // FCM 토큰 삭제 실패가 로그아웃을 방해하면 안 되므로 try-catch로 감싸고 silent fail
      try {
        await _firebaseMessaging.deleteToken(userId);
        debugPrint('[AuthService] FCM 토큰 삭제 성공');
      } catch (e) {
        debugPrint('[AuthService] FCM 토큰 삭제 실패 (무시됨): $e');
      }
    }

    await _auth.signOut();
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(email);
  }

  // 비밀번호 변경
  Future<UserResponse> updatePassword(String newPassword) async {
    return await _auth.updateUser(UserAttributes(password: newPassword));
  }

  // 현재 비밀번호 검증 후 새 비밀번호로 변경
  Future<void> verifyAndUpdatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = currentUser?.email;
    if (email == null) {
      throw Exception('로그인 상태가 아닙니다');
    }

    // 현재 비밀번호로 재인증
    try {
      await _auth.signInWithPassword(email: email, password: currentPassword);
    } catch (e) {
      throw Exception('현재 비밀번호가 올바르지 않습니다');
    }

    // 새 비밀번호로 변경
    await _auth.updateUser(UserAttributes(password: newPassword));
  }

  // HEX 색상 코드 검증
  void _validateHexColor(String color) {
    if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
      throw ArgumentError(
        'Invalid color format. Must be HEX code (e.g., #A8D8EA)',
      );
    }
  }

  // 프로필 업데이트
  Future<void> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? color,
  }) async {
    if (currentUser == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['display_name'] = displayName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
    if (color != null) {
      _validateHexColor(color);
      updates['color'] = color;
    }
    updates['updated_at'] = DateTime.now().toIso8601String();

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', currentUser!.id)
        .select()
        .single();
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
    // RPC 함수를 통해 사용자 데이터 및 계정 삭제
    await SupabaseConfig.client.rpc('delete_user_account');
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

  Future<void> deleteAccount() async {
    state = const AsyncValue.loading();
    try {
      await _authService.deleteAccount();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
      final authService = ref.watch(authServiceProvider);
      return AuthNotifier(authService);
    });

// 사용자 프로필을 실시간으로 스트리밍하는 프로바이더
final userProfileProvider = StreamProvider.autoDispose<Map<String, dynamic>?>((
  ref,
) async* {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    yield null;
    return;
  }

  final stream = SupabaseConfig.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', user.id);

  await for (final data in stream) {
    yield data.isNotEmpty ? data.first : null;
  }
});

// 현재 사용자의 색상을 제공하는 프로바이더
final userColorProvider = Provider<String>((ref) {
  final profile = ref.watch(userProfileProvider).valueOrNull;
  return profile?['color'] ?? '#A8D8EA';
});

// 특정 사용자 ID로 색상을 조회하는 프로바이더
final userColorByIdProvider = FutureProvider.family<String, String>((
  ref,
  userId,
) async {
  try {
    final response = await SupabaseConfig.client
        .from('profiles')
        .select('color')
        .eq('id', userId)
        .single();
    return response['color'] ?? '#A8D8EA';
  } catch (e) {
    // 사용자를 찾을 수 없거나 에러 발생 시 기본 색상 반환
    return '#A8D8EA';
  }
});
