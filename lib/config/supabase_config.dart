import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';

  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static const String appScheme = 'sharedhousehold';

  static const String schema = 'house';

  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase URL과 Anon Key가 설정되지 않았습니다.\n'
        '.env 파일에 SUPABASE_URL과 SUPABASE_ANON_KEY를 설정하세요.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(authFlowType: AuthFlowType.pkce),
      postgrestOptions: PostgrestClientOptions(schema: schema),
      debug: kDebugMode,
    );

    await _saveConfigForWidget();
  }

  static Future<void> _saveConfigForWidget() async {
    final prefs = await SharedPreferences.getInstance();

    await _migrateOldKeys(prefs);

    await prefs.setString('supabase_url', supabaseUrl);
    await prefs.setString('supabase_anon_key', supabaseAnonKey);
  }

  static Future<void> _migrateOldKeys(SharedPreferences prefs) async {
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
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static SupabaseStorageClient get storage => client.storage;

  static RealtimeClient get realtime => client.realtime;
}
