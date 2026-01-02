import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// 카테고리 관리 노티파이어
class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;
  final String? _ledgerId;

  CategoryNotifier(this._repository, this._ledgerId)
      : super(const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadCategories();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadCategories() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final categories = await _repository.getCategories(_ledgerId);
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Category> createCategory({
    required String name,
    required String icon,
    required String color,
    required String type,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    final category = await _repository.createCategory(
      ledgerId: _ledgerId,
      name: name,
      icon: icon,
      color: color,
      type: type,
    );

    await loadCategories();
    return category;
  }

  Future<void> updateCategory({
    required String id,
    String? name,
    String? icon,
    String? color,
  }) async {
    await _repository.updateCategory(
      id: id,
      name: name,
      icon: icon,
      color: color,
    );
    await loadCategories();
  }

  Future<void> deleteCategory(String id) async {
    await _repository.deleteCategory(id);
    await loadCategories();
  }
}

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, AsyncValue<List<Category>>>((ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  return CategoryNotifier(repository, ledgerId);
});
