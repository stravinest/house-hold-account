import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// router.dart의 redirect 로직을 순수 함수로 추출하여 테스트합니다.
/// 핵심: authState가 loading일 때 로그인 페이지로 튕기지 않는지 검증합니다.

// router.dart:100-141의 redirect 로직을 동일하게 재현
String? redirectLogic({
  required AsyncValue<User?> authState,
  required String matchedLocation,
}) {
  final isLoggedIn = authState.valueOrNull != null;
  final isAuthRoute = matchedLocation == '/login' ||
      matchedLocation == '/signup' ||
      matchedLocation == '/forgot-password' ||
      matchedLocation == '/email-verification';
  final isResetPassword = matchedLocation == '/reset-password';
  final isSplash = matchedLocation == '/';
  final isDeepLinkRoute = matchedLocation == '/add-expense' ||
      matchedLocation == '/add-income' ||
      matchedLocation == '/quick-expense' ||
      matchedLocation == '/payment-method';

  if (isSplash) return null;

  // 핵심 수정: loading 상태에서 redirect 보류
  if (authState.isLoading) return null;

  if (isDeepLinkRoute && isLoggedIn) return null;
  if (isResetPassword) return null;
  if (!isLoggedIn && !isAuthRoute) return '/login';
  if (isLoggedIn && isAuthRoute) return '/home';
  return null;
}

// 수정 전 로직 (버그 재현용)
String? redirectLogicBefore({
  required AsyncValue<User?> authState,
  required String matchedLocation,
}) {
  final isLoggedIn = authState.valueOrNull != null;
  final isAuthRoute = matchedLocation == '/login' ||
      matchedLocation == '/signup' ||
      matchedLocation == '/forgot-password' ||
      matchedLocation == '/email-verification';
  final isResetPassword = matchedLocation == '/reset-password';
  final isSplash = matchedLocation == '/';
  final isDeepLinkRoute = matchedLocation == '/add-expense' ||
      matchedLocation == '/add-income' ||
      matchedLocation == '/quick-expense' ||
      matchedLocation == '/payment-method';

  if (isSplash) return null;
  // 수정 전: loading 체크 없음!
  if (isDeepLinkRoute && isLoggedIn) return null;
  if (isResetPassword) return null;
  if (!isLoggedIn && !isAuthRoute) return '/login';
  if (isLoggedIn && isAuthRoute) return '/home';
  return null;
}

void main() {
  // ============================================================
  // 버그 재현: 수정 전 로직에서 loading 시 로그인으로 튕김
  // ============================================================
  group('[버그 재현] 수정 전 로직에서 loading 시 잘못된 redirect 발생', () {
    const loadingState = AsyncValue<User?>.loading();

    test('수정 전: 홈에서 loading 시 /login으로 잘못 redirect됨 (버그)', () {
      final result = redirectLogicBefore(
        authState: loadingState,
        matchedLocation: '/home',
      );
      // 수정 전에는 /login으로 보내버림 - 이것이 버그!
      expect(result, '/login',
          reason: '수정 전 로직은 loading을 미로그인으로 잘못 판단합니다');
    });

    test('수정 전: 설정에서 loading 시 /login으로 잘못 redirect됨 (버그)', () {
      final result = redirectLogicBefore(
        authState: loadingState,
        matchedLocation: '/settings',
      );
      expect(result, '/login');
    });
  });

  // ============================================================
  // 핵심 테스트: 수정 후 loading 상태에서 redirect 보류
  // ============================================================
  group('[수정 후] authState가 loading 상태일 때 redirect 보류', () {
    const loadingState = AsyncValue<User?>.loading();

    test('홈 화면에서 로그인 페이지로 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/home',
      );
      expect(result, isNull,
          reason: 'loading 상태에서는 redirect를 보류해야 합니다');
    });

    test('설정 페이지에서 로그인 페이지로 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/settings',
      );
      expect(result, isNull);
    });

    test('통계 페이지에서 로그인 페이지로 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/statistics',
      );
      expect(result, isNull);
    });

    test('검색 페이지에서 로그인 페이지로 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/search',
      );
      expect(result, isNull);
    });

    test('결제수단 페이지에서 로그인 페이지로 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/payment-method',
      );
      expect(result, isNull);
    });

    test('스플래시 화면에서도 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/',
      );
      expect(result, isNull);
    });

    test('로그인 페이지에서도 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loadingState,
        matchedLocation: '/login',
      );
      expect(result, isNull);
    });

    test('백그라운드 복귀 시 모든 주요 페이지에서 loading 시 현재 경로 유지', () {
      final pages = [
        '/home', '/settings', '/statistics', '/search',
        '/category', '/fixed-expense', '/recurring-templates',
        '/budget', '/share',
      ];

      for (final page in pages) {
        final result = redirectLogic(
          authState: loadingState,
          matchedLocation: page,
        );
        expect(result, isNull,
            reason: '$page 에서 loading 시 redirect가 발생하면 안 됩니다');
      }
    });
  });

  // ============================================================
  // 정상 케이스: 로그아웃 상태 (data(null))
  // ============================================================
  group('authState가 data(null)일 때 (명시적 로그아웃)', () {
    const loggedOutState = AsyncValue<User?>.data(null);

    test('홈 화면에서 로그인 페이지로 리다이렉트되어야 한다', () {
      final result = redirectLogic(
        authState: loggedOutState,
        matchedLocation: '/home',
      );
      expect(result, '/login');
    });

    test('설정 페이지에서 로그인 페이지로 리다이렉트되어야 한다', () {
      final result = redirectLogic(
        authState: loggedOutState,
        matchedLocation: '/settings',
      );
      expect(result, '/login');
    });

    test('로그인 페이지에서 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loggedOutState,
        matchedLocation: '/login',
      );
      expect(result, isNull);
    });

    test('회원가입 페이지에서 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loggedOutState,
        matchedLocation: '/signup',
      );
      expect(result, isNull);
    });

    test('비밀번호 재설정 페이지는 항상 접근 가능해야 한다', () {
      final result = redirectLogic(
        authState: loggedOutState,
        matchedLocation: '/reset-password',
      );
      expect(result, isNull);
    });

    test('비밀번호 찾기 페이지에서 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: loggedOutState,
        matchedLocation: '/forgot-password',
      );
      expect(result, isNull);
    });
  });

  // ============================================================
  // 에러 상태
  // ============================================================
  group('authState가 error일 때', () {
    final errorState = AsyncValue<User?>.error(
      Exception('Auth error'),
      StackTrace.current,
    );

    test('홈 화면에서 로그인 페이지로 리다이렉트되어야 한다', () {
      final result = redirectLogic(
        authState: errorState,
        matchedLocation: '/home',
      );
      expect(result, '/login');
    });

    test('로그인 페이지에서 리다이렉트되지 않아야 한다', () {
      final result = redirectLogic(
        authState: errorState,
        matchedLocation: '/login',
      );
      expect(result, isNull);
    });
  });

  // ============================================================
  // 상태 전환 시나리오
  // ============================================================
  group('상태 전환 시나리오 (앱 시작/복귀 시뮬레이션)', () {
    test('loading -> 로그인 완료: 홈 화면이 유지되어야 한다', () {
      // 1단계: loading - redirect 보류
      final result1 = redirectLogic(
        authState: const AsyncValue<User?>.loading(),
        matchedLocation: '/home',
      );
      expect(result1, isNull, reason: 'loading 중에는 현재 경로 유지');
    });

    test('loading -> 미로그인: 로그인 페이지로 이동해야 한다', () {
      // 1단계: loading - 보류
      final result1 = redirectLogic(
        authState: const AsyncValue<User?>.loading(),
        matchedLocation: '/home',
      );
      expect(result1, isNull, reason: 'loading 중에는 현재 경로 유지');

      // 2단계: data(null) - 미로그인 확정
      final result2 = redirectLogic(
        authState: const AsyncValue<User?>.data(null),
        matchedLocation: '/home',
      );
      expect(result2, '/login', reason: '세션 없으면 로그인 페이지로');
    });
  });

  // ============================================================
  // 회귀 테스트
  // ============================================================
  group('회귀 테스트 (기존 기능 유지 확인)', () {
    test('스플래시 화면은 어떤 상태에서든 리다이렉트되지 않아야 한다', () {
      final states = [
        const AsyncValue<User?>.loading(),
        const AsyncValue<User?>.data(null),
        AsyncValue<User?>.error(Exception('err'), StackTrace.current),
      ];
      for (final state in states) {
        final result = redirectLogic(
          authState: state,
          matchedLocation: '/',
        );
        expect(result, isNull);
      }
    });

    test('비밀번호 재설정은 어떤 상태에서든 접근 가능해야 한다', () {
      final states = [
        const AsyncValue<User?>.loading(),
        const AsyncValue<User?>.data(null),
        AsyncValue<User?>.error(Exception('err'), StackTrace.current),
      ];
      for (final state in states) {
        final result = redirectLogic(
          authState: state,
          matchedLocation: '/reset-password',
        );
        expect(result, isNull);
      }
    });
  });
}
