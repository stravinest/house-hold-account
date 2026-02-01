import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../ledger/domain/entities/ledger.dart';
import '../../../../share/presentation/providers/share_provider.dart';
import '../../providers/statistics_provider.dart';

/// 공유 가계부 통계용 사용자 필터 위젯 - Pencil memberTabs (nkQZa) 디자인 적용
/// [합쳐서] [사용자1] [사용자2] [겹쳐서] 형태로 표시
class SharedUserFilter extends ConsumerWidget {
  const SharedUserFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final sharedState = ref.watch(sharedStatisticsStateProvider);

    return membersAsync.when(
      data: (members) {
        if (members.length < 2) {
          return const SizedBox.shrink();
        }

        // Pencil memberTabs (nkQZa) 디자인 적용
        final colorScheme = Theme.of(context).colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(2),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 합쳐서 버튼
                _buildTabButton(
                  context: context,
                  label: l10n.statisticsFilterCombined,
                  isSelected: sharedState.mode == SharedStatisticsMode.combined,
                  onTap: () {
                    ref
                        .read(sharedStatisticsStateProvider.notifier)
                        .state = const SharedStatisticsState(
                      mode: SharedStatisticsMode.combined,
                    );
                  },
                ),

                // 사용자별 버튼
                ...members.map((member) {
                  final isSelected =
                      sharedState.mode == SharedStatisticsMode.singleUser &&
                      sharedState.selectedUserId == member.userId;
                  final displayName = _getDisplayName(member);

                  return _buildTabButton(
                    context: context,
                    label: displayName,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(sharedStatisticsStateProvider.notifier)
                          .state = SharedStatisticsState(
                        mode: SharedStatisticsMode.singleUser,
                        selectedUserId: member.userId,
                      );
                    },
                  );
                }),

                // 겹쳐서 버튼
                _buildTabButton(
                  context: context,
                  label: l10n.statisticsFilterOverlay,
                  isSelected: sharedState.mode == SharedStatisticsMode.overlay,
                  onTap: () {
                    ref
                        .read(sharedStatisticsStateProvider.notifier)
                        .state = const SharedStatisticsState(
                      mode: SharedStatisticsMode.overlay,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (e, stack) => const SizedBox.shrink(),
    );
  }

  String _getDisplayName(LedgerMember member) {
    if (member.displayName != null && member.displayName!.isNotEmpty) {
      return member.displayName!;
    }
    if (member.email != null && member.email!.isNotEmpty) {
      return member.email!.split('@').first;
    }
    return 'User';
  }

  /// Pencil memberTabs 디자인 - 탭 버튼
  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
