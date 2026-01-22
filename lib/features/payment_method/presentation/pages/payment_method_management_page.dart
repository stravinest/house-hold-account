import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../domain/entities/payment_method.dart';
import '../providers/payment_method_provider.dart';
import '../providers/pending_transaction_provider.dart';
import 'payment_method_wizard_page.dart';

class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  const PaymentMethodManagementPage({super.key});

  @override
  ConsumerState<PaymentMethodManagementPage> createState() =>
      _PaymentMethodManagementPageState();
}

class _PaymentMethodManagementPageState
    extends ConsumerState<PaymentMethodManagementPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 결제수단 목록을 새로고침하지 않습니다.
    // StateNotifier가 생성될 때 자동으로 loadPaymentMethods()를 호출하고,
    // Realtime subscription이 변경사항을 감지하므로 중복 refresh가 불필요합니다.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final paymentMethodsAsync = ref.watch(paymentMethodNotifierProvider);
    // 대기 중인 거래 실시간 갱신을 위해 구독 유지
    ref.watch(pendingTransactionNotifierProvider);
    final pendingCountAsync = ref.watch(pendingTransactionCountProvider);
    final isAndroid = Platform.isAndroid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.paymentMethodManagement),
        actions: [
          if (isAndroid)
            pendingCountAsync.when(
              data: (count) => count > 0
                  ? Badge(
                      label: Text(count.toString()),
                      backgroundColor: Theme.of(context).colorScheme.error,
                      textColor: Theme.of(context).colorScheme.onError,
                      child: IconButton(
                        icon: const Icon(Icons.notifications_active_outlined),
                        tooltip: '대기 중인 거래',
                        onPressed: () {
                          context.push('/settings/pending-transactions');
                        },
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.notifications_none_outlined),
                      tooltip: '대기 중인 거래',
                      onPressed: () {
                        context.push('/settings/pending-transactions');
                      },
                    ),
              loading: () => IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: null,
              ),
              error: (_, __) => IconButton(
                icon: const Icon(Icons.notifications_off_outlined),
                onPressed: null,
              ),
            ),
        ],
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: Column(
          children: [
            _buildPendingAlert(context, ref),
            Expanded(
              child: paymentMethodsAsync.when(
                data: (paymentMethods) {
                  if (paymentMethods.isEmpty) {
                    return EmptyState(
                      icon: Icons.credit_card_outlined,
                      message: l10n.paymentMethodEmpty,
                      action: ElevatedButton.icon(
                        onPressed: () => _showAddDialog(context),
                        icon: const Icon(Icons.add),
                        label: Text(l10n.paymentMethodAdd),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(Spacing.md),
                    itemCount: paymentMethods.length,
                    itemBuilder: (context, index) {
                      final paymentMethod = paymentMethods[index];
                      return _PaymentMethodTile(
                        key: ValueKey(paymentMethod.id),
                        paymentMethod: paymentMethod,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text(l10n.errorWithMessage(e.toString()))),
              ),
            ),
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
      MaterialPageRoute(builder: (context) => const PaymentMethodWizardPage()),
    );
  }

  Widget _buildPendingAlert(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingCountAsync = ref.watch(pendingTransactionCountProvider);

    return pendingCountAsync.maybeWhen(
      data: (count) {
        if (count == 0) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            0,
          ),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.secondary.withOpacity(0.3)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => context.push('/settings/pending-transactions'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.notifications_active_outlined,
                      color: colorScheme.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        '새로운 거래 내역이 $count건 있습니다',
                        style: TextStyle(
                          color: colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.secondary.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _PaymentMethodTile extends ConsumerWidget {
  final PaymentMethod paymentMethod;

  const _PaymentMethodTile({super.key, required this.paymentMethod});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAndroid = Platform.isAndroid;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: _safeParseColor(paymentMethod.color),
              child: Text(
                paymentMethod.name.isNotEmpty ? paymentMethod.name[0] : '?',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(paymentMethod.name),
            subtitle: _buildSubtitle(context, l10n),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.commonEdit,
                  onPressed: () => _showEditDialog(context, ref, paymentMethod),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.commonDelete,
                  onPressed: () =>
                      _showDeleteConfirm(context, ref, paymentMethod),
                ),
              ],
            ),
          ),
          if (isAndroid && paymentMethod.canAutoSave) ...[
            const Divider(height: 1),
            InkWell(
              onTap: () {
                context.push(
                  '/settings/payment-methods/${paymentMethod.id}/auto-save',
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      paymentMethod.autoSaveMode == AutoSaveMode.auto
                          ? Icons.auto_awesome_outlined
                          : paymentMethod.autoSaveMode == AutoSaveMode.suggest
                          ? Icons.notifications_active_outlined
                          : Icons.flash_off_outlined,
                      size: 20,
                      color: paymentMethod.isAutoSaveEnabled
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(child: Text('자동 처리', style: textTheme.bodyMedium)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: Spacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: paymentMethod.isAutoSaveEnabled
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(
                          BorderRadiusToken.xs,
                        ),
                      ),
                      child: Text(
                        _getAutoSaveModeText(paymentMethod.autoSaveMode),
                        style: textTheme.labelSmall?.copyWith(
                          color: paymentMethod.isAutoSaveEnabled
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildSubtitle(BuildContext context, AppLocalizations l10n) {
    if (paymentMethod.isDefault) {
      return Text(l10n.paymentMethodDefault);
    }
    return null;
  }

  String _getAutoSaveModeText(AutoSaveMode mode) {
    switch (mode) {
      case AutoSaveMode.manual:
        return '꺼짐';
      case AutoSaveMode.suggest:
        return '제안';
      case AutoSaveMode.auto:
        return '자동';
    }
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
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

  void _showDeleteConfirm(
    BuildContext context,
    WidgetRef ref,
    PaymentMethod paymentMethod,
  ) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.paymentMethodDeleteConfirmTitle),
        content: Text(
          '\'${paymentMethod.name}\'\n\n'
          '${l10n.paymentMethodDeleteConfirmMessage}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(paymentMethodNotifierProvider.notifier)
                    .deletePaymentMethod(paymentMethod.id);
                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, l10n.paymentMethodDeleted);
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showError(
                    context,
                    l10n.paymentMethodDeleteFailed(e.toString()),
                  );
                }
              }
            },
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  Color _safeParseColor(String colorStr) {
    try {
      return Color(int.parse(colorStr.replaceAll('#', '0xFF')));
    } catch (_) {
      return Colors.grey;
    }
  }
}
