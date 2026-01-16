import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/domain/entities/transaction.dart';

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
      .select('*, categories(name, icon, color)')
      .eq('ledger_id', ledgerId)
      .or('title.ilike.%$escapedQuery%,memo.ilike.%$escapedQuery%')
      .order('date', ascending: false)
      .limit(50);

  return (response as List).map((json) => Transaction.fromJson(json)).toList();
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
    final l10n = AppLocalizations.of(context)!;
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
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
      body: resultsAsync.when(
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
            itemCount: results.length,
            itemBuilder: (context, index) {
              final transaction = results[index];
              return _SearchResultItem(transaction: transaction);
            },
          );
        },
        loading: () => const SkeletonListView(itemCount: 5),
        error: (e, st) =>
            Center(child: Text(l10n.errorWithMessage(e.toString()))),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Transaction transaction;

  const _SearchResultItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _parseColor(transaction.categoryColor).withAlpha(51),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            transaction.categoryIcon ?? '',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(transaction.categoryName ?? l10n.searchUncategorized),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (transaction.title != null && transaction.title!.isNotEmpty)
            Text(
              transaction.title!,
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

  Color _parseColor(String? hexColor) {
    // fallback 색상은 onSurfaceVariant 대신 중립적 회색 상수 사용
    // (context 없이 호출되므로 ColorScheme 접근 불가)
    const fallbackColor = Color(0xFF9E9E9E); // Grey 500
    if (hexColor == null) return fallbackColor;
    try {
      final hex = hexColor.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return fallbackColor;
    }
  }
}
