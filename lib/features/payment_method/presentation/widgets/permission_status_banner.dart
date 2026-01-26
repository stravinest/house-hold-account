import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/utils/snackbar_utils.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../../shared/themes/design_tokens.dart';
import '../../data/services/notification_listener_wrapper.dart';
import '../../data/services/sms_listener_service.dart';

/// 권한 확인 상태
enum _PermissionCheckStatus {
  granted,  // 권한 허용됨
  denied,   // 권한 거부됨
  error,    // 권한 확인 실패 (시스템 오류)
}

/// 앱 재개 시 권한을 재확인하기 위한 라이프사이클 핸들러
mixin _PermissionResumeHandler<T extends StatefulWidget> on State<T> {
  late final AppLifecycleListener _lifecycleListener;

  void onAppResumed();

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onResume: onAppResumed,
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }
}

/// 투명도 상수
class _OpacityConstants {
  static const double successBannerBackground = 0.1;
  static const double permissionItemGrantedBackground = 0.5;
  static const double permissionItemDeniedBackground = 0.3;
  static const double errorButtonBackground = 0.1;
}

/// 안드로이드 플랫폼 여부
bool get _isAndroidPlatform {
  try {
    return Platform.isAndroid;
  } catch (_) {
    return false;
  }
}

/// 권한 상태 배너 위젯 (체크리스트 스타일)
///
/// SMS 읽기 권한과 알림 접근 권한의 상태를 표시하고 요청할 수 있는 배너
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
  _PermissionCheckStatus _smsPermissionStatus = _PermissionCheckStatus.error;
  _PermissionCheckStatus _notificationPermissionStatus = _PermissionCheckStatus.error;
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

    _PermissionCheckStatus smsStatus = _PermissionCheckStatus.error;
    _PermissionCheckStatus notificationStatus = _PermissionCheckStatus.error;

    // 각 권한을 독립적으로 체크 (하나 실패해도 다른 것은 계속 체크)
    try {
      final granted = await SmsListenerService.instance.checkPermissions();
      smsStatus = granted ? _PermissionCheckStatus.granted : _PermissionCheckStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('SMS 권한 체크 실패: $e');
      }
      smsStatus = _PermissionCheckStatus.error;
    }

    try {
      final granted = await NotificationListenerWrapper.instance.isPermissionGranted();
      notificationStatus = granted ? _PermissionCheckStatus.granted : _PermissionCheckStatus.denied;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('알림 권한 체크 실패: $e');
      }
      notificationStatus = _PermissionCheckStatus.error;
    }

    if (mounted) {
      setState(() {
        _smsPermissionStatus = smsStatus;
        _notificationPermissionStatus = notificationStatus;
        _isLoading = false;
      });
    }
  }

  Future<void> _requestSmsPermission() async {
    // 권한 요청 다이얼로그가 표시되므로 돌아올 때 재확인
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
    // 설정 화면으로 이동하므로 돌아올 때 권한 재확인 플래그 설정
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(Spacing.md),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
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
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final allGranted = _smsPermissionStatus == _PermissionCheckStatus.granted &&
        _notificationPermissionStatus == _PermissionCheckStatus.granted;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: allGranted
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(BorderRadiusToken.sm),
        border: Border.all(
          color: allGranted ? colorScheme.primary : colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allGranted ? Icons.check_circle : Icons.info_outline,
                color: allGranted
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: IconSize.md,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  l10n.autoSaveSettingsRequiredPermissions,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: allGranted
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),

          // SMS 권한
          _buildPermissionItem(
            context: context,
            icon: Icons.sms_outlined,
            title: 'SMS 읽기',
            description: '문자 메시지에서 거래 정보를 읽습니다',
            status: _smsPermissionStatus,
            onRequest: _requestSmsPermission,
            onRetry: _checkPermissions,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          const SizedBox(height: Spacing.sm),

          // 알림 접근 권한
          _buildPermissionItem(
            context: context,
            icon: Icons.notifications_outlined,
            title: '알림 접근',
            description: '푸시 알림에서 거래 정보를 읽습니다',
            status: _notificationPermissionStatus,
            onRequest: _requestNotificationPermission,
            onRetry: _checkPermissions,
            isNotificationPermission: true,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          if (allGranted) ...[
            const SizedBox(height: Spacing.sm),
            Container(
              padding: const EdgeInsets.all(Spacing.sm),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(
                  alpha: _OpacityConstants.successBannerBackground,
                ),
                borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: IconSize.sm,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      '모든 권한이 허용되었습니다',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required _PermissionCheckStatus status,
    required VoidCallback onRequest,
    required VoidCallback onRetry,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    bool isNotificationPermission = false,
  }) {
    final isGranted = status == _PermissionCheckStatus.granted;
    final isError = status == _PermissionCheckStatus.error;

    return Container(
      padding: const EdgeInsets.all(Spacing.sm),
      decoration: BoxDecoration(
        color: isGranted
            ? colorScheme.primaryContainer.withValues(
                alpha: _OpacityConstants.permissionItemGrantedBackground,
              )
            : colorScheme.errorContainer.withValues(
                alpha: _OpacityConstants.permissionItemDeniedBackground,
              ),
        borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
        border: Border.all(
          color: isGranted ? colorScheme.primary : colorScheme.error,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(Spacing.xs),
            decoration: BoxDecoration(
              color: isGranted ? colorScheme.primary : colorScheme.error,
              borderRadius: BorderRadius.circular(BorderRadiusToken.xs),
            ),
            child: Icon(
              isGranted ? Icons.check : (isError ? Icons.error_outline : Icons.warning_amber_rounded),
              color: isGranted ? colorScheme.onPrimary : colorScheme.onError,
              size: IconSize.sm,
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
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    if (isGranted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius:
                              BorderRadius.circular(BorderRadiusToken.xs),
                        ),
                        child: Text(
                          '허용됨',
                          style: textTheme.labelSmall?.copyWith(
                            color: colorScheme.onPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
                if (isNotificationPermission && !isGranted)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 12,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '시스템 설정에서 직접 허용 필요',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.error,
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
          ),
          if (!isGranted) ...[
            const SizedBox(width: Spacing.xs),
            TextButton(
              onPressed: isError ? onRetry : onRequest,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: Spacing.xs,
                ),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor: colorScheme.error.withValues(
                  alpha: _OpacityConstants.errorButtonBackground,
                ),
                foregroundColor: colorScheme.error,
              ),
              child: Text(
                isError
                    ? '재시도'
                    : (isNotificationPermission ? '설정 열기' : '허용'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
