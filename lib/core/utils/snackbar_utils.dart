import 'package:flutter/material.dart';

import '../../shared/themes/design_tokens.dart';

/// SnackBar 표시를 위한 유틸리티 클래스
///
/// ScaffoldMessenger.of(context).showSnackBar 호출을 간소화하고
/// 일관된 스타일과 지속 시간을 제공합니다.
///
/// 사용 예시:
/// ```dart
/// // 성공 메시지
/// SnackBarUtils.showSuccess(context, '카테고리가 삭제되었습니다');
///
/// // 에러 메시지
/// SnackBarUtils.showError(context, '삭제에 실패했습니다');
///
/// // 정보 메시지
/// SnackBarUtils.showInfo(context, '변경사항이 저장되었습니다');
///
/// // 커스텀 지속 시간
/// SnackBarUtils.showSuccess(
///   context,
///   '성공',
///   duration: const Duration(seconds: 5),
/// );
/// ```
class SnackBarUtils {
  SnackBarUtils._();

  /// 성공 메시지를 표시하는 SnackBar
  ///
  /// [context] - BuildContext (내부적으로 mounted 체크 수행)
  /// [message] - 표시할 메시지
  /// [duration] - 표시 시간 (기본값: SnackBarDuration.short = 2초)
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? SnackBarDuration.short,
        backgroundColor: Colors.green[700],
      ),
    );
  }

  /// 에러 메시지를 표시하는 SnackBar
  ///
  /// [context] - BuildContext (내부적으로 mounted 체크 수행)
  /// [message] - 표시할 메시지
  /// [duration] - 표시 시간 (기본값: SnackBarDuration.short = 2초)
  static void showError(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? SnackBarDuration.short,
        backgroundColor: Colors.red[700],
      ),
    );
  }

  /// 정보 메시지를 표시하는 SnackBar
  ///
  /// [context] - BuildContext (내부적으로 mounted 체크 수행)
  /// [message] - 표시할 메시지
  /// [duration] - 표시 시간 (기본값: SnackBarDuration.short = 2초)
  static void showInfo(
    BuildContext context,
    String message, {
    Duration? duration,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration ?? SnackBarDuration.short,
      ),
    );
  }
}
