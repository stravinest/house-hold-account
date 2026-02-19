import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';

// 검색 쿼리 프로바이더
final searchQueryProvider = StateProvider<String>((ref) => '');

// LIKE 패턴 특수문자 이스케이프
String _escapeLikePattern(String input) {
  // PostgreSQL LIKE 패턴에서 와일드카드로 해석되는 문자들을 이스케이프
  // %: 0개 이상의 문자 매칭
  // _: 정확히 1개 문자 매칭
  // \: 이스케이프 문자
  return input
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');
}

// 검색 결과 프로바이더
final searchResultsProvider = FutureProvider<List<Transaction>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);

  if (query.isEmpty || ledgerId == null) return [];

  // 특수문자 이스케이프 처리
  final escapedQuery = _escapeLikePattern(query.trim());
  if (escapedQuery.isEmpty) return [];

  final client = SupabaseConfig.client;

  final response = await client
      .from('transactions')
      .select(
        '*, categories(name, icon, color), profiles(display_name, email, color), payment_methods(name)',
      )
      .eq('ledger_id', ledgerId)
      .or('title.ilike.%$escapedQuery%,memo.ilike.%$escapedQuery%')
      .order('date', ascending: false)
      .limit(50);

  return (response as List)
      .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
      .toList();
});

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          maxLength: 30,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
            counterText: '',
          ),
          onChanged: (value) {
            ref.read(searchQueryProvider.notifier).state = value;
          },
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              tooltip: l10n.tooltipClear,
            ),
        ],
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: resultsAsync.when(
          data: (results) {
            if (ref.watch(searchQueryProvider).isEmpty) {
              return EmptyState(icon: Icons.search, message: l10n.searchEmpty);
            }

            if (results.isEmpty) {
              return EmptyState(
                icon: Icons.search_off,
                message: l10n.searchNoResults,
              );
            }

            return ListView.builder(
              cacheExtent: 500,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewPadding.bottom,
              ),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final transaction = results[index];
                return _SearchResultItem(
                  transaction: transaction,
                  onDetailClosed: () {
                    ref.invalidate(searchResultsProvider);
                  },
                );
              },
            );
          },
          loading: () => const SkeletonListView(itemCount: 5),
          error: (e, st) =>
              Center(child: Text(l10n.errorWithMessage(e.toString()))),
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onDetailClosed;

  const _SearchResultItem({required this.transaction, this.onDetailClosed});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('yyyy.MM.dd');
    final amountColor = transaction.isIncome
        ? colorScheme.primary
        : transaction.isAssetType
        ? colorScheme.tertiary
        : colorScheme.error;
    final amountPrefix = transaction.isIncome
        ? '+'
        : transaction.isAssetType
        ? ''
        : '-';

    return ListTile(
      onTap: () async {
        await showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          builder: (context) =>
              TransactionDetailSheet(transaction: transaction),
        );
        onDetailClosed?.call();
      },
      leading: CategoryIcon(
        icon: (transaction.isFixedExpense
                ? transaction.fixedExpenseCategoryIcon
                : transaction.categoryIcon) ??
            '',
        name: (transaction.isFixedExpense
                ? transaction.fixedExpenseCategoryName
                : transaction.categoryName) ??
            '',
        color: (transaction.isFixedExpense
                ? transaction.fixedExpenseCategoryColor
                : transaction.categoryColor) ??
            '#9E9E9E',
        size: CategoryIconSize.medium,
      ),
      title: Text(
        (transaction.isFixedExpense
                ? transaction.fixedExpenseCategoryName
                : transaction.categoryName) ??
            l10n.searchUncategorized,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.title != null && transaction.title!.isNotEmpty)
            Text(
              transaction.isInstallment && transaction.installmentTotalMonths > 0
                  ? '${transaction.title!} ${AppLocalizations.of(context).installmentProgress(transaction.installmentCurrentMonth, transaction.installmentTotalMonths)}'
                  : transaction.title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            dateFormat.format(transaction.date),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Text(
        '$amountPrefix${NumberFormatUtils.currency.format(transaction.amount)}${l10n.transactionAmountUnit}',
        style: TextStyle(fontWeight: FontWeight.bold, color: amountColor),
      ),
    );
  }
}
