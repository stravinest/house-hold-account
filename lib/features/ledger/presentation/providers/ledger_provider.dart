import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  RealtimeChannel? _ledgersChannel;
  RealtimeChannel? _membersChannel;

  LedgerNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadLedgers();
    _subscribeToChanges();
  }

  void _subscribeToChanges() {
    try {
      // ledgers 테이블 변경 구독
      _ledgersChannel = _repository.subscribeLedgers((ledgers) {
        state = AsyncValue.data(ledgers);
      });

      // ledger_members 테이블 변경 구독 (멤버 나감/들어옴 감지)
      _membersChannel = _repository.subscribeLedgerMembers(() {
        // 로딩 상태 없이 데이터만 새로고침
        _refreshLedgersQuietly();
      });
    } catch (e) {
      // Realtime 구독 실패 시 무시 (기본 기능에는 영향 없음)
      debugPrint('Realtime 구독 실패: $e');
    }
  }

  // 로딩 상태 없이 데이터만 새로고침 (UI 깜빡임 방지)
  Future<void> _refreshLedgersQuietly() async {
    try {
      final ledgers = await _repository.getLedgers();
      state = AsyncValue.data(ledgers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  @override
  void dispose() {
    _ledgersChannel?.unsubscribe();
    _membersChannel?.unsubscribe();
    super.dispose();
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
    final wasSelected = selectedId == id;

    if (wasSelected) {
      _ref.read(selectedLedgerIdProvider.notifier).state = null;
    }

    await loadLedgers();

    // 삭제 후 남은 가계부가 있고, 삭제된 가계부가 선택되어 있었다면 첫 번째 가계부 자동 선택
    if (wasSelected) {
      final currentState = state;
      if (currentState is AsyncData<List<Ledger>>) {
        final ledgers = currentState.value;
        if (ledgers.isNotEmpty) {
          _ref.read(selectedLedgerIdProvider.notifier).state = ledgers.first.id;
        }
      }
    }
  }

  void selectLedger(String id) {
    _ref.read(selectedLedgerIdProvider.notifier).state = id;
  }

  // 멤버 수에 따라 공유 상태 동기화
  // 멤버가 1명이면 개인 가계부, 2명 이상이면 공유 가계부
  Future<void> syncShareStatus({
    required String ledgerId,
    required int memberCount,
    required bool currentIsShared,
  }) async {
    final shouldBeShared = memberCount >= 2;

    // 현재 상태와 다르면 업데이트
    if (currentIsShared != shouldBeShared) {
      await _repository.updateLedger(
        id: ledgerId,
        isShared: shouldBeShared,
      );
      // Realtime 구독이 자동으로 데이터를 새로고침하므로 별도 호출 불필요
    }
  }
}

final ledgerNotifierProvider =
    StateNotifierProvider<LedgerNotifier, AsyncValue<List<Ledger>>>((ref) {
  final repository = ref.watch(ledgerRepositoryProvider);
  return LedgerNotifier(repository, ref);
});
