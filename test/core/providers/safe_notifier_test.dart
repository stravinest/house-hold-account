import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/providers/safe_notifier.dart';

// 테스트용 SafeNotifier 구현
class TestSafeNotifier extends SafeNotifier<List<String>> {
  TestSafeNotifier(Ref ref) : super(ref, const AsyncValue.loading());

  // 테스트용 비동기 작업 시뮬레이션
  Future<String> mockAsyncOperation() async {
    await Future.delayed(const Duration(milliseconds: 10));
    return 'result';
  }

  Future<void> testSafeAsync() async {
    final result = await safeAsync(() => mockAsyncOperation());
    if (result == null) return;
    state = AsyncValue.data([result]);
  }

  Future<void> testSafeGuard() async {
    await safeGuard(() async {
      await Future.delayed(const Duration(milliseconds: 10));
      return ['item1', 'item2'];
    });
  }

  void testSafeUpdateState(AsyncValue<List<String>> newState) {
    safeUpdateState(newState);
  }

  void testSafeInvalidate(ProviderBase provider) {
    safeInvalidate(provider);
  }

  void testSafeInvalidateAll(List<ProviderBase> providers) {
    safeInvalidateAll(providers);
  }
}

// 테스트용 Provider들
final testProvider = Provider<String>((ref) => 'test');
final testProvider2 = Provider<int>((ref) => 123);

final testNotifierProvider =
    StateNotifierProvider<TestSafeNotifier, AsyncValue<List<String>>>((ref) {
  return TestSafeNotifier(ref);
});

void main() {
  group('SafeNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    group('safeAsync', () {
      test('mounted 상태에서 비동기 작업이 정상 완료된다', () async {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);

        // When
        await notifier.testSafeAsync();

        // Then
        final state = container.read(testNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, equals(['result']));
      });

      test('dispose된 후에는 null을 반환한다', () async {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);

        // When
        final future = notifier.mockAsyncOperation();
        testContainer.dispose(); // 비동기 작업 중에 dispose
        final result = await notifier.safeAsync(() => future);

        // Then
        expect(result, isNull);
      });

      test('비동기 작업 결과를 정상적으로 반환한다', () async {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);

        // When
        final result = await notifier.safeAsync(() => notifier.mockAsyncOperation());

        // Then
        expect(result, equals('result'));
      });
    });

    group('safeInvalidate', () {
      test('mounted 상태에서 Provider를 무효화한다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        final providerValue = container.read(testProvider);
        expect(providerValue, equals('test'));

        // When
        notifier.testSafeInvalidate(testProvider);

        // Then
        final newValue = container.read(testProvider);
        expect(newValue, equals('test'));
      });

      test('dispose된 후에는 무효화를 건너뛴다', () {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);
        testContainer.dispose();

        // When & Then - 에러가 발생하지 않아야 함
        expect(
          () => notifier.testSafeInvalidate(testProvider),
          returnsNormally,
        );
      });
    });

    group('safeInvalidateAll', () {
      test('mounted 상태에서 여러 Provider를 무효화한다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        final providers = [testProvider, testProvider2];

        // When
        notifier.testSafeInvalidateAll(providers);

        // Then
        expect(container.read(testProvider), equals('test'));
        expect(container.read(testProvider2), equals(123));
      });

      test('dispose된 후에는 무효화를 건너뛴다', () {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);
        final providers = [testProvider, testProvider2];
        testContainer.dispose();

        // When & Then - 에러가 발생하지 않아야 함
        expect(
          () => notifier.testSafeInvalidateAll(providers),
          returnsNormally,
        );
      });

      test('빈 리스트를 전달해도 에러가 발생하지 않는다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        final emptyProviders = <ProviderBase>[];

        // When & Then
        expect(
          () => notifier.testSafeInvalidateAll(emptyProviders),
          returnsNormally,
        );
      });
    });

    group('safeUpdateState', () {
      test('mounted 상태에서 상태를 업데이트한다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        final newState = AsyncValue<List<String>>.data(['updated']);

        // When
        notifier.testSafeUpdateState(newState);

        // Then
        final state = container.read(testNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, equals(['updated']));
      });

      test('dispose된 후에는 상태 업데이트를 건너뛴다', () {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);
        final newState = AsyncValue<List<String>>.data(['should not update']);
        testContainer.dispose();

        // When & Then - 에러가 발생하지 않아야 함
        expect(
          () => notifier.testSafeUpdateState(newState),
          returnsNormally,
        );
      });

      test('에러 상태로 업데이트할 수 있다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        final error = Exception('test error');
        final errorState = AsyncValue<List<String>>.error(
          error,
          StackTrace.current,
        );

        // When
        notifier.testSafeUpdateState(errorState);

        // Then
        final state = container.read(testNotifierProvider);
        expect(state.hasError, isTrue);
      });

      test('로딩 상태로 업데이트할 수 있다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        const loadingState = AsyncValue<List<String>>.loading();

        // When
        notifier.testSafeUpdateState(loadingState);

        // Then
        final state = container.read(testNotifierProvider);
        expect(state.isLoading, isTrue);
      });
    });

    group('safeGuard', () {
      test('비동기 작업을 실행하고 성공 결과를 상태에 반영한다', () async {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);

        // When
        await notifier.testSafeGuard();

        // Then
        final state = container.read(testNotifierProvider);
        expect(state.hasValue, isTrue);
        expect(state.value, equals(['item1', 'item2']));
      });

      test('작업 시작 시 로딩 상태로 전환한다', () async {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);
        final states = <AsyncValue<List<String>>>[];

        container.listen<AsyncValue<List<String>>>(
          testNotifierProvider,
          (previous, next) => states.add(next),
          fireImmediately: true,
        );

        // When
        await notifier.testSafeGuard();

        // Then
        expect(states.length, greaterThanOrEqualTo(2));
        expect(states[0].isLoading, isTrue);
        expect(states.last.hasValue, isTrue);
      });

      test('작업 중 에러가 발생하면 에러 상태로 전환한다', () async {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);

        // When
        await notifier.safeGuard(() async {
          throw Exception('test error');
        });

        // Then
        final state = container.read(testNotifierProvider);
        expect(state.hasError, isTrue);
      });

      test('dispose된 후에는 상태를 업데이트하지 않는다', () async {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);

        // When
        final guardFuture = notifier.safeGuard(() async {
          await Future.delayed(const Duration(milliseconds: 50));
          return ['should not update'];
        });

        await Future.delayed(const Duration(milliseconds: 5));
        testContainer.dispose();
        await guardFuture;

        // Then - dispose 후에는 상태가 변경되지 않음
        expect(notifier.mounted, isFalse);
      });
    });

    group('mounted 상태 확인', () {
      test('생성 직후에는 mounted가 true다', () {
        // Given & When
        final notifier = container.read(testNotifierProvider.notifier);

        // Then
        expect(notifier.mounted, isTrue);
      });

      test('dispose 후에는 mounted가 false다', () {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);

        // When
        testContainer.dispose();

        // Then
        expect(notifier.mounted, isFalse);
      });

      test('container dispose 시 notifier도 dispose된다', () {
        // Given
        final testContainer = ProviderContainer();
        final notifier = testContainer.read(testNotifierProvider.notifier);
        expect(notifier.mounted, isTrue);

        // When
        testContainer.dispose();

        // Then
        expect(notifier.mounted, isFalse);
      });
    });

    group('SafeNotifier 기본 동작', () {
      test('초기 상태가 loading이다', () {
        // Given & When
        final state = container.read(testNotifierProvider);

        // Then
        expect(state.isLoading, isTrue);
      });

      test('Ref 인스턴스를 갖고 있다', () {
        // Given
        final notifier = container.read(testNotifierProvider.notifier);

        // When & Then
        expect(notifier.ref, isNotNull);
      });
    });
  });
}
