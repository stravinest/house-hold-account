import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/budget.dart';
import '../providers/budget_provider.dart';
import '../widgets/add_budget_dialog.dart';

class BudgetPage extends ConsumerWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final spentAsync = ref.watch(budgetSpentProvider);
    final summary = ref.watch(budgetSummaryProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(budgetsProvider);
        ref.invalidate(budgetSpentProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 전체 예산 요약
            _BudgetSummaryCard(summary: summary),
            const SizedBox(height: 24),

            // 예산 관리 버튼들
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showAddBudgetDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('예산 추가'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyFromPreviousMonth(context, ref),
                    icon: const Icon(Icons.copy),
                    label: const Text('이전 달 복사'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 카테고리별 예산
            Text(
              '카테고리별 예산',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            budgetsAsync.when(
              data: (budgets) {
                final categoryBudgets =
                    budgets.where((b) => !b.isTotalBudget).toList();

                if (categoryBudgets.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '설정된 예산이 없습니다',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () =>
                                  _showAddBudgetDialog(context, ref),
                              child: const Text('예산 추가하기'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return spentAsync.when(
                  data: (spent) => _BudgetList(
                    budgets: categoryBudgets,
                    spent: spent,
                    onEdit: (budget) =>
                        _showEditBudgetDialog(context, ref, budget),
                    onDelete: (budget) =>
                        _deleteBudget(context, ref, budget),
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) => Center(child: Text('오류: $e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(child: Text('오류: $e')),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddBudgetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AddBudgetDialog(),
    );
  }

  void _showEditBudgetDialog(
      BuildContext context, WidgetRef ref, Budget budget) {
    showDialog(
      context: context,
      builder: (context) => AddBudgetDialog(budget: budget),
    );
  }

  Future<void> _deleteBudget(
      BuildContext context, WidgetRef ref, Budget budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('예산 삭제'),
        content: Text('${budget.categoryName ?? '총 예산'} 예산을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(budgetNotifierProvider.notifier).deleteBudget(budget.id);
    }
  }

  Future<void> _copyFromPreviousMonth(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('이전 달 예산 복사'),
        content: const Text('이전 달의 예산 설정을 현재 달로 복사하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('복사'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(budgetNotifierProvider.notifier).copyFromPreviousMonth();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이전 달 예산이 복사되었습니다')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }
}

// 예산 요약 카드
class _BudgetSummaryCard extends StatelessWidget {
  final BudgetSummary summary;

  const _BudgetSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final progressRate = summary.progressRate.clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '이번 달 예산',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (summary.isOverBudget)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '예산 초과',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // 진행률 바
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressRate,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(
                  summary.isOverBudget ? Colors.red : Colors.blue,
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 지출 / 예산 정보
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '지출',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '${numberFormat.format(summary.totalSpent)}원',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: summary.isOverBudget ? Colors.red : null,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '예산',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '${numberFormat.format(summary.totalBudget)}원',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '남은 예산',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                    ),
                    Text(
                      '${numberFormat.format(summary.remaining)}원',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: summary.remaining < 0 ? Colors.red : Colors.green,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 카테고리별 예산 목록
class _BudgetList extends StatelessWidget {
  final List<Budget> budgets;
  final Map<String, int> spent;
  final Function(Budget) onEdit;
  final Function(Budget) onDelete;

  const _BudgetList({
    required this.budgets,
    required this.spent,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: budgets.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final budget = budgets[index];
          final categorySpent = spent[budget.categoryId] ?? 0;
          final progress = budget.getProgressRate(categorySpent);
          final isOverBudget = categorySpent > budget.amount;

          return ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _parseColor(budget.categoryColor).withAlpha(51),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  budget.categoryIcon ?? '📦',
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(child: Text(budget.categoryName ?? '미분류')),
                if (isOverBudget)
                  Icon(Icons.warning_amber_rounded,
                      size: 16, color: Colors.red.shade400),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      isOverBudget ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${numberFormat.format(categorySpent)}원 / ${numberFormat.format(budget.amount)}원',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('수정'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('삭제', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit(budget);
                } else if (value == 'delete') {
                  onDelete(budget);
                }
              },
            ),
          );
        },
      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null) return Colors.grey;
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.grey;
    }
  }
}
