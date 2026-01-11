import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/notification_type.dart';
import '../providers/notification_settings_provider.dart';

/// 알림 설정 페이지
///
/// 각 알림 타입별로 활성화/비활성화를 설정할 수 있는 페이지입니다.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('알림 설정'),
      ),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsList(context, ref, settings),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorView(context, error),
      ),
    );
  }

  /// 알림 설정 리스트 빌드
  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    Map<NotificationType, bool> settings,
  ) {
    return ListView(
      children: [
        // 설명 헤더
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            '받고 싶은 알림을 선택하세요',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),

        // 예산 관련 알림
        _SectionHeader(title: '예산'),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.budgetWarning,
          title: '예산 경고',
          subtitle: '예산의 80%를 초과했을 때 알림',
          icon: Icons.warning_amber_outlined,
          enabled: settings[NotificationType.budgetWarning] ?? true,
        ),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.budgetExceeded,
          title: '예산 초과',
          subtitle: '예산을 초과했을 때 알림',
          icon: Icons.error_outline,
          enabled: settings[NotificationType.budgetExceeded] ?? true,
        ),

        const Divider(),

        // 공유 가계부 관련 알림
        _SectionHeader(title: '공유 가계부'),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.sharedLedgerChange,
          title: '공유 가계부 변경',
          subtitle: '다른 멤버가 거래를 추가/수정/삭제했을 때 알림',
          icon: Icons.people_outline,
          enabled: settings[NotificationType.sharedLedgerChange] ?? true,
        ),

        const Divider(),

        // 초대 관련 알림
        _SectionHeader(title: '초대'),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.inviteReceived,
          title: '가계부 초대 받음',
          subtitle: '다른 사용자가 가계부에 초대했을 때 알림',
          icon: Icons.mail_outline,
          enabled: settings[NotificationType.inviteReceived] ?? true,
        ),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.inviteAccepted,
          title: '초대 수락됨',
          subtitle: '내가 보낸 초대를 다른 사용자가 수락했을 때 알림',
          icon: Icons.check_circle_outline,
          enabled: settings[NotificationType.inviteAccepted] ?? true,
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  /// 알림 토글 빌드
  Widget _buildNotificationToggle(
    BuildContext context,
    WidgetRef ref, {
    required NotificationType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool enabled,
  }) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: enabled,
      onChanged: (value) async {
        try {
          await ref
              .read(notificationSettingsProvider.notifier)
              .updateNotificationSetting(type, value);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('설정 저장 실패: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      },
    );
  }

  /// 에러 뷰 빌드
  Widget _buildErrorView(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '알림 설정을 불러올 수 없습니다',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// 섹션 헤더 위젯
class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
