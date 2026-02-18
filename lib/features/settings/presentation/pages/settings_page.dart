import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../config/router.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/themes/locale_provider.dart';
import '../../../../shared/themes/theme_provider.dart';
import '../../../../shared/utils/responsive_utils.dart';
import '../../../../shared/widgets/color_picker.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../ledger/presentation/providers/calendar_view_provider.dart';
import '../../../notification/presentation/pages/notification_settings_page.dart';
import '../../../payment_method/presentation/widgets/permission_request_dialog.dart';
import '../../data/services/app_update_service.dart';
import '../providers/app_update_provider.dart';
import '../widgets/data_export_bottom_sheet.dart';

// 알림 설정 프로바이더
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationEnabled = ref.watch(notificationEnabledProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        scrolledUnderElevation: 0,
      ),
      body: CenteredContent(
        maxWidth: context.isTabletOrLarger ? 600 : double.infinity,
        child: ListView(
          children: [
            // 앱 설정 섹션
            SectionHeader(title: l10n.settingsAppSettings),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: Text(l10n.settingsTheme),
              subtitle: Text(_getThemeModeLabel(themeMode, l10n)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showThemeSelector(context, ref, themeMode, l10n),
            ),
            ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.settingsLanguage),
              subtitle: Text(_getLocaleLabel(locale, l10n)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLanguageSelector(context, ref, locale, l10n),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: Text(l10n.settingsNotification),
              subtitle: Text(l10n.settingsNotificationDescription),
              value: notificationEnabled,
              onChanged: (value) {
                ref.read(notificationEnabledProvider.notifier).state = value;
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(l10n.settingsNotificationSettings),
              subtitle: Text(l10n.settingsNotificationSettingsDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsPage(),
                  ),
                );
              },
            ),
            // 주 시작일 설정
            Consumer(
              builder: (context, ref, child) {
                final weekStartDay = ref.watch(weekStartDayProvider);
                return ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l10n.settingsWeekStartDay),
                  subtitle: Text(
                    weekStartDay == WeekStartDay.sunday
                        ? l10n.settingsWeekStartSunday
                        : l10n.settingsWeekStartMonday,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showWeekStartDaySelector(
                    context,
                    ref,
                    weekStartDay,
                    l10n,
                  ),
                );
              },
            ),

            // 앱 권한 설정 (Android 전용)
            if (Platform.isAndroid)
              ListTile(
                leading: const Icon(Icons.security_outlined),
                title: Text(l10n.permissionAppSettings),
                subtitle: Text(l10n.settingsAppPermissionsDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  PermissionRequestDialog.show(
                    context,
                    permissionType: AutoSavePermissionType.all,
                    isInitialSetup: true,
                  );
                },
              ),

            const Divider(),

            // 계정 섹션
            SectionHeader(title: l10n.settingsAccount),

            // 프로필 편집 섹션
            Card(
              margin: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.settingsProfile,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: Spacing.md),
                    // 표시 이름
                    _DisplayNameEditor(l10n: l10n),
                    const SizedBox(height: Spacing.lg),
                    // 색상 선택
                    Text(
                      l10n.settingsMyColor,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: Spacing.sm + Spacing.xs),
                    Consumer(
                      builder: (context, ref, child) {
                        final currentColor = ref.watch(userColorProvider);

                        return ColorPicker(
                          selectedColor: currentColor,
                          onColorSelected: (color) async {
                            final authService = ref.read(authServiceProvider);
                            try {
                              await authService.updateProfile(color: color);
                              if (context.mounted) {
                                ref.invalidate(userProfileProvider);
                                SnackBarUtils.showSuccess(
                                  context,
                                  l10n.settingsColorChanged,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                SnackBarUtils.showError(
                                  context,
                                  l10n.settingsColorChangeFailed(e.toString()),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: Spacing.sm),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: Text(l10n.settingsPasswordChange),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPasswordChangeDialog(context, ref, l10n),
            ),

            const Divider(),

            // 데이터 섹션
            SectionHeader(title: l10n.settingsData),
            ListTile(
              leading: const Icon(Icons.download_outlined),
              title: Text(l10n.settingsDataExport),
              subtitle: Text(l10n.settingsDataExportDescription),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _exportData(context, l10n),
            ),

            const Divider(),

            // 개발자 옵션 (디버그 모드에서만 표시)
            if (kDebugMode) ...[
              SectionHeader(title: l10n.settingsDeveloperOptions),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: Text(l10n.settingsAutoCollectDebug),
                subtitle: Text(l10n.settingsAutoCollectDebugDesc),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.debugTest),
              ),
              const Divider(),
            ],

            // 정보 섹션
            SectionHeader(title: l10n.settingsInfo),
            _AppInfoTile(l10n: l10n),
            ListTile(
              leading: const Icon(Icons.menu_book_outlined),
              title: Text(l10n.settingsGuide),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.guide),
            ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l10n.settingsTerms),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.termsOfService),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(l10n.settingsPrivacy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(Routes.privacyPolicy),
            ),

            const Divider(),

            // 로그아웃/탈퇴
            Builder(
              builder: (context) {
                final errorColor = Theme.of(context).colorScheme.error;
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.logout, color: errorColor),
                      title: Text(
                        l10n.authLogout,
                        style: TextStyle(color: errorColor),
                      ),
                      onTap: () => _logout(context, ref, l10n),
                    ),
                    ListTile(
                      leading: Icon(Icons.delete_forever, color: errorColor),
                      title: Text(
                        l10n.settingsDeleteAccount,
                        style: TextStyle(color: errorColor),
                      ),
                      onTap: () => _deleteAccount(context, ref, l10n),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
      case ThemeMode.system:
        // 시스템 설정은 더 이상 사용하지 않음 (라이트 모드로 표시)
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
    }
  }

  String _getLocaleLabel(Locale locale, AppLocalizations l10n) {
    if (locale.languageCode == 'ko') {
      return l10n.settingsLanguageKorean;
    } else {
      return l10n.settingsLanguageEnglish;
    }
  }

  void _showThemeSelector(
    BuildContext context,
    WidgetRef ref,
    ThemeMode current,
    AppLocalizations l10n,
  ) {
    // 시스템 설정이 선택되어 있으면 라이트 모드로 표시
    final effectiveCurrent = current == ThemeMode.system
        ? ThemeMode.light
        : current;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.check,
                color: effectiveCurrent == ThemeMode.light
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              title: Text(l10n.settingsThemeLight),
              onTap: () async {
                try {
                  await ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.light);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackBarUtils.showError(
                      context,
                      l10n.settingsThemeSaveFailed(e.toString()),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check,
                color: effectiveCurrent == ThemeMode.dark
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              title: Text(l10n.settingsThemeDark),
              onTap: () async {
                try {
                  await ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(ThemeMode.dark);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackBarUtils.showError(
                      context,
                      l10n.settingsThemeSaveFailed(e.toString()),
                    );
                  }
                }
              },
            ),
            SizedBox(height: Spacing.md + bottomPadding),
          ],
        );
      },
    );
  }

  void _showLanguageSelector(
    BuildContext context,
    WidgetRef ref,
    Locale current,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.check,
                color: current.languageCode == 'ko'
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              title: Text(l10n.settingsLanguageKorean),
              onTap: () async {
                try {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(SupportedLocales.korean);
                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackBarUtils.showSuccess(
                      context,
                      l10n.settingsLanguageChanged,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check,
                color: current.languageCode == 'en'
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              title: Text(l10n.settingsLanguageEnglish),
              onTap: () async {
                try {
                  await ref
                      .read(localeProvider.notifier)
                      .setLocale(SupportedLocales.english);
                  if (context.mounted) {
                    Navigator.pop(context);
                    SnackBarUtils.showSuccess(
                      context,
                      l10n.settingsLanguageChanged,
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            SizedBox(height: Spacing.md + bottomPadding),
          ],
        );
      },
    );
  }

  void _showWeekStartDaySelector(
    BuildContext context,
    WidgetRef ref,
    WeekStartDay current,
    AppLocalizations l10n,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                Icons.check,
                color: current == WeekStartDay.sunday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              title: Text(l10n.settingsWeekStartSunday),
              onTap: () async {
                try {
                  await ref
                      .read(weekStartDayProvider.notifier)
                      .setWeekStartDay(WeekStartDay.sunday);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.check,
                color: current == WeekStartDay.monday
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
              ),
              title: Text(l10n.settingsWeekStartMonday),
              onTap: () async {
                try {
                  await ref
                      .read(weekStartDayProvider.notifier)
                      .setWeekStartDay(WeekStartDay.monday);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            SizedBox(height: Spacing.md + bottomPadding),
          ],
        );
      },
    );
  }

  void _showPasswordChangeDialog(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) {
    showDialog(
      context: context,
      builder: (context) => _PasswordChangeDialog(ref: ref, l10n: l10n),
    );
  }

  void _exportData(BuildContext context, AppLocalizations l10n) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const DataExportBottomSheet(),
    );
  }

  Future<void> _logout(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.authLogout),
        content: Text(l10n.settingsLogoutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.authLogout),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  Future<void> _deleteAccount(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsDeleteAccount),
        content: Text(l10n.settingsDeleteAccountConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.shareLeave),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(authNotifierProvider.notifier).deleteAccount();
        if (context.mounted) {
          await ref.read(authNotifierProvider.notifier).signOut();
        }
      } catch (e) {
        if (context.mounted) {
          SnackBarUtils.showError(
            context,
            l10n.settingsDeleteAccountFailed(e.toString()),
          );
        }
      }
    }
  }
}

// 앱 정보 타일 (업데이트 정보 포함)
class _AppInfoTile extends ConsumerWidget {
  final AppLocalizations l10n;

  const _AppInfoTile({required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateInfo = ref.watch(appUpdateProvider).valueOrNull;
    final currentVersion =
        ref.watch(packageInfoProvider).valueOrNull?.version ?? '';

    final subtitle = updateInfo != null
        ? l10n.settingsNewVersionAvailable(updateInfo.version)
        : currentVersion.isNotEmpty
            ? l10n.settingsVersion(currentVersion)
            : '';

    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: Text(l10n.settingsAppInfo),
      subtitle: Text(subtitle),
      trailing: updateInfo != null
          ? Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () =>
          _showAboutDialog(context, l10n, currentVersion, updateInfo),
    );
  }

  void _showAboutDialog(
    BuildContext context,
    AppLocalizations l10n,
    String currentVersion,
    AppVersionInfo? updateInfo,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/app_icon.png',
                width: 64,
                height: 64,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.settingsAboutAppName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.settingsVersion(
                  currentVersion.isNotEmpty ? currentVersion : '...'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (updateInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.settingsNewVersionAvailable(updateInfo.version),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
            const SizedBox(height: 16),
            Text(l10n.settingsAboutAppDescription),
            const SizedBox(height: 8),
            Text(l10n.settingsAboutAppSubDescription),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonClose),
          ),
          if (updateInfo?.storeUrl != null)
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                final url = Uri.tryParse(updateInfo!.storeUrl!);
                if (url != null) launchUrl(url);
              },
              child: Text(l10n.settingsUpdate),
            ),
        ],
      ),
    );
  }
}

// 표시 이름 편집 위젯
class _DisplayNameEditor extends ConsumerStatefulWidget {
  final AppLocalizations l10n;

  const _DisplayNameEditor({required this.l10n});

  @override
  ConsumerState<_DisplayNameEditor> createState() => _DisplayNameEditorState();
}

class _DisplayNameEditorState extends ConsumerState<_DisplayNameEditor> {
  late TextEditingController _controller;
  String _originalValue = '';
  bool _isChanged = false;
  bool _isLoading = false;

  AppLocalizations get l10n => widget.l10n;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final isChanged = _controller.text != _originalValue;
    if (_isChanged != isChanged) {
      setState(() {
        _isChanged = isChanged;
      });
    }
  }

  Future<void> _saveDisplayName() async {
    final newName = _controller.text.trim();
    if (newName.isEmpty) {
      SnackBarUtils.showError(context, l10n.settingsDisplayNameRequired);
      return;
    }

    if (!_isChanged || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(displayName: newName);
      ref.invalidate(userProfileProvider);
      _originalValue = newName;
      setState(() {
        _isChanged = false;
      });
      if (mounted) {
        SnackBarUtils.showSuccess(context, l10n.settingsDisplayNameChanged);
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          l10n.settingsDisplayNameChangeFailed(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final displayName = profile?['display_name'] ?? '';

    if (_originalValue.isEmpty && displayName.isNotEmpty) {
      _originalValue = displayName;
      _controller.text = displayName;
    } else if (_originalValue.isEmpty &&
        _controller.text.isEmpty &&
        profile != null) {
      _originalValue = '';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            maxLength: 15,
            decoration: InputDecoration(
              labelText: l10n.settingsDisplayName,
              border: const OutlineInputBorder(),
              counterText: '',
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          height: 56,
          child: FilledButton(
            onPressed: _isChanged && !_isLoading ? _saveDisplayName : null,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: _isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : Text(l10n.commonEdit),
          ),
        ),
      ],
    );
  }
}

// 비밀번호 변경 다이얼로그
class _PasswordChangeDialog extends StatefulWidget {
  final WidgetRef ref;
  final AppLocalizations l10n;

  const _PasswordChangeDialog({required this.ref, required this.l10n});

  @override
  State<_PasswordChangeDialog> createState() => _PasswordChangeDialogState();
}

class _PasswordChangeDialogState extends State<_PasswordChangeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  AppLocalizations get l10n => widget.l10n;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = widget.ref.read(authServiceProvider);
      await authService.verifyAndUpdatePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        Navigator.pop(context);
        SnackBarUtils.showSuccess(context, l10n.settingsPasswordChanged);
      }
    } catch (e) {
      if (mounted) {
        // 보안: 에러 원본 노출 방지 - 일반화된 메시지 사용
        final errorMessage = e.toString().contains('현재 비밀번호')
            ? l10n.settingsPasswordCurrentIncorrect
            : l10n.settingsPasswordChangeFailed;
        SnackBarUtils.showError(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(l10n.settingsPasswordChange),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrentPassword,
                decoration: InputDecoration(
                  labelText: l10n.settingsCurrentPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureCurrentPassword = !_obscureCurrentPassword;
                      });
                    },
                    tooltip: l10n.tooltipTogglePassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.settingsCurrentPasswordHint;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: l10n.settingsNewPassword,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      });
                    },
                    tooltip: l10n.tooltipTogglePassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.settingsNewPasswordHint;
                  }
                  if (value.length < 6) {
                    return l10n.validationPasswordTooShort;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: l10n.settingsNewPasswordConfirm,
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    tooltip: l10n.tooltipTogglePassword,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.settingsNewPasswordConfirmHint;
                  }
                  if (value != _newPasswordController.text) {
                    return l10n.settingsNewPasswordMismatch;
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Text(l10n.settingsChange),
        ),
      ],
    );
  }
}
