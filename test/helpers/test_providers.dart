import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Riverpod ProviderContainer 생성 헬퍼
///
/// 사용 예시:
/// ```dart
/// final container = createContainer(
///   overrides: [
///     myProvider.overrideWith((ref) => mockValue),
///   ],
/// );
/// ```
ProviderContainer createContainer({
  List<Override> overrides = const [],
  ProviderContainer? parent,
  List<ProviderObserver>? observers,
}) {
  return ProviderContainer(
    overrides: overrides,
    parent: parent,
    observers: observers,
  );
}

/// AsyncValue 테스트 헬퍼
class AsyncValueTestHelpers {
  /// AsyncValue.data 생성 헬퍼
  static AsyncValue<T> data<T>(T value) => AsyncValue.data(value);

  /// AsyncValue.loading 생성 헬퍼
  static AsyncValue<T> loading<T>() => const AsyncValue.loading();

  /// AsyncValue.error 생성 헬퍼
  static AsyncValue<T> error<T>(Object error, [StackTrace? stackTrace]) {
    return AsyncValue.error(error, stackTrace ?? StackTrace.current);
  }

  /// AsyncValue가 data 상태인지 확인
  static bool isData<T>(AsyncValue<T> value) => value is AsyncData<T>;

  /// AsyncValue가 loading 상태인지 확인
  static bool isLoading<T>(AsyncValue<T> value) => value is AsyncLoading<T>;

  /// AsyncValue가 error 상태인지 확인
  static bool isError<T>(AsyncValue<T> value) => value is AsyncError<T>;
}

/// ProviderListener Mock을 위한 클래스
class ProviderListener<T> {
  final List<T?> values = [];

  void call(T? previous, T value) {
    values.add(value);
  }

  T? get latest => values.isEmpty ? null : values.last;

  int get callCount => values.length;

  void reset() => values.clear();
}

/// Provider 테스트를 위한 확장 메서드
extension ProviderContainerTestExtension on ProviderContainer {
  /// Provider의 값을 읽고 dispose까지 보장하는 헬퍼
  ///
  /// 사용 예시:
  /// ```dart
  /// final value = await container.readAndDispose(myProvider.future);
  /// ```
  Future<T> readAndDispose<T>(ProviderListenable<Future<T>> provider) async {
    try {
      return await read(provider);
    } finally {
      dispose();
    }
  }

  /// Provider 상태 변화 감지 헬퍼
  ///
  /// 사용 예시:
  /// ```dart
  /// final listener = ProviderListener<int>();
  /// container.listenTo(myProvider, listener);
  /// ```
  void listenTo<T>(
    ProviderListenable<T> provider,
    ProviderListener<T> listener, {
    bool fireImmediately = false,
  }) {
    listen<T>(
      provider,
      (previous, next) => listener(previous, next),
      fireImmediately: fireImmediately,
    );
  }
}

/// 비동기 Provider 테스트 대기 헬퍼
///
/// Provider의 비동기 작업이 완료될 때까지 대기합니다.
///
/// 사용 예시:
/// ```dart
/// await pumpEventQueue();
/// ```
Future<void> pumpEventQueue({Duration duration = Duration.zero}) {
  return Future.delayed(duration);
}

/// Provider 오버라이드 빌더
///
/// 사용 예시:
/// ```dart
/// final overrides = ProviderOverrideBuilder()
///   .add(provider1, mockValue1)
///   .add(provider2, mockValue2)
///   .build();
/// ```
class ProviderOverrideBuilder {
  final List<Override> _overrides = [];

  /// Provider를 특정 값으로 오버라이드
  /// 주의: overrideWith를 사용하여 값을 반환하는 함수로 오버라이드
  ProviderOverrideBuilder addValue<T>(
    ProviderBase<T> provider,
    T value,
  ) {
    if (provider is Provider<T>) {
      _overrides.add(provider.overrideWith((_) => value));
    }
    return this;
  }

  /// Provider를 함수로 오버라이드
  ProviderOverrideBuilder addProvider<T>(
    ProviderBase<T> provider,
    T Function(Ref ref) create,
  ) {
    if (provider is Provider<T>) {
      _overrides.add(provider.overrideWith(create));
    }
    return this;
  }

  /// 빌드
  List<Override> build() => List.unmodifiable(_overrides);
}
