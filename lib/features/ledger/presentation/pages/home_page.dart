import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budget/presentation/pages/budget_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/add_transaction_sheet.dart';
import '../../../widget/presentation/providers/widget_provider.dart';
import '../providers/ledger_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/transaction_list.dart';

class HomePage extends ConsumerStatefulWidget {
  /// 위젯 딥링크에서 전달받는 초기 거래 타입
  /// 'expense' 또는 'income'
  final String? initialTransactionType;

  const HomePage({super.key, this.initialTransactionType});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  bool _showUserSummary = false;

  @override
  void initState() {
    super.initState();

    // 앱 시작 시 가계부 목록 로드 및 첫 번째 가계부 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLedger();
      // 위젯 딥링크에서 호출된 경우 거래 추가 시트 열기
      _handleInitialTransactionType();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleInitialTransactionType() {
    if (widget.initialTransactionType != null) {
      // 다른 초기화 작업이 완료된 후 시트를 열도록 딜레이 추가
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        final date = ref.read(selectedDateProvider);
        _showAddTransactionSheet(
          context,
          date,
          initialType: widget.initialTransactionType,
        );
      });
    }
  }

  Future<void> _initializeLedger() async {
    try {
      final ledgers = await ref.read(ledgersProvider.future);
      if (ledgers.isEmpty) {
        // 가계부가 없으면 기본 가계부 생성
        await ref
            .read(ledgerNotifierProvider.notifier)
            .createLedger(name: '내 가계부', currency: 'KRW');
      }

      // 오늘 날짜가 선택되어 있으면 자동으로 유저별 요약 표시
      final today = DateTime.now();
      final selectedDate = ref.read(selectedDateProvider);
      final isToday =
          selectedDate.year == today.year &&
          selectedDate.month == today.month &&
          selectedDate.day == today.day;

      if (isToday && mounted) {
        setState(() {
          _showUserSummary = true;
        });
      }
    } catch (e) {
      debugPrint('가계부 초기화 오류: $e');
    }
  }

  Future<void> _refreshCalendarData() async {
    ref.invalidate(dailyTransactionsProvider);
    ref.invalidate(monthlyTransactionsProvider);
    ref.invalidate(monthlyTotalProvider);
    ref.invalidate(dailyTotalsProvider);

    // 실제 데이터 로딩 완료를 기다림
    try {
      await ref.read(dailyTransactionsProvider.future);
      await ref.read(monthlyTransactionsProvider.future);
      await ref.read(monthlyTotalProvider.future);
      await ref.read(dailyTotalsProvider.future);
    } catch (e) {
      // 에러를 상위로 전파하여 RefreshIndicator가 에러 상태를 표시할 수 있도록 함
      debugPrint('캘린더 새로고침 오류: $e');
      rethrow;
    }
  }

  void _handleDateSelected(DateTime date) {
    // 날짜 선택 시 사용자 요약 표시
    setState(() {
      _showUserSummary = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final ledgersAsync = ref.watch(ledgersProvider);
    final currentLedgerAsync = ref.watch(currentLedgerProvider);

    // 위젯 데이터 자동 업데이트 (월별 합계 변경 시)
    ref.watch(widgetDataUpdaterProvider);

    return Scaffold(
      appBar: AppBar(
        title: currentLedgerAsync.when(
          data: (ledger) => Text(ledger?.name ?? '공유 가계부'),
          loading: () => const Text('공유 가계부'),
          error: (e, st) => const Text('공유 가계부'),
        ),
        leading: ledgersAsync.when(
          data: (ledgers) => ledgers.length > 1
              ? IconButton(
                  icon: const Icon(Icons.book),
                  onPressed: () => _showLedgerSelector(context),
                )
              : null,
          loading: () => null,
          error: (e, st) => null,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.push(Routes.search);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              context.push(Routes.settings);
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          // 캘린더 탭
          CalendarTabView(
            selectedDate: selectedDate,
            focusedDate: selectedDate,
            showUserSummary: _showUserSummary,
            onDateSelected: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
              _handleDateSelected(date);
            },
            onPageChanged: (focusedDate) {
              // 월이 변경되면 선택 날짜도 업데이트
              final currentDate = ref.read(selectedDateProvider);
              if (currentDate.year != focusedDate.year ||
                  currentDate.month != focusedDate.month) {
                ref.read(selectedDateProvider.notifier).state = focusedDate;
                // 월 변경 시 사용자 요약 숨김
                setState(() {
                  _showUserSummary = false;
                });
              }
            },
            onRefresh: _refreshCalendarData,
            onAddPressed: () => _showAddTransactionSheet(context, selectedDate),
          ),
          // 통계 탭
          const StatisticsTabView(),
          // 예산 탭
          const BudgetTabView(),
          // 더보기 탭
          const MoreTabView(),
        ],
      ),
      floatingActionButton: _selectedIndex != 0
          ? FloatingActionButton(
              onPressed: () => _showAddTransactionSheet(context, selectedDate),
              mini: true,
              child: const Icon(Icons.add, size: 20),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          // 다른 탭에서 캘린더 탭으로 돌아올 때만 새로고침
          final shouldRefresh = index == 0 && _selectedIndex != 0;

          setState(() {
            _selectedIndex = index;
            // 다른 탭으로 이동하면 사용자 요약 숨김
            if (index != 0) {
              _showUserSummary = false;
            }
          });

          if (shouldRefresh) {
            _refreshCalendarData();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: '예산',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: '더보기',
          ),
        ],
      ),
    );
  }

  void _showAddTransactionSheet(
    BuildContext context,
    DateTime date, {
    String? initialType,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          AddTransactionSheet(initialDate: date, initialType: initialType),
    );
  }

  void _showLedgerSelector(BuildContext context) {
    final ledgersAsync = ref.read(ledgersProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => ledgersAsync.when(
        data: (ledgers) => ListView.builder(
          shrinkWrap: true,
          itemCount: ledgers.length,
          itemBuilder: (context, index) {
            final ledger = ledgers[index];
            final selectedId = ref.read(selectedLedgerIdProvider);
            final isSelected = ledger.id == selectedId;

            return ListTile(
              leading: Icon(
                ledger.isShared ? Icons.people : Icons.person,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Text(ledger.name),
              subtitle: Text(ledger.isShared ? '공유 가계부' : '개인 가계부'),
              trailing: isSelected ? const Icon(Icons.check) : null,
              onTap: () {
                ref
                    .read(ledgerNotifierProvider.notifier)
                    .selectLedger(ledger.id);
                Navigator.pop(context);
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
    );
  }
}

// 캘린더 탭 뷰
class CalendarTabView extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final bool showUserSummary;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onAddPressed;

  const CalendarTabView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.showUserSummary,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onRefresh,
    required this.onAddPressed,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            CalendarView(
              selectedDate: selectedDate,
              focusedDate: focusedDate,
              onDateSelected: onDateSelected,
              onPageChanged: onPageChanged,
              onRefresh: onRefresh,
            ),
            // 일일 요약과 FAB를 Stack으로 배치 (FAB가 위에 떠있음)
            Stack(
              children: [
                // 일일 요약 (아래)
                Column(
                  children: [
                    if (showUserSummary) ...[
                      const Divider(height: 1),
                      _DailyUserSummary(date: selectedDate),
                    ] else
                      const SizedBox(height: 56),
                  ],
                ),
                // FAB (위에 떠있음)
                Positioned(
                  top: 6,
                  right: 5,
                  child: FloatingActionButton(
                    onPressed: onAddPressed,
                    mini: true,
                    child: const Icon(Icons.add, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 통계 탭
class StatisticsTabView extends StatelessWidget {
  const StatisticsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const StatisticsPage();
  }
}

// 예산 탭
class BudgetTabView extends StatelessWidget {
  const BudgetTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const BudgetPage();
  }
}

// 더보기 탭
class MoreTabView extends ConsumerWidget {
  const MoreTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    return ListView(
      children: [
        // 프로필 섹션
        ListTile(
          leading: CircleAvatar(
            child: Text(user?.email?.substring(0, 1).toUpperCase() ?? 'U'),
          ),
          title: Text(user?.email ?? '사용자'),
          subtitle: const Text('프로필 수정'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 프로필 페이지로 이동
          },
        ),
        const Divider(),
        // 메뉴 아이템들
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: const Text('공유 관리'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.share);
          },
        ),
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: const Text('카테고리 관리'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.category);
          },
        ),
        ListTile(
          leading: const Icon(Icons.book_outlined),
          title: const Text('가계부 관리'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.ledgerManage);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: const Text('설정'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.settings);
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('로그아웃'),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('로그아웃'),
                content: const Text('정말 로그아웃하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            );

            if (confirmed == true) {
              await ref.read(authNotifierProvider.notifier).signOut();
            }
          },
        ),
      ],
    );
  }
}

// 일일 사용자별 요약
class _DailyUserSummary extends ConsumerWidget {
  final DateTime date;

  const _DailyUserSummary({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTransactionsAsync = ref.watch(dailyTransactionsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');

    final transactions = dailyTransactionsAsync.valueOrNull ?? [];

    if (transactions.isEmpty) {
      return const SizedBox.shrink();
    }

    // 사용자별로 거래 그룹화
    final Map<String, List<Transaction>> transactionsByUser = {};
    for (final tx in transactions) {
      transactionsByUser.putIfAbsent(tx.userId, () => []).add(tx);
    }

    // 모든 거래 행 생성
    final List<Widget> transactionRows = [];

    for (final entry in transactionsByUser.entries) {
      final userId = entry.key;
      final userTransactions = entry.value;

      // 금액 순으로 정렬
      userTransactions.sort((a, b) => b.amount.compareTo(a.amount));

      for (final tx in userTransactions) {
        final userName = tx.userName ?? '사용자';
        final colorHex = tx.userColor ?? '#A8D8EA';
        final userColor = _parseColor(colorHex);
        final description = tx.memo ?? tx.categoryName ?? '내역 없음';
        final isIncome = tx.type == 'income';

        transactionRows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: userColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  userName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncome ? '' : '-'}${formatter.format(tx.amount)}원',
                  style: TextStyle(
                    fontSize: 11,
                    color: isIncome
                        ? Colors.blue.shade700
                        : Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: transactionRows,
      ),
    );
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFFA8D8EA);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFA8D8EA);
    }
  }
}
