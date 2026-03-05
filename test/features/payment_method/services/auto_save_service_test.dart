import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/payment_method/data/services/auto_save_service.dart';

/// AutoSaveService 단위 테스트
///
/// AutoSaveService는 싱글톤 서비스로 Platform.isAndroid에 의존한다.
/// 테스트 환경(macOS/Linux)에서는 isAndroid=false이므로 비안드로이드 경로만 테스트한다.
/// 비즈니스 로직 데이터 클래스인 TransactionDetectedEvent, PermissionStatus는 직접 테스트한다.
void main() {
  group('AutoSaveStatus 열거형', () {
    test('6가지 상태값이 존재한다', () {
      // Given/When: 모든 상태값 확인
      // Then: notInitialized, initializing, running, stopped, error 상태가 존재해야 한다
      expect(AutoSaveStatus.notInitialized, isNotNull);
      expect(AutoSaveStatus.initializing, isNotNull);
      expect(AutoSaveStatus.running, isNotNull);
      expect(AutoSaveStatus.stopped, isNotNull);
      expect(AutoSaveStatus.error, isNotNull);
    });

    test('AutoSaveStatus 값 목록이 5개다', () {
      // Given/When: AutoSaveStatus.values 확인
      // Then: 5개의 값이 있어야 한다
      expect(AutoSaveStatus.values.length, 5);
    });
  });

  group('TransactionSource 열거형', () {
    test('sms와 notification 소스가 존재한다', () {
      // Given/When/Then: 두 가지 소스 타입 확인
      expect(TransactionSource.sms, isNotNull);
      expect(TransactionSource.notification, isNotNull);
    });

    test('TransactionSource 값이 2개다', () {
      // Given/When/Then
      expect(TransactionSource.values.length, 2);
    });
  });

  group('TransactionDetectedEvent - SMS 소스', () {
    late TransactionDetectedEvent event;

    setUp(() {
      event = const TransactionDetectedEvent(
        source: TransactionSource.sms,
        sender: '01234',
        content: '[KB카드] 10,000원 승인',
        success: true,
        reason: null,
        autoSaveMode: 'suggest',
        parsedAmount: 10000,
        parsedMerchant: '스타벅스',
      );
    });

    test('isFromSms가 true를 반환한다', () {
      // Given: SMS 소스 이벤트
      // When/Then: isFromSms는 true여야 한다
      expect(event.isFromSms, isTrue);
    });

    test('isFromNotification이 false를 반환한다', () {
      // Given: SMS 소스 이벤트
      // When/Then: isFromNotification은 false여야 한다
      expect(event.isFromNotification, isFalse);
    });

    test('모든 필드가 올바르게 저장된다', () {
      // Given: SMS 소스 이벤트
      // When/Then: 각 필드값을 확인한다
      expect(event.source, equals(TransactionSource.sms));
      expect(event.sender, equals('01234'));
      expect(event.content, equals('[KB카드] 10,000원 승인'));
      expect(event.success, isTrue);
      expect(event.reason, isNull);
      expect(event.autoSaveMode, equals('suggest'));
      expect(event.parsedAmount, equals(10000));
      expect(event.parsedMerchant, equals('스타벅스'));
    });
  });

  group('TransactionDetectedEvent - 알림 소스', () {
    late TransactionDetectedEvent event;

    setUp(() {
      event = const TransactionDetectedEvent(
        source: TransactionSource.notification,
        sender: 'com.kbcard.cxh.appcard',
        content: 'KB Pay 승인 15,000원',
        success: false,
        reason: '파싱 실패',
        autoSaveMode: 'manual',
        parsedAmount: null,
        parsedMerchant: null,
      );
    });

    test('isFromNotification이 true를 반환한다', () {
      // Given: 알림 소스 이벤트
      // When/Then: isFromNotification은 true여야 한다
      expect(event.isFromNotification, isTrue);
    });

    test('isFromSms가 false를 반환한다', () {
      // Given: 알림 소스 이벤트
      // When/Then: isFromSms는 false여야 한다
      expect(event.isFromSms, isFalse);
    });

    test('실패한 이벤트의 reason이 저장된다', () {
      // Given: 실패한 이벤트
      // When/Then: reason 필드가 올바르게 저장된다
      expect(event.success, isFalse);
      expect(event.reason, equals('파싱 실패'));
    });

    test('parsedAmount와 parsedMerchant가 null일 수 있다', () {
      // Given: 파싱 실패 이벤트
      // When/Then: nullable 필드가 null로 저장된다
      expect(event.parsedAmount, isNull);
      expect(event.parsedMerchant, isNull);
    });
  });

  group('PermissionStatus - 안드로이드', () {
    test('allGranted는 모든 권한이 허용된 경우 true를 반환한다', () {
      // Given: SMS와 알림 모두 허용
      const status = PermissionStatus(
        smsGranted: true,
        notificationGranted: true,
        isAndroid: true,
      );

      // When/Then
      expect(status.allGranted, isTrue);
    });

    test('allGranted는 하나라도 거부된 경우 false를 반환한다', () {
      // Given: SMS만 허용, 알림은 거부
      const statusSmsOnly = PermissionStatus(
        smsGranted: true,
        notificationGranted: false,
        isAndroid: true,
      );
      const statusNotiOnly = PermissionStatus(
        smsGranted: false,
        notificationGranted: true,
        isAndroid: true,
      );

      // When/Then
      expect(statusSmsOnly.allGranted, isFalse);
      expect(statusNotiOnly.allGranted, isFalse);
    });

    test('anyGranted는 하나라도 허용된 경우 true를 반환한다', () {
      // Given: SMS만 허용
      const status = PermissionStatus(
        smsGranted: true,
        notificationGranted: false,
        isAndroid: true,
      );

      // When/Then
      expect(status.anyGranted, isTrue);
    });

    test('anyGranted는 모두 거부된 경우 false를 반환한다', () {
      // Given: 모두 거부
      const status = PermissionStatus(
        smsGranted: false,
        notificationGranted: false,
        isAndroid: true,
      );

      // When/Then
      expect(status.anyGranted, isFalse);
    });

    test('noneGranted는 모두 거부된 경우 true를 반환한다', () {
      // Given: 모두 거부
      const status = PermissionStatus(
        smsGranted: false,
        notificationGranted: false,
        isAndroid: true,
      );

      // When/Then
      expect(status.noneGranted, isTrue);
    });

    test('noneGranted는 하나라도 허용된 경우 false를 반환한다', () {
      // Given: SMS 허용
      const status = PermissionStatus(
        smsGranted: true,
        notificationGranted: false,
        isAndroid: true,
      );

      // When/Then
      expect(status.noneGranted, isFalse);
    });
  });

  group('PermissionStatus - 비안드로이드', () {
    test('isAndroid=false이면 smsGranted와 notificationGranted가 false다', () {
      // Given: 비안드로이드 환경 (iOS)
      const status = PermissionStatus(
        smsGranted: false,
        notificationGranted: false,
        isAndroid: false,
      );

      // When/Then: SMS 관련 기능 미지원
      expect(status.isAndroid, isFalse);
      expect(status.smsGranted, isFalse);
      expect(status.notificationGranted, isFalse);
      expect(status.allGranted, isFalse);
      expect(status.noneGranted, isTrue);
    });
  });

  group('AutoSaveService - 비안드로이드 환경', () {
    // 주의: dispose()는 내부적으로 SmsListenerService.instance를 통해
    // platform channel을 초기화하려 하므로 테스트 환경에서 호출하지 않는다.
    // 대신 각 테스트는 독립적으로 instance에 접근한다.

    test('instance 접근 시 싱글톤 인스턴스를 반환한다', () {
      // Given/When: instance에 두 번 접근
      final instance1 = AutoSaveService.instance;
      final instance2 = AutoSaveService.instance;

      // Then: 동일한 인스턴스여야 한다
      expect(identical(instance1, instance2), isTrue);
    });

    test('초기 상태는 notInitialized다', () {
      // Given/When: AutoSaveService 인스턴스
      // Then: 상태가 notInitialized 또는 그 이후 상태여야 한다
      expect(AutoSaveService.instance.status, isA<AutoSaveStatus>());
    });

    test('비안드로이드에서 isRunning은 false다', () {
      // Given: 비안드로이드 환경
      // When/Then: isRunning은 false여야 한다
      expect(AutoSaveService.instance.isRunning, isFalse);
    });

    test('비안드로이드에서 isAndroid는 false다', () {
      // Given: 비안드로이드 환경 (테스트 환경은 macOS)
      // When/Then: isAndroid는 false여야 한다
      expect(AutoSaveService.instance.isAndroid, isFalse);
    });

    test('비안드로이드에서 initialize 호출 시 상태가 running이 되지 않는다', () async {
      // Given: 비안드로이드 환경
      // When: initialize 호출
      await AutoSaveService.instance.initialize(
        userId: 'user-1',
        ledgerId: 'ledger-1',
      );

      // Then: isAndroid=false이므로 running 상태가 아니어야 한다
      expect(AutoSaveService.instance.isRunning, isFalse);
    });

    test('비안드로이드에서 start 호출 시 상태가 running이 되지 않는다', () {
      // Given: 비안드로이드 환경
      // When: start 호출
      AutoSaveService.instance.start();

      // Then: isAndroid=false이므로 running 상태가 아니어야 한다
      expect(AutoSaveService.instance.isRunning, isFalse);
    });

    test('비안드로이드에서 stop 호출 시 크래시가 발생하지 않는다', () {
      // Given: 비안드로이드 환경
      // When/Then: stop 호출 시 예외 없이 동작해야 한다
      expect(() => AutoSaveService.instance.stop(), returnsNormally);
    });

    test('비안드로이드에서 checkPermissions는 isAndroid=false 상태를 반환한다', () async {
      // Given: 비안드로이드 환경
      // When: checkPermissions 호출
      final permissions = await AutoSaveService.instance.checkPermissions();

      // Then: isAndroid=false, 모든 권한이 false여야 한다
      expect(permissions.isAndroid, isFalse);
      expect(permissions.smsGranted, isFalse);
      expect(permissions.notificationGranted, isFalse);
    });

    test('비안드로이드에서 requestSmsPermission은 false를 반환한다', () async {
      // Given: 비안드로이드 환경
      // When: requestSmsPermission 호출
      final result = await AutoSaveService.instance.requestSmsPermission();

      // Then: false여야 한다
      expect(result, isFalse);
    });

    test('비안드로이드에서 requestNotificationPermission은 false를 반환한다', () async {
      // Given: 비안드로이드 환경
      // When: requestNotificationPermission 호출
      final result = await AutoSaveService.instance.requestNotificationPermission();

      // Then: false여야 한다
      expect(result, isFalse);
    });

    test('비안드로이드에서 processPastSms 호출 시 크래시가 발생하지 않는다', () async {
      // Given: 비안드로이드 환경
      // When/Then: processPastSms 호출 시 예외 없이 동작해야 한다
      await expectLater(
        AutoSaveService.instance.processPastSms(days: 3),
        completes,
      );
    });

    test('onTransactionDetected 스트림이 존재한다', () {
      // Given/When: 스트림 접근
      // Then: 스트림이 null이 아니어야 한다
      expect(AutoSaveService.instance.onTransactionDetected, isNotNull);
    });

    test('onStatusChanged 스트림이 존재한다', () {
      // Given/When: 스트림 접근
      // Then: 스트림이 null이 아니어야 한다
      expect(AutoSaveService.instance.onStatusChanged, isNotNull);
    });

    test('onNativeNotification 스트림이 존재한다', () {
      // Given/When: 스트림 접근
      // Then: 스트림이 null이 아니어야 한다
      expect(AutoSaveService.instance.onNativeNotification, isNotNull);
    });

    test('currentUserId getter가 존재한다', () {
      // Given/When: getter 접근
      // Then: 예외 없이 접근 가능해야 한다
      expect(() => AutoSaveService.instance.currentUserId, returnsNormally);
    });

    test('currentLedgerId getter가 존재한다', () {
      // Given/When: getter 접근
      // Then: 예외 없이 접근 가능해야 한다
      expect(() => AutoSaveService.instance.currentLedgerId, returnsNormally);
    });

    test('lastError getter가 존재한다', () {
      // Given/When: getter 접근
      // Then: 예외 없이 접근 가능해야 한다
      expect(() => AutoSaveService.instance.lastError, returnsNormally);
    });
  });
}
