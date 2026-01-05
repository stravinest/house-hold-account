import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/supabase_config.dart';
import '../../../ledger/domain/entities/ledger.dart';
import '../../../ledger/presentation/providers/ledger_provider.dart';
import '../../domain/entities/ledger_invite.dart';
import '../providers/share_provider.dart';

class ShareManagementPage extends ConsumerStatefulWidget {
  const ShareManagementPage({super.key});

  @override
  ConsumerState<ShareManagementPage> createState() => _ShareManagementPageState();
}

class _ShareManagementPageState extends ConsumerState<ShareManagementPage>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('공유 관리'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '멤버'),
            Tab(text: '받은 초대'),
            Tab(text: '보낸 초대'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _MembersTab(),
          const _ReceivedInvitesTab(),
          const _SentInvitesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('초대하기'),
      ),
    );
  }

  void _showInviteDialog(BuildContext context) {
    final ledgerId = ref.read(selectedLedgerIdProvider);
    if (ledgerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가계부를 먼저 선택해주세요')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => _InviteDialog(ledgerId: ledgerId),
    );
  }
}

// 멤버 목록 탭
class _MembersTab extends ConsumerWidget {
  const _MembersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(currentLedgerMembersProvider);
    final currentUserId = SupabaseConfig.auth.currentUser?.id;

    return membersAsync.when(
      data: (members) {
        if (members.isEmpty) {
          return const Center(
            child: Text('멤버가 없습니다'),
          );
        }

        return ListView.builder(
          itemCount: members.length,
          itemBuilder: (context, index) {
            final member = members[index];
            final isCurrentUser = member.userId == currentUserId;
            final isOwner = member.role == 'owner';

            return ListTile(
              leading: CircleAvatar(
                backgroundImage: member.avatarUrl != null
                    ? NetworkImage(member.avatarUrl!)
                    : null,
                child: member.avatarUrl == null
                    ? Text(
                        (member.displayName ?? member.email ?? 'U')
                            .substring(0, 1)
                            .toUpperCase(),
                      )
                    : null,
              ),
              title: Row(
                children: [
                  Text(member.displayName ?? member.email ?? '알 수 없음'),
                  if (isCurrentUser)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        '나',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
              subtitle: Text(_getRoleLabel(member.role)),
              trailing: _buildTrailingWidget(
                context,
                ref,
                member,
                isCurrentUser,
                isOwner,
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('오류: $e')),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return '소유자';
      case 'admin':
        return '관리자';
      default:
        return '멤버';
    }
  }

  Widget? _buildTrailingWidget(
    BuildContext context,
    WidgetRef ref,
    LedgerMember member,
    bool isCurrentUser,
    bool isOwner,
  ) {
    // 소유자는 아무 액션 없음
    if (isOwner) return null;

    // 본인인 경우 나가기 버튼
    if (isCurrentUser) {
      return IconButton(
        icon: const Icon(Icons.exit_to_app, color: Colors.red),
        tooltip: '가계부 나가기',
        onPressed: () => _leaveLedger(context, ref),
      );
    }

    // 다른 멤버의 경우 관리 메뉴
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'change_role',
          child: Text(
            member.role == 'admin' ? '멤버로 변경' : '관리자로 변경',
          ),
        ),
        const PopupMenuItem(
          value: 'remove',
          child: Text(
            '내보내기',
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'change_role') {
          _changeRole(context, ref, member);
        } else if (value == 'remove') {
          _removeMember(context, ref, member);
        }
      },
    );
  }

  Future<void> _leaveLedger(BuildContext context, WidgetRef ref) async {
    final ledgerId = ref.read(selectedLedgerIdProvider);
    if (ledgerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('가계부 나가기'),
        content: const Text(
          '이 가계부에서 나가시겠습니까?\n나가면 더 이상 이 가계부의 내역을 볼 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('나가기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(shareNotifierProvider.notifier).leaveLedger(ledgerId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('가계부에서 나갔습니다')),
          );
          Navigator.pop(context); // 공유 관리 페이지 닫기
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }

  Future<void> _changeRole(
      BuildContext context, WidgetRef ref, LedgerMember member) async {
    final ledgerId = ref.read(selectedLedgerIdProvider);
    if (ledgerId == null) return;

    final newRole = member.role == 'admin' ? 'member' : 'admin';

    try {
      await ref.read(shareNotifierProvider.notifier).updateMemberRole(
            ledgerId: ledgerId,
            userId: member.userId,
            role: newRole,
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('역할이 변경되었습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _removeMember(
      BuildContext context, WidgetRef ref, LedgerMember member) async {
    final ledgerId = ref.read(selectedLedgerIdProvider);
    if (ledgerId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('멤버 내보내기'),
        content: Text('${member.displayName ?? member.email}님을 내보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('내보내기'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(shareNotifierProvider.notifier).removeMember(
              ledgerId: ledgerId,
              userId: member.userId,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('멤버가 내보내졌습니다')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }
}

// 받은 초대 목록 탭
class _ReceivedInvitesTab extends ConsumerWidget {
  const _ReceivedInvitesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitesAsync = ref.watch(receivedInvitesProvider);

    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  '받은 초대가 없습니다',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // 여러 초대가 있을 수 있으므로 스크롤 가능한 목록으로 표시
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: invites.map((invite) {
              return _buildInviteCard(context, ref, invite);
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('오류: $e')),
    );
  }

  Widget _buildInviteCard(BuildContext context, WidgetRef ref, LedgerInvite invite) {
    // 상태에 따른 색상 및 스타일 결정
    Color borderColor;
    Color iconBackgroundColor;
    Color iconColor;
    IconData iconData;

    if (invite.isAccepted) {
      borderColor = Colors.blue.shade100;
      iconBackgroundColor = Colors.blue.shade50;
      iconColor = Colors.blue.shade600;
      iconData = Icons.check_circle_outline;
    } else if (invite.isRejected) {
      borderColor = Colors.grey.shade200;
      iconBackgroundColor = Colors.grey.shade100;
      iconColor = Colors.grey.shade500;
      iconData = Icons.cancel_outlined;
    } else {
      borderColor = Colors.green.shade100;
      iconBackgroundColor = Colors.green.shade50;
      iconColor = Colors.green.shade600;
      iconData = Icons.mail_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 상태 배지
          if (invite.isAccepted || invite.isRejected)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: invite.isAccepted ? Colors.blue.shade50 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                invite.isAccepted ? '수락됨' : '거절됨',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: invite.isAccepted ? Colors.blue.shade700 : Colors.grey.shade600,
                ),
              ),
            ),
          // 아이콘
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconBackgroundColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              size: 28,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 16),
          // 가계부 이름
          Text(
            invite.ledgerName ?? '가계부',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // 초대자 정보
          Text(
            '${invite.inviterEmail ?? '알 수 없음'}님이',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            '가계부에 초대했습니다',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          // 버튼들 (pending 상태일 때만 표시)
          if (invite.isPending) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _acceptInvite(context, ref, invite),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '수락',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _rejectInvite(context, ref, invite),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '거절',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _acceptInvite(
      BuildContext context, WidgetRef ref, LedgerInvite invite) async {
    try {
      await ref.read(shareNotifierProvider.notifier).acceptInvite(invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대를 수락했습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }

  Future<void> _rejectInvite(
      BuildContext context, WidgetRef ref, LedgerInvite invite) async {
    try {
      await ref.read(shareNotifierProvider.notifier).rejectInvite(invite.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대를 거절했습니다')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    }
  }
}

// 보낸 초대 목록 탭
class _SentInvitesTab extends ConsumerWidget {
  const _SentInvitesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerId = ref.watch(selectedLedgerIdProvider);

    if (ledgerId == null) {
      return const Center(
        child: Text('가계부를 선택해주세요'),
      );
    }

    final invitesAsync = ref.watch(sentInvitesProvider(ledgerId));

    return invitesAsync.when(
      data: (invites) {
        if (invites.isEmpty) {
          return const Center(
            child: Text('보낸 초대가 없습니다'),
          );
        }

        return ListView.builder(
          itemCount: invites.length,
          itemBuilder: (context, index) {
            final invite = invites[index];

            return ListTile(
              leading: CircleAvatar(
                child: Text(invite.inviteeEmail.substring(0, 1).toUpperCase()),
              ),
              title: Text(invite.inviteeEmail),
              subtitle: Text(_getStatusLabel(invite)),
              trailing: invite.isPending
                  ? IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () =>
                          _cancelInvite(context, ref, invite, ledgerId),
                    )
                  : null,
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text('오류: $e')),
    );
  }

  String _getStatusLabel(LedgerInvite invite) {
    if (invite.isExpired) return '만료됨';
    switch (invite.status) {
      case 'pending':
        return '대기 중';
      case 'accepted':
        return '수락됨';
      case 'rejected':
        return '거절됨';
      default:
        return invite.status;
    }
  }

  Future<void> _cancelInvite(
    BuildContext context,
    WidgetRef ref,
    LedgerInvite invite,
    String ledgerId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('초대 취소'),
        content: Text('${invite.inviteeEmail}님에게 보낸 초대를 취소하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(shareNotifierProvider.notifier).cancelInvite(
              inviteId: invite.id,
              ledgerId: ledgerId,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('초대가 취소되었습니다')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류: $e')),
          );
        }
      }
    }
  }
}

// 초대 다이얼로그
class _InviteDialog extends ConsumerStatefulWidget {
  final String ledgerId;

  const _InviteDialog({required this.ledgerId});

  @override
  ConsumerState<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends ConsumerState<_InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRole = 'member';
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('멤버 초대'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: '이메일',
                hintText: 'example@email.com',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '이메일을 입력해주세요';
                }
                if (!value.contains('@')) {
                  return '올바른 이메일 형식이 아닙니다';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: const InputDecoration(
                labelText: '역할',
                border: OutlineInputBorder(),
              ),
              isExpanded: true,
              itemHeight: 60,
              items: const [
                DropdownMenuItem(
                  value: 'member',
                  child: _RoleDropdownItem(
                    title: '멤버',
                    description: '거래 내역 조회/추가/수정/삭제',
                  ),
                ),
                DropdownMenuItem(
                  value: 'admin',
                  child: _RoleDropdownItem(
                    title: '관리자',
                    description: '거래 + 카테고리/예산 관리 + 멤버 초대',
                  ),
                ),
              ],
              selectedItemBuilder: (context) => [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('멤버'),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('관리자'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _sendInvite,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('초대'),
        ),
      ],
    );
  }

  Future<void> _sendInvite() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(shareNotifierProvider.notifier).sendInvite(
            ledgerId: widget.ledgerId,
            email: _emailController.text.trim(),
            role: _selectedRole,
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('초대를 보냈습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('오류: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}

// 역할 드롭다운 아이템 위젯
class _RoleDropdownItem extends StatelessWidget {
  final String title;
  final String description;

  const _RoleDropdownItem({
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        Text(
          description,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}
