import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/router.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

// 테마 모드 프로바이더
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.system);

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

          const Divider(),

          // 가계부 관리 섹션
          _SectionHeader(title: '가계부 관리'),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('카테고리 관리'),
            subtitle: const Text('수입/지출 카테고리 설정'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.category),
          ),
          ListTile(
            leading: const Icon(Icons.credit_card_outlined),
            title: const Text('결제수단 관리'),
            subtitle: const Text('결제수단 추가/수정/삭제'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(Routes.paymentMethod),
          ),

          const Divider(),

          // 계정 섹션
          _SectionHeader(title: '계정'),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('프로필 편집'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: 프로필 편집 페이지로 이동
            },
          ),
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
            onTap: () {
              ref.read(themeModeProvider.notifier).state = ThemeMode.system;
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.light ? Theme.of(context).colorScheme.primary : Colors.transparent,
            ),
            title: const Text('라이트 모드'),
            onTap: () {
              ref.read(themeModeProvider.notifier).state = ThemeMode.light;
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: Icon(
              Icons.check,
              color: current == ThemeMode.dark ? Theme.of(context).colorScheme.primary : Colors.transparent,
            ),
            title: const Text('다크 모드'),
            onTap: () {
              ref.read(themeModeProvider.notifier).state = ThemeMode.dark;
              Navigator.pop(context);
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
      builder: (context) => AlertDialog(
        title: const Text('비밀번호 변경'),
        content: const Text('비밀번호 재설정 이메일을 보내시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: 비밀번호 재설정 이메일 발송
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('비밀번호 재설정 이메일을 발송했습니다')),
              );
            },
            child: const Text('보내기'),
          ),
        ],
      ),
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
