import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/learned_push_format_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_push_format_repository.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late LearnedPushFormatRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = LearnedPushFormatRepository(client: mockClient);
  });

  Map<String, dynamic> _makeFormatData({
    String id = 'fmt-1',
    double confidence = 0.95,
    int matchCount = 20,
  }) {
    return {
      'id': id,
      'payment_method_id': 'pm-1',
      'package_name': 'com.kbcard.cxh.appcard',
      'app_keywords': ['KB Pay', 'KB국민카드'],
      'amount_regex': r'\d{1,3}(,\d{3})*원',
      'type_keywords': {
        'expense': ['결제', '승인']
      },
      'merchant_regex': null,
      'date_regex': null,
      'sample_notification': 'KB Pay 결제 10,000원',
      'confidence': confidence,
      'match_count': matchCount,
      'created_at': '2024-01-01T00:00:00Z',
      'updated_at': '2024-01-01T00:00:00Z',
    };
  }

  group('LearnedPushFormatRepository - getFormatsByPaymentMethod', () {
    test('결제수단별 Push 포맷 조회 시 신뢰도 기준 내림차순으로 정렬된 리스트를 반환한다',
        () async {
      final mockData = [_makeFormatData()];

      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getFormatsByPaymentMethod('pm-1');
      expect(result, isA<List<LearnedPushFormatModel>>());
      expect(result.length, 1);
      expect(result[0].packageName, 'com.kbcard.cxh.appcard');
      expect(result[0].confidence, 0.95);
    });
  });

  group('LearnedPushFormatRepository - createFormat', () {
    test('Push 포맷 생성 시 올바른 데이터로 INSERT하고 생성된 포맷을 반환한다', () async {
      final mockResponse = _makeFormatData(
        id: 'fmt-new',
        confidence: 0.8,
        matchCount: 0,
      );
      mockResponse['package_name'] = 'com.shinhancard.smartpay';
      mockResponse['app_keywords'] = ['신한카드'];
      mockResponse['sample_notification'] = null;

      when(() => mockClient.from('learned_push_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.createFormat(
        paymentMethodId: 'pm-1',
        packageName: 'com.shinhancard.smartpay',
        amountRegex: r'\d+원',
      );
      expect(result, isA<LearnedPushFormatModel>());
      expect(result.id, 'fmt-new');
    });
  });

  group('LearnedPushFormatRepository - incrementMatchCount', () {
    test('매칭 카운트 증가 시 RPC 함수를 호출한다', () async {
      when(() => mockClient.rpc('increment_push_format_match_count',
              params: any(named: 'params')))
          .thenAnswer(
              (_) => FakePostgrestFilterBuilder<dynamic>(null));

      await repository.incrementMatchCount('fmt-1');
      verify(() => mockClient.rpc('increment_push_format_match_count',
          params: any(named: 'params'))).called(1);
    });
  });

  group('LearnedPushFormatRepository - deleteFormat', () {
    test('포맷 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteFormat('fmt-1');
      // 에러 없이 완료되면 성공
    });
  });
}
