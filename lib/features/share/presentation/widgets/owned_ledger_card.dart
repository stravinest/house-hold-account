import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/constants/app_constants.dart';
import '../providers/share_provider.dart';

class OwnedLedgerCard extends ConsumerWidget {
  final LedgerWithInviteInfo ledgerInfo;
  final VoidCallback? onInviteTap;
  final VoidCallback? onCancelInvite;
  final VoidCallback? onSelectLedger;

  const OwnedLedgerCard({
    super.key,
    required this.ledgerInfo,
    this.onInviteTap,
    this.onCancelInvite,
    this.onSelectLedger,
  });

  // 사용중인 가계부 (녹색)
  static const _activeBorderColor = Color(0xFF4CAF50);
  static const _activeBackgroundColor = Color(0xFFE8F5E9);
  // 사용중이 아닌 가계부 (회색)
  static const _inactiveBorderColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = SupabaseConfig.auth.currentUser?.id;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: ledgerInfo.isCurrentLedger
            ? _activeBackgroundColor
            : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ledgerInfo.isCurrentLedger
              ? _activeBorderColor
              : _inactiveBorderColor,
          width: ledgerInfo.isCurrentLedger ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 가계부 이름 + 현재 사용 중 배지 + 사용 버튼
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: ledgerInfo.isCurrentLedger
                            ? _activeBorderColor
                            : _inactiveBorderColor,
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
                            color: _activeBorderColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '사용 중',
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
                // 사용 버튼 (사용중이 아닌 경우에만)
                if (!ledgerInfo.isCurrentLedger)
                  TextButton(
                    onPressed: onSelectLedger,
                    style: TextButton.styleFrom(
                      foregroundColor: _activeBorderColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      minimumSize: const Size(0, 32),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('사용'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // 중간: 멤버 정보
            _buildMemberInfo(context, currentUserId),
            const SizedBox(height: 12),
            // 하단: 초대 상태 + 액션 버튼
            _buildInviteSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberInfo(BuildContext context, String? currentUserId) {
    final colorScheme = Theme.of(context).colorScheme;
    final memberNames = ledgerInfo.members.map((m) {
      if (m.userId == currentUserId) {
        return '나';
      }
      return m.displayName ?? m.email ?? '알 수 없음';
    }).toList();

    return Row(
      children: [
        Icon(
          Icons.people_outline,
          size: 16,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        Text(
          '멤버 ${ledgerInfo.members.length}/${AppConstants.maxMembersPerLedger}명',
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withOpacity(0.7),
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
      ],
    );
  }

  Widget _buildInviteSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // 멤버가 꽉 찬 경우
    if (ledgerInfo.isMemberFull) {
      return _buildStatusRow(
        context,
        statusWidget: Container(
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
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                '멤버 가득 참',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        showInviteButton: false,
      );
    }

    // 초대가 없는 경우
    if (ledgerInfo.hasNoInvite) {
      return _buildStatusRow(
        context,
        statusWidget: null,
        showInviteButton: true,
        inviteEnabled: true,
      );
    }

    final invite = ledgerInfo.sentInvite!;

    // 수락 대기중
    if (ledgerInfo.hasPendingInvite) {
      return _buildPendingInviteRow(
        context,
        statusWidget: _buildStatusBadge(
          context,
          '수락 대기중',
          invite.inviteeEmail,
          Colors.orange,
          Colors.orange[50]!,
        ),
      );
    }

    // 수락됨
    if (ledgerInfo.hasAcceptedInvite) {
      return _buildStatusRow(
        context,
        statusWidget: _buildStatusBadge(
          context,
          '수락됨',
          invite.inviteeEmail,
          colorScheme.tertiary,
          colorScheme.tertiaryContainer,
        ),
        showInviteButton: false,
      );
    }

    // 거부됨
    if (ledgerInfo.hasRejectedInvite) {
      return _buildStatusRow(
        context,
        statusWidget: _buildStatusBadge(
          context,
          '수락 거부됨',
          invite.inviteeEmail,
          colorScheme.error,
          colorScheme.errorContainer,
        ),
        showInviteButton: true,
        inviteEnabled: true,
      );
    }

    // 기본 (만료 등)
    return _buildStatusRow(
      context,
      statusWidget: null,
      showInviteButton: true,
      inviteEnabled: true,
    );
  }

  // 수락 대기중 상태 전용 Row (초대취소 버튼 포함)
  Widget _buildPendingInviteRow(
    BuildContext context, {
    required Widget statusWidget,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(child: statusWidget),
        const SizedBox(width: 8),
        TextButton(
          onPressed: onCancelInvite,
          style: TextButton.styleFrom(
            foregroundColor: colorScheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          child: const Text('초대취소'),
        ),
      ],
    );
  }

  Widget _buildStatusRow(
    BuildContext context, {
    Widget? statusWidget,
    required bool showInviteButton,
    bool inviteEnabled = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final inviteButton = showInviteButton
        ? ElevatedButton.icon(
            onPressed: inviteEnabled ? onInviteTap : null,
            icon: const Icon(Icons.person_add, size: 16),
            label: const Text('초대'),
            style: ElevatedButton.styleFrom(
              backgroundColor: inviteEnabled
                  ? _activeBorderColor
                  : colorScheme.surfaceContainerHighest,
              foregroundColor: inviteEnabled
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
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

    // statusWidget이 없으면 버튼만 오른쪽 정렬
    if (statusWidget == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [if (inviteButton != null) inviteButton],
      );
    }

    // statusWidget이 있으면 좌우 배치
    return Row(
      children: [
        Expanded(child: statusWidget),
        if (inviteButton != null) ...[const SizedBox(width: 8), inviteButton],
      ],
    );
  }

  Widget _buildStatusBadge(
    BuildContext context,
    String status,
    String email,
    Color color,
    Color backgroundColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              email,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
