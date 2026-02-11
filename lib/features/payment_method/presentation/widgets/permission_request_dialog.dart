import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../shared/themes/design_tokens.dart';
import '../../../notification/services/local_notification_service.dart';
import '../../data/services/notification_listener_wrapper.dart';
import '../../data/services/sms_listener_service.dart';

/// 권한 상태 표시용 색상 상수 (pencil 디자인 umYUS/v8XwX 기준)
class _PermissionColors {
  // 다이얼로그
  static const Color dialogBackground = Color(0xFFFDFDF5);

  // 카드 (허용/비허용 동일)
  static const Color cardBackground = Color(0xFFEFEEE6);

  // 아이콘 배경 (허용/비허용 동일)
  static const Color iconBackground = Color(0xFFA8DAB5);
  static const Color iconColor = Color(0xFF2E7D32);

  // 배지 - 비허용
  static const Color deniedBadgeBackground = Color(0xFFFFF3E0);
  static const Color deniedBadgeText = Color(0xFFE65100);

  // 배지 - 허용
  static const Color grantedBadgeBackground = Color(0xFFA8DAB5);
  static const Color grantedBadgeText = Color(0xFF2E7D32);

  // 버튼
  static const Color buttonBorder = Color(0xFF74796D);
  static const Color buttonText = Color(0xFF2E7D32);

  // 텍스트
  static const Color titleColor = Color(0xFF1A1C19);
  static const Color descColor = Color(0xFF44483E);
  static const Color warningColor = Color(0xFF74796D);

  // 성공 메시지
  static const Color successBackground = Color(0xFFA8DAB5);
  static const Color successText = Color(0xFF2E7D32);
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

    // 초기 설정 모드에 따른 타이틀/설명
    final title = widget.isInitialSetup ? '앱 권한 설정' : '자동 저장 권한 설정';
    final description = widget.isInitialSetup
        ? '더 나은 서비스를 위해 다음 권한이 필요합니다.'
        : '거래 내역을 자동으로 저장하려면 다음 권한이 필요합니다.';

    return Dialog(
      backgroundColor: _PermissionColors.dialogBackground,
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
                        color: _PermissionColors.titleColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacing.sm),
                    // 설명
                    Text(
                      _allPermissionsGranted ? '모든 권한이 허용되었습니다.' : description,
                      style: textTheme.bodyMedium?.copyWith(
                        color: _allPermissionsGranted
                            ? _PermissionColors.successText
                            : _PermissionColors.descColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Spacing.md),
                    // 권한 카드들
                    // 푸시 알림 권한 (all 타입일 때만)
                    if (_needsPushPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.notifications_active_outlined,
                        title: '푸시 알림',
                        description: '공유 가계부 알림, 초대 알림 등을 받습니다.',
                        isGranted: _pushPermissionGranted,
                        onRequest: _requestPushPermission,
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                    // SMS 권한
                    if (_needsSmsPermission) ...[
                      _buildPermissionItem(
                        icon: Icons.sms_outlined,
                        title: 'SMS 읽기',
                        description: '카드사/은행 문자에서 거래 정보를 읽습니다.',
                        isGranted: _smsPermissionGranted,
                        onRequest: _requestSmsPermission,
                      ),
                      const SizedBox(height: Spacing.sm),
                    ],
                    // 알림 접근 권한
                    if (_needsNotificationPermission)
                      _buildPermissionItem(
                        icon: Icons.app_settings_alt_outlined,
                        title: '알림 접근',
                        description: '카드/은행 앱 푸시 알림에서 거래 정보를 읽습니다.',
                        isGranted: _notificationPermissionGranted,
                        onRequest: _requestNotificationPermission,
                        isNotificationPermission: true,
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
                          color: _PermissionColors.successBackground,
                          borderRadius: BorderRadius.circular(
                            BorderRadiusToken.sm,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: _PermissionColors.successText,
                              size: 18,
                            ),
                            const SizedBox(width: Spacing.sm),
                            Text(
                              '모든 권한이 허용되었습니다',
                              style: textTheme.bodyMedium?.copyWith(
                                color: _PermissionColors.successText,
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
                            child: const Text('취소'),
                          ),
                          const SizedBox(width: Spacing.sm),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                            child: const Text('나중에'),
                          ),
                        ] else
                          OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop(true);
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _PermissionColors.buttonText,
                              side: const BorderSide(
                                color: _PermissionColors.buttonBorder,
                              ),
                              minimumSize: const Size(120, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('완료'),
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
    bool isNotificationPermission = false,
  }) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: _PermissionColors.cardBackground,
        borderRadius: BorderRadius.circular(BorderRadiusToken.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더 (아이콘 + 제목 + 배지)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상태 아이콘 박스
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _PermissionColors.iconBackground,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  isGranted ? Icons.check : Icons.priority_high,
                  size: 18,
                  color: _PermissionColors.iconColor,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              // 제목 + 설명
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목 + 배지
                    Row(
                      children: [
                        Text(
                          title,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: Spacing.sm),
                        // 상태 배지
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Spacing.sm,
                            vertical: Spacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: isGranted
                                ? _PermissionColors.grantedBadgeBackground
                                : _PermissionColors.deniedBadgeBackground,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isGranted ? '허용됨' : '필요',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: isGranted
                                  ? _PermissionColors.grantedBadgeText
                                  : _PermissionColors.deniedBadgeText,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: Spacing.xs),
                    // 설명
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: _PermissionColors.descColor,
                      ),
                    ),
                    // 알림 접근 권한 경고 텍스트
                    if (isNotificationPermission && !isGranted)
                      Padding(
                        padding: const EdgeInsets.only(top: Spacing.xs),
                        child: Text(
                          '시스템 설정에서 직접 허용해야 합니다.',
                          style: textTheme.bodySmall?.copyWith(
                            color: _PermissionColors.warningColor,
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
          // 허용 버튼 (비허용 상태일 때만)
          if (!isGranted) ...[
            const SizedBox(height: Spacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : onRequest,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _PermissionColors.buttonText,
                  side: const BorderSide(color: _PermissionColors.buttonBorder),
                  padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(isNotificationPermission ? '설정 열기' : '허용'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
