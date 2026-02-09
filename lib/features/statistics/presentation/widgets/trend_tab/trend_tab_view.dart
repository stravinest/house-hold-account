import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../l10n/generated/app_localizations.dart';
import '../../providers/statistics_provider.dart';
import 'trend_bar_chart.dart';
import 'trend_filter_section.dart';
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
            // 필터 (기간 드롭다운 + 타입 토글)
            const TrendFilterSection(),
            const SizedBox(height: 16),

            // 막대 그래프
            Container(
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
                  Text(
                    l10n.statisticsTrend,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const TrendBarChart(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 상세 리스트
            Container(
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
