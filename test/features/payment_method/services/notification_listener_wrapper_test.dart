import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:notification_listener_service/notification_event.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/payment_method/data/models/learned_push_format_model.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_push_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/payment_method/data/services/category_mapping_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/duplicate_check_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/notification_listener_wrapper.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';

// Mock 클래스 정의
class MockPaymentMethodRepository extends Mock
    implements PaymentMethodRepository {}

class MockPendingTransactionRepository extends Mock
    implements PendingTransactionRepository {}

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockLearnedPushFormatRepository extends Mock
    implements LearnedPushFormatRepository {}

class MockCategoryMappingService extends Mock
    implements CategoryMappingService {}

class MockDuplicateCheckService extends Mock implements DuplicateCheckService {}

class MockNotificationService extends Mock implements NotificationService {}

/// NotificationListenerWrapper 통합 단위 테스트
///
/// mocktail을 사용하여 Repository/Service를 mock한 후
/// 전체 흐름을 검증한다.
///
/// 주요 테스트 대상:
/// - _isFinancialApp: 패키지명 기반 금융 앱 판별
/// - isFinancialAlimtalk: 카카오톡 알림톡 3중 검증
/// - forTesting 팩토리를 통한 의존성 주입
void main() {
  late MockPaymentMethodRepository mockPaymentMethodRepo;
  late MockPendingTransactionRepository mockPendingTxRepo;
  late MockTransactionRepository mockTransactionRepo;
  late MockLearnedPushFormatRepository mockLearnedPushFormatRepo;
  late MockCategoryMappingService mockCategoryMappingService;
  late MockDuplicateCheckService mockDuplicateCheckService;
  late MockNotificationService mockNotificationService;

  setUp(() {
    mockPaymentMethodRepo = MockPaymentMethodRepository();
    mockPendingTxRepo = MockPendingTransactionRepository();
    mockTransactionRepo = MockTransactionRepository();
    mockLearnedPushFormatRepo = MockLearnedPushFormatRepository();
    mockCategoryMappingService = MockCategoryMappingService();
    mockDuplicateCheckService = MockDuplicateCheckService();
    mockNotificationService = MockNotificationService();
  });

  group('forTesting 팩토리 생성자', () {
    test('forTesting으로 인스턴스를 생성할 수 있어야 한다', () {
      final wrapper = NotificationListenerWrapper.forTesting(
        paymentMethodRepository: mockPaymentMethodRepo,
        pendingTransactionRepository: mockPendingTxRepo,
        transactionRepository: mockTransactionRepo,
        learnedPushFormatRepository: mockLearnedPushFormatRepo,
        categoryMappingService: mockCategoryMappingService,
        duplicateCheckService: mockDuplicateCheckService,
        notificationService: mockNotificationService,
      );

      expect(wrapper, isNotNull);
      // 초기 상태 검증 - 초기화 전이므로 false
      expect(wrapper.isInitialized, isFalse);
      expect(wrapper.isListening, isFalse);
    });
  });

  group('isFinancialAppForTesting', () {
    test('KB Pay 패키지를 금융 앱으로 인식해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.kbcard.cxh.appcard',
        ),
        isTrue,
      );
    });

    test('신한카드를 금융 앱으로 인식해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.shcard.smartpay',
        ),
        isTrue,
      );
    });

    test('삼성페이를 금융 앱으로 인식해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.samsung.android.spay',
        ),
        isTrue,
      );
    });

    test('카카오톡은 금융 앱 목록에 포함되어야 한다 (알림톡 수집)', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting('com.kakao.talk'),
        isTrue,
        reason: '카카오톡 알림톡의 금융 알림을 수집하기 위해 포함',
      );
    });

    test('비금융 앱은 차단해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.example.random.app',
        ),
        isFalse,
      );
    });

    test('빈 패키지명은 차단해야 한다', () {
      expect(NotificationListenerWrapper.isFinancialAppForTesting(''), isFalse);
    });

    test('대소문자를 무시하고 매칭해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'COM.KBCARD.CXH.APPCARD',
        ),
        isTrue,
        reason: '패키지명은 대소문자 무관하게 매칭되어야 한다',
      );
    });
  });

  group('isFinancialAlimtalkForTesting - 3중 검증', () {
    test('3중 조건 모두 충족 시 true를 반환해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAlimtalkForTesting(
          'KB국민카드',
          '50,000원 승인 스타벅스',
        ),
        isTrue,
      );
    });

    test('금융 채널이 아닌 title은 false를 반환해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAlimtalkForTesting(
          '홍길동',
          '50,000원 승인 스타벅스',
        ),
        isFalse,
      );
    });

    test('거래 키워드가 없는 content는 false를 반환해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAlimtalkForTesting(
          'KB국민카드',
          '이벤트 안내 10,000원 혜택',
        ),
        isFalse,
      );
    });

    test('금액 패턴이 없는 content는 false를 반환해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAlimtalkForTesting(
          'KB국민카드',
          '승인 완료 스타벅스',
        ),
        isFalse,
      );
    });

    test('빈 title은 false를 반환해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAlimtalkForTesting(
          '',
          '50,000원 승인',
        ),
        isFalse,
      );
    });

    test('빈 content는 false를 반환해야 한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAlimtalkForTesting('KB국민카드', ''),
        isFalse,
      );
    });
  });

  group('금융 앱 패키지 커버리지', () {
    final financialPackages = [
      'com.kbcard.cxh.appcard', // KB Pay
      'com.kbstar.kbbank', // KB국민은행
      'com.shcard.smartpay', // 신한 SOL페이
      'com.shinhan.sbanking', // 신한은행
      'kr.co.samsungcard.mpocket', // 삼성카드
      'com.samsung.android.spay', // 삼성페이
      'com.hyundaicard.appcard', // 현대카드
      'com.lcacapp', // 롯데카드
      'com.kakaopay.app', // 카카오페이
      'viva.republica.toss', // 토스
      'gov.gyeonggi.ggcard', // 경기지역화폐
      'com.kakao.talk', // 카카오톡 (알림톡)
    ];

    for (final pkg in financialPackages) {
      test('$pkg 를 금융 앱으로 인식해야 한다', () {
        expect(
          NotificationListenerWrapper.isFinancialAppForTesting(pkg),
          isTrue,
          reason: '$pkg가 금융 앱 패키지 목록에 포함되어 있어야 한다',
        );
      });
    }
  });

  group('금융 채널 키워드 커버리지', () {
    final channelTestCases = [
      ('KB국민카드', '50,000원 승인'),
      ('신한카드', '30,000원 결제'),
      ('삼성카드', '20,000원 승인'),
      ('현대카드', '15,000원 승인'),
      ('롯데카드', '10,000원 결제'),
      ('우리카드', '25,000원 승인'),
      ('하나카드', '40,000원 승인'),
      ('카카오뱅크', '100,000원 이체'),
      ('토스뱅크', '50,000원 입금'),
      ('카카오페이', '5,000원 충전'),
      ('네이버페이', '8,000원 결제'),
    ];

    for (final (channel, content) in channelTestCases) {
      test('$channel 채널을 금융 채널로 인식해야 한다', () {
        expect(
          NotificationListenerWrapper.isFinancialAlimtalkForTesting(
            channel,
            content,
          ),
          isTrue,
          reason: '$channel은 금융 채널 키워드에 포함되어야 한다',
        );
      });
    }
  });

  group('processManualNotification - 카테고리 매핑 흐름 검증', () {
    late NotificationListenerWrapper wrapper;

    // 테스트용 공통 픽스처
    const testPackageName = 'com.kbcard.cxh.appcard';
    const testTitle = 'KB Pay';
    // 파싱 성공을 위해 금액 패턴과 거래 키워드가 반드시 포함되어야 함
    // amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원' 에 매칭되는 '15,000원'
    // typeKeywords expense: ['승인', '결제'] 에 매칭되는 '승인'
    // appKeywords: ['KB Pay'] 에 매칭되는 'KB Pay'
    const testContent = 'KB Pay 승인 15,000원 스타벅스';

    /// 테스트용 PaymentMethod 생성 헬퍼
    PaymentMethodModel buildPaymentMethod({String? defaultCategoryId}) {
      return PaymentMethodModel(
        id: 'pm-1',
        ledgerId: 'ledger-1',
        ownerUserId: 'user-1',
        name: 'KB Pay',
        icon: 'credit_card',
        color: '#FF0000',
        isDefault: false,
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
        autoSaveMode: AutoSaveMode.suggest,
        canAutoSave: true,
        autoCollectSource: AutoCollectSource.push,
        defaultCategoryId: defaultCategoryId,
      );
    }

    /// 테스트용 LearnedPushFormatModel 생성 헬퍼
    LearnedPushFormatModel buildFormat() {
      return LearnedPushFormatModel(
        id: 'format-1',
        paymentMethodId: 'pm-1',
        packageName: testPackageName,
        appKeywords: const ['KB Pay'],
        amountRegex: r'(\d{1,3}(,\d{3})*|\d+)원',
        typeKeywords: const {
          'expense': ['승인', '결제'],
          'income': ['입금'],
        },
        merchantRegex: null,
        confidence: 0.9,
        matchCount: 10,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    /// 테스트용 PendingTransactionModel 반환값 생성 헬퍼
    PendingTransactionModel buildPendingTx({String? parsedCategoryId}) {
      final now = DateTime(2026, 1, 1);
      return PendingTransactionModel(
        id: 'pending-1',
        ledgerId: 'ledger-1',
        paymentMethodId: 'pm-1',
        userId: 'user-1',
        sourceType: SourceType.notification,
        sourceContent: '$testTitle $testContent',
        sourceTimestamp: now,
        status: PendingTransactionStatus.pending,
        createdAt: now,
        updatedAt: now,
        expiresAt: now.add(const Duration(days: 7)),
        parsedCategoryId: parsedCategoryId,
      );
    }

    setUp(() {
      wrapper = NotificationListenerWrapper.forTesting(
        paymentMethodRepository: mockPaymentMethodRepo,
        pendingTransactionRepository: mockPendingTxRepo,
        transactionRepository: mockTransactionRepo,
        learnedPushFormatRepository: mockLearnedPushFormatRepo,
        categoryMappingService: mockCategoryMappingService,
        duplicateCheckService: mockDuplicateCheckService,
        notificationService: mockNotificationService,
      );

      // registerFallbackValue: mocktail의 any()가 열거형/커스텀 타입 매칭을 위해 필요
      registerFallbackValue(SourceType.notification);
      registerFallbackValue(PendingTransactionStatus.pending);
      registerFallbackValue(DateTime(2026));
      registerFallbackValue(NotificationType.autoCollectSuggested);
    });

    /// 공통 mock stub 설정 헬퍼
    void setupCommonStubs({
      String? categoryIdFromKeyword,
      String? categoryIdFromMerchant,
      String? pendingTxCategoryId,
    }) {
      // DuplicateCheckService: 항상 중복 없음으로 응답
      when(() => mockDuplicateCheckService.checkDuplicate(
        amount: any(named: 'amount'),
        paymentMethodId: any(named: 'paymentMethodId'),
        ledgerId: any(named: 'ledgerId'),
        timestamp: any(named: 'timestamp'),
      )).thenAnswer((_) async => DuplicateCheckResult.notDuplicate('hash-123'));

      // PendingTransactionRepository.createPendingTransaction: 성공 응답
      when(() => mockPendingTxRepo.createPendingTransaction(
        ledgerId: any(named: 'ledgerId'),
        paymentMethodId: any(named: 'paymentMethodId'),
        userId: any(named: 'userId'),
        sourceType: any(named: 'sourceType'),
        sourceSender: any(named: 'sourceSender'),
        sourceContent: any(named: 'sourceContent'),
        sourceTimestamp: any(named: 'sourceTimestamp'),
        parsedAmount: any(named: 'parsedAmount'),
        parsedType: any(named: 'parsedType'),
        parsedMerchant: any(named: 'parsedMerchant'),
        parsedCategoryId: any(named: 'parsedCategoryId'),
        parsedDate: any(named: 'parsedDate'),
        duplicateHash: any(named: 'duplicateHash'),
        isDuplicate: any(named: 'isDuplicate'),
        status: any(named: 'status'),
        isViewed: any(named: 'isViewed'),
      )).thenAnswer((_) async => buildPendingTx(
        parsedCategoryId: pendingTxCategoryId,
      ));

      // LearnedPushFormatRepository.incrementMatchCount: 성공 응답
      when(() => mockLearnedPushFormatRepo.incrementMatchCount(any()))
          .thenAnswer((_) async {});

      // CategoryMappingService.findCategoryByKeywordMapping: 기본값 null
      when(() => mockCategoryMappingService.findCategoryByKeywordMapping(
        any(),
        any(),
        any(),
        any(),
      )).thenAnswer((_) async => categoryIdFromKeyword);

      // CategoryMappingService.findCategoryId: 기본값 null
      when(() => mockCategoryMappingService.findCategoryId(
        any(),
        any(),
        useCache: any(named: 'useCache'),
      )).thenAnswer((_) async => categoryIdFromMerchant);

      // NotificationService.sendAutoCollectNotification: 성공 응답
      when(() => mockNotificationService.sendAutoCollectNotification(
        userId: any(named: 'userId'),
        type: any(named: 'type'),
        title: any(named: 'title'),
        body: any(named: 'body'),
        data: any(named: 'data'),
      )).thenAnswer((_) async {});
    }

    test(
      'defaultCategoryId가 null인 결제수단으로 알림 처리 시 findCategoryByKeywordMapping이 호출되어야 한다',
      () async {
        // Given: defaultCategoryId가 없는 결제수단과 포맷 설정
        final pm = buildPaymentMethod(defaultCategoryId: null);
        final format = buildFormat();

        wrapper.initializeForTesting(
          userId: 'user-1',
          ledgerId: 'ledger-1',
          autoSavePaymentMethods: [pm],
          learnedFormatsCache: {'pm-1': [format]},
        );

        setupCommonStubs(categoryIdFromKeyword: 'food-category-id');

        // When: 실제 processManualNotification 호출
        await wrapper.processManualNotification(
          packageName: testPackageName,
          title: testTitle,
          content: testContent,
        );

        // Then: findCategoryByKeywordMapping이 'notification' sourceType으로 1회 호출되어야 한다
        verify(() => mockCategoryMappingService.findCategoryByKeywordMapping(
          any(),
          'pm-1',
          'notification',
          'ledger-1',
        )).called(1);
      },
    );

    test(
      'defaultCategoryId가 설정된 결제수단으로 알림 처리 시 findCategoryByKeywordMapping을 건너뛰어야 한다',
      () async {
        // Given: defaultCategoryId가 있는 결제수단과 포맷 설정
        final pm = buildPaymentMethod(defaultCategoryId: 'default-cat-id');
        final format = buildFormat();

        wrapper.initializeForTesting(
          userId: 'user-1',
          ledgerId: 'ledger-1',
          autoSavePaymentMethods: [pm],
          learnedFormatsCache: {'pm-1': [format]},
        );

        setupCommonStubs();

        // When: 실제 processManualNotification 호출
        await wrapper.processManualNotification(
          packageName: testPackageName,
          title: testTitle,
          content: testContent,
        );

        // Then: defaultCategoryId가 있으므로 키워드 매핑은 호출되지 않아야 한다
        verifyNever(() => mockCategoryMappingService.findCategoryByKeywordMapping(
          any(),
          any(),
          any(),
          any(),
        ));
      },
    );

    test(
      '키워드 매핑 성공 시 parsedCategoryId가 해당 카테고리 ID로 pending transaction을 생성해야 한다',
      () async {
        // Given: defaultCategoryId가 없고 키워드 매핑이 'food-category-id'를 반환하도록 설정
        final pm = buildPaymentMethod(defaultCategoryId: null);
        final format = buildFormat();

        wrapper.initializeForTesting(
          userId: 'user-1',
          ledgerId: 'ledger-1',
          autoSavePaymentMethods: [pm],
          learnedFormatsCache: {'pm-1': [format]},
        );

        setupCommonStubs(
          categoryIdFromKeyword: 'food-category-id',
          pendingTxCategoryId: 'food-category-id',
        );

        // When: 실제 processManualNotification 호출
        await wrapper.processManualNotification(
          packageName: testPackageName,
          title: testTitle,
          content: testContent,
        );

        // Then: createPendingTransaction이 parsedCategoryId: 'food-category-id'로 호출되어야 한다
        // parsedCategoryId named 파라미터만 captureAny로 캡처하여 정확히 검증
        final captured = verify(() => mockPendingTxRepo.createPendingTransaction(
          ledgerId: any(named: 'ledgerId'),
          paymentMethodId: any(named: 'paymentMethodId'),
          userId: any(named: 'userId'),
          sourceType: any(named: 'sourceType'),
          sourceSender: any(named: 'sourceSender'),
          sourceContent: any(named: 'sourceContent'),
          sourceTimestamp: any(named: 'sourceTimestamp'),
          parsedAmount: any(named: 'parsedAmount'),
          parsedType: any(named: 'parsedType'),
          parsedMerchant: any(named: 'parsedMerchant'),
          parsedCategoryId: captureAny(named: 'parsedCategoryId'),
          parsedDate: any(named: 'parsedDate'),
          duplicateHash: any(named: 'duplicateHash'),
          isDuplicate: any(named: 'isDuplicate'),
          status: any(named: 'status'),
          isViewed: any(named: 'isViewed'),
        )).captured;

        // parsedCategoryId만 캡처했으므로 인덱스 0이 해당 값
        expect(captured[0], equals('food-category-id'));
      },
    );

    test(
      '키워드 매핑이 null을 반환하면 findCategoryId가 상호명 기반 fallback으로 호출되어야 한다',
      () async {
        // Given: 키워드 매핑은 null, 상호명 매핑은 'merchant-category-id' 반환
        final pm = buildPaymentMethod(defaultCategoryId: null);
        final format = buildFormat();

        wrapper.initializeForTesting(
          userId: 'user-1',
          ledgerId: 'ledger-1',
          autoSavePaymentMethods: [pm],
          learnedFormatsCache: {'pm-1': [format]},
        );

        setupCommonStubs(
          categoryIdFromKeyword: null,
          categoryIdFromMerchant: 'merchant-category-id',
        );

        // When: 실제 processManualNotification 호출
        await wrapper.processManualNotification(
          packageName: testPackageName,
          title: testTitle,
          content: testContent,
        );

        // Then: findCategoryId(상호명 기반 매핑)가 1회 호출되어야 한다
        verify(() => mockCategoryMappingService.findCategoryId(
          any(),
          any(),
        )).called(1);
      },
    );
  });

  group('onNotificationReceived - 분기 처리', () {
    late NotificationListenerWrapper wrapper;

    setUp(() {
      wrapper = NotificationListenerWrapper.forTesting(
        paymentMethodRepository: mockPaymentMethodRepo,
        pendingTransactionRepository: mockPendingTxRepo,
        transactionRepository: mockTransactionRepo,
        learnedPushFormatRepository: mockLearnedPushFormatRepo,
        categoryMappingService: mockCategoryMappingService,
        duplicateCheckService: mockDuplicateCheckService,
        notificationService: mockNotificationService,
      );
    });

    ServiceNotificationEvent _makeEvent({
      String? packageName,
      String? title,
      String? content,
      bool? hasRemoved,
    }) {
      return ServiceNotificationEvent(
        packageName: packageName,
        title: title,
        content: content,
        hasRemoved: hasRemoved,
      );
    }

    test('userId가 null이면 아무것도 처리하지 않는다', () async {
      // Given: 초기화 안 된 상태 (userId=null)
      final event = _makeEvent(
        packageName: 'com.kbcard.cxh.appcard',
        content: '승인 50,000원',
      );

      // When: 알림 수신
      await wrapper.onNotificationReceived(event);

      // Then: pendingTransaction 생성이 호출되지 않아야 한다
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('hasRemoved=true이면 처리를 건너뛴다', () async {
      // Given: 초기화된 wrapper
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.kbcard.cxh.appcard',
        content: '승인 50,000원',
        hasRemoved: true,
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then: 처리 없이 종료
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('packageName이 비어있으면 처리를 건너뛴다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: '',
        content: '승인 50,000원',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('content가 비어있으면 처리를 건너뛴다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.kbcard.cxh.appcard',
        content: '',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('SMS 앱(com.android.mms) 알림은 처리를 건너뛴다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.android.mms',
        content: '승인 50,000원',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then: SMS 앱은 Kotlin이 처리하므로 Dart에서 건너뜀
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('비금융 앱 알림은 처리를 건너뛴다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.example.randomapp',
        content: '새 메시지가 있습니다',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('카카오톡이지만 금융 알림톡이 아니면 처리를 건너뛴다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.kakao.talk',
        title: '홍길동',
        content: '오늘 저녁 뭐 먹을까요?',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then: 일반 카카오 메시지는 건너뜀
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('금융 앱에서 autoSave 결제수단 없이 알림이 오면 매칭 없이 종료된다', () async {
      // Given: 결제수단 없음
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.kbcard.cxh.appcard',
        title: 'KB국민카드',
        content: '승인 50,000원 스타벅스',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then: 매칭 결제수단 없으므로 pending transaction 미생성
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('자기 앱 패키지 알림은 처리를 건너뛴다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      final event = _makeEvent(
        packageName: 'com.household.shared.shared_household_account',
        title: '지출 알림',
        content: '승인 10,000원 카페',
      );

      // When
      await wrapper.onNotificationReceived(event);

      // Then: 자기 앱 알림은 건너뜀
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });
  });

  group('isFinancialAlimtalkForTesting - 카카오 알림톡 3중 검증', () {
    test('금융 채널 title + 거래 키워드 + 금액 패턴 모두 있으면 true를 반환한다', () {
      // Given: 카카오페이 금융 알림톡
      const title = '카카오페이';
      const content = 'KB국민카드 승인 50,000원 스타벅스';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isTrue);
    });

    test('title이 금융 채널이 아니면 false를 반환한다', () {
      // Given: 일반 카카오톡 메시지
      const title = '홍길동';
      const content = '승인 50,000원 스타벅스';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isFalse);
    });

    test('거래 키워드가 없으면 false를 반환한다', () {
      // Given: 금융 채널이지만 거래 키워드 없음
      const title = 'KB국민카드';
      const content = '안녕하세요 고객님';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isFalse);
    });

    test('금액 패턴이 없으면 false를 반환한다', () {
      // Given: 금융 채널 + 거래 키워드 있지만 금액 없음
      const title = '신한카드';
      const content = '카드 승인이 완료되었습니다';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isFalse);
    });

    test('title이 빈 문자열이면 false를 반환한다', () {
      // Given
      const title = '';
      const content = '승인 50,000원 스타벅스';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isFalse);
    });

    test('content가 빈 문자열이면 false를 반환한다', () {
      // Given
      const title = 'KB국민카드';
      const content = '';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isFalse);
    });

    test('카카오뱅크 title로도 금융 알림톡을 인식한다', () {
      // Given
      const title = '카카오뱅크';
      const content = '출금 15,000원 편의점';

      // When
      final result = NotificationListenerWrapper.isFinancialAlimtalkForTesting(
        title,
        content,
      );

      // Then
      expect(result, isTrue);
    });
  });

  group('isFinancialAppForTesting - 금융 앱 패키지명 판별', () {
    test('KB Pay 패키지명은 금융 앱으로 인식한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.kbcard.cxh.appcard',
        ),
        isTrue,
      );
    });

    test('카카오페이 패키지명은 금융 앱으로 인식한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.kakaopay.app',
        ),
        isTrue,
      );
    });

    test('일반 앱 패키지명은 금융 앱으로 인식하지 않는다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.example.normalapp',
        ),
        isFalse,
      );
    });

    test('삼성페이 패키지명은 금융 앱으로 인식한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'com.samsung.android.spay',
        ),
        isTrue,
      );
    });

    test('토스 패키지명은 금융 앱으로 인식한다', () {
      expect(
        NotificationListenerWrapper.isFinancialAppForTesting(
          'viva.republica.toss',
        ),
        isTrue,
      );
    });
  });

  group('refreshPaymentMethods - 캐시 갱신', () {
    late NotificationListenerWrapper wrapper;

    setUp(() {
      wrapper = NotificationListenerWrapper.forTesting(
        paymentMethodRepository: mockPaymentMethodRepo,
        pendingTransactionRepository: mockPendingTxRepo,
        transactionRepository: mockTransactionRepo,
        learnedPushFormatRepository: mockLearnedPushFormatRepo,
        categoryMappingService: mockCategoryMappingService,
        duplicateCheckService: mockDuplicateCheckService,
        notificationService: mockNotificationService,
      );
    });

    test('초기화 후 refreshPaymentMethods 호출 시 결제수단을 재로딩한다', () async {
      // Given
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      when(() => mockPaymentMethodRepo.getAutoSaveEnabledPaymentMethods(
            any(),
            any(),
          )).thenAnswer((_) async => []);

      // When
      await wrapper.refreshPaymentMethods();

      // Then: getAutoSaveEnabledPaymentMethods가 호출되어야 한다
      verify(() => mockPaymentMethodRepo.getAutoSaveEnabledPaymentMethods(
            'ledger-1',
            'user-1',
          )).called(1);
    });
  });

  group('processManualNotification - 수동 알림 처리', () {
    late NotificationListenerWrapper wrapper;

    setUp(() {
      wrapper = NotificationListenerWrapper.forTesting(
        paymentMethodRepository: mockPaymentMethodRepo,
        pendingTransactionRepository: mockPendingTxRepo,
        transactionRepository: mockTransactionRepo,
        learnedPushFormatRepository: mockLearnedPushFormatRepo,
        categoryMappingService: mockCategoryMappingService,
        duplicateCheckService: mockDuplicateCheckService,
        notificationService: mockNotificationService,
      );
    });

    test('userId가 null이면 처리를 건너뛴다', () async {
      // Given: 초기화하지 않은 상태 (userId = null)
      // wrapper는 초기화되지 않았으므로 userId == null

      // When
      await wrapper.processManualNotification(
        packageName: 'com.kbcard.cxh.appcard',
        title: 'KB국민카드',
        content: '승인 50,000원 스타벅스',
      );

      // Then: 아무것도 호출되지 않아야 한다
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });

    test('결제수단이 없으면 processManualNotification이 아무것도 처리하지 않는다', () async {
      // Given: 결제수단 없이 초기화
      wrapper.initializeForTesting(
        userId: 'user-1',
        ledgerId: 'ledger-1',
        autoSavePaymentMethods: [],
        learnedFormatsCache: {},
      );

      // When
      await wrapper.processManualNotification(
        packageName: 'com.kbcard.cxh.appcard',
        title: 'KB국민카드',
        content: '승인 50,000원 스타벅스',
      );

      // Then: pending transaction이 생성되지 않아야 한다
      verifyNever(() => mockPendingTxRepo.createPendingTransaction(
            ledgerId: any(named: 'ledgerId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            userId: any(named: 'userId'),
            sourceType: any(named: 'sourceType'),
            sourceSender: any(named: 'sourceSender'),
            sourceContent: any(named: 'sourceContent'),
            sourceTimestamp: any(named: 'sourceTimestamp'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            duplicateHash: any(named: 'duplicateHash'),
            isDuplicate: any(named: 'isDuplicate'),
            status: any(named: 'status'),
            isViewed: any(named: 'isViewed'),
          ));
    });
  });

  group('stopListening - 리스닝 중지', () {
    late NotificationListenerWrapper wrapper;

    setUp(() {
      wrapper = NotificationListenerWrapper.forTesting(
        paymentMethodRepository: mockPaymentMethodRepo,
        pendingTransactionRepository: mockPendingTxRepo,
        transactionRepository: mockTransactionRepo,
        learnedPushFormatRepository: mockLearnedPushFormatRepo,
        categoryMappingService: mockCategoryMappingService,
        duplicateCheckService: mockDuplicateCheckService,
        notificationService: mockNotificationService,
      );
    });

    test('stopListening 호출 후 isListening이 false가 된다', () {
      // Given: 초기 상태
      expect(wrapper.isListening, isFalse);

      // When
      wrapper.stopListening();

      // Then
      expect(wrapper.isListening, isFalse);
    });
  });

  group('financialChannelKeywordsForTesting - 키워드 목록', () {
    test('금융 채널 키워드 목록이 비어있지 않다', () {
      final keywords =
          NotificationListenerWrapper.financialChannelKeywordsForTesting;
      expect(keywords, isNotEmpty);
      expect(keywords, contains('KB국민카드'));
      expect(keywords, contains('카카오페이'));
    });

    test('알림톡 거래 키워드 목록이 비어있지 않다', () {
      final keywords =
          NotificationListenerWrapper.alimtalkTransactionKeywordsForTesting;
      expect(keywords, isNotEmpty);
      expect(keywords, contains('승인'));
      expect(keywords, contains('결제'));
    });

    test('금액 패턴이 원 단위 금액을 인식한다', () {
      final pattern = NotificationListenerWrapper.amountPatternForTesting;
      expect(pattern.hasMatch('50,000원'), isTrue);
      expect(pattern.hasMatch('1,000,000원'), isTrue);
      expect(pattern.hasMatch('안녕하세요'), isFalse);
    });
  });
}
