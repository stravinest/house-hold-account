import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/utils/number_format_utils.dart';
import '../../../../../l10n/generated/app_localizations.dart';
import '../../../data/repositories/statistics_repository.dart';
import '../../../domain/entities/statistics_entities.dart';
import '../../providers/statistics_provider.dart';

class TrendBarChart extends ConsumerWidget {
  const TrendBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(trendPeriodProvider);
    final selectedType = ref.watch(selectedStatisticsTypeProvider);
    final selectedDate = ref.watch(statisticsSelectedDateProvider);

    if (period == TrendPeriod.monthly) {
      // 날짜 또는 타입 변경 시 widget을 재생성하여 데이터와 스크롤 갱신
      return _MonthlyTrendChart(
        key: ValueKey('monthly_${selectedDate.year}_${selectedDate.month}_$selectedType'),
        selectedType: selectedType,
      );
    } else {
      return _YearlyTrendChart(
        key: ValueKey('yearly_${selectedDate.year}_$selectedType'),
        selectedType: selectedType,
      );
    }
  }
}

class _MonthlyTrendChart extends ConsumerStatefulWidget {
  final String selectedType;

  const _MonthlyTrendChart({super.key, required this.selectedType});

  @override
  ConsumerState<_MonthlyTrendChart> createState() => _MonthlyTrendChartState();
}

class _MonthlyTrendChartState extends ConsumerState<_MonthlyTrendChart> {
  late final ScrollController _scrollController;
  DateTime? _lastSelectedDate;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedMonth(
    List<MonthlyStatistics> data,
    DateTime selectedDate,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && data.isNotEmpty) {
        // 선택된 월은 데이터의 마지막이므로 맨 끝으로 스크롤
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trendAsync = ref.watch(monthlyTrendWithAverageProvider);
    final selectedDate = ref.watch(statisticsSelectedDateProvider);

    return trendAsync.when(
      data: (trendData) {
        if (trendData.data.isEmpty) {
          return _buildEmptyState(context, l10n);
        }
        final data = trendData.data.cast<MonthlyStatistics>();

        // 선택된 날짜가 변경되었거나 첫 로드인 경우 스크롤 조정
        if (_lastSelectedDate == null ||
            _lastSelectedDate!.year != selectedDate.year ||
            _lastSelectedDate!.month != selectedDate.month) {
          _lastSelectedDate = selectedDate;
          _scrollToSelectedMonth(data, selectedDate);
        }

        return _buildChart(context, l10n, trendData, selectedDate);
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          l10n.statisticsNoData,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    AppLocalizations l10n,
    TrendStatisticsData trendData,
    DateTime selectedDate,
  ) {
    final data = trendData.data.cast<MonthlyStatistics>();
    final average = trendData.getAverageByType(widget.selectedType);
    final theme = Theme.of(context);
    final barColor = _getBarColor(widget.selectedType, context);

    // maxY 계산
    double maxY = 0;
    for (final item in data) {
      final value = _getValueByType(item, widget.selectedType);
      if (value > maxY) maxY = value.toDouble();
    }
    if (average > maxY) maxY = average.toDouble();
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return SizedBox(
      height: 250,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: data.length * 60.0 + 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[group.x.toInt()];
                      return BarTooltipItem(
                        '${item.year}.${item.month.toString().padLeft(2, '0')}\n${NumberFormatUtils.currency.format(rod.toY.toInt())}${l10n.transactionAmountUnit}',
                        TextStyle(color: theme.colorScheme.onSurface),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final item = data[index];
                          final isSelected =
                              item.year == selectedDate.year &&
                              item.month == selectedDate.month;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${item.year % 100}.${item.month.toString().padLeft(2, '0')}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(data, selectedDate, barColor),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: average.toDouble(),
                      color: theme.colorScheme.outline,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => l10n.statisticsAverage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<MonthlyStatistics> data,
    DateTime selectedDate,
    Color barColor,
  ) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final value = _getValueByType(item, widget.selectedType);
      final isSelected =
          item.year == selectedDate.year && item.month == selectedDate.month;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: isSelected ? barColor : barColor.withValues(alpha: 0.5),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  int _getValueByType(MonthlyStatistics item, String type) {
    switch (type) {
      case 'income':
        return item.income;
      case 'asset':
        return item.saving;
      default:
        return item.expense;
    }
  }

  Color _getBarColor(String type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'income':
        return colorScheme.primary;
      case 'asset':
        return colorScheme.tertiary;
      default:
        return colorScheme.error;
    }
  }
}

class _YearlyTrendChart extends ConsumerStatefulWidget {
  final String selectedType;

  const _YearlyTrendChart({super.key, required this.selectedType});

  @override
  ConsumerState<_YearlyTrendChart> createState() => _YearlyTrendChartState();
}

class _YearlyTrendChartState extends ConsumerState<_YearlyTrendChart> {
  late final ScrollController _scrollController;
  int? _lastSelectedYear;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedYear(
    List<YearlyStatistics> data,
    DateTime selectedDate,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && data.isNotEmpty) {
        // 선택된 연도는 데이터의 마지막이므로 맨 끝으로 스크롤
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trendAsync = ref.watch(yearlyTrendWithAverageProvider);
    final selectedDate = ref.watch(statisticsSelectedDateProvider);

    return trendAsync.when(
      data: (trendData) {
        if (trendData.data.isEmpty) {
          return _buildEmptyState(context, l10n);
        }
        final data = trendData.data.cast<YearlyStatistics>();

        // 선택된 연도가 변경되었거나 첫 로드인 경우 스크롤 조정
        if (_lastSelectedYear == null ||
            _lastSelectedYear != selectedDate.year) {
          _lastSelectedYear = selectedDate.year;
          _scrollToSelectedYear(data, selectedDate);
        }

        return _buildChart(context, l10n, trendData, selectedDate);
      },
      loading: () => const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) =>
          Center(child: Text(l10n.errorWithMessage(error.toString()))),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      height: 250,
      child: Center(
        child: Text(
          l10n.statisticsNoData,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    AppLocalizations l10n,
    TrendStatisticsData trendData,
    DateTime selectedDate,
  ) {
    final data = trendData.data.cast<YearlyStatistics>();
    final average = trendData.getAverageByType(widget.selectedType);
    final theme = Theme.of(context);
    final barColor = _getBarColor(widget.selectedType, context);

    // maxY 계산
    double maxY = 0;
    for (final item in data) {
      final value = _getValueByType(item, widget.selectedType);
      if (value > maxY) maxY = value.toDouble();
    }
    if (average > maxY) maxY = average.toDouble();
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return SizedBox(
      height: 250,
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: data.length * 60.0 + 40,
          child: Padding(
            padding: const EdgeInsets.only(top: 16, right: 16, left: 16),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surfaceContainerHighest,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = data[group.x.toInt()];
                      return BarTooltipItem(
                        '${l10n.statisticsYear(item.year)}\n${NumberFormatUtils.currency.format(rod.toY.toInt())}${l10n.transactionAmountUnit}',
                        TextStyle(color: theme.colorScheme.onSurface),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < data.length) {
                          final item = data[index];
                          final isSelected = item.year == selectedDate.year;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              l10n.statisticsYear(item.year),
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: theme.colorScheme.outlineVariant,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: _buildBarGroups(data, selectedDate, barColor),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: average.toDouble(),
                      color: theme.colorScheme.outline,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        labelResolver: (_) => l10n.statisticsAverage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups(
    List<YearlyStatistics> data,
    DateTime selectedDate,
    Color barColor,
  ) {
    return List.generate(data.length, (index) {
      final item = data[index];
      final value = _getValueByType(item, widget.selectedType);
      final isSelected = item.year == selectedDate.year;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: isSelected ? barColor : barColor.withValues(alpha: 0.5),
            width: 32,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  int _getValueByType(YearlyStatistics item, String type) {
    switch (type) {
      case 'income':
        return item.income;
      case 'asset':
        return item.saving;
      default:
        return item.expense;
    }
  }

  Color _getBarColor(String type, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case 'income':
        return colorScheme.primary;
      case 'asset':
        return colorScheme.tertiary;
      default:
        return colorScheme.error;
    }
  }
}
