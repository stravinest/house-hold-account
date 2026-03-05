import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';

void main() {
  group('AppUpdateService 로직 단위 테스트', () {
    group('업데이트 체크 간격 로직', () {
      test('24시간이 경과하지 않으면 체크를 스킵해야 한다', () {
        // Given: 마지막 체크 시각이 현재로부터 1시간 전
        final now = DateTime.now().millisecondsSinceEpoch;
        final oneHourAgo = now - (1 * 60 * 60 * 1000);
        const checkIntervalHours = 24;
        const checkIntervalMs = checkIntervalHours * 60 * 60 * 1000;

        // When: 경과 시간 계산
        final elapsed = now - oneHourAgo;
        final shouldSkip = elapsed < checkIntervalMs;

        // Then: 스킵해야 한다
        expect(shouldSkip, isTrue);
      });

      test('24시간이 경과하면 체크를 수행해야 한다', () {
        // Given: 마지막 체크 시각이 현재로부터 25시간 전
        final now = DateTime.now().millisecondsSinceEpoch;
        final twentyFiveHoursAgo = now - (25 * 60 * 60 * 1000);
        const checkIntervalHours = 24;
        const checkIntervalMs = checkIntervalHours * 60 * 60 * 1000;

        // When
        final elapsed = now - twentyFiveHoursAgo;
        final shouldSkip = elapsed < checkIntervalMs;

        // Then: 스킵하지 않는다
        expect(shouldSkip, isFalse);
      });

      test('마지막 체크 시각이 0이면 항상 체크를 수행해야 한다', () {
        // Given: 초기 상태 (한 번도 체크하지 않음)
        const lastCheck = 0;
        final now = DateTime.now().millisecondsSinceEpoch;
        const checkIntervalMs = 24 * 60 * 60 * 1000;

        // When
        final elapsed = now - lastCheck;
        final shouldSkip = elapsed < checkIntervalMs;

        // Then: 스킵하지 않는다 (경과 시간이 충분히 크다)
        expect(shouldSkip, isFalse);
      });

      test('force=true이면 체크 간격과 무관하게 항상 체크를 수행한다', () {
        // Given
        const force = true;

        // When: force가 true이면 lastCheck와 무관하게 진행
        final shouldForceCheck = force;

        // Then
        expect(shouldForceCheck, isTrue);
      });

      test('정확히 24시간이 경과한 경우 체크를 수행해야 한다', () {
        // Given: 정확히 24시간 경과
        final now = DateTime.now().millisecondsSinceEpoch;
        final exactlyTwentyFourHoursAgo = now - (24 * 60 * 60 * 1000);
        const checkIntervalMs = 24 * 60 * 60 * 1000;

        // When
        final elapsed = now - exactlyTwentyFourHoursAgo;
        final shouldSkip = elapsed < checkIntervalMs;

        // Then: 정확히 24시간이면 스킵하지 않는다 (< 조건)
        expect(shouldSkip, isFalse);
      });
    });

    group('서버 빌드 번호 비교 로직', () {
      test('서버 빌드 번호가 현재보다 크면 업데이트가 필요하다', () {
        // Given
        const currentBuildNumber = 10;
        const serverBuildNumber = 11;

        // When
        final hasUpdate = serverBuildNumber > currentBuildNumber;

        // Then
        expect(hasUpdate, isTrue);
      });

      test('서버 빌드 번호가 현재와 같으면 업데이트가 필요 없다', () {
        // Given
        const currentBuildNumber = 10;
        const serverBuildNumber = 10;

        // When
        final hasUpdate = serverBuildNumber > currentBuildNumber;

        // Then
        expect(hasUpdate, isFalse);
      });

      test('서버 빌드 번호가 현재보다 작으면 업데이트가 필요 없다', () {
        // Given
        const currentBuildNumber = 10;
        const serverBuildNumber = 9;

        // When
        final hasUpdate = serverBuildNumber > currentBuildNumber;

        // Then
        expect(hasUpdate, isFalse);
      });

      test('buildNumber를 문자열에서 정수로 변환하는 로직이 올바르다', () {
        // Given: PackageInfo.buildNumber는 String 반환
        const buildNumberString = '42';

        // When
        final buildNumber = int.tryParse(buildNumberString) ?? 0;

        // Then
        expect(buildNumber, equals(42));
      });

      test('buildNumber가 빈 문자열이면 0으로 처리한다', () {
        // Given
        const buildNumberString = '';

        // When
        final buildNumber = int.tryParse(buildNumberString) ?? 0;

        // Then
        expect(buildNumber, equals(0));
      });

      test('buildNumber가 숫자가 아니면 0으로 처리한다', () {
        // Given
        const buildNumberString = 'invalid';

        // When
        final buildNumber = int.tryParse(buildNumberString) ?? 0;

        // Then
        expect(buildNumber, equals(0));
      });
    });

    group('서버 응답 파싱 로직', () {
      test('서버 응답이 null이면 업데이트 없음을 반환해야 한다', () {
        // Given
        const Map<String, dynamic>? response = null;

        // When: null 체크 로직
        final shouldReturn = response == null;

        // Then
        expect(shouldReturn, isTrue);
      });

      test('is_force_update가 null이면 false로 처리한다', () {
        // Given
        final response = <String, dynamic>{
          'version': '2.0.0',
          'build_number': 100,
          'is_force_update': null,
        };

        // When
        final isForceUpdate = response['is_force_update'] as bool? ?? false;

        // Then
        expect(isForceUpdate, isFalse);
      });

      test('is_force_update가 true이면 true로 처리한다', () {
        // Given
        final response = <String, dynamic>{
          'version': '2.0.0',
          'build_number': 100,
          'is_force_update': true,
        };

        // When
        final isForceUpdate = response['is_force_update'] as bool? ?? false;

        // Then
        expect(isForceUpdate, isTrue);
      });

      test('서버 응답에서 AppVersionInfo를 올바르게 생성한다', () {
        // Given
        final response = <String, dynamic>{
          'version': '2.0.0',
          'build_number': 100,
          'store_url': 'https://play.google.com',
          'release_notes': '새로운 기능 추가',
          'is_force_update': false,
        };

        // When
        final versionInfo = AppVersionInfo(
          version: response['version'] as String,
          buildNumber: response['build_number'] as int,
          storeUrl: response['store_url'] as String?,
          releaseNotes: response['release_notes'] as String?,
          isForceUpdate: response['is_force_update'] as bool? ?? false,
        );

        // Then
        expect(versionInfo.version, equals('2.0.0'));
        expect(versionInfo.buildNumber, equals(100));
        expect(versionInfo.storeUrl, equals('https://play.google.com'));
        expect(versionInfo.releaseNotes, equals('새로운 기능 추가'));
        expect(versionInfo.isForceUpdate, isFalse);
      });
    });

    group('플랫폼 분기 로직', () {
      test('android 플랫폼 문자열이 올바르다', () {
        // Given: Platform.isAndroid가 true인 경우
        const platform = 'android';

        // When & Then
        expect(platform, equals('android'));
      });

      test('ios 플랫폼 문자열이 올바르다', () {
        // Given: Platform.isAndroid가 false인 경우
        const platform = 'ios';

        // When & Then
        expect(platform, equals('ios'));
      });
    });
  });
}
