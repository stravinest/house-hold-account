import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/providers/safe_notifier.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/fixed_expense_category_repository.dart';
import '../../domain/entities/fixed_expense_category.dart';

// Repository 프로바이더
final fixedExpenseCategoryRepositoryProvider =
    Provider<FixedExpenseCategoryRepository>((ref) {
      return FixedExpenseCategoryRepository();
    });

// 현재 가계부의 고정비 카테고리 목록
final fixedExpenseCategoriesProvider =
    FutureProvider<List<FixedExpenseCategory>>((ref) async {
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      if (ledgerId == null) return [];

      final repository = ref.watch(fixedExpenseCategoryRepositoryProvider);
      return repository.getCategories(ledgerId);
    });

// 고정비 카테고리 관리 노티파이어
class FixedExpenseCategoryNotifier
    extends SafeNotifier<List<FixedExpenseCategory>> {
  final FixedExpenseCategoryRepository _repository;
  final String? _ledgerId;
  RealtimeChannel? _categoriesChannel;

  FixedExpenseCategoryNotifier(this._repository, this._ledgerId, Ref ref)
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
      debugPrint('FixedExpenseCategory Realtime subscribe fail: $e');
    }
  }

  Future<void> _refreshCategoriesQuietly() async {
    if (_ledgerId == null) return;

    try {
      final categories = await safeAsync(
        () => _repository.getCategories(_ledgerId),
      );
      if (categories == null) return;

      safeUpdateState(AsyncValue.data(categories));
      safeInvalidate(fixedExpenseCategoriesProvider);
    } catch (e) {
      debugPrint('FixedExpenseCategory refresh fail: $e');
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

  Future<FixedExpenseCategory> createCategory({
    required String name,
    String icon = '',
    required String color,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    try {
      final category = await safeAsync(
        () => _repository.createCategory(
          ledgerId: _ledgerId,
          name: name,
          icon: icon,
          color: color,
        ),
      );

      if (category == null) throw Exception('위젯이 dispose되었습니다');

      safeInvalidate(fixedExpenseCategoriesProvider);
      await loadCategories();
      return category;
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
      rethrow;
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    String? icon,
    String? color,
  }) async {
    try {
      await safeAsync(
        () => _repository.updateCategory(
          id: id,
          name: name,
          icon: icon,
          color: color,
        ),
      );

      safeInvalidate(fixedExpenseCategoriesProvider);
      await loadCategories();
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
      rethrow;
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await safeAsync(() => _repository.deleteCategory(id));

      safeInvalidate(fixedExpenseCategoriesProvider);
      await loadCategories();
    } catch (e) {
      // 에러 발생 시에도 데이터를 다시 로드하여 상태 복구
      await loadCategories();
      rethrow;
    }
  }
}

final fixedExpenseCategoryNotifierProvider =
    StateNotifierProvider.autoDispose<
      FixedExpenseCategoryNotifier,
      AsyncValue<List<FixedExpenseCategory>>
    >((ref) {
      final repository = ref.watch(fixedExpenseCategoryRepositoryProvider);
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      return FixedExpenseCategoryNotifier(repository, ledgerId, ref);
    });
