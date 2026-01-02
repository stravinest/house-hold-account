import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budget/presentation/pages/budget_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/add_transaction_sheet.dart';
import '../providers/ledger_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/transaction_list.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // 앱 시작 시 가계부 목록 로드 및 첫 번째 가계부 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLedger();
    });
  }

  Future<void> _initializeLedger() async {
    try {
      final ledgers = await ref.read(ledgersProvider.future);
      if (ledgers.isEmpty) {
        // 가계부가 없으면 기본 가계부 생성
        await ref.read(ledgerNotifierProvider.notifier).createLedger(
              name: '내 가계부',
              currency: 'KRW',
            );
      }
    } catch (e) {
      debugPrint('가계부 초기화 오류: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final ledgersAsync = ref.watch(ledgersProvider);
    final currentLedgerAsync = ref.watch(currentLedgerProvider);

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
            onDateSelected: (date) {
              ref.read(selectedDateProvider.notifier).state = date;
            },
            onPageChanged: (focusedDate) {
              // 월이 변경되면 선택 날짜도 업데이트
              final currentDate = ref.read(selectedDateProvider);
              if (currentDate.year != focusedDate.year ||
                  currentDate.month != focusedDate.month) {
                ref.read(selectedDateProvider.notifier).state = focusedDate;
              }
            },
          ),
          // 통계 탭
          const StatisticsTabView(),
          // 예산 탭
          const BudgetTabView(),
          // 더보기 탭
          const MoreTabView(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddTransactionSheet(context, selectedDate),
        icon: const Icon(Icons.add),
        label: const Text('기록하기'),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
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

  void _showAddTransactionSheet(BuildContext context, DateTime date) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => AddTransactionSheet(initialDate: date),
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
                ref.read(ledgerNotifierProvider.notifier).selectLedger(ledger.id);
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
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;

  const CalendarTabView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.onDateSelected,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 캘린더
        CalendarView(
          selectedDate: selectedDate,
          focusedDate: focusedDate,
          onDateSelected: onDateSelected,
          onPageChanged: onPageChanged,
        ),
        const Divider(height: 1),
        // 선택된 날짜의 거래 목록
        Expanded(
          child: TransactionList(date: selectedDate),
        ),
      ],
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
            // TODO: 카테고리 관리 페이지로 이동
          },
        ),
        ListTile(
          leading: const Icon(Icons.book_outlined),
          title: const Text('가계부 관리'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // TODO: 가계부 관리 페이지로 이동
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
