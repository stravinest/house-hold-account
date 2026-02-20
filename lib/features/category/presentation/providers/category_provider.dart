import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/safe_notifier.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/category_repository.dart';
import '../../domain/entities/category.dart';

// Repository 프로바이더
final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});

// 현재 가계부의 카테고리 목록
final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(categoryRepositoryProvider);
  return repository.getCategories(ledgerId);
});

// 수입 카테고리 목록
final incomeCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  return categories.where((c) => c.isIncome).toList();
});

// 지출 카테고리 목록
final expenseCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  return categories.where((c) => c.isExpense).toList();
});

// 자산 카테고리 목록
final savingCategoriesProvider = FutureProvider<List<Category>>((ref) async {
  final categories = await ref.watch(categoriesProvider.future);
  return categories.where((c) => c.isAssetType).toList();
});

// 카테고리 관리 노티파이어
class CategoryNotifier extends SafeNotifier<List<Category>> {
  final CategoryRepository _repository;
  final String? _ledgerId;
  RealtimeChannel? _categoriesChannel;

  CategoryNotifier(this._repository, this._ledgerId, Ref ref)
    : super(ref, const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadCategories();
      _subscribeToChanges();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  void _subscribeToChanges() {
    if (_ledgerId == null) return;

    try {
      _categoriesChannel = _repository.subscribeCategories(
        ledgerId: _ledgerId,
        onCategoryChanged: () {
          _refreshCategoriesQuietly();
        },
      );
    } catch (e) {
      debugPrint('Category Realtime subscribe fail: $e');
    }
  }

  Future<void> _refreshCategoriesQuietly() async {
    if (_ledgerId == null) return;

    try {
      final categories = await safeAsync(
        () => _repository.getCategories(_ledgerId),
      );
      if (categories == null) return; // disposed

      safeUpdateState(AsyncValue.data(categories));
      safeInvalidate(categoriesProvider);
    } catch (e) {
      debugPrint('Category refresh fail: $e');
    }
  }

  @override
  void dispose() {
    _categoriesChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> loadCategories() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getCategories(_ledgerId);
      if (mounted) {
        state = AsyncValue.data(categories);
      }
    } catch (e, st) {
      if (mounted) {
        state = AsyncValue.error(e, st);
      }
      rethrow;
    }
  }

  Future<Category> createCategory({
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    try {
      final category = await safeAsync(
        () => _repository.createCategory(
          ledgerId: _ledgerId,
          name: name,
          icon: icon,
          color: color,
          type: type,
        ),
      );

      if (category == null) throw Exception('위젯이 dispose되었습니다');

      safeInvalidate(categoriesProvider);
      await loadCategories();
      return category;
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
      rethrow;
    }
  }

  Future<Category> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    try {
      final result = await safeAsync(
        () => _repository.updateCategory(
          id: id,
          name: name,
          icon: icon,
          color: color,
        ),
      );

      safeInvalidate(categoriesProvider);
      await loadCategories();
      return result!;
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await safeAsync(() => _repository.deleteCategory(id));

      safeInvalidate(categoriesProvider);
      await loadCategories();
    } catch (e) {
      // 에러 발생 시에도 데이터를 다시 로드하여 상태 복구
      await loadCategories();
      rethrow;
    }
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>((ref) {
      final repository = ref.watch(categoryRepositoryProvider);
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      return CategoryNotifier(repository, ledgerId, ref);
    });
