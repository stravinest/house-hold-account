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

/// pencil 디자인 기준 색상
class _BannerColors {
  static const Color background = Color(0xFFEFEEE6);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color iconGranted = Color(0xFFA8DAB5);
  static const Color iconDenied = Color(0xFFFFF3E0);
  static const Color iconGrantedFg = Color(0xFF2E7D32);
  static const Color iconDeniedFg = Color(0xFFE65100);
  static const Color badgeGrantedBg = Color(0xFFA8DAB5);
  static const Color badgeGrantedText = Color(0xFF2E7D32);
  static const Color badgeDeniedBg = Color(0xFFFFF3E0);
  static const Color badgeDeniedText = Color(0xFFE65100);
  static const Color buttonBorder = Color(0xFF74796D);
  static const Color buttonText = Color(0xFF2E7D32);
  static const Color titleColor = Color(0xFF1A1C19);
  static const Color descColor = Color(0xFF44483E);
  static const Color warningColor = Color(0xFF74796D);
  static const Color successBg = Color(0xFFA8DAB5);
  static const Color successText = Color(0xFF2E7D32);
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

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: _BannerColors.background,
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
              style: textTheme.bodySmall?.copyWith(
                color: _BannerColors.descColor,
              ),
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
        color: _BannerColors.background,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.autoSaveSettingsRequiredPermissions,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: _BannerColors.titleColor,
            ),
          ),
          const SizedBox(height: Spacing.md),

          // 푸시 알림 권한
          _buildPermissionItem(
            icon: Icons.notifications_active_outlined,
            title: '푸시 알림',
            description: '공유 가계부 알림, 초대 알림 등을 받습니다',
            status: _pushPermissionStatus,
            onRequest: _requestPushPermission,
            onRetry: _checkPermissions,
            textTheme: textTheme,
          ),

          const SizedBox(height: Spacing.sm),

          // SMS 권한
          _buildPermissionItem(
            icon: Icons.sms_outlined,
            title: 'SMS 읽기',
            description: '문자 메시지에서 거래 정보를 읽습니다',
            status: _smsPermissionStatus,
            onRequest: _requestSmsPermission,
            onRetry: _checkPermissions,
            textTheme: textTheme,
          ),

          const SizedBox(height: Spacing.sm),

          // 알림 접근 권한
          _buildPermissionItem(
            icon: Icons.app_settings_alt_outlined,
            title: '알림 접근',
            description: '푸시 알림에서 거래 정보를 읽습니다',
            status: _notificationPermissionStatus,
            onRequest: _requestNotificationPermission,
            onRetry: _checkPermissions,
            isNotificationPermission: true,
            textTheme: textTheme,
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
                color: _BannerColors.successBg,
                borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: _BannerColors.successText,
                    size: 18,
                  ),
                  const SizedBox(width: Spacing.sm),
                  Text(
                    '모든 권한이 허용되었습니다',
                    style: textTheme.bodyMedium?.copyWith(
                      color: _BannerColors.successText,
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
    bool isNotificationPermission = false,
  }) {
    final isGranted = status == _PermissionCheckStatus.granted;
    final isError = status == _PermissionCheckStatus.error;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: _BannerColors.cardBackground,
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
                  color: isGranted
                      ? _BannerColors.iconGranted
                      : _BannerColors.iconDenied,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isGranted
                      ? Icons.check
                      : (isError ? Icons.error_outline : Icons.priority_high),
                  color: isGranted
                      ? _BannerColors.iconGrantedFg
                      : _BannerColors.iconDeniedFg,
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
                              color: _BannerColors.titleColor,
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
                                ? _BannerColors.badgeGrantedBg
                                : _BannerColors.badgeDeniedBg,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGranted ? '허용됨' : '필요',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isGranted
                                  ? _BannerColors.badgeGrantedText
                                  : _BannerColors.badgeDeniedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: _BannerColors.descColor,
                        fontSize: 12,
                      ),
                    ),
                    if (isNotificationPermission && !isGranted)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '시스템 설정에서 직접 허용 필요',
                          style: textTheme.bodySmall?.copyWith(
                            color: _BannerColors.warningColor,
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
                  foregroundColor: _BannerColors.buttonText,
                  side: const BorderSide(color: _BannerColors.buttonBorder),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  isError
                      ? '재시도'
                      : (isNotificationPermission ? '설정 열기' : '허용하기'),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
