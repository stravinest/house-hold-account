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
      monthly: [],
      byCategory: [],
    );
  }

  final repository = ref.watch(assetRepositoryProvider);
  final now = DateTime.now();

  final total = await repository.getTotalAssets(ledgerId: ledgerId);
  final change = await repository.getMonthlyChange(
    ledgerId: ledgerId,
    year: now.year,
    month: now.month,
  );
  final monthly = await repository.getMonthlyAssets(ledgerId: ledgerId);
  final byCategory = await repository.getAssetsByCategory(ledgerId: ledgerId);

  return AssetStatistics(
    totalAmount: total,
    monthlyChange: change,
    monthly: monthly,
    byCategory: byCategory,
  );
});
