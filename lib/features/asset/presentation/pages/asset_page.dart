import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../providers/asset_provider.dart';
import '../widgets/asset_category_list.dart';
import '../widgets/asset_donut_chart.dart';
import '../widgets/asset_goal_card_simple.dart';
import '../widgets/asset_line_chart.dart';
import '../widgets/asset_summary_card.dart';

class AssetPage extends ConsumerWidget {
  const AssetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final statisticsAsync = ref.watch(assetStatisticsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(assetStatisticsProvider);
        await ref.read(assetStatisticsProvider.future);
      },
      child: statisticsAsync.when(
        data: (statistics) => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AssetSummaryCard(
                totalAmount: statistics.totalAmount,
                monthlyChange: statistics.monthlyChange,
                ledgerId: ref.watch(selectedLedgerIdProvider),
              ),
              if (ref.watch(selectedLedgerIdProvider) != null)
                AssetGoalCardSimple(
                  ledgerId: ref.watch(selectedLedgerIdProvider)!,
                ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.assetChange,
                child: AssetLineChart(monthly: statistics.monthly),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.assetCategoryDistribution,
                child: AssetDonutChart(byCategory: statistics.byCategory),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: l10n.assetList,
                child: AssetCategoryList(assetStatistics: statistics),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        loading: () => SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 80, height: 16),
                    SizedBox(height: 8),
                    SkeletonLine(width: 160, height: 32),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        SkeletonBox(
                          width: 16,
                          height: 16,
                          borderRadius: BorderRadiusToken.xs,
                        ),
                        SizedBox(width: 4),
                        SkeletonLine(width: 100, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            SkeletonBox(
                              width: 28,
                              height: 28,
                              borderRadius: BorderRadiusToken.xs,
                            ),
                            SizedBox(width: 8),
                            SkeletonLine(width: 50, height: 16),
                          ],
                        ),
                        Row(
                          children: [
                            SkeletonBox(
                              width: 20,
                              height: 20,
                              borderRadius: BorderRadiusToken.xs,
                            ),
                            SizedBox(width: 8),
                            SkeletonBox(
                              width: 20,
                              height: 20,
                              borderRadius: BorderRadiusToken.xs,
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    SkeletonLine(width: 150, height: 28),
                    SizedBox(height: 16),
                    SkeletonLine(width: double.infinity, height: 12),
                    SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonLine(width: 80, height: 14),
                        SkeletonLine(width: 100, height: 14),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 100, height: 18),
                    SizedBox(height: 16),
                    SkeletonBox(
                      width: double.infinity,
                      height: 200,
                      borderRadius: BorderRadiusToken.md,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLine(width: 120, height: 18),
                    SizedBox(height: 16),
                    Center(child: SkeletonCircle(size: 180)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonLine(width: 80, height: 18),
                    const SizedBox(height: 16),
                    ...List.generate(
                      3,
                      (index) => const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(child: SkeletonLine(height: 16)),
                            SizedBox(width: 16),
                            SkeletonLine(width: 80, height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
        error: (error, stackTrace) =>
            Center(child: Text(l10n.errorWithMessage(error.toString()))),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
