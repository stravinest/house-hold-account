import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../data/services/notification_listener_wrapper.dart';
import '../../data/services/sms_listener_service.dart';

enum AutoSavePermissionType { sms, notification, both }

class PermissionRequestDialog extends StatefulWidget {
  final AutoSavePermissionType permissionType;
  final VoidCallback? onPermissionGranted;
  final VoidCallback? onPermissionDenied;

  const PermissionRequestDialog({
    super.key,
    this.permissionType = AutoSavePermissionType.both,
    this.onPermissionGranted,
    this.onPermissionDenied,
  });

  static Future<bool> show(
    BuildContext context, {
    AutoSavePermissionType permissionType = AutoSavePermissionType.both,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          PermissionRequestDialog(permissionType: permissionType),
    );
    return result ?? false;
  }

  @override
  State<PermissionRequestDialog> createState() =>
      _PermissionRequestDialogState();
}

class _PermissionRequestDialogState extends State<PermissionRequestDialog> {
  bool _smsPermissionGranted = false;
  bool _notificationPermissionGranted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    if (!Platform.isAndroid) {
      setState(() => _isLoading = false);
      return;
    }

    if (widget.permissionType == AutoSavePermissionType.sms ||
        widget.permissionType == AutoSavePermissionType.both) {
      _smsPermissionGranted = await SmsListenerService.instance
          .checkPermissions();
    }

    if (widget.permissionType == AutoSavePermissionType.notification ||
        widget.permissionType == AutoSavePermissionType.both) {
      _notificationPermissionGranted = await NotificationListenerWrapper
          .instance
          .isPermissionGranted();
    }

    setState(() => _isLoading = false);
  }

  Future<void> _requestSmsPermission() async {
    setState(() => _isLoading = true);

    final granted = await SmsListenerService.instance.requestPermissions();

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

    final isGranted = await NotificationListenerWrapper.instance
        .isPermissionGranted();

    setState(() {
      _notificationPermissionGranted = isGranted;
      _isLoading = false;
    });

    _checkAllPermissionsGranted();
  }

  void _checkAllPermissionsGranted() {
    bool allGranted = true;

    if (widget.permissionType == AutoSavePermissionType.sms ||
        widget.permissionType == AutoSavePermissionType.both) {
      allGranted &= _smsPermissionGranted;
    }

    if (widget.permissionType == AutoSavePermissionType.notification ||
        widget.permissionType == AutoSavePermissionType.both) {
      allGranted &= _notificationPermissionGranted;
    }

    if (allGranted) {
      widget.onPermissionGranted?.call();
    }
  }

  bool get _needsSmsPermission =>
      (widget.permissionType == AutoSavePermissionType.sms ||
          widget.permissionType == AutoSavePermissionType.both) &&
      !_smsPermissionGranted;

  bool get _needsNotificationPermission =>
      (widget.permissionType == AutoSavePermissionType.notification ||
          widget.permissionType == AutoSavePermissionType.both) &&
      !_notificationPermissionGranted;

  bool get _allPermissionsGranted =>
      !_needsSmsPermission && !_needsNotificationPermission;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      title: Text('자동 저장 권한 설정', style: textTheme.titleLarge),
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
                    '거래 내역을 자동으로 저장하려면 다음 권한이 필요합니다.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  if (widget.permissionType == AutoSavePermissionType.sms ||
                      widget.permissionType == AutoSavePermissionType.both)
                    _buildPermissionItem(
                      icon: Icons.sms_outlined,
                      title: 'SMS 읽기',
                      description: '카드사/은행 문자에서 거래 정보를 읽습니다.',
                      isGranted: _smsPermissionGranted,
                      onRequest: _requestSmsPermission,
                    ),
                  if (widget.permissionType ==
                          AutoSavePermissionType.notification ||
                      widget.permissionType == AutoSavePermissionType.both) ...[
                    const SizedBox(height: Spacing.md),
                    _buildPermissionItem(
                      icon: Icons.notifications_outlined,
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
            ? colorScheme.primaryContainer.withOpacity(0.3)
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
