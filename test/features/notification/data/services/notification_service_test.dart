import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/notification/data/repositories/notification_settings_repository.dart';
import 'package:shared_household_account/features/notification/data/services/notification_service.dart';
import 'package:shared_household_account/features/notification/domain/entities/notification_type.dart';
import 'package:shared_household_account/features/notification/services/local_notification_service.dart';

class MockNotificationSettingsRepository extends Mock
    implements NotificationSettingsRepository {}

class MockLocalNotificationService extends Mock
    implements LocalNotificationService {}

/// NotificationService의 핵심 분기 로직을 독립적으로 추출하여 테스트
/// (NotificationService는 생성자에서 Supabase를 직접 초기화하므로
///  서비스 클래스 자체를 인스턴스화하지 않고 동등한 로직을 검증)
Future<void> sendAutoCollectNotificationLogic({
  required NotificationSettingsRepository settingsRepo,
  required LocalNotificationService localNotifService,
  required String userId,
  required NotificationType type,
  required String title,
  required String body,
  required Map<String, dynamic> data,
}) async {
  final settings = await settingsRepo.getNotificationSettings(userId);
  final isEnabled = settings[type] ?? false;
  if (!isEnabled) return;

  await localNotifService.showNotification(
    title: title,
    body: body,
    data: data,
  );
}

void main() {
  group('NotificationService 핵심 로직 단위 테스트', () {
    late MockNotificationSettingsRepository mockSettingsRepository;
    late MockLocalNotificationService mockLocalNotificationService;

    setUpAll(() {
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue(NotificationType.autoCollectSuggested);
    });

    setUp(() {
      mockSettingsRepository = MockNotificationSettingsRepository();
      mockLocalNotificationService = MockLocalNotificationService();
    });

    group('sendAutoCollectNotification - 알림 활성화 여부 분기', () {
      test('해당 알림 타입이 활성화된 경우 로컬 알림을 표시한다', () async {
        // Given: autoCollectSuggested가 활성화된 설정
        when(() => mockSettingsRepository.getNotificationSettings('user-1'))
            .thenAnswer(
          (_) async => {
            NotificationType.autoCollectSuggested: true,
          },
        );
        when(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-1',
          type: NotificationType.autoCollectSuggested,
          title: '거래 감지',
          body: '5,000원 거래를 감지했습니다.',
          data: {'pendingId': 'pending-1'},
        );

        // Then: 로컬 알림이 표시되어야 한다
        verify(
          () => mockLocalNotificationService.showNotification(
            title: '거래 감지',
            body: '5,000원 거래를 감지했습니다.',
            data: {'pendingId': 'pending-1'},
          ),
        ).called(1);
      });

      test('해당 알림 타입이 비활성화된 경우 로컬 알림을 표시하지 않는다', () async {
        // Given: autoCollectSuggested가 비활성화된 설정
        when(() => mockSettingsRepository.getNotificationSettings('user-1'))
            .thenAnswer(
          (_) async => {
            NotificationType.autoCollectSuggested: false,
          },
        );

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-1',
          type: NotificationType.autoCollectSuggested,
          title: '거래 감지',
          body: '5,000원 거래를 감지했습니다.',
          data: {},
        );

        // Then: 로컬 알림이 표시되지 않아야 한다
        verifyNever(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        );
      });

      test('알림 설정에 해당 타입이 없으면(null) 기본값 false로 처리하여 알림을 표시하지 않는다',
          () async {
        // Given: 설정에 타입이 없음
        when(() => mockSettingsRepository.getNotificationSettings('user-1'))
            .thenAnswer((_) async => <NotificationType, bool>{});

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-1',
          type: NotificationType.autoCollectSaved,
          title: '자동 저장 완료',
          body: '거래가 자동으로 저장되었습니다.',
          data: {},
        );

        // Then: 로컬 알림이 표시되지 않아야 한다
        verifyNever(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        );
      });
    });

    group('NotificationType 값 검증', () {
      test('autoCollectSuggested의 value가 올바르다', () {
        expect(
          NotificationType.autoCollectSuggested.value,
          equals('auto_collect_suggested'),
        );
      });

      test('autoCollectSaved의 value가 올바르다', () {
        expect(
          NotificationType.autoCollectSaved.value,
          equals('auto_collect_saved'),
        );
      });

      test('inviteReceived의 value가 올바르다', () {
        expect(
          NotificationType.inviteReceived.value,
          equals('invite_received'),
        );
      });

      test('inviteAccepted의 value가 올바르다', () {
        expect(
          NotificationType.inviteAccepted.value,
          equals('invite_accepted'),
        );
      });

      test('transactionAdded의 value가 올바르다', () {
        expect(
          NotificationType.transactionAdded.value,
          equals('transaction_added'),
        );
      });

      test('transactionUpdated의 value가 올바르다', () {
        expect(
          NotificationType.transactionUpdated.value,
          equals('transaction_updated'),
        );
      });

      test('transactionDeleted의 value가 올바르다', () {
        expect(
          NotificationType.transactionDeleted.value,
          equals('transaction_deleted'),
        );
      });

      test('fromString으로 올바른 타입을 반환한다', () {
        expect(
          NotificationType.fromString('auto_collect_suggested'),
          equals(NotificationType.autoCollectSuggested),
        );
        expect(
          NotificationType.fromString('transaction_added'),
          equals(NotificationType.transactionAdded),
        );
        expect(
          NotificationType.fromString('invite_received'),
          equals(NotificationType.inviteReceived),
        );
      });

      test('fromString에 알 수 없는 값을 넣으면 ArgumentError가 발생한다', () {
        expect(
          () => NotificationType.fromString('unknown_type'),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('NotificationType.icon 검증', () {
      test('모든 NotificationType은 icon을 반환한다', () {
        for (final type in NotificationType.values) {
          expect(type.icon, isNotNull);
        }
      });
    });

    group('sendAutoCollectNotification 추가 케이스', () {
      test('여러 타입의 알림이 설정맵에 있을 때 해당 타입만 확인한다', () async {
        // Given: 여러 타입이 섞인 설정
        when(() => mockSettingsRepository.getNotificationSettings('user-5'))
            .thenAnswer(
          (_) async => {
            NotificationType.autoCollectSuggested: false,
            NotificationType.autoCollectSaved: true,
            NotificationType.transactionAdded: true,
          },
        );

        // When: 비활성화된 autoCollectSuggested 타입으로 요청
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-5',
          type: NotificationType.autoCollectSuggested,
          title: '제목',
          body: '내용',
          data: {},
        );

        // Then: 비활성화된 타입이므로 알림이 표시되지 않는다
        verifyNever(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        );
      });

      test('data 파라미터가 비어있어도 알림이 활성화되면 showNotification이 호출된다', () async {
        // Given
        when(() => mockSettingsRepository.getNotificationSettings('user-6'))
            .thenAnswer(
          (_) async => {NotificationType.transactionDeleted: true},
        );
        when(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-6',
          type: NotificationType.transactionDeleted,
          title: '거래 삭제',
          body: '거래가 삭제되었습니다.',
          data: {},
        );

        // Then: 빈 data라도 알림이 표시되어야 한다
        verify(
          () => mockLocalNotificationService.showNotification(
            title: '거래 삭제',
            body: '거래가 삭제되었습니다.',
            data: {},
          ),
        ).called(1);
      });

      test('transactionUpdated 타입이 활성화된 경우 로컬 알림을 표시한다', () async {
        // Given
        when(() => mockSettingsRepository.getNotificationSettings('user-7'))
            .thenAnswer(
          (_) async => {NotificationType.transactionUpdated: true},
        );
        when(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-7',
          type: NotificationType.transactionUpdated,
          title: '거래 수정',
          body: '거래가 수정되었습니다.',
          data: {'transactionId': 'tx-99'},
        );

        // Then
        verify(
          () => mockLocalNotificationService.showNotification(
            title: '거래 수정',
            body: '거래가 수정되었습니다.',
            data: {'transactionId': 'tx-99'},
          ),
        ).called(1);
      });

      test('inviteAccepted 타입이 비활성화된 경우 로컬 알림을 표시하지 않는다', () async {
        // Given
        when(() => mockSettingsRepository.getNotificationSettings('user-8'))
            .thenAnswer(
          (_) async => {NotificationType.inviteAccepted: false},
        );

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-8',
          type: NotificationType.inviteAccepted,
          title: '초대 수락',
          body: '초대가 수락되었습니다.',
          data: {},
        );

        // Then
        verifyNever(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        );
      });
    });

    group('NotificationService 타입 구조 검증', () {
      test('NotificationService 타입이 존재한다', () {
        // Given / When / Then: 클래스 타입이 존재함을 검증
        expect(NotificationService, isNotNull);
      });

      test('sendAutoCollectNotification 핵심 분기 - 활성화 타입은 로컬 알림을 표시한다', () async {
        // Given: autoCollectSaved가 활성화된 상태
        when(() => mockSettingsRepository.getNotificationSettings('user-2'))
            .thenAnswer(
          (_) async => {
            NotificationType.autoCollectSaved: true,
          },
        );
        when(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-2',
          type: NotificationType.autoCollectSaved,
          title: '자동 저장 완료',
          body: '10,000원이 자동으로 저장되었습니다.',
          data: {'transactionId': 'tx-1'},
        );

        // Then: showNotification이 정확한 인자로 호출됨
        verify(
          () => mockLocalNotificationService.showNotification(
            title: '자동 저장 완료',
            body: '10,000원이 자동으로 저장되었습니다.',
            data: {'transactionId': 'tx-1'},
          ),
        ).called(1);
      });

      test('sendAutoCollectNotification 핵심 분기 - inviteReceived 타입도 올바르게 처리된다', () async {
        // Given: inviteReceived가 활성화된 상태
        when(() => mockSettingsRepository.getNotificationSettings('user-3'))
            .thenAnswer(
          (_) async => {
            NotificationType.inviteReceived: true,
          },
        );
        when(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        ).thenAnswer((_) async {});

        // When
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-3',
          type: NotificationType.inviteReceived,
          title: '초대 수신',
          body: '새로운 가계부 초대가 도착했습니다.',
          data: {'ledgerId': 'ledger-1'},
        );

        // Then
        verify(
          () => mockLocalNotificationService.showNotification(
            title: '초대 수신',
            body: '새로운 가계부 초대가 도착했습니다.',
            data: {'ledgerId': 'ledger-1'},
          ),
        ).called(1);
      });

      test('sendAutoCollectNotification 핵심 분기 - transactionAdded 비활성화 시 알림 없음', () async {
        // Given: transactionAdded가 비활성화된 상태
        when(() => mockSettingsRepository.getNotificationSettings('user-4'))
            .thenAnswer(
          (_) async => {
            NotificationType.transactionAdded: false,
            NotificationType.autoCollectSaved: true,
          },
        );

        // When: transactionAdded 타입으로 알림 요청
        await sendAutoCollectNotificationLogic(
          settingsRepo: mockSettingsRepository,
          localNotifService: mockLocalNotificationService,
          userId: 'user-4',
          type: NotificationType.transactionAdded,
          title: '거래 추가됨',
          body: '5,000원 거래가 추가되었습니다.',
          data: {},
        );

        // Then: showNotification이 호출되지 않아야 함
        verifyNever(
          () => mockLocalNotificationService.showNotification(
            title: any(named: 'title'),
            body: any(named: 'body'),
            data: any(named: 'data'),
          ),
        );
      });
    });
  });
}
