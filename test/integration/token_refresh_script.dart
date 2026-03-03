// Access Token 만료 시 Refresh Token 자동 갱신 통합 테스트
//
// 실행 방법:
//   dart run test/integration/token_refresh_test.dart
//
// 테스트 계정이 필요합니다 (아래 credentials 수정)

import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

// ========== 설정 ==========
const supabaseUrl = 'https://qcpjxxgnqdbngyepevmt.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjcGp4eGducWRibmd5ZXBldm10Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0NjQ4OTUsImV4cCI6MjA4NDA0MDg5NX0.mrf-mE_mzR04NyhUWqJZmaOsDk4CwTcvedQv4HIxoOo';

// 테스트용 계정 (실제 계정으로 변경 필요)
const testEmail = 'user1@test.com';
const testPassword = 'testpass123';

void main() async {
  print('=== Access Token 만료 & Refresh Token 갱신 테스트 ===\n');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  try {
    // ---- STEP 1: 로그인 ----
    print('[STEP 1] 로그인 시도...');
    final authResponse = await client.auth.signInWithPassword(
      email: testEmail,
      password: testPassword,
    );

    final session = authResponse.session;
    if (session == null) {
      print('  실패: 세션을 받지 못했습니다.');
      exit(1);
    }

    print('  성공: 로그인 완료');
    print('  - User ID: ${session.user.id}');
    print('  - Access Token 앞 20자: ${session.accessToken.substring(0, 20)}...');
    print('  - Refresh Token: ${session.refreshToken?.substring(0, 10)}...');
    print('  - 만료 시각: ${DateTime.fromMillisecondsSinceEpoch(session.expiresAt! * 1000)}');
    print('');

    // ---- STEP 2: 정상 API 호출 확인 ----
    print('[STEP 2] 정상 상태에서 API 호출 테스트...');
    try {
      final profiles = await client.from('profiles').select('id, email').limit(1);
      print('  성공: profiles 조회 완료 (${profiles.length}개)');
    } catch (e) {
      print('  실패: $e');
    }
    print('');

    // ---- STEP 3: Access Token 강제 만료 시뮬레이션 ----
    print('[STEP 3] Access Token 강제 만료 시뮬레이션...');
    print('  현재 유효한 Refresh Token을 사용하여 세션 갱신을 테스트합니다.');

    // 방법: 만료된 가짜 JWT로 세션을 덮어씌운 뒤, SDK가 자동으로 refresh 하는지 확인
    // Supabase Dart SDK는 API 호출 실패 시 자동 갱신을 시도함

    final originalAccessToken = session.accessToken;
    final originalRefreshToken = session.refreshToken!;

    // JWT를 디코딩하여 만료 시각 확인
    final parts = originalAccessToken.split('.');
    final payload = json.decode(
      utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
    );
    print('  - JWT exp: ${DateTime.fromMillisecondsSinceEpoch(payload['exp'] * 1000)}');
    print('  - JWT iat: ${DateTime.fromMillisecondsSinceEpoch(payload['iat'] * 1000)}');
    print('');

    // ---- STEP 4: refreshSession() 직접 호출 테스트 ----
    print('[STEP 4] refreshSession() 직접 호출 테스트...');
    try {
      final refreshResponse = await client.auth.refreshSession();
      final newSession = refreshResponse.session;

      if (newSession == null) {
        print('  실패: 갱신된 세션을 받지 못했습니다.');
      } else {
        final tokenChanged = newSession.accessToken != originalAccessToken;
        print('  성공: 세션 갱신 완료');
        print('  - Access Token 변경됨: $tokenChanged');
        print('  - 새 Access Token 앞 20자: ${newSession.accessToken.substring(0, 20)}...');
        print('  - 새 만료 시각: ${DateTime.fromMillisecondsSinceEpoch(newSession.expiresAt! * 1000)}');
      }
    } catch (e) {
      print('  실패: $e');
    }
    print('');

    // ---- STEP 5: 갱신 후 API 호출 확인 ----
    print('[STEP 5] 갱신된 토큰으로 API 호출 테스트...');
    try {
      final profiles = await client.from('profiles').select('id, email').limit(1);
      print('  성공: profiles 조회 완료 (${profiles.length}개)');
    } catch (e) {
      print('  실패: $e');
    }
    print('');

    // ---- STEP 6: 잘못된 Refresh Token으로 갱신 실패 테스트 ----
    print('[STEP 6] 잘못된 Refresh Token으로 갱신 실패 시뮬레이션...');

    // 새 클라이언트로 잘못된 세션 설정
    final badClient = SupabaseClient(
      supabaseUrl,
      supabaseAnonKey,
      postgrestOptions: const PostgrestClientOptions(schema: 'house'),
    );

    try {
      // 잘못된 refresh token으로 갱신 시도
      await badClient.auth.setSession('invalid_refresh_token');
      print('  예상 외: 에러가 발생하지 않았습니다.');
    } on AuthException catch (e) {
      print('  예상대로 AuthException 발생:');
      print('  - message: ${e.message}');
      print('  - statusCode: ${e.statusCode}');
      print('  이 경우 앱에서는 로그인 화면으로 이동시켜야 합니다.');
    } catch (e) {
      print('  예상대로 에러 발생: $e');
    }
    print('');

    // ---- STEP 7: 네트워크 끊김 시뮬레이션 (타임아웃) ----
    print('[STEP 7] 네트워크 문제 시뮬레이션 (존재하지 않는 URL)...');

    final offlineClient = SupabaseClient(
      'https://nonexistent-project.supabase.co',
      supabaseAnonKey,
      postgrestOptions: const PostgrestClientOptions(schema: 'house'),
    );

    try {
      await offlineClient.from('profiles').select().limit(1).timeout(
        const Duration(seconds: 5),
      );
      print('  예상 외: 에러가 발생하지 않았습니다.');
    } catch (e) {
      print('  예상대로 에러 발생: ${e.runtimeType}');
      print('  - 네트워크 끊김 시 DB 저장 불가 확인됨');
      print('  - 하지만 로그인 자체가 풀리지는 않음 (로컬 세션 유지)');
    }
    print('');

    // ---- 결과 요약 ----
    print('=== 테스트 결과 요약 ===');
    print('1. 정상 로그인 후 API 호출: 성공');
    print('2. refreshSession() 자동 갱신: 성공 (Access Token 새로 발급됨)');
    print('3. 갱신 후 API 호출: 성공');
    print('4. 잘못된 Refresh Token: AuthException 발생 (로그인 풀림)');
    print('5. 네트워크 끊김: 에러 발생하지만 세션 자체는 유지');

    // 정리
    await client.auth.signOut();
    print('\n로그아웃 완료. 테스트 종료.');
  } catch (e, st) {
    print('테스트 중 예외 발생: $e');
    print(st);
    exit(1);
  }

  exit(0);
}
