import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/models/category_keyword_mapping_model.dart';
import '../../data/repositories/category_keyword_mapping_repository.dart';

final categoryKeywordMappingRepositoryProvider =
    Provider<CategoryKeywordMappingRepository>((ref) {
      return CategoryKeywordMappingRepository();
    });

// paymentMethodId + sourceType 기반 조회 Provider
final categoryKeywordMappingsProvider = FutureProvider.family<
  List<CategoryKeywordMappingModel>,
  ({String paymentMethodId, String? sourceType})
>((ref, params) async {
  final repository = ref.watch(categoryKeywordMappingRepositoryProvider);
  return repository.getByPaymentMethod(
    params.paymentMethodId,
    sourceType: params.sourceType,
  );
});

// ledgerId 기반 전체 조회 Provider
final categoryKeywordMappingsByLedgerProvider = FutureProvider.family<
  List<CategoryKeywordMappingModel>,
  ({String ledgerId, String? sourceType})
>((ref, params) async {
  final repository = ref.watch(categoryKeywordMappingRepositoryProvider);
  return repository.getByLedger(
    params.ledgerId,
    sourceType: params.sourceType,
  );
});

class CategoryKeywordMappingNotifier
    extends StateNotifier<AsyncValue<List<CategoryKeywordMappingModel>>> {
  final CategoryKeywordMappingRepository _repository;
  final String? _paymentMethodId;
  final Ref _ref;

  CategoryKeywordMappingNotifier(
    this._repository,
    this._paymentMethodId,
    this._ref,
  ) : super(const AsyncValue.loading()) {
    if (_paymentMethodId != null) {
      loadMappings();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadMappings({String? sourceType}) async {
    if (_paymentMethodId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final mappings = await _repository.getByPaymentMethod(
        _paymentMethodId,
        sourceType: sourceType,
      );
      state = AsyncValue.data(mappings);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> create({
    required String ledgerId,
    required String keyword,
    required String categoryId,
    required String sourceType,
    required String createdBy,
  }) async {
    if (_paymentMethodId == null) return;

    try {
      await _repository.create(
        paymentMethodId: _paymentMethodId,
        ledgerId: ledgerId,
        keyword: keyword,
        categoryId: categoryId,
        sourceType: sourceType,
        createdBy: createdBy,
      );

      _ref.invalidate(
        categoryKeywordMappingsProvider((
          paymentMethodId: _paymentMethodId,
          sourceType: null,
        )),
      );
      await loadMappings();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CategoryKeywordMappingNotifier] create failed: $e');
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repository.delete(id);

      if (_paymentMethodId != null) {
        _ref.invalidate(
          categoryKeywordMappingsProvider((
            paymentMethodId: _paymentMethodId,
            sourceType: null,
          )),
        );
      }
      await loadMappings();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[CategoryKeywordMappingNotifier] delete failed: $e');
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final categoryKeywordMappingNotifierProvider = StateNotifierProvider.family
    .autoDispose<
      CategoryKeywordMappingNotifier,
      AsyncValue<List<CategoryKeywordMappingModel>>,
      String?
    >((ref, paymentMethodId) {
      final repository = ref.watch(categoryKeywordMappingRepositoryProvider);
      return CategoryKeywordMappingNotifier(repository, paymentMethodId, ref);
    });

// 현재 선택된 가계부의 키워드 매핑 조회 (편의용)
final currentLedgerKeywordMappingsProvider = FutureProvider.family<
  List<CategoryKeywordMappingModel>,
  String?
>((ref, sourceType) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final currentUser = ref.watch(currentUserProvider);
  if (currentUser == null) return [];

  final repository = ref.watch(categoryKeywordMappingRepositoryProvider);
  return repository.getByLedger(ledgerId, sourceType: sourceType);
});
