import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/pending_transaction.dart';
import '../providers/payment_method_provider.dart';
import '../providers/pending_transaction_provider.dart';
import 'payment_method_wizard_page.dart';

/// 결제수단 관리 페이지 (멤버별 탭 + 자동수집내역 탭)
class PaymentMethodManagementPage extends ConsumerStatefulWidget {
  const PaymentMethodManagementPage({super.key});

  @override
  ConsumerState<PaymentMethodManagementPage> createState() =>
      _PaymentMethodManagementPageState();
}

class _PaymentMethodManagementPageState
    extends ConsumerState<PaymentMethodManagementPage>
    with TickerProviderStateMixin {
  late TabController _mainTabController;
  TabController? _autoCollectTabController;
  int _autoCollectTabIndex = -1;

  @override
  void initState() {
    super.initState();
    // 멤버 수 + 자동수집 1개 (초기 길이는 dispose 시점에 업데이트)
    _mainTabController = TabController(length: 2, vsync: this);
    _autoCollectTabController = TabController(length: 3, vsync: this);

    // 자동수집 탭 선택 시 viewed 처리
    _mainTabController.addListener(() {
      if (_mainTabController.index == _autoCollectTabIndex) {
        _markAsViewed();
      }
    });
  }

  Future<void> _markAsViewed() async {
    await ref
        .read(pendingTransactionNotifierProvider.notifier)
        .markAllAsViewed();
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    _autoCollectTabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentUser = ref.watch(currentUserProvider);
    final ledgerId = ref.watch(selectedLedgerIdProvider);
    final ledgerMembersAsync = ledgerId != null
        ? ref.watch(ledgerMembersProvider(ledgerId))
        : const AsyncValue<List>.data([]);
    final pendingCountAsync = ref.watch(pendingTransactionCountProvider);
    final isAndroid = Platform.isAndroid;

    return ledgerMembersAsync.when(
      data: (members) {
        // 탭 길이 업데이트
        final tabLength = isAndroid ? members.length + 1 : members.length;
        if (_mainTabController.length != tabLength) {
          _mainTabController.dispose();
          _mainTabController = TabController(length: tabLength, vsync: this);
          _autoCollectTabIndex = isAndroid ? members.length : -1;
          _mainTabController.addListener(() {
            if (_mainTabController.index == _autoCollectTabIndex) {
              _markAsViewed();
            }
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.paymentMethodManagement),
            bottom: TabBar(
              controller: _mainTabController,
              isScrollable: members.length > 2,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant,
              indicatorWeight: 3,
              tabs: [
                // 멤버별 탭
                ...members.map((member) {
                  final isMe = member.userId == currentUser?.id;
                  final displayName =
                      member.displayName ?? member.email ?? '사용자';
                  return Tab(text: isMe ? '나 ($displayName)' : displayName);
                }),
                // 자동수집 탭 (Android만, 뱃지 포함)
                if (isAndroid)
                  Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('자동수집'),
                        if (pendingCountAsync.value != null &&
                            pendingCountAsync.value! > 0) ...[
                          const SizedBox(width: Spacing.xs),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            child: Text(
                              '${pendingCountAsync.value}',
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
              ],
            ),
          ),
          body: CenteredContent(
            maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
            child: TabBarView(
              controller: _mainTabController,
              children: [
                // 멤버별 결제수단 뷰
                ...members.map((member) {
                  final isOwner = member.userId == currentUser?.id;
                  final displayName =
                      member.displayName ?? member.email ?? '사용자';
                  return _PaymentMethodListView(
                    memberId: member.userId,
                    memberName: displayName,
                    isOwner: isOwner,
                  );
                }),
                // 자동수집 뷰 (2레벨 탭)
                if (isAndroid) _buildAutoCollectView(context, l10n),
              ],
            ),
          ),
          floatingActionButton: _shouldShowFAB(members.length)
              ? FloatingActionButton(
                  onPressed: () => _showAddDialog(context),
                  tooltip: l10n.paymentMethodAdd,
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('오류: $e'))),
    );
  }

  bool _shouldShowFAB(int memberCount) {
    final isAndroid = Platform.isAndroid;
    final maxIndex = isAndroid ? memberCount : memberCount - 1;
    return _mainTabController.index <= maxIndex;
  }

  Widget _buildAutoCollectView(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        // 2레벨 탭바
        Material(
          color: Theme.of(context).colorScheme.surface,
          elevation: 1,
          child: TabBar(
            controller: _autoCollectTabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant,
            indicatorWeight: 2,
            tabs: const [
              Tab(text: '대기중'),
              Tab(text: '확인됨'),
              Tab(text: '거부됨'),
            ],
          ),
        ),
        // 2레벨 탭뷰
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
      MaterialPageRoute(builder: (context) => const PaymentMethodWizardPage()),
    );
  }
}

/// 멤버별 결제수단 리스트
class _PaymentMethodListView extends ConsumerWidget {
  final String memberId;
  final String memberName;
  final bool isOwner;

  const _PaymentMethodListView({
    required this.memberId,
    required this.memberName,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final paymentMethodsAsync = ref.watch(
      paymentMethodsByOwnerProvider(memberId),
    );

    return paymentMethodsAsync.when(
      data: (paymentMethods) {
        if (paymentMethods.isEmpty) {
          return EmptyState(
            icon: Icons.credit_card_outlined,
            message: isOwner
                ? l10n.paymentMethodEmpty
                : '$memberName님의 결제수단이 없습니다',
            subtitle: isOwner ? '결제수단을 추가하여 시작하세요' : null,
            action: isOwner
                ? ElevatedButton.icon(
                    onPressed: () => _showAddDialog(context),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.paymentMethodAdd),
                  )
                : null,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: paymentMethods.length + (isOwner ? 0 : 1),
          itemBuilder: (context, index) {
            // 상단에 안내 메시지 (파트너 탭)
            if (!isOwner && index == 0) {
              return Container(
                margin: const EdgeInsets.only(bottom: Spacing.md),
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(BorderRadiusToken.md),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: IconSize.sm,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: Spacing.sm),
                    Expanded(
                      child: Text(
                        '$memberName님의 결제수단은 조회만 가능합니다',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final paymentMethod = paymentMethods[isOwner ? index : index - 1];
            return _PaymentMethodTile(
              key: ValueKey(paymentMethod.id),
              paymentMethod: paymentMethod,
              isOwner: isOwner,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.errorWithMessage(e.toString()))),
    );
  }

  void _showAddDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PaymentMethodWizardPage()),
    );
  }
}

/// 결제수단 타일
class _PaymentMethodTile extends ConsumerWidget {
  final PaymentMethod paymentMethod;
  final bool isOwner;

  const _PaymentMethodTile({
    super.key,
    required this.paymentMethod,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isAndroid = Platform.isAndroid;

    return Card(
      margin: const EdgeInsets.only(bottom: Spacing.sm),
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
            subtitle: isOwner && paymentMethod.isDefault
                ? Text(l10n.paymentMethodDefault)
                : null,
            trailing: isOwner
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: IconSize.sm),
                        tooltip: l10n.commonEdit,
                        onPressed: () =>
                            _showEditDialog(context, ref, paymentMethod),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: IconSize.sm),
                        tooltip: l10n.commonDelete,
                        onPressed: () =>
                            _showDeleteConfirm(context, ref, paymentMethod),
                      ),
                    ],
                  )
                : Icon(
                    Icons.visibility_outlined,
                    color: colorScheme.onSurfaceVariant,
                    size: IconSize.sm,
                  ),
          ),
          // 자동 처리 설정 (본인 것만, Android만)
          if (isOwner && isAndroid && paymentMethod.canAutoSave) ...[
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
                      size: IconSize.sm,
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
                      size: IconSize.sm,
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

/// 대기 거래 리스트 (자동수집내역)
class _PendingTransactionListView extends ConsumerWidget {
  final PendingTransactionStatus status;

  const _PendingTransactionListView({required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredTransactions = status == PendingTransactionStatus.pending
        ? ref.watch(pendingTabTransactionsProvider)
        : status == PendingTransactionStatus.converted
        ? ref.watch(confirmedTabTransactionsProvider)
        : ref.watch(rejectedTabTransactionsProvider);

    if (filteredTransactions.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_outlined,
        message: _getEmptyMessage(status),
        subtitle: _getEmptySubtitle(status),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: Spacing.sm),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _getStatusIcon(status),
                color: Theme.of(context).colorScheme.primary,
                size: IconSize.sm,
              ),
            ),
            title: Text(
              transaction.parsedMerchant ?? transaction.sourceContent,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              transaction.parsedAmount != null
                  ? '${transaction.parsedAmount}원'
                  : '금액 정보 없음',
            ),
            trailing: Icon(
              Icons.chevron_right,
              size: IconSize.sm,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              context.push('/settings/pending-transactions');
            },
          ),
        );
      },
    );
  }

  String _getEmptyMessage(PendingTransactionStatus status) {
    switch (status) {
      case PendingTransactionStatus.pending:
        return '대기 중인 거래가 없습니다';
      case PendingTransactionStatus.converted:
      case PendingTransactionStatus.confirmed:
        return '확인된 거래가 없습니다';
      case PendingTransactionStatus.rejected:
        return '거부된 거래가 없습니다';
    }
  }

  String? _getEmptySubtitle(PendingTransactionStatus status) {
    if (status == PendingTransactionStatus.pending) {
      return 'SMS/푸시 알림에서 감지된 거래가 여기 표시됩니다';
    }
    return null;
  }

  IconData _getStatusIcon(PendingTransactionStatus status) {
    switch (status) {
      case PendingTransactionStatus.pending:
        return Icons.schedule_outlined;
      case PendingTransactionStatus.converted:
      case PendingTransactionStatus.confirmed:
        return Icons.check_circle_outline;
      case PendingTransactionStatus.rejected:
        return Icons.cancel_outlined;
    }
  }
}
