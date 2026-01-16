import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../config/router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../asset/presentation/pages/asset_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/add_transaction_sheet.dart';
import '../../../transaction/presentation/widgets/quick_expense_sheet.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
import '../../../widget/presentation/providers/widget_provider.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../providers/ledger_provider.dart';
import '../widgets/calendar_view.dart';

class HomePage extends ConsumerStatefulWidget {
  final String? initialTransactionType;
  final bool showQuickExpense;

  const HomePage({
    super.key,
    this.initialTransactionType,
    this.showQuickExpense = false,
  });

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _selectedIndex = 0;
  bool _showUserSummary = true;

  @override
  void initState() {
    super.initState();

    // 앱 시작 시 가계부 목록 로드 및 첫 번째 가계부 자동 생성
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLedger();
      _handleInitialTransactionType();
      _handleQuickExpense();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleInitialTransactionType() {
    if (widget.initialTransactionType != null) {
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

  void _handleQuickExpense() {
    if (widget.showQuickExpense) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => const QuickExpenseSheet(),
        );
      });
    }
  }

  Future<void> _initializeLedger() async {
    final l10n = AppLocalizations.of(context);
    try {
      final ledgers = await ref.read(ledgersProvider.future);
      if (ledgers.isEmpty) {
        await ref
            .read(ledgerNotifierProvider.notifier)
            .createLedger(name: l10n.ledgerMyLedgers, currency: 'KRW');
      }

      // 가계부 초기화 후 데이터 새로고침
      if (mounted) {
        await _refreshCalendarData();
      }
    } on AuthException catch (e) {
      debugPrint('가계부 초기화 오류 (인증): $e');
      if (mounted) {
        _handleAuthError(e);
      }
    } on SocketException catch (e) {
      debugPrint('가계부 초기화 오류 (네트워크): $e');
      if (mounted) {
        _showNetworkError();
      }
    } catch (e) {
      debugPrint('가계부 초기화 오류: $e');
      if (mounted && _isNetworkError(e)) {
        _showNetworkError();
      }
    }
  }

  Future<void> _refreshCalendarData() async {
    ref.invalidate(dailyTransactionsProvider);
    ref.invalidate(monthlyTransactionsProvider);
    ref.invalidate(monthlyTotalProvider);
    ref.invalidate(dailyTotalsProvider);

    // 실제 데이터 로딩 완료를 기다림
    try {
      await Future.wait([
        ref.read(dailyTransactionsProvider.future),
        ref.read(monthlyTransactionsProvider.future),
        ref.read(monthlyTotalProvider.future),
        ref.read(dailyTotalsProvider.future),
      ]);

      // 홈 화면 위젯 데이터 업데이트
      await ref.read(widgetNotifierProvider.notifier).updateWidgetData();
    } on AuthException catch (e) {
      debugPrint('캘린더 새로고침 오류 (인증): $e');
      if (mounted) {
        _handleAuthError(e);
      }
      rethrow;
    } on SocketException catch (e) {
      debugPrint('캘린더 새로고침 오류 (네트워크): $e');
      if (mounted) {
        _showNetworkError();
      }
      rethrow;
    } catch (e) {
      debugPrint('캘린더 새로고침 오류: $e');
      if (mounted && _isNetworkError(e)) {
        _showNetworkError();
      }
      rethrow;
    }
  }

  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('network') ||
        errorString.contains('authretryablefetchexception');
  }

  void _handleAuthError(AuthException error) {
    final l10n = AppLocalizations.of(context);
    final errorMessage = error.message.toLowerCase();

    if (errorMessage.contains('expired') ||
        errorMessage.contains('refresh') ||
        errorMessage.contains('invalid') ||
        error.statusCode == '401') {
      SnackBarUtils.showError(
        context,
        l10n.errorSessionExpired,
        duration: SnackBarDuration.medium,
      );

      Future.delayed(const Duration(seconds: 1), () async {
        await ref.read(authNotifierProvider.notifier).signOut();
      });
    }
  }

  void _showNetworkError() {
    final l10n = AppLocalizations.of(context);
    SnackBarUtils.showError(
      context,
      l10n.errorNetwork,
      duration: SnackBarDuration.short,
    );
  }

  void _handleDateSelected(DateTime date) {
    // 날짜 선택 시 사용자 요약 표시
    setState(() {
      _showUserSummary = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedDate = ref.watch(selectedDateProvider);
    final ledgersAsync = ref.watch(ledgersProvider);

    // 위젯 데이터 자동 업데이트 (월별 합계 변경 시)
    ref.watch(widgetDataUpdaterProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          const Spacer(),
          ledgersAsync.when(
            data: (ledgers) => ledgers.length > 1
                ? IconButton(
                    icon: const Icon(Icons.book),
                    tooltip: l10n.tooltipBook,
                    onPressed: () => _showLedgerSelector(context),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (e, st) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.tooltipSearch,
            onPressed: () {
              context.push(Routes.search);
            },
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.tooltipSettings,
            onPressed: () {
              context.push(Routes.settings);
            },
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const SizedBox(width: 4),
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
          ),
          // 통계 탭
          const StatisticsTabView(),
          // 자산 탭
          const AssetTabView(),
          // 더보기 탭
          const MoreTabView(),
        ],
      ),
      floatingActionButton: _selectedIndex == 1
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddTransactionSheet(context, selectedDate),
              elevation: 6,
              child: const Icon(Icons.add, size: 28),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: NavigationBar(
        height: 56, // 라벨 제거로 높이 축소
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          // 다른 탭에서 캘린더 탭으로 돌아올 때만 새로고침
          final shouldRefresh = index == 0 && _selectedIndex != 0;

          setState(() {
            // 캘린더 탭으로 돌아올 때 사용자 요약 표시
            if (index == 0 && _selectedIndex != 0) {
              _showUserSummary = true;
            }
            _selectedIndex = index;
          });

          if (shouldRefresh) {
            _refreshCalendarData();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: '', // 라벨 숨김
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: '', // 라벨 숨김
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_outlined),
            selectedIcon: Icon(Icons.account_balance),
            label: '', // 라벨 숨김
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: '', // 라벨 숨김
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
    final l10n = AppLocalizations.of(context);

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
              subtitle: Text(
                ledger.isShared ? l10n.ledgerShared : l10n.ledgerPersonal,
              ),
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
        loading: () => ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const SkeletonCircle(size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonLine(
                        width: MediaQuery.of(context).size.width * 0.4,
                        height: 16,
                      ),
                      const SizedBox(height: 8),
                      SkeletonLine(
                        width: MediaQuery.of(context).size.width * 0.25,
                        height: 12,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        error: (e, _) =>
            Center(child: Text(l10n.errorWithMessage(e.toString()))),
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
            // 일일 요약
            if (showUserSummary) ...[
              const Divider(height: 1),
              _DailyUserSummary(date: selectedDate),
            ],
            // FAB가 겹치지 않도록 하단 여백 추가
            const SizedBox(height: 80),
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

// 자산 탭
class AssetTabView extends StatelessWidget {
  const AssetTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AssetPage();
  }
}

// 더보기 탭
class MoreTabView extends ConsumerWidget {
  const MoreTabView({super.key});

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFFA8D8EA);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFA8D8EA);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(currentUserProvider);
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final userColor = profile?['color'] as String?;
    final displayName = profile?['display_name'] as String?;

    return ListView(
      children: [
        ListTile(
          leading: CircleAvatar(
            backgroundColor: _parseColor(userColor),
            child: Text(
              user?.email?.substring(0, 1).toUpperCase() ?? 'U',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(user?.email ?? l10n.user),
          subtitle: displayName != null && displayName.isNotEmpty
              ? Text(displayName)
              : null,
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.people_outline),
          title: Text(l10n.moreMenuShareManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.share);
          },
        ),
        ListTile(
          leading: const Icon(Icons.category_outlined),
          title: Text(l10n.moreMenuCategoryManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.category);
          },
        ),
        ListTile(
          leading: const Icon(Icons.credit_card_outlined),
          title: Text(l10n.moreMenuPaymentMethodManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.paymentMethod);
          },
        ),
        ListTile(
          leading: const Icon(Icons.repeat),
          title: Text(l10n.moreMenuFixedExpenseManagement),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.fixedExpense);
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.settings_outlined),
          title: Text(l10n.settingsTitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            context.push(Routes.settings);
          },
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.authLogout),
          onTap: () async {
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: Text(l10n.authLogout),
                content: Text(l10n.settingsLogoutConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text(l10n.commonCancel),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: Text(l10n.authLogout),
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
    final l10n = AppLocalizations.of(context)!;
    final dailyTransactionsAsync = ref.watch(dailyTransactionsProvider);
    final formatter = NumberFormat('#,###', 'ko_KR');

    return dailyTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return const SizedBox.shrink();
        }

        final Map<String, List<Transaction>> transactionsByUser = {};
        for (final tx in transactions) {
          transactionsByUser.putIfAbsent(tx.userId, () => []).add(tx);
        }

        final List<Widget> transactionRows = [];

        for (final entry in transactionsByUser.entries) {
          final userTransactions = entry.value;

          userTransactions.sort((a, b) => b.amount.compareTo(a.amount));

          for (final tx in userTransactions) {
            final userName = tx.userName ?? l10n.user;
            final colorHex = tx.userColor ?? '#A8D8EA';
            final userColor = _parseColor(colorHex);
            final description = tx.title ?? tx.categoryName ?? l10n.noHistory;
            final isIncome = tx.type == 'income';
            final isAssetType = tx.type == 'asset';

            final colorScheme = Theme.of(context).colorScheme;
            Color amountColor;
            String amountPrefix;
            if (isIncome) {
              amountColor = colorScheme.primary;
              amountPrefix = '';
            } else if (isAssetType) {
              amountColor = colorScheme.tertiary;
              amountPrefix = '';
            } else {
              amountColor = colorScheme.error;
              amountPrefix = '-';
            }

            transactionRows.add(
              GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (context) =>
                        TransactionDetailSheet(transaction: tx),
                  );
                },
                child: Padding(
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
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontSize: 11,
                                color: colorScheme.onSurfaceVariant,
                              ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$amountPrefix${formatter.format(tx.amount)}${l10n.transactionAmountUnit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: amountColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
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
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
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
