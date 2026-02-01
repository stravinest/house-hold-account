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
import '../../../asset/presentation/providers/asset_goal_provider.dart';
import '../../../asset/presentation/providers/asset_provider.dart';
import '../../../asset/presentation/pages/asset_page.dart';
import '../../../statistics/presentation/pages/statistics_page.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/providers/transaction_provider.dart';
import '../../../transaction/presentation/widgets/add_transaction_sheet.dart';
import '../../../transaction/presentation/widgets/quick_expense_sheet.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
import '../../../widget/presentation/providers/widget_provider.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../domain/entities/ledger.dart';
import '../../../share/presentation/providers/share_provider.dart';
import '../providers/ledger_provider.dart';
import '../providers/calendar_view_provider.dart';
import '../widgets/calendar_view.dart';
import '../widgets/calendar_month_summary.dart';
import '../widgets/calendar_view_mode_selector.dart';
import '../widgets/daily_view.dart';
import '../widgets/weekly_view.dart';

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
      if (!mounted) return;
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

      if (!mounted) return;

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

    // 가계부 Provider 초기화 및 자동 선택 로직 실행
    // (앱 시작 시 저장된 가계부 ID 복원 또는 첫 번째 가계부 자동 선택)
    ref.watch(ledgerNotifierProvider);

    // 위젯 데이터 자동 업데이트 (월별 합계 변경 시)
    ref.watch(widgetDataUpdaterProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        titleSpacing: Spacing.sm,
        leading: ledgersAsync.when(
          data: (ledgers) => ledgers.length > 1
              ? IconButton(
                  icon: const Icon(Icons.book),
                  tooltip: l10n.tooltipBook,
                  onPressed: () => _showLedgerSelector(context),
                )
              : null,
          loading: () => null,
          error: (e, st) => null,
        ),
        title: _selectedIndex == 0
            ? Consumer(
                builder: (context, ref, _) {
                  final viewMode = ref.watch(calendarViewModeProvider);
                  return CalendarViewModeSelector(
                    selectedMode: viewMode,
                    onModeChanged: (mode) {
                      ref
                          .read(calendarViewModeProvider.notifier)
                          .setViewMode(mode);
                    },
                  );
                },
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.tooltipSearch,
            onPressed: () {
              context.push(Routes.search);
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: l10n.tooltipSettings,
            onPressed: () {
              context.push(Routes.settings);
            },
          ),
          const SizedBox(width: Spacing.xs),
        ],
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: IndexedStack(
          index: _selectedIndex,
          children: [
            CalendarTabView(
              selectedDate: selectedDate,
              focusedDate: selectedDate,
              showUserSummary: _showUserSummary,
              onDateSelected: (date) {
                ref.read(selectedDateProvider.notifier).state = date;
                _handleDateSelected(date);
              },
              onPageChanged: (focusedDate) {
                final currentDate = ref.read(selectedDateProvider);
                if (currentDate.year != focusedDate.year ||
                    currentDate.month != focusedDate.month) {
                  ref.read(selectedDateProvider.notifier).state = focusedDate;
                  setState(() {
                    _showUserSummary = false;
                  });
                }
              },
              onRefresh: _refreshCalendarData,
            ),
            const StatisticsTabView(),
            const AssetTabView(),
            const MoreTabView(),
          ],
        ),
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
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
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

          // 자산 탭 클릭 시 자산 데이터 새로고침
          if (index == 2) {
            final ledgerId = ref.read(selectedLedgerIdProvider);
            if (ledgerId != null) {
              ref.invalidate(assetGoalNotifierProvider(ledgerId));
              ref.invalidate(assetStatisticsProvider);
            }
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.calendar_today_outlined),
            selectedIcon: const Icon(Icons.calendar_today),
            label: l10n.navTabCalendar,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.navTabStatistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_outlined),
            selectedIcon: const Icon(Icons.account_balance),
            label: l10n.navTabAsset,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            selectedIcon: const Icon(Icons.more_horiz),
            label: l10n.navTabMore,
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
    final currentUserId = ref.read(currentUserProvider)?.id;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        final colorScheme = Theme.of(context).colorScheme;
        // 네비게이션 바 높이 + 시스템 패딩 고려
        final safeBottomPadding =
            bottomPadding + kBottomNavigationBarHeight + Spacing.sm;

        return ledgersAsync.when(
          data: (ledgers) {
            final selectedId = ref.read(selectedLedgerIdProvider);

            // 내 가계부 / 공유 가계부로 분류
            // - 내 가계부: 내가 owner이고 isShared = false
            // - 공유 가계부: 내가 owner가 아니거나 isShared = true
            final myLedgers = ledgers
                .where((l) => l.ownerId == currentUserId && !l.isShared)
                .toList();
            final sharedLedgers = ledgers
                .where((l) => l.ownerId != currentUserId || l.isShared)
                .toList();

            Widget buildSectionHeader(String title) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.xs,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            // 가계부 변경 확인 다이얼로그
            Future<void> showChangeConfirmDialog(Ledger ledger) async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(l10n.ledgerChangeConfirmTitle),
                  content: Text(l10n.ledgerChangeConfirmMessage(ledger.name)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.commonNo),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.commonYes),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                ref
                    .read(ledgerNotifierProvider.notifier)
                    .selectLedger(ledger.id);
                Navigator.pop(context);
              }
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 내 가계부 섹션
                if (myLedgers.isNotEmpty) ...[
                  buildSectionHeader(l10n.ledgerSelectorMyLedgers),
                  ...myLedgers.map(
                    (ledger) => _buildLedgerTile(
                      context,
                      ledger: ledger,
                      isSelected: ledger.id == selectedId,
                      isShared: false,
                      l10n: l10n,
                      onTap: () {
                        if (ledger.id == selectedId) {
                          Navigator.pop(context);
                        } else {
                          showChangeConfirmDialog(ledger);
                        }
                      },
                    ),
                  ),
                ],

                // 공유 가계부 섹션
                if (sharedLedgers.isNotEmpty) ...[
                  if (myLedgers.isNotEmpty) const Divider(height: 1),
                  buildSectionHeader(l10n.ledgerSelectorSharedLedgers),
                  ...sharedLedgers.map(
                    (ledger) => Consumer(
                      builder: (context, ref, _) {
                        final membersAsync = ref.watch(
                          ledgerMembersProvider(ledger.id),
                        );
                        final memberNames = membersAsync.maybeWhen(
                          data: (members) => members
                              .where((m) => m.userId != currentUserId)
                              .map((m) => m.displayName ?? m.email ?? '')
                              .where((name) => name.isNotEmpty)
                              .toList(),
                          orElse: () => <String>[],
                        );

                        return _buildLedgerTile(
                          context,
                          ledger: ledger,
                          isSelected: ledger.id == selectedId,
                          isShared: true,
                          l10n: l10n,
                          sharedMemberNames: memberNames,
                          onTap: () {
                            if (ledger.id == selectedId) {
                              Navigator.pop(context);
                            } else {
                              showChangeConfirmDialog(ledger);
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
                SizedBox(height: safeBottomPadding),
              ],
            );
          },
          loading: () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: 3,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm + Spacing.xs,
                  ),
                  child: Row(
                    children: [
                      const SkeletonCircle(size: 40),
                      const SizedBox(width: Spacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SkeletonLine(
                              width: MediaQuery.of(context).size.width * 0.4,
                              height: Spacing.md,
                            ),
                            const SizedBox(height: Spacing.sm),
                            SkeletonLine(
                              width: MediaQuery.of(context).size.width * 0.25,
                              height: Spacing.sm + Spacing.xs,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: safeBottomPadding),
            ],
          ),
          error: (e, _) =>
              Center(child: Text(l10n.errorWithMessage(e.toString()))),
        );
      },
    );
  }

  Widget _buildLedgerTile(
    BuildContext context, {
    required Ledger ledger,
    required bool isSelected,
    required bool isShared,
    required AppLocalizations l10n,
    required VoidCallback onTap,
    List<String>? sharedMemberNames,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // 아이콘 색상: 선택됨 = 컬러, 미선택 = 회색
    final Color iconBackgroundColor;
    final Color iconColor;

    if (isSelected) {
      // 선택됨: 내 가계부 = primary, 공유 가계부 = tertiary
      iconBackgroundColor = isShared
          ? colorScheme.tertiaryContainer
          : colorScheme.primaryContainer;
      iconColor = isShared
          ? colorScheme.onTertiaryContainer
          : colorScheme.onPrimaryContainer;
    } else {
      // 미선택: 회색
      iconBackgroundColor = colorScheme.surfaceContainerHighest;
      iconColor = colorScheme.onSurfaceVariant;
    }

    // 공유 가계부일 때 멤버 이름으로 subtitle 생성
    String subtitle;
    if (isShared && sharedMemberNames != null && sharedMemberNames.isNotEmpty) {
      if (sharedMemberNames.length == 1) {
        subtitle = l10n.ledgerSharedWithOne(sharedMemberNames[0]);
      } else if (sharedMemberNames.length == 2) {
        subtitle = l10n.ledgerSharedWithTwo(
          sharedMemberNames[0],
          sharedMemberNames[1],
        );
      } else {
        subtitle = l10n.ledgerSharedWithMany(
          sharedMemberNames[0],
          sharedMemberNames[1],
          sharedMemberNames.length - 2,
        );
      }
    } else {
      subtitle = isShared ? l10n.ledgerShared : l10n.ledgerPersonal;
    }

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBackgroundColor,
          borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
        ),
        child: Icon(
          isShared ? Icons.people : Icons.person,
          color: iconColor,
          size: 20,
        ),
      ),
      title: Text(
        ledger.name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

// 캘린더 탭 뷰
class CalendarTabView extends ConsumerStatefulWidget {
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
  ConsumerState<CalendarTabView> createState() => _CalendarTabViewState();
}

class _CalendarTabViewState extends ConsumerState<CalendarTabView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _calendarKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTransactionList() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final calendarContext = _calendarKey.currentContext;
      if (calendarContext == null) return;

      final calendarBox = calendarContext.findRenderObject() as RenderBox?;
      if (calendarBox == null) return;

      // CalendarView 높이 + Divider(1px)만큼 스크롤하면
      // DailyDateHeader가 고정된 Summary 바로 아래에 위치 (Divider 숨김)
      final calendarHeight = calendarBox.size.height;
      const dividerHeight = 1.0;

      _scrollController.animateTo(
        calendarHeight + dividerHeight,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void didUpdateWidget(CalendarTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final viewMode = ref.read(calendarViewModeProvider);
    // 월별 뷰에서만 날짜가 변경되고 사용자 요약이 표시되는 경우 스크롤
    if (viewMode == CalendarViewMode.monthly &&
        widget.showUserSummary &&
        (oldWidget.selectedDate != widget.selectedDate ||
            !oldWidget.showUserSummary)) {
      _scrollToTransactionList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewMode = ref.watch(calendarViewModeProvider);
    // 뷰 모드 전환 시 날짜 변경 불필요
    // - WeeklyView가 selectedDate로 주 범위를 자체 계산
    // - 날짜 변경 시 Provider 연쇄 업데이트로 화면 흔들림 발생
    return _buildViewContent(viewMode);
  }

  Widget _buildViewContent(CalendarViewMode viewMode) {
    switch (viewMode) {
      case CalendarViewMode.daily:
        return DailyView(
          selectedDate: widget.selectedDate,
          onDateChanged: widget.onDateSelected,
          onRefresh: widget.onRefresh,
        );
      case CalendarViewMode.weekly:
        return WeeklyView(
          selectedDate: widget.selectedDate,
          onDateChanged: widget.onDateSelected,
          onRefresh: widget.onRefresh,
        );
      case CalendarViewMode.monthly:
        return _MonthlyViewContent(
          selectedDate: widget.selectedDate,
          focusedDate: widget.focusedDate,
          showUserSummary: widget.showUserSummary,
          onDateSelected: widget.onDateSelected,
          onPageChanged: widget.onPageChanged,
          onRefresh: widget.onRefresh,
          scrollController: _scrollController,
          calendarKey: _calendarKey,
          scrollToTransactionList: _scrollToTransactionList,
        );
    }
  }
}

// 월별 뷰 콘텐츠 (기존 CalendarTabView의 내용)
class _MonthlyViewContent extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime focusedDate;
  final bool showUserSummary;
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<DateTime> onPageChanged;
  final Future<void> Function() onRefresh;
  final ScrollController scrollController;
  final GlobalKey calendarKey;
  final VoidCallback scrollToTransactionList;

  const _MonthlyViewContent({
    required this.selectedDate,
    required this.focusedDate,
    required this.showUserSummary,
    required this.onDateSelected,
    required this.onPageChanged,
    required this.onRefresh,
    required this.scrollController,
    required this.calendarKey,
    required this.scrollToTransactionList,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 고정 헤더: 수입 | 지출 | 합계
        Consumer(
          builder: (context, ref, child) {
            // 실제 멤버 수 사용 (실시간 반영을 위해 isShared 대신 직접 조회)
            final memberCount = ref.watch(currentLedgerMemberCountProvider);

            return RepaintBoundary(
              child: CalendarMonthSummary(
                focusedDate: focusedDate,
                memberCount: memberCount,
              ),
            );
          },
        ),
        // 스크롤 가능한 영역
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scrollAreaHeight = constraints.maxHeight;

              return RefreshIndicator(
                onRefresh: onRefresh,
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      CalendarView(
                        key: calendarKey,
                        selectedDate: selectedDate,
                        focusedDate: focusedDate,
                        onDateSelected: onDateSelected,
                        onPageChanged: onPageChanged,
                        onRefresh: onRefresh,
                        showSummary: false,
                      ),
                      // 일일 요약
                      if (showUserSummary) ...[
                        const Divider(height: 1),
                        _DailyDateHeader(date: selectedDate),
                        _DailyUserSummary(date: selectedDate),
                      ],
                      // 스크롤 가능하도록 최소 높이 보장
                      SizedBox(height: scrollAreaHeight - 80),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// 날짜 헤더 위젯 (impCdDayHeader 디자인 적용)
class _DailyDateHeader extends StatelessWidget {
  final DateTime date;

  const _DailyDateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // 포맷: "2026년 1월 17일 토요일"
    final dateFormatter = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR');
    final dateText = dateFormatter.format(date);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surfaceContainer,
      child: Text(
        dateText,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
    final dailyTransactionsAsync = ref.watch(dailyTransactionsProvider);
    final formatter = NumberFormat('#,###', 'ko_KR');

    return dailyTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.lg,
            ),
            child: Center(
              child: Text(
                l10n.calendarNoRecords,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
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
            final categoryDisplay =
                tx.categoryName ?? l10n.categoryUncategorized;
            final String description;
            if (tx.title != null && tx.title!.isNotEmpty) {
              description = '$categoryDisplay · ${tx.title}';
            } else {
              description = categoryDisplay;
            }
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

            // 월별 뷰 거래 항목 (일/주 뷰와 일관된 디자인)
            transactionRows.add(
              Material(
                color: colorScheme.surface,
                child: InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      builder: (context) =>
                          TransactionDetailSheet(transaction: tx),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: userColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            description,
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$amountPrefix${formatter.format(tx.amount)}${l10n.transactionAmountUnit}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: amountColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: transactionRows,
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
