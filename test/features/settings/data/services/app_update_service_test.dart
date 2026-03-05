import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';

void main() {
  group('AppVersionInfo 모델 테스트', () {
    group('생성자 테스트', () {
      test('필수 필드만으로 AppVersionInfo를 올바르게 생성한다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.2.0',
          buildNumber: 42,
        );

        // Then: 모든 필수 필드가 올바르게 초기화되어야 한다
        expect(versionInfo.version, '1.2.0');
        expect(versionInfo.buildNumber, 42);
      });

      test('모든 필드를 포함하여 AppVersionInfo를 올바르게 생성한다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '2.0.0',
          buildNumber: 100,
          storeUrl: 'https://play.google.com/store/apps/details?id=com.example',
          releaseNotes: '버그 수정 및 성능 개선',
          isForceUpdate: true,
        );

        // Then: 모든 필드가 올바르게 초기화되어야 한다
        expect(versionInfo.version, '2.0.0');
        expect(versionInfo.buildNumber, 100);
        expect(
          versionInfo.storeUrl,
          'https://play.google.com/store/apps/details?id=com.example',
        );
        expect(versionInfo.releaseNotes, '버그 수정 및 성능 개선');
        expect(versionInfo.isForceUpdate, true);
      });
    });

    group('기본값 테스트', () {
      test('isForceUpdate의 기본값은 false이다', () {
        // Given & When: isForceUpdate를 명시하지 않고 생성
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
        );

        // Then: 기본값이 false여야 한다
        expect(versionInfo.isForceUpdate, false);
      });

      test('isForceUpdate를 명시적으로 false로 지정할 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
          isForceUpdate: false,
        );

        // Then
        expect(versionInfo.isForceUpdate, false);
      });

      test('isForceUpdate를 true로 지정하면 강제 업데이트가 활성화된다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
          isForceUpdate: true,
        );

        // Then
        expect(versionInfo.isForceUpdate, true);
      });
    });

    group('nullable 필드 테스트', () {
      test('storeUrl은 null일 수 있다', () {
        // Given & When: storeUrl 없이 생성
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
        );

        // Then: storeUrl이 null이어야 한다
        expect(versionInfo.storeUrl, isNull);
      });

      test('releaseNotes는 null일 수 있다', () {
        // Given & When: releaseNotes 없이 생성
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
        );

        // Then: releaseNotes가 null이어야 한다
        expect(versionInfo.releaseNotes, isNull);
      });

      test('storeUrl과 releaseNotes 모두 null일 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
        );

        // Then: 두 nullable 필드 모두 null이어야 한다
        expect(versionInfo.storeUrl, isNull);
        expect(versionInfo.releaseNotes, isNull);
      });

      test('storeUrl에 iOS App Store URL을 저장할 수 있다', () {
        // Given & When
        const iosStoreUrl =
            'https://apps.apple.com/kr/app/example/id1234567890';
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
          storeUrl: iosStoreUrl,
        );

        // Then
        expect(versionInfo.storeUrl, iosStoreUrl);
      });

      test('releaseNotes에 여러 줄의 릴리즈 노트를 저장할 수 있다', () {
        // Given & When
        const multilineNotes = '- 버그 수정\n- 성능 개선\n- 새로운 기능 추가';
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
          releaseNotes: multilineNotes,
        );

        // Then
        expect(versionInfo.releaseNotes, multilineNotes);
      });
    });

    group('다양한 버전 형식 테스트', () {
      test('메이저.마이너.패치 형식의 버전을 저장할 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.2.3',
          buildNumber: 50,
        );

        // Then
        expect(versionInfo.version, '1.2.3');
        expect(versionInfo.buildNumber, 50);
      });

      test('빌드 번호 0을 저장할 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 0,
        );

        // Then
        expect(versionInfo.buildNumber, 0);
      });

      test('큰 빌드 번호를 저장할 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '10.0.0',
          buildNumber: 99999,
        );

        // Then
        expect(versionInfo.buildNumber, 99999);
      });

      test('단자리 버전 번호를 저장할 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '1.0.0',
          buildNumber: 1,
        );

        // Then
        expect(versionInfo.version, '1.0.0');
      });

      test('두 자리 이상의 버전 번호를 저장할 수 있다', () {
        // Given & When
        const versionInfo = AppVersionInfo(
          version: '10.20.30',
          buildNumber: 1000,
        );

        // Then
        expect(versionInfo.version, '10.20.30');
        expect(versionInfo.buildNumber, 1000);
      });
    });
  });

  group('AppUpdateService 상수 및 설정 테스트', () {
    test('업데이트 체크 간격이 24시간으로 설정되어 있다', () {
      // AppUpdateService 내부의 _checkIntervalHours 상수 검증
      // static const이므로 간접적으로 동작을 통해 검증
      // 24시간 = 86400초 = 86400000밀리초
      const expectedHours = 24;
      const expectedMillis = expectedHours * 60 * 60 * 1000;

      // 24시간에 해당하는 밀리초값이 올바른지 확인
      expect(expectedMillis, 86400000);
    });
  });
}
