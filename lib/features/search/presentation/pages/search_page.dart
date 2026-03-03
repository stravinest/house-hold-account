import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../config/supabase_config.dart';
import '../../../../core/utils/number_format_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/category_icon.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../../transaction/data/models/transaction_model.dart';
import '../../../transaction/domain/entities/transaction.dart';
import '../../../transaction/presentation/widgets/transaction_detail_sheet.dart';
import '../widgets/batch_edit_transaction_sheet.dart';

// 검색 쿼리 프로바이더
final searchQueryProvider = StateProvider<String>((ref) => '');

// LIKE 패턴 특수문자 이스케이프
String _escapeLikePattern(String input) {
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

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 이전 검색 상태 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchQueryProvider.notifier).state = '';
    });
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedIds.clear();
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  /// 선택 가능한 거래 목록 (본인 거래 + 반복거래 아닌 것)
  List<Transaction> _selectableTransactions(List<Transaction> results) {
    final currentUserId = ref.read(currentUserProvider)?.id;
    return results
        .where((t) => t.userId == currentUserId && !t.isRecurring)
        .toList();
  }

  void _toggleSelectAll(List<Transaction> selectable) {
    final allSelected =
        selectable.every((t) => _selectedIds.contains(t.id));
    setState(() {
      if (allSelected) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(selectable.map((t) => t.id));
      }
    });
  }

  Future<void> _openBatchEditSheet(List<Transaction> results) async {
    final selectedTransactions =
        results.where((t) => _selectedIds.contains(t.id)).toList();
    if (selectedTransactions.isEmpty) return;

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          BatchEditTransactionSheet(transactions: selectedTransactions),
    );

    if (result == true) {
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
      });
      ref.invalidate(searchResultsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final resultsAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        title: _isSelectionMode
            ? Text(l10n.searchSelectedCount(_selectedIds.length))
            : TextField(
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
          if (!_isSelectionMode && _searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchQueryProvider.notifier).state = '';
              },
              tooltip: l10n.tooltipClear,
            ),
          // 검색 결과가 있을 때만 선택 모드 토글 표시
          if (resultsAsync.valueOrNull?.isNotEmpty == true)
            IconButton(
              icon: Icon(
                _isSelectionMode ? Icons.close : Icons.checklist,
              ),
              onPressed: _toggleSelectionMode,
              tooltip: l10n.searchSelectionMode,
            ),
        ],
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: resultsAsync.when(
          data: (results) {
            if (ref.watch(searchQueryProvider).isEmpty) {
              return EmptyState(
                  icon: Icons.search, message: l10n.searchEmpty);
            }

            if (results.isEmpty) {
              return EmptyState(
                icon: Icons.search_off,
                message: l10n.searchNoResults,
              );
            }

            final currentUserId = ref.watch(currentUserProvider)?.id;

            return Column(
              children: [
                // 전체 선택 행 (선택 모드일 때)
                if (_isSelectionMode) _buildSelectAllRow(results, l10n),

                // 결과 리스트
                Expanded(
                  child: ListView.builder(
                    cacheExtent: 500,
                    padding: EdgeInsets.only(
                      bottom: _isSelectionMode
                          ? 80
                          : MediaQuery.of(context).viewPadding.bottom,
                    ),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final transaction = results[index];
                      final isOwner =
                          transaction.userId == currentUserId;
                      final isRecurring = transaction.isRecurring;
                      final canSelect = isOwner && !isRecurring;

                      return _SearchResultItem(
                        transaction: transaction,
                        isSelectionMode: _isSelectionMode,
                        isSelected:
                            _selectedIds.contains(transaction.id),
                        canSelect: canSelect,
                        disabledReason: !isOwner
                            ? l10n.searchOtherUserTooltip
                            : isRecurring
                                ? l10n.searchRecurringTooltip
                                : null,
                        onToggleSelection: canSelect
                            ? () =>
                                _toggleSelection(transaction.id)
                            : null,
                        onDetailClosed: () {
                          ref.invalidate(searchResultsProvider);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
          loading: () => const SkeletonListView(itemCount: 5),
          error: (e, st) =>
              Center(child: Text(l10n.errorWithMessage(e.toString()))),
        ),
      ),
      // 하단 일괄 수정 바
      bottomNavigationBar: _isSelectionMode
          ? resultsAsync.whenOrNull(
              data: (results) => _buildBatchEditBar(results, l10n),
            )
          : null,
    );
  }

  Widget _buildSelectAllRow(
      List<Transaction> results, AppLocalizations l10n) {
    final selectable = _selectableTransactions(results);
    final allSelected =
        selectable.isNotEmpty &&
        selectable.every((t) => _selectedIds.contains(t.id));

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: allSelected,
            onChanged: selectable.isEmpty
                ? null
                : (_) => _toggleSelectAll(selectable),
          ),
          Text(
            l10n.searchSelectAll,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selectable.isEmpty
                      ? Theme.of(context).colorScheme.onSurface.withAlpha(97)
                      : null,
                ),
          ),
          const Spacer(),
          Text(
            l10n.searchSelectedCount(_selectedIds.length),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchEditBar(
      List<Transaction> results, AppLocalizations l10n) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              l10n.searchSelectedCount(_selectedIds.length),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () => _openBatchEditSheet(results),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(l10n.searchBatchEdit),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final Transaction transaction;
  final bool isSelectionMode;
  final bool isSelected;
  final bool canSelect;
  final String? disabledReason;
  final VoidCallback? onToggleSelection;
  final VoidCallback? onDetailClosed;

  const _SearchResultItem({
    required this.transaction,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.canSelect = true,
    this.disabledReason,
    this.onToggleSelection,
    this.onDetailClosed,
  });

  static Color _parseUserColor(String? colorStr) {
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

    Widget leading;
    if (isSelectionMode) {
      if (canSelect) {
        leading = Checkbox(
          value: isSelected,
          onChanged: (_) => onToggleSelection?.call(),
        );
      } else {
        // 선택 불가 거래는 체크박스 영역만큼 빈 공간 유지
        leading = const SizedBox(width: 48);
      }
    } else {
      leading = CategoryIcon(
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
      );
    }

    return ListTile(
      onTap: isSelectionMode
          ? (canSelect ? onToggleSelection : null)
          : () async {
              await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (context) =>
                    TransactionDetailSheet(transaction: transaction),
              );
              onDetailClosed?.call();
            },
      leading: leading,
      title: Text(
        (transaction.isFixedExpense
                ? transaction.fixedExpenseCategoryName
                : transaction.categoryName) ??
            l10n.searchUncategorized,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 (색상 점 + 이름)
          if (transaction.userName != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _parseUserColor(transaction.userColor),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      transaction.userName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (transaction.title != null && transaction.title!.isNotEmpty)
            Text(
              transaction.isInstallment &&
                      transaction.installmentTotalMonths > 0
                  ? '${transaction.title!} ${AppLocalizations.of(context).installmentProgress(transaction.installmentCurrentMonth, transaction.installmentTotalMonths)}'
                  : transaction.title!,
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            dateFormat.format(transaction.date),
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Text(
        '$amountPrefix${NumberFormatUtils.currency.format(transaction.amount)}${l10n.transactionAmountUnit}',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: amountColor,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
