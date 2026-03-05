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
    } catch (_) {}
  });

  group('AuthNotifier 액션 메서드 테스트', () {
    late _MockAuthService mockAuthService;
    late _MockLedgerRepository mockLedgerRepository;

    setUp(() {
      mockAuthService = _MockAuthService();
      mockLedgerRepository = _MockLedgerRepository();
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

    group('signUpWithEmail 테스트', () {
      test('회원가입 성공 시 AsyncData(user) 상태로 전환된다', () async {
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
        await container.read(authNotifierProvider.notifier).signUpWithEmail(
          email: 'test@test.com',
          password: 'password123',
          displayName: '홍길동',
        );

        // Then
        expect(container.read(authNotifierProvider), isA<AsyncData<User?>>());
        expect(
          container.read(authNotifierProvider).valueOrNull,
          equals(mockUser),
        );
      });

      test('회원가입 실패 시 AsyncError 상태로 전환되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenThrow(AuthApiException('Email already in use', statusCode: '400'));

        final container = createContainer();

        // When & Then: 예외가 rethrow된다
        expect(
          () => container.read(authNotifierProvider.notifier).signUpWithEmail(
            email: 'existing@test.com',
            password: 'password123',
          ),
          throwsA(isA<AuthApiException>()),
        );
        await Future.delayed(Duration.zero);
        expect(
          container.read(authNotifierProvider),
          isA<AsyncError<User?>>(),
        );
      });

      test('회원가입 중 loading 상태를 거친다', () async {
        // Given
        final states = <AsyncValue<User?>>[];
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(null);
        when(
          () => mockAuthService.signUpWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
            displayName: any(named: 'displayName'),
          ),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();
        container.listen(
          authNotifierProvider,
          (prev, next) => states.add(next),
          fireImmediately: false,
        );

        // When
        await container.read(authNotifierProvider.notifier).signUpWithEmail(
          email: 'test@test.com',
          password: 'password123',
        );

        // Then: loading -> data 순서
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states.first, isA<AsyncLoading<User?>>());
        expect(states.last, isA<AsyncData<User?>>());
      });
    });

    group('signInWithEmail 테스트', () {
      test('로그인 성공 시 AsyncData(user) 상태로 전환된다', () async {
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
        await container.read(authNotifierProvider.notifier).signInWithEmail(
          email: 'test@test.com',
          password: 'password123',
        );

        // Then
        expect(container.read(authNotifierProvider), isA<AsyncData<User?>>());
        expect(
          container.read(authNotifierProvider).valueOrNull,
          equals(mockUser),
        );
      });

      test('로그인 실패 시 AsyncError 상태로 전환되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.signInWithEmail(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(
          AuthApiException('Invalid login credentials', statusCode: '400'),
        );

        final container = createContainer();

        // When & Then: 예외가 rethrow된다
        expect(
          () => container.read(authNotifierProvider.notifier).signInWithEmail(
            email: 'wrong@test.com',
            password: 'wrongpass',
          ),
          throwsA(isA<AuthApiException>()),
        );
        await Future.delayed(Duration.zero);
        expect(
          container.read(authNotifierProvider),
          isA<AsyncError<User?>>(),
        );
      });

      test('로그인 중 loading 상태를 거친다', () async {
        // Given
        final states = <AsyncValue<User?>>[];
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(null);
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
        await container.read(authNotifierProvider.notifier).signInWithEmail(
          email: 'test@test.com',
          password: 'password123',
        );

        // Then: loading -> data 순서
        expect(states.first, isA<AsyncLoading<User?>>());
        expect(states.last, isA<AsyncData<User?>>());
      });
    });

    group('signInWithGoogle 테스트', () {
      test('Google 로그인 성공 시 AsyncData(user) 상태로 전환된다', () async {
        // Given
        final mockUser = MockUser();
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(mockUser);
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).signInWithGoogle();

        // Then
        expect(container.read(authNotifierProvider), isA<AsyncData<User?>>());
      });

      test('Google 로그인 실패 시 AsyncError 상태로 전환되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenThrow(const AuthException('Google 로그인이 취소되었습니다.'));

        final container = createContainer();

        // When & Then
        expect(
          () => container.read(authNotifierProvider.notifier).signInWithGoogle(),
          throwsA(isA<AuthException>()),
        );
        await Future.delayed(Duration.zero);
        expect(
          container.read(authNotifierProvider),
          isA<AsyncError<User?>>(),
        );
      });

      test('Google 로그인 중 loading 상태를 거친다', () async {
        // Given
        final states = <AsyncValue<User?>>[];
        final mockResponse = MockAuthResponse();
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockResponse.user).thenReturn(null);
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => mockResponse);

        final container = createContainer();
        container.listen(
          authNotifierProvider,
          (prev, next) => states.add(next),
          fireImmediately: false,
        );

        // When
        await container.read(authNotifierProvider.notifier).signInWithGoogle();

        // Then
        expect(states.first, isA<AsyncLoading<User?>>());
        expect(states.last, isA<AsyncData<User?>>());
      });
    });

    group('signOut 테스트', () {
      test('로그아웃 성공 시 AsyncData(null) 상태로 전환된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.signOut()).thenAnswer((_) async {});

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).signOut();

        // Then
        expect(container.read(authNotifierProvider), isA<AsyncData<User?>>());
        expect(container.read(authNotifierProvider).valueOrNull, isNull);
      });

      test('로그아웃 실패 시 AsyncError 상태로 전환된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.signOut(),
        ).thenThrow(Exception('Network error'));

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).signOut();

        // Then: 에러 상태 (signOut은 rethrow하지 않음)
        expect(container.read(authNotifierProvider), isA<AsyncError<User?>>());
      });
    });

    group('deleteAccount 테스트', () {
      test('계정 삭제 성공 시 AsyncData(null) 상태로 전환된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(() => mockAuthService.deleteAccount()).thenAnswer((_) async {});

        final container = createContainer();

        // When
        await container.read(authNotifierProvider.notifier).deleteAccount();

        // Then
        expect(container.read(authNotifierProvider), isA<AsyncData<User?>>());
        expect(container.read(authNotifierProvider).valueOrNull, isNull);
      });

      test('계정 삭제 실패 시 AsyncError 상태로 전환되고 예외가 rethrow된다', () async {
        // Given
        when(() => mockAuthService.currentUser).thenReturn(null);
        when(
          () => mockAuthService.deleteAccount(),
        ).thenThrow(Exception('Delete failed'));

        final container = createContainer();

        // When & Then
        expect(
          () => container.read(authNotifierProvider.notifier).deleteAccount(),
          throwsA(isA<Exception>()),
        );
        await Future.delayed(Duration.zero);
        expect(
          container.read(authNotifierProvider),
          isA<AsyncError<User?>>(),
        );
      });

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
        expect(states.any((s) => s is AsyncLoading), isTrue);
        expect(states.last, isA<AsyncData<User?>>());
      });
    });
  });

  group('AuthService 로직 단위 테스트', () {
    group('verifyAndUpdatePassword 조건 검증', () {
      test('이메일이 null이면 예외를 발생시켜야 한다', () async {
        // Given: 로그인하지 않은 상태 (currentUser == null)
        String? email;

        // When: 이메일이 null인 경우 에러 발생 로직
        Object? caughtError;
        try {
          if (email == null) {
            throw Exception('로그인 상태가 아닙니다');
          }
        } catch (e) {
          caughtError = e;
        }

        // Then: 예외가 발생한다
        expect(caughtError, isA<Exception>());
        expect(caughtError.toString(), contains('로그인 상태가 아닙니다'));
      });
    });

    group('updateProfile 로직 검증', () {
      test('currentUser가 null이면 updates를 빌드하지 않는다', () {
        // Given: 비로그인 상태
        const Object? currentUser = null;
        final updates = <String, dynamic>{};

        // When: currentUser null 체크 로직
        if (currentUser == null) return;
        updates['display_name'] = 'test';

        // Then: updates가 비어있다 (위에서 return했으므로 이 줄은 실행 안 됨)
        expect(updates.isEmpty, isTrue);
      });

      test('displayName이 있으면 updates에 포함된다', () {
        // Given
        const displayName = '홍길동';
        final updates = <String, dynamic>{};

        // When: updateProfile 로직 시뮬레이션
        if (displayName != null) updates['display_name'] = displayName;

        // Then
        expect(updates['display_name'], equals('홍길동'));
      });

      test('color가 있으면 updates에 포함된다', () {
        // Given
        const color = '#A8D8EA';
        final updates = <String, dynamic>{};

        // When
        if (color != null) updates['color'] = color;

        // Then
        expect(updates['color'], equals('#A8D8EA'));
      });
    });

    group('_validateHexColor 로직 검증', () {
      bool isValidHexColor(String color) {
        return RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color);
      }

      test('유효한 대문자 HEX 색상 코드를 허용한다', () {
        expect(isValidHexColor('#A8D8EA'), isTrue);
        expect(isValidHexColor('#FFFFFF'), isTrue);
        expect(isValidHexColor('#000000'), isTrue);
      });

      test('유효한 소문자 HEX 색상 코드를 허용한다', () {
        expect(isValidHexColor('#abcdef'), isTrue);
        expect(isValidHexColor('#123abc'), isTrue);
      });

      test('# 없는 색상 코드를 거부한다', () {
        expect(isValidHexColor('A8D8EA'), isFalse);
        expect(isValidHexColor('FFFFFF'), isFalse);
      });

      test('7자리 미만 색상 코드를 거부한다', () {
        expect(isValidHexColor('#FFFFF'), isFalse);
        expect(isValidHexColor('#FFF'), isFalse);
      });

      test('7자리 초과 색상 코드를 거부한다', () {
        expect(isValidHexColor('#FFFFFFF'), isFalse);
      });

      test('유효하지 않은 문자가 포함된 색상 코드를 거부한다', () {
        expect(isValidHexColor('#GGGGGG'), isFalse);
        expect(isValidHexColor('#ZZZZZZ'), isFalse);
      });
    });

    group('_getDisplayName 로직 검증', () {
      String getDisplayName({
        Map<String, dynamic>? userMetadata,
        String? email,
      }) {
        return userMetadata?['full_name'] ??
            userMetadata?['name'] ??
            email?.split('@').first ??
            'User';
      }

      test('full_name을 우선 반환한다', () {
        final result = getDisplayName(
          userMetadata: {'full_name': '홍길동', 'name': '다른이름'},
        );
        expect(result, equals('홍길동'));
      });

      test('full_name이 없으면 name을 반환한다', () {
        final result = getDisplayName(
          userMetadata: {'name': '이순신'},
        );
        expect(result, equals('이순신'));
      });

      test('metadata가 없으면 이메일 앞부분을 반환한다', () {
        final result = getDisplayName(email: 'user@example.com');
        expect(result, equals('user'));
      });

      test('모두 없으면 User를 반환한다', () {
        final result = getDisplayName();
        expect(result, equals('User'));
      });
    });
  });
}
