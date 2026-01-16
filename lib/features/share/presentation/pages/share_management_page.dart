import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/ledger_invite.dart';
import '../providers/share_provider.dart';
import '../widgets/invited_ledger_card.dart';
import '../widgets/owned_ledger_card.dart';

class ShareManagementPage extends ConsumerWidget {
  const ShareManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ownedLedgersAsync = ref.watch(myOwnedLedgersWithInvitesProvider);
    final receivedInvitesAsync = ref.watch(receivedInvitesProvider);
    final selectedLedgerId = ref.watch(selectedLedgerIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareManagementTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(myOwnedLedgersWithInvitesProvider);
          ref.invalidate(receivedInvitesProvider);
        },
        child: _buildBody(
          context,
          ref,
          ownedLedgersAsync,
          receivedInvitesAsync,
          selectedLedgerId,
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<List<LedgerWithInviteInfo>> ownedLedgersAsync,
    AsyncValue<List<LedgerInvite>> receivedInvitesAsync,
    String? selectedLedgerId,
  ) {
    // 로딩 상태
    if (ownedLedgersAsync.isLoading || receivedInvitesAsync.isLoading) {
      return _buildScrollableCenter(child: const CircularProgressIndicator());
    }

    // 에러 상태
    if (ownedLedgersAsync.hasError) {
      return _buildErrorWidget(
        context,
        ref,
        ownedLedgersAsync.error.toString(),
      );
    }

    if (receivedInvitesAsync.hasError) {
      return _buildErrorWidget(
        context,
        ref,
        receivedInvitesAsync.error.toString(),
      );
    }

    final ownedLedgers = ownedLedgersAsync.valueOrNull ?? [];
    final receivedInvites = receivedInvitesAsync.valueOrNull ?? [];

    // 둘 다 비어있는 경우
    if (ownedLedgers.isEmpty && receivedInvites.isEmpty) {
      return _buildEmptyState(context);
    }

    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // 내 가계부 섹션
        if (ownedLedgers.isNotEmpty) ...[
          SectionHeader(
            title: l10n.shareMyLedgers,
            icon: Icons.account_balance_wallet,
          ),
          ...ownedLedgers.map(
            (ledgerInfo) => OwnedLedgerCard(
              ledgerInfo: ledgerInfo,
              onInviteTap: ledgerInfo.canInvite
                  ? () => _showInviteDialog(context, ref, ledgerInfo.ledger.id)
                  : null,
              onCancelInvite: ledgerInfo.hasPendingInvite
                  ? () => _showCancelInviteDialog(context, ref, ledgerInfo)
                  : null,
              onSelectLedger: !ledgerInfo.isCurrentLedger
                  ? () => _showSelectLedgerDialog(
                      context,
                      ref,
                      ledgerInfo.ledger.id,
                      ledgerInfo.ledger.name,
                    )
                  : null,
            ),
          ),
        ],

        // 초대받은 가계부 섹션
        if (receivedInvites.isNotEmpty) ...[
          if (ownedLedgers.isNotEmpty) const SizedBox(height: 24),
          SectionHeader(
            title: l10n.shareInvitedLedgers,
            icon: Icons.mail_outline,
          ),
          ...receivedInvites.map(
            (invite) => InvitedLedgerCard(
              invite: invite,
              isCurrentLedger: invite.ledgerId == selectedLedgerId,
              onAccept: invite.isPending
                  ? () => _acceptInvite(context, ref, invite)
                  : null,
              onReject: invite.isPending
                  ? () => _showRejectConfirmDialog(context, ref, invite)
                  : null,
              onLeave: invite.isAccepted
                  ? () => _showLeaveConfirmDialog(context, ref, invite)
                  : null,
              onSelectLedger:
                  invite.isAccepted && invite.ledgerId != selectedLedgerId
                  ? () => _showSelectLedgerDialog(
                      context,
                      ref,
                      invite.ledgerId,
                      invite.ledgerName ?? l10n.ledgerTitle,
                    )
                  : null,
            ),
          ),
        ],

        // 하단 여백
        const SizedBox(height: 16),
      ],
    );
  }

  // RefreshIndicator 호환을 위한 스크롤 가능한 Center 위젯
  Widget _buildScrollableCenter({required Widget child}) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _buildScrollableCenter(
      child: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        message: l10n.shareLedgerEmpty,
        subtitle: l10n.shareLedgerEmptySubtitle,
        action: ElevatedButton.icon(
          onPressed: () => context.push(Routes.ledgerManage),
          icon: const Icon(Icons.add),
          label: Text(l10n.shareCreateLedger),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
    final l10n = AppLocalizations.of(context)!;
    return _buildScrollableCenter(
      child: EmptyState(
        icon: Icons.error_outline,
        message: l10n.shareErrorOccurred,
        subtitle: error,
        action: ElevatedButton.icon(
          onPressed: () {
            ref.invalidate(myOwnedLedgersWithInvitesProvider);
            ref.invalidate(receivedInvitesProvider);
          },
          icon: const Icon(Icons.refresh),
          label: Text(l10n.commonRetry),
        ),
      ),
    );
  }

  void _showInviteDialog(BuildContext context, WidgetRef ref, String ledgerId) {
    showDialog(
      context: context,
      builder: (context) => _InviteDialog(ledgerId: ledgerId),
    );
  }

  Future<void> _showSelectLedgerDialog(
    BuildContext context,
    WidgetRef ref,
    String ledgerId,
    String ledgerName,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ledgerChangeConfirmTitle),
        content: Text(l10n.ledgerChangeConfirmMessage(ledgerName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ledgerUse),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(ledgerNotifierProvider.notifier).selectLedger(ledgerId);
      ref.invalidate(myOwnedLedgersWithInvitesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.shareLedgerChanged(ledgerName)),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Future<void> _showLeaveConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareLeaveConfirmTitle),
        content: Text(
          l10n.shareLeaveConfirmMessage(invite.ledgerName ?? l10n.ledgerTitle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.shareLeave),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _leaveLedger(context, ref, invite);
    }
  }

  Future<void> _leaveLedger(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .leaveLedger(invite.ledgerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareLedgerLeft),
            duration: const Duration(seconds: 1),
          ),
        );
        ref.invalidate(receivedInvitesProvider);
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _showCancelInviteDialog(
    BuildContext context,
    WidgetRef ref,
    LedgerWithInviteInfo ledgerInfo,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final invite = ledgerInfo.sentInvite;
    if (invite == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareInviteCancelConfirmTitle),
        content: Text(
          l10n.shareInviteCancelConfirmMessage(invite.inviteeEmail),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonNo),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.shareInviteCancelText),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _cancelInvite(context, ref, invite.id, ledgerInfo.ledger.id);
    }
  }

  Future<void> _cancelInvite(
    BuildContext context,
    WidgetRef ref,
    String inviteId,
    String ledgerId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .cancelInvite(inviteId: inviteId, ledgerId: ledgerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareInviteCancelledMessage),
            duration: const Duration(seconds: 1),
          ),
        );
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _acceptInvite(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(shareNotifierProvider.notifier).acceptInvite(invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareInviteAcceptedMessage),
            duration: const Duration(seconds: 1),
          ),
        );
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Future<void> _showRejectConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareInviteRejectConfirmTitle),
        content: Text(
          l10n.shareInviteRejectConfirmMessage(
            invite.ledgerName ?? l10n.ledgerTitle,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.shareReject),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _rejectInvite(context, ref, invite);
    }
  }

  Future<void> _rejectInvite(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(shareNotifierProvider.notifier).rejectInvite(invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareInviteRejectedMessage),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }
}

// 초대 다이얼로그
class _InviteDialog extends ConsumerStatefulWidget {
  final String ledgerId;

  const _InviteDialog({required this.ledgerId});

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'member';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.shareMemberInvite),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: l10n.authEmail,
                hintText: l10n.shareEmailHint,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.validationEmailRequired;
                }
                if (!value.contains('@')) {
                  return l10n.validationEmailInvalid;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: l10n.shareRole,
                border: const OutlineInputBorder(),
              ),
              isExpanded: true,
              itemHeight: 60,
              items: [
                DropdownMenuItem(
                  value: 'member',
                  child: _RoleDropdownItem(
                    title: l10n.shareRoleMember,
                    description: l10n.shareRoleMemberDescription,
                  ),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: _RoleDropdownItem(
                    title: l10n.shareRoleAdmin,
                    description: l10n.shareRoleAdminDescription,
                  ),
                ),
              ],
              selectedItemBuilder: (context) => [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.shareRoleMember),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(l10n.shareRoleAdmin),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _sendInvite,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.shareInvite),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;
    setState(() => _isLoading = true);

    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .sendInvite(
            ledgerId: widget.ledgerId,
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.shareInviteSentMessage),
            duration: const Duration(seconds: 1),
          ),
        );
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorWithMessage(e.toString())),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// 역할 드롭다운 아이템 위젯
class _RoleDropdownItem extends StatelessWidget {
  final String title;
  final String description;

  const _RoleDropdownItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(
          description,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
