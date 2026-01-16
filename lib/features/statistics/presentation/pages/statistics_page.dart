import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../providers/statistics_provider.dart';
import '../widgets/category_tab/category_tab_view.dart';
import '../widgets/common/statistics_date_selector.dart';
import '../widgets/payment_method_tab/payment_method_tab_view.dart';
import '../widgets/trend_tab/trend_tab_view.dart';

class StatisticsPage extends ConsumerStatefulWidget {
  const StatisticsPage({super.key});

  @override
  ConsumerState<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends ConsumerState<StatisticsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(statisticsTabIndexProvider.notifier).state =
          _tabController.index;
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        const StatisticsDateSelector(),
        Container(
          color: theme.colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: l10n.statisticsCategory),
              Tab(text: l10n.statisticsTrend),
              Tab(text: l10n.statisticsPaymentMethod),
            ],
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            indicatorColor: theme.colorScheme.primary,
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              CategoryTabView(),
              TrendTabView(),
              PaymentMethodTabView(),
            ],
          ),
        ),
      ],
    );
  }
}
