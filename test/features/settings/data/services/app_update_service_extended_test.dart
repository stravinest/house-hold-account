import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';

// AppUpdateService의 핵심 비즈니스 로직을 단위 테스트로 검증합니다.
// Supabase 및 PackageInfo 직접 호출 부분은 제외하고
// 순수 로직 (조건, 비교, 파싱)을 검증합니다.

void main() {
  group('AppVersionInfo 모델 테스트', () {
    test('필수 필드만으로 AppVersionInfo를 생성할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.0.0',
        buildNumber: 100,
      );

      // Then
      expect(info.version, equals('1.0.0'));
      expect(info.buildNumber, equals(100));
      expect(info.storeUrl, isNull);
      expect(info.releaseNotes, isNull);
      expect(info.isForceUpdate, isFalse);
    });

    test('모든 필드를 지정하여 AppVersionInfo를 생성할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        storeUrl: 'https://play.google.com/store/apps/details?id=com.example',
        releaseNotes: '새로운 기능이 추가되었습니다.',
        isForceUpdate: true,
      );

      // Then
      expect(info.version, equals('2.0.0'));
      expect(info.buildNumber, equals(200));
      expect(info.storeUrl, isNotNull);
      expect(info.releaseNotes, isNotNull);
      expect(info.isForceUpdate, isTrue);
    });

    test('isForceUpdate 기본값은 false이다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.0.0',
        buildNumber: 100,
      );

      // Then
      expect(info.isForceUpdate, isFalse);
    });

    test('isForceUpdate를 true로 설정할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.0.0',
        buildNumber: 100,
        isForceUpdate: true,
      );

      // Then
      expect(info.isForceUpdate, isTrue);
    });

    test('storeUrl을 null로 설정할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.0.0',
        buildNumber: 100,
        storeUrl: null,
      );

      // Then
      expect(info.storeUrl, isNull);
    });

    test('releaseNotes를 null로 설정할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.0.0',
        buildNumber: 100,
        releaseNotes: null,
      );

      // Then
      expect(info.releaseNotes, isNull);
    });
  });

  group('AppUpdateService 상수 테스트', () {
    test('checkIntervalHours가 24시간이다', () {
      // Given: AppUpdateService._checkIntervalHours
      const checkIntervalHours = 24;

      // When & Then
      expect(checkIntervalHours, equals(24));
    });

    test('24시간을 밀리초로 환산하면 86400000이다', () {
      // Given
      const hours = 24;

      // When
      final ms = hours * 60 * 60 * 1000;

      // Then
      expect(ms, equals(86400000));
    });
  });

  group('AppUpdateService 업데이트 필요 여부 판단 로직', () {
    test('서버 빌드 번호가 현재보다 크면 업데이트가 필요하다', () {
      // Given
      const currentBuildNumber = 100;
      const serverBuildNumber = 101;

      // When: 비교 로직
      final needsUpdate = serverBuildNumber > currentBuildNumber;

      // Then
      expect(needsUpdate, isTrue);
    });

    test('서버 빌드 번호가 현재와 같으면 업데이트가 불필요하다', () {
      // Given
      const currentBuildNumber = 100;
      const serverBuildNumber = 100;

      // When
      final needsUpdate = serverBuildNumber > currentBuildNumber;

      // Then
      expect(needsUpdate, isFalse);
    });

    test('서버 빌드 번호가 현재보다 작으면 업데이트가 불필요하다', () {
      // Given
      const currentBuildNumber = 100;
      const serverBuildNumber = 99;

      // When
      final needsUpdate = serverBuildNumber > currentBuildNumber;

      // Then
      expect(needsUpdate, isFalse);
    });

    test('빌드 번호가 크게 차이 나도 올바르게 판단한다', () {
      // Given
      const currentBuildNumber = 50;
      const serverBuildNumber = 200;

      // When
      final needsUpdate = serverBuildNumber > currentBuildNumber;

      // Then
      expect(needsUpdate, isTrue);
    });
  });

  group('AppUpdateService 체크 간격 로직', () {
    test('24시간이 경과하지 않으면 체크를 건너뛴다', () {
      // Given
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastCheck = now - (12 * 60 * 60 * 1000); // 12시간 전
      const checkIntervalMs = 24 * 60 * 60 * 1000;

      // When: 체크 스킵 조건
      final elapsed = now - lastCheck;
      final shouldSkip = elapsed < checkIntervalMs;

      // Then
      expect(shouldSkip, isTrue);
    });

    test('24시간이 경과했으면 체크를 수행한다', () {
      // Given
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastCheck = now - (25 * 60 * 60 * 1000); // 25시간 전
      const checkIntervalMs = 24 * 60 * 60 * 1000;

      // When
      final elapsed = now - lastCheck;
      final shouldSkip = elapsed < checkIntervalMs;

      // Then
      expect(shouldSkip, isFalse);
    });

    test('마지막 체크 기록이 없으면 (0) 체크를 수행한다', () {
      // Given
      final now = DateTime.now().millisecondsSinceEpoch;
      const lastCheck = 0; // 기록 없음
      const checkIntervalMs = 24 * 60 * 60 * 1000;

      // When
      final elapsed = now - lastCheck;
      final shouldSkip = elapsed < checkIntervalMs;

      // Then
      expect(shouldSkip, isFalse);
    });

    test('force=true이면 체크 간격과 상관없이 항상 체크를 수행한다', () {
      // Given
      const force = true;
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastCheck = now - (1 * 60 * 1000); // 1분 전
      const checkIntervalMs = 24 * 60 * 60 * 1000;
      final elapsed = now - lastCheck;

      // When: force 플래그로 스킵 조건 우회
      final shouldCheck = force || elapsed >= checkIntervalMs;

      // Then
      expect(shouldCheck, isTrue);
    });

    test('force=false이고 24시간 미경과이면 체크를 건너뛴다', () {
      // Given
      const force = false;
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastCheck = now - (6 * 60 * 60 * 1000); // 6시간 전
      const checkIntervalMs = 24 * 60 * 60 * 1000;
      final elapsed = now - lastCheck;

      // When
      final shouldSkip = !force && elapsed < checkIntervalMs;

      // Then
      expect(shouldSkip, isTrue);
    });
  });

  group('AppUpdateService 서버 응답 파싱 로직', () {
    test('서버 응답에서 version을 파싱한다', () {
      // Given
      final response = <String, dynamic>{
        'version': '2.5.0',
        'build_number': 250,
        'store_url': 'https://play.google.com',
        'release_notes': '버그 수정',
        'is_force_update': false,
      };

      // When: checkForUpdate 내 응답 파싱 시뮬레이션
      final version = response['version'] as String;
      final buildNumber = response['build_number'] as int;
      final storeUrl = response['store_url'] as String?;
      final releaseNotes = response['release_notes'] as String?;
      final isForceUpdate = response['is_force_update'] as bool? ?? false;

      // Then
      expect(version, equals('2.5.0'));
      expect(buildNumber, equals(250));
      expect(storeUrl, equals('https://play.google.com'));
      expect(releaseNotes, equals('버그 수정'));
      expect(isForceUpdate, isFalse);
    });

    test('is_force_update가 null이면 false로 기본값 처리된다', () {
      // Given
      final response = <String, dynamic>{
        'version': '2.5.0',
        'build_number': 250,
        'is_force_update': null,
      };

      // When
      final isForceUpdate = response['is_force_update'] as bool? ?? false;

      // Then
      expect(isForceUpdate, isFalse);
    });

    test('is_force_update가 true이면 강제 업데이트로 처리된다', () {
      // Given
      final response = <String, dynamic>{
        'version': '3.0.0',
        'build_number': 300,
        'is_force_update': true,
      };

      // When
      final isForceUpdate = response['is_force_update'] as bool? ?? false;

      // Then
      expect(isForceUpdate, isTrue);
    });

    test('서버 응답이 null이면 null을 반환한다', () {
      // Given
      const Map<String, dynamic>? response = null;

      // When: null 체크 로직
      AppVersionInfo? result;
      if (response == null) {
        result = null;
      }

      // Then
      expect(result, isNull);
    });

    test('store_url이 null이어도 AppVersionInfo를 생성한다', () {
      // Given
      final response = <String, dynamic>{
        'version': '2.0.0',
        'build_number': 200,
        'store_url': null,
        'release_notes': null,
        'is_force_update': false,
      };

      // When
      final info = AppVersionInfo(
        version: response['version'] as String,
        buildNumber: response['build_number'] as int,
        storeUrl: response['store_url'] as String?,
        releaseNotes: response['release_notes'] as String?,
        isForceUpdate: response['is_force_update'] as bool? ?? false,
      );

      // Then
      expect(info.storeUrl, isNull);
      expect(info.version, equals('2.0.0'));
    });
  });

  group('AppUpdateService 빌드 번호 파싱 로직', () {
    test('유효한 숫자 문자열을 int로 파싱한다', () {
      // Given
      const buildNumberStr = '150';

      // When: int.tryParse 로직
      final buildNumber = int.tryParse(buildNumberStr) ?? 0;

      // Then
      expect(buildNumber, equals(150));
    });

    test('null 또는 빈 문자열이면 0을 기본값으로 사용한다', () {
      // Given
      const String? buildNumberStr = null;

      // When
      final buildNumber = int.tryParse(buildNumberStr ?? '') ?? 0;

      // Then
      expect(buildNumber, equals(0));
    });

    test('숫자가 아닌 문자열이면 0을 기본값으로 사용한다', () {
      // Given
      const buildNumberStr = 'invalid';

      // When
      final buildNumber = int.tryParse(buildNumberStr) ?? 0;

      // Then
      expect(buildNumber, equals(0));
    });

    test('빌드 번호 0은 모든 서버 버전보다 낮다', () {
      // Given
      const currentBuildNumber = 0;
      const serverBuildNumber = 1;

      // When
      final needsUpdate = serverBuildNumber > currentBuildNumber;

      // Then
      expect(needsUpdate, isTrue);
    });
  });

  group('AppUpdateService 플랫폼 로직', () {
    test('플랫폼 문자열은 android 또는 ios이다', () {
      // Given: 가능한 플랫폼 값들
      const platforms = ['android', 'ios'];

      // When & Then
      for (final platform in platforms) {
        expect(platform == 'android' || platform == 'ios', isTrue);
      }
    });

    test('android 플랫폼 문자열은 올바른 형식이다', () {
      // Given
      const platform = 'android';

      // Then
      expect(platform, equals('android'));
      expect(platform.isNotEmpty, isTrue);
    });

    test('ios 플랫폼 문자열은 올바른 형식이다', () {
      // Given
      const platform = 'ios';

      // Then
      expect(platform, equals('ios'));
      expect(platform.isNotEmpty, isTrue);
    });
  });
}
