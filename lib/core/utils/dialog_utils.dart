import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';

/// 확인 다이얼로그 표시를 위한 유틸리티 클래스
///
/// AlertDialog 호출을 간소화하고 일관된 스타일과 동작을 제공합니다.
///
/// 사용 예시:
/// ```dart
/// // 기본 확인 다이얼로그
/// final confirmed = await DialogUtils.showConfirmation(
///   context,
///   title: '카테고리 삭제',
///   message: '정말로 삭제하시겠습니까?',
/// );
/// if (confirmed == true) {
///   // 사용자가 확인 버튼을 눌렀을 때
/// }
///
/// // 커스텀 버튼 텍스트
/// final confirmed = await DialogUtils.showConfirmation(
///   context,
///   title: '삭제 확인',
///   message: '이 작업은 되돌릴 수 없습니다.',
///   confirmText: '삭제',
///   cancelText: '취소',
/// );
/// ```
class DialogUtils {
  DialogUtils._();

  /// 확인 다이얼로그를 표시
  ///
  /// [context] - BuildContext
  /// [title] - 다이얼로그 제목
  /// [message] - 다이얼로그 메시지 내용
  /// [confirmText] - 확인 버튼 텍스트 (기본값: l10n.commonConfirm)
  /// [cancelText] - 취소 버튼 텍스트 (기본값: l10n.commonCancel)
  ///
  /// 반환값:
  /// - true: 사용자가 확인 버튼을 눌렀을 때
  /// - null: 사용자가 취소 버튼을 누르거나 다이얼로그를 닫았을 때
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
  }) {
    final l10n = AppLocalizations.of(context);

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText ?? l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText ?? l10n.commonConfirm),
          ),
        ],
      ),
    );
  }
}
