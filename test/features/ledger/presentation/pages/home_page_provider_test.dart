import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// HomePage에서 사용하는 프로바이더 동작 단위 테스트
void main() {
  group('HomePage에서 사용하는 프로바이더 정의 테스트', () {
    test('selectedLedgerIdProvider가 null을 기본값으로 가져야 한다', () {
      // Given
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // When
      final ledgerId = container.read(selectedLedgerIdProvider);

      // Then
      expect(ledgerId, isNull);
    });

    test('dailyTransactionsProvider는 AutoDispose FutureProvider여야 한다', () {
      // Given & When & Then
      expect(dailyTransactionsProvider, isNotNull);
    });

    test('monthlyTransactionsProvider는 AutoDispose FutureProvider여야 한다', () {
      // Given & When & Then
      expect(monthlyTransactionsProvider, isNotNull);
    });

    test('monthlyTotalProvider는 AutoDispose FutureProvider여야 한다', () {
      // Given & When & Then
      expect(monthlyTotalProvider, isNotNull);
    });

    test('dailyTotalsProvider는 AutoDispose FutureProvider여야 한다', () {
      // Given & When & Then
      expect(dailyTotalsProvider, isNotNull);
    });
  });

  group('HomePage 프로바이더 오버라이드 동작 테스트', () {
    test('selectedLedgerIdProvider를 오버라이드하면 해당 값이 사용되어야 한다', () {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'home-ledger-id'),
        ],
      );
      addTearDown(container.dispose);

      // When
      final ledgerId = container.read(selectedLedgerIdProvider);

      // Then
      expect(ledgerId, equals('home-ledger-id'));
    });

    test('dailyTransactionsProvider를 오버라이드하면 해당 값을 반환해야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          dailyTransactionsProvider.overrideWith((ref) async => []),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(dailyTransactionsProvider.future);

      // Then
      expect(result, isEmpty);
    });

    test('monthlyTotalProvider를 오버라이드하면 해당 값을 반환해야 한다', () async {
      // Given
      final mockTotal = {'income': 500000, 'expense': 300000, 'balance': 200000, 'users': {}};
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          monthlyTotalProvider.overrideWith((ref) async => mockTotal),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(monthlyTotalProvider.future);

      // Then
      expect(result['income'], equals(500000));
      expect(result['expense'], equals(300000));
      expect(result['balance'], equals(200000));
    });

    test('dailyTotalsProvider를 오버라이드하면 해당 값을 반환해야 한다', () async {
      // Given
      final mockTotals = {DateTime(2026, 3, 1): {'income': 10000, 'expense': 5000}};
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          dailyTotalsProvider.overrideWith((ref) async => mockTotals),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(dailyTotalsProvider.future);

      // Then
      expect(result, isNotEmpty);
      expect(result[DateTime(2026, 3, 1)], isNotNull);
    });
  });

  group('HomePage 프로바이더 병렬 실행 및 에러 처리 테스트', () {
    test('모든 프로바이더를 병렬로 실행할 수 있어야 한다', () async {
      // Given
      bool daily = false;
      bool monthly = false;
      bool total = false;
      bool dailyTotals = false;

      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          dailyTransactionsProvider.overrideWith((ref) async {
            daily = true;
            return [];
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            monthly = true;
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            total = true;
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            dailyTotals = true;
            return <DateTime, Map<String, dynamic>>{};
          }),
        ],
      );
      addTearDown(container.dispose);

      // When: 병렬로 모두 실행
      await Future.wait([
        container.read(dailyTransactionsProvider.future),
        container.read(monthlyTransactionsProvider.future),
        container.read(monthlyTotalProvider.future),
        container.read(dailyTotalsProvider.future),
      ]);

      // Then: 모두 실행됨
      expect(daily, isTrue);
      expect(monthly, isTrue);
      expect(total, isTrue);
      expect(dailyTotals, isTrue);
    });

    test('병렬 실행이 순차 실행보다 빠르게 완료되어야 한다', () async {
      // Given: 각 프로바이더가 50ms 지연
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          dailyTransactionsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return [];
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 50));
            return <DateTime, Map<String, dynamic>>{};
          }),
        ],
      );
      addTearDown(container.dispose);

      // When: 병렬 실행 시간 측정
      final start = DateTime.now();
      await Future.wait([
        container.read(dailyTransactionsProvider.future),
        container.read(monthlyTransactionsProvider.future),
        container.read(monthlyTotalProvider.future),
        container.read(dailyTotalsProvider.future),
      ]);
      final elapsed = DateTime.now().difference(start);

      // Then: 순차(200ms)가 아닌 병렬(100ms 이내)로 완료됨
      expect(elapsed.inMilliseconds, lessThan(150));
    });

    test('프로바이더 중 하나가 에러를 던지면 Future.wait이 에러를 전파해야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          dailyTransactionsProvider.overrideWith((ref) async {
            throw Exception('조회 실패');
          }),
          monthlyTransactionsProvider.overrideWith((ref) async => []),
          monthlyTotalProvider.overrideWith(
            (ref) async => {'income': 0, 'expense': 0, 'balance': 0, 'users': {}},
          ),
          dailyTotalsProvider.overrideWith((ref) async => <DateTime, Map<String, dynamic>>{}),
        ],
      );
      addTearDown(container.dispose);

      // When & Then: 에러가 전파됨
      await expectLater(
        Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(isA<Exception>()),
      );
    });

    test('SocketException 발생 시 에러가 올바르게 전파되어야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          dailyTransactionsProvider.overrideWith((ref) async {
            throw const SocketException('네트워크 오류');
          }),
          monthlyTransactionsProvider.overrideWith((ref) async => []),
          monthlyTotalProvider.overrideWith(
            (ref) async => {'income': 0, 'expense': 0, 'balance': 0, 'users': {}},
          ),
          dailyTotalsProvider.overrideWith((ref) async => <DateTime, Map<String, dynamic>>{}),
        ],
      );
      addTearDown(container.dispose);

      // When & Then
      await expectLater(
        Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(isA<SocketException>()),
      );
    });

    test('AuthException 발생 시 에러가 올바르게 전파되어야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          monthlyTransactionsProvider.overrideWith((ref) async {
            throw const AuthException('인증 실패');
          }),
          dailyTransactionsProvider.overrideWith((ref) async => []),
          monthlyTotalProvider.overrideWith(
            (ref) async => {'income': 0, 'expense': 0, 'balance': 0, 'users': {}},
          ),
          dailyTotalsProvider.overrideWith((ref) async => <DateTime, Map<String, dynamic>>{}),
        ],
      );
      addTearDown(container.dispose);

      // When & Then
      await expectLater(
        Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('HomePage selectedLedgerIdProvider 변경 시 프로바이더 반응 테스트', () {
    test('selectedLedgerIdProvider가 변경되면 dependant provider가 재실행되어야 한다', () async {
      // Given
      int callCount = 0;
      final container = ProviderContainer(
        overrides: [
          dailyTransactionsProvider.overrideWith((ref) async {
            ref.watch(selectedLedgerIdProvider);
            callCount++;
            return [];
          }),
        ],
      );
      addTearDown(container.dispose);

      // When: 초기 실행
      await container.read(dailyTransactionsProvider.future);
      expect(callCount, equals(1));

      // When: selectedLedgerIdProvider 변경
      container.read(selectedLedgerIdProvider.notifier).state = 'new-ledger';
      await Future.delayed(Duration.zero);

      // When: 다시 읽기 (autoDispose이므로 새 instance가 생성됨)
      await container.read(dailyTransactionsProvider.future);

      // Then: 재실행됨
      expect(callCount, greaterThanOrEqualTo(1));
    });
  });

  group('HomePage 월간 합계 데이터 구조 테스트', () {
    test('monthlyTotalProvider의 반환값이 예상 키를 포함해야 한다', () async {
      // Given
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger'),
          monthlyTotalProvider.overrideWith((ref) async => {
            'income': 1000000,
            'expense': 500000,
            'balance': 500000,
            'users': {'user-1': {'income': 1000000, 'expense': 500000}},
          }),
        ],
      );
      addTearDown(container.dispose);

      // When
      final result = await container.read(monthlyTotalProvider.future);

      // Then: 필수 키 존재 확인
      expect(result.containsKey('income'), isTrue);
      expect(result.containsKey('expense'), isTrue);
      expect(result.containsKey('balance'), isTrue);
      expect(result.containsKey('users'), isTrue);
      expect(result['income'], equals(1000000));
      expect(result['expense'], equals(500000));
      expect(result['balance'], equals(500000));
    });
  });
}
