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

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
      length: 1,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          ],
        ),
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: TabBarView(
          controller: _mainTabController,
          children: [
            _PaymentMethodListView(isAndroid: _isAndroidPlatform),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: l10n.paymentMethodAdd,
        child: const Icon(Icons.add),
      ),
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
                    onEdit: () => showDialog(
                      context: context,
                      builder: (context) => AutoSaveModeDialog(
                        paymentMethod: method,
                        onSave: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    onDelete: () => _showDeleteConfirm(context, ref, method),
                  ),
              ],
            ),
          if (_isAndroidPlatform && methods.isNotEmpty) ...[
            const SizedBox(height: Spacing.md),
            _buildPermissionBanner(context, l10n, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildPermissionBanner(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        border: Border.all(color: colorScheme.secondary),
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: colorScheme.secondary,
                  size: IconSize.sm,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    l10n.autoSaveSettingsRequiredPermissions,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.autoSaveSettingsPermissionDesc,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              onPressed: () => showDialog(
                context: context,
                builder: (context) => const PermissionRequestDialog(),
              ),
              icon: const Icon(Icons.settings, size: IconSize.sm),
              label: Text(l10n.autoSaveSettingsPermissionButton),
            ),
          ],
        ),
      ),
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
}

