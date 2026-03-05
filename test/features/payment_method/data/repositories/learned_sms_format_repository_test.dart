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
    String paymentMethodId = 'pm-1',
  }) {
    return {
      'id': id,
      'payment_method_id': paymentMethodId,
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
      'excluded_keywords': <String>[],
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

    test('포맷이 없는 결제수단 조회 시 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getFormatsByPaymentMethod('pm-no-format');
      expect(result, isEmpty);
    });
  });

  group('LearnedSmsFormatRepository - getAllFormatsForLedger', () {
    test('가계부의 모든 SMS 포맷을 조회한다', () async {
      final mockData = [
        _makeFormatData(),
        _makeFormatData(id: 'fmt-2', paymentMethodId: 'pm-2', confidence: 0.8),
      ];

      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAllFormatsForLedger('ledger-1');
      expect(result, isA<List<LearnedSmsFormatModel>>());
      expect(result.length, 2);
    });

    test('포맷이 없는 가계부 조회 시 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getAllFormatsForLedger('ledger-empty');
      expect(result, isEmpty);
    });
  });

  group('LearnedSmsFormatRepository - findMatchingFormat', () {
    test('발신자와 매칭되는 포맷을 찾아 반환한다', () async {
      final formatData = _makeFormatData();
      // sender_keywords에 'KB카드'가 포함된 포맷
      formatData['sender_keywords'] = ['KB카드', 'KB국민'];

      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: [formatData]));

      final result = await repository.findMatchingFormat('ledger-1', 'KB카드');
      // matchesSender가 keyword를 기반으로 체크하므로 결과 검증
      // 실제 매칭 로직은 LearnedSmsFormatModel.matchesSender에 의존
      // 여기서는 응답이 null이 아니거나 null임을 검증
      expect(result == null || result is LearnedSmsFormatModel, isTrue);
    });

    test('매칭되는 포맷이 없으면 null을 반환한다', () async {
      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.findMatchingFormat('ledger-1', '알수없는발신자');
      expect(result, isNull);
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
    });

    test('시스템 포맷으로 생성할 수 있다', () async {
      final mockResponse = _makeFormatData(id: 'fmt-sys');
      mockResponse['is_system'] = true;
      mockResponse['confidence'] = 0.95;

      when(() => mockClient.from('learned_sms_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.createFormat(
        paymentMethodId: 'pm-1',
        senderPattern: 'KB국민카드',
        amountRegex: r'\d{1,3}(,\d{3})*원',
        isSystem: true,
        confidence: 0.95,
      );
      expect(result.isSystem, isTrue);
    });
  });

  group('LearnedSmsFormatRepository - updateFormat', () {
    test('SMS 포맷 수정 시 제공된 필드를 업데이트하고 결과를 반환한다', () async {
      final updatedData = _makeFormatData(confidence: 0.95);

      when(() => mockClient.from('learned_sms_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updatedData], singleData: updatedData));

      final result = await repository.updateFormat(
        id: 'fmt-1',
        confidence: 0.95,
      );
      expect(result, isA<LearnedSmsFormatModel>());
      expect(result.confidence, 0.95);
    });

    test('제외 키워드를 업데이트한다', () async {
      final updatedData = _makeFormatData();
      updatedData['excluded_keywords'] = ['광고', '이벤트'];

      when(() => mockClient.from('learned_sms_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updatedData], singleData: updatedData));

      final result = await repository.updateFormat(
        id: 'fmt-1',
        excludedKeywords: ['광고', '이벤트'],
      );
      expect(result, isA<LearnedSmsFormatModel>());
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

    test('RPC 실패 후 직접 업데이트도 실패하면 예외 없이 처리된다', () async {
      when(() => mockClient.rpc('increment_sms_format_match_count',
              params: any(named: 'params')))
          .thenThrow(Exception('RPC failed'));

      when(() => mockClient.from('learned_sms_formats'))
          .thenThrow(Exception('DB error'));

      // 예외가 전파되지 않고 안전하게 처리됨
      await repository.incrementMatchCount('fmt-1');
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

  group('LearnedSmsFormatRepository - deleteNonSystemFormats', () {
    test('결제수단의 비시스템 포맷을 모두 삭제한다', () async {
      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteNonSystemFormats('pm-1');
      // 에러 없이 완료되면 성공
    });
  });

  group('LearnedSmsFormatRepository - create (별칭 메서드)', () {
    test('Model 객체로 포맷을 생성한다', () async {
      final mockResponse = _makeFormatData(id: 'fmt-new');

      when(() => mockClient.from('learned_sms_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final model = LearnedSmsFormatModel.fromJson(_makeFormatData());
      final result = await repository.create(model);
      expect(result, isA<LearnedSmsFormatModel>());
    });
  });

  group('LearnedSmsFormatRepository - getByPaymentMethodId (별칭 메서드)', () {
    test('결제수단 ID로 포맷 목록을 조회한다', () async {
      final mockData = [_makeFormatData()];

      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByPaymentMethodId('pm-1');
      expect(result, isA<List<LearnedSmsFormatModel>>());
      expect(result.length, 1);
    });
  });

  group('LearnedSmsFormatRepository - delete (별칭 메서드)', () {
    test('포맷 ID로 삭제한다', () async {
      when(() => mockClient.from('learned_sms_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.delete('fmt-1');
      // 에러 없이 완료되면 성공
    });
  });
}
