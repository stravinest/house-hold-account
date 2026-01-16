import 'package:flutter/material.dart';

import '../../../../shared/themes/design_tokens.dart';

/// A progress bar widget that displays the progress towards an asset goal.
///
/// Features:
/// - Percentage indicator positioned above the progress bar
/// - Gradient-filled progress bar with color based on progress level
/// - 0% and 100% labels at the ends
/// - Interactive tap gesture support
///
/// Progress colors:
/// - >= 100%: Primary color (goal achieved)
/// - >= 75%: Tertiary color (almost there)
/// - >= 50%: Secondary color (halfway)
/// - < 50%: Error color (needs improvement)
class AssetGoalProgressBar extends StatelessWidget {
  final double progress;
  final VoidCallback? onTap;

  const AssetGoalProgressBar({
    super.key,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressColor = _getProgressColor(progress, theme);
    final clampedProgress = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final barWidth = constraints.maxWidth;
            final percentPosition = barWidth * clampedProgress;
            final percentText = '${(progress * 100).toStringAsFixed(1)}%';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Percentage indicator positioned above progress
                SizedBox(
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        left: percentPosition,
                        bottom: 0,
                        child: Transform.translate(
                          offset: const Offset(-20, 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: progressColor.withValues(
                                alpha: 0.15,
                              ),
                              borderRadius: BorderRadius.circular(
                                4,
                              ),
                            ),
                            child: Text(
                              percentText,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: progressColor,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),

                // Thin rectangular progress bar
                SizedBox(
                  width: double.infinity,
                  height: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.brightness == Brightness.dark
                          ? Colors.white.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(
                        BorderRadiusToken.xs,
                      ),
                      border: Border.all(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.6)
                            : theme.colorScheme.onSurfaceVariant,
                        width: 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        BorderRadiusToken.xs,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: clampedProgress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                progressColor.withValues(
                                  alpha: 0.9,
                                ),
                                progressColor,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // 0% and 100% labels at ends
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '0%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      '100%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Color _getProgressColor(double progress, ThemeData theme) {
    if (progress >= 1.0) return theme.colorScheme.primary;
    if (progress >= 0.75) return theme.colorScheme.tertiary;
    if (progress >= 0.5) return theme.colorScheme.secondary;
    return theme.colorScheme.error;
  }
}
