import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../data/models/pending_transaction_model.dart';
import '../../domain/entities/pending_transaction.dart';
import '../providers/pending_transaction_provider.dart';
import '../widgets/pending_transaction_card.dart';

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
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });

    // 페이지 진입 시 모든 대기 거래를 '확인함' 처리하여 배지 카운트 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pendingTransactionNotifierProvider.notifier).markAllAsViewed();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final pendingTxAsync = ref.watch(pendingTransactionNotifierProvider);
    final ledgerId = ref.watch(selectedLedgerIdProvider);
    final currentUser = ref.watch(currentUserProvider);

    // ledgerId나 userId가 없으면 로딩 표시
    if (ledgerId == null || currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.autoCollectTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final userId = currentUser.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.autoCollectTitle),
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
                case 'delete_pending':
                  _deleteAllByStatus(PendingTransactionStatus.pending);
                  break;
                case 'delete_confirmed':
                  _deleteAllConfirmed();
                  break;
                case 'delete_rejected':
                  _deleteRejected();
                  break;
              }
            },
            itemBuilder: (context) {
              final l10n = AppLocalizations.of(context);
              final index = _tabController.index;
              if (index == 0) {
                return [
                  PopupMenuItem(
                    value: 'confirm_all',
                    child: ListTile(
                      leading: const Icon(Icons.check_circle_outline),
                      title: Text(l10n.pendingMenuConfirmAll),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'reject_all',
                    child: ListTile(
                      leading: const Icon(Icons.cancel_outlined),
                      title: Text(l10n.pendingMenuRejectAll),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete_pending',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.pendingMenuDeletePending),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ];
              } else if (index == 1) {
                return [
                  PopupMenuItem(
                    value: 'delete_confirmed',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.pendingMenuDeleteRecords),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ];
              } else {
                return [
                  PopupMenuItem(
                    value: 'delete_rejected',
                    child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.pendingMenuDeleteRejected),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ];
              }
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.pendingTransactionStatusPending),
            Tab(text: l10n.pendingTransactionStatusConfirmed),
            Tab(text: l10n.pendingTransactionStatusRejected),
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
                ledgerId: ledgerId,
                userId: userId,
                emptyMessage: l10n.pendingTransactionEmptyPending,
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
                ledgerId: ledgerId,
                userId: userId,
                emptyMessage: l10n.pendingTransactionEmptyConfirmed,
                emptyIcon: Icons.check_circle_outline,
              ),
              _buildTransactionList(
                context,
                transactions
                    .where((t) => t.status == PendingTransactionStatus.rejected)
                    .toList(),
                ledgerId: ledgerId,
                userId: userId,
                emptyMessage: l10n.pendingTransactionEmptyRejected,
                emptyIcon: Icons.cancel_outlined,
              ),
            ],
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Text(
              l10n.errorWithMessage(error.toString()),
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
    required String ledgerId,
    required String userId,
    required String emptyMessage,
    required IconData emptyIcon,
  }) {
    if (transactions.isEmpty) {
      return EmptyState(icon: emptyIcon, message: emptyMessage);
    }

    // 날짜별로 그룹화 (로컬 시간 기준)
    final groupedTransactions = <DateTime, List<PendingTransactionModel>>{};
    for (final tx in transactions) {
      final localTime = tx.sourceTimestamp.toLocal();
      final date = DateTime(localTime.year, localTime.month, localTime.day);
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
                  ledgerId: ledgerId,
                  userId: userId,
                  onConfirm: tx.status == PendingTransactionStatus.pending
                      ? () => _confirmTransaction(tx.id)
                      : null,
                  onReject: tx.status == PendingTransactionStatus.pending
                      ? () => _rejectTransaction(tx.id)
                      : null,
                  onEdit: tx.status == PendingTransactionStatus.pending
                      ? () => _editTransaction(tx)
                      : null,
                  onDelete: () => _deleteTransaction(tx.id),
                  onViewOriginal: tx.isDuplicate
                      ? () {
                          // 원본 거래로 스크롤
                          // TODO: 구현 필요
                        }
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
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateText;
    if (date == today) {
      dateText = l10n.dateGroupToday;
    } else if (date == yesterday) {
      dateText = l10n.dateGroupYesterday;
    } else {
      final localeStr = Localizations.localeOf(context).toString();
      dateText = DateFormat.MMMEd(localeStr).format(date);
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
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .confirmTransaction(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pendingTransactionConfirmed)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    }
  }

  Future<void> _rejectTransaction(String id) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref
          .read(pendingTransactionNotifierProvider.notifier)
          .rejectTransaction(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.pendingTransactionRejected)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
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
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.pendingConfirmAllTitle),
          content: Text(l10n.pendingConfirmAllMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonConfirm),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref
            .read(pendingTransactionNotifierProvider.notifier)
            .confirmAll();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.pendingAllProcessed)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _rejectAll() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.pendingRejectAllTitle),
          content: Text(l10n.pendingRejectAllMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonReject),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref.read(pendingTransactionNotifierProvider.notifier).rejectAll();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.pendingAllRejected)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteRejected() async {
    await _deleteAllByStatus(PendingTransactionStatus.rejected);
  }

  Future<void> _deleteTransaction(String id) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.pendingTransactionDeleteConfirmTitle),
          content: Text(l10n.pendingTransactionDeleteConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref
            .read(pendingTransactionNotifierProvider.notifier)
            .deleteTransaction(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.pendingTransactionDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteAllByStatus(PendingTransactionStatus status) async {
    final l10n = AppLocalizations.of(context);
    String title;
    String content;

    switch (status) {
      case PendingTransactionStatus.pending:
        title = l10n.pendingDeletePendingTitle;
        content = l10n.pendingDeletePendingMessage;
        break;
      case PendingTransactionStatus.rejected:
        title = l10n.pendingDeleteRejectedTitle;
        content = l10n.pendingDeleteRejectedMessage;
        break;
      case PendingTransactionStatus.confirmed:
      case PendingTransactionStatus.converted:
        title = l10n.pendingDeleteConfirmedTitle;
        content = l10n.pendingDeleteConfirmedMessage;
        break;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await ref
            .read(pendingTransactionNotifierProvider.notifier)
            .deleteAllByStatus(status);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.commonDeletedMessage)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
          );
        }
      }
    }
  }

  Future<void> _deleteAllConfirmed() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.pendingDeleteConfirmedTitle),
          content: Text(l10n.pendingDeleteConfirmedMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.commonCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.commonDelete),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        final notifier = ref.read(pendingTransactionNotifierProvider.notifier);
        // confirmed와 converted 모두 삭제
        await notifier.deleteAllByStatus(PendingTransactionStatus.confirmed);
        await notifier.deleteAllByStatus(PendingTransactionStatus.converted);

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l10n.commonDeletedMessage)));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
          );
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
    final l10n = AppLocalizations.of(context);
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
                l10n.pendingEditTitle,
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
                    l10n.pendingOriginalMessage,
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
            decoration: InputDecoration(
              labelText: l10n.transactionAmount,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: Spacing.md),

          // 상호명
          TextField(
            controller: _merchantController,
            decoration: InputDecoration(
              labelText: l10n.pendingMerchantName,
              border: const OutlineInputBorder(),
              prefixIcon: const Icon(Icons.store),
            ),
          ),
          const SizedBox(height: Spacing.md),

          // 거래 유형
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                value: 'expense',
                label: Text(l10n.transactionExpense),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              ButtonSegment(
                value: 'income',
                label: Text(l10n.transactionIncome),
                icon: const Icon(Icons.add_circle_outline),
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
                  : l10n.pendingSelectDate,
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
                : Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
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
        ).showSnackBar(SnackBar(content: Text(l10n.pendingTransactionUpdated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
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
