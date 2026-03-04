import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/services/ad_service.dart';

void main() {
  group('AdService 테스트', () {
    test('bannerAdUnitId가 null이 아닌 유효한 문자열을 반환해야 한다', () {
      // When: 배너 광고 단위 ID 조회
      final adUnitId = AdService.bannerAdUnitId;

      // Then: 유효한 문자열이어야 한다
      expect(adUnitId, isNotNull);
      expect(adUnitId, isNotEmpty);
    });

    test('bannerAdUnitId가 AdMob 광고 단위 ID 형식이어야 한다 (ca-app-pub-로 시작)', () {
      // When: 배너 광고 단위 ID 조회
      final adUnitId = AdService.bannerAdUnitId;

      // Then: ca-app-pub- 접두사로 시작해야 한다
      expect(adUnitId, startsWith('ca-app-pub-'));
    });

    test('bannerAdUnitId가 슬래시(/)로 구분된 광고 단위 ID 형식이어야 한다', () {
      // When: 배너 광고 단위 ID 조회
      final adUnitId = AdService.bannerAdUnitId;

      // Then: 앱 ID와 광고 단위 ID가 슬래시로 구분되어야 한다
      expect(adUnitId, contains('/'));
    });

    test('디버그 모드에서는 테스트 광고 단위 ID를 반환해야 한다', () {
      // Given: 디버그 모드 확인
      // flutter test는 항상 디버그 모드로 실행됨
      expect(kDebugMode, isTrue);

      // When: 배너 광고 단위 ID 조회
      final adUnitId = AdService.bannerAdUnitId;

      // Then: Google 공식 테스트 광고 ID를 반환해야 한다
      if (Platform.isAndroid) {
        expect(adUnitId, equals('ca-app-pub-3940256099942544/6300978111'));
      } else if (Platform.isIOS) {
        expect(adUnitId, equals('ca-app-pub-3940256099942544/2934735716'));
      }
      // 테스트 광고 ID는 항상 3940256099942544 퍼블리셔 ID를 포함한다
      expect(adUnitId, contains('3940256099942544'));
    });

    test('디버그 모드에서 프로덕션 광고 ID가 사용되지 않아야 한다', () {
      // Given: 디버그 모드 확인
      expect(kDebugMode, isTrue);

      // When: 배너 광고 단위 ID 조회
      final adUnitId = AdService.bannerAdUnitId;

      // Then: 프로덕션 퍼블리셔 ID(8329456731797308)가 포함되지 않아야 한다
      expect(adUnitId, isNot(contains('8329456731797308')));
    });

    test('플랫폼별로 적절한 광고 단위 ID를 반환해야 한다', () {
      // When: 배너 광고 단위 ID 조회
      final adUnitId = AdService.bannerAdUnitId;

      // Then: 현재 플랫폼에 맞는 ID를 반환해야 한다
      // macOS에서 테스트 실행 시 Platform.isAndroid == false, Platform.isIOS == false
      // 이 경우 iOS 테스트 ID가 반환됨
      if (Platform.isAndroid) {
        expect(adUnitId, contains('6300978111'));
      } else {
        expect(adUnitId, contains('2934735716'));
      }
    });
  });
}
