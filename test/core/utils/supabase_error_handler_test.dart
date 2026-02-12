import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/core/utils/supabase_error_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseErrorHandler', () {
    group('isDuplicateError', () {
      test('PostgrestException에서 23505 코드를 감지한다', () {
        // Given
        final error = PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        );

        // When
        final result = SupabaseErrorHandler.isDuplicateError(error);

        // Then
        expect(result, isTrue);
      });

      test('에러 문자열에서 duplicate 키워드를 감지한다', () {
        // Given
        final error = Exception('duplicate key error');

        // When
        final result = SupabaseErrorHandler.isDuplicateError(error);

        // Then
        expect(result, isTrue);
      });

      test('에러 문자열에서 unique 키워드를 감지한다', () {
        // Given
        final error = Exception('unique constraint violation');

        // When
        final result = SupabaseErrorHandler.isDuplicateError(error);

        // Then
        expect(result, isTrue);
      });

      test('에러 문자열에서 23505 코드를 감지한다', () {
        // Given
        final error = Exception('error code 23505 occurred');

        // When
        final result = SupabaseErrorHandler.isDuplicateError(error);

        // Then
        expect(result, isTrue);
      });

      test('중복 에러가 아닌 경우 false를 반환한다', () {
        // Given
        final error = Exception('some other error');

        // When
        final result = SupabaseErrorHandler.isDuplicateError(error);

        // Then
        expect(result, isFalse);
      });

      test('대소문자를 구분하지 않고 duplicate를 감지한다', () {
        // Given
        final error = Exception('DUPLICATE KEY ERROR');

        // When
        final result = SupabaseErrorHandler.isDuplicateError(error);

        // Then
        expect(result, isTrue);
      });
    });

    group('isForeignKeyError', () {
      test('PostgrestException에서 23503 코드를 감지한다', () {
        // Given
        final error = PostgrestException(
          message: 'violates foreign key constraint',
          code: '23503',
        );

        // When
        final result = SupabaseErrorHandler.isForeignKeyError(error);

        // Then
        expect(result, isTrue);
      });

      test('에러 문자열에서 23503 코드를 감지한다', () {
        // Given
        final error = Exception('error 23503: foreign key violation');

        // When
        final result = SupabaseErrorHandler.isForeignKeyError(error);

        // Then
        expect(result, isTrue);
      });

      test('외래키 에러가 아닌 경우 false를 반환한다', () {
        // Given
        final error = Exception('some other error');

        // When
        final result = SupabaseErrorHandler.isForeignKeyError(error);

        // Then
        expect(result, isFalse);
      });
    });

    group('getErrorMessage', () {
      test('중복 에러일 때 적절한 한글 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(message: 'duplicate', code: '23505');

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, contains('이미 동일한 이름의'));
        expect(result, contains('항목'));
      });

      test('중복 에러일 때 itemType을 포함한 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(message: 'duplicate', code: '23505');

        // When
        final result = SupabaseErrorHandler.getErrorMessage(
          error,
          itemType: '카테고리',
        );

        // Then
        expect(result, contains('카테고리'));
        expect(result, contains('이미 동일한 이름의'));
      });

      test('외래키 에러일 때 적절한 한글 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(
          message: 'foreign key violation',
          code: '23503',
        );

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, contains('다른 데이터에서 사용 중'));
        expect(result, contains('삭제할 수 없습니다'));
      });

      test('외래키 에러일 때 itemType을 포함한 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(
          message: 'foreign key violation',
          code: '23503',
        );

        // When
        final result = SupabaseErrorHandler.getErrorMessage(
          error,
          itemType: '결제수단',
        );

        // Then
        expect(result, contains('결제수단'));
        expect(result, contains('다른 데이터에서 사용 중'));
      });

      test('RLS 권한 에러(42501)일 때 권한 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(
          message: 'insufficient privilege',
          code: '42501',
        );

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, equals('권한이 없습니다.'));
      });

      test('RLS 메시지 포함 에러일 때 권한 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(
          message: 'RLS policy violation',
          code: 'PGRST000',
        );

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, equals('권한이 없습니다.'));
      });

      test('무한 재귀 에러(42P17)일 때 서버 오류 메시지를 반환한다', () {
        // Given
        final error = PostgrestException(
          message: 'infinite recursion',
          code: '42P17',
        );

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, contains('서버 오류'));
        expect(result, contains('잠시 후 다시 시도'));
      });

      test('일반 Exception일 때 toString()을 반환한다', () {
        // Given
        final error = Exception('일반 에러 메시지');

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, contains('일반 에러 메시지'));
      });

      test('알 수 없는 PostgrestException일 때 toString()을 반환한다', () {
        // Given
        final error = PostgrestException(
          message: '알 수 없는 에러',
          code: '99999',
        );

        // When
        final result = SupabaseErrorHandler.getErrorMessage(error);

        // Then
        expect(result, contains('알 수 없는 에러'));
      });
    });

    group('toUserFriendlyException', () {
      test('에러를 Exception으로 변환한다', () {
        // Given
        final error = PostgrestException(message: 'duplicate', code: '23505');

        // When
        final result = SupabaseErrorHandler.toUserFriendlyException(error);

        // Then
        expect(result, isA<Exception>());
      });

      test('변환된 Exception의 메시지가 getErrorMessage와 동일하다', () {
        // Given
        final error = PostgrestException(message: 'duplicate', code: '23505');
        final expectedMessage = SupabaseErrorHandler.getErrorMessage(
          error,
          itemType: '가계부',
        );

        // When
        final result = SupabaseErrorHandler.toUserFriendlyException(
          error,
          itemType: '가계부',
        );

        // Then
        expect(result.toString(), contains(expectedMessage));
      });
    });
  });

  group('DuplicateItemException', () {
    test('itemName이 있을 때 이름을 포함한 메시지를 반환한다', () {
      // Given
      final exception = DuplicateItemException(
        itemType: '카테고리',
        itemName: '식비',
      );

      // When
      final message = exception.toString();

      // Then
      expect(message, contains("'식비'"));
      expect(message, contains('카테고리'));
      expect(message, contains('이미 존재합니다'));
    });

    test('itemName이 없을 때 기본 메시지를 반환한다', () {
      // Given
      final exception = DuplicateItemException(itemType: '결제수단');

      // When
      final message = exception.toString();

      // Then
      expect(message, contains('이미 동일한 이름의'));
      expect(message, contains('결제수단'));
      expect(message, contains('존재합니다'));
    });

    test('Exception으로 throw되고 catch될 수 있다', () {
      // Given
      final exception = DuplicateItemException(
        itemType: '가계부',
        itemName: '테스트',
      );

      // When & Then
      expect(
        () => throw exception,
        throwsA(isA<DuplicateItemException>()),
      );
    });
  });
}
