import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../data/services/app_badge_service.dart';
import '../../data/services/auto_save_service.dart';
import '../../data/services/native_notification_sync_service.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../category/domain/entities/category.dart';
import '../../../category/presentation/providers/category_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/pending_transaction.dart';
import '../providers/payment_method_provider.dart';
import '../providers/pending_transaction_provider.dart';
import '../widgets/pending_transaction_card.dart';
import '../widgets/permission_request_dialog.dart';
import '../widgets/permission_status_banner.dart';
import 'payment_method_wizard_page.dart';

/// Platform check for Android (cached at app startup)
// Note: Platform.isAndroid is evaluated once at import time.
// For testing, consider using a Provider or passing isAndroid as parameter.
bool get _isAndroidPlatform => Platform.isAndroid;

// _safeParseColor removed - use ColorUtils.parseHexColor instead

/// Badge style constants
const double _badgePaddingH = 6.0;
const double _badgePaddingV = 2.0;
const double _badgeBorderRadius = 10.0;
const double _starIconSize = 14.0;

/// Tab index constant
const int _autoCollectHistoryTabIndex = 1;

/// Date group classification enum
enum _DateGroup { today, yesterday, thisWeek, thisMonth, older }

/// Classify date into group with consistent now reference
_DateGroup _getDateGroup(DateTime date, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  final targetDate = DateTime(date.year, date.month, date.day);
  final difference = today.difference(targetDate).inDays;

  if (difference == 0) return _DateGroup.today;
  if (difference == 1) return _DateGroup.yesterday;
  // thisWeek applies only within 7 days and same year/month (month boundary handling)
  if (difference <= 7 && date.year == now.year && date.month == now.month) {
    return _DateGroup.thisWeek;
  }
  if (date.year == now.year && date.month == now.month) {
    return _DateGroup.thisMonth;
  }
  return _DateGroup.older;
}

/// Convert date group to l10n string
String _getDateGroupLabel(AppLocalizations l10n, _DateGroup group) {
  return switch (group) {
    _DateGroup.today => l10n.dateGroupToday,
    _DateGroup.yesterday => l10n.dateGroupYesterday,
    _DateGroup.thisWeek => l10n.dateGroupThisWeek,
    _DateGroup.thisMonth => l10n.dateGroupThisMonth,
    _DateGroup.older => l10n.dateGroupOlder,
  };
}

/// Group transactions by date with consistent now reference
Map<_DateGroup, List<PendingTransactionModel>> _groupTransactionsByDate(
  List<PendingTransactionModel> transactions,
) {
  final now = DateTime.now(); // Create once for consistency
  final grouped = <_DateGroup, List<PendingTransactionModel>>{};
  for (final tx in transactions) {
    final group = _getDateGroup(tx.sourceTimestamp.toLocal(), now);
    grouped.putIfAbsent(group, () => []).add(tx);
  }
  return grouped;
}

/// Payment method management page (payment method tab + auto-collect history tab)
class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  const PaymentMethodManagementPage({super.key});

  @override
  ConsumerState<PaymentMethodManagementPage> createState() =>
      _PaymentMethodManagementPageState();
}

class _PaymentMethodManagementPageState
    extends ConsumerState<PaymentMethodManagementPage>
    with TickerProviderStateMixin {
  late final TabController _mainTabController;
  late final TabController _autoCollectTabController;
  StreamSubscription<NewNotificationEvent>? _nativeNotificationSubscription;

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
      length: _isAndroidPlatform ? 2 : 1,
      vsync: this,
    );
    _autoCollectTabController = TabController(length: 3, vsync: this);

    // Listener for FAB state update
    _mainTabController.addListener(_onMainTabChanged);

    // 네이티브 알림 이벤트 구독 (배지 실시간 업데이트)
    if (_isAndroidPlatform) {
      _subscribeToNativeNotifications();
    }
  }

  void _subscribeToNativeNotifications() {
    _nativeNotificationSubscription = AutoSaveService
        .instance
        .onNativeNotification
        .listen((event) {
          if (kDebugMode) {
            debugPrint(
              '[PaymentMethodPage] Native notification received, refreshing badge...',
            );
          }
          // Provider invalidate로 배지 카운트 갱신
          ref.invalidate(pendingTransactionCountProvider);
        });
  }

  void _onMainTabChanged() {
    // Process only after animation completes (prevent unnecessary setState)
    if (_mainTabController.indexIsChanging) return;

    // FAB state update
    setState(() {});

    // Mark as viewed when auto-collect history tab is selected (Android only)
    if (_isAndroidPlatform &&
        _mainTabController.index == _autoCollectHistoryTabIndex) {
      _handleAutoCollectTabSelected();
    }
  }

  Future<void> _handleAutoCollectTabSelected() async {
    if (kDebugMode) {
      debugPrint('[TabChanged] Auto-collect tab selected, refreshing data...');
    }
    try {
      await _refreshPendingTransactions();
      await _markAsViewed();

      // 수집내역 탭 진입 시 앱 아이콘 뱃지 제거
      await AppBadgeService.instance.removeBadge();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[TabChanged] Error: $e');
      }
    }
  }

  Future<void> _refreshPendingTransactions() async {
    // Silent refresh: 이미 데이터가 있으면 UI 깜빡임 없이 백그라운드에서 업데이트
    await ref
        .read(pendingTransactionNotifierProvider.notifier)
        .loadPendingTransactions(silent: true);
  }

  Future<void> _markAsViewed() async {
    await ref
        .read(pendingTransactionNotifierProvider.notifier)
        .markAllAsViewed();
  }

  @override
  void dispose() {
    _nativeNotificationSubscription?.cancel();
    _mainTabController.removeListener(_onMainTabChanged);
    _mainTabController.dispose();
    _autoCollectTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pendingCountAsync = ref.watch(pendingTransactionCountProvider);
    final pendingCount = pendingCountAsync.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethodManagement),
        bottom: TabBar(
          controller: _mainTabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurfaceVariant,
          indicatorWeight: 3,
          tabs: [
            Tab(text: l10n.paymentMethodTab),
            // Auto-collect history tab (Android only, with badge)
            if (_isAndroidPlatform)
              Tab(
                child: Semantics(
                  label: pendingCount > 0
                      ? '${l10n.autoCollectTab}, $pendingCount'
                      : l10n.autoCollectTab,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(l10n.autoCollectTab),
                      if (pendingCount > 0) ...[
                        const SizedBox(width: Spacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: _badgePaddingH,
                            vertical: _badgePaddingV,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.error,
                            borderRadius: BorderRadius.circular(
                              _badgeBorderRadius,
                            ),
                          ),
                          constraints: const BoxConstraints(minWidth: 18),
                          child: Text(
                            '$pendingCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: TabBarView(
          controller: _mainTabController,
          children: [
            // Payment method tab (shared + auto-collect integrated)
            _PaymentMethodListView(isAndroid: _isAndroidPlatform),
            // Auto-collect history tab (Android only)
            if (_isAndroidPlatform) _buildAutoCollectHistoryView(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoCollectHistoryView(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Column(
      children: [
        // 2-level tab bar
        Material(
          color: colorScheme.surface,
          elevation: 1,
          child: TabBar(
            controller: _autoCollectTabController,
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorWeight: 2,
            tabs: [
              Tab(text: l10n.pendingTransactionStatusPending),
              Tab(text: l10n.pendingTransactionStatusConfirmed),
              Tab(text: l10n.pendingTransactionStatusRejected),
            ],
          ),
        ),
        // 2-level tab view
        Expanded(
          child: TabBarView(
            controller: _autoCollectTabController,
            children: [
              _PendingTransactionListView(
                status: PendingTransactionStatus.pending,
                tabController: _autoCollectTabController,
              ),
              _PendingTransactionListView(
                status: PendingTransactionStatus.converted,
                tabController: _autoCollectTabController,
              ),
              _PendingTransactionListView(
                status: PendingTransactionStatus.rejected,
                tabController: _autoCollectTabController,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodWizardPage()),
    );
  }
}

/// Payment method list (shared + auto-collect integrated view, Design D)
class _PaymentMethodListView extends ConsumerWidget {
  final bool isAndroid;

  const _PaymentMethodListView({this.isAndroid = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);

    // Show loading if user is not logged in
    if (currentUser == null) {
      return Semantics(
        label: l10n.commonLoading,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final userId = currentUser.id;
    final sharedAsync = ref.watch(sharedPaymentMethodsProvider);
    final autoCollectAsync = ref.watch(
      autoCollectPaymentMethodsByOwnerProvider(userId),
    );

    // Parallel loading handling
    final isLoading = sharedAsync.isLoading || autoCollectAsync.isLoading;
    final error = sharedAsync.error ?? autoCollectAsync.error;

    if (isLoading) {
      return Semantics(
        label: l10n.commonLoading,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      debugPrint('PaymentMethod load error: $error');
      return Center(child: Text(l10n.errorWithMessage(error.toString())));
    }

    final sharedMethods = sharedAsync.value ?? [];
    final autoCollectMethods = autoCollectAsync.value ?? [];
    final hasShared = sharedMethods.isNotEmpty;
    final hasAutoCollect = autoCollectMethods.isNotEmpty;

    if (!hasShared && !hasAutoCollect) {
      return RefreshIndicator(
        onRefresh: () => _refreshPaymentMethods(ref, userId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: Icons.credit_card_outlined,
                message: l10n.paymentMethodEmpty,
                subtitle: l10n.paymentMethodEmptySubtitle,
                action: ElevatedButton.icon(
                  onPressed: () => _showAddDialog(context),
                  icon: const Icon(Icons.add),
                  label: Text(l10n.paymentMethodAdd),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshPaymentMethods(ref, userId),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Shared payment method section (chip style)
            _buildSharedSection(context, sharedMethods, ref, l10n),

            // 2. Auto-collect section (card list, Android only)
            if (isAndroid) ...[
              const SizedBox(height: Spacing.lg),
              _buildAutoCollectSection(context, autoCollectMethods, ref, l10n),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _refreshPaymentMethods(WidgetRef ref, String userId) async {
    // Invalidate providers to trigger refresh
    ref.invalidate(sharedPaymentMethodsProvider);
    ref.invalidate(autoCollectPaymentMethodsByOwnerProvider(userId));
    // Wait for the new data to load
    await Future.wait([
      ref.read(sharedPaymentMethodsProvider.future),
      ref.read(autoCollectPaymentMethodsByOwnerProvider(userId).future),
    ]);
  }

  /// Shared payment method section (chip style)
  Widget _buildSharedSection(
    BuildContext context,
    List<PaymentMethod> methods,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_outline,
                size: IconSize.sm,
                color: colorScheme.primary,
                semanticLabel: l10n.sharedPaymentMethodTitle,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                l10n.sharedPaymentMethodTitle,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showAddSharedDialog(context),
                icon: const Icon(Icons.add, size: IconSize.sm),
                tooltip: l10n.sharedPaymentMethodAdd,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.sharedPaymentMethodDescription,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (methods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Text(
                  l10n.sharedPaymentMethodEmpty,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: Spacing.sm,
              runSpacing: Spacing.sm,
              children: [
                for (final method in methods)
                  _SharedPaymentMethodChip(
                    paymentMethod: method,
                    onTap: () => _showEditDialog(context, method),
                    onDelete: () => _showDeleteConfirm(context, ref, method),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// Auto-collect section (card list)
  Widget _buildAutoCollectSection(
    BuildContext context,
    List<PaymentMethod> methods,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome_outlined,
                size: IconSize.sm,
                color: colorScheme.tertiary,
                semanticLabel: l10n.autoCollectTitle,
              ),
              const SizedBox(width: Spacing.xs),
              Text(
                l10n.autoCollectTitle,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.tertiary,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => _showAddAutoCollectDialog(context),
                icon: const Icon(Icons.add, size: IconSize.sm),
                tooltip: l10n.autoCollectPaymentMethodAdd,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            l10n.autoCollectDescription,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.md),
          if (methods.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.md),
                child: Column(
                  children: [
                    Text(
                      l10n.autoCollectPaymentMethodEmpty,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    OutlinedButton.icon(
                      onPressed: () => _showAddAutoCollectDialog(context),
                      icon: const Icon(Icons.add, size: IconSize.sm),
                      label: Text(l10n.commonAdd),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                for (final method in methods)
                  _AutoCollectPaymentMethodCard(
                    key: ValueKey(method.id),
                    paymentMethod: method,
                    onEdit: () => _showAutoSaveModeDialog(context, method),
                    onDelete: () => _showDeleteConfirm(context, ref, method),
                  ),
                const SizedBox(height: Spacing.md),
                _buildPermissionBanner(context, l10n),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(BuildContext context, AppLocalizations l10n) {
    return PermissionStatusBanner(
      onPermissionDialogRequested: () => _showPermissionDialog(context),
    );
  }

  void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const PermissionRequestDialog(),
    );
  }

  void _showAddDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodWizardPage()),
    );
  }

  void _showAddSharedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddSharedPaymentMethodDialog(),
    );
  }

  void _showAddAutoCollectDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodWizardPage(
          initialMode: PaymentMethodAddMode.autoCollect,
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, PaymentMethod paymentMethod) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentMethodWizardPage(paymentMethod: paymentMethod),
      ),
    );
  }

  void _showDeleteConfirm(
    BuildContext parentContext,
    WidgetRef ref,
    PaymentMethod paymentMethod,
  ) {
    final l10n = AppLocalizations.of(parentContext);
    showDialog(
      context: parentContext,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(BorderRadiusToken.xl),
          ),
          child: Container(
            width: 280,
            padding: const EdgeInsets.all(Spacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 제목
                Text(
                  l10n.paymentMethodDeleteConfirmTitle,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),

                // 결제수단명 박스
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFCDD2),
                    borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                  ),
                  child: Text(
                    paymentMethod.name,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: Spacing.lg),

                // 메시지
                Text(
                  l10n.paymentMethodDeleteConfirmMessage,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: Spacing.lg),

                // 버튼
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 취소 버튼
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: Spacing.md,
                          ),
                        ),
                        child: Text(l10n.commonCancel),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    // 삭제 버튼
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(dialogContext);
                          try {
                            await ref
                                .read(paymentMethodNotifierProvider.notifier)
                                .deletePaymentMethod(paymentMethod.id);

                            // UI 즉시 업데이트를 위해 관련 provider들 invalidate
                            ref.invalidate(sharedPaymentMethodsProvider);
                            final currentUser = ref.read(currentUserProvider);
                            if (currentUser != null) {
                              ref.invalidate(
                                autoCollectPaymentMethodsByOwnerProvider(
                                  currentUser.id,
                                ),
                              );
                            }

                            if (parentContext.mounted) {
                              SnackBarUtils.showSuccess(
                                parentContext,
                                l10n.paymentMethodDeleted,
                              );
                            }
                          } catch (e) {
                            if (parentContext.mounted) {
                              final errorMsg = e.toString().toLowerCase();
                              if (errorMsg.contains('policy') ||
                                  errorMsg.contains('permission') ||
                                  errorMsg.contains('denied') ||
                                  errorMsg.contains('권한') ||
                                  errorMsg.contains('존재하지 않는')) {
                                SnackBarUtils.showError(
                                  parentContext,
                                  l10n.paymentMethodNoPermissionToDelete,
                                );
                              } else {
                                SnackBarUtils.showError(
                                  parentContext,
                                  l10n.paymentMethodDeleteFailed(e.toString()),
                                );
                              }
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.error,
                          foregroundColor: colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            vertical: Spacing.md,
                          ),
                        ),
                        child: Text(l10n.commonDelete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAutoSaveModeDialog(
    BuildContext context,
    PaymentMethod paymentMethod,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            PaymentMethodWizardPage(paymentMethod: paymentMethod),
      ),
    );
  }
}

/// Shared payment method chip (with delete button)
class _SharedPaymentMethodChip extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SharedPaymentMethodChip({
    required this.paymentMethod,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label:
          '${paymentMethod.name}${paymentMethod.isDefault ? ', ${l10n.paymentMethodDefault}' : ''}',
      button: true,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Chip content
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(BorderRadiusToken.circular),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    BorderRadiusToken.circular,
                  ),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      paymentMethod.name,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (paymentMethod.isDefault) ...[
                      const SizedBox(width: Spacing.xs),
                      Icon(
                        Icons.star,
                        size: _starIconSize,
                        color: Colors.amber[700],
                        semanticLabel: l10n.paymentMethodDefault,
                      ),
                    ],
                    const SizedBox(width: Spacing.xs),
                  ],
                ),
              ),
            ),
          ),
          // Delete button (top-right corner)
          Positioned(
            top: -5,
            right: -5,
            child: Semantics(
              label: l10n.commonDelete,
              button: true,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.surfaceContainer,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: colorScheme.surface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Auto-collect payment method card
class _AutoCollectPaymentMethodCard extends StatelessWidget {
  final PaymentMethod paymentMethod;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AutoCollectPaymentMethodCard({
    super.key,
    required this.paymentMethod,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        children: [
          ListTile(
            title: Text(paymentMethod.name),
            subtitle: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: _badgePaddingH,
                    vertical: _badgePaddingV,
                  ),
                  decoration: BoxDecoration(
                    color: paymentMethod.isAutoSaveEnabled
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
                  ),
                  child: Text(
                    _getAutoSaveModeText(l10n, paymentMethod),
                    style: textTheme.labelSmall?.copyWith(
                      color: paymentMethod.isAutoSaveEnabled
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: IconSize.sm),
                  tooltip: l10n.commonEdit,
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete,
                    size: IconSize.sm,
                    semanticLabel: l10n.commonDelete,
                  ),
                  tooltip: l10n.commonDelete,
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getAutoSaveModeText(
    AppLocalizations l10n,
    PaymentMethod paymentMethod,
  ) {
    return switch (paymentMethod.autoSaveMode) {
      AutoSaveMode.manual => l10n.autoSaveModeOff,
      AutoSaveMode.suggest =>
        paymentMethod.autoCollectSource == AutoCollectSource.sms
            ? l10n.autoSaveModeSuggestSms
            : l10n.autoSaveModeSuggestPush,
      AutoSaveMode.auto =>
        paymentMethod.autoCollectSource == AutoCollectSource.sms
            ? l10n.autoSaveModeAutoSms
            : l10n.autoSaveModeAutoPush,
    };
  }
}

/// Pending transaction list view (collection history) - date grouping + detailed card
class _PendingTransactionListView extends ConsumerStatefulWidget {
  final PendingTransactionStatus status;
  final TabController? tabController;

  const _PendingTransactionListView({required this.status, this.tabController});

  @override
  ConsumerState<_PendingTransactionListView> createState() =>
      _PendingTransactionListViewState();
}

class _PendingTransactionListViewState
    extends ConsumerState<_PendingTransactionListView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // KeepAlive를 위해 필수
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // ledgerId와 userId 가져오기
    final ledgerId = ref.watch(selectedLedgerIdProvider);
    final currentUser = ref.watch(currentUserProvider);

    // AsyncValue 상태 확인
    final asyncState = ref.watch(pendingTransactionNotifierProvider);

    final filteredTransactions = switch (widget.status) {
      PendingTransactionStatus.pending => ref.watch(
        pendingTabTransactionsProvider,
      ),
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed => ref.watch(
        confirmedTabTransactionsProvider,
      ),
      PendingTransactionStatus.rejected => ref.watch(
        rejectedTabTransactionsProvider,
      ),
    };

    // ledgerId나 userId가 없으면 빈 상태 표시
    if (ledgerId == null || currentUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Error 상태 처리
    if (asyncState.hasError && filteredTransactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(pendingTransactionNotifierProvider.notifier)
              .loadPendingTransactions();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: colorScheme.error,
                    ),
                    const SizedBox(height: Spacing.md),
                    Text(
                      l10n.errorOccurred,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      l10n.pullToRefresh,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Loading 상태 처리 (초기 로딩만)
    if (asyncState.isLoading && filteredTransactions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (filteredTransactions.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          await ref
              .read(pendingTransactionNotifierProvider.notifier)
              .loadPendingTransactions();
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                message: _getEmptyMessage(l10n, widget.status),
                subtitle: _getEmptySubtitle(l10n, widget.status),
              ),
            ),
          ],
        ),
      );
    }

    // Date grouping (newest first)
    final grouped = _groupTransactionsByDate(filteredTransactions);
    final sortedGroups = grouped.keys.toList()
      ..sort(
        (a, b) => a.index.compareTo(b.index),
      ); // today(0) -> older(4) order

    return Column(
      children: [
        // Action bar (Design C: count + delete all button)
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.pendingTransactionItemCount(filteredTransactions.length),
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showDeleteAllConfirm(
                  context,
                  ref,
                  l10n,
                  filteredTransactions.length,
                ),
                icon: Icon(
                  Icons.delete_sweep_outlined,
                  size: IconSize.sm,
                  color: colorScheme.error,
                  semanticLabel: l10n.pendingTransactionDeleteAll,
                ),
                label: Text(
                  l10n.pendingTransactionDeleteAll,
                  style: TextStyle(color: colorScheme.error),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ],
          ),
        ),
        // List content with pull-to-refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(pendingTransactionNotifierProvider.notifier)
                  .loadPendingTransactions();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(Spacing.md),
              itemCount: sortedGroups.length,
              itemBuilder: (context, groupIndex) {
                final group = sortedGroups[groupIndex];
                // Create new list for immutability and sort by newest first
                final sortedTransactions = grouped[group]!.toList()
                  ..sort(
                    (a, b) => b.sourceTimestamp.compareTo(a.sourceTimestamp),
                  );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date group header
                    Padding(
                      padding: const EdgeInsets.only(
                        top: Spacing.sm,
                        bottom: Spacing.sm,
                      ),
                      child: Text(
                        _getDateGroupLabel(l10n, group),
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Transaction cards
                    for (final tx in sortedTransactions)
                      PendingTransactionCard(
                        key: ValueKey(tx.id),
                        transaction: tx,
                        ledgerId: ledgerId,
                        userId: currentUser.id,
                        onEdit:
                            widget.status == PendingTransactionStatus.pending
                            ? () {
                                _showEditSheet(context, ref, tx);
                              }
                            : null,
                        onReject:
                            widget.status == PendingTransactionStatus.pending
                            ? () => _rejectTransaction(context, ref, tx.id)
                            : null,
                        onConfirm:
                            widget.status == PendingTransactionStatus.pending
                            ? () => _confirmTransaction(context, ref, tx)
                            : null,
                        onDelete: () =>
                            _deletePendingTransaction(context, ref, tx.id),
                        onViewOriginal: tx.isDuplicate
                            ? () {
                                // 원본 거래로 스크롤하거나 표시
                                // TODO: 구현 필요
                              }
                            : null,
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showDeleteAllConfirm(
    BuildContext parentContext,
    WidgetRef ref,
    AppLocalizations l10n,
    int count,
  ) {
    final statusText = _getStatusText(l10n, widget.status);
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pendingTransactionDeleteAllConfirmTitle),
        content: Text(
          l10n.pendingTransactionDeleteAllConfirmMessage(statusText, count),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                final notifier = ref.read(
                  pendingTransactionNotifierProvider.notifier,
                );
                // 확인됨 탭에서는 confirmed + converted 둘 다 삭제
                if (widget.status == PendingTransactionStatus.converted ||
                    widget.status == PendingTransactionStatus.confirmed) {
                  await notifier.deleteAllConfirmed();
                } else {
                  await notifier.deleteAllByStatus(widget.status);
                }
                if (parentContext.mounted) {
                  SnackBarUtils.showSuccess(
                    parentContext,
                    l10n.pendingTransactionDeleteAllSuccess,
                  );
                }
              } catch (e) {
                if (parentContext.mounted) {
                  SnackBarUtils.showError(parentContext, e.toString());
                }
              }
            },
            child: Text(
              l10n.commonDelete,
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(
    AppLocalizations l10n,
    PendingTransactionStatus status,
  ) {
    return switch (status) {
      PendingTransactionStatus.pending => l10n.pendingTransactionStatusPending,
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed =>
        l10n.pendingTransactionStatusConfirmed,
      PendingTransactionStatus.rejected =>
        l10n.pendingTransactionStatusRejected,
    };
  }

  String _getEmptyMessage(
    AppLocalizations l10n,
    PendingTransactionStatus status,
  ) {
    return switch (status) {
      PendingTransactionStatus.pending => l10n.pendingTransactionEmptyPending,
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed =>
        l10n.pendingTransactionEmptyConfirmed,
      PendingTransactionStatus.rejected => l10n.pendingTransactionEmptyRejected,
    };
  }

  String? _getEmptySubtitle(
    AppLocalizations l10n,
    PendingTransactionStatus status,
  ) {
    if (status == PendingTransactionStatus.pending) {
      return l10n.pendingTransactionEmptySubtitle;
    }
    return null;
  }

  void _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    PendingTransactionModel transaction,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _PendingTransactionEditSheet(
        transaction: transaction,
        onConfirmed: () {
          // 확인됨 탭으로 이동 (index 1)
          widget.tabController?.animateTo(1);
        },
        onRejected: () {
          // 거부됨 탭으로 이동 (index 2)
          widget.tabController?.animateTo(2);
        },
      ),
    );
  }

  Future<void> _rejectTransaction(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .rejectTransaction(transactionId);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.pendingTransactionRejected);
        // 거부됨 탭으로 이동 (index 2)
        widget.tabController?.animateTo(2);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }

  Future<void> _confirmTransaction(
    BuildContext context,
    WidgetRef ref,
    PendingTransaction transaction,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .confirmTransaction(transaction.id);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.pendingTransactionConfirmed);
        // 확인됨 탭으로 이동 (index 1)
        widget.tabController?.animateTo(1);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, e.toString());
      }
    }
  }

  Future<void> _deletePendingTransaction(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pendingTransactionDeleteConfirmTitle),
        content: Text(l10n.pendingTransactionDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref
            .read(pendingTransactionNotifierProvider.notifier)
            .deleteTransaction(transactionId);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, l10n.pendingTransactionDeleted);
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, e.toString());
        }
      }
    }
  }
}

/// 대기중 거래 수정/저장/거부 바텀시트
class _PendingTransactionEditSheet extends ConsumerStatefulWidget {
  final PendingTransactionModel transaction;
  final VoidCallback? onConfirmed;
  final VoidCallback? onRejected;

  const _PendingTransactionEditSheet({
    required this.transaction,
    this.onConfirmed,
    this.onRejected,
  });

  @override
  ConsumerState<_PendingTransactionEditSheet> createState() =>
      _PendingTransactionEditSheetState();
}

class _PendingTransactionEditSheetState
    extends ConsumerState<_PendingTransactionEditSheet> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  String? _selectedCategoryId;
  late String _transactionType;
  late DateTime _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.parsedAmount?.toString() ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.transaction.parsedMerchant ?? '',
    );
    _selectedCategoryId = widget.transaction.parsedCategoryId;
    _transactionType = 'expense'; // 자동수집은 항상 지출만 처리
    _selectedDate =
        widget.transaction.parsedDate ?? widget.transaction.sourceTimestamp;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final dateFormat = DateFormat('yyyy-MM-dd');

    // 카테고리 목록 가져오기
    // 자동수집은 항상 지출 카테고리만 사용
    final categoriesAsync = ref.watch(expenseCategoriesProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(BorderRadiusToken.lg),
            ),
          ),
          child: Column(
            children: [
              // 핸들 바
              Container(
                margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  children: [
                    Text(
                      l10n.pendingTransactionDetail,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 내용
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 원본 메시지 표시
                      Container(
                        padding: const EdgeInsets.all(Spacing.md),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(
                            BorderRadiusToken.sm,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  widget.transaction.sourceType ==
                                          SourceType.sms
                                      ? Icons.sms_outlined
                                      : Icons.notifications_outlined,
                                  size: IconSize.sm,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: Spacing.xs),
                                Text(
                                  widget.transaction.sourceSender ?? '',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: Spacing.sm),
                            Text(
                              widget.transaction.sourceContent,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // 금액 입력
                      Text(
                        l10n.transactionAmount,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      TextField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: l10n.transactionAmountHint,
                          suffixText: l10n.transactionAmountUnit,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // 가맹점 입력
                      Text(
                        l10n.transactionMerchant,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      TextField(
                        controller: _merchantController,
                        decoration: InputDecoration(
                          hintText: l10n.transactionMerchantHint,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // 카테고리 선택
                      Text(
                        l10n.transactionCategory,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      categoriesAsync.when(
                        data: (categories) => _buildCategorySelector(
                          context,
                          categories,
                          colorScheme,
                          textTheme,
                        ),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (e, _) =>
                            Text(l10n.errorWithMessage(e.toString())),
                      ),
                      const SizedBox(height: Spacing.lg),

                      // 날짜 선택
                      Text(
                        l10n.labelDate,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: Spacing.sm),
                      InkWell(
                        onTap: () => _selectDate(context),
                        borderRadius: BorderRadius.circular(
                          BorderRadiusToken.sm,
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(Spacing.md),
                          decoration: BoxDecoration(
                            border: Border.all(color: colorScheme.outline),
                            borderRadius: BorderRadius.circular(
                              BorderRadiusToken.sm,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: Spacing.md),
                              Text(
                                dateFormat.format(_selectedDate),
                                style: textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: Spacing.xl),
                    ],
                  ),
                ),
              ),
              // 하단 버튼
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // 거부 버튼 (연한 분홍 배경 + 빨간 텍스트)
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _rejectTransaction,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFFFE4E4),
                            foregroundColor: const Color(0xFFD32F2F),
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                          ),
                          child: Text(l10n.pendingTransactionReject),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      // 수정 버튼 (연한 회색 배경 + 회색 텍스트)
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _updateTransaction,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE8E8E8),
                            foregroundColor: const Color(0xFF666666),
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                          ),
                          child: Text(l10n.pendingTransactionUpdate),
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      // 저장 버튼 (연한 초록 배경 + 초록 텍스트)
                      Expanded(
                        child: FilledButton(
                          onPressed: _isLoading ? null : _confirmTransaction,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE4F5E4),
                            foregroundColor: const Color(0xFF2E7D32),
                            padding: const EdgeInsets.symmetric(
                              vertical: Spacing.md,
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFF2E7D32),
                                    ),
                                  ),
                                )
                              : Text(l10n.pendingTransactionConfirm),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySelector(
    BuildContext context,
    List<Category> categories,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline),
          borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
        ),
        child: Text(
          AppLocalizations.of(context).noCategoryAvailable,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: categories.map((category) {
        final isSelected = _selectedCategoryId == category.id;
        return FilterChip(
          selected: isSelected,
          label: Text(category.name),
          avatar: Text(category.icon),
          onSelected: (selected) {
            setState(() {
              _selectedCategoryId = selected ? category.id : null;
            });
          },
          selectedColor: colorScheme.primaryContainer,
          checkmarkColor: colorScheme.onPrimaryContainer,
        );
      }).toList(),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// 수정 버튼: 변경 내용만 저장하고 대기중 상태 유지
  Future<void> _updateTransaction() async {
    final l10n = AppLocalizations.of(context);
    final amountText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '');
    final amount = int.tryParse(amountText);

    if (amount == null || amount <= 0) {
      SnackBarUtils.showError(context, l10n.transactionAmountRequired);
      return;
    }

    // 최대 금액 제한 (1억원)
    const maxAmount = 100000000;
    if (amount > maxAmount) {
      SnackBarUtils.showError(context, l10n.transactionAmountRequired);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 파싱 데이터만 업데이트하고 상태는 pending 유지
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .updateParsedData(
            id: widget.transaction.id,
            parsedAmount: amount,
            parsedType: _transactionType,
            parsedMerchant: _merchantController.text.trim().isEmpty
                ? null
                : _merchantController.text.trim(),
            parsedCategoryId: _selectedCategoryId,
            parsedDate: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, l10n.pendingTransactionUpdated);
        // 대기중 상태 유지이므로 탭 이동 없음
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  /// 저장 버튼: 거래 생성 및 확인됨 상태로 변경
  Future<void> _confirmTransaction() async {
    final l10n = AppLocalizations.of(context);
    final amountText = _amountController.text
        .replaceAll(',', '')
        .replaceAll(' ', '');
    final amount = int.tryParse(amountText);

    if (amount == null || amount <= 0) {
      SnackBarUtils.showError(context, l10n.transactionAmountRequired);
      return;
    }

    // 최대 금액 제한 (1억원)
    const maxAmount = 100000000;
    if (amount > maxAmount) {
      SnackBarUtils.showError(context, l10n.transactionAmountRequired);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 단일 트랜잭션으로 파싱 데이터 업데이트와 거래 확인 수행
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .updateAndConfirmTransaction(
            id: widget.transaction.id,
            parsedAmount: amount,
            parsedType: _transactionType,
            parsedMerchant: _merchantController.text.trim().isEmpty
                ? null
                : _merchantController.text.trim(),
            parsedCategoryId: _selectedCategoryId,
            parsedDate: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, l10n.pendingTransactionConfirmed);
        widget.onConfirmed?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Future<void> _rejectTransaction() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .rejectTransaction(widget.transaction.id);

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, l10n.pendingTransactionRejected);
        widget.onRejected?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }
}

/// 공유 결제수단 추가 다이얼로그 (카테고리 추가 스타일)
class _AddSharedPaymentMethodDialog extends ConsumerStatefulWidget {
  const _AddSharedPaymentMethodDialog();

  @override
  ConsumerState<_AddSharedPaymentMethodDialog> createState() =>
      _AddSharedPaymentMethodDialogState();
}

class _AddSharedPaymentMethodDialogState
    extends ConsumerState<_AddSharedPaymentMethodDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.sharedPaymentMethodAdd),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          autofocus: true,
          maxLength: 20,
          decoration: InputDecoration(
            labelText: l10n.paymentMethodName,
            hintText: l10n.paymentMethodNameHint,
            border: const OutlineInputBorder(),
            counterText: '',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return l10n.paymentMethodNameRequired;
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        TextButton(onPressed: _submit, child: Text(l10n.commonAdd)),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context);

    try {
      // 공유 결제수단 생성 (canAutoSave = false)
      await ref
          .read(paymentMethodNotifierProvider.notifier)
          .createPaymentMethod(
            name: _nameController.text.trim(),
            canAutoSave: false,
          );

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, l10n.paymentMethodAdded);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }
}
