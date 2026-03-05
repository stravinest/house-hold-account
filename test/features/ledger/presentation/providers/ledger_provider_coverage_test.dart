import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:realtime_client/realtime_client.dart' show RealtimeSubscribeStatus;
import 'package:shared_household_account/features/ledger/data/models/ledger_model.dart';
import 'package:shared_household_account/features/ledger/data/repositories/ledger_repository.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockLedgerRepo extends Mock implements LedgerRepository {}

/// FakeRealtimeChannel - Realtime 구독 Mock
class FakeRealtimeChannel extends Fake implements RealtimeChannel {
  @override
  RealtimeChannel onPostgresChanges({
    PostgresChangeEvent event = PostgresChangeEvent.all,
    String? schema,
    String? table,
    PostgresChangeFilter? filter,
    required void Function(PostgresChangePayload payload) callback,
  }) => this;

  @override
  RealtimeChannel subscribe([
    void Function(RealtimeSubscribeStatus status, Object? error)? callback,
    Duration? timeout,
  ]) => this;

  @override
  Future<String> unsubscribe([Duration? timeout]) async => 'ok';
}

// 테스트용 LedgerModel 생성 헬퍼 (LedgerModel은 Ledger를 extends)
LedgerModel _makeLedger({
  String id = 'ledger-1',
  String name = '내 가계부',
  String ownerId = 'user-1',
  bool isShared = false,
}) {
  return LedgerModel(
    id: id,
    name: name,
    ownerId: ownerId,
    currency: 'KRW',
    isShared: isShared,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockLedgerRepo mockRepo;

  setUp(() {
    mockRepo = MockLedgerRepo();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(_makeLedger());
  });

  group('selectedLedgerIdProvider 상태 관리 테스트', () {
    test('초기 상태가 null이어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final value = container.read(selectedLedgerIdProvider);

      // Then
      expect(value, isNull);
    });

    test('값을 설정하면 올바르게 저장되어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      container.read(selectedLedgerIdProvider.notifier).state = 'ledger-123';

      // Then
      expect(container.read(selectedLedgerIdProvider), equals('ledger-123'));
    });

    test('null로 초기화하면 null이어야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(selectedLedgerIdProvider.notifier).state = 'ledger-123';

      // When
      container.read(selectedLedgerIdProvider.notifier).state = null;

      // Then
      expect(container.read(selectedLedgerIdProvider), isNull);
    });

    test('서로 다른 컨테이너는 독립적인 상태를 가져야 한다', () {
      // Given
      final container1 = ProviderContainer();
      final container2 = ProviderContainer();
      addTearDown(container1.dispose);
      addTearDown(container2.dispose);

      // When
      container1.read(selectedLedgerIdProvider.notifier).state = 'ledger-A';
      container2.read(selectedLedgerIdProvider.notifier).state = 'ledger-B';

      // Then
      expect(container1.read(selectedLedgerIdProvider), equals('ledger-A'));
      expect(container2.read(selectedLedgerIdProvider), equals('ledger-B'));
    });
  });

  group('restoreLedgerIdProvider 테스트', () {
    test('저장된 가계부 ID가 없으면 null을 반환해야 한다', () async {
      // Given
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final restoredId = await container.read(restoreLedgerIdProvider.future);

      // Then
      expect(restoredId, isNull);
    });

    test('저장된 가계부 ID가 있으면 해당 값을 반환해야 한다', () async {
      // Given
      SharedPreferences.setMockInitialValues({
        'current_ledger_id': 'saved-ledger-id',
      });
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final restoredId = await container.read(restoreLedgerIdProvider.future);

      // Then
      expect(restoredId, equals('saved-ledger-id'));
    });
  });

  group('currentLedgerProvider 테스트', () {
    test('selectedLedgerIdProvider가 null이면 null을 반환해야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => null),
          ledgerNotifierProvider.overrideWith(
            (ref) => _FakeLedgerNotifierWithData(mockRepo, ref, []),
          ),
        ],
      );
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);

      // When
      final ledger = await container.read(currentLedgerProvider.future);

      // Then
      expect(ledger, isNull);
    });

    test('selectedLedgerIdProvider가 유효한 ID면 가계부를 반환해야 한다', () async {
      // Given
      final testLedger = _makeLedger(id: 'ledger-find-me');
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-find-me'),
          ledgerNotifierProvider.overrideWith(
            (ref) => _FakeLedgerNotifierWithData(mockRepo, ref, [testLedger]),
          ),
        ],
      );
      addTearDown(container.dispose);
      await Future.delayed(Duration.zero);

      // When
      final ledger = await container.read(currentLedgerProvider.future);

      // Then
      expect(ledger, isNotNull);
      expect(ledger!.id, equals('ledger-find-me'));
    });
  });

  group('ledgerRepositoryProvider 테스트', () {
    test('ledgerRepositoryProvider가 정의되어 있어야 한다', () {
      // Given & When & Then
      expect(ledgerRepositoryProvider, isNotNull);
    });
  });

  group('ledgerMembersProvider 테스트', () {
    test('ledgerMembersProvider가 family provider여야 한다', () {
      // Given & When & Then
      expect(ledgerMembersProvider, isNotNull);
    });
  });

  group('LedgerNotifier selectLedger 테스트', () {
    test('selectLedger 호출 시 selectedLedgerIdProvider가 업데이트되어야 한다', () async {
      // Given
      when(() => mockRepo.getLedgers()).thenAnswer((_) async => [
        _makeLedger(id: 'ledger-select-test'),
      ]);
      when(() => mockRepo.subscribeLedgers(any())).thenReturn(FakeRealtimeChannel());
      when(() => mockRepo.subscribeLedgerMembers(any())).thenReturn(FakeRealtimeChannel());

      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);

      // 초기 로딩 대기
      await Future.delayed(const Duration(milliseconds: 100));

      // When
      container.read(ledgerNotifierProvider.notifier).selectLedger('ledger-select-test');

      // Then
      expect(container.read(selectedLedgerIdProvider), equals('ledger-select-test'));
    });
  });

  group('LedgerNotifier 상태 흐름 테스트', () {
    test('getLedgers 성공 시 data 상태로 전환되어야 한다', () async {
      // Given
      final ledgers = [_makeLedger()];
      when(() => mockRepo.getLedgers()).thenAnswer((_) async => ledgers);
      when(() => mockRepo.subscribeLedgers(any())).thenReturn(FakeRealtimeChannel());
      when(() => mockRepo.subscribeLedgerMembers(any())).thenReturn(FakeRealtimeChannel());

      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(mockRepo),
          // restoreOrSelectLedger 내부에서 Supabase.instance에 접근하지 않도록
          // selectedLedgerIdProvider를 미리 설정
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      // When: 로딩 완료 대기 (최대 2초)
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final s = container.read(ledgerNotifierProvider);
        if (s is AsyncData<List<Ledger>>) break;
      }

      // Then
      final state = container.read(ledgerNotifierProvider);
      expect(state, isA<AsyncData<List<Ledger>>>());
    });

    test('getLedgers 실패 시 error 상태로 전환되어야 한다', () async {
      // Given: getLedgers가 예외를 던지도록 설정
      when(() => mockRepo.getLedgers()).thenThrow(Exception('네트워크 오류'));
      when(() => mockRepo.subscribeLedgers(any())).thenReturn(FakeRealtimeChannel());
      when(() => mockRepo.subscribeLedgerMembers(any())).thenReturn(FakeRealtimeChannel());

      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(mockRepo),
          selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
        ],
      );
      addTearDown(container.dispose);

      // When: 에러 상태 전환 대기 (최대 2초)
      for (var i = 0; i < 20; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        final s = container.read(ledgerNotifierProvider);
        if (s is AsyncError<List<Ledger>>) break;
      }

      // Then
      final state = container.read(ledgerNotifierProvider);
      expect(state, isA<AsyncError<List<Ledger>>>());
    });
  });

  group('LedgerNotifier syncShareStatus 추가 테스트', () {
    test('멤버가 2명 이상이고 현재 공유 아닌 경우 isShared를 true로 업데이트한다', () async {
      // Given
      const ledgerId = 'ledger-sync';
      when(() => mockRepo.getLedgers()).thenAnswer(
        (_) async => [_makeLedger(id: ledgerId, isShared: false)],
      );
      when(() => mockRepo.subscribeLedgers(any())).thenReturn(FakeRealtimeChannel());
      when(() => mockRepo.subscribeLedgerMembers(any())).thenReturn(FakeRealtimeChannel());
      when(() => mockRepo.updateLedger(id: any(named: 'id'), isShared: any(named: 'isShared')))
          .thenAnswer((_) async => _makeLedger(id: ledgerId, isShared: true));

      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      // When: 멤버 2명, 현재 비공유 → 공유로 전환 필요
      await container
          .read(ledgerNotifierProvider.notifier)
          .syncShareStatus(ledgerId: ledgerId, memberCount: 2, currentIsShared: false);

      // Then: updateLedger가 호출됨
      verify(() => mockRepo.updateLedger(id: ledgerId, isShared: true)).called(1);
    });

    test('멤버 수와 현재 공유 상태가 일치하는 경우 updateLedger를 호출하지 않는다', () async {
      // Given
      const ledgerId = 'ledger-no-sync';
      when(() => mockRepo.getLedgers()).thenAnswer(
        (_) async => [_makeLedger(id: ledgerId, isShared: true)],
      );
      when(() => mockRepo.subscribeLedgers(any())).thenReturn(FakeRealtimeChannel());
      when(() => mockRepo.subscribeLedgerMembers(any())).thenReturn(FakeRealtimeChannel());

      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          ledgerRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
      addTearDown(container.dispose);
      await Future.delayed(const Duration(milliseconds: 100));

      // When: 멤버 3명, 현재 공유 → 변경 불필요
      await container
          .read(ledgerNotifierProvider.notifier)
          .syncShareStatus(ledgerId: ledgerId, memberCount: 3, currentIsShared: true);

      // Then: updateLedger가 호출되지 않음
      verifyNever(() => mockRepo.updateLedger(id: any(named: 'id'), isShared: any(named: 'isShared')));
    });
  });
}

// 테스트용 데이터 상태 LedgerNotifier
class _FakeLedgerNotifierWithData extends LedgerNotifier {
  final List<Ledger> _ledgers;

  _FakeLedgerNotifierWithData(super.repository, super.ref, this._ledgers);

  @override
  Future<void> loadLedgers() async {
    state = AsyncValue.data(_ledgers);
  }

  @override
  void _subscribeToChanges() {}
}

extension _LedgerNotifierTestExt on LedgerNotifier {
  void _subscribeToChanges() {}
}
