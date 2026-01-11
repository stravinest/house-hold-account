import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ledger.dart';
import '../providers/ledger_provider.dart';

// 최소 가계부 개수 상수
class _LedgerConstants {
  static const int minLedgerCount = 1;
}

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
                ledgersCount: ledgers.length,
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
  final int ledgersCount;

  const _LedgerCard({
    required this.ledger,
    required this.isSelected,
    required this.onSelect,
    required this.ledgersCount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner = ledger.ownerId == currentUserId;
    final membersAsync = ref.watch(ledgerMembersProvider(ledger.id));

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
                        if (ledger.isShared)
                          _MemberInfoWidget(
                            ledger: ledger,
                            membersAsync: membersAsync,
                            currentUserId: currentUserId,
                            buildMembersInfo: _buildMembersInfo,
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

  Widget _buildMembersInfo(
    BuildContext context,
    List<LedgerMember> members,
    String? currentUserId,
  ) {
    // currentUserId가 null이면 표시하지 않음
    if (currentUserId == null) {
      return const SizedBox.shrink();
    }

    // 본인 제외한 멤버 목록
    final otherMembers = members
        .where((m) => m.userId != currentUserId)
        .toList();

    if (otherMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    // 이름 추출 헬퍼 함수
    String getName(LedgerMember member) {
      return member.displayName ??
          member.email?.split('@')[0] ??
          '사용자';
    }

    // 멤버 수에 따라 텍스트 생성
    String memberText;
    if (otherMembers.length == 1) {
      memberText = '${getName(otherMembers[0])}님과 공유 중';
    } else if (otherMembers.length == 2) {
      memberText =
          '${getName(otherMembers[0])}, ${getName(otherMembers[1])}님과 공유 중';
    } else {
      final remainingCount = otherMembers.length - 2;
      memberText =
          '${getName(otherMembers[0])}, ${getName(otherMembers[1])} 외 $remainingCount명과 공유 중';
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              memberText,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    // 가계부가 1개뿐이면 삭제 불가 경고
    if (ledgersCount <= _LedgerConstants.minLedgerCount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('삭제 불가'),
          content: const Text(
            '최소 1개의 가계부가 필요합니다.\n다른 가계부를 먼저 생성해주세요.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('확인'),
            ),
          ],
        ),
      );
      return;
    }

    // 현재 선택된 가계부인지 확인
    final selectedId = ref.read(selectedLedgerIdProvider);
    final isCurrentlySelected = ledger.id == selectedId;

    // 기존 삭제 확인 다이얼로그
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가계부 삭제'),
        content: Text(
          '\'${ledger.name}\' 가계부를 삭제하시겠습니까?\n\n'
          '${isCurrentlySelected ? '현재 사용 중인 가계부입니다.\n삭제 후 다른 가계부로 자동 전환됩니다.\n\n' : ''}'
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
                    const SnackBar(
                      content: Text('가계부가 삭제되었습니다'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('삭제 실패: $e'),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 1),
                    ),
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
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('오류: $e'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }
}

// 멤버 정보 위젯 - 한 번만 동기화 실행
class _MemberInfoWidget extends ConsumerStatefulWidget {
  final Ledger ledger;
  final AsyncValue<List<LedgerMember>> membersAsync;
  final String? currentUserId;
  final Widget Function(BuildContext, List<LedgerMember>, String?) buildMembersInfo;

  // 이미 동기화 처리된 ledger ID 추적 (위젯 재생성 시에도 유지)
  static final Set<String> _syncedLedgerIds = {};
  static final Set<String> _refreshTriedLedgerIds = {};

  const _MemberInfoWidget({
    required this.ledger,
    required this.membersAsync,
    required this.currentUserId,
    required this.buildMembersInfo,
  });

  @override
  ConsumerState<_MemberInfoWidget> createState() => _MemberInfoWidgetState();
}

class _MemberInfoWidgetState extends ConsumerState<_MemberInfoWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.membersAsync.when(
      data: (members) {
        // 멤버 수에 따라 공유 상태 자동 동기화 (ledger당 한 번만 실행)
        final needsSync = widget.ledger.isShared && members.length < 2;
        final alreadySynced = _MemberInfoWidget._syncedLedgerIds.contains(widget.ledger.id);

        if (needsSync && !alreadySynced) {
          _MemberInfoWidget._syncedLedgerIds.add(widget.ledger.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(ledgerNotifierProvider.notifier).syncShareStatus(
              ledgerId: widget.ledger.id,
              memberCount: members.length,
              currentIsShared: widget.ledger.isShared,
            );
          });
        }

        // 동기화 완료 후 (isShared가 false가 되면) 추적에서 제거
        if (!widget.ledger.isShared) {
          _MemberInfoWidget._syncedLedgerIds.remove(widget.ledger.id);
          _MemberInfoWidget._refreshTriedLedgerIds.remove(widget.ledger.id);
        }

        return widget.buildMembersInfo(context, members, widget.currentUserId);
      },
      loading: () => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              '멤버 정보 로딩 중...',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
      error: (error, stack) {
        // 에러 발생 시 빈 위젯 반환 (공유 해제된 가계부일 가능성)
        // 가계부 목록이 Realtime으로 자동 업데이트되므로 별도 새로고침 불필요
        return const SizedBox.shrink();
      },
    );
  }
}
