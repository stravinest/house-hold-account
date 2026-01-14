import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
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
    final ownedLedgersAsync = ref.watch(myOwnedLedgersWithInvitesProvider);
    final receivedInvitesAsync = ref.watch(receivedInvitesProvider);
    final selectedLedgerId = ref.watch(selectedLedgerIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('가계부 및 공유 관리')),
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

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        // 내 가계부 섹션
        if (ownedLedgers.isNotEmpty) ...[
          const SectionHeader(
            title: '내 가계부',
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
          const SectionHeader(title: '초대받은 가계부', icon: Icons.mail_outline),
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
                      invite.ledgerName ?? '가계부',
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
    return _buildScrollableCenter(
      child: EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        message: '가계부가 없습니다',
        subtitle: '가계부를 생성하여 시작하세요',
        action: ElevatedButton.icon(
          onPressed: () => context.push(Routes.ledgerManage),
          icon: const Icon(Icons.add),
          label: const Text('가계부 생성하기'),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context, WidgetRef ref, String error) {
    return _buildScrollableCenter(
      child: EmptyState(
        icon: Icons.error_outline,
        message: '오류가 발생했습니다',
        subtitle: error,
        action: ElevatedButton.icon(
          onPressed: () {
            ref.invalidate(myOwnedLedgersWithInvitesProvider);
            ref.invalidate(receivedInvitesProvider);
          },
          icon: const Icon(Icons.refresh),
          label: const Text('다시 시도'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가계부 변경'),
        content: Text('\'$ledgerName\' 가계부를 사용하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('사용'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(ledgerNotifierProvider.notifier).selectLedger(ledgerId);
      ref.invalidate(myOwnedLedgersWithInvitesProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('\'$ledgerName\' 가계부로 변경했습니다'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가계부 탈퇴'),
        content: Text(
          '\'${invite.ledgerName ?? '가계부'}\'에서 탈퇴하시겠습니까?\n'
          '탈퇴하면 해당 가계부의 데이터에 더 이상 접근할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('탈퇴'),
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
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .leaveLedger(invite.ledgerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('가계부에서 탈퇴했습니다'),
            duration: Duration(seconds: 1),
          ),
        );
        ref.invalidate(receivedInvitesProvider);
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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
    final invite = ledgerInfo.sentInvite;
    if (invite == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 취소'),
        content: Text('\'${invite.inviteeEmail}\'님에게 보낸 초대를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('초대취소'),
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
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .cancelInvite(inviteId: inviteId, ledgerId: ledgerId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 취소했습니다'),
            duration: Duration(seconds: 1),
          ),
        );
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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
    try {
      await ref.read(shareNotifierProvider.notifier).acceptInvite(invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 수락했습니다'),
            duration: Duration(seconds: 1),
          ),
        );
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 거부'),
        content: Text(
          '\'${invite.ledgerName ?? '가계부'}\' 초대를 거부하시겠습니까?\n'
          '거부하면 목록에서 사라집니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('거부'),
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
    try {
      await ref.read(shareNotifierProvider.notifier).rejectInvite(invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('초대를 거부했습니다'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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
    return AlertDialog(
      title: const Text('멤버 초대'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요';
                }
                if (!value.contains('@')) {
                  return '올바른 이메일 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: const InputDecoration(
                labelText: '역할',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              itemHeight: 60,
              items: const [
                DropdownMenuItem(
                  value: 'member',
                  child: _RoleDropdownItem(
                    title: '멤버',
                    description: '거래 내역 조회/추가/수정/삭제',
                  ),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: _RoleDropdownItem(
                    title: '관리자',
                    description: '거래 + 카테고리/예산 관리 + 멤버 초대',
                  ),
                ),
              ],
              selectedItemBuilder: (context) => [
                const Align(alignment: Alignment.centerLeft, child: Text('멤버')),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('관리자'),
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
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _sendInvite,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('초대'),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

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
          const SnackBar(
            content: Text('초대를 보냈습니다'),
            duration: Duration(seconds: 1),
          ),
        );
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
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
