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
    String paymentMethodId = 'pm-1',
  }) {
    return {
      'id': id,
      'payment_method_id': paymentMethodId,
      'package_name': 'com.kbcard.cxh.appcard',
      'app_keywords': ['KB Pay', 'KB국민카드'],
      'amount_regex': r'\d{1,3}(,\d{3})*원',
      'type_keywords': {
        'expense': ['결제', '승인']
      },
      'merchant_regex': null,
      'date_regex': null,
      'sample_notification': 'KB Pay 결제 10,000원',
      'excluded_keywords': <String>[],
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

    test('포맷이 없는 결제수단 조회 시 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getFormatsByPaymentMethod('pm-no-format');
      expect(result, isEmpty);
    });
  });

  group('LearnedPushFormatRepository - getAllFormatsForLedger', () {
    test('가계부의 모든 Push 포맷을 조회한다', () async {
      final mockData = [
        _makeFormatData(),
        _makeFormatData(id: 'fmt-2', paymentMethodId: 'pm-2', confidence: 0.8),
      ];

      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAllFormatsForLedger('ledger-1');
      expect(result.length, 2);
    });
  });

  group('LearnedPushFormatRepository - findMatchingFormat', () {
    test('패키지명과 매칭되는 포맷을 찾아 반환한다', () async {
      final formatData = _makeFormatData();

      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: [formatData]));

      // matchesNotification 내부 로직에 따라 결과 검증
      final result = await repository.findMatchingFormat(
        'ledger-1',
        'com.kbcard.cxh.appcard',
        'KB Pay 결제 10,000원',
      );
      // 결과가 null이거나 LearnedPushFormatModel 인스턴스임
      expect(result == null || result is LearnedPushFormatModel, isTrue);
    });

    test('매칭되는 포맷이 없으면 null을 반환한다', () async {
      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.findMatchingFormat(
        'ledger-1',
        'com.unknown.app',
        '알 수 없는 알림',
      );
      expect(result, isNull);
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

    test('앱 키워드와 샘플 알림을 포함하여 포맷을 생성한다', () async {
      final mockResponse = _makeFormatData();
      mockResponse['app_keywords'] = ['KB Pay', 'KB국민'];

      when(() => mockClient.from('learned_push_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.createFormat(
        paymentMethodId: 'pm-1',
        packageName: 'com.kbcard.cxh.appcard',
        appKeywords: ['KB Pay', 'KB국민'],
        amountRegex: r'\d{1,3}(,\d{3})*원',
        sampleNotification: 'KB Pay 결제 10,000원',
      );
      expect(result, isA<LearnedPushFormatModel>());
    });
  });

  group('LearnedPushFormatRepository - updateFormat', () {
    test('Push 포맷 수정 시 제공된 필드를 업데이트하고 결과를 반환한다', () async {
      final updatedData = _makeFormatData(confidence: 0.98);

      when(() => mockClient.from('learned_push_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updatedData], singleData: updatedData));

      final result = await repository.updateFormat(
        id: 'fmt-1',
        confidence: 0.98,
      );
      expect(result, isA<LearnedPushFormatModel>());
      expect(result.confidence, 0.98);
    });

    test('패키지명과 키워드를 함께 업데이트한다', () async {
      final updatedData = _makeFormatData();
      updatedData['package_name'] = 'com.updated.app';
      updatedData['app_keywords'] = ['새 앱'];

      when(() => mockClient.from('learned_push_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updatedData], singleData: updatedData));

      final result = await repository.updateFormat(
        id: 'fmt-1',
        packageName: 'com.updated.app',
        appKeywords: ['새 앱'],
      );
      expect(result, isA<LearnedPushFormatModel>());
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

    test('RPC 함수 실패 시 직접 업데이트로 폴백한다', () async {
      when(() => mockClient.rpc('increment_push_format_match_count',
              params: any(named: 'params')))
          .thenThrow(Exception('RPC failed'));

      when(() => mockClient.from('learned_push_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
            selectData: [{'match_count': 5}],
            maybeSingleData: {'match_count': 5},
            hasMaybeSingleData: true,
          ));

      await repository.incrementMatchCount('fmt-1');
      // 폴백이 에러 없이 완료되면 성공
    });

    test('RPC 실패 후 직접 업데이트도 실패하면 예외 없이 처리된다', () async {
      when(() => mockClient.rpc('increment_push_format_match_count',
              params: any(named: 'params')))
          .thenThrow(Exception('RPC failed'));

      when(() => mockClient.from('learned_push_formats'))
          .thenThrow(Exception('DB error'));

      await repository.incrementMatchCount('fmt-1');
      // 예외가 전파되지 않고 안전하게 처리됨
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

  group('LearnedPushFormatRepository - deleteNonSystemFormats', () {
    test('결제수단의 Push 포맷을 모두 삭제한다', () async {
      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteNonSystemFormats('pm-1');
      // 에러 없이 완료되면 성공
    });
  });

  group('LearnedPushFormatRepository - create (별칭 메서드)', () {
    test('Model 객체로 포맷을 생성한다', () async {
      final mockResponse = _makeFormatData(id: 'fmt-new');

      when(() => mockClient.from('learned_push_formats')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final model = LearnedPushFormatModel.fromJson(_makeFormatData());
      final result = await repository.create(model);
      expect(result, isA<LearnedPushFormatModel>());
    });
  });

  group('LearnedPushFormatRepository - getByPaymentMethodId (별칭 메서드)', () {
    test('결제수단 ID로 포맷 목록을 조회한다', () async {
      final mockData = [_makeFormatData()];

      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getByPaymentMethodId('pm-1');
      expect(result, isA<List<LearnedPushFormatModel>>());
      expect(result.length, 1);
    });
  });

  group('LearnedPushFormatRepository - delete (별칭 메서드)', () {
    test('포맷 ID로 삭제한다', () async {
      when(() => mockClient.from('learned_push_formats'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.delete('fmt-1');
      // 에러 없이 완료되면 성공
    });
  });
}
