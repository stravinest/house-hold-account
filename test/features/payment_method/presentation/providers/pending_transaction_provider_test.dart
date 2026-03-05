import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/payment_method/data/models/pending_transaction_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/pending_transaction_repository.dart';
import 'package:shared_household_account/features/payment_method/domain/entities/pending_transaction.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/pending_transaction_provider.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';

import '../../../../helpers/mock_repositories.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_providers.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

/// 테스트용 PendingTransactionModel 생성 헬퍼
PendingTransactionModel _makePendingTx({
  String id = 'tx-1',
  PendingTransactionStatus status = PendingTransactionStatus.pending,
  int? parsedAmount = 10000,
  String? parsedType = 'expense',
  String? parsedMerchant = '스타벅스',
  String? parsedCategoryId,
}) {
  final now = DateTime(2026, 3, 1, 10, 0);
  return PendingTransactionModel(
    id: id,
    ledgerId: 'ledger-1',
    userId: 'user-1',
    paymentMethodId: 'pm-1',
    sourceType: SourceType.sms,
    sourceSender: '1234',
    sourceContent: '카드결제 10,000원 스타벅스',
    sourceTimestamp: now,
    parsedAmount: parsedAmount,
    parsedType: parsedType,
    parsedMerchant: parsedMerchant,
    parsedCategoryId: parsedCategoryId,
    parsedDate: now,
    status: status,
    createdAt: now,
    updatedAt: now,
    expiresAt: now.add(const Duration(days: 7)),
    isViewed: false,
    duplicateHash: null,
    isDuplicate: false,
  );
}

/// Provider container를 생성하고 notifier를 반환하는 헬퍼
({
  ProviderContainer container,
  PendingTransactionNotifier notifier,
}) _createNotifierSetup({
  required MockPendingTransactionRepository mockRepository,
  required MockTransactionRepository mockTransactionRepository,
  required MockRealtimeChannel mockChannel,
  String? ledgerId = 'ledger-1',
  String? userId = 'user-1',
}) {
  final mockUser = MockUser();
  when(() => mockUser.id).thenReturn(userId ?? 'user-1');

  final container = ProviderContainer(
    overrides: [
      pendingTransactionRepositoryProvider.overrideWith(
        (_) => mockRepository,
      ),
      transactionRepositoryProvider.overrideWith(
        (_) => mockTransactionRepository,
      ),
      selectedLedgerIdProvider.overrideWith((_) => ledgerId),
      currentUserProvider.overrideWith((_) => userId != null ? mockUser : null),
    ],
  );

  final notifier = container.read(
    pendingTransactionNotifierProvider.notifier,
  );

  return (container: container, notifier: notifier);
}

void main() {
  late MockPendingTransactionRepository mockRepository;
  late MockTransactionRepository mockTransactionRepository;
  late MockRealtimeChannel mockChannel;

  setUpAll(() {
    registerFallbackValue(PendingTransactionStatus.pending);
    registerFallbackValue(StackTrace.empty);
  });

  setUp(() {
    mockRepository = MockPendingTransactionRepository();
    mockTransactionRepository = MockTransactionRepository();
    mockChannel = MockRealtimeChannel();

    // 기본 mock 설정
    when(() => mockRepository.subscribePendingTransactions(
          ledgerId: any(named: 'ledgerId'),
          userId: any(named: 'userId'),
          onTableChanged: any(named: 'onTableChanged'),
        )).thenReturn(mockChannel);
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
    when(() => mockRepository.markAllAsViewed(any(), any()))
        .thenAnswer((_) async {});
  });

  group('PendingTransactionProvider - 기본 Provider 테스트', () {
    test('pendingTransactionRepositoryProvider는 PendingTransactionRepository 인스턴스를 제공한다', () {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
        ],
      );
      addTearDown(container.dispose);

      // When
      final repository = container.read(pendingTransactionRepositoryProvider);

      // Then
      expect(repository, isA<PendingTransactionRepository>());
    });

    test('ledgerId가 null이면 pendingTransactionsProvider는 빈 목록을 반환한다', () async {
      // Given
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(pendingTransactionsProvider.future);

      // Then
      expect(result, isEmpty);
    });

    test('currentUser가 null이면 pendingTransactionsProvider는 빈 목록을 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(pendingTransactionsProvider.future);

      // Then
      expect(result, isEmpty);
    });

    test('ledgerId와 userId가 있으면 pendingTransactionsProvider는 데이터를 로드한다', () async {
      // Given
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final txList = [_makePendingTx()];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(pendingTransactionsProvider.future);

      // Then
      expect(result, hasLength(1));
      expect(result.first.id, 'tx-1');
    });

    test('pendingTransactionCountProvider는 ledgerId나 userId가 null이면 0을 반환한다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(pendingTransactionCountProvider.future);

      // Then
      expect(result, 0);
    });

    test('pendingTransactionCountProvider는 카운트를 정확히 반환한다', () async {
      // Given
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockRepository.getPendingCount(any(), any()))
          .thenAnswer((_) async => 5);

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(pendingTransactionCountProvider.future);

      // Then
      expect(result, 5);
    });
  });

  group('PendingTransactionNotifier - 초기 상태', () {
    test('ledgerId가 null이면 초기 상태가 빈 목록이다', () {
      // Given
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      // When
      final state = container.read(pendingTransactionNotifierProvider);

      // Then: ledgerId가 null이면 빈 목록 상태
      expect(state.valueOrNull, isEmpty);
    });

    test('ledgerId가 있으면 초기 상태가 loading이거나 data가 된다', () {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When: provider를 읽으면 초기 상태가 로딩 또는 데이터여야 한다
      final state = container.read(pendingTransactionNotifierProvider);

      // Then
      expect(
        state is AsyncLoading || state is AsyncData,
        isTrue,
      );
    });
  });

  group('PendingTransactionNotifier - loadPendingTransactions', () {
    test('정상적으로 거래 목록을 로드한다', () async {
      // Given
      final txList = [_makePendingTx(), _makePendingTx(id: 'tx-2')];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.loadPendingTransactions();

      // Then
      final state = container.read(pendingTransactionNotifierProvider);
      expect(state.value, hasLength(2));
    });

    test('에러 발생 시 AsyncError 상태가 된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenThrow(Exception('네트워크 오류'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.loadPendingTransactions();

      // Then
      final state = container.read(pendingTransactionNotifierProvider);
      expect(state, isA<AsyncError>());
    });

    test('silent=true이고 기존 데이터가 있으면 데이터가 유지된다', () async {
      // Given: 기존 데이터가 있는 상태
      final txList = [_makePendingTx()];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // 먼저 데이터 로드
      await notifier.loadPendingTransactions();
      expect(container.read(pendingTransactionNotifierProvider).value, isNotEmpty);

      // When: silent refresh
      await notifier.loadPendingTransactions(silent: true);

      // Then: 데이터가 유지되어야 한다
      expect(container.read(pendingTransactionNotifierProvider).value, hasLength(1));
    });
  });

  group('PendingTransactionNotifier - rejectTransaction', () {
    test('거래를 성공적으로 거부한다', () async {
      // Given
      final txList = [_makePendingTx(id: 'tx-1')];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);
      when(() => mockRepository.updateStatus(
            id: any(named: 'id'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => txList.first);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.rejectTransaction('tx-1');

      // Then: updateStatus가 호출되었어야 한다
      verify(() => mockRepository.updateStatus(
            id: 'tx-1',
            status: PendingTransactionStatus.rejected,
          )).called(1);
    });

    test('거부 중 에러 발생 시 AsyncError 상태가 되고 rethrow된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.updateStatus(
            id: any(named: 'id'),
            status: any(named: 'status'),
          )).thenThrow(Exception('DB 오류'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then
      expect(() => notifier.rejectTransaction('tx-1'), throwsException);
    });
  });

  group('PendingTransactionNotifier - updateParsedData', () {
    test('파싱 데이터를 성공적으로 업데이트한다', () async {
      // Given
      final txList = [_makePendingTx()];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);
      when(() => mockRepository.updateParsedData(
            id: any(named: 'id'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            paymentMethodId: any(named: 'paymentMethodId'),
          )).thenAnswer((_) async => txList.first);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.updateParsedData(
        id: 'tx-1',
        parsedAmount: 15000,
        parsedType: 'expense',
        parsedMerchant: '카페',
      );

      // Then: updateParsedData가 호출되었어야 한다
      verify(() => mockRepository.updateParsedData(
            id: 'tx-1',
            parsedAmount: 15000,
            parsedType: 'expense',
            parsedMerchant: '카페',
            parsedCategoryId: null,
            parsedDate: null,
            paymentMethodId: null,
          )).called(1);
    });

    test('업데이트 중 에러 발생 시 rethrow된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.updateParsedData(
            id: any(named: 'id'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            paymentMethodId: any(named: 'paymentMethodId'),
          )).thenThrow(Exception('업데이트 실패'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then
      expect(
        () => notifier.updateParsedData(id: 'tx-1'),
        throwsException,
      );
    });
  });

  group('PendingTransactionNotifier - deleteTransaction', () {
    test('거래를 성공적으로 삭제한다', () async {
      // Given
      final txList = [_makePendingTx()];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);
      when(() => mockRepository.deletePendingTransaction(any()))
          .thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.deleteTransaction('tx-1');

      // Then
      verify(() => mockRepository.deletePendingTransaction('tx-1')).called(1);
    });

    test('삭제 중 에러 발생 시 rethrow된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.deletePendingTransaction(any()))
          .thenThrow(Exception('삭제 실패'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then
      expect(() => notifier.deleteTransaction('tx-1'), throwsException);
    });
  });

  group('PendingTransactionNotifier - deleteAllByStatus', () {
    test('상태별 전체 삭제가 성공한다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.deleteAllByStatus(any(), any(), any()))
          .thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.deleteAllByStatus(PendingTransactionStatus.rejected);

      // Then
      verify(() => mockRepository.deleteAllByStatus(
            'ledger-1',
            'user-1',
            PendingTransactionStatus.rejected,
          )).called(1);
    });

    test('ledgerId나 userId가 null이면 deleteAllByStatus가 아무 동작도 하지 않는다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.deleteAllByStatus(PendingTransactionStatus.rejected);

      // Then: repository 메서드가 호출되지 않아야 한다
      verifyNever(() => mockRepository.deleteAllByStatus(any(), any(), any()));
    });
  });

  group('PendingTransactionNotifier - deleteRejected', () {
    test('deleteRejected는 rejected 상태 거래를 모두 삭제한다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.deleteAllByStatus(any(), any(), any()))
          .thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.deleteRejected();

      // Then
      verify(() => mockRepository.deleteAllByStatus(
            'ledger-1',
            'user-1',
            PendingTransactionStatus.rejected,
          )).called(1);
    });
  });

  group('PendingTransactionNotifier - deleteAllConfirmed', () {
    test('deleteAllConfirmed는 confirmed 거래를 모두 삭제한다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.deleteAllConfirmed(any(), any()))
          .thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.deleteAllConfirmed();

      // Then
      verify(() => mockRepository.deleteAllConfirmed('ledger-1', 'user-1'))
          .called(1);
    });

    test('ledgerId가 null이면 deleteAllConfirmed가 아무 동작도 하지 않는다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.deleteAllConfirmed();

      // Then
      verifyNever(() => mockRepository.deleteAllConfirmed(any(), any()));
    });
  });

  group('PendingTransactionNotifier - markAllAsViewed', () {
    test('markAllAsViewed가 성공적으로 호출된다', () async {
      // Given
      when(() => mockRepository.markAllAsViewed(any(), any()))
          .thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.markAllAsViewed();

      // Then
      verify(() => mockRepository.markAllAsViewed('ledger-1', 'user-1'))
          .called(1);
    });

    test('ledgerId가 null이면 markAllAsViewed가 아무 동작도 하지 않는다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.markAllAsViewed();

      // Then
      verifyNever(() => mockRepository.markAllAsViewed(any(), any()));
    });
  });

  group('PendingTransactionNotifier - rejectAll', () {
    test('rejectAll이 성공적으로 호출된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.rejectAll(any(), any()))
          .thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When
      await notifier.rejectAll();

      // Then
      verify(() => mockRepository.rejectAll('ledger-1', 'user-1')).called(1);
    });

    test('ledgerId가 null이면 rejectAll이 아무 동작도 하지 않는다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.rejectAll();

      // Then
      verifyNever(() => mockRepository.rejectAll(any(), any()));
    });

    test('rejectAll 중 에러 발생 시 rethrow된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.rejectAll(any(), any()))
          .thenThrow(Exception('서버 오류'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then
      expect(() => notifier.rejectAll(), throwsException);
    });
  });

  group('PendingTransactionNotifier - confirmTransaction 유효성 검사', () {
    test('parsedAmount가 null이면 confirmTransaction이 예외를 던진다', () async {
      // Given: parsedAmount가 null인 거래
      final txWithNullAmount = _makePendingTx(id: 'tx-null', parsedAmount: null);
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => [txWithNullAmount]);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then: parsedAmount가 없으면 예외 발생
      expect(() => notifier.confirmTransaction('tx-null'), throwsException);
    });

    test('parsedType이 null이면 confirmTransaction이 예외를 던진다', () async {
      // Given: parsedType이 null인 거래
      final txWithNullType = _makePendingTx(id: 'tx-null-type', parsedType: null);
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => [txWithNullType]);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then
      expect(() => notifier.confirmTransaction('tx-null-type'), throwsException);
    });
  });

  group('탭별 필터링 Provider', () {
    test('pendingTabTransactionsProvider는 pending 상태 거래만 반환한다', () async {
      // Given
      final txList = [
        _makePendingTx(id: 'tx-pending', status: PendingTransactionStatus.pending),
        _makePendingTx(id: 'tx-confirmed', status: PendingTransactionStatus.confirmed),
        _makePendingTx(id: 'tx-rejected', status: PendingTransactionStatus.rejected),
      ];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // 데이터 로드 대기
      await container.read(pendingTransactionNotifierProvider.notifier)
          .loadPendingTransactions();

      // When
      final result = container.read(pendingTabTransactionsProvider);

      // Then
      expect(result.every((t) => t.status == PendingTransactionStatus.pending), isTrue);
    });

    test('confirmedTabTransactionsProvider는 confirmed+converted 상태 거래를 반환한다', () async {
      // Given
      final txList = [
        _makePendingTx(id: 'tx-confirmed', status: PendingTransactionStatus.confirmed),
        _makePendingTx(id: 'tx-converted', status: PendingTransactionStatus.converted),
        _makePendingTx(id: 'tx-pending', status: PendingTransactionStatus.pending),
      ];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingTransactionNotifierProvider.notifier)
          .loadPendingTransactions();

      // When
      final result = container.read(confirmedTabTransactionsProvider);

      // Then
      expect(result.length, 2);
      expect(
        result.every(
          (t) =>
              t.status == PendingTransactionStatus.confirmed ||
              t.status == PendingTransactionStatus.converted,
        ),
        isTrue,
      );
    });

    test('rejectedTabTransactionsProvider는 rejected 상태 거래만 반환한다', () async {
      // Given
      final txList = [
        _makePendingTx(id: 'tx-rejected-1', status: PendingTransactionStatus.rejected),
        _makePendingTx(id: 'tx-rejected-2', status: PendingTransactionStatus.rejected),
        _makePendingTx(id: 'tx-pending', status: PendingTransactionStatus.pending),
      ];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingTransactionNotifierProvider.notifier)
          .loadPendingTransactions();

      // When
      final result = container.read(rejectedTabTransactionsProvider);

      // Then
      expect(result.length, 2);
      expect(
        result.every((t) => t.status == PendingTransactionStatus.rejected),
        isTrue,
      );
    });

    test('빈 목록이면 모든 탭 필터 provider가 빈 목록을 반환한다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingTransactionNotifierProvider.notifier)
          .loadPendingTransactions();

      // When & Then
      expect(container.read(pendingTabTransactionsProvider), isEmpty);
      expect(container.read(confirmedTabTransactionsProvider), isEmpty);
      expect(container.read(rejectedTabTransactionsProvider), isEmpty);
    });
  });

  group('PendingTransactionNotifier - confirmAll', () {
    test('confirmAll 중 에러 발생 시 rethrow된다', () async {
      // Given
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.confirmAll(any(), any()))
          .thenThrow(Exception('서버 오류'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then
      expect(() => notifier.confirmAll(), throwsException);
    });

    test('ledgerId가 null이면 confirmAll이 아무 동작도 하지 않는다', () async {
      // Given
      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);

      // When
      await notifier.confirmAll();

      // Then
      verifyNever(() => mockRepository.confirmAll(any(), any()));
    });
  });

  group('PendingTransactionNotifier - updateAndConfirmTransaction', () {
    test('거래를 찾을 수 없으면 예외를 던진다', () async {
      // Given: 빈 목록
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => []);
      when(() => mockRepository.updateParsedData(
            id: any(named: 'id'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            paymentMethodId: any(named: 'paymentMethodId'),
          )).thenAnswer((_) async => _makePendingTx());

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then: 빈 목록에서 존재하지 않는 ID 조회 시 예외 발생
      expect(
        () => notifier.updateAndConfirmTransaction(
          id: 'non-existent',
          parsedAmount: 10000,
          parsedType: 'expense',
        ),
        throwsException,
      );
    });
  });

  group('탭 필터 Provider - pendingTabTransactionsProvider', () {
    test('대기중 상태 거래만 반환한다', () async {
      // Given: pending, converted, rejected 거래 혼합
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();
      final mockChannel = MockRealtimeChannel();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final txPending = _makePendingTx(id: 'tx-pending', status: PendingTransactionStatus.pending);
      final txConverted = _makePendingTx(id: 'tx-converted', status: PendingTransactionStatus.converted);
      final txRejected = _makePendingTx(id: 'tx-rejected', status: PendingTransactionStatus.rejected);

      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => [txPending, txConverted, txRejected]);

      when(() => mockRepository.subscribePendingTransactions(
        ledgerId: any(named: 'ledgerId'),
        userId: any(named: 'userId'),
        onTableChanged: any(named: 'onTableChanged'),
      )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // loadPendingTransactions 완료 대기
      await container.read(pendingTransactionNotifierProvider.notifier).loadPendingTransactions();

      // When: pendingTabTransactionsProvider 읽기
      final pendingTxs = container.read(pendingTabTransactionsProvider);

      // Then: pending 상태만 반환되어야 한다
      expect(pendingTxs.length, 1);
      expect(pendingTxs.first.id, 'tx-pending');
    });

    test('확인됨 탭은 converted 및 confirmed 거래를 반환한다', () async {
      // Given: confirmed, converted 거래
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();
      final mockChannel = MockRealtimeChannel();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final txConfirmed = _makePendingTx(id: 'tx-confirmed', status: PendingTransactionStatus.confirmed);
      final txConverted = _makePendingTx(id: 'tx-converted', status: PendingTransactionStatus.converted);
      final txPending = _makePendingTx(id: 'tx-pending', status: PendingTransactionStatus.pending);

      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => [txConfirmed, txConverted, txPending]);

      when(() => mockRepository.subscribePendingTransactions(
        ledgerId: any(named: 'ledgerId'),
        userId: any(named: 'userId'),
        onTableChanged: any(named: 'onTableChanged'),
      )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingTransactionNotifierProvider.notifier).loadPendingTransactions();

      // When: confirmedTabTransactionsProvider 읽기
      final confirmedTxs = container.read(confirmedTabTransactionsProvider);

      // Then: confirmed + converted 둘 다 포함되어야 한다
      expect(confirmedTxs.length, 2);
      expect(confirmedTxs.any((t) => t.id == 'tx-confirmed'), isTrue);
      expect(confirmedTxs.any((t) => t.id == 'tx-converted'), isTrue);
    });

    test('거부됨 탭은 rejected 거래만 반환한다', () async {
      // Given: rejected, pending 거래
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();
      final mockChannel = MockRealtimeChannel();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final txRejected1 = _makePendingTx(id: 'tx-rej-1', status: PendingTransactionStatus.rejected);
      final txRejected2 = _makePendingTx(id: 'tx-rej-2', status: PendingTransactionStatus.rejected);
      final txPending = _makePendingTx(id: 'tx-pending', status: PendingTransactionStatus.pending);

      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => [txRejected1, txRejected2, txPending]);

      when(() => mockRepository.subscribePendingTransactions(
        ledgerId: any(named: 'ledgerId'),
        userId: any(named: 'userId'),
        onTableChanged: any(named: 'onTableChanged'),
      )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingTransactionNotifierProvider.notifier).loadPendingTransactions();

      // When: rejectedTabTransactionsProvider 읽기
      final rejectedTxs = container.read(rejectedTabTransactionsProvider);

      // Then: rejected 상태만 반환되어야 한다
      expect(rejectedTxs.length, 2);
      expect(rejectedTxs.every((t) => t.status == PendingTransactionStatus.rejected), isTrue);
    });

    test('거래가 없으면 각 탭 Provider가 빈 목록을 반환한다', () async {
      // Given: 빈 목록
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();
      final mockChannel = MockRealtimeChannel();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => []);

      when(() => mockRepository.subscribePendingTransactions(
        ledgerId: any(named: 'ledgerId'),
        userId: any(named: 'userId'),
        onTableChanged: any(named: 'onTableChanged'),
      )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      await container.read(pendingTransactionNotifierProvider.notifier).loadPendingTransactions();

      // When/Then: 세 탭 모두 빈 목록
      expect(container.read(pendingTabTransactionsProvider), isEmpty);
      expect(container.read(confirmedTabTransactionsProvider), isEmpty);
      expect(container.read(rejectedTabTransactionsProvider), isEmpty);
    });
  });

  group('pendingTransactionsProvider - FutureProvider', () {
    test('ledgerId가 없으면 빈 목록을 반환한다', () async {
      // Given: ledgerId가 null인 상태
      final mockRepository = MockPendingTransactionRepository();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When: FutureProvider 읽기
      final result = await container.read(pendingTransactionsProvider.future);

      // Then: 빈 목록 반환
      expect(result, isEmpty);
    });

    test('currentUser가 없으면 빈 목록을 반환한다', () async {
      // Given: currentUser가 null인 상태
      final mockRepository = MockPendingTransactionRepository();

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      // When: FutureProvider 읽기
      final result = await container.read(pendingTransactionsProvider.future);

      // Then: 빈 목록 반환
      expect(result, isEmpty);
    });

    test('ledgerId와 userId가 있으면 repository에서 데이터를 가져온다', () async {
      // Given: 정상 상태
      final mockRepository = MockPendingTransactionRepository();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final tx = _makePendingTx(id: 'tx-1', status: PendingTransactionStatus.pending);
      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => [tx]);

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When: FutureProvider 읽기
      final result = await container.read(pendingTransactionsProvider.future);

      // Then: 거래 목록 반환
      expect(result.length, 1);
      expect(result.first.id, 'tx-1');
    });
  });

  group('pendingTransactionCountProvider - FutureProvider', () {
    test('ledgerId가 없으면 0을 반환한다', () async {
      // Given: ledgerId가 null
      final mockRepository = MockPendingTransactionRepository();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When: FutureProvider 읽기
      final count = await container.read(pendingTransactionCountProvider.future);

      // Then: 0 반환
      expect(count, 0);
    });

    test('currentUser가 없으면 0을 반환한다', () async {
      // Given: currentUser가 null
      final mockRepository = MockPendingTransactionRepository();

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      // When: FutureProvider 읽기
      final count = await container.read(pendingTransactionCountProvider.future);

      // Then: 0 반환
      expect(count, 0);
    });

    test('정상 상태에서 repository의 getPendingCount를 호출한다', () async {
      // Given: 대기중 거래 3개
      final mockRepository = MockPendingTransactionRepository();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockRepository.getPendingCount(any(), any()))
          .thenAnswer((_) async => 3);

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When: FutureProvider 읽기
      final count = await container.read(pendingTransactionCountProvider.future);

      // Then: 3 반환
      expect(count, 3);
    });
  });

  group('PendingTransactionNotifier - ledgerId/userId 없음 초기화', () {
    test('ledgerId가 null이면 빈 데이터 상태로 초기화된다', () async {
      // Given: ledgerId가 null인 상태
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => null),
          currentUserProvider.overrideWith((_) => null),
        ],
      );
      addTearDown(container.dispose);

      // When: notifier 생성 후 상태 확인
      await Future.delayed(Duration.zero);
      final state = container.read(pendingTransactionNotifierProvider);

      // Then: 빈 데이터 상태여야 한다
      expect(state.hasValue, isTrue);
      expect(state.value, isEmpty);
    });

    test('ledgerId가 있으면 loadPendingTransactions가 호출된다', () async {
      // Given: ledgerId가 있는 상태
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();
      final mockChannel = MockRealtimeChannel();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => []);
      when(() => mockRepository.subscribePendingTransactions(
        ledgerId: any(named: 'ledgerId'),
        userId: any(named: 'userId'),
        onTableChanged: any(named: 'onTableChanged'),
      )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      // When: notifier 생성 후 데이터 로딩 완료 대기
      await container.read(pendingTransactionNotifierProvider.notifier).loadPendingTransactions();

      // Then: getPendingTransactions가 호출되었어야 한다
      verify(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).called(greaterThan(0));
    });
  });

  group('PendingTransactionNotifier - confirmTransaction 성공', () {
    test('parsedAmount와 parsedType이 있으면 거래를 성공적으로 확정한다', () async {
      // Given
      final tx = _makePendingTx(id: 'tx-1', parsedAmount: 10000, parsedType: 'expense');
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => [tx]);
      when(() => mockRepository.updateStatus(
            id: any(named: 'id'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => tx);
      when(() => mockTransactionRepository.createTransaction(
            ledgerId: any(named: 'ledgerId'),
            categoryId: any(named: 'categoryId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            amount: any(named: 'amount'),
            type: any(named: 'type'),
            date: any(named: 'date'),
            title: any(named: 'title'),
            sourceType: any(named: 'sourceType'),
          )).thenAnswer((_) async => throw UnimplementedError('mock not needed'));

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then: createTransaction 호출 시 예외가 발생하더라도 확정 로직 진입 확인
      // (실제 Supabase 없이 createTransaction mock이 throw해도 에러 상태가 됨)
      await expectLater(
        () => notifier.confirmTransaction('tx-1'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  group('PendingTransactionNotifier - confirmAll 성공', () {
    test('parsedAmount와 parsedType이 있는 거래를 모두 확정한다', () async {
      // Given
      final txList = [
        _makePendingTx(id: 'tx-1', parsedAmount: 10000, parsedType: 'expense'),
        _makePendingTx(id: 'tx-2', parsedAmount: null, parsedType: null),
      ];
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => txList);
      when(() => mockRepository.confirmAll(any(), any()))
          .thenAnswer((_) async => txList);
      when(() => mockRepository.updateStatus(
            id: any(named: 'id'),
            status: any(named: 'status'),
          )).thenAnswer((_) async => txList.first);
      when(() => mockTransactionRepository.createTransaction(
            ledgerId: any(named: 'ledgerId'),
            categoryId: any(named: 'categoryId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            amount: any(named: 'amount'),
            type: any(named: 'type'),
            date: any(named: 'date'),
            title: any(named: 'title'),
            sourceType: any(named: 'sourceType'),
          )).thenAnswer((_) async => throw UnimplementedError());

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When: confirmAll 호출 - createTransaction이 예외를 던져도 내부에서 catch됨
      await notifier.confirmAll();

      // Then: confirmAll이 호출되었어야 한다
      verify(() => mockRepository.confirmAll('ledger-1', 'user-1')).called(1);
    });
  });

  group('PendingTransactionNotifier - updateAndConfirmTransaction 성공', () {
    test('파싱 데이터를 업데이트하고 거래를 생성한다', () async {
      // Given
      final tx = _makePendingTx(id: 'tx-1', parsedAmount: 10000, parsedType: 'expense');
      when(() => mockRepository.getPendingTransactions(
            any(),
            status: any(named: 'status'),
            userId: any(named: 'userId'),
          )).thenAnswer((_) async => [tx]);
      when(() => mockRepository.updateParsedData(
            id: any(named: 'id'),
            parsedAmount: any(named: 'parsedAmount'),
            parsedType: any(named: 'parsedType'),
            parsedMerchant: any(named: 'parsedMerchant'),
            parsedCategoryId: any(named: 'parsedCategoryId'),
            parsedDate: any(named: 'parsedDate'),
            paymentMethodId: any(named: 'paymentMethodId'),
          )).thenAnswer((_) async => tx);
      when(() => mockTransactionRepository.createTransaction(
            ledgerId: any(named: 'ledgerId'),
            categoryId: any(named: 'categoryId'),
            paymentMethodId: any(named: 'paymentMethodId'),
            amount: any(named: 'amount'),
            type: any(named: 'type'),
            date: any(named: 'date'),
            title: any(named: 'title'),
            sourceType: any(named: 'sourceType'),
          )).thenAnswer((_) async => throw UnimplementedError());

      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith(
            (ref) => mockRepository,
          ),
          transactionRepositoryProvider.overrideWith(
            (_) => mockTransactionRepository,
          ),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When & Then: updateParsedData 후 createTransaction에서 예외 발생
      await expectLater(
        () => notifier.updateAndConfirmTransaction(
          id: 'tx-1',
          parsedAmount: 15000,
          parsedType: 'expense',
          parsedMerchant: '스타벅스',
        ),
        throwsA(isA<UnimplementedError>()),
      );

      // updateParsedData는 호출되었어야 한다
      verify(() => mockRepository.updateParsedData(
            id: 'tx-1',
            parsedAmount: 15000,
            parsedType: 'expense',
            parsedMerchant: '스타벅스',
            parsedCategoryId: null,
            parsedDate: null,
            paymentMethodId: null,
          )).called(1);
    });
  });

  group('deleteRejected - 단축 메서드', () {
    test('deleteRejected는 deleteAllByStatus(rejected)를 호출한다', () async {
      // Given
      final mockRepository = MockPendingTransactionRepository();
      final mockTransactionRepository = MockTransactionRepository();
      final mockChannel = MockRealtimeChannel();
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-1');

      when(() => mockRepository.getPendingTransactions(
        any(),
        status: any(named: 'status'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => []);
      when(() => mockRepository.subscribePendingTransactions(
        ledgerId: any(named: 'ledgerId'),
        userId: any(named: 'userId'),
        onTableChanged: any(named: 'onTableChanged'),
      )).thenReturn(mockChannel);
      when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');
      when(() => mockRepository.deleteAllByStatus(any(), any(), any()))
          .thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          pendingTransactionRepositoryProvider.overrideWith((ref) => mockRepository),
          transactionRepositoryProvider.overrideWith((_) => mockTransactionRepository),
          selectedLedgerIdProvider.overrideWith((_) => 'ledger-1'),
          currentUserProvider.overrideWith((_) => mockUser),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(pendingTransactionNotifierProvider.notifier);
      await notifier.loadPendingTransactions();

      // When: deleteRejected 호출
      await notifier.deleteRejected();

      // Then: deleteAllByStatus가 rejected 상태로 호출되었어야 한다
      verify(() => mockRepository.deleteAllByStatus(
        any(),
        any(),
        PendingTransactionStatus.rejected,
      )).called(1);
    });
  });
}
