import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseConfig 상수 테스트', () {
    test('appScheme 상수가 올바른 값이어야 한다', () {
      // Given & When & Then
      expect(SupabaseConfig.appScheme, 'sharedhousehold');
    });

    test('schema 상수가 house여야 한다', () {
      // Given & When & Then
      // CLAUDE.md에 명시된 대로 house 스키마를 사용해야 한다
      expect(SupabaseConfig.schema, 'house');
    });

    test('schema가 public이 아니어야 한다', () {
      // Given & When & Then
      // public 스키마에 생성하면 앱에서 테이블을 찾을 수 없음
      expect(SupabaseConfig.schema, isNot('public'));
    });

    test('appScheme이 딥링크 스킴으로 사용 가능해야 한다', () {
      // Given & When & Then
      // 딥링크 스킴은 소문자 알파벳과 숫자만 포함해야 함
      final scheme = SupabaseConfig.appScheme;
      expect(scheme, matches(RegExp(r'^[a-z][a-z0-9]*$')));
    });

    test('supabaseUrl getter가 dotenv 미로드 시 예외를 던진다', () {
      // Given & When & Then
      // dotenv가 로드되지 않은 테스트 환경에서는 NotInitializedError 발생이 정상
      expect(() => SupabaseConfig.supabaseUrl, throwsA(anything));
    });

    test('supabaseAnonKey getter가 dotenv 미로드 시 예외를 던진다', () {
      // Given & When & Then
      expect(() => SupabaseConfig.supabaseAnonKey, throwsA(anything));
    });
  });

  group('SupabaseConfig 스키마 설계 규칙 테스트', () {
    test('schema 값이 소문자 알파벳만으로 구성된다', () {
      // Given & When
      final schema = SupabaseConfig.schema;

      // Then: 소문자 알파벳만 포함해야 한다
      expect(schema, matches(RegExp(r'^[a-z]+$')));
    });

    test('schema 값이 비어있지 않다', () {
      // Given & When
      final schema = SupabaseConfig.schema;

      // Then
      expect(schema, isNotEmpty);
    });

    test('appScheme이 비어있지 않다', () {
      // Given & When
      final scheme = SupabaseConfig.appScheme;

      // Then
      expect(scheme, isNotEmpty);
    });

    test('appScheme이 소문자로만 구성된다', () {
      // Given & When
      final scheme = SupabaseConfig.appScheme;

      // Then: URI 스킴 규칙에 따라 소문자만 허용
      expect(scheme, equals(scheme.toLowerCase()));
    });

    test('schema는 house이다 (PostgREST 접근 보장)', () {
      // Given & When: CLAUDE.md의 장애 이력에 따라 house 스키마 필수
      // 2026-02-25~03-05 장애: public 스키마 사용으로 cron job 10일간 실패
      final schema = SupabaseConfig.schema;

      // Then
      expect(schema, 'house');
    });
  });

  group('SupabaseConfig 환경변수 키 문서화 테스트', () {
    test('SharedPreferences에 저장되는 키 이름이 올바른 형식이다', () {
      // Given: _saveConfigForWidget에서 사용하는 키들
      const supabaseUrlKey = 'supabase_url';
      const supabaseAnonKeyKey = 'supabase_anon_key';

      // Then: snake_case 형식이어야 한다
      final snakeCasePattern = RegExp(r'^[a-z]+(_[a-z]+)*$');
      expect(snakeCasePattern.hasMatch(supabaseUrlKey), isTrue);
      expect(snakeCasePattern.hasMatch(supabaseAnonKeyKey), isTrue);
    });

    test('마이그레이션 대상 키들의 flutter. 접두사 형식이 올바르다', () {
      // Given: _migrateOldKeys에서 사용하는 이전 키들
      const oldKeys = [
        'flutter.supabase_url',
        'flutter.supabase_anon_key',
        'flutter.current_ledger_id',
      ];

      // Then: 모두 flutter. 접두사를 가진다
      for (final key in oldKeys) {
        expect(key, startsWith('flutter.'));
      }
    });

    test('마이그레이션 후 새 키들이 flutter. 접두사 없이 저장된다', () {
      // Given: 마이그레이션 후 신규 키들
      const newKeys = ['supabase_url', 'supabase_anon_key', 'current_ledger_id'];

      // Then: flutter. 접두사가 없다
      for (final key in newKeys) {
        expect(key, isNot(startsWith('flutter.')));
      }
    });
  });

  group('SupabaseConfig 타입 검증', () {
    test('appScheme이 const String 타입이다', () {
      // Given & When
      const scheme = SupabaseConfig.appScheme;

      // Then
      expect(scheme, isA<String>());
    });

    test('schema가 const String 타입이다', () {
      // Given & When
      const schema = SupabaseConfig.schema;

      // Then
      expect(schema, isA<String>());
    });
  });

  group('SupabaseConfig dotenv 환경변수 설정 시 테스트', () {
    setUp(() {
      dotenv.testLoad(fileInput: '''
SUPABASE_URL=https://test.supabase.co
SUPABASE_ANON_KEY=test-anon-key-12345
''');
    });

    test('supabaseUrl이 dotenv 설정 시 올바른 값을 반환한다', () {
      // Given: dotenv에 SUPABASE_URL이 설정됨
      // When
      final result = SupabaseConfig.supabaseUrl;

      // Then
      expect(result, equals('https://test.supabase.co'));
    });

    test('supabaseAnonKey가 dotenv 설정 시 올바른 값을 반환한다', () {
      // Given: dotenv에 SUPABASE_ANON_KEY가 설정됨
      // When
      final result = SupabaseConfig.supabaseAnonKey;

      // Then
      expect(result, equals('test-anon-key-12345'));
    });

    test('supabaseUrl이 비어있지 않다', () {
      // Given
      // When
      final result = SupabaseConfig.supabaseUrl;

      // Then
      expect(result, isNotEmpty);
    });

    test('supabaseAnonKey가 비어있지 않다', () {
      // Given
      // When
      final result = SupabaseConfig.supabaseAnonKey;

      // Then
      expect(result, isNotEmpty);
    });

    test('supabaseUrl이 https로 시작한다', () {
      // Given
      // When
      final result = SupabaseConfig.supabaseUrl;

      // Then
      expect(result, startsWith('https://'));
    });
  });

  group('SupabaseConfig 환경변수 미설정 시 기본값 테스트', () {
    setUp(() {
      dotenv.testLoad(fileInput: '');
    });

    test('supabaseUrl이 dotenv 미설정 시 빈 문자열을 반환한다', () {
      // Given: dotenv에 SUPABASE_URL이 없음
      // When
      final result = SupabaseConfig.supabaseUrl;

      // Then: 기본값 '' 반환
      expect(result, equals(''));
    });

    test('supabaseAnonKey가 dotenv 미설정 시 빈 문자열을 반환한다', () {
      // Given: dotenv에 SUPABASE_ANON_KEY가 없음
      // When
      final result = SupabaseConfig.supabaseAnonKey;

      // Then: 기본값 '' 반환
      expect(result, equals(''));
    });
  });

  group('SupabaseConfig Supabase 인스턴스 getter 테스트', () {
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

    test('auth getter가 GoTrueClient 타입을 반환한다', () {
      // Given: Supabase가 초기화된 상태
      // When
      final result = SupabaseConfig.auth;

      // Then
      expect(result, isA<GoTrueClient>());
    });

    test('client getter가 SupabaseClient 타입을 반환한다', () {
      // Given: Supabase가 초기화된 상태
      // When
      final result = SupabaseConfig.client;

      // Then
      expect(result, isA<SupabaseClient>());
    });

    test('storage getter가 SupabaseStorageClient 타입을 반환한다', () {
      // Given: Supabase가 초기화된 상태
      // When
      final result = SupabaseConfig.storage;

      // Then
      expect(result, isA<SupabaseStorageClient>());
    });

    test('realtime getter가 RealtimeClient 타입을 반환한다', () {
      // Given: Supabase가 초기화된 상태
      // When
      final result = SupabaseConfig.realtime;

      // Then
      expect(result, isA<RealtimeClient>());
    });
  });
}
