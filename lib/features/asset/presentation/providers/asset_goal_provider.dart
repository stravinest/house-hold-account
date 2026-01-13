import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/asset_goal.dart';
import '../../data/repositories/asset_repository.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';

final assetGoalRepositoryProvider = Provider<AssetRepository>((ref) {
  return AssetRepository();
});

final assetGoalsProvider = FutureProvider<List<AssetGoal>>((ref) async {
  final ledgerId = ref.watch(selectedLedgerIdProvider);
  if (ledgerId == null) return [];

  final repository = ref.watch(assetGoalRepositoryProvider);
  return repository.getGoals(ledgerId: ledgerId);
});

class AssetGoalNotifier extends StateNotifier<AsyncValue<List<AssetGoal>>> {
  final AssetRepository _repository;
  final String _ledgerId;

  AssetGoalNotifier(this._repository, this._ledgerId)
    : super(const AsyncValue.loading()) {
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repository.getGoals(ledgerId: _ledgerId),
    );
  }

  Future<void> createGoal({
    required String title,
    required int targetAmount,
    DateTime? targetDate,
    String? assetType,
    List<String>? categoryIds,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('로그인이 필요합니다');
      }

      final goal = AssetGoal(
        id: '',
        ledgerId: _ledgerId,
        title: title,
        targetAmount: targetAmount,
        targetDate: targetDate,
        assetType: assetType,
        categoryIds: categoryIds,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: currentUser.id,
      );

      await _repository.createGoal(goal);
      return _repository.getGoals(ledgerId: _ledgerId);
    });
  }

  Future<void> updateGoal(AssetGoal goal) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.updateGoal(goal);
      return _repository.getGoals(ledgerId: _ledgerId);
    });
  }

  Future<void> deleteGoal(String goalId) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repository.deleteGoal(goalId);
      return _repository.getGoals(ledgerId: _ledgerId);
    });
  }
}

final assetGoalNotifierProvider =
    StateNotifierProvider.family<
      AssetGoalNotifier,
      AsyncValue<List<AssetGoal>>,
      String
    >((ref, ledgerId) {
      final repository = ref.watch(assetGoalRepositoryProvider);
      return AssetGoalNotifier(repository, ledgerId);
    });

final assetGoalCurrentAmountProvider = FutureProvider.family<int, AssetGoal>((
  ref,
  goal,
) async {
  final repository = ref.watch(assetGoalRepositoryProvider);
  return repository.getCurrentAmount(
    ledgerId: goal.ledgerId,
    assetType: goal.assetType,
    categoryIds: goal.categoryIds,
  );
});

final assetGoalProgressProvider = Provider.family<double, AssetGoal>((
  ref,
  goal,
) {
  final currentAmount = ref.watch(assetGoalCurrentAmountProvider(goal));

  return currentAmount.when(
    data: (amount) {
      if (goal.targetAmount == 0) return 0.0;
      return (amount / goal.targetAmount).clamp(0.0, 1.0);
    },
    loading: () => 0.0,
    error: (error, stack) => 0.0,
  );
});

final assetGoalRemainingDaysProvider = Provider.family<int?, AssetGoal>((
  ref,
  goal,
) {
  if (goal.targetDate == null) return null;
  final now = DateTime.now();
  return goal.targetDate!.difference(now).inDays;
});
