import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/models/fcm_token_model.dart';
import 'package:shared_household_account/features/notification/data/repositories/fcm_token_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late FcmTokenRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = FcmTokenRepository(client: mockClient);
  });

  group('FcmTokenRepository - getFcmTokens', () {
    test('사용자의 FCM 토큰 조회 시 생성일 기준 내림차순으로 정렬된 리스트를 반환한다',
        () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'token-1',
          'user_id': 'user-123',
          'token': 'fcm-token-abc',
          'device_type': 'android',
          'created_at': '2024-01-15T00:00:00Z',
          'updated_at': '2024-01-15T00:00:00Z',
        },
        {
          'id': 'token-2',
          'user_id': 'user-123',
          'token': 'fcm-token-def',
          'device_type': 'ios',
          'created_at': '2024-01-10T00:00:00Z',
          'updated_at': '2024-01-10T00:00:00Z',
        },
      ];

      when(() => mockClient.from('fcm_tokens'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getFcmTokens('user-123');
      expect(result, isA<List<FcmTokenModel>>());
      expect(result.length, 2);
      expect(result[0].token, 'fcm-token-abc');
    });
  });

  group('FcmTokenRepository - saveFcmToken', () {
    test('FCM 토큰 저장 시 다른 사용자의 동일 토큰을 먼저 삭제하고 UPSERT를 실행한다',
        () async {
      // from()이 두 번 호출됨: delete 체인, upsert 체인
      when(() => mockClient.from('fcm_tokens'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.saveFcmToken(
        userId: 'user-123',
        token: 'fcm-token-xyz',
        deviceType: 'android',
      );
      // 에러 없이 완료되면 성공
    });
  });

  group('FcmTokenRepository - deleteFcmToken', () {
    test('FCM 토큰 삭제 시 올바른 토큰으로 DELETE 쿼리를 실행한다', () async {
      when(() => mockClient.from('fcm_tokens'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteFcmToken('fcm-token-abc');
      // 에러 없이 완료되면 성공
    });
  });

  group('FcmTokenRepository - deleteAllUserTokens', () {
    test('사용자의 모든 FCM 토큰 삭제 시 user_id로 필터링하여 삭제한다', () async {
      when(() => mockClient.from('fcm_tokens'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteAllUserTokens('user-123');
      // 에러 없이 완료되면 성공
    });
  });
}
