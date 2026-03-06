import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../statistics/domain/entities/statistics_entities.dart';
import '../providers/asset_provider.dart';

class AssetLineChart extends ConsumerStatefulWidget {
  const AssetLineChart({super.key});

  @override
  ConsumerState<AssetLineChart> createState() => _AssetLineChartState();
}

class _AssetLineChartState extends ConsumerState<AssetLineChart> {
  int? _selectedIndex;
  TrendPeriod? _previousPeriod;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final period = ref.watch(assetChartPeriodProvider);

    // 기간 전환 시 선택 인덱스 리셋
    if (_previousPeriod != null && _previousPeriod != period) {
      _selectedIndex = null;
    }
    _previousPeriod = period;

    if (period == TrendPeriod.yearly) {
      return _buildYearlyChart(context, l10n, theme);
    }
    return _buildMonthlyChart(context, l10n, theme);
  }

  Widget _buildMonthlyChart(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final monthlyAsync = ref.watch(assetMonthlyChartWithLoanProvider);

    return monthlyAsync.when(
      data: (monthly) {
        if (monthly.isEmpty) {
          return _buildEmptyState(l10n, theme);
        }

        final amounts = monthly.map((m) => m.amount).toList();
        final maxY = _calculateMaxY(amounts);
        final minY = _calculateMinY(amounts);
        final spots = _buildSpots(amounts);

        // 초기 선택: 마지막 데이터 포인트
        final effectiveIndex =
            _selectedIndex?.clamp(0, monthly.length - 1) ?? monthly.length - 1;

        return _buildChartWithHeader(
          theme: theme,
          spots: spots,
          dataLength: monthly.length,
          maxY: maxY,
          minY: minY,
          selectedIndex: effectiveIndex,
          selectedLabel:
              '${monthly[effectiveIndex].year}.${monthly[effectiveIndex].month.toString().padLeft(2, '0')}',
          selectedAmount: amounts[effectiveIndex],
          bottomTitleBuilder: (index) {
            if (index >= 0 && index < monthly.length) {
              return l10n.statisticsMonthLabel(monthly[index].month);
            }
            return null;
          },
          tooltipBuilder: (index) {
            if (index >= 0 && index < monthly.length) {
              final item = monthly[index];
              return '${item.year}.${item.month.toString().padLeft(2, '0')}\n${NumberFormatUtils.currency.format(item.amount)}';
            }
            return null;
          },
        );
      },
      loading: () => const AspectRatio(
        aspectRatio: 1.7,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildYearlyChart(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final yearlyAsync = ref.watch(assetYearlyChartWithLoanProvider);

    return yearlyAsync.when(
      data: (yearly) {
        if (yearly.isEmpty) {
          return _buildEmptyState(l10n, theme);
        }

        final amounts = yearly.map((y) => y.amount).toList();
        final maxY = _calculateMaxY(amounts);
        final minY = _calculateMinY(amounts);
        final spots = _buildSpots(amounts);

        // 초기 선택: 마지막 데이터 포인트
        final effectiveIndex =
            _selectedIndex?.clamp(0, yearly.length - 1) ?? yearly.length - 1;

        return _buildChartWithHeader(
          theme: theme,
          spots: spots,
          dataLength: yearly.length,
          maxY: maxY,
          minY: minY,
          selectedIndex: effectiveIndex,
          selectedLabel: '${yearly[effectiveIndex].year}',
          selectedAmount: amounts[effectiveIndex],
          bottomTitleBuilder: (index) {
            if (index >= 0 && index < yearly.length) {
              return l10n.statisticsYearLabel(yearly[index].year);
            }
            return null;
          },
          tooltipBuilder: (index) {
            if (index >= 0 && index < yearly.length) {
              final item = yearly[index];
              return '${item.year}\n${NumberFormatUtils.currency.format(item.amount)}';
            }
            return null;
          },
        );
      },
      loading: () => const AspectRatio(
        aspectRatio: 1.7,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Center(child: Text(e.toString())),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          l10n.assetNoAssetData,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChartWithHeader({
    required ThemeData theme,
    required List<FlSpot> spots,
    required int dataLength,
    required double maxY,
    required double minY,
    required int selectedIndex,
    required String selectedLabel,
    required int selectedAmount,
    required String? Function(int index) bottomTitleBuilder,
    required String? Function(int index) tooltipBuilder,
  }) {
    return Column(
      children: [
        // 선택된 시점 + 금액 표시
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            children: [
              Text(
                selectedLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                NumberFormatUtils.currency.format(selectedAmount),
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        _buildChart(
          theme: theme,
          spots: spots,
          dataLength: dataLength,
          maxY: maxY,
          minY: minY,
          selectedIndex: selectedIndex,
          bottomTitleBuilder: bottomTitleBuilder,
          tooltipBuilder: tooltipBuilder,
        ),
      ],
    );
  }

  Widget _buildChart({
    required ThemeData theme,
    required List<FlSpot> spots,
    required int dataLength,
    required double maxY,
    required double minY,
    required int selectedIndex,
    required String? Function(int index) bottomTitleBuilder,
    required String? Function(int index) tooltipBuilder,
  }) {
    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.only(
          right: 18,
          left: 12,
          top: 24,
          bottom: 12,
        ),
        child: LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: false,
                color: theme.colorScheme.primary,
                barWidth: 3,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    final isSelected = selectedIndex == index;
                    return FlDotCirclePainter(
                      radius: isSelected ? 6 : 4,
                      color: theme.colorScheme.primary,
                      strokeWidth: isSelected ? 3 : 2,
                      strokeColor: theme.colorScheme.surface,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    final title = bottomTitleBuilder(index);
                    if (title != null) {
                      final isSelected = selectedIndex == index;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedIndex = index),
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            title,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 50,
                  getTitlesWidget: (value, meta) {
                    if (value == maxY || value == 0) {
                      return Text(
                        NumberFormatUtils.currency.format(value.toInt()),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY > 0 ? maxY / 4 : 25,
              getDrawingHorizontalLine: (value) {
                return FlLine(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.5,
                  ),
                  strokeWidth: 1,
                );
              },
            ),
            minX: 0,
            maxX: (dataLength - 1).toDouble(),
            minY: minY,
            maxY: maxY,
            lineTouchData: LineTouchData(
              touchCallback: (event, response) {
                if (event is! FlTapUpEvent && event is! FlPanUpdateEvent) {
                  return;
                }
                if (response?.lineBarSpots != null &&
                    response!.lineBarSpots!.isNotEmpty) {
                  setState(() =>
                      _selectedIndex = response.lineBarSpots!.first.x.toInt());
                }
              },
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) =>
                    theme.colorScheme.surfaceContainerHighest,
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    final index = spot.x.toInt();
                    final text = tooltipBuilder(index);
                    if (text != null) {
                      return LineTooltipItem(
                        text,
                        TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    }
                    return null;
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _calculateMaxY(List<int> amounts) {
    if (amounts.isEmpty) return 100;

    final maxAmount = amounts.reduce((a, b) => a > b ? a : b);
    final minAmount = amounts.reduce((a, b) => a < b ? a : b);

    if (maxAmount <= 0) return 100;

    if (minAmount < 0) {
      return ((maxAmount - minAmount) * 1.2).ceilToDouble();
    }

    return (maxAmount * 1.2).ceilToDouble();
  }

  double _calculateMinY(List<int> amounts) {
    if (amounts.isEmpty) return 0;

    final minAmount = amounts.reduce((a, b) => a < b ? a : b);

    if (minAmount < 0) {
      return (minAmount * 1.2).floorToDouble();
    }

    return 0;
  }

  List<FlSpot> _buildSpots(List<int> amounts) {
    return List.generate(
      amounts.length,
      (index) => FlSpot(index.toDouble(), amounts[index].toDouble()),
    );
  }
}
