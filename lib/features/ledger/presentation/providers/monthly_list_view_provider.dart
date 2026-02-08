import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';

/// 월간 뷰 타입 (캘린더 또는 리스트)
enum MonthlyViewType { calendar, list }

/// 거래 필터 타입
enum TransactionFilter {
  all, // 전체
  recurring, // 고정비
  income, // 수입
  expense, // 지출
  asset, // 자산
}

/// 월간 뷰 타입 관리 StateNotifier
/// SharedPreferences를 사용하여 사용자 선택을 지속적으로 저장
class MonthlyViewTypeNotifier extends StateNotifier<MonthlyViewType> {
  MonthlyViewTypeNotifier() : super(MonthlyViewType.calendar) {
    _loadViewType();
  }

  static const String _key = 'monthly_view_type';

  /// 저장된 뷰 타입 로드
  Future<void> _loadViewType() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    if (value == 'list') {
      state = MonthlyViewType.list;
    }
  }

  /// 뷰 타입 토글
  Future<void> toggle() async {
    state = state == MonthlyViewType.calendar
        ? MonthlyViewType.list
        : MonthlyViewType.calendar;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, state.name);
  }
}

/// 월간 뷰 타입 Provider
final monthlyViewTypeProvider =
    StateNotifierProvider<MonthlyViewTypeNotifier, MonthlyViewType>((ref) {
  return MonthlyViewTypeNotifier();
});

/// 선택된 필터 Set Provider (복수 선택 가능)
final selectedFiltersProvider = StateProvider<Set<TransactionFilter>>((ref) {
  return {TransactionFilter.all}; // 기본값: 전체 선택
});

/// 필터링된 월간 거래 Provider
final filteredMonthlyTransactionsProvider =
    Provider<AsyncValue<List<Transaction>>>((ref) {
  final monthlyTransactionsAsync = ref.watch(monthlyTransactionsProvider);
  final selectedFilters = ref.watch(selectedFiltersProvider);

  return monthlyTransactionsAsync.when(
    data: (transactions) {
      // '전체' 필터가 선택되어 있으면 모든 거래 반환
      if (selectedFilters.contains(TransactionFilter.all)) {
        return AsyncValue.data(transactions);
      }

      // 선택된 필터에 따라 OR 조건으로 필터링
      final filtered = transactions.where((tx) {
        // 고정비 필터: isFixedExpense 속성 확인
        if (selectedFilters.contains(TransactionFilter.recurring) &&
            tx.isFixedExpense) {
          return true;
        }
        // 수입 필터
        if (selectedFilters.contains(TransactionFilter.income) &&
            tx.type == 'income') {
          return true;
        }
        // 지출 필터
        if (selectedFilters.contains(TransactionFilter.expense) &&
            tx.type == 'expense') {
          return true;
        }
        // 자산 필터
        if (selectedFilters.contains(TransactionFilter.asset) &&
            tx.type == 'asset') {
          return true;
        }
        return false;
      }).toList();

      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
