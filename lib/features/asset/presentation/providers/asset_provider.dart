import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/repositories/asset_repository.dart';
import '../../domain/entities/asset_statistics.dart';

final assetRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

final assetStatisticsProvider = FutureProvider<AssetStatistics>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) {
    return const AssetStatistics(
      totalAmount: 0,
      monthlyChange: 0,
      monthlyChangeRate: 0.0,
      annualGrowthRate: 0.0,
      monthly: [],
      byCategory: [],
    );
  }

  final repository = ref.watch(assetRepositoryProvider);
  return repository.getEnhancedStatistics(ledgerId: ledgerId);
});
