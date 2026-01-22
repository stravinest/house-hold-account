import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/skeleton_loading.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../domain/entities/ledger.dart';
import '../providers/ledger_provider.dart';

// 최소 가계부 개수 상수
class _LedgerConstants {
  static const int minLedgerCount = 1;
}

class LedgerManagementPage extends ConsumerStatefulWidget {
  const LedgerManagementPage({super.key});

  @override
  ConsumerState<LedgerManagementPage> createState() =>
      _LedgerManagementPageState();
}

class _LedgerManagementPageState extends ConsumerState<LedgerManagementPage> {
  @override
  void initState() {
    super.initState();
    // autoDispose provider는 페이지 재진입 시 자동으로 새 인스턴스를 생성하여 데이터를 로드하고,
    // Realtime subscription이 변경사항을 감지하므로 수동 refresh가 불필요합니다.
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ledgersAsync = ref.watch(ledgerNotifierProvider);
    final selectedId = ref.watch(selectedLedgerIdProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.ledgerManagement)),
      body: ledgersAsync.when(
        data: (ledgers) {
          if (ledgers.isEmpty) {
            return EmptyState(
              icon: Icons.book_outlined,
              message: l10n.ledgerNoLedgers,
              action: ElevatedButton.icon(
                onPressed: () => _showAddLedgerDialog(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.ledgerCreateButton),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Spacing.md),
            cacheExtent: 500, // 성능 최적화: 스크롤 시 미리 렌더링
            itemCount: ledgers.length,
            itemBuilder: (context, index) {
              final ledger = ledgers[index];
              final isSelected = ledger.id == selectedId;

              return _LedgerCard(
                ledger: ledger,
                isSelected: isSelected,
                onSelect: () {
                  ref
                      .read(ledgerNotifierProvider.notifier)
                      .selectLedger(ledger.id);
                },
                ledgersCount: ledgers.length,
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(Spacing.md),
          itemCount: 3,
          itemBuilder: (context, index) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: Row(
                children: [
                  const SkeletonCircle(size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonLine(
                          width: MediaQuery.of(context).size.width * 0.4,
                          height: 16,
                        ),
                        const SizedBox(height: 8),
                        SkeletonLine(
                          width: MediaQuery.of(context).size.width * 0.2,
                          height: 12,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        error: (e, _) =>
            Center(child: Text(l10n.errorWithMessage(e.toString()))),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddLedgerDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddLedgerDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (context) => const _LedgerDialog());
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
    final l10n = AppLocalizations.of(context);
    final currentUserId = ref.watch(currentUserProvider)?.id;
    final isOwner = ledger.ownerId == currentUserId;
    final membersAsync = ref.watch(ledgerMembersProvider(ledger.id));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onSelect,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        child: Padding(
          padding: const EdgeInsets.all(Spacing.md),
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isSelected) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.ledgerInUse,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          ledger.isShared
                              ? l10n.ledgerShared
                              : l10n.ledgerPersonal,
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
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
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              const Icon(Icons.edit, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.commonEdit),
                            ],
                          ),
                        ),
                      if (isOwner)
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 20,
                                color: Theme.of(context).colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.commonDelete,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
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
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final colorScheme = Theme.of(context).colorScheme;
                  return Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ledger.currency,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ledger.createdAt.year}.${ledger.createdAt.month}.${ledger.createdAt.day}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  );
                },
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
    final l10n = AppLocalizations.of(context);

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
          l10n.ledgerUser;
    }

    // 멤버 수에 따라 텍스트 생성
    String memberText;
    if (otherMembers.length == 1) {
      memberText = l10n.ledgerSharedWithOne(getName(otherMembers[0]));
    } else if (otherMembers.length == 2) {
      memberText = l10n.ledgerSharedWithTwo(
        getName(otherMembers[0]),
        getName(otherMembers[1]),
      );
    } else {
      final remainingCount = otherMembers.length - 2;
      memberText = l10n.ledgerSharedWithMany(
        getName(otherMembers[0]),
        getName(otherMembers[1]),
        remainingCount,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            size: 14,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              memberText,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurface.withOpacity(0.7),
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
    final l10n = AppLocalizations.of(context);

    // 가계부가 1개뿐이면 삭제 불가 경고
    if (ledgersCount <= _LedgerConstants.minLedgerCount) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.ledgerDeleteNotAllowedTitle),
          content: Text(l10n.ledgerDeleteNotAllowedContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonConfirm),
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
        title: Text(l10n.ledgerDeleteConfirmTitle),
        content: Text(
          '${isCurrentlySelected ? l10n.ledgerDeleteCurrentInUseWarning : ''}'
          '${l10n.ledgerDeleteConfirmWithName(ledger.name)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(ledgerNotifierProvider.notifier)
                    .deleteLedger(ledger.id);

                if (context.mounted) {
                  SnackBarUtils.showSuccess(context, l10n.ledgerDeleted);
                }
              } catch (e) {
                if (context.mounted) {
                  SnackBarUtils.showError(
                    context,
                    l10n.ledgerDeleteFailed(e.toString()),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.commonDelete),
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
    _descriptionController = TextEditingController(
      text: widget.ledger?.description ?? '',
    );
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
    final l10n = AppLocalizations.of(context);
    final isEdit = widget.ledger != null;

    return AlertDialog(
      title: Text(isEdit ? l10n.ledgerEditTitle : l10n.ledgerNewTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 20,
                decoration: InputDecoration(
                  labelText: l10n.ledgerNameLabel,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.ledgerNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: l10n.ledgerDescriptionLabel,
                  border: const OutlineInputBorder(),
                  counterText: '',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedCurrency,
                decoration: InputDecoration(
                  labelText: l10n.ledgerCurrencyLabel,
                  border: const OutlineInputBorder(),
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
          child: Text(l10n.commonCancel),
        ),
        TextButton(
          onPressed: _submit,
          child: Text(isEdit ? l10n.commonEdit : l10n.ledgerCreateButton),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);

    if (!_formKey.currentState!.validate()) return;

    try {
      if (widget.ledger != null) {
        await ref
            .read(ledgerNotifierProvider.notifier)
            .updateLedger(
              id: widget.ledger!.id,
              name: _nameController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              currency: _selectedCurrency,
            );
      } else {
        await ref
            .read(ledgerNotifierProvider.notifier)
            .createLedger(
              name: _nameController.text,
              description: _descriptionController.text.isEmpty
                  ? null
                  : _descriptionController.text,
              currency: _selectedCurrency,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(
          context,
          widget.ledger != null ? l10n.ledgerUpdated : l10n.ledgerCreated,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, l10n.errorWithMessage(e.toString()));
      }
    }
  }
}

// 멤버 정보 위젯 - 한 번만 동기화 실행
class _MemberInfoWidget extends ConsumerStatefulWidget {
  final Ledger ledger;
  final AsyncValue<List<LedgerMember>> membersAsync;
  final String? currentUserId;
  final Widget Function(BuildContext, List<LedgerMember>, String?)
  buildMembersInfo;

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
    final l10n = AppLocalizations.of(context);

    return widget.membersAsync.when(
      data: (members) {
        // 멤버 수에 따라 공유 상태 자동 동기화 (ledger당 한 번만 실행)
        final needsSync = widget.ledger.isShared && members.length < 2;
        final alreadySynced = _MemberInfoWidget._syncedLedgerIds.contains(
          widget.ledger.id,
        );

        if (needsSync && !alreadySynced) {
          _MemberInfoWidget._syncedLedgerIds.add(widget.ledger.id);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref
                .read(ledgerNotifierProvider.notifier)
                .syncShareStatus(
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
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.ledgerMemberLoading,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
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
