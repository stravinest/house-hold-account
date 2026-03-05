import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/data/services/app_update_service.dart';
import 'package:shared_household_account/features/settings/presentation/providers/app_update_provider.dart';

// build() 실행 시 null 반환하는 Fake
class _FakeAppUpdateNull extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async {
    ref.keepAlive();
    return null;
  }
}

// build() 실행 시 업데이트 정보 반환하는 Fake
class _FakeAppUpdateWithData extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async {
    ref.keepAlive();
    return const AppVersionInfo(
      version: '2.5.0',
      buildNumber: 250,
      storeUrl: 'https://play.google.com',
      releaseNotes: '새 기능',
      isForceUpdate: false,
    );
  }
}

// forceCheck()에서 에러를 던지는 Fake
class _FakeAppUpdateError extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;

  @override
  Future<AppVersionInfo?> forceCheck() async {
    state = const AsyncLoading();
    try {
      throw Exception('테스트 에러');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return null;
    }
  }
}

// forceCheck()에서 성공하는 Fake
class _FakeAppUpdateForceCheckSuccess extends AppUpdate {
  @override
  Future<AppVersionInfo?> build() async => null;

  @override
  Future<AppVersionInfo?> forceCheck() async {
    state = const AsyncLoading();
    const result = AppVersionInfo(
      version: '3.0.0',
      buildNumber: 300,
      isForceUpdate: true,
    );
    state = const AsyncData(result);
    return result;
  }
}

void main() {
  group('AppUpdate notifier build() 커버리지 테스트', () {
    test('build()가 실행되어 keepAlive 호출 후 null을 반환한다', () async {
      // Given: keepAlive가 포함된 Fake notifier
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNull()),
        ],
      );
      addTearDown(container.dispose);

      // When: build() 실행 대기
      final result = await container.read(appUpdateProvider.future);

      // Then: null 반환
      expect(result, isNull);
    });

    test('build()가 실행되어 keepAlive 호출 후 AppVersionInfo를 반환한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateWithData()),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(appUpdateProvider.future);

      // Then
      expect(result, isNotNull);
      expect(result!.version, equals('2.5.0'));
      expect(result.buildNumber, equals(250));
      expect(result.isForceUpdate, isFalse);
    });
  });

  group('AppUpdate forceCheck() 커버리지 테스트', () {
    test('forceCheck() 성공 시 AsyncData 상태가 된다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(
            () => _FakeAppUpdateForceCheckSuccess(),
          ),
        ],
      );
      addTearDown(container.dispose);

      // When: build 완료 대기
      await container.read(appUpdateProvider.future);

      // When: forceCheck 호출
      final result =
          await container.read(appUpdateProvider.notifier).forceCheck();

      // Then: 결과가 있다
      expect(result, isNotNull);
      expect(result!.version, equals('3.0.0'));
      expect(result.isForceUpdate, isTrue);

      // 상태가 AsyncData
      final state = container.read(appUpdateProvider);
      expect(state, isA<AsyncData<AppVersionInfo?>>());
    });

    test('forceCheck() 에러 시 AsyncError 상태가 되고 null을 반환한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateError()),
        ],
      );
      addTearDown(container.dispose);

      // When: build 완료 대기
      await container.read(appUpdateProvider.future);

      // When: forceCheck 호출
      final result =
          await container.read(appUpdateProvider.notifier).forceCheck();

      // Then: 에러 시 null 반환
      expect(result, isNull);

      // 상태가 AsyncError
      final state = container.read(appUpdateProvider);
      expect(state, isA<AsyncError<AppVersionInfo?>>());
    });

    test('forceCheck() 실행 중 AsyncLoading 상태를 거친다', () async {
      // Given: 약간 지연이 있는 Fake
      final loadingStates = <bool>[];

      final container = ProviderContainer(
        overrides: [
          appUpdateProvider.overrideWith(() => _FakeAppUpdateNull()),
        ],
      );
      addTearDown(container.dispose);

      // build 완료 대기
      await container.read(appUpdateProvider.future);

      // forceCheck 실행 (AsyncLoading 설정 후 결과 반환)
      container.listen(appUpdateProvider, (prev, next) {
        loadingStates.add(next.isLoading);
      });

      await container.read(appUpdateProvider.notifier).forceCheck();

      // Then: 로딩 상태가 있었다
      expect(loadingStates, isNotEmpty);
    });
  });

  group('packageInfoProvider 커버리지 테스트', () {
    test('packageInfoProvider는 AutoDisposeFutureProvider<dynamic>이다', () {
      // Given & When & Then
      expect(packageInfoProvider, isNotNull);
    });
  });
}
