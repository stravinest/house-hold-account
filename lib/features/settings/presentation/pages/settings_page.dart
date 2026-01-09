import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../../shared/themes/theme_provider.dart';
import '../../../../shared/widgets/color_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../notification/presentation/pages/notification_settings_page.dart';

// 알림 설정 프로바이더
final notificationEnabledProvider = StateProvider<bool>((ref) => true);

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final notificationEnabled = ref.watch(notificationEnabledProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          // 앱 설정 섹션
          _SectionHeader(title: '앱 설정'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('테마'),
            subtitle: Text(_getThemeModeLabel(themeMode)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeSelector(context, ref, themeMode),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('알림'),
            subtitle: const Text('예산 초과, 공유 초대 등 알림 받기'),
            value: notificationEnabled,
            onChanged: (value) {
              ref.read(notificationEnabledProvider.notifier).state = value;
            },
          ),
          ListTile(
            leading: const Icon(Icons.notifications_active),
            title: const Text('알림 설정'),
            subtitle: const Text('알림 유형별 설정'),
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
          _SectionHeader(title: '계정'),

          // 프로필 편집 섹션
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '프로필',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  // 표시 이름
                  const _DisplayNameEditor(),
                  const SizedBox(height: 24),
                  // 색상 선택
                  Text(
                    '내 색상',
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
                            // 프로파일 프로바이더를 새로고침하여 UI 즉시 업데이트
                            ref.invalidate(userProfileProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('색상이 변경되었습니다')),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('색상 변경 실패: $e')),
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
            title: const Text('비밀번호 변경'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showPasswordChangeDialog(context, ref),
          ),

          const Divider(),

          // 데이터 섹션
          _SectionHeader(title: '데이터'),
          ListTile(
            leading: const Icon(Icons.download_outlined),
            title: const Text('데이터 내보내기'),
            subtitle: const Text('거래 내역을 CSV로 내보내기'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context),
          ),

          const Divider(),

          // 정보 섹션
          _SectionHeader(title: '정보'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('앱 정보'),
            subtitle: const Text('버전 1.0.0'),
            onTap: () => _showAboutDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('이용약관'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 이용약관 페이지로 이동
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 개인정보처리방침 페이지로 이동
            },
          ),

          const Divider(),

          // 로그아웃/탈퇴
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('로그아웃', style: TextStyle(color: Colors.red)),
            onTap: () => _logout(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('회원 탈퇴', style: TextStyle(color: Colors.red)),
            onTap: () => _deleteAccount(context, ref),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return '라이트 모드';
      case ThemeMode.dark:
        return '다크 모드';
      case ThemeMode.system:
        return '시스템 설정';
    }
  }

  void _showThemeSelector(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.system ? Theme.of(context).colorScheme.primary : Colors.transparent,
            ),
            title: const Text('시스템 설정'),
            onTap: () async {
              try {
                await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.system);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('테마 저장 실패: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.light ? Theme.of(context).colorScheme.primary : Colors.transparent,
            ),
            title: const Text('라이트 모드'),
            onTap: () async {
              try {
                await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.light);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('테마 저장 실패: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.dark ? Theme.of(context).colorScheme.primary : Colors.transparent,
            ),
            title: const Text('다크 모드'),
            onTap: () async {
              try {
                await ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('테마 저장 실패: $e')),
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

  void _showPasswordChangeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _PasswordChangeDialog(ref: ref),
    );
  }

  void _exportData(BuildContext context) {
    // TODO: 데이터 내보내기 구현
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('준비 중인 기능입니다')),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '공유 가계부',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.account_balance_wallet, size: 48),
      children: [
        const SizedBox(height: 16),
        const Text('Flutter + Supabase로 만든 공유 가계부 앱입니다.'),
        const SizedBox(height: 8),
        const Text('가족, 연인, 룸메이트와 함께 지출을 관리하세요.'),
      ],
    );
  }

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authNotifierProvider.notifier).signOut();
      if (context.mounted) {
        context.go(Routes.login);
      }
    }
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '정말 탈퇴하시겠습니까?\n\n'
          '모든 데이터가 삭제되며 복구할 수 없습니다.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: 회원 탈퇴 처리
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('준비 중인 기능입니다')),
      );
    }
  }
}

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

// 표시 이름 편집 위젯
class _DisplayNameEditor extends ConsumerStatefulWidget {
  const _DisplayNameEditor();

  @override
  ConsumerState<_DisplayNameEditor> createState() => _DisplayNameEditorState();
}

class _DisplayNameEditorState extends ConsumerState<_DisplayNameEditor> {
  late TextEditingController _controller;
  String _originalValue = '';
  bool _isChanged = false;
  bool _isLoading = false;

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
      _originalValue = _controller.text;
      setState(() {
        _isChanged = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('표시 이름이 변경되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('표시 이름 변경 실패: $e')),
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

    // 프로필이 로드되면 초기값 설정 (한 번만)
    if (_originalValue.isEmpty && displayName.isNotEmpty) {
      _originalValue = displayName;
      _controller.text = displayName;
    } else if (_originalValue.isEmpty && _controller.text.isEmpty && profile != null) {
      // 프로필은 로드됐지만 display_name이 비어있는 경우
      _originalValue = '';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: '표시 이름',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          height: 56,
          child: FilledButton(
            onPressed: _isChanged && !_isLoading ? _saveDisplayName : null,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('수정'),
          ),
        ),
      ],
    );
  }
}

// 비밀번호 변경 다이얼로그
class _PasswordChangeDialog extends StatefulWidget {
  final WidgetRef ref;

  const _PasswordChangeDialog({required this.ref});

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
          const SnackBar(content: Text('비밀번호가 변경되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
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
      title: const Text('비밀번호 변경'),
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
                  labelText: '현재 비밀번호',
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
                    return '현재 비밀번호를 입력하세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: '새 비밀번호',
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
                    return '새 비밀번호를 입력하세요';
                  }
                  if (value.length < 6) {
                    return '비밀번호는 6자 이상이어야 합니다';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: '새 비밀번호 확인',
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
                    return '새 비밀번호를 다시 입력하세요';
                  }
                  if (value != _newPasswordController.text) {
                    return '새 비밀번호가 일치하지 않습니다';
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
          child: const Text('취소'),
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
              : const Text('변경'),
        ),
      ],
    );
  }
}
