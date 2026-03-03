// 세션 복원 및 로그인 풀림 시나리오 종합 테스트
//
// 실행 방법:
//   dart run test/integration/session_restore_test.dart
//
// 목적: 앱 실행 시 로그인이 예상치 않게 풀리는 원인 규명

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:supabase/supabase.dart';

const supabaseUrl = 'https://qcpjxxgnqdbngyepevmt.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFjcGp4eGducWRibmd5ZXBldm10Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg0NjQ4OTUsImV4cCI6MjA4NDA0MDg5NX0.mrf-mE_mzR04NyhUWqJZmaOsDk4CwTcvedQv4HIxoOo';

const testEmail = 'user1@test.com';
const testPassword = 'testpass123';

int _passed = 0;
int _failed = 0;

void _result(String name, bool success, [String? detail]) {
  if (success) {
    _passed++;
    print('  [PASS] $name');
  } else {
    _failed++;
    print('  [FAIL] $name');
  }
  if (detail != null) print('         $detail');
}

void main() async {
  print('============================================================');
  print('  세션 복원 & 로그인 풀림 시나리오 종합 테스트');
  print('============================================================\n');

  await test1_onAuthStateChangeEmitOrder();
  await test2_refreshTokenReuse();
  await test3_concurrentRefresh();
  await test4_expiredAccessTokenApiCall();
  await test5_revokedRefreshToken();
  await test6_sessionRecoveryAfterNetworkFailure();
  await test7_multipleSignInSignOut();
  await test8_backgroundSimulation();
  await test9_corruptedSession();
  await test10_simultaneousApiCalls();

  print('\n============================================================');
  print('  결과: $_passed개 통과, $_failed개 실패 (총 ${_passed + _failed}개)');
  print('============================================================');

  exit(_failed > 0 ? 1 : 0);
}

// ============================================================
// 테스트 1: onAuthStateChange 이벤트 emit 순서 확인
// - 앱 시작 시 null이 먼저 emit되는지 확인 (로그인 풀림의 핵심 원인)
// ============================================================
Future<void> test1_onAuthStateChangeEmitOrder() async {
  print('\n[테스트 1] onAuthStateChange 이벤트 emit 순서 확인');
  print('  목적: 로그인 후 새 클라이언트 생성 시 첫 이벤트가 무엇인지 확인');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  // 로그인
  final auth = await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );
  final refreshToken = auth.session!.refreshToken!;

  // 새 클라이언트 생성 (앱 재시작 시뮬레이션)
  final newClient = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final events = <String>[];
  final completer = Completer<void>();

  final sub = newClient.auth.onAuthStateChange.listen((data) {
    final eventName = data.event.name;
    final hasUser = data.session?.user != null;
    events.add('$eventName(user=${hasUser ? "있음" : "없음"})');

    // 첫 이벤트 수신 후 짧은 대기
    if (events.length == 1) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (!completer.isCompleted) completer.complete();
      });
    }
  });

  // 저장된 세션 복원 시뮬레이션
  try {
    await newClient.auth.setSession(refreshToken);
  } catch (_) {}

  // 이벤트 수집 대기
  await completer.future.timeout(
    Duration(seconds: 5),
    onTimeout: () {},
  );

  await sub.cancel();
  print('  수신된 이벤트 순서: $events');

  // 첫 이벤트에 user가 없으면 로그인 풀림 가능
  final firstEventHasNoUser = events.isNotEmpty &&
      events.first.contains('user=없음');

  if (firstEventHasNoUser) {
    _result(
      'onAuthStateChange 첫 이벤트에 user 없음 감지',
      true, // 테스트 자체는 통과 (현상 확인)
      '*** 주의: 이것이 로그인 풀림의 원인일 수 있습니다! ***',
    );
  } else {
    _result(
      'onAuthStateChange 첫 이벤트에 user 있음',
      true,
      '정상: 첫 이벤트부터 user 정보가 포함됨',
    );
  }

  await client.auth.signOut();
  await newClient.dispose();
  await client.dispose();
}

// ============================================================
// 테스트 2: Refresh Token 재사용 가능 여부
// - 같은 refresh token으로 여러 번 갱신 가능한지 확인
// - rotation이 활성화되어 있으면 재사용 불가 → 로그인 풀림
// ============================================================
Future<void> test2_refreshTokenReuse() async {
  print('\n[테스트 2] Refresh Token 재사용 (rotation) 테스트');
  print('  목적: refresh token rotation으로 인한 로그인 풀림 가능성 확인');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final auth = await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );
  final originalRefreshToken = auth.session!.refreshToken!;

  // 첫 번째 갱신
  final refresh1 = await client.auth.refreshSession();
  final newRefreshToken1 = refresh1.session!.refreshToken!;
  final rotated = originalRefreshToken != newRefreshToken1;

  _result(
    'Refresh Token Rotation 활성화 여부',
    true,
    'Rotation ${rotated ? "활성화됨" : "비활성화됨"} (원본과 ${rotated ? "다름" : "같음"})',
  );

  if (rotated) {
    // rotation이 활성화된 경우, 이전 토큰으로 갱신 시도
    print('  -> 이전(원본) Refresh Token으로 재사용 시도...');
    final testClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
    try {
      await testClient.auth.setSession(originalRefreshToken);
      _result(
        '이전 Refresh Token 재사용',
        true,
        '재사용 가능 (grace period 존재)',
      );
    } on AuthException catch (e) {
      _result(
        '이전 Refresh Token 재사용',
        true, // 현상 확인 목적이므로 pass
        '*** 재사용 불가! (${e.message}) - 이것이 로그인 풀림 원인 가능 ***',
      );
    }
    await testClient.dispose();
  }

  await client.auth.signOut();
  await client.dispose();
}

// ============================================================
// 테스트 3: 동시 Refresh 요청 (Race Condition)
// - 여러 API가 동시에 401을 받고 동시에 refresh 요청하는 시나리오
// - refresh token rotation + 동시 갱신 = 두 번째 요청 실패 가능
// ============================================================
Future<void> test3_concurrentRefresh() async {
  print('\n[테스트 3] 동시 Refresh 요청 (Race Condition) 테스트');
  print('  목적: 여러 API 호출이 동시에 토큰 갱신을 시도할 때 문제 발생 여부');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );

  // 동시에 3개의 refreshSession 호출
  try {
    final results = await Future.wait([
      client.auth.refreshSession(),
      client.auth.refreshSession(),
      client.auth.refreshSession(),
    ]);

    final allSucceeded = results.every((r) => r.session != null);
    _result(
      '동시 3개 refreshSession() 호출',
      allSucceeded,
      '모든 갱신 ${allSucceeded ? "성공" : "일부 실패"}',
    );
  } catch (e) {
    _result(
      '동시 3개 refreshSession() 호출',
      false,
      '에러 발생: $e - *** 동시 갱신 시 로그인 풀림 가능! ***',
    );
  }

  await client.auth.signOut();
  await client.dispose();
}

// ============================================================
// 테스트 4: 만료된 Access Token으로 API 호출 시 자동 갱신
// - SDK가 401 응답 후 자동으로 refresh하는지 확인
// ============================================================
Future<void> test4_expiredAccessTokenApiCall() async {
  print('\n[테스트 4] 만료된 Access Token으로 API 호출 시 SDK 자동 갱신');
  print('  목적: Access Token 만료 후 API 호출이 자동으로 복구되는지 확인');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );

  final originalToken = client.auth.currentSession!.accessToken;

  // Access Token 강제 만료 시뮬레이션은 SDK 레벨에서 직접 불가능
  // 대신 refreshSession 후 정상 동작 확인
  await client.auth.refreshSession();
  final newToken = client.auth.currentSession!.accessToken;

  try {
    final result = await client
        .from('profiles')
        .select('id')
        .limit(1);

    _result(
      '갱신된 토큰으로 API 호출',
      result.isNotEmpty,
      'Access Token 변경됨: ${originalToken != newToken}',
    );
  } catch (e) {
    _result('갱신된 토큰으로 API 호출', false, '에러: $e');
  }

  await client.auth.signOut();
  await client.dispose();
}

// ============================================================
// 테스트 5: Revoke된 Refresh Token 시나리오
// - signOut 후 이전 refresh token 사용 시도
// ============================================================
Future<void> test5_revokedRefreshToken() async {
  print('\n[테스트 5] 로그아웃 후 이전 Refresh Token 사용 시도');
  print('  목적: 로그아웃이 refresh token을 실제로 무효화하는지 확인');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final auth = await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );
  final refreshToken = auth.session!.refreshToken!;

  // 로그아웃
  await client.auth.signOut();

  // 이전 refresh token으로 세션 복원 시도
  final newClient = SupabaseClient(supabaseUrl, supabaseAnonKey);
  try {
    await newClient.auth.setSession(refreshToken);
    final hasUser = newClient.auth.currentSession?.user != null;
    _result(
      '로그아웃 후 이전 Refresh Token 사용',
      !hasUser,
      hasUser
          ? '*** 주의: 로그아웃 후에도 이전 토큰 사용 가능! ***'
          : '정상: 이전 토큰 무효화됨',
    );
  } on AuthException catch (e) {
    _result(
      '로그아웃 후 이전 Refresh Token 사용',
      true,
      '정상: AuthException 발생 (${e.message})',
    );
  }

  await newClient.dispose();
  await client.dispose();
}

// ============================================================
// 테스트 6: 네트워크 실패 후 세션 복구
// - 네트워크 끊김 → 복구 → 세션이 살아있는지 확인
// ============================================================
Future<void> test6_sessionRecoveryAfterNetworkFailure() async {
  print('\n[테스트 6] 네트워크 실패 후 세션 복구 가능 여부');
  print('  목적: 네트워크 끊김이 세션을 무효화하는지 확인');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );

  // 네트워크 실패 시뮬레이션 (잘못된 URL로 요청)
  final offlineClient = SupabaseClient(
    'https://nonexistent.supabase.co',
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  try {
    await offlineClient.from('profiles').select().limit(1).timeout(
      Duration(seconds: 3),
    );
  } catch (_) {
    // 예상된 에러 - 무시
  }

  // 원래 클라이언트로 복귀 (네트워크 복구 시뮬레이션)
  final sessionStillValid = client.auth.currentSession != null;
  bool apiWorks = false;

  if (sessionStillValid) {
    try {
      final result = await client.from('profiles').select('id').limit(1);
      apiWorks = result.isNotEmpty;
    } catch (_) {}
  }

  _result(
    '네트워크 실패 후 세션 유지',
    sessionStillValid && apiWorks,
    '세션 유지: $sessionStillValid, API 동작: $apiWorks',
  );

  await client.auth.signOut();
  await offlineClient.dispose();
  await client.dispose();
}

// ============================================================
// 테스트 7: 빠른 로그인/로그아웃 반복 (Race Condition)
// - 연속적인 signIn/signOut이 세션 상태를 꼬이게 하는지
// ============================================================
Future<void> test7_multipleSignInSignOut() async {
  print('\n[테스트 7] 빠른 로그인/로그아웃 반복 테스트');
  print('  목적: 연속적인 인증 상태 변경이 세션을 꼬이게 하는지 확인');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  try {
    for (var i = 0; i < 3; i++) {
      await client.auth.signInWithPassword(
        email: testEmail,
        password: testPassword,
      );
      await client.auth.signOut();
    }

    // 마지막으로 로그인하고 API 호출
    await client.auth.signInWithPassword(
      email: testEmail,
      password: testPassword,
    );

    final result = await client.from('profiles').select('id').limit(1);
    _result(
      '3회 로그인/로그아웃 후 최종 API 호출',
      result.isNotEmpty,
      '정상 동작 확인',
    );

    await client.auth.signOut();
  } catch (e) {
    _result('3회 로그인/로그아웃 후 최종 API 호출', false, '에러: $e');
  }

  await client.dispose();
}

// ============================================================
// 테스트 8: 장시간 백그라운드 시뮬레이션
// - 로그인 후 대기 → refreshSession → API 호출
// ============================================================
Future<void> test8_backgroundSimulation() async {
  print('\n[테스트 8] 장시간 백그라운드 시뮬레이션 (5초 대기)');
  print('  목적: 대기 후 세션 갱신 및 API 호출이 정상인지 확인');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );

  final beforeToken = client.auth.currentSession!.accessToken;

  // 백그라운드 대기 시뮬레이션
  print('  5초 대기 중...');
  await Future.delayed(Duration(seconds: 5));

  // 포그라운드 복귀 - 세션 갱신 시도
  try {
    final refreshed = await client.auth.refreshSession();
    final afterToken = refreshed.session!.accessToken;

    final result = await client.from('profiles').select('id').limit(1);
    _result(
      '5초 대기 후 세션 갱신 + API 호출',
      result.isNotEmpty,
      'Token 변경: ${beforeToken != afterToken}',
    );
  } catch (e) {
    _result('5초 대기 후 세션 갱신 + API 호출', false, '에러: $e');
  }

  await client.auth.signOut();
  await client.dispose();
}

// ============================================================
// 테스트 9: 손상된 세션 데이터로 복원 시도
// - 잘못된 형식의 토큰으로 setSession 호출
// ============================================================
Future<void> test9_corruptedSession() async {
  print('\n[테스트 9] 손상된 세션 데이터로 복원 시도');
  print('  목적: SharedPreferences에 저장된 세션이 손상되었을 때 동작 확인');

  final client = SupabaseClient(supabaseUrl, supabaseAnonKey);

  final testCases = [
    ('빈 문자열', ''),
    ('잘못된 형식', 'not-a-valid-token'),
    ('잘린 JWT', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3Mi'),
    ('null 문자 포함', 'token\x00corrupted'),
  ];

  for (final (name, token) in testCases) {
    try {
      await client.auth.setSession(token);
      _result('손상된 세션 ($name)', false, '에러가 발생하지 않음 - 예상 외');
    } on AuthException catch (e) {
      _result('손상된 세션 ($name)', true, 'AuthException: ${e.message}');
    } on FormatException catch (e) {
      _result('손상된 세션 ($name)', true, 'FormatException: ${e.message}');
    } catch (e) {
      _result('손상된 세션 ($name)', true, '${e.runtimeType}: $e');
    }
  }

  await client.dispose();
}

// ============================================================
// 테스트 10: 동시 다수 API 호출 시 토큰 일관성
// - 여러 API를 동시에 호출할 때 모두 같은 토큰을 사용하는지
// ============================================================
Future<void> test10_simultaneousApiCalls() async {
  print('\n[테스트 10] 동시 다수 API 호출 시 일관성 테스트');
  print('  목적: 여러 API 동시 호출 시 인증 에러 발생 여부');

  final client = SupabaseClient(
    supabaseUrl,
    supabaseAnonKey,
    postgrestOptions: const PostgrestClientOptions(schema: 'house'),
  );

  await client.auth.signInWithPassword(
    email: testEmail,
    password: testPassword,
  );

  try {
    final results = await Future.wait([
      client.from('profiles').select('id').limit(1),
      client.from('ledgers').select('id').limit(1),
      client.from('categories').select('id').limit(1),
      client.from('payment_methods').select('id').limit(1),
      client.from('transactions').select('id').limit(1),
    ]);

    final allSucceeded = results.every((r) => r is List);
    _result(
      '5개 API 동시 호출',
      allSucceeded,
      '모든 호출 성공',
    );
  } catch (e) {
    _result('5개 API 동시 호출', false, '에러: $e');
  }

  await client.auth.signOut();
  await client.dispose();
}
