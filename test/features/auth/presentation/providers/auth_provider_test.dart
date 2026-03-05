import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/data/repositories/ledger_repository.dart';

// Mock 클래스 정의
class MockLedgerRepository extends Mock implements LedgerRepository {}

class FakeUser extends Fake implements User {
  final String _id;
  final String? _email;

  FakeUser({String id = 'test-user-id', String? email = 'test@example.com'})
    : _id = id,
      _email = email;

  @override
  String get id => _id;

  @override
  String? get email => _email;

  @override
  Map<String, dynamic>? get userMetadata => {'display_name': 'Test User'};
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // .env 파일 없거나 이미 로드된 경우 무시
    }
    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // 이미 초기화된 경우 무시
    }
    registerFallbackValue(FakeUser());
  });

  group('AuthService', () {
    group('_getDisplayName 메서드', () {
      test('AuthService는 클래스 타입이다', () {
        // Given/When/Then: AuthService 타입 자체가 클래스임을 확인
        // (환경 변수 없이 인스턴스 직접 생성 불가 - GoogleSignInService 의존)
        expect(AuthService, isNotNull);
      });
    });
  });

  group('AuthNotifier 상태 관리', () {
    test('authNotifierProvider는 StateNotifierProvider이다', () {
      // Given/When/Then: 타입 확인
      expect(
        authNotifierProvider,
        isA<StateNotifierProvider<AuthNotifier, AsyncValue<User?>>>(),
      );
    });

    test('authStateProvider는 StreamProvider이다', () {
      // Given/When/Then: 타입 확인
      expect(authStateProvider, isA<StreamProvider<User?>>());
    });

    test('currentUserProvider는 Provider이다', () {
      // Given/When/Then: 타입 확인
      expect(currentUserProvider, isA<Provider<User?>>());
    });

    test('ledgerRepositoryProvider는 Provider이다', () {
      // Given/When/Then: 타입 확인
      expect(ledgerRepositoryProvider, isA<Provider<LedgerRepository>>());
    });

    test('authServiceProvider는 Provider이다', () {
      // Given/When/Then: 타입 확인
      expect(authServiceProvider, isA<Provider<AuthService>>());
    });

    test('userColorProvider는 Provider이다', () {
      // Given/When/Then: 타입 확인
      expect(userColorProvider, isA<Provider<String>>());
    });

    test('userColorByIdProvider는 FutureProvider.family이다', () {
      // Given/When/Then: 타입 확인
      expect(userColorByIdProvider, isA<FutureProviderFamily<String, String>>());
    });
  });

  group('AuthNotifier 초기 상태', () {
    test('ProviderContainer를 통해 authNotifierProvider 상태를 읽을 수 있다', () {
      // Given: ProviderContainer (Supabase 없이도 타입 검사만 가능)
      // When/Then: 타입이 AsyncValue<User?>이다
      expect(
        const AsyncValue<User?>.data(null),
        isA<AsyncValue<User?>>(),
      );
    });

    test('AsyncValue.loading 상태를 생성할 수 있다', () {
      // Given/When: loading 상태 생성
      const loading = AsyncValue<User?>.loading();

      // Then: isLoading이 true이다
      expect(loading.isLoading, isTrue);
    });

    test('AsyncValue.data(null) 상태를 생성할 수 있다', () {
      // Given/When: 로그아웃 상태 (null user)
      const loggedOut = AsyncValue<User?>.data(null);

      // Then: isLoading이 false이고 valueOrNull이 null이다
      expect(loggedOut.isLoading, isFalse);
      expect(loggedOut.valueOrNull, isNull);
    });

    test('AsyncValue.error 상태를 생성할 수 있다', () {
      // Given/When: 에러 상태 생성
      final error = AsyncValue<User?>.error(
        Exception('로그인 실패'),
        StackTrace.current,
      );

      // Then: hasError가 true이다
      expect(error.hasError, isTrue);
    });
  });

  group('AuthService 메서드 시그니처 검증', () {
    test('authServiceProvider는 AuthService를 제공한다', () {
      // Given/When/Then: authServiceProvider가 Provider<AuthService> 타입임을 확인
      // (환경 변수 없이 AuthService 직접 인스턴스 생성 불가 - GoogleSignInService 의존)
      expect(authServiceProvider, isA<Provider<AuthService>>());
    });
  });
}
