import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../domain/entities/notification_type.dart';
import '../providers/notification_settings_provider.dart';

/// 알림 설정 페이지
///
/// 각 알림 타입별로 활성화/비활성화를 설정할 수 있는 페이지입니다.
class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final settingsAsync = ref.watch(notificationSettingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationSettingsTitle)),
      body: settingsAsync.when(
        data: (settings) => _buildSettingsList(context, ref, settings, l10n),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _buildErrorView(context, error, l10n),
      ),
    );
  }

  /// 알림 설정 리스트 빌드
  Widget _buildSettingsList(
    BuildContext context,
    WidgetRef ref,
    Map<NotificationType, bool> settings,
    AppLocalizations l10n,
  ) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(Spacing.md),
          child: Text(
            l10n.notificationSettingsDescription,
            style: Theme.of(context).textTheme.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),

        SectionHeader(title: l10n.notificationSectionSharedLedger),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.sharedLedgerChange,
          title: l10n.notificationSharedLedgerChange,
          subtitle: l10n.notificationSharedLedgerChangeDesc,
          icon: Icons.people_outline,
          enabled: settings[NotificationType.sharedLedgerChange] ?? true,
        ),

        const Divider(),

        SectionHeader(title: l10n.notificationSectionInvite),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.inviteReceived,
          title: l10n.notificationInviteReceived,
          subtitle: l10n.notificationInviteReceivedDesc,
          icon: Icons.mail_outline,
          enabled: settings[NotificationType.inviteReceived] ?? true,
        ),
        _buildNotificationToggle(
          context,
          ref,
          type: NotificationType.inviteAccepted,
          title: l10n.notificationInviteAccepted,
          subtitle: l10n.notificationInviteAcceptedDesc,
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
    final l10n = AppLocalizations.of(context)!;
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
                content: Text(
                  l10n.notificationSettingsSaveFailed(e.toString()),
                ),
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
  Widget _buildErrorView(
    BuildContext context,
    Object error,
    AppLocalizations l10n,
  ) {
    return EmptyState(
      icon: Icons.error_outline,
      message: l10n.notificationSettingsLoadFailed,
      subtitle: error.toString(),
    );
  }
}
