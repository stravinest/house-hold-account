import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../../notification/services/local_notification_service.dart';
import '../../data/services/notification_listener_wrapper.dart';
import '../../data/services/sms_listener_service.dart';

/// 권한 확인 상태
enum _PermissionCheckStatus {
  granted, // 권한 허용됨
  denied, // 권한 거부됨
  error, // 권한 확인 실패 (시스템 오류)
}

/// 앱 재개 시 권한을 재확인하기 위한 라이프사이클 핸들러
mixin _PermissionResumeHandler<T extends StatefulWidget> on State<T> {
  late final AppLifecycleListener _lifecycleListener;

  void onAppResumed();

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(onResume: onAppResumed);
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }
}

/// 안드로이드 플랫폼 여부
bool get _isAndroidPlatform {
  try {
    return Platform.isAndroid;
  } catch (_) {
    return false;
  }
}

/// 다크모드 지원 배너 색상
class _BannerColors {
  final ColorScheme colorScheme;
  final bool isDark;

  _BannerColors(BuildContext context)
    : colorScheme = Theme.of(context).colorScheme,
      isDark = Theme.of(context).brightness == Brightness.dark;

  Color get background =>
      isDark ? colorScheme.surfaceContainerHigh : const Color(0xFFEFEEE6);
  Color get cardBackground =>
      isDark ? colorScheme.surfaceContainerHighest : const Color(0xFFFFFFFF);
  Color get iconGranted =>
      isDark ? const Color(0xFF1B5E20) : const Color(0xFFA8DAB5);
  Color get iconDenied =>
      isDark ? const Color(0xFF4E2600) : const Color(0xFFFFF3E0);
  Color get iconGrantedFg =>
      isDark ? const Color(0xFFA8DAB5) : const Color(0xFF2E7D32);
  Color get iconDeniedFg =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
  Color get badgeGrantedBg =>
      isDark ? const Color(0xFF1B5E20) : const Color(0xFFA8DAB5);
  Color get badgeGrantedText =>
      isDark ? const Color(0xFFA8DAB5) : const Color(0xFF2E7D32);
  Color get badgeDeniedBg =>
      isDark ? const Color(0xFF4E2600) : const Color(0xFFFFF3E0);
  Color get badgeDeniedText =>
      isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
  Color get buttonBorder =>
      isDark ? colorScheme.outline : const Color(0xFF74796D);
  Color get buttonText =>
      isDark ? const Color(0xFFA8DAB5) : const Color(0xFF2E7D32);
  Color get titleColor => colorScheme.onSurface;
  Color get descColor => colorScheme.onSurfaceVariant;
  Color get warningColor =>
      isDark ? colorScheme.onSurfaceVariant : const Color(0xFF74796D);
  Color get successBg =>
      isDark ? const Color(0xFF1B5E20) : const Color(0xFFA8DAB5);
  Color get successText =>
      isDark ? const Color(0xFFA8DAB5) : const Color(0xFF2E7D32);
}

/// 권한 상태 배너 위젯 (체크리스트 스타일)
///
/// 푸시 알림, SMS 읽기, 알림 접근 권한의 상태를 표시하고 요청할 수 있는 배너
class PermissionStatusBanner extends StatefulWidget {
  final VoidCallback onPermissionDialogRequested;

  const PermissionStatusBanner({
    super.key,
    required this.onPermissionDialogRequested,
  });

  @override
  State<PermissionStatusBanner> createState() => _PermissionStatusBannerState();
}

class _PermissionStatusBannerState extends State<PermissionStatusBanner>
    with _PermissionResumeHandler {
  _PermissionCheckStatus _pushPermissionStatus = _PermissionCheckStatus.error;
  _PermissionCheckStatus _smsPermissionStatus = _PermissionCheckStatus.error;
  _PermissionCheckStatus _notificationPermissionStatus =
      _PermissionCheckStatus.error;
  bool _isLoading = true;
  bool _shouldCheckOnResume = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void onAppResumed() {
    // 설정 화면에서 돌아올 때만 권한 재확인
    if (_shouldCheckOnResume) {
      _checkPermissions();
      _shouldCheckOnResume = false;
    }
  }

  Future<void> _checkPermissions() async {
    if (!_isAndroidPlatform) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

    _PermissionCheckStatus pushStatus = _PermissionCheckStatus.error;
    _PermissionCheckStatus smsStatus = _PermissionCheckStatus.error;
    _PermissionCheckStatus notificationStatus = _PermissionCheckStatus.error;

    // 각 권한을 독립적으로 체크 (하나 실패해도 다른 것은 계속 체크)
    try {
      final granted = await LocalNotificationService()
          .checkPushNotificationPermission();
      pushStatus = granted
          ? _PermissionCheckStatus.granted
          : _PermissionCheckStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('푸시 알림 권한 체크 실패: $e');
      }
      pushStatus = _PermissionCheckStatus.error;
    }

    try {
      final granted = await SmsListenerService.instance.checkPermissions();
      smsStatus = granted
          ? _PermissionCheckStatus.granted
          : _PermissionCheckStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SMS 권한 체크 실패: $e');
      }
      smsStatus = _PermissionCheckStatus.error;
    }

    try {
      final granted = await NotificationListenerWrapper.instance
          .isPermissionGranted();
      notificationStatus = granted
          ? _PermissionCheckStatus.granted
          : _PermissionCheckStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('알림 권한 체크 실패: $e');
      }
      notificationStatus = _PermissionCheckStatus.error;
    }

    if (mounted) {
      setState(() {
        _pushPermissionStatus = pushStatus;
        _smsPermissionStatus = smsStatus;
        _notificationPermissionStatus = notificationStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPushPermission() async {
    _shouldCheckOnResume = true;

    try {
      final granted = await LocalNotificationService()
          .requestPushNotificationPermission();
      if (mounted) {
        setState(() {
          _pushPermissionStatus = granted
              ? _PermissionCheckStatus.granted
              : _PermissionCheckStatus.denied;
          _shouldCheckOnResume = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('푸시 알림 권한 요청 중 에러: $e');
      }
      if (mounted) {
        setState(() {
          _pushPermissionStatus = _PermissionCheckStatus.error;
          _shouldCheckOnResume = false;
        });
      }
    }
  }

  Future<void> _requestSmsPermission() async {
    _shouldCheckOnResume = true;

    try {
      final granted = await SmsListenerService.instance.requestPermissions();
      if (mounted) {
        setState(() {
          _smsPermissionStatus = granted
              ? _PermissionCheckStatus.granted
              : _PermissionCheckStatus.denied;
          _shouldCheckOnResume = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SMS 권한 요청 중 에러: $e');
      }
      if (mounted) {
        setState(() {
          _smsPermissionStatus = _PermissionCheckStatus.error;
          _shouldCheckOnResume = false;
        });
      }
    }
  }

  Future<void> _requestNotificationPermission() async {
    _shouldCheckOnResume = true;

    try {
      await NotificationListenerWrapper.instance.openSettings();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('설정 화면 열기 중 에러: $e');
      }
    }

    if (!mounted) return;

    final l10n = AppLocalizations.of(context);
    SnackBarUtils.showInfo(
      context,
      l10n.permissionSettingsSnackbar,
      duration: const Duration(seconds: 5),
      action: SnackBarAction(
        label: l10n.commonConfirm,
        onPressed: _checkPermissions,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colors = _BannerColors(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(BorderRadiusToken.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              l10n.permissionCheckingStatus,
              style: textTheme.bodySmall?.copyWith(color: colors.descColor),
            ),
          ],
        ),
      );
    }

    final allGranted =
        _pushPermissionStatus == _PermissionCheckStatus.granted &&
        _smsPermissionStatus == _PermissionCheckStatus.granted &&
        _notificationPermissionStatus == _PermissionCheckStatus.granted;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.autoSaveSettingsRequiredPermissions,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.titleColor,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // 푸시 알림 권한
          _buildPermissionItem(
            icon: Icons.notifications_active_outlined,
            title: l10n.permissionPushNotification,
            description: l10n.permissionPushDescShort,
            status: _pushPermissionStatus,
            onRequest: _requestPushPermission,
            onRetry: _checkPermissions,
            textTheme: textTheme,
            colors: colors,
            l10n: l10n,
          ),

          const SizedBox(height: Spacing.sm),

          // SMS 권한
          _buildPermissionItem(
            icon: Icons.sms_outlined,
            title: l10n.permissionSmsRead,
            description: l10n.permissionSmsDescShort,
            status: _smsPermissionStatus,
            onRequest: _requestSmsPermission,
            onRetry: _checkPermissions,
            textTheme: textTheme,
            colors: colors,
            l10n: l10n,
          ),

          const SizedBox(height: Spacing.sm),

          // 알림 접근 권한
          _buildPermissionItem(
            icon: Icons.app_settings_alt_outlined,
            title: l10n.permissionNotificationAccess,
            description: l10n.permissionNotificationDescShort,
            status: _notificationPermissionStatus,
            onRequest: _requestNotificationPermission,
            onRetry: _checkPermissions,
            isNotificationPermission: true,
            textTheme: textTheme,
            colors: colors,
            l10n: l10n,
          ),

          if (allGranted) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sm,
              ),
              decoration: BoxDecoration(
                color: colors.successBg,
                borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
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
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required IconData icon,
    required String title,
    required String description,
    required _PermissionCheckStatus status,
    required VoidCallback onRequest,
    required VoidCallback onRetry,
    required TextTheme textTheme,
    required _BannerColors colors,
    required AppLocalizations l10n,
    bool isNotificationPermission = false,
  }) {
    final isGranted = status == _PermissionCheckStatus.granted;
    final isError = status == _PermissionCheckStatus.error;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isGranted ? colors.iconGranted : colors.iconDenied,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isGranted
                      ? Icons.check
                      : (isError ? Icons.error_outline : Icons.priority_high),
                  color: isGranted ? colors.iconGrantedFg : colors.iconDeniedFg,
                  size: 16,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colors.titleColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isGranted
                                ? colors.badgeGrantedBg
                                : colors.badgeDeniedBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGranted
                                ? l10n.permissionGranted
                                : l10n.permissionRequired,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isGranted
                                  ? colors.badgeGrantedText
                                  : colors.badgeDeniedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.descColor,
                        fontSize: 12,
                      ),
                    ),
                    if (isNotificationPermission && !isGranted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          l10n.permissionSystemSettingsShort,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.warningColor,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
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
                onPressed: isError ? onRetry : onRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: colors.buttonText,
                  side: BorderSide(color: colors.buttonBorder),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isError
                      ? l10n.permissionRetry
                      : (isNotificationPermission
                            ? l10n.permissionOpenSettings
                            : l10n.permissionAllowAction),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
