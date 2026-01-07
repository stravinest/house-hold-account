import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../data/services/widget_data_service.dart';

/// 위젯 초기화 상태
final widgetInitializedProvider = FutureProvider<bool>((ref) async {
  await WidgetDataService.initialize();
  return true;
});

/// 위젯 데이터 업데이트 Provider
///
/// 월별 합계 데이터가 변경될 때 자동으로 위젯 데이터를 업데이트합니다.
final widgetDataUpdaterProvider = Provider<void>((ref) {
  // 월별 합계 데이터 감시
  final monthlyTotalAsync = ref.watch(monthlyTotalProvider);
  final currentLedger = ref.watch(currentLedgerProvider);

  monthlyTotalAsync.whenData((monthlyTotal) {
    final ledgerName = currentLedger.valueOrNull?.name ?? '가계부';
    final income = monthlyTotal['income'] ?? 0;
    final expense = monthlyTotal['expense'] ?? 0;

    // 위젯 데이터 업데이트
    WidgetDataService.updateWidgetData(
      monthlyExpense: expense,
      monthlyIncome: income,
      ledgerName: ledgerName,
    );
  });
});

/// 위젯 데이터 수동 업데이트
class WidgetNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  WidgetNotifier(this._ref) : super(const AsyncValue.data(null));

  /// 위젯 데이터 수동 업데이트
  Future<void> updateWidgetData() async {
    state = const AsyncValue.loading();
    try {
      final monthlyTotal = await _ref.read(monthlyTotalProvider.future);
      final currentLedger = _ref.read(currentLedgerProvider);
      final ledgerName = currentLedger.valueOrNull?.name ?? '가계부';

      await WidgetDataService.updateWidgetData(
        monthlyExpense: monthlyTotal['expense'] ?? 0,
        monthlyIncome: monthlyTotal['income'] ?? 0,
        ledgerName: ledgerName,
      );

      state = const AsyncValue.data(null);
    } catch (e, st) {
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
