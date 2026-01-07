import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../config/router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../budget/presentation/pages/budget_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
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

class _HomePageState extends ConsumerState<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _showPanel = false;
  late AnimationController _panelAnimationController;
  late Animation<double> _panelAnimation;
  DateTime? _lastSelectedDate;
  bool _showUserSummary = false;

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _panelAnimation = CurvedAnimation(
      parent: _panelAnimationController,
      curve: Curves.easeInOut,
    );

    // 앱 시작 시 가계부 목록 로드 및 첫 번째 가계부 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLedger();
      // 위젯 딥링크에서 호출된 경우 거래 추가 시트 열기
      _handleInitialTransactionType();
    });
  }

  @override
  void dispose() {
    _panelAnimationController.dispose();
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
        await ref.read(ledgerNotifierProvider.notifier).createLedger(
              name: '내 가계부',
              currency: 'KRW',
            );
      }

      // 오늘 날짜가 선택되어 있으면 자동으로 유저별 요약 표시
      final today = DateTime.now();
      final selectedDate = ref.read(selectedDateProvider);
      final isToday = selectedDate.year == today.year &&
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
    // 이전에 선택된 날짜와 비교 (년월일만)
    final isSameDate = _lastSelectedDate != null &&
        _lastSelectedDate!.year == date.year &&
        _lastSelectedDate!.month == date.month &&
        _lastSelectedDate!.day == date.day;

    if (isSameDate) {
      // 같은 날짜 재클릭 -> 패널 토글
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        final transactionsAsync = ref.read(dailyTransactionsProvider);
        final hasTransactions =
            transactionsAsync.valueOrNull?.isNotEmpty ?? false;

        if (!hasTransactions) {
          // 거래가 없으면 패널을 표시하지 않음
          return;
        }

        if (!_showPanel) {
          // 패널 표시
          _panelAnimationController.stop();
          setState(() {
            _showPanel = true;
          });
          _panelAnimationController.forward(from: 0.0);
        } else {
          // 패널 숨김
          _panelAnimationController.stop();
          _panelAnimationController.value = 0.0;
          setState(() {
            _showPanel = false;
          });
        }
      });
    } else {
      // 다른 날짜 클릭 -> 패널 숨김, 사용자 요약 표시
      if (_showPanel) {
        _panelAnimationController.stop();
        _panelAnimationController.value = 0.0;
      }

      setState(() {
        _showPanel = false;
        _showUserSummary = true;
      });

      // 현재 날짜를 이전 날짜로 저장
      _lastSelectedDate = DateTime(date.year, date.month, date.day);
    }
  }

  void _closePanel() {
    if (!_showPanel) return;

    // 즉시 숨김 처리
    _panelAnimationController.stop();
    _panelAnimationController.value = 0.0;
    setState(() {
      _showPanel = false;
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
      body: Stack(
        children: [
          // 메인 컨텐츠
          IndexedStack(
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
              ),
              // 통계 탭
              const StatisticsTabView(),
              // 예산 탭
              const BudgetTabView(),
              // 더보기 탭
              const MoreTabView(),
            ],
          ),
          // 슬라이드 패널
          if (_showPanel && _selectedIndex == 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(_panelAnimation),
                child: _DailyTransactionPanel(
                  date: selectedDate,
                  onClose: _closePanel,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionSheet(context, selectedDate),
        mini: true,
        child: const Icon(Icons.add, size: 20),
      ),
      floatingActionButtonLocation: _selectedIndex == 0
          ? const _CalendarBottomRightFabLocation()
          : FloatingActionButtonLocation.endFloat,
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
      builder: (context) => AddTransactionSheet(
        initialDate: date,
        initialType: initialType,
      ),
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
  final bool showUserSummary;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;
  final Future<void> Function() onRefresh;

  const CalendarTabView({
    super.key,
    required this.selectedDate,
    required this.focusedDate,
    required this.showUserSummary,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onRefresh,
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
            if (showUserSummary) ...[
              const Divider(height: 1),
              _DailyUserSummary(date: selectedDate),
            ],
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
    final dailyTotalsAsync = ref.watch(dailyTotalsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');

    final normalizedDate = DateTime(date.year, date.month, date.day);
    final totals = dailyTotalsAsync.valueOrNull?[normalizedDate];

    if (totals == null || totals['users'] == null) {
      return const SizedBox.shrink();
    }

    final users = totals['users'] as Map<String, dynamic>;
    if (users.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: users.entries.take(3).map((entry) {
          final userData = entry.value as Map<String, dynamic>;
          final userName = userData['displayName'] as String? ?? '사용자';
          final colorHex = userData['color'] as String? ?? '#A8D8EA';
          final userColor = _parseColor(colorHex);
          final income = userData['income'] as int? ?? 0;
          final expense = userData['expense'] as int? ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 8),
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (income > 0) ...[
                        Text(
                          '수입 ${formatter.format(income)}원',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blue.shade700,
                          ),
                        ),
                        if (expense > 0) const SizedBox(width: 8),
                      ],
                      if (expense > 0)
                        Text(
                          '지출 ${formatter.format(expense)}원',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.red.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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

// 일일 거래 패널 (슬라이드)
class _DailyTransactionPanel extends ConsumerWidget {
  final DateTime date;
  final VoidCallback onClose;

  const _DailyTransactionPanel({
    required this.date,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(dailyTransactionsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', 'ko_KR');

    return Container(
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.4,
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          transactionsAsync.when(
            data: (transactions) {
              final income = transactions
                  .where((t) => t.isIncome)
                  .fold<int>(0, (sum, t) => sum + t.amount);
              final expense = transactions
                  .where((t) => !t.isIncome)
                  .fold<int>(0, (sum, t) => sum + t.amount);
              final balance = income - expense;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      DateFormat('M월 d일 (E)', 'ko_KR').format(date),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '수입 ${formatter.format(income)}원',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(' | ', style: TextStyle(fontSize: 11)),
                          Text(
                            '지출 ${formatter.format(expense)}원',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                            ),
                          ),
                          const Text(' | ', style: TextStyle(fontSize: 11)),
                          Text(
                            '합계 ${formatter.format(balance)}원',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: onClose,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('로딩 중...'),
            ),
            error: (e, st) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: const Text('오류 발생'),
            ),
          ),

          // 거래 목록
          Expanded(
            child: transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Text('거래 내역이 없습니다'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final categoryColor = _parseColor(
                      transaction.categoryColor,
                    ) ?? colorScheme.primaryContainer;

                    return ListTile(
                      dense: true,
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: categoryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            transaction.categoryIcon ?? '📦',
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          if (transaction.userName != null) ...[
                            Text(
                              transaction.userName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.outline,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Expanded(
                            child: Text(
                              transaction.memo ?? '메모 없음',
                              style: const TextStyle(fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      subtitle: transaction.categoryName != null
                          ? Text(
                              transaction.categoryName!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            )
                          : null,
                      trailing: Text(
                        '${formatter.format(transaction.amount)}원',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: transaction.isIncome ? Colors.blue : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (e, st) => Center(
                child: Text('오류: $e'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color? _parseColor(String? colorStr) {
    if (colorStr == null) return null;
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return null;
    }
  }
}

// 달력 맨 아래 맨 오른쪽 칸에 FAB 배치
class _CalendarBottomRightFabLocation extends FloatingActionButtonLocation {
  const _CalendarBottomRightFabLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX = _getCalendarRightColumnCenter(scaffoldGeometry);
    final double fabY = _getCalendarBottomRowCenter(scaffoldGeometry);

    return Offset(fabX, fabY);
  }

  double _getCalendarRightColumnCenter(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final screenWidth = scaffoldGeometry.scaffoldSize.width;
    final columnWidth = screenWidth / 7;
    final rightColumnCenter = columnWidth * 6.5;
    final fabWidth = scaffoldGeometry.floatingActionButtonSize.width;
    return rightColumnCenter - (fabWidth / 2);
  }

  double _getCalendarBottomRowCenter(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    const double monthSummaryHeight = 80.0;
    const double customHeaderHeight = 64.0;
    const double daysOfWeekHeight = 40.0;
    const double rowHeight = 70.0;
    const int lastRowIndex = 5;

    final calendarTop = monthSummaryHeight + customHeaderHeight + daysOfWeekHeight;
    // 달력 마지막 행 아래 한 칸의 중앙에 배치
    final lastRowCenter = calendarTop + (rowHeight * (lastRowIndex + 1)) + (rowHeight / 2);
    final fabHeight = scaffoldGeometry.floatingActionButtonSize.height;

    return lastRowCenter - (fabHeight / 2);
  }
}
