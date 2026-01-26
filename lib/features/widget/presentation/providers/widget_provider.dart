import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../data/services/widget_data_service.dart';

/// 위젯 초기화 상태
final widgetInitializedProvider = FutureProvider<bool>((ref) async {
  await WidgetDataService.initialize();
  return true;
});

final widgetDataUpdaterProvider = Provider<void>((ref) {
  final monthlyTotalAsync = ref.watch(monthlyTotalProvider);
  final currentLedger = ref.watch(currentLedgerProvider);

  monthlyTotalAsync.whenData((monthlyTotal) {
    final ledgerName = currentLedger.valueOrNull?.name ?? '가계부';
    final income = monthlyTotal['income'] ?? 0;
    final expense = monthlyTotal['expense'] ?? 0;

    if (kDebugMode) {
      debugPrint('[Widget] Auto update: income=$income, expense=$expense');
    }

    // 현재 프레임 완료 후 위젯 업데이트 실행
    // Navigator가 잠긴 상태에서 위젯 트리 변경 방지
    SchedulerBinding.instance.addPostFrameCallback((_) {
      WidgetDataService.updateWidgetData(
        monthlyExpense: expense,
        monthlyIncome: income,
        ledgerName: ledgerName,
      );
    });
  });
});

/// 위젯 데이터 수동 업데이트
class WidgetNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WidgetNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 위젯 데이터 수동 업데이트
  /// 항상 현재 월(이번 달) 데이터를 가져옴 (selectedDateProvider와 무관)
  Future<void> updateWidgetData() async {
    state = const AsyncValue.loading();
    try {
      final ledgerId = _ref.read(selectedLedgerIdProvider);
      final currentLedger = _ref.read(currentLedgerProvider);
      final ledgerName = currentLedger.valueOrNull?.name ?? '가계부';

      if (ledgerId == null) {
        debugPrint('[Widget] No ledger selected, skipping widget update');
        state = const AsyncValue.data(null);
        return;
      }

      // 항상 현재 월 데이터를 직접 조회 (selectedDateProvider 무시)
      final now = DateTime.now();
      final repository = _ref.read(transactionRepositoryProvider);
      final monthlyTotal = await repository.getMonthlyTotal(
        ledgerId: ledgerId,
        year: now.year,
        month: now.month,
      );

      final expense = monthlyTotal['expense'] ?? 0;
      final income = monthlyTotal['income'] ?? 0;

      debugPrint(
        '[Widget] Manual update (current month): '
        'expense=$expense, income=$income',
      );

      await WidgetDataService.updateWidgetData(
        monthlyExpense: expense,
        monthlyIncome: income,
        ledgerName: ledgerName,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
      debugPrint('[Widget] Update failed: $e');
      state = AsyncValue.error(e, st);
    }
  }

  /// 위젯 데이터 초기화 (로그아웃 시)
  Future<void> clearWidgetData() async {
    await WidgetDataService.clearWidgetData();
  }
}

final widgetNotifierProvider =
    StateNotifierProvider<WidgetNotifier, AsyncValue<void>>((ref) {
      return WidgetNotifier(ref);
    });
