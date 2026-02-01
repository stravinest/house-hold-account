import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../providers/share_provider.dart';

class OwnedLedgerCard extends ConsumerWidget {
  final LedgerWithInviteInfo ledgerInfo;
  final VoidCallback? onInviteTap;
  final void Function(String inviteId)? onCancelInvite;
  final VoidCallback? onSelectLedger;
  final VoidCallback? onEdit;
  final void Function(String inviteId)? onDeleteInvite;
  final VoidCallback? onMemberTap;

  const OwnedLedgerCard({
    super.key,
    required this.ledgerInfo,
    this.onInviteTap,
    this.onCancelInvite,
    this.onSelectLedger,
    this.onEdit,
    this.onDeleteInvite,
    this.onMemberTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    final colorScheme = Theme.of(context).colorScheme;

    // 다크모드 대응: colorScheme 기반 색상
    final activeBorderColor = colorScheme.primary;
    // 배경색을 더 연하게 (primary의 8% 투명도)
    final activeBackgroundColor = colorScheme.primary.withValues(alpha: 0.08);
    final inactiveBorderColor = colorScheme.outlineVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: ledgerInfo.isCurrentLedger ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
        side: ledgerInfo.isCurrentLedger
            ? BorderSide(color: activeBorderColor, width: 2)
            : BorderSide(color: inactiveBorderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 아이콘 + 가계부 이름 + 배지 + 수정 버튼
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 원형 아이콘 배경
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ledgerInfo.isCurrentLedger
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: ledgerInfo.isCurrentLedger
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              ledgerInfo.ledger.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (ledgerInfo.isCurrentLedger) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                l10n.shareInUse,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      _buildMemberInfo(context, currentUserId, l10n),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // 수정 버튼 (우상단)
                IconButton(
                  onPressed: onEdit,
                  icon: Icon(
                    Icons.edit,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(40, 40),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: l10n.commonEdit,
                ),
              ],
            ),
            const SizedBox(height: 19),
            // 하단: 초대 상태 + 액션 버튼
            _buildInviteSection(context, l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfo(
    BuildContext context,
    String? currentUserId,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final memberNames = ledgerInfo.members.map((m) {
      if (m.userId == currentUserId) {
        return l10n.shareMe;
      }
      return m.displayName ?? m.email ?? l10n.shareUnknown;
    }).toList();

    return Row(
      children: [
        Icon(Icons.people, size: 14, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${l10n.shareMemberCount(ledgerInfo.members.length, AppConstants.maxMembersPerLedger)} (${memberNames.join(', ')})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.normal,
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildInviteSection(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    // 멤버가 꽉 찬 경우
    if (ledgerInfo.isMemberFull) {
      return _buildStatusRow(
        context,
        l10n,
        statusWidgets: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.shareMemberFull,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        showInviteButton: false,
      );
    }

    // 초대가 없는 경우
    if (ledgerInfo.hasNoInvite) {
      return _buildStatusRow(
        context,
        l10n,
        statusWidgets: [],
        showInviteButton: true,
        inviteEnabled: true,
      );
    }

    // 복수 초대 배지 생성
    final statusWidgets = <Widget>[];
    final pendingInvites = ledgerInfo.pendingInvites;
    final acceptedInvites = ledgerInfo.acceptedInvites;
    final rejectedInvites = ledgerInfo.rejectedInvites;

    // pending 초대가 있으면 취소 버튼과 함께 표시
    if (pendingInvites.isNotEmpty) {
      for (final invite in pendingInvites) {
        statusWidgets.add(
          _buildStatusBadge(
            context,
            l10n.sharePendingAccept,
            invite.inviteeEmail,
            icon: Icons.hourglass_empty_outlined,
            showDeleteButton: true,
            onDelete: () => onCancelInvite?.call(invite.id),
          ),
        );
      }
    }

    // 수락된 초대
    for (final invite in acceptedInvites) {
      statusWidgets.add(
        _buildStatusBadge(
          context,
          l10n.shareAccepted,
          invite.inviteeEmail,
          icon: Icons.check_circle_outlined,
        ),
      );
    }

    // 거부된 초대 (삭제 버튼 포함)
    for (final invite in rejectedInvites) {
      statusWidgets.add(
        _buildStatusBadge(
          context,
          l10n.shareRejected,
          invite.inviteeEmail,
          icon: Icons.block_outlined,
          showDeleteButton: true,
          onDelete: () => onDeleteInvite?.call(invite.id),
        ),
      );
    }

    return _buildStatusRow(
      context,
      l10n,
      statusWidgets: statusWidgets,
      showInviteButton: ledgerInfo.canInvite,
      inviteEnabled: ledgerInfo.canInvite,
    );
  }

  Widget _buildStatusRow(
    BuildContext context,
    AppLocalizations l10n, {
    List<Widget> statusWidgets = const [],
    required bool showInviteButton,
    bool inviteEnabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // 버튼들을 먼저 빌드
    final buttons = <Widget>[];

    // 사용 버튼 (사용중이 아닌 경우에만)
    if (!ledgerInfo.isCurrentLedger) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: onSelectLedger,
          icon: Icon(Icons.check, size: 16, color: colorScheme.primary),
          label: Text(
            l10n.shareUse,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            side: BorderSide(color: colorScheme.outline),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    if (showInviteButton) {
      buttons.add(
        OutlinedButton.icon(
          onPressed: inviteEnabled ? onInviteTap : null,
          icon: Icon(
            Icons.person_add,
            size: 16,
            color: inviteEnabled
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
          label: Text(
            l10n.shareInvite,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: inviteEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            side: BorderSide(
              color: inviteEnabled
                  ? colorScheme.outline
                  : colorScheme.outlineVariant,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      );
    }

    // statusWidgets가 없으면 버튼만 표시
    if (statusWidgets.isEmpty && buttons.isNotEmpty) {
      return Align(
        alignment: Alignment.centerRight,
        child: Wrap(spacing: 8, children: buttons),
      );
    }

    // statusWidgets가 있으면 수직 스택으로 배치
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 복수 배지를 수직으로 나열
        ...statusWidgets.map(
          (widget) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: widget),
        ),
        if (buttons.isNotEmpty) ...[
          const SizedBox(height: 4),
          // Align 사용 - 버튼을 오른쪽 정렬하되 width 제약 문제 없음
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(spacing: 8, children: buttons),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String status,
    String email, {
    required IconData icon,
    bool showDeleteButton = false,
    VoidCallback? onDelete,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // pencil 디자인: 간단한 Row (icon + text)
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$status: $email',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showDeleteButton) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: Icon(
              Icons.close,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
