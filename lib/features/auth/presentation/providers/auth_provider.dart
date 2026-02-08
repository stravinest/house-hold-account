import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';
import '../../../ledger/data/repositories/ledger_repository.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../notification/services/firebase_messaging_service.dart';
import '../../data/services/google_sign_in_service.dart';

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
  final GoogleSignInService _googleSignInService = GoogleSignInService();

  AuthService(this._ledgerRepository);

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // 이메일/비밀번호 회원가입
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    debugPrint('[AuthService] signUpWithEmail started');

    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: displayName != null ? {'display_name': displayName} : null,
      );

      debugPrint(
        '[AuthService] signUp completed, session exists: ${response.session != null}',
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
          debugPrint('[AuthService] FCM initialized');
        } catch (e) {
          debugPrint('[AuthService] FCM init failed (ignored)');
        }
      } else {
        debugPrint('[AuthService] Email verification required - skipping FCM');
      }

      return response;
    } catch (e) {
      debugPrint('[AuthService] signUpWithEmail error: ${e.runtimeType}');
      rethrow;
    }
  }

  // 백업 안전장치: 프로필이 없으면 생성 (Google 로그인 시 트리거 실패 대비)
  Future<void> _ensureProfileExists(User user) async {
    debugPrint('[AuthService] Checking profile existence...');

    try {
      final profile = await _client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profile != null) {
        debugPrint('[AuthService] Profile exists');
        return;
      }

      // 프로필이 없으면 생성
      debugPrint('[AuthService] Profile not found, creating...');
      final displayName =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'User';

      await _client.from('profiles').insert({
        'id': user.id,
        'email': user.email,
        'display_name': displayName,
      });
      debugPrint('[AuthService] Profile created');
    } catch (e) {
      debugPrint('[AuthService] Profile creation failed: ${e.runtimeType}');
      rethrow;
    }
  }

  // 백업 안전장치: 가계부가 0개면 기본 가계부 생성
  Future<void> _ensureDefaultLedgerExists() async {
    // DB 트리거 완료 대기 (최대 1.5초, 재시도 3회로 단축하여 UI 프리징 방지)
    for (int i = 0; i < 3; i++) {
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 500));
      }

      try {
        // timeout을 추가하여 네트워크 지연 시 무한 대기를 방지합니다.
        final ledgers = await _ledgerRepository.getLedgers().timeout(
          const Duration(seconds: 2),
        );

        if (ledgers.isNotEmpty) {
          debugPrint('[AuthService] Ledger confirmed: ${ledgers.length}');
          return;
        }
      } catch (e) {
        debugPrint('[AuthService] Ledger check failed (retry ${i + 1}/3): $e');
        if (i == 2) break;
        continue;
      }
    }

    // 여전히 0개면 생성 시도 (트리거 실패 추정)
    debugPrint(
      '[AuthService] Trigger failure suspected, creating backup ledger',
    );
    try {
      await _ledgerRepository.createLedger(name: '내 가계부', currency: 'KRW');
      debugPrint('[AuthService] Backup ledger created');
    } catch (e) {
      debugPrint(
        '[AuthService] Backup ledger creation failed: ${e.runtimeType}',
      );
      // CLAUDE.md 원칙: 데이터베이스 에러는 절대 무시하지 않는다
      rethrow;
    }
  }

  // 이메일/비밀번호 로그인
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] signInWithEmail started');
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[AuthService] Login successful');

      try {
        await _firebaseMessaging.initialize(response.user!.id);
        debugPrint('[AuthService] FCM initialized');
      } catch (e) {
        debugPrint('[AuthService] FCM init failed: ${e.runtimeType}');
      }

      return response;
    } catch (e) {
      debugPrint('[AuthService] Login error: $e');
      rethrow;
    }
  }

  // Google 로그인 (Native)
  //
  // google_sign_in 패키지를 사용하여 네이티브 Google 로그인 후
  // Supabase signInWithIdToken으로 인증을 완료합니다.
  Future<AuthResponse> signInWithGoogle() async {
    debugPrint('[AuthService] signInWithGoogle started');

    try {
      // 1. Native Google Sign-In + Supabase 인증
      final response = await _googleSignInService.signIn();
      debugPrint('[AuthService] Google login successful');

      // 2. 로그인 성공 시 프로필/가계부 확인 및 FCM 초기화
      if (response.session != null && response.user != null) {
        // 백업 안전장치: DB 트리거가 실패했을 경우를 대비
        // 프로필 먼저 확인 (가계부의 owner_id가 profiles를 참조하므로)
        await _ensureProfileExists(response.user!);
        // 가계부 확인 및 생성
        await _ensureDefaultLedgerExists();

        // FCM 토큰 등록
        try {
          await _firebaseMessaging.initialize(response.user!.id);
          debugPrint('[AuthService] FCM initialized');
        } catch (e) {
          debugPrint('[AuthService] FCM init failed (ignored)');
        }
      }

      return response;
    } catch (e) {
      debugPrint('[AuthService] Google login failed: ${e.runtimeType}');
      rethrow;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    // 로그아웃 전에 FCM 토큰 삭제
    final userId = currentUser?.id;
    if (userId != null) {
      // FCM 토큰 삭제 실패가 로그아웃을 방해하면 안 되므로 try-catch로 감싸고 silent fail
      try {
        await _firebaseMessaging.deleteToken(userId);
        debugPrint('[AuthService] FCM token deleted');
      } catch (e) {
        debugPrint('[AuthService] FCM token delete failed (ignored)');
      }
    }

    // Google 로그아웃도 함께 처리
    try {
      await _googleSignInService.signOut();
    } catch (e) {
      debugPrint('[AuthService] Google signOut failed (ignored)');
    }

    // SharedPreferences에서 저장된 가계부 ID 삭제 (다른 사용자 로그인 시 RLS 위반 방지)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_ledger_id');
      debugPrint('[AuthService] Stored ledger ID deleted');
    } catch (e) {
      debugPrint('[AuthService] Stored ledger ID delete failed (ignored)');
    }

    await _auth.signOut();
  }

  // 비밀번호 재설정 이메일 전송
  Future<void> resetPassword(String email) async {
    await _auth.resetPasswordForEmail(
      email,
      redirectTo: 'sharedhousehold://auth-callback/',
    );
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
  final Ref _ref;

  AuthNotifier(this._authService, this._ref)
    : super(const AsyncValue.loading()) {
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

      // 로그인 성공 후 가계부 상태 초기화
      _ref.read(selectedLedgerIdProvider.notifier).state = null;
      _ref.invalidate(ledgerNotifierProvider);

      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow; // 에러를 다시 throw하여 호출자가 catch할 수 있도록 함
    }
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signInWithGoogle();

      // 로그인 성공 후 가계부 상태 초기화
      _ref.read(selectedLedgerIdProvider.notifier).state = null;
      _ref.invalidate(ledgerNotifierProvider);

      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();

      // 선택된 가계부 ID 초기화 (다른 사용자 로그인 시 RLS 위반 방지)
      _ref.read(selectedLedgerIdProvider.notifier).state = null;
      debugPrint('[AuthNotifier] selectedLedgerIdProvider cleared');

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
      return AuthNotifier(authService, ref);
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
