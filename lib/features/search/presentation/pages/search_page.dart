import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/supabase_config.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/domain/entities/transaction.dart';

// 검색 쿼리 프로바이더
final searchQueryProvider = StateProvider<String>((ref) => '');

// 검색 결과 프로바이더
final searchResultsProvider = FutureProvider<List<Transaction>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final ledgerId = ref.watch(selectedLedgerIdProvider);

  if (query.isEmpty || ledgerId == null) return [];

  final client = SupabaseConfig.client;

  final response = await client
      .from('transactions')
      .select('*, categories(name, icon, color)')
      .eq('ledger_id', ledgerId)
      .or('title.ilike.%$query%,memo.ilike.%$query%')
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
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            hintText: '제목/메모로 검색...',
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
            ),
        ],
      ),
      body: resultsAsync.when(
        data: (results) {
          if (ref.watch(searchQueryProvider).isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '제목/메모로 거래 내역을 검색하세요',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (results.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '검색 결과가 없습니다',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
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
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('오류: $e')),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Transaction transaction;

  const _SearchResultItem({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('yyyy.MM.dd');
    final amountColor = transaction.isIncome
        ? Colors.blue
        : transaction.isAssetType
            ? Colors.green
            : Colors.red;
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
            transaction.categoryIcon ?? '📦',
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
      title: Text(transaction.categoryName ?? '미분류'),
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
        '$amountPrefix${numberFormat.format(transaction.amount)}원',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
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
