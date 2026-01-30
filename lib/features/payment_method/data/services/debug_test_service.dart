import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class DebugTestResult {
  final int? sqliteId;
  final bool supabaseSuccess;
  final int pendingCount;

  DebugTestResult({
    this.sqliteId,
    required this.supabaseSuccess,
    required this.pendingCount,
  });

  factory DebugTestResult.fromMap(Map<dynamic, dynamic> map) {
    return DebugTestResult(
      sqliteId: map['sqliteId'] as int?,
      supabaseSuccess: map['supabaseSuccess'] as bool? ?? false,
      pendingCount: map['pendingCount'] as int? ?? 0,
    );
  }
}

class DebugStatus {
  final int sqlitePendingCount;
  final int sqliteFailedCount;
  final bool supabaseInitialized;
  final bool supabaseHasToken;
  final String? ledgerId;
  final bool notificationListenerActive;

  DebugStatus({
    required this.sqlitePendingCount,
    required this.sqliteFailedCount,
    required this.supabaseInitialized,
    required this.supabaseHasToken,
    this.ledgerId,
    required this.notificationListenerActive,
  });

  factory DebugStatus.fromMap(Map<dynamic, dynamic> map) {
    final sqlite = map['sqlite'] as Map<dynamic, dynamic>? ?? {};
    final supabase = map['supabase'] as Map<dynamic, dynamic>? ?? {};
    final notificationListener =
        map['notificationListener'] as Map<dynamic, dynamic>? ?? {};

    return DebugStatus(
      sqlitePendingCount: sqlite['pendingCount'] as int? ?? 0,
      sqliteFailedCount: sqlite['failedCount'] as int? ?? 0,
      supabaseInitialized: supabase['initialized'] as bool? ?? false,
      supabaseHasToken: supabase['hasToken'] as bool? ?? false,
      ledgerId: supabase['ledgerId'] as String?,
      notificationListenerActive:
          notificationListener['instance'] as bool? ?? false,
    );
  }
}

class SupabaseStatus {
  final bool initialized;
  final bool tokenValid;
  final String? ledgerId;
  final bool hasRefreshToken;

  SupabaseStatus({
    required this.initialized,
    required this.tokenValid,
    this.ledgerId,
    required this.hasRefreshToken,
  });

  factory SupabaseStatus.fromMap(Map<dynamic, dynamic> map) {
    return SupabaseStatus(
      initialized: map['initialized'] as bool? ?? false,
      tokenValid: map['tokenValid'] as bool? ?? false,
      ledgerId: map['ledgerId'] as String?,
      hasRefreshToken: map['hasRefreshToken'] as bool? ?? false,
    );
  }
}

class ParsedResult {
  final bool isParsed;
  final int? amount;
  final String? transactionType;
  final String? merchant;
  final int? dateTimeMillis;
  final String? cardLastDigits;
  final double confidence;
  final String? matchedPattern;

  ParsedResult({
    required this.isParsed,
    this.amount,
    this.transactionType,
    this.merchant,
    this.dateTimeMillis,
    this.cardLastDigits,
    required this.confidence,
    this.matchedPattern,
  });

  factory ParsedResult.fromMap(Map<dynamic, dynamic> map) {
    return ParsedResult(
      isParsed: map['isParsed'] as bool? ?? false,
      amount: map['amount'] as int?,
      transactionType: map['transactionType'] as String?,
      merchant: map['merchant'] as String?,
      dateTimeMillis: map['dateTimeMillis'] as int?,
      cardLastDigits: map['cardLastDigits'] as String?,
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      matchedPattern: map['matchedPattern'] as String?,
    );
  }
}

class SmsTemplate {
  final String name;
  final String sender;
  final String Function(int amount, String merchant) bodyBuilder;

  const SmsTemplate({
    required this.name,
    required this.sender,
    required this.bodyBuilder,
  });
}

class PushTemplate {
  final String name;
  final String packageName;
  final String title;
  final String Function(int amount, String merchant) textBuilder;

  const PushTemplate({
    required this.name,
    required this.packageName,
    required this.title,
    required this.textBuilder,
  });
}

class DebugTestService {
  static const _channel = MethodChannel('com.household.shared/debug_test');

  static final List<SmsTemplate> smsTemplates = [
    SmsTemplate(
      name: 'KB국민카드',
      sender: '15881688',
      bodyBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        final now = DateTime.now();
        final date =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return '[Web발신]\nKB국민카드 1234승인\n홍*동\n$formatted원 일시불\n$date\n$merchant';
      },
    ),
    SmsTemplate(
      name: '신한카드',
      sender: '15447200',
      bodyBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        final now = DateTime.now();
        final date =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return '[Web발신]\n신한카드5678승인\n홍*동님\n$formatted원\n$date\n$merchant';
      },
    ),
    SmsTemplate(
      name: '현대카드',
      sender: '15776200',
      bodyBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        final now = DateTime.now();
        final date =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return '[Web발신]\n현대카드 9012\n$formatted원 승인\n$date\n$merchant\n홍*동';
      },
    ),
    SmsTemplate(
      name: '카카오페이',
      sender: '15999508',
      bodyBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        final now = DateTime.now();
        final date =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return '[카카오페이]\n$formatted원 결제완료\n$date\n$merchant\n홍*동님';
      },
    ),
    SmsTemplate(
      name: '입금 알림',
      sender: '15881688',
      bodyBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        final now = DateTime.now();
        final date =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return '[Web발신]\n[KB국민] 입금\n$formatted원\n$date\n홍*동\n잔액 5,678,901원';
      },
    ),
  ];

  static final List<PushTemplate> pushTemplates = [
    PushTemplate(
      name: 'KB Pay',
      packageName: 'com.kbcard.cxh.appcard',
      title: 'KB Pay',
      textBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        final now = DateTime.now();
        final date =
            '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        return 'KB국민카드1234승인\n홍*동님\n$formatted원 일시불\n$date\n$merchant\n누적500,000원';
      },
    ),
    PushTemplate(
      name: '경기지역화폐',
      packageName: 'gov.gyeonggi.ggcard',
      title: '경기지역화폐',
      textBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        return '결제 완료 $formatted원\n$merchant\n수원페이 충전형 인센티브 441원\n수원페이(수원이) 총 보유 잔액 50,000원';
      },
    ),
    PushTemplate(
      name: '카카오페이',
      packageName: 'com.kakaopay.app',
      title: '카카오페이',
      textBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        return '$formatted원 결제\n$merchant';
      },
    ),
    PushTemplate(
      name: '토스',
      packageName: 'viva.republica.toss',
      title: '토스',
      textBuilder: (amount, merchant) {
        final formatted = _formatAmount(amount);
        return '홍*동님께 $formatted원 입금\n잔액 1,234,567원';
      },
    ),
  ];

  static String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  static bool get isAvailable => kDebugMode;

  static Future<DebugTestResult> simulateSms({
    required String sender,
    required String body,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Debug test is only available in debug mode');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'simulateSms',
        {'sender': sender, 'body': body},
      );
      return DebugTestResult.fromMap(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('simulateSms failed: ${e.message}');
      rethrow;
    }
  }

  static Future<DebugTestResult> simulatePush({
    required String packageName,
    required String title,
    required String text,
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Debug test is only available in debug mode');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'simulatePush',
        {'packageName': packageName, 'title': title, 'text': text},
      );
      return DebugTestResult.fromMap(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('simulatePush failed: ${e.message}');
      rethrow;
    }
  }

  static Future<DebugStatus> getDebugStatus() async {
    if (!isAvailable) {
      throw UnsupportedError('Debug test is only available in debug mode');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDebugStatus',
      );
      return DebugStatus.fromMap(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('getDebugStatus failed: ${e.message}');
      rethrow;
    }
  }

  static Future<int> clearAllTestData() async {
    if (!isAvailable) {
      throw UnsupportedError('Debug test is only available in debug mode');
    }

    try {
      final result = await _channel.invokeMethod<int>('clearAllTestData');
      return result ?? 0;
    } on PlatformException catch (e) {
      debugPrint('clearAllTestData failed: ${e.message}');
      rethrow;
    }
  }

  static Future<SupabaseStatus> getSupabaseStatus() async {
    if (!isAvailable) {
      throw UnsupportedError('Debug test is only available in debug mode');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getSupabaseStatus',
      );
      return SupabaseStatus.fromMap(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('getSupabaseStatus failed: ${e.message}');
      rethrow;
    }
  }

  static Future<ParsedResult> testParsing({
    required String content,
    String sourceType = 'sms',
  }) async {
    if (!isAvailable) {
      throw UnsupportedError('Debug test is only available in debug mode');
    }

    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'testParsing',
        {'content': content, 'sourceType': sourceType},
      );
      return ParsedResult.fromMap(result ?? {});
    } on PlatformException catch (e) {
      debugPrint('testParsing failed: ${e.message}');
      rethrow;
    }
  }

  static Future<DebugTestResult> simulateSmsWithTemplate(
    SmsTemplate template, {
    int? amount,
    String? merchant,
  }) async {
    final actualAmount = amount ?? (10000 + DateTime.now().millisecond * 100);
    final actualMerchant = merchant ?? '스타벅스';
    final body = template.bodyBuilder(actualAmount, actualMerchant);

    return simulateSms(sender: template.sender, body: body);
  }

  static Future<DebugTestResult> simulatePushWithTemplate(
    PushTemplate template, {
    int? amount,
    String? merchant,
  }) async {
    final actualAmount = amount ?? (10000 + DateTime.now().millisecond * 100);
    final actualMerchant = merchant ?? '스타벅스';
    final text = template.textBuilder(actualAmount, actualMerchant);

    return simulatePush(
      packageName: template.packageName,
      title: template.title,
      text: text,
    );
  }
}
