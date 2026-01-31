import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../../notification/services/local_notification_service.dart';
import '../../data/services/notification_listener_wrapper.dart';
import '../../data/services/sms_listener_service.dart';

/// 권한 요청 타입
/// - sms: SMS 읽기 권한만
/// - notification: 알림 접근 권한만
/// - both: SMS + 알림 접근 (자동 수집용)
/// - all: 푸시 알림 + SMS + 알림 접근 (앱 초기 설정용)
enum AutoSavePermissionType { sms, notification, both, all }

class PermissionRequestDialog extends StatefulWidget {
  final AutoSavePermissionType permissionType;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  /// 앱 초기 설정 모드 (타이틀/설명이 변경됨)
  final bool isInitialSetup;

  const PermissionRequestDialog({
    super.key,
    this.permissionType = AutoSavePermissionType.both,
    this.onPermissionGranted,
    this.onPermissionDenied,
    this.isInitialSetup = false,
  });

  static Future<bool> show(
    BuildContext context, {
    AutoSavePermissionType permissionType = AutoSavePermissionType.both,
    bool isInitialSetup = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PermissionRequestDialog(
        permissionType: permissionType,
        isInitialSetup: isInitialSetup,
      ),
    );
    return result ?? false;
  }

  /// 앱 초기 실행 시 모든 권한 요청 다이얼로그 표시
  static Future<bool> showInitialPermissions(BuildContext context) async {
    // Android가 아니면 스킵
    if (!Platform.isAndroid) return true;

    return show(
      context,
      permissionType: AutoSavePermissionType.all,
      isInitialSetup: true,
    );
  }

  @override
  State<PermissionRequestDialog> createState() =>
      _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _pushPermissionGranted = false;
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isLoading = true;

  bool get _needsPushPermission =>
      widget.permissionType == AutoSavePermissionType.all;

  bool get _needsSmsPermission =>
      widget.permissionType == AutoSavePermissionType.sms ||
      widget.permissionType == AutoSavePermissionType.both ||
      widget.permissionType == AutoSavePermissionType.all;

  bool get _needsNotificationPermission =>
      widget.permissionType == AutoSavePermissionType.notification ||
      widget.permissionType == AutoSavePermissionType.both ||
      widget.permissionType == AutoSavePermissionType.all;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    if (!Platform.isAndroid) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // 푸시 알림 권한 확인 (all 타입일 때만)
    if (_needsPushPermission) {
      _pushPermissionGranted = await LocalNotificationService()
          .checkPushNotificationPermission();
    }
    if (!mounted) return;

    // SMS 권한 확인
    if (_needsSmsPermission) {
      _smsPermissionGranted = await SmsListenerService.instance
          .checkPermissions();
    }
    if (!mounted) return;

    // 알림 접근 권한 확인
    if (_needsNotificationPermission) {
      _notificationPermissionGranted = await NotificationListenerWrapper
          .instance
          .isPermissionGranted();
    }
    if (!mounted) return;

    setState(() => _isLoading = false);
  }

  Future<void> _requestSmsPermission() async {
    setState(() => _isLoading = true);

    final granted = await SmsListenerService.instance.requestPermissions();

    if (!mounted) return;

    setState(() {
      _smsPermissionGranted = granted;
      _isLoading = false;
    });

    _checkAllPermissionsGranted();
  }

  Future<void> _requestNotificationPermission() async {
    setState(() => _isLoading = true);

    await NotificationListenerWrapper.instance.requestPermission();

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final isGranted = await NotificationListenerWrapper.instance
        .isPermissionGranted();

    if (!mounted) return;

    setState(() {
      _notificationPermissionGranted = isGranted;
      _isLoading = false;
    });

    _checkAllPermissionsGranted();
  }

  Future<void> _requestPushPermission() async {
    setState(() => _isLoading = true);

    final granted = await LocalNotificationService()
        .requestPushNotificationPermission();

    if (!mounted) return;

    setState(() {
      _pushPermissionGranted = granted;
      _isLoading = false;
    });

    _checkAllPermissionsGranted();
  }

  void _checkAllPermissionsGranted() {
    if (_allPermissionsGranted) {
      widget.onPermissionGranted?.call();
    }
  }

  bool get _allPermissionsGranted {
    if (_needsPushPermission && !_pushPermissionGranted) return false;
    if (_needsSmsPermission && !_smsPermissionGranted) return false;
    if (_needsNotificationPermission && !_notificationPermissionGranted) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 초기 설정 모드에 따른 타이틀/설명
    final title = widget.isInitialSetup ? '앱 권한 설정' : '자동 저장 권한 설정';
    final description = widget.isInitialSetup
        ? '더 나은 서비스를 위해 다음 권한이 필요합니다.'
        : '거래 내역을 자동으로 저장하려면 다음 권한이 필요합니다.';

    return AlertDialog(
      title: Text(title, style: textTheme.titleLarge),
      content: _isLoading
          ? const SizedBox(
              height: 100,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  // 푸시 알림 권한 (all 타입일 때만)
                  if (_needsPushPermission) ...[
                    _buildPermissionItem(
                      icon: Icons.notifications_active_outlined,
                      title: '푸시 알림',
                      description: '공유 가계부 알림, 초대 알림 등을 받습니다.',
                      isGranted: _pushPermissionGranted,
                      onRequest: _requestPushPermission,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  // SMS 권한
                  if (_needsSmsPermission)
                    _buildPermissionItem(
                      icon: Icons.sms_outlined,
                      title: 'SMS 읽기',
                      description: '카드사/은행 문자에서 거래 정보를 읽습니다.',
                      isGranted: _smsPermissionGranted,
                      onRequest: _requestSmsPermission,
                    ),
                  // 알림 접근 권한
                  if (_needsNotificationPermission) ...[
                    const SizedBox(height: Spacing.md),
                    _buildPermissionItem(
                      icon: Icons.app_settings_alt_outlined,
                      title: '알림 접근',
                      description: '카드/은행 앱 푸시 알림에서 거래 정보를 읽습니다.',
                      isGranted: _notificationPermissionGranted,
                      onRequest: _requestNotificationPermission,
                      isNotificationPermission: true,
                    ),
                  ],
                  if (_allPermissionsGranted) ...[
                    const SizedBox(height: Spacing.md),
                    Container(
                      padding: const EdgeInsets.all(Spacing.sm),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          BorderRadiusToken.sm,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                            size: IconSize.md,
                          ),
                          const SizedBox(width: Spacing.sm),
                          Expanded(
                            child: Text(
                              '모든 권한이 허용되었습니다!',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
      actions: [
        TextButton(
          onPressed: () {
            widget.onPermissionDenied?.call();
            Navigator.of(context).pop(false);
          },
          child: const Text('취소'),
        ),
        if (_allPermissionsGranted)
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text('완료'),
          )
        else
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text('나중에'),
          ),
      ],
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    bool isNotificationPermission = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: isGranted
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
        border: Border.all(
          color: isGranted ? colorScheme.primary : colorScheme.outline,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.sm),
            decoration: BoxDecoration(
              color: isGranted
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
            ),
            child: Icon(
              icon,
              color: isGranted
                  ? colorScheme.onPrimary
                  : colorScheme.onSurfaceVariant,
              size: IconSize.md,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    if (isGranted) ...[
                      const SizedBox(width: Spacing.xs),
                      Icon(
                        Icons.check,
                        color: colorScheme.primary,
                        size: IconSize.sm,
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (isNotificationPermission && !isGranted)
                  Padding(
                    padding: const EdgeInsets.only(top: Spacing.xs),
                    child: Text(
                      '시스템 설정에서 직접 허용해야 합니다.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.error,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (!isGranted)
            TextButton(
              onPressed: _isLoading ? null : onRequest,
              child: Text(isNotificationPermission ? '설정 열기' : '허용'),
            ),
        ],
      ),
    );
  }
}
