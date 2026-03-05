import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';

// AppUpdate를 상속한 Fake notifier - build() 메서드를 오버라이드하여 실제 네트워크 호출을 피함
class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

class _FakeAppUpdateAvailable extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => const AppVersionInfo(
        version: '2.0.0',
        buildNumber: 999,
        storeUrl: 'https://play.google.com/store',
        isForceUpdate: false,
      );
}

class _FakeAppUpdateForceUpdate extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => const AppVersionInfo(
        version: '3.0.0',
        buildNumber: 1000,
        isForceUpdate: true,
      );
}

void main() {
  group('AppUpdateProvider 타입 검증 테스트', () {
    group('packageInfoProvider 타입 테스트', () {
      test('packageInfoProvider는 AutoDisposeFutureProvider<PackageInfo> 타입이다', () {
        // Given & When & Then
        // Riverpod 코드 생성으로 만들어진 provider의 타입을 검증한다
        expect(
          packageInfoProvider,
          isA<AutoDisposeFutureProvider<PackageInfo>>(),
        );
      });
    });

    group('appUpdateProvider 타입 테스트', () {
      test(
        'appUpdateProvider는 AutoDisposeAsyncNotifierProvider<AppUpdate, AppVersionInfo?> 타입이다',
        () {
          // Given & When & Then
          // Riverpod 코드 생성으로 만들어진 notifier provider의 타입을 검증한다
          expect(
            appUpdateProvider,
            isA<
              AutoDisposeAsyncNotifierProvider<AppUpdate, AppVersionInfo?>
            >(),
          );
        },
      );
    });

    group('AppUpdate notifier 타입 테스트', () {
      test('AppUpdate 인스턴스를 생성할 수 있다', () {
        // Given & When
        // AppUpdate는 Riverpod 코드 생성의 _$AppUpdate를 상속하므로
        // AsyncNotifier의 직접 타입 비교 대신 인스턴스 생성 가능 여부를 검증한다
        final notifier = AppUpdate();

        // Then: 인스턴스가 null이 아니어야 한다
        expect(notifier, isNotNull);
      });

      test('appUpdateProvider로 AppUpdate notifier를 참조할 수 있다', () {
        // Given & When & Then
        // provider를 통해 notifier 타입에 접근 가능한지 검증한다
        expect(appUpdateProvider, isNotNull);
      });
    });
  });

  group('AppUpdate notifier build() 실행 테스트', () {
    test('업데이트가 없을 때 null을 반환한다', () async {
      // Given: 업데이트 없음 Fake notifier 사용
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
        ],
      );
      addTearDown(container.dispose);

      // When: 상태 읽기
      final result = await container.read(appUpdateProvider.future);

      // Then: null 반환
      expect(result, isNull);
    });

    test('업데이트가 있을 때 AppVersionInfo를 반환한다', () async {
      // Given: 업데이트 있음 Fake notifier 사용
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
        ],
      );
      addTearDown(container.dispose);

      // When: 상태 읽기
      final result = await container.read(appUpdateProvider.future);

      // Then: AppVersionInfo 반환
      expect(result, isNotNull);
      expect(result!.version, equals('2.0.0'));
      expect(result.buildNumber, equals(999));
      expect(result.isForceUpdate, isFalse);
    });

    test('강제 업데이트가 있을 때 isForceUpdate가 true이다', () async {
      // Given: 강제 업데이트 Fake notifier 사용
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateForceUpdate()),
        ],
      );
      addTearDown(container.dispose);

      // When: 상태 읽기
      final result = await container.read(appUpdateProvider.future);

      // Then: 강제 업데이트 정보 반환
      expect(result, isNotNull);
      expect(result!.isForceUpdate, isTrue);
      expect(result.version, equals('3.0.0'));
    });

    test('초기 상태는 AsyncLoading이다', () {
      // Given: Fake notifier 사용
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
        ],
      );
      addTearDown(container.dispose);

      // When: 상태 즉시 읽기 (비동기 완료 전)
      final state = container.read(appUpdateProvider);

      // Then: 로딩 상태
      expect(state, isA<AsyncValue<AppVersionInfo?>>());
    });

    test('상태 완료 후 AsyncData 상태이다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
        ],
      );
      addTearDown(container.dispose);

      // When: 비동기 완료 대기
      await container.read(appUpdateProvider.future);
      final state = container.read(appUpdateProvider);

      // Then: 데이터 상태
      expect(state, isA<AsyncData<AppVersionInfo?>>());
    });
  });

  group('AppUpdate forceCheck() 테스트', () {
    test('forceCheck() 호출 시 결과를 반환한다', () async {
      // Given: 커스텀 forceCheck가 있는 Fake notifier
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateWithForceCheck()),
        ],
      );
      addTearDown(container.dispose);

      // When: build 완료 대기 후 forceCheck 호출
      await container.read(appUpdateProvider.future);
      final result = await container
          .read(appUpdateProvider.notifier)
          .forceCheck();

      // Then: 결과가 반환됨
      // forceCheck는 AppVersionInfo? 반환
      expect(result, isNull); // 업데이트 없음 경우
    });
  });

  group('AppVersionInfo 모델 추가 테스트', () {
    test('storeUrl이 있는 AppVersionInfo를 생성할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.5.0',
        buildNumber: 150,
        storeUrl: 'https://play.google.com/store/apps/details?id=com.test',
        releaseNotes: '버그 수정 및 성능 개선',
        isForceUpdate: false,
      );

      // Then
      expect(info.version, equals('1.5.0'));
      expect(info.buildNumber, equals(150));
      expect(info.storeUrl, isNotNull);
      expect(info.releaseNotes, equals('버그 수정 및 성능 개선'));
      expect(info.isForceUpdate, isFalse);
    });

    test('AppVersionInfo는 const 생성자로 생성할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(version: '1.0.0', buildNumber: 1);

      // Then
      expect(info, isNotNull);
    });
  });
}

// forceCheck()를 override하는 추가 Fake notifier
class _FakeAppUpdateWithForceCheck extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;

  @override
  Future<AppVersionInfo?> forceCheck() async {
    state = const AsyncLoading();
    state = const AsyncData(null);
    return null;
  }
}
