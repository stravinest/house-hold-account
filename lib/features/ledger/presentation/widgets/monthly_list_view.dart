import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/date_time_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
import '../providers/monthly_list_view_provider.dart';

/// 월간 리스트 뷰 위젯
///
/// 필터링된 월간 거래를 날짜별로 그룹핑하여 리스트로 표시합니다.
/// - 최신순 정렬 (역순)
/// - 날짜 헤더 + 거래 항목
/// - EmptyState, Loading, Error 상태 처리
class MonthlyListView extends ConsumerWidget {
  const MonthlyListView({super.key});

  /// 거래를 날짜별로 그룹핑
  Map<String, List<Transaction>> _groupByDate(List<Transaction> transactions) {
    final Map<String, List<Transaction>> grouped = {};

    for (final tx in transactions) {
      final dateKey = DateFormat('yyyy-MM-dd').format(tx.date);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    // 각 날짜별 거래를 금액 내림차순으로 정렬
    grouped.forEach((key, value) {
      value.sort((a, b) => b.amount.compareTo(a.amount));
    });

    return grouped;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final filteredTransactionsAsync = ref.watch(
      filteredMonthlyTransactionsProvider,
    );

    return filteredTransactionsAsync.when(
      data: (transactions) {
        if (transactions.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Text(
                l10n.calendarNoRecords,
                style: TextStyle(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        // 날짜별 그룹핑
        final groupedTransactions = _groupByDate(transactions);

        // 날짜 키를 최신순으로 정렬
        final sortedDateKeys = groupedTransactions.keys.toList()
          ..sort((a, b) => b.compareTo(a)); // 역순 정렬

        return ListView.builder(
          itemCount: sortedDateKeys.length,
          itemBuilder: (context, index) {
            final dateKey = sortedDateKeys[index];
            final date = DateTime.parse(dateKey);
            final dailyTransactions = groupedTransactions[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 날짜 헤더
                _DailyDateHeader(date: date),
                // 거래 항목들
                ...dailyTransactions.map((tx) {
                  return _TransactionItem(transaction: tx);
                }),
              ],
            );
          },
        );
      },
      loading: () => _buildLoadingSkeleton(),
      error: (error, stackTrace) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: colorScheme.error),
              const SizedBox(height: Spacing.md),
              Text(
                l10n.errorWithMessage(error.toString()),
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonLine(width: 150, height: 16),
              SizedBox(height: Spacing.sm),
              Row(
                children: [
                  SkeletonCircle(size: 8),
                  SizedBox(width: 12),
                  Expanded(child: SkeletonLine(height: 14)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 날짜 헤더 위젯
class _DailyDateHeader extends StatelessWidget {
  final DateTime date;

  const _DailyDateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final l10n = AppLocalizations.of(context);
    final dateText = l10n.calendarDailyDateHeader(
      date.year,
      date.month,
      date.day,
      DateTimeUtils.weekdayLabel(l10n, date.weekday),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: colorScheme.surfaceContainer,
      child: Text(
        dateText,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// 거래 항목 위젯 (기존 _DailyUserSummary 스타일 재사용)
class _TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const _TransactionItem({required this.transaction});

  Color _parseColor(String? colorStr) {
    if (colorStr == null) return const Color(0xFFA8D8EA);
    try {
      final hex = colorStr.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFFA8D8EA);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final formatter = NumberFormat('#,###', Localizations.localeOf(context).toString());

    final tx = transaction;
    final userName = tx.userName ?? l10n.user;
    final colorHex = tx.userColor ?? '#A8D8EA';
    final userColor = _parseColor(colorHex);
    final categoryDisplay = tx.categoryName ?? l10n.categoryUncategorized;

    // 카테고리 · 제목 표시
    final String description;
    if (tx.title != null && tx.title!.isNotEmpty) {
      description = '$categoryDisplay · ${tx.title}';
    } else {
      description = categoryDisplay;
    }

    final isIncome = tx.type == 'income';
    final isAssetType = tx.type == 'asset';

    // 금액 색상 및 prefix
    Color amountColor;
    String amountPrefix;
    if (isIncome) {
      amountColor = colorScheme.primary;
      amountPrefix = '';
    } else if (isAssetType) {
      amountColor = colorScheme.tertiary;
      amountPrefix = '';
    } else {
      amountColor = colorScheme.error;
      amountPrefix = '-';
    }

    return Material(
      color: colorScheme.surface,
      child: InkWell(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (context) => TransactionDetailSheet(transaction: tx),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 사용자 색상 점
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: userColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              // 사용자 이름
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              // 카테고리 · 제목
              Flexible(
                child: Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // 금액
              Text(
                '$amountPrefix${formatter.format(tx.amount)}${l10n.transactionAmountUnit}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: amountColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
