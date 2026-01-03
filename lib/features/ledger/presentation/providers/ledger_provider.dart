import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/ledger_repository.dart';
import '../../domain/entities/ledger.dart';

// Repository 프로바이더
final ledgerRepositoryProvider = Provider<LedgerRepository>((ref) {
  return LedgerRepository();
});

// 현재 선택된 가계부 ID
final selectedLedgerIdProvider = StateProvider<String?>((ref) => null);

// 사용자의 가계부 목록
final ledgersProvider = FutureProvider<List<Ledger>>((ref) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  final ledgers = await repository.getLedgers();

  // 선택된 가계부가 없고, 가계부가 있으면 첫 번째 가계부 선택
  final selectedId = ref.read(selectedLedgerIdProvider);
  if (selectedId == null && ledgers.isNotEmpty) {
    ref.read(selectedLedgerIdProvider.notifier).state = ledgers.first.id;
  }

  return ledgers;
});

// 현재 선택된 가계부
final currentLedgerProvider = FutureProvider<Ledger?>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return null;

  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getLedger(ledgerId);
});

// 가계부 멤버 목록
final ledgerMembersProvider =
    FutureProvider.family<List<LedgerMember>, String>((ref, ledgerId) async {
  final repository = ref.watch(ledgerRepositoryProvider);
  return repository.getMembers(ledgerId);
});

// 가계부 관리 노티파이어
class LedgerNotifier extends StateNotifier<AsyncValue<List<Ledger>>> {
  final LedgerRepository _repository;
  final Ref _ref;

  LedgerNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadLedgers();
  }

  Future<void> loadLedgers() async {
    state = const AsyncValue.loading();
    try {
      final ledgers = await _repository.getLedgers();
      state = AsyncValue.data(ledgers);

      // 선택된 가계부가 없고, 가계부가 있으면 첫 번째 가계부 선택
      final selectedId = _ref.read(selectedLedgerIdProvider);
      if (selectedId == null && ledgers.isNotEmpty) {
        _ref.read(selectedLedgerIdProvider.notifier).state = ledgers.first.id;
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Ledger> createLedger({
    required String name,
    String? description,
    String currency = 'KRW',
  }) async {
    final ledger = await _repository.createLedger(
      name: name,
      description: description,
      currency: currency,
    );

    await loadLedgers();

    // 새로 생성한 가계부 선택
    _ref.read(selectedLedgerIdProvider.notifier).state = ledger.id;

    return ledger;
  }

  Future<void> updateLedger({
    required String id,
    String? name,
    String? description,
    String? currency,
    bool? isShared,
  }) async {
    await _repository.updateLedger(
      id: id,
      name: name,
      description: description,
      currency: currency,
      isShared: isShared,
    );
    await loadLedgers();
  }

  Future<void> deleteLedger(String id) async {
    await _repository.deleteLedger(id);

    // 삭제한 가계부가 현재 선택된 가계부면 선택 해제
    final selectedId = _ref.read(selectedLedgerIdProvider);
    if (selectedId == id) {
      _ref.read(selectedLedgerIdProvider.notifier).state = null;
    }

    await loadLedgers();
  }

  void selectLedger(String id) {
    _ref.read(selectedLedgerIdProvider.notifier).state = id;
  }
}

final ledgerNotifierProvider =
    StateNotifierProvider<LedgerNotifier, AsyncValue<List<Ledger>>>((ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return LedgerNotifier(repository, ref);
});
