import 'dart:io';

import 'package:another_telephony/telephony.dart';
import 'package:flutter/foundation.dart';

import 'sms_parsing_service.dart';

@pragma('vm:entry-point')
void onBackgroundSmsReceived(SmsMessage message) async {
  debugPrint('Background SMS received from: ${message.address}');

  final sender = message.address ?? '';
  final content = message.body ?? '';

  if (sender.isEmpty || content.isEmpty) return;

  if (!FinancialSmsSenders.isFinancialSender(sender)) {
    debugPrint('Not a financial SMS, ignoring');
    return;
  }

  final parsedResult = SmsParsingService.parseSms(sender, content);

  if (parsedResult.isParsed) {
    debugPrint(
      'Parsed background SMS: ${parsedResult.amount}원 at ${parsedResult.merchant}',
    );
  }
}

class BackgroundSmsHandler {
  BackgroundSmsHandler._();

  static BackgroundSmsHandler? _instance;
  static BackgroundSmsHandler get instance {
    _instance ??= BackgroundSmsHandler._();
    return _instance!;
  }

  bool _isRegistered = false;

  bool get isAndroid => Platform.isAndroid;
  bool get isRegistered => _isRegistered;

  void register() {
    if (!isAndroid || _isRegistered) return;

    _isRegistered = true;
    debugPrint('Background SMS handler registered');
  }

  void unregister() {
    _isRegistered = false;
    debugPrint('Background SMS handler unregistered');
  }
}
