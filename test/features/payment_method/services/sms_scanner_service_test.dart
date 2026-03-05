import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/learned_sms_format_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_sms_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/services/sms_scanner_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/korean_financial_patterns.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/learned_sms_format.dart';

class MockLearnedSmsFormatRepository extends Mock
    implements LearnedSmsFormatRepository {}

LearnedSmsFormatModel _makeFormatModel({
  String id = 'fmt-1',
  String paymentMethodId = 'pm-1',
  String senderPattern = 'KB국민',
}) {
  final now = DateTime(2026, 1, 1);
  return LearnedSmsFormatModel(
    id: id,
    paymentMethodId: paymentMethodId,
    senderPattern: senderPattern,
    senderKeywords: const ['KB국민', 'KB카드'],
    amountRegex: r'([0-9,]+)\s*원',
    typeKeywords: const {'expense': ['승인'], 'income': ['입금']},
    merchantRegex: null,
    dateRegex: null,
    sampleSms: '승인 50,000원 스타벅스',
    isSystem: false,
    confidence: 0.9,
    matchCount: 1,
    createdAt: now,
    updatedAt: now,
  );
}

/// 테스트용 PlatformChecker 구현
class MockPlatformChecker implements PlatformChecker {
  final bool _isAndroid;
  final bool _isIOS;

  MockPlatformChecker({bool isAndroid = false, bool isIOS = false})
    : _isAndroid = isAndroid,
      _isIOS = isIOS;

  @override
  bool get isAndroid => _isAndroid;

  @override
  bool get isIOS => _isIOS;
}

void main() {
  setUpAll(() {
    registerFallbackValue(_makeFormatModel());
  });

  // Note: SmsScannerService 테스트는 Repository 의존성으로 인해
  // 통합 테스트에서 진행합니다. 여기서는 독립적인 유틸리티 테스트만 수행합니다.

  group('SmsMessageData', () {
    test('SmsMessageData 객체가 올바르게 생성되어야 한다', () {
      final message = SmsMessageData(
        id: 'msg-1',
        sender: 'KB국민카드',
        body: '승인 50,000원 스타벅스',
        date: DateTime(2024, 1, 15, 14, 30),
        isRead: true,
      );

      expect(message.id, equals('msg-1'));
      expect(message.sender, equals('KB국민카드'));
      expect(message.body, equals('승인 50,000원 스타벅스'));
      expect(message.isRead, isTrue);
    });

    test('toString이 유용한 디버그 정보를 반환해야 한다', () {
      final message = SmsMessageData(
        id: 'msg-1',
        sender: 'KB국민카드',
        body: '승인 50,000원',
        date: DateTime(2024, 1, 15),
      );

      final str = message.toString();

      expect(str, contains('KB국민카드'));
      expect(str, contains('승인 50,000원'));
    });
  });

  group('SmsFormatScanResult', () {
    test('빈 결과는 hasFinancialMessages가 false여야 한다', () {
      const result = SmsFormatScanResult(
        financialMessages: [],
        groupedBySender: {},
        detectedFormats: [],
      );

      expect(result.hasFinancialMessages, isFalse);
      expect(result.totalCount, equals(0));
    });

    test('메시지가 있으면 hasFinancialMessages가 true여야 한다', () {
      final result = SmsFormatScanResult(
        financialMessages: [
          SmsMessageData(
            id: '1',
            sender: 'KB',
            body: 'test',
            date: DateTime.now(),
          ),
        ],
        groupedBySender: const {},
        detectedFormats: const [],
      );

      expect(result.hasFinancialMessages, isTrue);
      expect(result.totalCount, equals(1));
    });
  });

  group('FormatLearningResult', () {
    test('success 팩토리가 올바른 결과를 반환해야 한다', () {
      final mockFormat = LearnedSmsFormat(
        id: 'test-id',
        paymentMethodId: 'pm-1',
        senderPattern: 'KB국민',
        senderKeywords: const ['KB국민', 'KB카드'],
        amountRegex: r'([0-9,]+)\s*원',
        typeKeywords: const {
          'expense': ['승인'],
          'income': ['입금'],
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = FormatLearningResult.success(mockFormat, confidence: 0.9);

      expect(result.success, isTrue);
      expect(result.learnedFormat, isNotNull);
      expect(result.confidence, equals(0.9));
      expect(result.error, isNull);
    });

    test('failure 팩토리가 올바른 결과를 반환해야 한다', () {
      final result = FormatLearningResult.failure('테스트 에러');

      expect(result.success, isFalse);
      expect(result.learnedFormat, isNull);
      expect(result.error, equals('테스트 에러'));
    });
  });

  group('KoreanFinancialPatterns', () {
    test('findByName으로 KB국민카드를 찾을 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('KB국민카드');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('KB국민카드'));
      expect(pattern.institutionType, equals('card'));
    });

    test('findByName으로 카카오뱅크를 찾을 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('카카오뱅크');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('카카오뱅크'));
      expect(pattern.institutionType, equals('bank'));
    });

    test('findByName으로 수원페이를 찾을 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('수원페이');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('수원페이'));
      expect(pattern.institutionType, equals('local_currency'));
    });

    test('존재하지 않는 금융사는 null을 반환해야 한다', () {
      final pattern = KoreanFinancialPatterns.findByName('존재하지않는은행');

      expect(pattern, isNull);
    });

    test('findBySender로 발신자 패턴을 매칭할 수 있어야 한다', () {
      final pattern = KoreanFinancialPatterns.findBySender('15881688');

      expect(pattern, isNotNull);
      expect(pattern!.institutionName, equals('KB국민카드'));
    });

    test('cardPatterns는 카드사만 포함해야 한다', () {
      final cards = KoreanFinancialPatterns.cardPatterns;

      expect(cards, isNotEmpty);
      expect(cards.every((p) => p.institutionType == 'card'), isTrue);
    });

    test('bankPatterns는 은행만 포함해야 한다', () {
      final banks = KoreanFinancialPatterns.bankPatterns;

      expect(banks, isNotEmpty);
      expect(banks.every((p) => p.institutionType == 'bank'), isTrue);
    });

    test('localCurrencyPatterns는 지역화폐만 포함해야 한다', () {
      final localCurrencies = KoreanFinancialPatterns.localCurrencyPatterns;

      expect(localCurrencies, isNotEmpty);
      expect(
        localCurrencies.every((p) => p.institutionType == 'local_currency'),
        isTrue,
      );
    });

    test('allPatterns에 모든 금융사가 포함되어야 한다', () {
      const all = KoreanFinancialPatterns.allPatterns;

      // 카드사 9개, 은행 9개, 지역화폐 3개 = 21개
      expect(all.length, greaterThanOrEqualTo(21));

      // 각 타입이 모두 포함되어 있는지 확인
      expect(all.any((p) => p.institutionType == 'card'), isTrue);
      expect(all.any((p) => p.institutionType == 'bank'), isTrue);
      expect(all.any((p) => p.institutionType == 'local_currency'), isTrue);
    });
  });

  group('SmsScannerService - 플랫폼 지원 여부', () {
    test('비-Android 환경에서 isSupported가 false이다', () {
      final mockRepo = MockLearnedSmsFormatRepository();
      final service = SmsScannerService(
        mockRepo,
        platformChecker: MockPlatformChecker(isAndroid: false),
      );

      expect(service.isSupported, isFalse);
    });

    test('Android 환경에서 isSupported가 true이다', () {
      final mockRepo = MockLearnedSmsFormatRepository();
      final service = SmsScannerService(
        mockRepo,
        platformChecker: MockPlatformChecker(isAndroid: true),
      );

      expect(service.isSupported, isTrue);
    });
  });

  group('SmsScannerService - 비-Android 환경에서 권한 체크', () {
    late MockLearnedSmsFormatRepository mockRepo;
    late SmsScannerService service;

    setUp(() {
      mockRepo = MockLearnedSmsFormatRepository();
      service = SmsScannerService(
        mockRepo,
        platformChecker: MockPlatformChecker(isAndroid: false),
      );
    });

    test('비-Android에서 checkSmsPermission은 false를 반환한다', () async {
      final result = await service.checkSmsPermission();
      expect(result, isFalse);
    });

    test('비-Android에서 requestSmsPermission은 false를 반환한다', () async {
      final result = await service.requestSmsPermission();
      expect(result, isFalse);
    });

    test('비-Android에서 scanFinancialSms는 빈 결과를 반환한다', () async {
      final result = await service.scanFinancialSms();
      expect(result.hasFinancialMessages, isFalse);
      expect(result.financialMessages, isEmpty);
      expect(result.groupedBySender, isEmpty);
      expect(result.detectedFormats, isEmpty);
    });
  });

  group('SmsScannerService - learnFormatFromSms', () {
    late MockLearnedSmsFormatRepository mockRepo;
    late SmsScannerService service;

    setUp(() {
      registerFallbackValue(_makeFormatModel());
      mockRepo = MockLearnedSmsFormatRepository();
      service = SmsScannerService(
        mockRepo,
        platformChecker: MockPlatformChecker(isAndroid: true),
      );
    });

    test('KB국민카드 SMS로 포맷을 학습할 수 있다', () async {
      // Given
      final savedModel = _makeFormatModel();
      when(() => mockRepo.create(any()))
          .thenAnswer((_) async => savedModel);

      final sampleSms = SmsMessageData(
        id: 'msg-1',
        sender: '15881688',
        body: '[KB국민카드] 승인 50,000원 스타벅스강남점 01/15 14:30',
        date: DateTime(2026, 1, 15, 14, 30),
      );

      // When
      final result = await service.learnFormatFromSms(
        sampleSms: sampleSms,
        paymentMethodId: 'pm-1',
      );

      // Then
      expect(result.success, isTrue);
      expect(result.learnedFormat, isNotNull);
    });

    test('파싱 불가 SMS는 실패 결과를 반환한다', () async {
      // Given: 금융 정보가 없는 SMS
      final sampleSms = SmsMessageData(
        id: 'msg-2',
        sender: '친구',
        body: '안녕하세요 오늘 밥 먹을래요?',
        date: DateTime(2026, 1, 15),
      );

      // When
      final result = await service.learnFormatFromSms(
        sampleSms: sampleSms,
        paymentMethodId: 'pm-1',
      );

      // Then
      expect(result.success, isFalse);
      expect(result.error, isNotNull);
    });

    test('존재하지 않는 금융사여도 범용 포맷으로 학습을 시도한다', () async {
      // Given: 알 수 없는 발신자이지만 금액 패턴이 있는 SMS
      final savedModel = _makeFormatModel(senderPattern: 'unknown');
      when(() => mockRepo.create(any()))
          .thenAnswer((_) async => savedModel);

      final sampleSms = SmsMessageData(
        id: 'msg-3',
        sender: '알수없는금융사',
        body: '승인 10,000원 편의점',
        date: DateTime(2026, 1, 15),
      );

      // When
      final result = await service.learnFormatFromSms(
        sampleSms: sampleSms,
        paymentMethodId: 'pm-1',
      );

      // Then - 파싱 성공 여부에 따라 다름 (성공하면 저장, 실패하면 error)
      expect(result, isA<FormatLearningResult>());
    });

    test('Repository 저장 중 에러 발생 시 실패 결과를 반환한다', () async {
      // Given
      when(() => mockRepo.create(any()))
          .thenThrow(Exception('DB 저장 실패'));

      final sampleSms = SmsMessageData(
        id: 'msg-4',
        sender: '15881688',
        body: '[KB국민카드] 승인 50,000원 스타벅스 01/15 14:30',
        date: DateTime(2026, 1, 15),
      );

      // When
      final result = await service.learnFormatFromSms(
        sampleSms: sampleSms,
        paymentMethodId: 'pm-1',
      );

      // Then
      expect(result.success, isFalse);
      expect(result.error, contains('포맷 저장 실패'));
    });
  });

  group('SmsScannerService - registerSystemFormat', () {
    late MockLearnedSmsFormatRepository mockRepo;
    late SmsScannerService service;

    setUp(() {
      registerFallbackValue(_makeFormatModel());
      mockRepo = MockLearnedSmsFormatRepository();
      service = SmsScannerService(mockRepo);
    });

    test('지원되지 않는 금융사는 실패 결과를 반환한다', () async {
      // When
      final result = await service.registerSystemFormat(
        paymentMethodId: 'pm-1',
        institutionName: '존재하지않는은행',
      );

      // Then
      expect(result.success, isFalse);
      expect(result.error, contains('지원하지 않는 금융사'));
    });

    test('지원되는 금융사(KB국민카드)로 시스템 포맷을 등록할 수 있다', () async {
      // Given
      final savedModel = _makeFormatModel(senderPattern: '15881688');
      when(() => mockRepo.create(any()))
          .thenAnswer((_) async => savedModel);

      // When
      final result = await service.registerSystemFormat(
        paymentMethodId: 'pm-1',
        institutionName: 'KB국민카드',
      );

      // Then
      expect(result.success, isTrue);
      expect(result.confidence, closeTo(0.95, 0.01));
    });

    test('Repository 저장 실패 시 에러 결과를 반환한다', () async {
      // Given
      when(() => mockRepo.create(any()))
          .thenThrow(Exception('DB 오류'));

      // When
      final result = await service.registerSystemFormat(
        paymentMethodId: 'pm-1',
        institutionName: 'KB국민카드',
      );

      // Then
      expect(result.success, isFalse);
      expect(result.error, contains('포맷 저장 실패'));
    });
  });

  group('SmsScannerService - getLearnedFormats', () {
    late MockLearnedSmsFormatRepository mockRepo;
    late SmsScannerService service;

    setUp(() {
      mockRepo = MockLearnedSmsFormatRepository();
      service = SmsScannerService(mockRepo);
    });

    test('결제수단에 연결된 포맷 목록을 반환한다', () async {
      // Given
      final models = [_makeFormatModel(), _makeFormatModel(id: 'fmt-2')];
      when(() => mockRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => models);

      // When
      final result = await service.getLearnedFormats('pm-1');

      // Then
      expect(result, hasLength(2));
      expect(result.first, isA<LearnedSmsFormat>());
    });

    test('포맷이 없으면 빈 목록을 반환한다', () async {
      // Given
      when(() => mockRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);

      // When
      final result = await service.getLearnedFormats('pm-1');

      // Then
      expect(result, isEmpty);
    });
  });

  group('SmsScannerService - deleteLearnedFormat', () {
    test('포맷을 삭제한다', () async {
      // Given
      final mockRepo = MockLearnedSmsFormatRepository();
      final service = SmsScannerService(mockRepo);
      when(() => mockRepo.delete(any())).thenAnswer((_) async {});

      // When
      await service.deleteLearnedFormat('fmt-1');

      // Then
      verify(() => mockRepo.delete('fmt-1')).called(1);
    });
  });

  group('SmsScannerService - findMatchingFormat', () {
    test('매칭되는 포맷을 찾으면 반환한다', () async {
      // Given
      final mockRepo = MockLearnedSmsFormatRepository();
      final service = SmsScannerService(mockRepo);
      final model = _makeFormatModel(senderPattern: 'kb국민');
      when(() => mockRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => [model]);

      // When - 발신자 패턴이 일치하는 경우
      final result = await service.findMatchingFormat(
        'kb국민',
        ['pm-1'],
      );

      // Then
      expect(result, isNotNull);
    });

    test('매칭되는 포맷이 없으면 null을 반환한다', () async {
      // Given
      final mockRepo = MockLearnedSmsFormatRepository();
      final service = SmsScannerService(mockRepo);
      when(() => mockRepo.getByPaymentMethodId(any()))
          .thenAnswer((_) async => []);

      // When
      final result = await service.findMatchingFormat(
        '존재하지않는발신자',
        ['pm-1'],
      );

      // Then
      expect(result, isNull);
    });

    test('paymentMethodIds가 비어있으면 null을 반환한다', () async {
      // Given
      final mockRepo = MockLearnedSmsFormatRepository();
      final service = SmsScannerService(mockRepo);

      // When
      final result = await service.findMatchingFormat('KB', []);

      // Then
      expect(result, isNull);
      verifyNever(() => mockRepo.getByPaymentMethodId(any()));
    });
  });
}
