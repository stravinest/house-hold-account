import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/learned_push_format_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/payment_method/data/services/category_mapping_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/duplicate_check_service.dart';
import 'package:shared_household_account/features/payment_method/data/services/notification_listener_wrapper.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
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
}
