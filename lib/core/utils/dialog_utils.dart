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

  /// 카테고리 삭제 확인 다이얼로그 (개선된 디자인)
  ///
  /// pencil 디자인 (CategoryDeleteDialog)을 따르는 특별한 삭제 확인 다이얼로그
  ///
  /// [context] - BuildContext
  /// [categoryName] - 삭제할 카테고리 이름
  ///
  /// 반환값:
  /// - true: 사용자가 삭제 버튼을 눌렀을 때
  /// - null: 사용자가 취소 버튼을 누르거나 다이얼로그를 닫았을 때
  static Future<bool?> showCategoryDeleteConfirmation(
    BuildContext context, {
    required String categoryName,
  }) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목
              Text(
                l10n.categoryDeleteConfirmTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 카테고리명 강조 박스
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCDD2), // 연한 빨간색 배경
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 설명 메시지
              Text(
                l10n.categoryDeleteConfirmMessage,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 버튼들 (가운데 정렬)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 취소 버튼 (Outlined)
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 52),
                    ),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  // 삭제 버튼 (Elevated, 빨간색)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      minimumSize: const Size(88, 52),
                    ),
                    child: Text(l10n.commonDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 고정비 카테고리 삭제 확인 다이얼로그 (개선된 디자인)
  ///
  /// pencil 디자인 (CategoryDeleteDialog)을 따르는 고정비 삭제 확인 다이얼로그
  ///
  /// [context] - BuildContext
  /// [categoryName] - 삭제할 고정비 카테고리 이름
  ///
  /// 반환값:
  /// - true: 사용자가 삭제 버튼을 눌렀을 때
  /// - null: 사용자가 취소 버튼을 누르거나 다이얼로그를 닫았을 때
  static Future<bool?> showFixedExpenseCategoryDeleteConfirmation(
    BuildContext context, {
    required String categoryName,
  }) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 제목
              Text(
                l10n.fixedExpenseCategoryDelete,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 카테고리명 강조 박스
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFCDD2), // 연한 빨간색 배경
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 설명 메시지
              Text(
                l10n.fixedExpenseCategoryDeleteMessage,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // 버튼들 (가운데 정렬)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 취소 버튼 (Outlined)
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(88, 52),
                    ),
                    child: Text(l10n.commonCancel),
                  ),
                  const SizedBox(width: 8),
                  // 삭제 버튼 (Elevated, 빨간색)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.error,
                      foregroundColor: colorScheme.onError,
                      minimumSize: const Size(88, 52),
                    ),
                    child: Text(l10n.commonDelete),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
