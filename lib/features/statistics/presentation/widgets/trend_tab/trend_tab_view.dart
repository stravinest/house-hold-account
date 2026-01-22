import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/statistics_provider.dart';
import '../common/period_filter.dart';
import '../common/statistics_type_filter.dart';
import 'trend_bar_chart.dart';
import 'trend_detail_list.dart';

class TrendTabView extends ConsumerWidget {
  const TrendTabView({super.key});

  Future<void> _refreshTrendData(WidgetRef ref) async {
    ref.invalidate(monthlyTrendWithAverageProvider);
    ref.invalidate(yearlyTrendWithAverageProvider);

    // 실제 데이터 로딩 완료를 기다림
    await Future.wait([
      ref.read(monthlyTrendWithAverageProvider.future),
      ref.read(yearlyTrendWithAverageProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return RefreshIndicator(
      onRefresh: () => _refreshTrendData(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 기간 필터 (월별/연별)
          const Center(child: PeriodFilter()),
          const SizedBox(height: 12),

          // 타입 필터 (수입/지출/자산)
          const Center(child: StatisticsTypeFilter()),
          const SizedBox(height: 16),

          // 막대 그래프
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.statisticsTrend,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const TrendBarChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 상세 리스트
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.statisticsDetail,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const TrendDetailList(),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
