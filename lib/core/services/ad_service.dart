import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdService {
  AdService._();

  // Google 공식 테스트 배너 광고 단위 ID
  static const String _androidTestBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _iosTestBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';

  static String get bannerAdUnitId {
    if (kDebugMode) {
      return Platform.isAndroid
          ? _androidTestBannerAdUnitId
          : _iosTestBannerAdUnitId;
    }
    return Platform.isAndroid
        ? dotenv.get('ADMOB_ANDROID_BANNER_ID')
        : dotenv.get('ADMOB_IOS_BANNER_ID');
  }
}
