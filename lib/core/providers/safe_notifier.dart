import 'package:flutter_riverpod/flutter_riverpod.dart';

/// StateNotifier의 안전한 비동기 작업을 위한 베이스 클래스
///
/// 이 클래스는 비동기 작업 중 위젯이 dispose되는 경우를 자동으로 처리합니다.
/// `_dependents.isEmpty` 에러를 방지하기 위해 모든 비동기 작업과
/// Provider 무효화 작업에 mounted 체크를 적용합니다.
///
/// 사용 예시:
/// ```dart
/// class MyNotifier extends SafeNotifier<List<Item>> {
///   MyNotifier(Ref ref) : super(ref, const AsyncValue.loading());
///
///   Future<void> createItem(Item item) async {
///     final result = await safeAsync(() => repository.createItem(item));
///     if (result == null) return; // disposed
///
///     safeInvalidate(itemsProvider);
///   }
/// }
/// ```
abstract class SafeNotifier<T> extends StateNotifier<AsyncValue<T>> {
  /// Riverpod Ref 인스턴스
  ///
  /// Provider 무효화 및 다른 Provider 접근에 사용됩니다.
  final Ref ref;

  SafeNotifier(this.ref, AsyncValue<T> initialState) : super(initialState);

  /// 비동기 작업을 안전하게 실행합니다.
  ///
  /// [action]을 실행하고, 완료 후 위젯이 아직 마운트되어 있는지 확인합니다.
  /// 위젯이 이미 dispose되었다면 null을 반환하여 후속 작업을 중단할 수 있습니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// final result = await safeAsync(() => repository.getData());
  /// if (result == null) return; // 위젯이 dispose됨
  /// // result 사용
  /// ```
  ///
  /// [action]: 실행할 비동기 작업
  /// 반환값: 작업 결과 또는 null (dispose된 경우)
  Future<R?> safeAsync<R>(Future<R> Function() action) async {
    final result = await action();
    if (!mounted) return null;
    return result;
  }

  /// Provider를 안전하게 무효화합니다.
  ///
  /// 위젯이 마운트되어 있을 때만 Provider를 무효화합니다.
  /// 이미 dispose된 경우 무효화를 건너뜁니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// safeInvalidate(itemsProvider);
  /// ```
  ///
  /// [provider]: 무효화할 Provider
  void safeInvalidate(ProviderBase provider) {
    if (mounted) {
      ref.invalidate(provider);
    }
  }

  /// 여러 Provider를 안전하게 무효화합니다.
  ///
  /// 위젯이 마운트되어 있을 때만 모든 Provider를 무효화합니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// safeInvalidateAll([
  ///   itemsProvider,
  ///   categoriesProvider,
  ///   statsProvider,
  /// ]);
  /// ```
  ///
  /// [providers]: 무효화할 Provider 목록
  void safeInvalidateAll(List<ProviderBase> providers) {
    if (!mounted) return;
    for (final provider in providers) {
      ref.invalidate(provider);
    }
  }

  /// 상태를 안전하게 업데이트합니다.
  ///
  /// 위젯이 마운트되어 있을 때만 상태를 업데이트합니다.
  /// 이미 dispose된 경우 업데이트를 건너뜁니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// safeUpdateState(AsyncValue.data(items));
  /// ```
  ///
  /// [newState]: 새로운 상태
  void safeUpdateState(AsyncValue<T> newState) {
    if (mounted) {
      state = newState;
    }
  }

  /// 비동기 작업을 실행하고 결과를 상태로 설정합니다.
  ///
  /// AsyncValue.guard 패턴을 안전하게 실행합니다.
  /// 작업 시작 시 로딩 상태로 전환하고, 완료 후 결과 또는 에러를 상태에 반영합니다.
  ///
  /// 사용 예시:
  /// ```dart
  /// await safeGuard(() async {
  ///   await repository.updateItem(item);
  ///   return repository.getItems();
  /// });
  /// ```
  ///
  /// [action]: 실행할 비동기 작업
  Future<void> safeGuard(Future<T> Function() action) async {
    if (!mounted) return;
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(action);
    if (!mounted) return;
    state = result;
  }
}
