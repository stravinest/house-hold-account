import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/asset_statistics.dart';

class AssetTypeChart extends StatelessWidget {
  final AssetTypeBreakdown breakdown;

  const AssetTypeChart({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.total == 0) {
      return const Center(child: Text('자산 데이터가 없습니다'));
    }

    return PieChart(
      PieChartData(
        sections: _buildSections(context),
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  List<PieChartSectionData> _buildSections(BuildContext context) {
    final sections = <PieChartSectionData>[];

    if (breakdown.savingAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.savingAmount.toDouble(),
          title: '저축\n${(breakdown.savingRatio * 100).toStringAsFixed(1)}%',
          color: const Color(0xFF4CAF50),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (breakdown.investmentAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.investmentAmount.toDouble(),
          title: '투자\n${(breakdown.investmentRatio * 100).toStringAsFixed(1)}%',
          color: const Color(0xFF2196F3),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (breakdown.realEstateAmount > 0) {
      sections.add(
        PieChartSectionData(
          value: breakdown.realEstateAmount.toDouble(),
          title:
              '부동산\n${(breakdown.realEstateRatio * 100).toStringAsFixed(1)}%',
          color: const Color(0xFFFF9800),
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return sections;
  }
}

class AssetTypeBreakdownCard extends StatelessWidget {
  final AssetTypeBreakdown breakdown;

  const AssetTypeBreakdownCard({super.key, required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '자산 유형별 분포',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (breakdown.total == 0)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Text('자산 데이터가 없습니다'),
                ),
              )
            else ...[
              SizedBox(
                height: 200,
                child: AssetTypeChart(breakdown: breakdown),
              ),
              const SizedBox(height: 24),
              _buildLegend(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Column(
      children: [
        _buildLegendItem('저축', breakdown.savingAmount, const Color(0xFF4CAF50)),
        const SizedBox(height: 8),
        _buildLegendItem(
          '투자',
          breakdown.investmentAmount,
          const Color(0xFF2196F3),
        ),
        const SizedBox(height: 8),
        _buildLegendItem(
          '부동산',
          breakdown.realEstateAmount,
          const Color(0xFFFF9800),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, int amount, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        Text(
          '₩${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
