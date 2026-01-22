import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../domain/entities/ledger_invite.dart';

class InvitedLedgerCard extends StatelessWidget {
  final LedgerInvite invite;
  final bool isCurrentLedger;
  final bool isLoading;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onLeave;
  final VoidCallback? onSelectLedger;

  const InvitedLedgerCard({
    super.key,
    required this.invite,
    this.isCurrentLedger = false,
    this.isLoading = false,
    this.onAccept,
    this.onReject,
    this.onLeave,
    this.onSelectLedger,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isAccepted = invite.isAccepted;
    final colorScheme = Theme.of(context).colorScheme;

    // 다크모드 대응: colorScheme 기반 색상
    final activeBorderColor = colorScheme.primary;
    // 배경색을 더 연하게 (primary의 8% 투명도)
    final activeBackgroundColor = colorScheme.primary.withOpacity(0.08);
    final inactiveBorderColor = colorScheme.outlineVariant;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentLedger ? activeBackgroundColor : colorScheme.surface,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        border: Border.all(
          color: isCurrentLedger ? activeBorderColor : inactiveBorderColor,
          width: isCurrentLedger ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.05),
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
            // 상단: 가계부 이름 + 사용중 배지
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 20,
                        color: isCurrentLedger
                            ? activeBorderColor
                            : inactiveBorderColor,
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
              ],
            ),
            const SizedBox(height: 8),
            // 중간: 초대자 정보
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.shareInviterLedger(
                      invite.inviterEmail ?? l10n.shareUnknown,
                    ),
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withOpacity(0.7),
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
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    // pending 상태: 수락/거부 버튼 (동일한 스타일 + 아이콘 구분)
    if (invite.isPending) {
      final buttonStyle = OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurfaceVariant,
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      );

      return Row(
        children: [
          const Spacer(),
          // 거부 버튼
          OutlinedButton.icon(
            onPressed: isLoading ? null : onReject,
            style: buttonStyle,
            icon: const Icon(Icons.close, size: 16),
            label: Text(l10n.shareReject),
          ),
          const SizedBox(width: 8),
          // 수락 버튼
          OutlinedButton.icon(
            onPressed: isLoading ? null : onAccept,
            style: buttonStyle,
            icon: const Icon(Icons.check, size: 16),
            label: Text(l10n.shareAccept),
          ),
        ],
      );
    }

    // accepted 상태: 멤버 참여중 표시 + 사용/탈퇴 버튼
    if (invite.isAccepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 사용 버튼 (사용중이 아닌 경우에만)
              if (!isCurrentLedger) ...[
                OutlinedButton(
                  onPressed: isLoading ? null : onSelectLedger,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Text(l10n.shareUse),
                ),
                const SizedBox(width: 8),
              ],
              OutlinedButton(
                onPressed: isLoading ? null : onLeave,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.error,
                  side: BorderSide(color: colorScheme.error),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(l10n.shareLeave),
              ),
            ],
          ),
        ],
      );
    }

    // rejected 상태: 거부됨 표시
    if (invite.isRejected) {
      return Row(
        children: [
          Icon(Icons.cancel_outlined, size: 16, color: colorScheme.error),
          const SizedBox(width: 6),
          Text(
            l10n.shareRejected,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.error,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // expired 상태: 만료됨 표시
    if (invite.isExpired) {
      return Row(
        children: [
          Icon(
            Icons.schedule_outlined,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.shareExpired,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    // 기타 상태
    return const SizedBox.shrink();
  }
}
