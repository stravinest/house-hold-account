import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/payment_method_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/payment_method_repository.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/payment_method.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/payment_method_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart' show MockUser;
import '../../../../helpers/test_providers.dart' hide pumpEventQueue;

class MockPaymentMethodRepository extends Mock
    implements PaymentMethodRepository {}

/// RealtimeChannel Mock - unsubscribe 지원
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

PaymentMethodModel _makePaymentMethod({
  String id = 'pm-1',
  String name = 'KB카드',
  String ledgerId = 'ledger-1',
  String ownerUserId = 'user-1',
  int sortOrder = 1,
}) {
  return PaymentMethodModel(
    id: id,
    ledgerId: ledgerId,
    ownerUserId: ownerUserId,
    name: name,
    icon: 'credit_card',
    color: '#6750A4',
    isDefault: false,
    sortOrder: sortOrder,
    createdAt: DateTime(2026, 1, 1),
    autoSaveMode: AutoSaveMode.manual,
    defaultCategoryId: null,
    canAutoSave: false,
    autoCollectSource: AutoCollectSource.sms,
  );
}

void main() {
  late MockPaymentMethodRepository mockRepository;
  late MockRealtimeChannel mockChannel;

  setUp(() {
    mockRepository = MockPaymentMethodRepository();
    mockChannel = MockRealtimeChannel();
    registerFallbackValue(StackTrace.empty);

    // subscribePaymentMethods mock 기본 설정
    when(() => mockRepository.subscribePaymentMethods(
          ledgerId: any(named: 'ledgerId'),
          onPaymentMethodChanged: any(named: 'onPaymentMethodChanged'),
        )).thenReturn(mockChannel);
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
  });

  group('paymentMethodRepositoryProvider', () {
    test('PaymentMethodRepository 인스턴스를 제공한다', () {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final repo = container.read(paymentMethodRepositoryProvider);
      expect(repo, isA<PaymentMethodRepository>());
    });
  });

  group('paymentMethodsProvider', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(paymentMethodsProvider.future);
      expect(result, isEmpty);
    });

    test('ledgerId가 있으면 결제수단 목록을 반환한다', () async {
      final methods = [_makePaymentMethod(), _makePaymentMethod(id: 'pm-2', name: '현금')];
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => methods);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(paymentMethodsProvider.future);
      expect(result.length, 2);
      expect(result[0].name, 'KB카드');
    });
  });

  group('paymentMethodsByOwnerProvider', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        paymentMethodsByOwnerProvider('user-1').future,
      );
      expect(result, isEmpty);
    });

    test('ownerUserId에 해당하는 결제수단 목록을 반환한다', () async {
      final methods = [_makePaymentMethod()];
      when(() => mockRepository.getPaymentMethodsByOwner(
            ledgerId: 'ledger-1',
            ownerUserId: 'user-1',
          )).thenAnswer((_) async => methods);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        paymentMethodsByOwnerProvider('user-1').future,
      );
      expect(result.length, 1);
      expect(result[0].ownerUserId, 'user-1');
    });
  });

  group('sharedPaymentMethodsProvider', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(sharedPaymentMethodsProvider.future);
      expect(result, isEmpty);
    });

    test('공유 결제수단 목록을 반환한다', () async {
      final methods = [
        _makePaymentMethod(id: 'shared-1', name: '가족카드'),
      ];
      when(() => mockRepository.getSharedPaymentMethods('ledger-1'))
          .thenAnswer((_) async => methods);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(sharedPaymentMethodsProvider.future);
      expect(result.length, 1);
      expect(result[0].name, '가족카드');
    });
  });

  group('autoCollectPaymentMethodsByOwnerProvider', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        autoCollectPaymentMethodsByOwnerProvider('user-1').future,
      );
      expect(result, isEmpty);
    });

    test('자동수집 결제수단 목록을 반환한다', () async {
      final methods = [
        _makePaymentMethod(id: 'auto-1', name: '자동수집카드'),
      ];
      when(() => mockRepository.getAutoCollectPaymentMethodsByOwner(
            ledgerId: 'ledger-1',
            ownerUserId: 'user-1',
          )).thenAnswer((_) async => methods);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        autoCollectPaymentMethodsByOwnerProvider('user-1').future,
      );
      expect(result.length, 1);
    });
  });

  group('PaymentMethodNotifier - loadPaymentMethods', () {
    test('ledgerId가 null이면 빈 리스트로 초기화된다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(Duration.zero);
      final state = container.read(paymentMethodNotifierProvider);
      expect(state, isA<AsyncData<List<PaymentMethod>>>());
      expect(state.value, isEmpty);
    });

    test('결제수단 목록을 로드하여 data 상태로 전환한다', () async {
      final methods = [_makePaymentMethod(), _makePaymentMethod(id: 'pm-2', name: '현금')];
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => methods);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      // notifier를 직접 읽어서 loadPaymentMethods 완료까지 대기
      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      await notifier.loadPaymentMethods();

      final state = container.read(paymentMethodNotifierProvider);
      expect(state, isA<AsyncData<List<PaymentMethod>>>());
      expect(state.value?.length, 2);
    });

    test('Repository 에러 시 loadPaymentMethods가 예외를 던진다', () async {
      // 첫 번째 호출(생성자 microtask)은 성공, 두 번째 이후는 에러
      var callCount = 0;
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [];
        throw Exception('DB 연결 실패');
      });

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      // notifier를 먼저 읽어서 초기화 트리거
      final notifier = container.read(paymentMethodNotifierProvider.notifier);

      // 생성자 microtask (첫 번째 getPaymentMethods 호출) 완료 대기
      await Future.delayed(const Duration(milliseconds: 100));

      // 두 번째 loadPaymentMethods 호출 - 예외를 던져야 함
      await expectLater(
        notifier.loadPaymentMethods(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentMethodNotifier - createPaymentMethod', () {
    test('결제수단 생성 후 목록을 갱신한다', () async {
      final newMethod = _makePaymentMethod(id: 'pm-new', name: '신규카드');
      final updatedList = [_makePaymentMethod(), newMethod];

      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [_makePaymentMethod()]);

      when(() => mockRepository.createPaymentMethod(
            ledgerId: 'ledger-1',
            name: '신규카드',
            icon: '',
            color: '#6750A4',
            canAutoSave: true,
          )).thenAnswer((_) async => newMethod);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      // 두 번째 호출 (createPaymentMethod 후 loadPaymentMethods)에서 갱신된 목록 반환
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => updatedList);

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      final result = await notifier.createPaymentMethod(name: '신규카드');

      expect(result.name, '신규카드');
      await Future.delayed(const Duration(milliseconds: 50));
      final state = container.read(paymentMethodNotifierProvider);
      expect(state.value?.length, 2);
    });

    test('ledgerId가 null이면 예외를 던진다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(Duration.zero);

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      expect(
        () => notifier.createPaymentMethod(name: '신규카드'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentMethodNotifier - updatePaymentMethod', () {
    test('결제수단 이름을 수정하면 수정된 결제수단을 반환한다', () async {
      final original = _makePaymentMethod();
      final updated = _makePaymentMethod(name: '수정된카드');

      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [original]);
      when(() => mockRepository.updatePaymentMethod(
            id: 'pm-1',
            name: '수정된카드',
            icon: null,
            color: null,
            canAutoSave: null,
          )).thenAnswer((_) async => updated);

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      final result = await notifier.updatePaymentMethod(
        id: 'pm-1',
        name: '수정된카드',
      );

      expect(result.name, '수정된카드');
    });

    test('Repository 에러 시 error 상태로 전환하고 예외를 rethrow한다', () async {
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [_makePaymentMethod()]);
      when(() => mockRepository.updatePaymentMethod(
            id: 'pm-1',
            name: any(named: 'name'),
            icon: any(named: 'icon'),
            color: any(named: 'color'),
            canAutoSave: any(named: 'canAutoSave'),
          )).thenThrow(Exception('업데이트 실패'));

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      expect(
        () => notifier.updatePaymentMethod(id: 'pm-1', name: '수정된카드'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('PaymentMethodNotifier - deletePaymentMethod', () {
    test('결제수단 삭제 후 목록이 갱신된다', () async {
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [_makePaymentMethod()]);
      when(() => mockRepository.deletePaymentMethod('pm-1'))
          .thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      // 삭제 후 목록 로드 시 빈 리스트 반환
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => []);

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      await notifier.deletePaymentMethod('pm-1');

      await Future.delayed(const Duration(milliseconds: 50));
      final state = container.read(paymentMethodNotifierProvider);
      expect(state.value, isEmpty);
    });
  });

  group('PaymentMethodNotifier - updateAutoSaveSettings', () {
    test('자동저장 설정 변경 후 목록이 갱신된다', () async {
      final method = _makePaymentMethod();
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [method]);
      when(() => mockRepository.updateAutoSaveSettings(
            id: 'pm-1',
            autoSaveMode: 'suggest',
            defaultCategoryId: null,
            autoCollectSource: null,
          )).thenAnswer((_) async => _makePaymentMethod());

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      await notifier.updateAutoSaveSettings(
        id: 'pm-1',
        autoSaveMode: AutoSaveMode.suggest,
      );

      verify(() => mockRepository.updateAutoSaveSettings(
            id: 'pm-1',
            autoSaveMode: 'suggest',
            defaultCategoryId: null,
            autoCollectSource: null,
          )).called(1);
    });

    test('기본 카테고리와 함께 자동저장 설정을 변경한다', () async {
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [_makePaymentMethod()]);
      when(() => mockRepository.updateAutoSaveSettings(
            id: 'pm-1',
            autoSaveMode: 'auto',
            defaultCategoryId: 'cat-food',
            autoCollectSource: null,
          )).thenAnswer((_) async => _makePaymentMethod());

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      await notifier.updateAutoSaveSettings(
        id: 'pm-1',
        autoSaveMode: AutoSaveMode.auto,
        defaultCategoryId: 'cat-food',
      );

      verify(() => mockRepository.updateAutoSaveSettings(
            id: 'pm-1',
            autoSaveMode: 'auto',
            defaultCategoryId: 'cat-food',
            autoCollectSource: null,
          )).called(1);
    });

    test('updateAutoSaveSettings 에러 시 예외를 rethrow한다', () async {
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async => [_makePaymentMethod()]);
      when(() => mockRepository.updateAutoSaveSettings(
            id: 'pm-1',
            autoSaveMode: any(named: 'autoSaveMode'),
            defaultCategoryId: any(named: 'defaultCategoryId'),
            autoCollectSource: any(named: 'autoCollectSource'),
          )).thenThrow(Exception('설정 변경 실패'));

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      await expectLater(
        notifier.updateAutoSaveSettings(
          id: 'pm-1',
          autoSaveMode: AutoSaveMode.suggest,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('selectablePaymentMethodsProvider', () {
    test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(selectablePaymentMethodsProvider.future);
      expect(result, isEmpty);
    });

    test('currentUser가 null이면 빈 리스트를 반환한다', () async {
      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(selectablePaymentMethodsProvider.future);
      expect(result, isEmpty);
    });

    test('공유+자동수집 결제수단을 합쳐서 반환한다', () async {
      final shared = [_makePaymentMethod(id: 'shared-1', name: '공유카드')];
      final autoCollect = [_makePaymentMethod(id: 'auto-1', name: '자동수집카드')];

      when(() => mockRepository.getSharedPaymentMethods('ledger-1'))
          .thenAnswer((_) async => shared);
      when(() => mockRepository.getAutoCollectPaymentMethodsByOwner(
            ledgerId: 'ledger-1',
            ownerUserId: 'user-1',
          )).thenAnswer((_) async => autoCollect);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(selectablePaymentMethodsProvider.future);
      expect(result.length, 2);
      expect(result.map((m) => m.name), containsAll(['공유카드', '자동수집카드']));
    });
  });

  group('PaymentMethodNotifier - deletePaymentMethod 에러 경로', () {
    test('삭제 실패 시 에러 후에도 loadPaymentMethods를 호출한다', () async {
      var callCount = 0;
      when(() => mockRepository.getPaymentMethods('ledger-1'))
          .thenAnswer((_) async {
        callCount++;
        return [_makePaymentMethod()];
      });
      when(() => mockRepository.deletePaymentMethod('pm-1'))
          .thenThrow(Exception('삭제 실패'));

      final container = createContainer(
        overrides: [
          paymentMethodRepositoryProvider.overrideWith((_) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      await Future.delayed(const Duration(milliseconds: 100));
      final beforeCount = callCount;

      final notifier = container.read(paymentMethodNotifierProvider.notifier);
      await expectLater(
        notifier.deletePaymentMethod('pm-1'),
        throwsA(isA<Exception>()),
      );

      // 에러 후에도 loadPaymentMethods 호출됨 (에러 복구)
      expect(callCount, greaterThan(beforeCount));
    });
  });
}
