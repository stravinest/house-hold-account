import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../notification/services/local_notification_service.dart';
import '../../data/services/notification_listener_wrapper.dart';
import '../../data/services/sms_listener_service.dart';

/// 권한 상태 표시용 색상 (다크모드 지원)
class _PermissionColors {
  final ColorScheme colorScheme;
  final bool isDark;

  _PermissionColors(BuildContext context)
      : colorScheme = Theme.of(context).colorScheme,
        isDark = Theme.of(context).brightness == Brightness.dark;

  // 다이얼로그
  Color get dialogBackground => isDark
      ? colorScheme.surfaceContainerHigh
      : const Color(0xFFFDFDF5);

  // 카드
  Color get cardBackground => isDark
      ? colorScheme.surfaceContainerHighest
      : const Color(0xFFEFEEE6);

  // 아이콘 배경
  Color get iconBackground => isDark
      ? const Color(0xFF1B5E20)
      : const Color(0xFFA8DAB5);
  Color get iconColor => isDark
      ? const Color(0xFFA8DAB5)
      : const Color(0xFF2E7D32);

  // 배지 - 비허용
  Color get deniedBadgeBackground => isDark
      ? const Color(0xFF4E2600)
      : const Color(0xFFFFF3E0);
  Color get deniedBadgeText => isDark
      ? const Color(0xFFFFB74D)
      : const Color(0xFFE65100);

  // 배지 - 허용
  Color get grantedBadgeBackground => isDark
      ? const Color(0xFF1B5E20)
      : const Color(0xFFA8DAB5);
  Color get grantedBadgeText => isDark
      ? const Color(0xFFA8DAB5)
      : const Color(0xFF2E7D32);

  // 버튼
  Color get buttonBorder => isDark
      ? colorScheme.outline
      : const Color(0xFF74796D);
  Color get buttonText => isDark
      ? const Color(0xFFA8DAB5)
      : const Color(0xFF2E7D32);

  // 텍스트
  Color get titleColor => colorScheme.onSurface;
  Color get descColor => colorScheme.onSurfaceVariant;
  Color get warningColor => isDark
      ? colorScheme.onSurfaceVariant
      : const Color(0xFF74796D);

  // 성공 메시지
  Color get successBackground => isDark
      ? const Color(0xFF1B5E20)
      : const Color(0xFFA8DAB5);
  Color get successText => isDark
      ? const Color(0xFFA8DAB5)
      : const Color(0xFF2E7D32);
}

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

  /// 비허용된 권한이 있는지 확인
  static Future<bool> hasAnyDeniedPermission() async {
    // Android가 아니면 false
    if (!Platform.isAndroid) return false;

    // 푸시 알림 권한 확인
    final pushGranted = await LocalNotificationService()
        .checkPushNotificationPermission();
    if (!pushGranted) return true;

    // SMS 권한 확인
    final smsGranted = await SmsListenerService.instance.checkPermissions();
    if (!smsGranted) return true;

    // 알림 접근 권한 확인
    final notificationGranted = await NotificationListenerWrapper.instance
        .isPermissionGranted();
    if (!notificationGranted) return true;

    return false;
  }

  /// 로그인 후 비허용된 권한이 있으면 다이얼로그 표시
  static Future<bool> showIfAnyDenied(BuildContext context) async {
    // Android가 아니면 스킵
    if (!Platform.isAndroid) return true;

    // 비허용된 권한이 있는지 확인
    final hasDenied = await hasAnyDeniedPermission();
    if (!hasDenied) return true;

    // context가 여전히 유효한지 확인
    if (!context.mounted) return false;

    // 비허용된 권한이 있으면 다이얼로그 표시
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
    final textTheme = Theme.of(context).textTheme;
    final colors = _PermissionColors(context);
    final l10n = AppLocalizations.of(context);

    // 초기 설정 모드에 따른 타이틀/설명
    final title = widget.isInitialSetup ? l10n.permissionAppSettings : l10n.permissionAutoSaveSettings;
    final description = widget.isInitialSetup
        ? l10n.permissionBetterServiceDesc
        : l10n.permissionAutoSaveDesc;

    return Dialog(
      backgroundColor: colors.dialogBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: _isLoading
            ? const SizedBox(
                height: 100,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 타이틀
                    Text(
                      title,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacing.sm),
                    // 설명
                    Text(
                      _allPermissionsGranted ? l10n.permissionAllGrantedMessage : description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: _allPermissionsGranted
                            ? colors.successText
                            : colors.descColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacing.md),
                    // 권한 카드들
                    // 푸시 알림 권한 (all 타입일 때만)
                    if (_needsPushPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.notifications_active_outlined,
                        title: l10n.permissionPushNotification,
                        description: l10n.permissionPushDesc,
                        isGranted: _pushPermissionGranted,
                        onRequest: _requestPushPermission,
                        colors: colors,
                        l10n: l10n,
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                    // SMS 권한
                    if (_needsSmsPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.sms_outlined,
                        title: l10n.permissionSmsRead,
                        description: l10n.permissionSmsDesc,
                        isGranted: _smsPermissionGranted,
                        onRequest: _requestSmsPermission,
                        colors: colors,
                        l10n: l10n,
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                    // 알림 접근 권한
                    if (_needsNotificationPermission)
                      _buildPermissionItem(
                        icon: Icons.app_settings_alt_outlined,
                        title: l10n.permissionNotificationAccess,
                        description: l10n.permissionNotificationDesc,
                        isGranted: _notificationPermissionGranted,
                        onRequest: _requestNotificationPermission,
                        isNotificationPermission: true,
                        colors: colors,
                        l10n: l10n,
                      ),
                    // 완료 메시지 (모든 권한 허용 시)
                    if (_allPermissionsGranted) ...[
                      const SizedBox(height: Spacing.md),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                          vertical: Spacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: colors.successBackground,
                          borderRadius: BorderRadius.circular(
                            BorderRadiusToken.sm,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: colors.successText,
                              size: 18,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              l10n.permissionAllGrantedBanner,
                              style: textTheme.bodyMedium?.copyWith(
                                color: colors.successText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: Spacing.md),
                    // 하단 버튼
                    Row(
                      mainAxisAlignment: _allPermissionsGranted
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.end,
                      children: [
                        if (!_allPermissionsGranted) ...[
                          TextButton(
                            onPressed: () {
                              widget.onPermissionDenied?.call();
                              Navigator.of(context).pop(false);
                            },
                            child: Text(l10n.commonCancel),
                          ),
                          const SizedBox(width: Spacing.sm),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: Text(l10n.permissionLater),
                          ),
                        ] else
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.buttonText,
                              side: BorderSide(
                                color: colors.buttonBorder,
                              ),
                              minimumSize: const Size(120, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(l10n.commonDone),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onRequest,
    required _PermissionColors colors,
    required AppLocalizations l10n,
    bool isNotificationPermission = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isGranted ? Icons.check : Icons.priority_high,
                  size: 18,
                  color: colors.iconColor,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isGranted
                                ? colors.grantedBadgeBackground
                                : colors.deniedBadgeBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGranted ? l10n.permissionGranted : l10n.permissionRequired,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isGranted
                                  ? colors.grantedBadgeText
                                  : colors.deniedBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.descColor,
                      ),
                    ),
                    if (isNotificationPermission && !isGranted)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.xs),
                        child: Text(
                          l10n.permissionSystemSettings,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.warningColor,
                            fontStyle: FontStyle.italic,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (!isGranted) ...[
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : onRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.buttonText,
                  side: BorderSide(color: colors.buttonBorder),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isNotificationPermission ? l10n.permissionOpenSettings : l10n.permissionAllow),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
