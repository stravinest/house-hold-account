import 'package:flutter/material.dart';

import '../../../../../core/utils/color_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../ledger/domain/entities/ledger.dart';
import '../../providers/statistics_provider.dart';

/// 공유 가계부용 유저별 탭 공통 위젯
/// 카테고리 탭과 결제수단 탭에서 동일하게 사용
class MemberTabs extends StatelessWidget {
  final List<LedgerMember> members;
  final SharedStatisticsState sharedState;
  final ValueChanged<SharedStatisticsState> onStateChanged;

  const MemberTabs({
    super.key,
    required this.members,
    required this.sharedState,
    required this.onStateChanged,
  });

  static String getDisplayName(LedgerMember member, AppLocalizations l10n) {
    if (member.displayName != null && member.displayName!.isNotEmpty) {
      return member.displayName!;
    }
    if (member.email != null && member.email!.isNotEmpty) {
      return member.email!.split('@').first;
    }
    return l10n.user;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        children: [
          // 합계 버튼
          Expanded(
            child: _buildTabButton(
              context: context,
              label: l10n.statisticsFilterCombined,
              isSelected:
                  sharedState.mode == SharedStatisticsMode.combined,
              userColor: null,
              onTap: () {
                onStateChanged(
                  const SharedStatisticsState(
                    mode: SharedStatisticsMode.combined,
                  ),
                );
              },
            ),
          ),

          // 사용자별 버튼
          ...members.map((member) {
            final isSelected =
                sharedState.mode == SharedStatisticsMode.singleUser &&
                    sharedState.selectedUserId == member.userId;
            final displayName = getDisplayName(member, l10n);

            return Expanded(
              child: _buildTabButton(
                context: context,
                label: displayName,
                isSelected: isSelected,
                userColor: member.color,
                onTap: () {
                  onStateChanged(
                    SharedStatisticsState(
                      mode: SharedStatisticsMode.singleUser,
                      selectedUserId: member.userId,
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required String? userColor,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final parsedUserColor = ColorUtils.parseHexColor(
      userColor,
      fallback: const Color(0xFF9E9E9E),
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 유저 색상 동그라미 (유저 탭일 경우만)
            if (userColor != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color:
                      isSelected ? colorScheme.onPrimary : parsedUserColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            // 라벨 (긴 텍스트 말줄임 처리)
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w500 : FontWeight.normal,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : (userColor != null
                          ? parsedUserColor
                          : colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
