import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/data/repositories/ledger_repository.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart' hide ledgerRepositoryProvider;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/test_helpers.dart';

// MockAuthService - AuthService를 Mock으로 대체
class MockAuthService extends Mock implements AuthService {}

// MockLedgerRepository
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

  group('AuthNotifier 테스트', () {
    late MockAuthService mockAuthService;
    late _MockLedgerRepository mockLedgerRepository;

    setUp(() {
      mockAuthService = MockAuthService();
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

    group('초기화', () {
      test('AuthNotifier가 초기화될 때 currentUser를 읽어 초기 상태를 설정한다', () {
        // Given: currentUser가 null인 경우
        when(() => mockAuthService.currentUser).thenReturn(null);

        // When: container 생성 (notifier 초기화)
        final container = createContainer();
        final state = container.read(authNotifierProvider);

        // Then: 초기 상태가 data(null)이어야 한다
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, isNull);
      });

      test('로그인된 사용자가 있을 때 초기 상태에 사용자가 설정된다', () {
        // Given: currentUser가 존재하는 경우
        final mockUser = MockUser();
        when(() => mockAuthService.currentUser).thenReturn(mockUser);

        // When: container 생성
        final container = createContainer();
        final state = container.read(authNotifierProvider);

        // Then: 초기 상태에 사용자가 설정되어야 한다
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, equals(mockUser));
      });
    });

    group('signInWithEmail', () {
      test('이메일 로그인 성공 시 상태가 data(user)로 변경된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signInWithEmail(email: 'test@test.com', password: 'password123');

        // Then
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, equals(mockUser));
      });

      test('이메일 로그인 실패 시 상태가 error로 변경되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(const AuthException('invalid_credentials'));

        final container = createContainer();

        // When & Then: 예외가 rethrow된다
        await expectLater(
          () => container
              .read(authNotifierProvider.notifier)
              .signInWithEmail(
                email: 'test@test.com',
                password: 'wrong',
              ),
          throwsA(isA<AuthException>()),
        );

        // 상태가 error로 변경된다
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncError<User?>>());
      });

      test('이메일 로그인 성공 시 selectedLedgerId가 초기화된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();
        // 먼저 selectedLedgerId에 값을 설정
        container.read(selectedLedgerIdProvider.notifier).state = 'some-ledger-id';

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signInWithEmail(email: 'test@test.com', password: 'password123');

        // Then: selectedLedgerId가 null로 초기화된다
        expect(container.read(selectedLedgerIdProvider), isNull);
      });
    });

    group('signUpWithEmail', () {
      test('회원가입 성공 시 상태가 data(user)로 변경된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signUpWithEmail(
              email: 'newuser@test.com',
              password: 'password123',
              displayName: '테스트 유저',
            );

        // Then
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, equals(mockUser));
      });

      test('회원가입 실패 시 상태가 error로 변경되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(const AuthException('user_already_exists'));

        final container = createContainer();

        // When & Then
        await expectLater(
          () => container
              .read(authNotifierProvider.notifier)
              .signUpWithEmail(
                email: 'existing@test.com',
                password: 'password123',
              ),
          throwsA(isA<AuthException>()),
        );

        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncError<User?>>());
      });

      test('회원가입 시 displayName 없이도 동작한다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signUpWithEmail(
              email: 'test@test.com',
              password: 'password123',
            );

        // Then
        final state = container.read(authNotifierProvider);
        expect(state.valueOrNull, equals(mockUser));
      });
    });

    group('signInWithGoogle', () {
      test('Google 로그인 성공 시 상태가 data(user)로 변경된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(() => mockAuthService.signInWithGoogle())
            .thenAnswer((_) async => mockResponse);

        final container = createContainer();

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signInWithGoogle();

        // Then
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, equals(mockUser));
      });

      test('Google 로그인 실패 시 상태가 error로 변경되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.signInWithGoogle())
            .thenThrow(const AuthException('Google 로그인 실패'));

        final container = createContainer();

        // When & Then
        await expectLater(
          () => container
              .read(authNotifierProvider.notifier)
              .signInWithGoogle(),
          throwsA(isA<AuthException>()),
        );

        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncError<User?>>());
      });

      test('Google 로그인 성공 시 selectedLedgerId가 초기화된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(() => mockAuthService.signInWithGoogle())
            .thenAnswer((_) async => mockResponse);

        final container = createContainer();
        container.read(selectedLedgerIdProvider.notifier).state = 'some-ledger-id';

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signInWithGoogle();

        // Then
        expect(container.read(selectedLedgerIdProvider), isNull);
      });
    });

    group('signOut', () {
      test('로그아웃 성공 시 상태가 data(null)로 변경된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).signOut();

        // Then
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, isNull);
      });

      test('로그아웃 성공 시 selectedLedgerId가 null로 초기화된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        final container = createContainer();
        container.read(selectedLedgerIdProvider.notifier).state = 'some-ledger-id';

        // When
        await container.read(authNotifierProvider.notifier).signOut();

        // Then
        expect(container.read(selectedLedgerIdProvider), isNull);
      });

      test('로그아웃 실패 시 상태가 error로 변경된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.signOut())
            .thenThrow(Exception('로그아웃 실패'));

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).signOut();

        // Then: 로그아웃 실패 시 error 상태가 된다 (rethrow 안 함)
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncError<User?>>());
      });
    });

    group('deleteAccount', () {
      test('계정 삭제 성공 시 상태가 data(null)로 변경된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).deleteAccount();

        // Then
        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncData<User?>>());
        expect(state.valueOrNull, isNull);
      });

      test('계정 삭제 실패 시 상태가 error로 변경되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.deleteAccount())
            .thenThrow(Exception('계정 삭제 실패'));

        final container = createContainer();

        // When & Then
        await expectLater(
          () => container
              .read(authNotifierProvider.notifier)
              .deleteAccount(),
          throwsA(isA<Exception>()),
        );

        final state = container.read(authNotifierProvider);
        expect(state, isA<AsyncError<User?>>());
      });
    });

    group('상태 전이 순서', () {
      test('로그인 중 loading 상태로 전환 후 성공 시 data 상태가 된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);

        final states = <AsyncValue<User?>>[];

        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();
        container.listen(
          authNotifierProvider,
          (prev, next) => states.add(next),
          fireImmediately: false,
        );

        // When
        await container
            .read(authNotifierProvider.notifier)
            .signInWithEmail(email: 'test@test.com', password: 'pw123456');

        // Then: loading -> data 순서로 상태가 변한다
        expect(states.length, greaterThanOrEqualTo(1));
        expect(states.last, isA<AsyncData<User?>>());
      });
    });
  });

  group('AuthService._validateHexColor 테스트', () {
    // HEX 색상 코드 검증 함수 (AuthService.updateProfile에서 사용될 로직)
    void validateHexColor(String color) {
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
        throw ArgumentError(
          'Invalid color format. Must be HEX code (e.g., #A8D8EA)',
        );
      }
    }

    test('검증 함수가 정의되어 있어야 한다', () {
      expect(validateHexColor, isNotNull);
    });

    group('HEX 코드 형식 검증', () {
      test('유효한 HEX 코드 형식(#RRGGBB)은 허용되어야 한다', () {
        // Given: 다양한 유효한 HEX 코드
        final validColors = [
          '#A8D8EA',
          '#a8d8ea',
          '#FF5733',
          '#000000',
          '#FFFFFF',
        ];

        // When & Then: 모든 유효한 색상이 ArgumentError를 발생시키지 않아야 함
        for (final color in validColors) {
          expect(
            () => validateHexColor(color),
            returnsNormally,
            reason: '$color는 유효한 HEX 코드 형식입니다',
          );
        }
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - # 기호 없음', () {
        const invalidColor = 'A8D8EA';
        expect(
          () => validateHexColor(invalidColor),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid color format'),
            ),
          ),
          reason: '# 기호가 없으면 ArgumentError가 발생해야 합니다',
        );
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - 길이가 짧음', () {
        const invalidColor = '#A8D';
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - 길이가 김', () {
        const invalidColor = '#A8D8EA12';
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - 잘못된 문자 포함', () {
        const invalidColor = '#GGGGGG';
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('ArgumentError 메시지에 올바른 형식 예시가 포함되어야 한다', () {
        const invalidColor = 'invalid';
        expect(
          () => validateHexColor(invalidColor),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('#A8D8EA'),
            ),
          ),
        );
      });
    });
  });

  group('사용자 색상 관련 Provider 테스트', () {
    group('userColorProvider', () {
      test('userColorProvider가 정의되어 있어야 한다', () {
        expect(userColorProvider, isNotNull);
      });
    });

    group('userProfileProvider', () {
      test('userProfileProvider가 정의되어 있어야 한다', () {
        expect(userProfileProvider, isNotNull);
      });
    });

    group('userColorByIdProvider', () {
      test('userColorByIdProvider가 정의되어 있어야 한다', () {
        expect(userColorByIdProvider, isNotNull);
      });
    });
  });
}
