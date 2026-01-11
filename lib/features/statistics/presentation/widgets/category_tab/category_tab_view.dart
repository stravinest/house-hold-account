import 'package:flutter/material.dart';

import '../common/statistics_type_filter.dart';
import 'category_donut_chart.dart';
import 'category_ranking_list.dart';
import 'category_summary_card.dart';

class CategoryTabView extends StatelessWidget {
  const CategoryTabView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 타입 필터 (수입/지출/저축)
          const Center(child: StatisticsTypeFilter()),
          const SizedBox(height: 16),

          // 요약 카드 (전월 대비 포함)
          const CategorySummaryCard(),
          const SizedBox(height: 16),

          // 도넛 차트
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '카테고리별 분포',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const CategoryDonutChart(),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 순위 리스트
          Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    '카테고리별 순위',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                const CategoryRankingList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
