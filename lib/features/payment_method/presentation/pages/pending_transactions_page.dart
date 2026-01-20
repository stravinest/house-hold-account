import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../domain/entities/pending_transaction.dart';
import '../providers/pending_transaction_provider.dart';
import '../widgets/pending_transaction_card.dart';

// DateFormat 캐싱 (매 빌드마다 생성하지 않음)
final _dateFormat = DateFormat('M월 d일 (E)', 'ko');

class PendingTransactionsPage extends ConsumerStatefulWidget {
  const PendingTransactionsPage({super.key});

  @override
  ConsumerState<PendingTransactionsPage> createState() =>
      _PendingTransactionsPageState();
}

class _PendingTransactionsPageState
    extends ConsumerState<PendingTransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pendingTxAsync = ref.watch(pendingTransactionNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('대기 중인 거래'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'confirm_all':
                  _confirmAll();
                  break;
                case 'reject_all':
                  _rejectAll();
                  break;
                case 'delete_rejected':
                  _deleteRejected();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'confirm_all',
                child: ListTile(
                  leading: Icon(Icons.check_circle_outline),
                  title: Text('모두 확인'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'reject_all',
                child: ListTile(
                  leading: Icon(Icons.cancel_outlined),
                  title: Text('모두 거부'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'delete_rejected',
                child: ListTile(
                  leading: Icon(Icons.delete_outline),
                  title: Text('거부된 항목 삭제'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '대기 중'),
            Tab(text: '확인됨'),
            Tab(text: '거부됨'),
          ],
        ),
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: pendingTxAsync.when(
          data: (transactions) => TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionList(
                context,
                transactions
                    .where((t) => t.status == PendingTransactionStatus.pending)
                    .toList(),
                emptyMessage: '대기 중인 거래가 없습니다',
                emptyIcon: Icons.hourglass_empty,
              ),
              _buildTransactionList(
                context,
                transactions
                    .where(
                      (t) =>
                          t.status == PendingTransactionStatus.confirmed ||
                          t.status == PendingTransactionStatus.converted,
                    )
                    .toList(),
                emptyMessage: '확인된 거래가 없습니다',
                emptyIcon: Icons.check_circle_outline,
              ),
              _buildTransactionList(
                context,
                transactions
                    .where((t) => t.status == PendingTransactionStatus.rejected)
                    .toList(),
                emptyMessage: '거부된 거래가 없습니다',
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              '오류: $error',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(
    BuildContext context,
    List<PendingTransactionModel> transactions, {
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (transactions.isEmpty) {
      return EmptyState(icon: emptyIcon, message: emptyMessage);
    }

    // 날짜별로 그룹화
    final groupedTransactions = <DateTime, List<PendingTransactionModel>>{};
    for (final tx in transactions) {
      final date = DateTime(
        tx.sourceTimestamp.year,
        tx.sourceTimestamp.month,
        tx.sourceTimestamp.day,
      );
      groupedTransactions.putIfAbsent(date, () => []).add(tx);
    }

    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(Spacing.md),
      cacheExtent: 500, // 성능 최적화: 스크롤 시 미리 렌더링
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final dateTxs = groupedTransactions[date]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: Spacing.md),
            _buildDateHeader(context, date),
            const SizedBox(height: Spacing.sm),
            ...dateTxs.map(
              (tx) => Padding(
                padding: const EdgeInsets.only(bottom: Spacing.sm),
                child: PendingTransactionCard(
                  transaction: tx,
                  onConfirm: tx.status == PendingTransactionStatus.pending
                      ? () => _confirmTransaction(tx.id)
                      : null,
                  onReject: tx.status == PendingTransactionStatus.pending
                      ? () => _rejectTransaction(tx.id)
                      : null,
                  onEdit: tx.status == PendingTransactionStatus.pending
                      ? () => _editTransaction(tx)
                      : null,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(BuildContext context, DateTime date) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (date == today) {
      dateText = '오늘';
    } else if (date == yesterday) {
      dateText = '어제';
    } else {
      dateText = _dateFormat.format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: Text(
        dateText,
        style: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _confirmTransaction(String id) async {
    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .confirmTransaction(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('거래가 저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  Future<void> _rejectTransaction(String id) async {
    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .rejectTransaction(id);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('거래가 거부되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    }
  }

  void _editTransaction(PendingTransactionModel tx) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _EditPendingTransactionSheet(transaction: tx),
    );
  }

  Future<void> _confirmAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 거래 확인'),
        content: const Text('대기 중인 모든 거래를 확인하시겠습니까?\n파싱 정보가 있는 거래만 저장됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('확인'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(pendingTransactionNotifierProvider.notifier)
            .confirmAll();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('모든 거래가 처리되었습니다')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _rejectAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('모든 거래 거부'),
        content: const Text('대기 중인 모든 거래를 거부하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('거부'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(pendingTransactionNotifierProvider.notifier).rejectAll();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('모든 거래가 거부되었습니다')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }

  Future<void> _deleteRejected() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('거부된 항목 삭제'),
        content: const Text('거부된 모든 거래를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
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
      try {
        await ref
            .read(pendingTransactionNotifierProvider.notifier)
            .deleteRejected();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('거부된 항목이 삭제되었습니다')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('오류: $e')));
        }
      }
    }
  }
}

class _EditPendingTransactionSheet extends ConsumerStatefulWidget {
  final PendingTransactionModel transaction;

  const _EditPendingTransactionSheet({required this.transaction});

  @override
  ConsumerState<_EditPendingTransactionSheet> createState() =>
      _EditPendingTransactionSheetState();
}

class _EditPendingTransactionSheetState
    extends ConsumerState<_EditPendingTransactionSheet> {
  late TextEditingController _amountController;
  late TextEditingController _merchantController;
  String? _selectedType;
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.transaction.parsedAmount?.toString() ?? '',
    );
    _merchantController = TextEditingController(
      text: widget.transaction.parsedMerchant ?? '',
    );
    _selectedType = widget.transaction.parsedType;
    _selectedDate = widget.transaction.parsedDate;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _merchantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.md + bottomPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '거래 정보 수정',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // 원본 내용
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '원본 메시지',
                    style: textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    widget.transaction.sourceContent,
                    style: textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // 금액
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: '금액',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: Spacing.md),

          // 상호명
          TextField(
            controller: _merchantController,
            decoration: const InputDecoration(
              labelText: '상호명',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // 거래 유형
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'expense',
                label: Text('지출'),
                icon: Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: 'income',
                label: Text('수입'),
                icon: Icon(Icons.add_circle_outline),
              ),
            ],
            selected: {_selectedType ?? 'expense'},
            onSelectionChanged: (selected) {
              setState(() {
                _selectedType = selected.first;
              });
            },
          ),
          const SizedBox(height: Spacing.md),

          // 날짜
          OutlinedButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime.now().subtract(const Duration(days: 365)),
                lastDate: DateTime.now(),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _selectedDate != null
                  ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
                  : '날짜 선택',
            ),
          ),
          const SizedBox(height: Spacing.lg),

          // 저장 버튼
          FilledButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final amount = int.tryParse(_amountController.text);

      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .updateParsedData(
            id: widget.transaction.id,
            parsedAmount: amount,
            parsedMerchant: _merchantController.text.isNotEmpty
                ? _merchantController.text
                : null,
            parsedType: _selectedType,
            parsedDate: _selectedDate,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('수정되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('오류: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
