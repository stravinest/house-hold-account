import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/utils/color_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/pending_transaction.dart';
import '../providers/payment_method_provider.dart';
import '../providers/pending_transaction_provider.dart';
import '../widgets/auto_save_mode_dialog.dart';
import '../widgets/permission_request_dialog.dart';
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

/// Tab index constants
const int _paymentMethodTabIndex = 0;
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
  if (date.year == now.year && date.month == now.month) return _DateGroup.thisMonth;
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
Map<_DateGroup, List<PendingTransaction>> _groupTransactionsByDate(
  List<PendingTransaction> transactions,
) {
  final now = DateTime.now(); // Create once for consistency
  final grouped = <_DateGroup, List<PendingTransaction>>{};
  for (final tx in transactions) {
    final group = _getDateGroup(tx.sourceTimestamp, now);
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
  }

  void _onMainTabChanged() {
    // Process only after animation completes (prevent unnecessary setState)
    if (_mainTabController.indexIsChanging) return;

    // FAB state update
    setState(() {});

    // Mark as viewed when auto-collect history tab is selected (Android only)
    if (_isAndroidPlatform && _mainTabController.index == _autoCollectHistoryTabIndex) {
      _markAsViewed();
    }
  }

  Future<void> _markAsViewed() async {
    await ref
        .read(pendingTransactionNotifierProvider.notifier)
        .markAllAsViewed();
  }

  @override
  void dispose() {
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
                            borderRadius:
                                BorderRadius.circular(_badgeBorderRadius),
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
      floatingActionButton: ListenableBuilder(
        listenable: _mainTabController,
        builder: (context, child) {
          return Visibility(
            visible: _mainTabController.index == _paymentMethodTabIndex,
            child: child!,
          );
        },
        child: FloatingActionButton(
          onPressed: () => _showAddDialog(context),
          tooltip: l10n.paymentMethodAdd,
          child: const Icon(Icons.add),
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
            children: const [
              _PendingTransactionListView(
                status: PendingTransactionStatus.pending,
              ),
              _PendingTransactionListView(
                status: PendingTransactionStatus.converted,
              ),
              _PendingTransactionListView(
                status: PendingTransactionStatus.rejected,
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
      MaterialPageRoute(
        builder: (context) => const PaymentMethodWizardPage(),
      ),
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
    final autoCollectAsync = ref.watch(autoCollectPaymentMethodsByOwnerProvider(userId));

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
      return EmptyState(
        icon: Icons.credit_card_outlined,
        message: l10n.paymentMethodEmpty,
        subtitle: l10n.paymentMethodEmptySubtitle,
        action: ElevatedButton.icon(
          onPressed: () => _showAddDialog(context),
          icon: const Icon(Icons.add),
          label: Text(l10n.paymentMethodAdd),
        ),
      );
    }

    return SingleChildScrollView(
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
    );
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
        color: colorScheme.surfaceContainerLow,
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
        color: colorScheme.surfaceContainerLow,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.security,
                color: colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                l10n.autoSaveSettingsRequiredPermissions,
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            l10n.autoSaveSettingsPermissionDesc,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          OutlinedButton.icon(
            onPressed: () => _showPermissionDialog(context),
            icon: const Icon(Icons.settings),
            label: Text(l10n.autoSaveSettingsPermissionButton),
          ),
        ],
      ),
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
      MaterialPageRoute(
        builder: (context) => const PaymentMethodWizardPage(),
      ),
    );
  }

  void _showAddSharedDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodWizardPage(
          initialMode: PaymentMethodAddMode.manual,
        ),
      ),
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
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.paymentMethodDeleteConfirmTitle),
        content: Text(
          '\'${paymentMethod.name}\'\n\n'
          '${l10n.paymentMethodDeleteConfirmMessage}',
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
                await ref
                    .read(paymentMethodNotifierProvider.notifier)
                    .deletePaymentMethod(paymentMethod.id);
                if (parentContext.mounted) {
                  SnackBarUtils.showSuccess(parentContext, l10n.paymentMethodDeleted);
                }
              } catch (e) {
                if (parentContext.mounted) {
                  final errorMsg = e.toString().toLowerCase();
                  if (errorMsg.contains('policy') ||
                      errorMsg.contains('permission') ||
                      errorMsg.contains('denied')) {
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
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  void _showAutoSaveModeDialog(BuildContext context, PaymentMethod paymentMethod) {
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (dialogContext) => AutoSaveModeDialog(
          paymentMethod: paymentMethod,
          onSave: () {
            // Dialog will handle its own closing via Navigator.pop
          },
        ),
      );
    }
  }
}

/// Shared payment method chip
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
    final paymentColor = ColorUtils.parseHexColor(paymentMethod.color);
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: '${paymentMethod.name}${paymentMethod.isDefault ? ', ${l10n.paymentMethodDefault}' : ''}',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: () => _showOptions(context),
          borderRadius: BorderRadius.circular(BorderRadiusToken.circular),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              color: paymentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(BorderRadiusToken.circular),
              border: Border.all(
                color: paymentColor.withValues(alpha: 0.5),
              ),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Semantics(
          label: l10n.paymentMethodOptions,
          explicitChildNodes: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                  semanticLabel: l10n.commonEdit,
                ),
                title: Text(l10n.commonEdit),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onTap();
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Theme.of(sheetContext).colorScheme.error,
                  semanticLabel: l10n.commonDelete,
                ),
                title: Text(
                  l10n.commonDelete,
                  style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDelete();
                },
              ),
            ],
          ),
        ),
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
                    _getAutoSaveModeText(l10n, paymentMethod.autoSaveMode),
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

  String _getAutoSaveModeText(AppLocalizations l10n, AutoSaveMode mode) {
    return switch (mode) {
      AutoSaveMode.manual => l10n.autoSaveModeOff,
      AutoSaveMode.suggest => l10n.autoSaveModeSuggest,
      AutoSaveMode.auto => l10n.autoSaveModeAuto,
    };
  }

  IconData _getAutoSaveModeIcon(AutoSaveMode mode) {
    return switch (mode) {
      AutoSaveMode.auto => Icons.auto_awesome_outlined,
      AutoSaveMode.suggest => Icons.notifications_active_outlined,
      AutoSaveMode.manual => Icons.flash_off_outlined,
    };
  }
}

/// Pending transaction list view (collection history) - date grouping + detailed card
class _PendingTransactionListView extends ConsumerWidget {
  final PendingTransactionStatus status;

  const _PendingTransactionListView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // 로케일 변경에 대응하기 위해 build마다 생성
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MM/dd HH:mm');
    final currencyFormat = NumberFormat('#,###');

    final filteredTransactions = switch (status) {
      PendingTransactionStatus.pending => ref.watch(pendingTabTransactionsProvider),
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed => ref.watch(confirmedTabTransactionsProvider),
      PendingTransactionStatus.rejected => ref.watch(rejectedTabTransactionsProvider),
    };

    if (filteredTransactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: _getEmptyMessage(l10n, status),
        subtitle: _getEmptySubtitle(l10n, status),
      );
    }

    // Date grouping (newest first)
    final grouped = _groupTransactionsByDate(filteredTransactions);
    final sortedGroups = grouped.keys.toList()
      ..sort((a, b) => a.index.compareTo(b.index)); // today(0) -> older(4) order

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
              bottom: BorderSide(
                color: colorScheme.outlineVariant,
                width: 1,
              ),
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
                onPressed: () => _showDeleteAllConfirm(context, ref, l10n, filteredTransactions.length),
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
        // List content
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(Spacing.md),
            itemCount: sortedGroups.length,
            itemBuilder: (context, groupIndex) {
              final group = sortedGroups[groupIndex];
              // Create new list for immutability and sort by newest first
              final sortedTransactions = grouped[group]!.toList()
                ..sort((a, b) => b.sourceTimestamp.compareTo(a.sourceTimestamp));

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
                    _PendingTransactionCard(
                      key: ValueKey(tx.id),
                      transaction: tx,
                      status: status,
                      timeFormat: timeFormat,
                      dateFormat: dateFormat,
                      currencyFormat: currencyFormat,
                    ),
                ],
              );
            },
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
    final statusText = _getStatusText(l10n, status);
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pendingTransactionDeleteAllConfirmTitle),
        content: Text(l10n.pendingTransactionDeleteAllConfirmMessage(statusText, count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(pendingTransactionNotifierProvider.notifier)
                    .deleteAllByStatus(status);
                if (parentContext.mounted) {
                  SnackBarUtils.showSuccess(parentContext, l10n.pendingTransactionDeleteAllSuccess);
                }
              } catch (e) {
                if (parentContext.mounted) {
                  SnackBarUtils.showError(parentContext, e.toString());
                }
              }
            },
            child: Text(
              l10n.commonDelete,
              style: TextStyle(color: Theme.of(dialogContext).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(AppLocalizations l10n, PendingTransactionStatus status) {
    return switch (status) {
      PendingTransactionStatus.pending => l10n.pendingTransactionStatusPending,
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed => l10n.pendingTransactionStatusConfirmed,
      PendingTransactionStatus.rejected => l10n.pendingTransactionStatusRejected,
    };
  }

  String _getEmptyMessage(AppLocalizations l10n, PendingTransactionStatus status) {
    return switch (status) {
      PendingTransactionStatus.pending => l10n.pendingTransactionEmptyPending,
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed => l10n.pendingTransactionEmptyConfirmed,
      PendingTransactionStatus.rejected => l10n.pendingTransactionEmptyRejected,
    };
  }

  String? _getEmptySubtitle(AppLocalizations l10n, PendingTransactionStatus status) {
    if (status == PendingTransactionStatus.pending) {
      return l10n.pendingTransactionEmptySubtitle;
    }
    return null;
  }
}

/// Improved pending transaction card widget
class _PendingTransactionCard extends ConsumerWidget {
  final PendingTransaction transaction;
  final PendingTransactionStatus status;
  final DateFormat timeFormat;
  final DateFormat dateFormat;
  final NumberFormat currencyFormat;

  const _PendingTransactionCard({
    super.key,
    required this.transaction,
    required this.status,
    required this.timeFormat,
    required this.dateFormat,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.md),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: notification source + time + delete button
            Row(
              children: [
                Icon(
                  transaction.sourceType == SourceType.sms
                      ? Icons.sms_outlined
                      : Icons.notifications_outlined,
                  size: IconSize.xs,
                  color: colorScheme.onSurfaceVariant,
                  semanticLabel: transaction.sourceType == SourceType.sms
                      ? l10n.sourceTypeSms
                      : l10n.sourceTypeNotification,
                ),
                const SizedBox(width: Spacing.xs),
                Text(
                  transaction.sourceType == SourceType.sms
                      ? l10n.sourceTypeSms
                      : l10n.sourceTypeNotification,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: Spacing.xs),
                Expanded(
                  child: Text(
                    transaction.sourceSender ?? '',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  timeFormat.format(transaction.sourceTimestamp),
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                IconButton(
                  onPressed: () => _showDeleteConfirm(context, ref),
                  icon: Icon(
                    Icons.delete_outline,
                    size: IconSize.sm,
                    color: colorScheme.error,
                    semanticLabel: l10n.commonDelete,
                  ),
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(Spacing.xs),
                  visualDensity: VisualDensity.compact,
                  tooltip: l10n.commonDelete,
                ),
              ],
            ),

            const SizedBox(height: Spacing.md),

            // Middle: amount + status badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    transaction.parsedAmount != null
                        ? '${transaction.parsedType == 'income' ? '+' : '-'}${currencyFormat.format(transaction.parsedAmount)}원'
                        : l10n.noAmountInfo,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: transaction.parsedType == 'income'
                          ? colorScheme.primary
                          : colorScheme.error,
                    ),
                  ),
                ),
                _buildStatusBadge(context, l10n),
              ],
            ),

            // Merchant + date
            if (transaction.parsedMerchant != null) ...[
              const SizedBox(height: Spacing.xs),
              Text(
                '${transaction.parsedMerchant} ${dateFormat.format(transaction.parsedDate ?? transaction.sourceTimestamp)}',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ],

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(vertical: Spacing.sm),
              child: Divider(height: 1),
            ),

            // Original message
            Text(
              transaction.sourceContent,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, AppLocalizations l10n) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final (String label, Color bgColor, Color textColor, IconData icon) = switch (status) {
      PendingTransactionStatus.pending => (
        l10n.pendingTransactionStatusWaiting,
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
        Icons.schedule_outlined,
      ),
      PendingTransactionStatus.converted ||
      PendingTransactionStatus.confirmed => (
        l10n.pendingTransactionStatusSaved,
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
        Icons.check_circle_outline,
      ),
      PendingTransactionStatus.rejected => (
        l10n.pendingTransactionStatusDenied,
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
        Icons.cancel_outlined,
      ),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _badgePaddingH,
          vertical: _badgePaddingV,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_badgeBorderRadius),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirm(BuildContext parentContext, WidgetRef ref) {
    final l10n = AppLocalizations.of(parentContext);
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.pendingTransactionDeleteConfirmTitle),
        content: Text(l10n.pendingTransactionDeleteConfirmMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ref
                    .read(pendingTransactionNotifierProvider.notifier)
                    .deleteTransaction(transaction.id);
                if (parentContext.mounted) {
                  SnackBarUtils.showSuccess(parentContext, l10n.pendingTransactionDeleted);
                }
              } catch (e) {
                if (parentContext.mounted) {
                  SnackBarUtils.showError(parentContext, e.toString());
                }
              }
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }
}
