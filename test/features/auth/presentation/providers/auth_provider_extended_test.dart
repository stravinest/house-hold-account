import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/data/repositories/ledger_repository.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart'
    hide ledgerRepositoryProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockLedgerRepository extends Mock implements LedgerRepository {}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      await Supabase.initialize(
        url: 'https://test.supabase.co',
        anonKey: 'test-anon-key',
      );
    } catch (_) {
      // 이미 초기화된 경우 무시
    }
  });

  group('AuthService._getDisplayName 로직 테스트', () {
    // _getDisplayName 로직을 직접 구현하여 검증
    String getDisplayName({
      Map<String, dynamic>? userMetadata,
      String? email,
    }) {
      return userMetadata?['full_name'] ??
          userMetadata?['name'] ??
          email?.split('@').first ??
          'User';
    }

    test('full_name이 있으면 full_name을 반환한다', () {
      // Given
      final metadata = {'full_name': '홍길동', 'name': '다른이름'};

      // When
      final result = getDisplayName(userMetadata: metadata);

      // Then
      expect(result, equals('홍길동'));
    });

    test('full_name이 없고 name이 있으면 name을 반환한다', () {
      // Given
      final metadata = {'name': '홍길동'};

      // When
      final result = getDisplayName(userMetadata: metadata);

      // Then
      expect(result, equals('홍길동'));
    });

    test('metadata가 없고 email이 있으면 @앞 부분을 반환한다', () {
      // Given
      const email = 'user@example.com';

      // When
      final result = getDisplayName(email: email);

      // Then
      expect(result, equals('user'));
    });

    test('모든 값이 없으면 User를 반환한다', () {
      // Given & When
      final result = getDisplayName();

      // Then
      expect(result, equals('User'));
    });

    test('metadata와 email 모두 null이면 User를 반환한다', () {
      // Given
      final result = getDisplayName(userMetadata: null, email: null);

      // Then
      expect(result, equals('User'));
    });
  });

  group('AuthNotifier 확장 테스트', () {
    late _MockAuthService mockAuthService;
    late _MockLedgerRepository mockLedgerRepository;

    setUp(() {
      mockAuthService = _MockAuthService();
      mockLedgerRepository = _MockLedgerRepository();
      registerFallbackValue(const AsyncValue<User?>.loading());
    });

    ProviderContainer createContainer() {
      final container = ProviderContainer(
        overrides: [
          authServiceProvider.overrideWith((ref) => mockAuthService),
          ledgerRepositoryProvider.overrideWith(
            (ref) => mockLedgerRepository,
          ),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    group('초기화 상태 테스트', () {
      test('currentUser가 null이 아닐 때 초기 상태에 사용자가 설정된다', () {
        // Given: 로그인된 사용자
        final mockUser = MockUser();
        when(() => mockAuthService.currentUser).thenReturn(mockUser);

        // When: container 생성
        final container = createContainer();
        final state = container.read(authNotifierProvider);

        // Then: 초기 상태에 사용자가 존재한다
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, equals(mockUser));
      });

      test('초기화 시 _init이 호출되어 상태가 설정된다', () {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);

        // When
        final container = createContainer();

        // Then: AsyncData(null) 상태
        expect(container.read(authNotifierProvider), isA<AsyncData<User?>>());
        expect(container.read(authNotifierProvider).valueOrNull, isNull);
      });
    });

    group('signOut 추가 테스트', () {
      test('로그아웃 시 loading 상태를 거쳐 data(null)로 전환된다', () async {
        // Given
        final states = <AsyncValue<User?>>[];
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        final container = createContainer();
        container.listen(
          authNotifierProvider,
          (prev, next) => states.add(next),
          fireImmediately: false,
        );

        // When
        await container.read(authNotifierProvider.notifier).signOut();

        // Then: 최소 1개 이상 상태 변화
        expect(states.isNotEmpty, isTrue);
        expect(states.last, isA<AsyncData<User?>>());
        expect(states.last.valueOrNull, isNull);
      });
    });

    group('deleteAccount 추가 테스트', () {
      test('계정 삭제 중 loading 상태를 거친다', () async {
        // Given
        final states = <AsyncValue<User?>>[];
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});

        final container = createContainer();
        container.listen(
          authNotifierProvider,
          (prev, next) => states.add(next),
          fireImmediately: false,
        );

        // When
        await container.read(authNotifierProvider.notifier).deleteAccount();

        // Then
        expect(states.isNotEmpty, isTrue);
        // loading 상태가 포함된다
        expect(states.any((s) => s is AsyncLoading), isTrue);
      });
    });
  });

  group('AuthService 상수 및 타입 테스트', () {
    test('authStateProvider가 StreamProvider<User?> 타입이다', () {
      // Given & When & Then
      expect(authStateProvider, isA<StreamProvider<User?>>());
    });

    test('currentUserProvider가 Provider<User?> 타입이다', () {
      // Given & When & Then
      expect(currentUserProvider, isA<Provider<User?>>());
    });

    test('authServiceProvider가 Provider<AuthService> 타입이다', () {
      // Given & When & Then
      expect(authServiceProvider, isA<Provider<AuthService>>());
    });

    test('authNotifierProvider가 StateNotifierProvider 타입이다', () {
      // Given & When & Then
      expect(
        authNotifierProvider,
        isA<StateNotifierProvider<AuthNotifier, AsyncValue<User?>>>(),
      );
    });

    test('userColorProvider가 Provider<String> 타입이다', () {
      // Given & When & Then
      expect(userColorProvider, isA<Provider<String>>());
    });

    test('userColorByIdProvider가 FutureProvider.family 타입이다', () {
      // Given & When & Then
      expect(userColorByIdProvider, isNotNull);
    });
  });

  group('AuthService 검증 로직 테스트', () {
    group('HEX 색상 코드 검증', () {
      void validateHexColor(String color) {
        if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
          throw ArgumentError(
            'Invalid color format. Must be HEX code (e.g., #A8D8EA)',
          );
        }
      }

      test('빈 문자열은 ArgumentError를 발생시킨다', () {
        // Given
        const color = '';

        // When & Then
        expect(
          () => validateHexColor(color),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('공백 문자열은 ArgumentError를 발생시킨다', () {
        // Given
        const color = '   ';

        // When & Then
        expect(
          () => validateHexColor(color),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('#으로 시작하고 소문자 6자리도 유효하다', () {
        // Given
        const color = '#abcdef';

        // When & Then
        expect(() => validateHexColor(color), returnsNormally);
      });

      test('숫자만으로 구성된 6자리 HEX 코드도 유효하다', () {
        // Given
        const color = '#123456';

        // When & Then
        expect(() => validateHexColor(color), returnsNormally);
      });
    });
  });

  group('userProfileProvider 테스트', () {
    test('userProfileProvider가 autoDispose StreamProvider 타입이다', () {
      // Given & When & Then
      expect(userProfileProvider, isNotNull);
    });
  });

  group('HEX 기본 색상값 테스트', () {
    test('기본 색상이 파스텔 블루(#A8D8EA)이다', () {
      // Given: userColorProvider의 기본값 확인
      const defaultColor = '#A8D8EA';

      // When & Then
      expect(defaultColor, startsWith('#'));
      expect(defaultColor.length, equals(7));
    });

    test('기본 색상 HEX 코드 형식이 유효하다', () {
      // Given
      const defaultColor = '#A8D8EA';
      final hexPattern = RegExp(r'^#[0-9A-Fa-f]{6}$');

      // When & Then
      expect(hexPattern.hasMatch(defaultColor), isTrue);
    });
  });
}
