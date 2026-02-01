import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../../config/supabase_config.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/ledger_invite.dart';
import '../providers/share_provider.dart';
import '../widgets/invited_ledger_card.dart';
import '../widgets/owned_ledger_card.dart';

class ShareManagementPage extends ConsumerStatefulWidget {
  const ShareManagementPage({super.key});

  @override
  ConsumerState<ShareManagementPage> createState() =>
      _ShareManagementPageState();
}

class _ShareManagementPageState extends ConsumerState<ShareManagementPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 항상 최신 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(myOwnedLedgersWithInvitesProvider);
      ref.invalidate(receivedInvitesProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ownedLedgersAsync = ref.watch(myOwnedLedgersWithInvitesProvider);
    final receivedInvitesAsync = ref.watch(receivedInvitesProvider);
    final selectedLedgerId = ref.watch(selectedLedgerIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.shareManagementTitle)),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(myOwnedLedgersWithInvitesProvider);
            ref.invalidate(receivedInvitesProvider);
          },
          child: _buildBody(
            context,
            ownedLedgersAsync,
            receivedInvitesAsync,
            selectedLedgerId,
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<LedgerWithInviteInfo>> ownedLedgersAsync,
    AsyncValue<List<LedgerInvite>> receivedInvitesAsync,
    String? selectedLedgerId,
  ) {
    // 로딩 상태
    if (ownedLedgersAsync.isLoading || receivedInvitesAsync.isLoading) {
      return _buildLoadingSkeleton();
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

    final l10n = AppLocalizations.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 내 가계부 섹션
        if (ownedLedgers.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.menu_book,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.shareMyLedgers,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...ownedLedgers.map(
            (ledgerInfo) => OwnedLedgerCard(
              ledgerInfo: ledgerInfo,
              onInviteTap: ledgerInfo.canInvite
                  ? () => _showInviteDialog(context, ref, ledgerInfo.ledger.id)
                  : null,
              onCancelInvite: (inviteId) => _showCancelInviteDialog(
                context,
                ref,
                inviteId,
                ledgerInfo.ledger.id,
              ),
              onDeleteInvite: (inviteId) =>
                  _deleteInvite(context, ref, inviteId, ledgerInfo.ledger.id),
              onSelectLedger: !ledgerInfo.isCurrentLedger
                  ? () => _showSelectLedgerDialog(
                      context,
                      ref,
                      ledgerInfo.ledger.id,
                      ledgerInfo.ledger.name,
                    )
                  : null,
              onEdit: () => _showEditLedgerDialog(
                context,
                ref,
                ledgerInfo.ledger.id,
                ledgerInfo.ledger.name,
              ),
              onMemberTap: ledgerInfo.members.length > 1
                  ? () => _showMemberManagementSheet(context, ref, ledgerInfo)
                  : null,
            ),
          ),
        ],

        // 초대받은 가계부 섹션
        if (receivedInvites.isNotEmpty) ...[
          if (ownedLedgers.isNotEmpty) const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.shareInvitedLedgers,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ...receivedInvites.map((invite) {
            final shareState = ref.watch(shareNotifierProvider);
            return InvitedLedgerCard(
              invite: invite,
              isCurrentLedger: invite.ledgerId == selectedLedgerId,
              isLoading: shareState.isLoading,
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
            );
          }),
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
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
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

  void _showMemberManagementSheet(
    BuildContext context,
    WidgetRef ref,
    LedgerWithInviteInfo ledgerInfo,
  ) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        // 네비게이션 바 높이 + 시스템 패딩 고려
        final safeBottomPadding =
            bottomPadding + kBottomNavigationBarHeight + Spacing.sm;
        return Padding(
          padding: EdgeInsets.only(bottom: safeBottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 헤더
              Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Row(
                  children: [
                    const Icon(Icons.people),
                    const SizedBox(width: Spacing.sm),
                    Text(
                      l10n.shareMemberManagement,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // 멤버 목록
              ...ledgerInfo.members.map((member) {
                final isCurrentUser = member.userId == currentUserId;
                final isOwner = member.role == 'owner';
                final displayName =
                    member.displayName ?? member.email ?? l10n.shareUnknown;

                // 권한 텍스트 (owner만 구분)
                final roleText = isOwner
                    ? l10n.shareMemberRoleOwner
                    : l10n.shareMemberRoleMember;

                // 멤버 색상
                final memberColor = member.color != null
                    ? Color(int.parse(member.color!.replaceFirst('#', '0xFF')))
                    : colorScheme.primary;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.md,
                    vertical: Spacing.sm,
                  ),
                  child: Row(
                    children: [
                      // 색상 점
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: memberColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: Spacing.sm),
                      // 멤버 정보
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                                if (isCurrentUser) ...[
                                  const SizedBox(width: Spacing.xs),
                                  Text(
                                    '(${l10n.shareMe})',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (member.email != null)
                              Text(
                                member.email!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                      // 권한 배지
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.sm,
                          vertical: Spacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(
                            BorderRadiusToken.xs,
                          ),
                        ),
                        child: Text(
                          roleText,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      // 방출 버튼 (소유자가 아닌 멤버만)
                      if (!isOwner) ...[
                        const SizedBox(width: Spacing.sm),
                        TextButton(
                          onPressed: () async {
                            debugPrint(
                              '[RemoveMember] Button pressed in bottom sheet',
                            );
                            // 바텀시트를 먼저 닫지 않고, 다이얼로그를 위에 표시
                            await _showRemoveMemberDialog(
                              context,
                              ref,
                              ledgerInfo.ledger.id,
                              member.userId,
                              displayName,
                            );
                            // 다이얼로그가 닫힌 후에만 바텀시트 닫기
                            if (context.mounted) {
                              debugPrint('[RemoveMember] Closing bottom sheet');
                              Navigator.pop(context);
                            }
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorScheme.error,
                            padding: const EdgeInsets.symmetric(
                              horizontal: Spacing.sm,
                            ),
                            minimumSize: const Size(0, 36),
                          ),
                          child: Text(l10n.shareMemberRemove),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: Spacing.md),
              // 닫기 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(l10n.commonClose),
                  ),
                ),
              ),
              const SizedBox(height: Spacing.md),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRemoveMemberDialog(
    BuildContext context,
    WidgetRef ref,
    String ledgerId,
    String userId,
    String memberName,
  ) async {
    debugPrint(
      '[RemoveMember] Dialog opened for user: $userId, member: $memberName',
    );
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareMemberRemoveTitle),
        content: Text(l10n.shareMemberRemoveConfirm(memberName)),
        actions: [
          TextButton(
            onPressed: () {
              debugPrint('[RemoveMember] Cancel button pressed');
              Navigator.pop(context, false);
            },
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              debugPrint('[RemoveMember] Confirm button pressed');
              Navigator.pop(context, true);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.shareMemberRemove),
          ),
        ],
      ),
    );

    debugPrint(
      '[RemoveMember] Dialog result: $confirmed, context.mounted: ${context.mounted}',
    );
    if (confirmed == true && context.mounted) {
      debugPrint('[RemoveMember] Calling _removeMember');
      await _removeMember(context, ref, ledgerId, userId);
    }
  }

  Future<void> _removeMember(
    BuildContext context,
    WidgetRef ref,
    String ledgerId,
    String userId,
  ) async {
    debugPrint(
      '[RemoveMember] Starting removal - ledgerId: $ledgerId, userId: $userId',
    );
    final l10n = AppLocalizations.of(context);
    try {
      debugPrint('[RemoveMember] Calling repository removeMember');
      await ref
          .read(shareNotifierProvider.notifier)
          .removeMember(ledgerId: ledgerId, userId: userId);
      debugPrint('[RemoveMember] Repository call successful');
      if (context.mounted) {
        debugPrint('[RemoveMember] Showing success message');
        SnackBarUtils.showSuccess(context, l10n.shareMemberRemoved);
        if (mounted) {
          debugPrint('[RemoveMember] Invalidating providers');
          ref.invalidate(myOwnedLedgersWithInvitesProvider);
        }
      }
    } catch (e, st) {
      debugPrint('[RemoveMember] Error: $e');
      debugPrint('[RemoveMember] StackTrace: $st');
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Future<void> _showEditLedgerDialog(
    BuildContext context,
    WidgetRef ref,
    String ledgerId,
    String currentName,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: currentName);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ledgerEditTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.ledgerNameLabel,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );

    // 다이얼로그 닫기 애니메이션이 완료된 후 dispose
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.dispose();
    });

    if (newName != null && newName.isNotEmpty && newName != currentName) {
      try {
        await ref
            .read(ledgerNotifierProvider.notifier)
            .updateLedger(id: ledgerId, name: newName);
        if (context.mounted) {
          SnackBarUtils.showSuccess(context, l10n.commonSuccess);
          if (mounted) {
            ref.invalidate(myOwnedLedgersWithInvitesProvider);
          }
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
        }
      }
    }
  }

  Future<void> _showSelectLedgerDialog(
    BuildContext context,
    WidgetRef ref,
    String ledgerId,
    String ledgerName,
  ) async {
    final l10n = AppLocalizations.of(context);
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
      if (mounted) {
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.shareLedgerChanged(ledgerName));
      }
    }
  }

  Future<void> _showLeaveConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .leaveLedger(invite.ledgerId);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.shareLedgerLeft);
        if (mounted) {
          ref.invalidate(receivedInvitesProvider);
          ref.invalidate(myOwnedLedgersWithInvitesProvider);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Future<void> _showCancelInviteDialog(
    BuildContext context,
    WidgetRef ref,
    String inviteId,
    String ledgerId,
  ) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.shareInviteCancelConfirmTitle),
        content: Text(l10n.shareInviteCancelConfirmTitle),
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
      await _cancelInvite(context, ref, inviteId, ledgerId);
    }
  }

  // 거부된 초대 삭제 (확인 없이 바로 삭제)
  Future<void> _deleteInvite(
    BuildContext context,
    WidgetRef ref,
    String inviteId,
    String ledgerId,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .cancelInvite(inviteId: inviteId, ledgerId: ledgerId);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.shareInviteCancelledMessage);
        if (mounted) {
          ref.invalidate(myOwnedLedgersWithInvitesProvider);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Future<void> _cancelInvite(
    BuildContext context,
    WidgetRef ref,
    String inviteId,
    String ledgerId,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .cancelInvite(inviteId: inviteId, ledgerId: ledgerId);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.shareInviteCancelledMessage);
        if (mounted) {
          ref.invalidate(myOwnedLedgersWithInvitesProvider);
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Future<void> _acceptInvite(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(shareNotifierProvider.notifier).acceptInvite(invite.id);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.shareInviteAcceptedMessage);
        // Provider 내부에서 receivedInvitesProvider, ledgersProvider 무효화됨
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Future<void> _showRejectConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
  ) async {
    final l10n = AppLocalizations.of(context);
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
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(shareNotifierProvider.notifier).rejectInvite(invite.id);
      if (context.mounted) {
        SnackBarUtils.showSuccess(context, l10n.shareInviteRejectedMessage);
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SkeletonBox(width: 24, height: 24),
              SizedBox(width: 8),
              SkeletonLine(width: 100, height: 20),
            ],
          ),
        ),
        ...List.generate(
          2,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(child: SkeletonLine(height: 18)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: const SkeletonLine(width: 60, height: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SkeletonLine(width: 120, height: 14),
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SkeletonBox(
                          width: 80,
                          height: 36,
                          borderRadius: BorderRadiusToken.md,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              SkeletonBox(width: 24, height: 24),
              SizedBox(width: 8),
              SkeletonLine(width: 120, height: 20),
            ],
          ),
        ),
        ...List.generate(
          1,
          (index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(height: 18),
                    SizedBox(height: 12),
                    SkeletonLine(width: 100, height: 14),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SkeletonBox(
                          width: 70,
                          height: 36,
                          borderRadius: BorderRadiusToken.md,
                        ),
                        SizedBox(width: 8),
                        SkeletonBox(
                          width: 70,
                          height: 36,
                          borderRadius: BorderRadiusToken.md,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
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
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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

    final l10n = AppLocalizations.of(context);
    setState(() => _isLoading = true);

    try {
      await ref
          .read(shareNotifierProvider.notifier)
          .sendInvite(
            ledgerId: widget.ledgerId,
            email: _emailController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, l10n.shareInviteSentMessage);
        ref.invalidate(myOwnedLedgersWithInvitesProvider);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
