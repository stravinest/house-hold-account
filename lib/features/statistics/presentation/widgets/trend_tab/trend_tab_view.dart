import 'package:flutter/material.dart';

import '../common/period_filter.dart';
import '../common/statistics_type_filter.dart';
import 'trend_bar_chart.dart';
import 'trend_detail_list.dart';

class TrendTabView extends StatelessWidget {
  const TrendTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 기간 필터 (월별/연별)
          const Center(child: PeriodFilter()),
          const SizedBox(height: 12),

          // 타입 필터 (수입/지출/저축)
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
                    '추이',
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
                    '상세 내역',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const TrendDetailList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
