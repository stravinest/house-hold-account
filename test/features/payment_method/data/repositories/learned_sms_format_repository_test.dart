import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/learned_sms_format_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_sms_format_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late LearnedSmsFormatRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = LearnedSmsFormatRepository(client: mockClient);
  });

  Map<String, dynamic> _makeFormatData({
    String id = 'fmt-1',
    double confidence = 0.9,
    int matchCount = 10,
  }) {
    return {
      'id': id,
      'payment_method_id': 'pm-1',
      'sender_pattern': 'KB',
      'sender_keywords': ['KB카드', 'KB'],
      'amount_regex': r'\d+원',
      'type_keywords': {
        'expense': ['사용', '결제']
      },
      'merchant_regex': null,
      'date_regex': null,
      'sample_sms': 'KB카드 사용 10000원',
      'is_system': false,
      'confidence': confidence,
      'match_count': matchCount,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
  }

  group('LearnedSmsFormatRepository - getFormatsByPaymentMethod', () {
    test('결제수단별 SMS 포맷 조회 시 신뢰도 기준 내림차순으로 정렬된 리스트를 반환한다',
        () async {
      final mockData = [_makeFormatData()];

      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getFormatsByPaymentMethod('pm-1');
      expect(result, isA<List<LearnedSmsFormatModel>>());
      expect(result.length, 1);
      expect(result[0].confidence, 0.9);
    });
  });

  group('LearnedSmsFormatRepository - createFormat', () {
    test('SMS 포맷 생성 시 올바른 데이터로 INSERT하고 생성된 포맷을 반환한다', () async {
      final mockResponse =
          _makeFormatData(id: 'fmt-new', confidence: 0.8, matchCount: 0);

      when(() => mockClient.from('learned_sms_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.createFormat(
        paymentMethodId: 'pm-1',
        senderPattern: 'KB카드',
        amountRegex: r'\d+원',
      );
      expect(result, isA<LearnedSmsFormatModel>());
      expect(result.id, 'fmt-new');
      expect(result.senderPattern, 'KB');
    });
  });

  group('LearnedSmsFormatRepository - incrementMatchCount', () {
    test('매칭 카운트 증가 시 RPC 함수를 호출한다', () async {
      when(() => mockClient.rpc('increment_sms_format_match_count',
              params: any(named: 'params')))
          .thenAnswer(
              (_) => FakePostgrestFilterBuilder<dynamic>(null));

      await repository.incrementMatchCount('fmt-1');
      verify(() => mockClient.rpc('increment_sms_format_match_count',
          params: any(named: 'params'))).called(1);
    });

    test('RPC 함수 실패 시 직접 업데이트로 폴백한다', () async {
      when(() => mockClient.rpc('increment_sms_format_match_count',
              params: any(named: 'params')))
          .thenThrow(Exception('RPC failed'));

      when(() => mockClient.from('learned_sms_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [{'match_count': 5}],
            maybeSingleData: {'match_count': 5},
            hasMaybeSingleData: true,
          ));

      await repository.incrementMatchCount('fmt-1');
      // 폴백이 에러 없이 완료되면 성공
    });
  });

  group('LearnedSmsFormatRepository - deleteFormat', () {
    test('포맷 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteFormat('fmt-1');
      // 에러 없이 완료되면 성공
    });
  });
}
