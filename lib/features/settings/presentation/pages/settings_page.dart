import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../../shared/themes/locale_provider.dart';
import '../../../../shared/themes/theme_provider.dart';
import '../../../../shared/widgets/color_picker.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/pages/notification_settings_page.dart';

// 알림 설정 프로바이더
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final notificationEnabled = ref.watch(notificationEnabledProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
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
                  const SizedBox(height: 16),
                  // 표시 이름
                  _DisplayNameEditor(l10n: l10n),
                  const SizedBox(height: 24),
                  // 색상 선택
                  Text(
                    l10n.settingsMyColor,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final currentColor = ref.watch(userColorProvider);

                      return ColorPicker(
                        selectedColor: currentColor,
                        onColorSelected: (color) async {
                          final authService = ref.read(authServiceProvider);
                          try {
                            await authService.updateProfile(color: color);
                            ref.invalidate(userProfileProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(l10n.settingsColorChanged),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    l10n.settingsColorChangeFailed(
                                      e.toString(),
                                    ),
                                  ),
                                  duration: const Duration(seconds: 1),
                                ),
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

          const SizedBox(height: 8),
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

          // 정보 섹션
          SectionHeader(title: l10n.settingsInfo),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l10n.settingsAppInfo),
            subtitle: Text(l10n.settingsVersion('1.0.0')),
            onTap: () => _showAboutDialog(context, l10n),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsTerms),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 이용약관 페이지로 이동
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.settingsPrivacy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 개인정보처리방침 페이지로 이동
            },
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
    );
  }

  String _getThemeModeLabel(ThemeMode mode, AppLocalizations l10n) {
    switch (mode) {
      case ThemeMode.light:
        return l10n.settingsThemeLight;
      case ThemeMode.dark:
        return l10n.settingsThemeDark;
      case ThemeMode.system:
        return l10n.settingsThemeSystem;
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
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.system
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
            ),
            title: Text(l10n.settingsThemeSystem),
            onTap: () async {
              try {
                await ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsThemeSaveFailed(e.toString())),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.light
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsThemeSaveFailed(e.toString())),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.dark
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsThemeSaveFailed(e.toString())),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
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
      builder: (context) => Column(
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsLanguageChanged),
                      duration: const Duration(seconds: 1),
                    ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.settingsLanguageChanged),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                }
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
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
    // TODO: 데이터 내보내기 구현
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.settingsFeaturePreparing),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showAboutDialog(BuildContext context, AppLocalizations l10n) {
    showAboutDialog(
      context: context,
      applicationName: l10n.settingsAboutAppName,
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const SizedBox(height: 16),
        Text(l10n.settingsAboutAppDescription),
        const SizedBox(height: 8),
        Text(l10n.settingsAboutAppSubDescription),
      ],
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.settingsDeleteAccountFailed(e.toString())),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
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
    if (!_isChanged || _isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.updateProfile(displayName: _controller.text);
      ref.invalidate(userProfileProvider);
      _originalValue = _controller.text;
      setState(() {
        _isChanged = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsDisplayNameChanged),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsDisplayNameChangeFailed(e.toString())),
            duration: const Duration(seconds: 1),
          ),
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
            decoration: InputDecoration(
              labelText: l10n.settingsDisplayName,
              border: const OutlineInputBorder(),
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
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.settingsPasswordChanged),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), duration: const Duration(seconds: 1)),
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
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(l10n.settingsChange),
        ),
      ],
    );
  }
}
