import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/safe_notifier.dart';

import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../ledger/presentation/providers/calendar_view_provider.dart';
import '../../../widget/presentation/providers/widget_provider.dart';
import '../../../fixed_expense/presentation/providers/fixed_expense_settings_provider.dart'
    show fixedExpenseSettingsProvider;
import '../../data/repositories/transaction_repository.dart';
import '../../domain/entities/transaction.dart';
import 'recurring_template_provider.dart';

// Repository 프로바이더
final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

// 거래 업데이트 트리거 (버전 관리용)
final transactionUpdateTriggerProvider = StateProvider<int>((ref) => 0);

// 선택된 날짜
final selectedDateProvider = StateProvider<DateTime>((ref) => DateTime.now());

// 선택된 날짜의 거래 목록
final dailyTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getTransactionsByDate(ledgerId: ledgerId, date: date);
});

// 일별 합계 (사용자별 데이터 포함)
final dailyTotalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final transactionsAsync = ref.watch(dailyTransactionsProvider);
  final transactions = transactionsAsync.valueOrNull ?? [];

  int income = 0;
  int expense = 0;
  int asset = 0;
  final Map<String, Map<String, dynamic>> users = {};

  for (final tx in transactions) {
    final userId = tx.userId;
    final userName = tx.userName ?? 'Unknown';
    final userColor = tx.userColor ?? '#A8D8EA';

    if (!users.containsKey(userId)) {
      users[userId] = {
        'displayName': userName,
        'color': userColor,
        'income': 0,
        'expense': 0,
        'asset': 0,
      };
    }

    switch (tx.type) {
      case 'income':
        income += tx.amount;
        users[userId]!['income'] =
            (users[userId]!['income'] as int) + tx.amount;
        break;
      case 'expense':
        expense += tx.amount;
        users[userId]!['expense'] =
            (users[userId]!['expense'] as int) + tx.amount;
        break;
      case 'asset':
        asset += tx.amount;
        users[userId]!['asset'] = (users[userId]!['asset'] as int) + tx.amount;
        break;
    }
  }

  return {
    'income': income,
    'expense': expense,
    'asset': asset,
    'balance': income - expense,
    'users': users,
  };
});

// 현재 월의 거래 목록
final monthlyTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getTransactionsByMonth(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
  );
});

// 현재 월 합계 (사용자별 데이터 포함)
final monthlyTotalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
  }

  final date = ref.watch(selectedDateProvider);
  final repository = ref.watch(transactionRepositoryProvider);
  final settings = await ref.watch(fixedExpenseSettingsProvider.future);
  final includeFixed = settings?.includeInExpense ?? false;

  return repository.getMonthlyTotal(
    ledgerId: ledgerId,
    year: date.year,
    month: date.month,
    excludeFixedExpense: !includeFixed,
  );
});

// 일별 합계 (캘린더용, 사용자별 데이터 포함)
final dailyTotalsProvider = FutureProvider<Map<DateTime, Map<String, dynamic>>>(
  (ref) async {
    final ledgerId = ref.watch(selectedLedgerIdProvider);
    if (ledgerId == null) return {};

    final date = ref.watch(selectedDateProvider);
    final repository = ref.watch(transactionRepositoryProvider);
    final settings = await ref.watch(fixedExpenseSettingsProvider.future);
    final includeFixed = settings?.includeInExpense ?? false;

    return repository.getDailyTotals(
      ledgerId: ledgerId,
      year: date.year,
      month: date.month,
      excludeFixedExpense: !includeFixed,
    );
  },
);

// 주별 거래 조회를 위한 선택된 주 범위 Provider
final selectedWeekStartProvider = Provider<DateTime>((ref) {
  final date = ref.watch(selectedDateProvider);
  final weekStartDay = ref.watch(weekStartDayProvider);
  // weekStartDayProvider 설정에 따라 주의 첫째 날 계산
  final weekRange = getWeekRangeFor(date, weekStartDay);
  return weekRange.start;
});

// 주별 거래 목록
final weeklyTransactionsProvider = FutureProvider<List<Transaction>>((
  ref,
) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final weekStart = ref.watch(selectedWeekStartProvider);
  final weekEnd = weekStart.add(const Duration(days: 6));
  final repository = ref.watch(transactionRepositoryProvider);

  return repository.getTransactionsByDateRange(
    ledgerId: ledgerId,
    startDate: weekStart,
    endDate: weekEnd,
  );
});

// 주별 합계 (사용자별 데이터 포함)
final weeklyTotalProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final transactionsAsync = ref.watch(weeklyTransactionsProvider);
  final transactions = transactionsAsync.valueOrNull ?? [];

  int income = 0;
  int expense = 0;
  int asset = 0;
  final Map<String, Map<String, dynamic>> users = {};

  for (final tx in transactions) {
    final userId = tx.userId;
    final userName = tx.userName ?? 'Unknown';
    final userColor = tx.userColor ?? '#A8D8EA';

    if (!users.containsKey(userId)) {
      users[userId] = {
        'displayName': userName,
        'color': userColor,
        'income': 0,
        'expense': 0,
        'asset': 0,
      };
    }

    switch (tx.type) {
      case 'income':
        income += tx.amount;
        users[userId]!['income'] =
            (users[userId]!['income'] as int) + tx.amount;
        break;
      case 'expense':
        expense += tx.amount;
        users[userId]!['expense'] =
            (users[userId]!['expense'] as int) + tx.amount;
        break;
      case 'asset':
        asset += tx.amount;
        users[userId]!['asset'] = (users[userId]!['asset'] as int) + tx.amount;
        break;
    }
  }

  return {
    'income': income,
    'expense': expense,
    'asset': asset,
    'balance': income - expense,
    'users': users,
  };
});

// 거래 관리 노티파이어
class TransactionNotifier extends SafeNotifier<List<Transaction>> {
  final TransactionRepository _repository;
  final String? _ledgerId;

  TransactionNotifier(this._repository, this._ledgerId, Ref ref)
    : super(ref, const AsyncValue.loading()) {
    if (_ledgerId != null) {
      loadTransactions();
    } else {
      state = const AsyncValue.data([]);
    }
  }

  Future<void> loadTransactions() async {
    if (_ledgerId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final date = ref.read(selectedDateProvider);
      final transactions = await safeAsync(
        () =>
            _repository.getTransactionsByDate(ledgerId: _ledgerId, date: date),
      );
      if (transactions == null) return;
      safeUpdateState(AsyncValue.data(transactions));
    } catch (e, st) {
      safeUpdateState(AsyncValue.error(e, st));
    }
  }

  Future<Transaction> createTransaction({
    String? categoryId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime date,
    String? title,
    String? memo,
    String? imageUrl,
    bool isRecurring = false,
    String? recurringType,
    DateTime? recurringEndDate,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
    bool isAsset = false,
    DateTime? maturityDate,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    final transaction = await safeAsync(
      () => _repository.createTransaction(
        ledgerId: _ledgerId,
        categoryId: categoryId,
        paymentMethodId: paymentMethodId,
        amount: amount,
        type: type,
        date: date,
        title: title,
        memo: memo,
        imageUrl: imageUrl,
        isRecurring: isRecurring,
        recurringType: recurringType,
        recurringEndDate: recurringEndDate,
        isFixedExpense: isFixedExpense,
        fixedExpenseCategoryId: fixedExpenseCategoryId,
        isAsset: isAsset,
        maturityDate: maturityDate,
      ),
    );

    if (transaction == null) throw Exception('위젯이 dispose되었습니다');

    // 데이터 갱신
    safeInvalidateAll([
      dailyTransactionsProvider,
      monthlyTransactionsProvider,
      monthlyTotalProvider,
      dailyTotalsProvider,
      recurringTemplatesProvider,
    ]);

    // 자산 거래인 경우 자산 통계도 갱신
    if (type == 'asset') {
      safeInvalidate(assetStatisticsProvider);
    }

    // 데이터 재계산 완료를 기다린 후 위젯 업데이트
    final monthlyTotal = await safeAsync(
      () => ref.read(monthlyTotalProvider.future),
    );
    if (monthlyTotal == null) return transaction;

    await safeAsync(
      () => ref.read(widgetNotifierProvider.notifier).updateWidgetData(),
    );

    // 트랜잭션 업데이트 트리거 발생 (가벼운 갱신용)
    if (mounted) {
      ref.read(transactionUpdateTriggerProvider.notifier).state++;
    }

    return transaction;
  }

  Future<void> updateTransaction({
    required String id,
    String? categoryId,
    String? paymentMethodId,
    int? amount,
    String? type,
    DateTime? date,
    String? title,
    String? memo,
    String? imageUrl,
    bool? isRecurring,
    String? recurringType,
    DateTime? recurringEndDate,
    bool? isFixedExpense,
    String? fixedExpenseCategoryId,
  }) async {
    await safeAsync(
      () => _repository.updateTransaction(
        id: id,
        categoryId: categoryId,
        paymentMethodId: paymentMethodId,
        amount: amount,
        type: type,
        date: date,
        title: title,
        memo: memo,
        imageUrl: imageUrl,
        isRecurring: isRecurring,
        recurringType: recurringType,
        recurringEndDate: recurringEndDate,
        isFixedExpense: isFixedExpense,
        fixedExpenseCategoryId: fixedExpenseCategoryId,
      ),
    );

    // 데이터 갱신
    safeInvalidateAll([
      dailyTransactionsProvider,
      monthlyTransactionsProvider,
      monthlyTotalProvider,
      dailyTotalsProvider,
      recurringTemplatesProvider,
    ]);

    // 자산 거래인 경우 자산 통계도 갱신
    if (type == 'asset') {
      safeInvalidate(assetStatisticsProvider);
    }

    // 데이터 재계산 완료를 기다린 후 위젯 업데이트
    await safeAsync(() => ref.read(monthlyTotalProvider.future));
    await safeAsync(
      () => ref.read(widgetNotifierProvider.notifier).updateWidgetData(),
    );

    // 트랜잭션 업데이트 트리거 발생
    if (mounted) {
      ref.read(transactionUpdateTriggerProvider.notifier).state++;
    }
  }

  Future<void> deleteTransaction(String id) async {
    await safeAsync(() => _repository.deleteTransaction(id));

    // 데이터 갱신
    safeInvalidateAll([
      dailyTransactionsProvider,
      monthlyTransactionsProvider,
      monthlyTotalProvider,
      dailyTotalsProvider,
      recurringTemplatesProvider,
    ]);

    // 자산 통계도 갱신 (자산 거래가 아닐 경우 무시됨)
    safeInvalidate(assetStatisticsProvider);

    // 데이터 재계산 완료를 기다린 후 위젯 업데이트
    await safeAsync(() => ref.read(monthlyTotalProvider.future));
    await safeAsync(
      () => ref.read(widgetNotifierProvider.notifier).updateWidgetData(),
    );

    // 트랜잭션 업데이트 트리거 발생
    if (mounted) {
      ref.read(transactionUpdateTriggerProvider.notifier).state++;
    }
  }

  // 반복 거래 삭제 + 템플릿 비활성화 (이후 모든 반복 중단)
  Future<void> deleteTransactionAndStopRecurring(
    String transactionId,
    String templateId,
  ) async {
    await safeAsync(
      () => _repository.deleteTransactionAndDeactivateTemplate(
        transactionId,
        templateId,
      ),
    );

    safeInvalidateAll([
      dailyTransactionsProvider,
      monthlyTransactionsProvider,
      monthlyTotalProvider,
      dailyTotalsProvider,
      recurringTemplatesProvider,
    ]);

    safeInvalidate(assetStatisticsProvider);

    await safeAsync(() => ref.read(monthlyTotalProvider.future));
    await safeAsync(
      () => ref.read(widgetNotifierProvider.notifier).updateWidgetData(),
    );

    if (mounted) {
      ref.read(transactionUpdateTriggerProvider.notifier).state++;
    }
  }

  // 반복 거래 템플릿 생성 및 오늘까지 거래 자동 생성
  Future<void> createRecurringTemplate({
    String? categoryId,
    String? paymentMethodId,
    required int amount,
    required String type,
    required DateTime startDate,
    DateTime? endDate,
    required String recurringType,
    String? title,
    String? memo,
    bool isFixedExpense = false,
    String? fixedExpenseCategoryId,
  }) async {
    if (_ledgerId == null) throw Exception('가계부를 선택해주세요');

    // 1. 템플릿 생성
    await _repository.createRecurringTemplate(
      ledgerId: _ledgerId,
      categoryId: categoryId,
      paymentMethodId: paymentMethodId,
      amount: amount,
      type: type,
      startDate: startDate,
      endDate: endDate,
      recurringType: recurringType,
      title: title,
      memo: memo,
      isFixedExpense: isFixedExpense,
      fixedExpenseCategoryId: fixedExpenseCategoryId,
    );

    // 2. 오늘까지의 거래 자동 생성 (DB 함수 호출)
    await _repository.generateRecurringTransactions();

    // 데이터 갱신
    safeInvalidateAll([
      dailyTransactionsProvider,
      monthlyTransactionsProvider,
      monthlyTotalProvider,
      dailyTotalsProvider,
      recurringTemplatesProvider,
    ]);

    // 데이터 재계산 완료를 기다린 후 위젯 업데이트
    await safeAsync(() => ref.read(monthlyTotalProvider.future));
    await safeAsync(
      () => ref.read(widgetNotifierProvider.notifier).updateWidgetData(),
    );

    // 트랜잭션 업데이트 트리거 발생
    if (mounted) {
      ref.read(transactionUpdateTriggerProvider.notifier).state++;
    }
  }
}

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>((
      ref,
    ) {
      final repository = ref.watch(transactionRepositoryProvider);
      final ledgerId = ref.watch(selectedLedgerIdProvider);
      return TransactionNotifier(repository, ledgerId, ref);
    });
