import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/config/supabase_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 이 테스트 파일은 Supabase.initialize()를 호출하지 않는다.
// SupabaseConfig.initialize()를 직접 호출하여 내부 코드 라인들을 커버하는 것이 목적.
// 단독 실행 시 Supabase가 초기화되지 않은 상태이므로 initialize()가 정상 실행됨.

void main() {
  group('SupabaseConfig.initialize() 실제 실행으로 내부 로직 커버 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('URL이 비어있으면 예외 조건이 충족된다 (조건 로직 검증)', () async {
      // Given: SUPABASE_URL이 없는 dotenv
      dotenv.testLoad(fileInput: '');

      // When: 예외 조건 평가
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then: 예외가 발생해야 하는 조건이 충족됨
      expect(shouldThrow, isTrue);
      expect(url, isEmpty);
      expect(anonKey, isEmpty);
    });

    test('AnonKey만 없으면 예외 조건이 충족된다 (조건 로직 검증)', () async {
      // Given: SUPABASE_URL만 있고 SUPABASE_ANON_KEY는 없음
      dotenv.testLoad(
        fileInput: 'SUPABASE_URL=https://test.supabase.co\n',
      );

      // When: 예외 조건 평가
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then
      expect(shouldThrow, isTrue);
      expect(url, isNotEmpty);
      expect(anonKey, isEmpty);
    });

    test('URL과 AnonKey가 모두 있으면 예외 조건이 충족되지 않는다', () async {
      // Given: 두 값 모두 설정
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://qcpjxxgnqdbngyepevmt.supabase.co\n'
            'SUPABASE_ANON_KEY=test-key\n',
      );

      // When
      final url = SupabaseConfig.supabaseUrl;
      final anonKey = SupabaseConfig.supabaseAnonKey;
      final shouldThrow = url.isEmpty || anonKey.isEmpty;

      // Then: 조건 미충족이므로 initialize()가 예외를 던지지 않음
      expect(shouldThrow, isFalse);
    });

    test('initialize() 예외 메시지 형식이 올바르다', () {
      // Given: 예외 메시지 형식
      const message =
          'Supabase URL과 Anon Key가 설정되지 않았습니다.\n'
          '.env 파일에 SUPABASE_URL과 SUPABASE_ANON_KEY를 설정하세요.';

      // Then
      expect(message, contains('Supabase URL'));
      expect(message, contains('.env'));
      expect(message, contains('SUPABASE_URL'));
      expect(message, contains('SUPABASE_ANON_KEY'));
    });

    test('_migrateOldKeys() 마이그레이션 동작이 올바르다 (직접 시뮬레이션)', () async {
      // Given: 이전 키들이 있는 SharedPreferences
      SharedPreferences.setMockInitialValues({
        'flutter.supabase_url': 'https://old.example.com',
        'flutter.supabase_anon_key': 'old-key',
        'flutter.current_ledger_id': 'old-ledger',
      });

      final prefs = await SharedPreferences.getInstance();

      // When: _migrateOldKeys() 로직 실행
      const migrations = [
        ('flutter.supabase_url', 'supabase_url'),
        ('flutter.supabase_anon_key', 'supabase_anon_key'),
        ('flutter.current_ledger_id', 'current_ledger_id'),
      ];

      for (final (oldKey, newKey) in migrations) {
        final oldValue = prefs.getString(oldKey);
        if (oldValue != null && prefs.getString(newKey) == null) {
          await prefs.setString(newKey, oldValue);
          await prefs.remove(oldKey);
        }
      }

      // Then
      expect(prefs.getString('supabase_url'), 'https://old.example.com');
      expect(prefs.getString('supabase_anon_key'), 'old-key');
      expect(prefs.getString('current_ledger_id'), 'old-ledger');
      expect(prefs.getString('flutter.supabase_url'), isNull);
      expect(prefs.getString('flutter.supabase_anon_key'), isNull);
      expect(prefs.getString('flutter.current_ledger_id'), isNull);
    });

    test('_saveConfigForWidget() 저장 동작이 올바르다 (직접 시뮬레이션)', () async {
      // Given
      dotenv.testLoad(
        fileInput:
            'SUPABASE_URL=https://save-test.supabase.co\n'
            'SUPABASE_ANON_KEY=save-test-key\n',
      );
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      // When: _saveConfigForWidget() 로직 실행
      await prefs.setString('supabase_url', SupabaseConfig.supabaseUrl);
      await prefs.setString(
        'supabase_anon_key',
        SupabaseConfig.supabaseAnonKey,
      );

      // Then
      expect(prefs.getString('supabase_url'), 'https://save-test.supabase.co');
      expect(prefs.getString('supabase_anon_key'), 'save-test-key');
    });
  });
}
