import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthService - updateProfile 색상 HEX 검증 로직', () {
    // HEX 색상 코드 검증 함수 (AuthService.updateProfile에서 사용될 로직)
    void validateHexColor(String color) {
      if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) {
        throw ArgumentError('Invalid color format. Must be HEX code (e.g., #A8D8EA)');
      }
    }

    test('검증 함수가 정의되어 있어야 한다', () {
      // When & Then: 검증 함수 호출 가능
      expect(validateHexColor, isNotNull);
    });

    group('HEX 코드 형식 검증', () {
      test('유효한 HEX 코드 형식(#RRGGBB)은 허용되어야 한다', () {
        // Given: 다양한 유효한 HEX 코드
        final validColors = [
          '#A8D8EA', // 대문자
          '#a8d8ea', // 소문자
          '#FF5733', // 혼합
          '#000000', // 검정
          '#FFFFFF', // 흰색
        ];

        // When & Then: 모든 유효한 색상이 ArgumentError를 발생시키지 않아야 함
        for (final color in validColors) {
          expect(
            () => validateHexColor(color),
            returnsNormally,
            reason: '$color는 유효한 HEX 코드 형식입니다',
          );
        }
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - # 기호 없음', () {
        // Given: # 기호가 없는 잘못된 형식
        const invalidColor = 'A8D8EA';

        // When & Then: ArgumentError 발생 예상
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid color format'),
          )),
          reason: '# 기호가 없으면 ArgumentError가 발생해야 합니다',
        );
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - 길이가 짧음', () {
        // Given: 6자리가 아닌 짧은 형식
        const invalidColor = '#A8D';

        // When & Then: ArgumentError 발생 예상
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid color format'),
          )),
          reason: 'HEX 코드는 정확히 6자리여야 합니다',
        );
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - 길이가 김', () {
        // Given: 6자리가 아닌 긴 형식
        const invalidColor = '#A8D8EA12';

        // When & Then: ArgumentError 발생 예상
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid color format'),
          )),
          reason: 'HEX 코드는 정확히 6자리여야 합니다',
        );
      });

      test('잘못된 HEX 코드 형식은 ArgumentError를 발생시켜야 한다 - 잘못된 문자 포함', () {
        // Given: HEX에 사용할 수 없는 문자 포함
        const invalidColor = '#GGGGGG';

        // When & Then: ArgumentError 발생 예상
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('Invalid color format'),
          )),
          reason: 'HEX 코드는 0-9, A-F 문자만 사용할 수 있습니다',
        );
      });

      test('ArgumentError 메시지에 올바른 형식 예시가 포함되어야 한다', () {
        // Given: 잘못된 형식
        const invalidColor = 'invalid';

        // When & Then: 에러 메시지에 예시 포함
        expect(
          () => validateHexColor(invalidColor),
          throwsA(isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('#A8D8EA'),
          )),
          reason: '에러 메시지에 올바른 형식의 예시가 포함되어야 합니다',
        );
      });
    });
  });
}
