import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../domain/entities/ledger_invite.dart';

class InvitedLedgerCard extends StatelessWidget {
  final LedgerInvite invite;
  final bool isCurrentLedger;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onLeave;
  final VoidCallback? onSelectLedger;

  const InvitedLedgerCard({
    super.key,
    required this.invite,
    this.isCurrentLedger = false,
    this.onAccept,
    this.onReject,
    this.onLeave,
    this.onSelectLedger,
  });

  // 사용중인 가계부 (녹색)
  static const _activeBorderColor = Color(0xFF4CAF50);
  static const _activeBackgroundColor = Color(0xFFE8F5E9);
  // 사용중이 아닌 가계부 (회색)
  static const _inactiveBorderColor = Color(0xFFBDBDBD);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAccepted = invite.isAccepted;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentLedger ? _activeBackgroundColor : colorScheme.surface,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        border: Border.all(
          color: isCurrentLedger ? _activeBorderColor : _inactiveBorderColor,
          width: isCurrentLedger ? 2.5 : 1.5,
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
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 가계부 이름 + 사용중 배지 + 사용 버튼
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: isCurrentLedger
                            ? _activeBorderColor
                            : _inactiveBorderColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          invite.ledgerName ?? l10n.ledgerTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentLedger) ...[
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
                // 사용 버튼 (수락함 상태이고 사용중이 아닌 경우에만)
                if (isAccepted && !isCurrentLedger)
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
                    child: Text(l10n.shareUse),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // 중간: 초대자 정보
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.shareInviterLedger(
                      invite.inviterEmail ?? l10n.shareUnknown,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            // 하단: 상태별 액션 버튼
            const SizedBox(height: 12),
            _buildActionRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    // pending 상태: 수락/거부 버튼
    if (invite.isPending) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // 거부 버튼
          OutlinedButton(
            onPressed: onReject,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.7),
              side: BorderSide(color: colorScheme.onSurfaceVariant),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(l10n.shareReject),
          ),
          const SizedBox(width: 8),
          // 수락 버튼
          ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: _activeBorderColor,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: Text(l10n.shareAccept),
          ),
        ],
      );
    }

    // accepted 상태: 멤버 참여중 표시 + 탈퇴 버튼
    if (invite.isAccepted) {
      return Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: colorScheme.tertiary,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.shareMemberParticipating,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.tertiary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          // 탈퇴 버튼
          TextButton(
            onPressed: onLeave,
            style: TextButton.styleFrom(
              foregroundColor: colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(l10n.shareLeave),
          ),
        ],
      );
    }

    // 기타 상태
    return const SizedBox.shrink();
  }
}
