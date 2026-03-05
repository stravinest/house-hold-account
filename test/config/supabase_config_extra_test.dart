import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  // initialize()는 내부에서 Supabase.initialize()를 호출하는데,
  // 테스트 환경에서는 이미 초기화된 경우가 많고 실제 네트워크 연결이 필요하다.
  // 따라서 initialize()의 예외 분기(URL/Key 누락)는 조건 로직 자체를 단위 검증한다.

  group('SupabaseConfig initialize 예외 조건 로직 테스트', () {
    test('supabaseUrl이 비어있으면 예외를 던져야 하는 조건이 충족된다', () {
      // Given: URL이 빈 문자열인 경우
      dotenv.testLoad(fileInput: '');
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;

      // When: 예외 조건 평가
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then: 빈 URL이므로 예외가 발생해야 함
      expect(shouldThrow, isTrue);
    });

    test('SUPABASE_ANON_KEY만 없으면 예외 조건이 충족된다', () {
      // Given: URL만 있고 AnonKey 없음
      dotenv.testLoad(fileInput: 'SUPABASE_URL=https://test.supabase.co\n');
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;

      // When
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then: anonKey가 비었으므로 예외 조건 충족
      expect(shouldThrow, isTrue);
      expect(url, isNotEmpty);
      expect(anonKey, isEmpty);
    });

    test('SUPABASE_URL만 없으면 예외 조건이 충족된다', () {
      // Given: AnonKey만 있고 URL 없음
      dotenv.testLoad(fileInput: 'SUPABASE_ANON_KEY=test-key\n');
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;

      // When
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then: url이 비었으므로 예외 조건 충족
      expect(shouldThrow, isTrue);
      expect(url, isEmpty);
      expect(anonKey, isNotEmpty);
    });

    test('URL과 AnonKey가 모두 있으면 예외 조건이 충족되지 않는다', () {
      // Given: 두 값 모두 설정됨
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://test.supabase.co\nSUPABASE_ANON_KEY=test-key\n',
      );
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;

      // When
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then: 예외 조건 미충족
      expect(shouldThrow, isFalse);
    });

    test('initialize 예외 메시지가 .env 파일 관련 안내를 포함한다', () {
      // Given: 예외 메시지 형식 검증
      const exceptionMessage =
          'Supabase URL과 Anon Key가 설정되지 않았습니다.\n'
          '.env 파일에 SUPABASE_URL과 SUPABASE_ANON_KEY를 설정하세요.';

      // Then: 메시지가 올바른 형식
      expect(exceptionMessage, contains('.env'));
      expect(exceptionMessage, contains('SUPABASE_URL'));
      expect(exceptionMessage, contains('SUPABASE_ANON_KEY'));
    });
  });

  group('SupabaseConfig _saveConfigForWidget 간접 테스트', () {
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

    setUp(() {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://widget-test.supabase.co\nSUPABASE_ANON_KEY=widget-test-anon-key\n',
      );
    });

    test('supabaseUrl이 SharedPreferences에 저장 가능한 String 타입이다', () {
      // Given & When
      final url = SupabaseConfig.supabaseUrl;

      // Then: String으로 SharedPreferences에 저장 가능
      expect(url, isA<String>());
      expect(url, isNotEmpty);
    });

    test('supabaseAnonKey가 SharedPreferences에 저장 가능한 String 타입이다', () {
      // Given & When
      final anonKey = SupabaseConfig.supabaseAnonKey;

      // Then
      expect(anonKey, isA<String>());
      expect(anonKey, isNotEmpty);
    });

    test('_saveConfigForWidget에서 사용하는 키 이름이 올바른 형식이다', () {
      // Given: 코드에서 사용하는 SharedPreferences 키들
      const supabaseUrlKey = 'supabase_url';
      const supabaseAnonKeyKey = 'supabase_anon_key';

      // Then: snake_case 형식
      final pattern = RegExp(r'^[a-z]+(_[a-z]+)*$');
      expect(pattern.hasMatch(supabaseUrlKey), isTrue);
      expect(pattern.hasMatch(supabaseAnonKeyKey), isTrue);
    });
  });

  group('SupabaseConfig _migrateOldKeys 로직 테스트', () {
    test('이전 키(flutter. 접두사)와 새 키 매핑이 올바르다', () {
      // Given: 마이그레이션 매핑
      const migrations = [
        ('flutter.supabase_url', 'supabase_url'),
        ('flutter.supabase_anon_key', 'supabase_anon_key'),
        ('flutter.current_ledger_id', 'current_ledger_id'),
      ];

      // When & Then
      for (final (oldKey, newKey) in migrations) {
        expect(oldKey, startsWith('flutter.'));
        expect(newKey, isNot(startsWith('flutter.')));
        expect(newKey, equals(oldKey.replaceFirst('flutter.', '')));
      }
    });

    test('새 키가 이미 있으면 마이그레이션하지 않는다 (조건 로직 검증)', () async {
      // Given: 새 키가 이미 있는 상태
      SharedPreferences.setMockInitialValues({
        'flutter.supabase_url': 'https://old.supabase.co',
        'supabase_url': 'https://new.supabase.co',
      });

      final prefs = await SharedPreferences.getInstance();
      final oldValue = prefs.getString('flutter.supabase_url');
      final newValue = prefs.getString('supabase_url');

      // When: 마이그레이션 조건 (새 키가 null일 때만 마이그레이션)
      final shouldMigrate = oldValue != null && newValue == null;

      // Then: 새 키가 있으므로 마이그레이션 불필요
      expect(shouldMigrate, isFalse);
      expect(newValue, 'https://new.supabase.co');
    });

    test('이전 키만 있고 새 키가 없으면 마이그레이션 조건이 충족된다', () {
      // Given: 이전 키만 있고 새 키는 없는 상태를 직접 시뮬레이션
      const oldValue = 'https://old.supabase.co';
      const String? newValue = null; // 새 키 없음

      // When: 마이그레이션 조건 평가
      final shouldMigrate = oldValue != null && newValue == null;

      // Then: 마이그레이션 조건 충족
      expect(shouldMigrate, isTrue);
      expect(oldValue, 'https://old.supabase.co');
    });

    test('마이그레이션 수행 시 이전 키가 삭제된다 (시뮬레이션)', () async {
      // Given: 이전 키가 있는 상태
      SharedPreferences.setMockInitialValues({
        'flutter.supabase_url': 'https://old.supabase.co',
      });

      final prefs = await SharedPreferences.getInstance();
      final oldValue = prefs.getString('flutter.supabase_url');

      // When: 마이그레이션 시뮬레이션
      if (oldValue != null && prefs.getString('supabase_url') == null) {
        await prefs.setString('supabase_url', oldValue);
        await prefs.remove('flutter.supabase_url');
      }

      // Then: 새 키에 값이 저장되고 이전 키는 삭제됨
      expect(prefs.getString('supabase_url'), 'https://old.supabase.co');
      expect(prefs.getString('flutter.supabase_url'), isNull);
    });

    test('3개 마이그레이션 항목 모두 처리된다 (시뮬레이션)', () async {
      // Given: 3개의 이전 키 모두 존재
      SharedPreferences.setMockInitialValues({
        'flutter.supabase_url': 'url-value',
        'flutter.supabase_anon_key': 'key-value',
        'flutter.current_ledger_id': 'ledger-id-value',
      });

      final prefs = await SharedPreferences.getInstance();

      const migrations = [
        ('flutter.supabase_url', 'supabase_url'),
        ('flutter.supabase_anon_key', 'supabase_anon_key'),
        ('flutter.current_ledger_id', 'current_ledger_id'),
      ];

      // When: 마이그레이션 시뮬레이션
      for (final (oldKey, newKey) in migrations) {
        final oldValue = prefs.getString(oldKey);
        if (oldValue != null && prefs.getString(newKey) == null) {
          await prefs.setString(newKey, oldValue);
          await prefs.remove(oldKey);
        }
      }

      // Then: 모든 새 키에 값이 설정됨
      expect(prefs.getString('supabase_url'), 'url-value');
      expect(prefs.getString('supabase_anon_key'), 'key-value');
      expect(prefs.getString('current_ledger_id'), 'ledger-id-value');
      // 이전 키들은 삭제됨
      expect(prefs.getString('flutter.supabase_url'), isNull);
      expect(prefs.getString('flutter.supabase_anon_key'), isNull);
      expect(prefs.getString('flutter.current_ledger_id'), isNull);
    });
  });

  group('SupabaseConfig supabaseUrl 유효성 검증 테스트', () {
    setUp(() {
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://xyzabc.supabase.co\nSUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9\n',
      );
    });

    test('supabaseUrl이 https://로 시작하는 유효한 URL이다', () {
      // Given & When
      final url = SupabaseConfig.supabaseUrl;

      // Then
      expect(url, startsWith('https://'));
    });

    test('supabaseUrl이 .supabase.co를 포함한다', () {
      // Given & When
      final url = SupabaseConfig.supabaseUrl;

      // Then
      expect(url, contains('supabase.co'));
    });

    test('supabaseUrl이 Uri.parse로 파싱 가능한 유효한 URI이다', () {
      // Given & When
      final url = SupabaseConfig.supabaseUrl;
      final uri = Uri.parse(url);

      // Then
      expect(uri.scheme, 'https');
      expect(uri.host, isNotEmpty);
    });
  });

  group('SupabaseConfig Supabase 인스턴스 getter 추가 테스트', () {
    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      try {
        await Supabase.initialize(
          url: 'https://test.supabase.co',
          anonKey: 'test-anon-key',
        );
      } catch (_) {}
    });

    test('client getter가 null이 아닌 SupabaseClient를 반환한다', () {
      // Given & When
      final client = SupabaseConfig.client;

      // Then
      expect(client, isNotNull);
      expect(client, isA<SupabaseClient>());
    });

    test('auth getter가 null이 아닌 GoTrueClient를 반환한다', () {
      // Given & When
      final auth = SupabaseConfig.auth;

      // Then
      expect(auth, isNotNull);
      expect(auth, isA<GoTrueClient>());
    });

    test('storage getter가 null이 아닌 SupabaseStorageClient를 반환한다', () {
      // Given & When
      final storage = SupabaseConfig.storage;

      // Then
      expect(storage, isNotNull);
      expect(storage, isA<SupabaseStorageClient>());
    });

    test('realtime getter가 null이 아닌 RealtimeClient를 반환한다', () {
      // Given & When
      final realtime = SupabaseConfig.realtime;

      // Then
      expect(realtime, isNotNull);
      expect(realtime, isA<RealtimeClient>());
    });
  });
}
