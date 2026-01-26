import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../../../ledger/domain/entities/ledger.dart';
import '../../../../share/presentation/providers/share_provider.dart';
import '../../providers/statistics_provider.dart';

/// 공유 가계부 통계용 사용자 필터 위젯
/// [합쳐서] [사용자1] [사용자2] [겹쳐서] 형태로 표시
class SharedUserFilter extends ConsumerWidget {
  const SharedUserFilter({super.key});

  Color _parseColor(String? colorString) {
    if (colorString == null) return const Color(0xFF4CAF50);
    try {
      final colorValue = int.parse(colorString.replaceFirst('#', '0xFF'));
      return Color(colorValue);
    } catch (e) {
      return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final sharedState = ref.watch(sharedStatisticsStateProvider);

    return membersAsync.when(
      data: (members) {
        if (members.length < 2) {
          return const SizedBox.shrink();
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 합쳐서 버튼
              _buildFilterChip(
                context: context,
                label: l10n.statisticsFilterCombined,
                isSelected: sharedState.mode == SharedStatisticsMode.combined,
                onTap: () {
                  ref.read(sharedStatisticsStateProvider.notifier).state =
                      const SharedStatisticsState(
                    mode: SharedStatisticsMode.combined,
                  );
                },
              ),
              const SizedBox(width: 8),

              // 사용자별 버튼
              ...members.map((member) {
                final isSelected =
                    sharedState.mode == SharedStatisticsMode.singleUser &&
                        sharedState.selectedUserId == member.userId;
                final userColor = _parseColor(member.color);
                final displayName = _getDisplayName(member);

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildUserChip(
                    context: context,
                    label: displayName,
                    color: userColor,
                    isSelected: isSelected,
                    onTap: () {
                      ref.read(sharedStatisticsStateProvider.notifier).state =
                          SharedStatisticsState(
                        mode: SharedStatisticsMode.singleUser,
                        selectedUserId: member.userId,
                      );
                    },
                  ),
                );
              }),

              // 겹쳐서 버튼
              _buildFilterChip(
                context: context,
                label: l10n.statisticsFilterOverlay,
                isSelected: sharedState.mode == SharedStatisticsMode.overlay,
                onTap: () {
                  ref.read(sharedStatisticsStateProvider.notifier).state =
                      const SharedStatisticsState(
                    mode: SharedStatisticsMode.overlay,
                  );
                },
                isPrimary: true,
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 36,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
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

  Widget _buildFilterChip({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected
          ? (isPrimary ? colorScheme.primary : colorScheme.secondaryContainer)
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isSelected
                  ? (isPrimary
                      ? colorScheme.onPrimary
                      : colorScheme.onSecondaryContainer)
                  : colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserChip({
    required BuildContext context,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: isSelected ? color.withOpacity(0.2) : colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : colorScheme.outline.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: isSelected ? color : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
