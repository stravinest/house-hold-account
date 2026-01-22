import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/supabase_config.dart';

/// Google Native Sign-In 서비스
///
/// google_sign_in 패키지를 사용하여 네이티브 Google 로그인을 처리하고,
/// Supabase의 signInWithIdToken을 통해 인증을 완료합니다.
class GoogleSignInService {
  // Web Client ID - .env에서 로드 (보안)
  static String get _webClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  // Google Sign-In 인스턴스
  late GoogleSignIn _googleSignIn;

  // 싱글톤 패턴
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;

  GoogleSignInService._internal() {
    _initializeGoogleSignIn();
  }

  void _initializeGoogleSignIn() {
    final clientId = _webClientId;
    if (clientId.isEmpty && kDebugMode) {
      debugPrint('[GoogleSignInService] GOOGLE_WEB_CLIENT_ID not set in .env');
    }
    _googleSignIn = GoogleSignIn(
      serverClientId: clientId.isNotEmpty ? clientId : null,
      scopes: ['email', 'profile'],
    );
  }

  /// iOS 클라이언트 ID 설정 (앱 시작 시 호출)
  void configure({String? iosClientId, String? webClientId}) {
    _googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId ?? _webClientId,
      scopes: ['email', 'profile'],
    );
  }

  /// Google 네이티브 로그인 후 Supabase 인증
  ///
  /// 1. Google Sign-In으로 사용자 인증
  /// 2. ID Token과 Access Token 획득
  /// 3. Supabase signInWithIdToken으로 세션 생성
  ///
  /// Returns: AuthResponse (성공 시) 또는 예외 throw
  Future<AuthResponse> signIn() async {
    try {
      debugPrint('[GoogleSignInService] 로그인 시작');

      // 1. Google Sign-In 실행
      final googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        debugPrint('[GoogleSignInService] 사용자가 로그인을 취소함');
        throw const AuthException('Google 로그인이 취소되었습니다.');
      }

      debugPrint('[GoogleSignInService] Google 사용자 인증됨');

      // 2. Authentication 정보 획득
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        debugPrint('[GoogleSignInService] ID Token이 없습니다');
        throw const AuthException('Google ID Token을 가져올 수 없습니다.');
      }

      debugPrint('[GoogleSignInService] ID Token 획득 완료');
      debugPrint(
        '[GoogleSignInService] Access Token: ${accessToken != null ? "있음" : "없음"}',
      );

      // 3. Supabase signInWithIdToken 호출
      final response = await SupabaseConfig.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      debugPrint('[GoogleSignInService] Supabase 인증 성공');

      return response;
    } on AuthException {
      rethrow;
    } catch (e) {
      debugPrint('[GoogleSignInService] 로그인 실패: ${e.runtimeType}');

      if (e.toString().contains('sign_in_canceled') ||
          e.toString().contains('canceled') ||
          e.toString().contains('CANCELED')) {
        throw const AuthException('Google 로그인이 취소되었습니다.');
      }

      throw AuthException('Google 로그인 실패: $e');
    }
  }

  /// Google 로그아웃
  ///
  /// Google 세션만 종료 (Supabase 세션은 별도 처리 필요)
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      debugPrint('[GoogleSignInService] Google 로그아웃 완료');
    } catch (e) {
      debugPrint('[GoogleSignInService] Google 로그아웃 실패: $e');
      // 로그아웃 실패는 무시 (Supabase 로그아웃이 주요 목적)
    }
  }

  /// Google 연결 해제 (계정 연결 완전 해제)
  ///
  /// 앱과 Google 계정 간의 연결을 완전히 해제합니다.
  /// 다음 로그인 시 권한 동의를 다시 받아야 합니다.
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      debugPrint('[GoogleSignInService] Google 연결 해제 완료');
    } catch (e) {
      debugPrint('[GoogleSignInService] Google 연결 해제 실패: $e');
    }
  }

  /// 현재 로그인된 Google 계정 확인
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// 조용히 로그인 시도 (이전 세션 복구)
  ///
  /// 이전에 로그인한 적이 있는 경우 UI 없이 자동 로그인
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('[GoogleSignInService] Silent sign-in 실패: $e');
      return null;
    }
  }
}
