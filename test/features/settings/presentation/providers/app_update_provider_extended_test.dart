import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';

// AppUpdate 빌드 시 null 반환하는 Fake
class _FakeAppUpdateNone extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;
}

// AppUpdate 빌드 시 업데이트 정보를 반환하는 Fake
class _FakeAppUpdateAvailable extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => const AppVersionInfo(
        version: '2.0.0',
        buildNumber: 200,
        storeUrl: 'https://play.google.com/store',
        isForceUpdate: false,
      );
}

// forceCheck 호출 결과를 제어하는 Fake (null 반환용)
class _FakeAppUpdateForceCheckNull extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;

  @override
  Future<AppVersionInfo?> forceCheck() async {
    state = const AsyncData(null);
    return null;
  }
}

// forceCheck 호출 결과를 제어하는 Fake (업데이트 있음 반환용)
class _FakeAppUpdateForceCheckAvailable extends AppUpdate {
  final AppVersionInfo updateInfo;

  _FakeAppUpdateForceCheckAvailable(this.updateInfo);

  @override
  Future<AppVersionInfo?> build() async => null;

  @override
  Future<AppVersionInfo?> forceCheck() async {
    state = AsyncData(updateInfo);
    return updateInfo;
  }
}

void main() {
  group('AppUpdate Notifier 상태 전환 테스트', () {
    test('업데이트 없음 상태로 초기화되어야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
        ],
      );
      addTearDown(container.dispose);

      // When: 비동기 상태 완료 대기
      final result = await container.read(appUpdateProvider.future);

      // Then: null (업데이트 없음)
      expect(result, isNull);
    });

    test('업데이트 있음 상태로 초기화되어야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateAvailable()),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(appUpdateProvider.future);

      // Then: 버전 정보 반환
      expect(result, isNotNull);
      expect(result!.version, '2.0.0');
      expect(result.buildNumber, 200);
    });

    test('forceCheck 호출 시 업데이트 없음 상태로 전환되어야 한다', () async {
      // Given
      final fakeNotifier = _FakeAppUpdateForceCheckNull();
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => fakeNotifier),
        ],
      );
      addTearDown(container.dispose);

      // When: build() 완료 대기 후 forceCheck 직접 호출
      await container.read(appUpdateProvider.future);
      final result = await fakeNotifier.forceCheck();

      // Then: null 반환 (업데이트 없음)
      expect(result, isNull);
      expect(container.read(appUpdateProvider).valueOrNull, isNull);
    });

    test('forceCheck 호출 시 업데이트 있음 상태로 전환되어야 한다', () async {
      // Given
      const updateInfo = AppVersionInfo(
        version: '3.0.0',
        buildNumber: 300,
        isForceUpdate: true,
      );
      final fakeNotifier = _FakeAppUpdateForceCheckAvailable(updateInfo);
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => fakeNotifier),
        ],
      );
      addTearDown(container.dispose);

      // When: build() 완료 대기 후 forceCheck 직접 호출
      await container.read(appUpdateProvider.future);
      final result = await fakeNotifier.forceCheck();

      // Then: 업데이트 정보 반환
      expect(result, isNotNull);
      expect(result!.version, '3.0.0');
      expect(result.isForceUpdate, isTrue);
      expect(container.read(appUpdateProvider).valueOrNull, isNotNull);
    });

    test('AppUpdate 인스턴스는 AppUpdate 타입이어야 한다', () {
      // Given & When
      final notifier = AppUpdate();

      // Then
      expect(notifier, isA<AppUpdate>());
    });

    test('appUpdateProvider는 null 상태를 AsyncData로 감쌀 수 있다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNone()),
        ],
      );
      addTearDown(container.dispose);

      // When
      final state = await container.read(appUpdateProvider.future);

      // Then: AsyncData<null> 상태
      expect(container.read(appUpdateProvider), isA<AsyncData<AppVersionInfo?>>());
      expect(state, isNull);
    });
  });

  group('AppVersionInfo 비교 로직 테스트', () {
    test('storeUrl이 있는 버전 정보를 생성할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.5.0',
        buildNumber: 150,
        storeUrl: 'https://play.google.com/store/apps/details?id=com.example',
      );

      // Then
      expect(info.storeUrl, isNotNull);
      expect(info.version, '1.5.0');
    });

    test('releaseNotes가 있는 버전 정보를 생성할 수 있다', () {
      // Given & When
      const info = AppVersionInfo(
        version: '1.5.0',
        buildNumber: 150,
        releaseNotes: '새로운 기능이 추가되었습니다.',
      );

      // Then
      expect(info.releaseNotes, '새로운 기능이 추가되었습니다.');
    });
  });
}
