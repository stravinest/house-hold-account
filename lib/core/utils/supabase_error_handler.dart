import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase/PostgreSQL 에러를 사용자 친화적인 메시지로 변환하는 유틸리티
class SupabaseErrorHandler {
  /// PostgreSQL 에러 코드
  static const String uniqueViolation = '23505'; // unique_violation
  static const String foreignKeyViolation = '23503'; // foreign_key_violation
  static const String notNullViolation = '23502'; // not_null_violation
  static const String checkViolation = '23514'; // check_violation

  /// 에러가 중복 에러인지 확인
  static bool isDuplicateError(dynamic error) {
    if (error is PostgrestException) {
      return error.code == uniqueViolation;
    }
    // 문자열에서 에러 코드 확인
    final errorString = error.toString().toLowerCase();
    return errorString.contains('duplicate') ||
        errorString.contains('unique') ||
        errorString.contains('23505');
  }

  /// 에러가 외래키 위반인지 확인
  static bool isForeignKeyError(dynamic error) {
    if (error is PostgrestException) {
      return error.code == foreignKeyViolation;
    }
    return error.toString().contains('23503');
  }

  /// 에러 메시지 변환 (항목 타입에 따른 메시지)
  static String getErrorMessage(dynamic error, {String? itemType}) {
    final type = itemType ?? '항목';

    if (isDuplicateError(error)) {
      return '이미 동일한 이름의 $type이(가) 존재합니다.';
    }

    if (isForeignKeyError(error)) {
      return '이 $type은(는) 다른 데이터에서 사용 중이므로 삭제할 수 없습니다.';
    }

    if (error is PostgrestException) {
      // RLS 에러
      if (error.code == '42501' || error.message.contains('RLS')) {
        return '권한이 없습니다.';
      }
      // 무한 재귀 에러
      if (error.code == '42P17') {
        return '서버 오류가 발생했습니다. 잠시 후 다시 시도해주세요.';
      }
    }

    return error.toString();
  }

  /// 에러를 사용자 친화적인 Exception으로 변환
  static Exception toUserFriendlyException(dynamic error, {String? itemType}) {
    return Exception(getErrorMessage(error, itemType: itemType));
  }
}

/// Duplicate 에러를 위한 커스텀 Exception
class DuplicateItemException implements Exception {
  final String itemType;
  final String? itemName;

  DuplicateItemException({required this.itemType, this.itemName});

  @override
  String toString() {
    if (itemName != null) {
      return "'$itemName' $itemType이(가) 이미 존재합니다.";
    }
    return '이미 동일한 이름의 $itemType이(가) 존재합니다.';
  }
}
