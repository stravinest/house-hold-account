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
    final l10n = AppLocalizations.of(context)!;
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    final colorScheme = Theme.of(context).colorScheme;

    // 다크모드 대응: colorScheme 기반 색상
    final activeBorderColor = colorScheme.primary;
    // 배경색을 더 연하게 (primary의 8% 투명도)
    final activeBackgroundColor = colorScheme.primary.withValues(alpha: 0.08);
    final inactiveBorderColor = colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ledgerInfo.isCurrentLedger
            ? activeBackgroundColor
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        border: Border.all(
          color: ledgerInfo.isCurrentLedger
              ? activeBorderColor
              : inactiveBorderColor,
          width: ledgerInfo.isCurrentLedger ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 가계부 이름 + 현재 사용 중 배지 + 수정 버튼
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: ledgerInfo.isCurrentLedger
                            ? activeBorderColor
                            : inactiveBorderColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          ledgerInfo.ledger.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (ledgerInfo.isCurrentLedger) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: activeBorderColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            l10n.shareInUse,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // 수정 버튼 (우상단)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  style: IconButton.styleFrom(
                    foregroundColor: colorScheme.onSurfaceVariant,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  tooltip: l10n.commonEdit,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 중간: 멤버 정보
            _buildMemberInfo(context, currentUserId, l10n),
            const SizedBox(height: 12),
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

    // 멤버가 2명 이상이면 탭 가능
    final isTappable = ledgerInfo.members.length > 1 && onMemberTap != null;

    final content = Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16,
          color: colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 4),
        Text(
          l10n.shareMemberCount(
            ledgerInfo.members.length,
            AppConstants.maxMembersPerLedger,
          ),
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        if (memberNames.isNotEmpty) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '(${memberNames.join(', ')})',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (isTappable) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );

    if (isTappable) {
      return InkWell(
        onTap: onMemberTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      );
    }

    return content;
  }

  Widget _buildInviteSection(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;

    // 멤버가 꽉 찬 경우
    if (ledgerInfo.isMemberFull) {
      return _buildStatusRow(
        context,
        l10n,
        statusWidgets: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.shareMemberFull,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
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

    // 사용 버튼 (사용중이 아닌 경우에만)
    final useButton = !ledgerInfo.isCurrentLedger
        ? OutlinedButton(
            onPressed: onSelectLedger,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.primary,
              side: BorderSide(color: colorScheme.primary),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            child: Text(l10n.shareUse),
          )
        : null;

    final inviteButton = showInviteButton
        ? OutlinedButton.icon(
            onPressed: inviteEnabled ? onInviteTap : null,
            icon: const Icon(Icons.person_add, size: 16),
            label: Text(l10n.shareInvite),
            style: OutlinedButton.styleFrom(
              foregroundColor: inviteEnabled
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              side: BorderSide(
                color: inviteEnabled
                    ? colorScheme.primary
                    : colorScheme.outlineVariant,
              ),
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        : null;

    final buttons = <Widget>[
      if (useButton != null) useButton,
      if (useButton != null && inviteButton != null) const SizedBox(width: 8),
      if (inviteButton != null) inviteButton,
    ];

    // statusWidgets가 없으면 버튼만 오른쪽 정렬
    if (statusWidgets.isEmpty) {
      return Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons);
    }

    // statusWidgets가 있으면 수직 스택으로 배치
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 복수 배지를 수직으로 나열
        ...statusWidgets.map(
          (widget) =>
              Padding(padding: const EdgeInsets.only(bottom: 8), child: widget),
        ),
        if (buttons.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.end, children: buttons),
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
    // 통일된 중립 색상 사용
    final badgeColor = colorScheme.onSurfaceVariant;
    final backgroundColor = colorScheme.surfaceContainerHigh;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 아이콘 + 상태 텍스트 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: badgeColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: colorScheme.surface),
                const SizedBox(width: 4),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.surface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // 삭제 버튼 (X)
          if (showDeleteButton) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(
                Icons.close,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
