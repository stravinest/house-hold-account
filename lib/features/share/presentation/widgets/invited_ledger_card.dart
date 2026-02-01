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
    final activeBackgroundColor = colorScheme.primary.withValues(alpha: 0.08);
    final inactiveBorderColor = colorScheme.outlineVariant;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentLedger ? 2 : 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(BorderRadiusToken.lg),
        side: isCurrentLedger
            ? BorderSide(color: activeBorderColor, width: 2)
            : BorderSide(color: inactiveBorderColor, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단: 아이콘 + 가계부 이름 + 배지
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 원형 아이콘 배경
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCurrentLedger
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    Icons.menu_book,
                    color: isCurrentLedger
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
                      // 가계부 이름 + 배지 (같은 Row에)
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              invite.ledgerName ?? l10n.ledgerTitle,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentLedger) ...[
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
                      // 초대자 정보
                      Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              l10n.shareInviterLedger(
                                invite.inviterEmail ?? l10n.shareUnknown,
                              ),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 19),
            // 하단: 상태별 액션 버튼
            _buildActionRow(context),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    // pending 상태: 수락/거부 버튼
    if (invite.isPending) {
      return Align(
        alignment: Alignment.centerRight,
        child: Wrap(
          spacing: 8,
          children: [
            // 거부 버튼
            OutlinedButton.icon(
              onPressed: isLoading ? null : onReject,
              icon: Icon(Icons.close, size: 16, color: colorScheme.error),
              label: Text(
                l10n.shareReject,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.error,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                side: BorderSide(color: colorScheme.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            // 수락 버튼
            OutlinedButton.icon(
              onPressed: isLoading ? null : onAccept,
              icon: Icon(Icons.check, size: 16, color: colorScheme.primary),
              label: Text(
                l10n.shareAccept,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.primary,
                ),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                side: BorderSide(color: colorScheme.outline),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    // accepted 상태: 멤버 참여중 표시 + 사용/탈퇴 버튼
    if (invite.isAccepted) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.check, size: 16, color: colorScheme.primary),
              const SizedBox(width: 6),
              Text(
                l10n.shareMemberParticipating,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              children: [
                // 사용 버튼 (사용중이 아닌 경우에만)
                if (!isCurrentLedger)
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : onSelectLedger,
                    icon: Icon(
                      Icons.check,
                      size: 16,
                      color: colorScheme.primary,
                    ),
                    label: Text(
                      l10n.shareUse,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.primary,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      side: BorderSide(color: colorScheme.outline),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onLeave,
                  icon: Icon(Icons.logout, size: 16, color: colorScheme.error),
                  label: Text(
                    l10n.shareLeave,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.error,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    side: BorderSide(color: colorScheme.error),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
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
