import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ledger.dart';
import '../providers/ledger_provider.dart';

class LedgerManagementPage extends ConsumerWidget {
  const LedgerManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgersAsync = ref.watch(ledgerNotifierProvider);
    final selectedId = ref.watch(selectedLedgerIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('가계부 관리'),
      ),
      body: ledgersAsync.when(
        data: (ledgers) {
          if (ledgers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '등록된 가계부가 없습니다',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddLedgerDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('가계부 만들기'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ledgers.length,
            itemBuilder: (context, index) {
              final ledger = ledgers[index];
              final isSelected = ledger.id == selectedId;

              return _LedgerCard(
                ledger: ledger,
                isSelected: isSelected,
                onSelect: () {
                  ref.read(ledgerNotifierProvider.notifier).selectLedger(ledger.id);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('오류: $e')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLedgerDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLedgerDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const _LedgerDialog(),
    );
  }
}

class _LedgerCard extends ConsumerWidget {
  final Ledger ledger;
  final bool isSelected;
  final VoidCallback onSelect;

  const _LedgerCard({
    required this.ledger,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner = ledger.ownerId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    ledger.isShared ? Icons.people : Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              ledger.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '사용중',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ledger.isShared ? '공유 가계부' : '개인 가계부',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _showEditDialog(context, ref, ledger);
                          break;
                        case 'delete':
                          _showDeleteConfirm(context, ref, ledger);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('수정'),
                            ],
                          ),
                        ),
                      if (isOwner)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: Colors.red),
                              SizedBox(width: 8),
                              Text('삭제', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (ledger.description != null &&
                  ledger.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ledger.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    ledger.currency,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    '${ledger.createdAt.year}.${ledger.createdAt.month}.${ledger.createdAt.day}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Ledger ledger) {
    showDialog(
      context: context,
      builder: (context) => _LedgerDialog(ledger: ledger),
    );
  }

  void _showDeleteConfirm(BuildContext context, WidgetRef ref, Ledger ledger) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가계부 삭제'),
        content: Text(
          '\'${ledger.name}\' 가계부를 삭제하시겠습니까?\n\n'
          '이 가계부에 기록된 모든 거래, 카테고리, 예산이 함께 삭제됩니다.\n'
          '이 작업은 되돌릴 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(ledgerNotifierProvider.notifier)
                    .deleteLedger(ledger.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('가계부가 삭제되었습니다')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('삭제 실패: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _LedgerDialog extends ConsumerStatefulWidget {
  final Ledger? ledger;

  const _LedgerDialog({this.ledger});

  @override
  ConsumerState<_LedgerDialog> createState() => _LedgerDialogState();
}

class _LedgerDialogState extends ConsumerState<_LedgerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedCurrency = 'KRW';

  final List<String> _currencies = ['KRW', 'USD', 'EUR', 'JPY', 'CNY'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.ledger?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.ledger?.description ?? '');
    _selectedCurrency = widget.ledger?.currency ?? 'KRW';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.ledger != null;

    return AlertDialog(
      title: Text(isEdit ? '가계부 수정' : '새 가계부'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '가계부 이름',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가계부 이름을 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명 (선택)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: '통화',
                  border: OutlineInputBorder(),
                ),
                items: _currencies
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCurrency = value);
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEdit ? '수정' : '만들기'),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.ledger != null) {
        await ref.read(ledgerNotifierProvider.notifier).updateLedger(
              id: widget.ledger!.id,
              name: _nameController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              currency: _selectedCurrency,
            );
      } else {
        await ref.read(ledgerNotifierProvider.notifier).createLedger(
              name: _nameController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              currency: _selectedCurrency,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.ledger != null
                ? '가계부가 수정되었습니다'
                : '가계부가 생성되었습니다'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }
}
