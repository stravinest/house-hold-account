import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
}
