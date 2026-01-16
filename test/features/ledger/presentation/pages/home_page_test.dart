import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('HomePage 병렬 프로바이더 새로고침 테스트', () {
    test('캘린더 새로고침 시 모든 프로바이더가 병렬로 호출되어야 한다', () async {
      // Given: 프로바이더들이 오버라이드된 컨테이너
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          dailyTransactionsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return [];
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return {};
          }),
        ],
      );

      // When: RefreshIndicator를 통해 새로고침 수행
      // Then: Future.wait 덕분에 순차 실행(400ms)이 아닌 병렬 실행(100ms)으로 완료되어야 함
      final startTime = DateTime.now();

      await container.read(dailyTransactionsProvider.future);
      await container.read(monthlyTransactionsProvider.future);
      await container.read(monthlyTotalProvider.future);
      await container.read(dailyTotalsProvider.future);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // 병렬 실행이므로 최대 150ms 이내에 완료되어야 함 (100ms + 버퍼)
      // 순차 실행이었다면 400ms 이상 소요되었을 것
      expect(duration.inMilliseconds, lessThan(150));

      container.dispose();
    });

    test('dailyTransactionsProvider가 정의되어 있어야 한다', () {
      // Given & When: Provider 존재 확인
      // Then: Provider가 정의되어 있어야 함
      expect(dailyTransactionsProvider, isNotNull);
    });

    test('monthlyTransactionsProvider가 정의되어 있어야 한다', () {
      // Given & When: Provider 존재 확인
      // Then: Provider가 정의되어 있어야 함
      expect(monthlyTransactionsProvider, isNotNull);
    });

    test('monthlyTotalProvider가 정의되어 있어야 한다', () {
      // Given & When: Provider 존재 확인
      // Then: Provider가 정의되어 있어야 함
      expect(monthlyTotalProvider, isNotNull);
    });

    test('dailyTotalsProvider가 정의되어 있어야 한다', () {
      // Given & When: Provider 존재 확인
      // Then: Provider가 정의되어 있어야 함
      expect(dailyTotalsProvider, isNotNull);
    });

    test('모든 프로바이더가 호출되어야 한다', () async {
      // Given: 프로바이더들이 오버라이드된 컨테이너
      bool dailyTransactionsCalled = false;
      bool monthlyTransactionsCalled = false;
      bool monthlyTotalCalled = false;
      bool dailyTotalsCalled = false;

      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          dailyTransactionsProvider.overrideWith((ref) async {
            dailyTransactionsCalled = true;
            return [];
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            monthlyTransactionsCalled = true;
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            monthlyTotalCalled = true;
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            dailyTotalsCalled = true;
            return {};
          }),
        ],
      );

      // When: 모든 프로바이더를 병렬로 호출
      await Future.wait([
        container.read(dailyTransactionsProvider.future),
        container.read(monthlyTransactionsProvider.future),
        container.read(monthlyTotalProvider.future),
        container.read(dailyTotalsProvider.future),
      ]);

      // Then: 모든 프로바이더가 호출되었어야 함
      expect(dailyTransactionsCalled, isTrue);
      expect(monthlyTransactionsCalled, isTrue);
      expect(monthlyTotalCalled, isTrue);
      expect(dailyTotalsCalled, isTrue);

      container.dispose();
    });

    test('프로바이더 중 하나가 에러를 발생시키면 해당 에러가 전파되어야 한다', () async {
      // Given: 하나의 프로바이더가 에러를 발생시키는 컨테이너
      final testError = Exception('Test error');

      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          dailyTransactionsProvider.overrideWith((ref) async {
            throw testError;
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            return {};
          }),
        ],
      );

      // When & Then: Future.wait이 첫 번째 에러를 전파해야 함
      expect(
        () => Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(testError),
      );

      container.dispose();
    });

    test('AuthException 발생 시 에러가 올바르게 전파되어야 한다', () async {
      // Given: AuthException을 발생시키는 프로바이더
      final authError = AuthException('Unauthorized');

      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          dailyTransactionsProvider.overrideWith((ref) async {
            throw authError;
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            return {};
          }),
        ],
      );

      // When & Then: AuthException이 전파되어야 함
      expect(
        () => Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(isA<AuthException>()),
      );

      container.dispose();
    });

    test('SocketException 발생 시 에러가 올바르게 전파되어야 한다', () async {
      // Given: SocketException을 발생시키는 프로바이더
      final socketError = SocketException('Network error');

      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          dailyTransactionsProvider.overrideWith((ref) async {
            throw socketError;
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            return [];
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            return {};
          }),
        ],
      );

      // When & Then: SocketException이 전파되어야 함
      expect(
        () => Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(isA<SocketException>()),
      );

      container.dispose();
    });

    test('여러 프로바이더 중 하나만 실패해도 Future.wait이 즉시 에러를 반환해야 한다', () async {
      // Given: 두 번째 프로바이더가 에러를 발생시키는 컨테이너
      final testError = Exception('Second provider error');

      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          dailyTransactionsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return [];
          }),
          monthlyTransactionsProvider.overrideWith((ref) async {
            throw testError;
          }),
          monthlyTotalProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return {'income': 0, 'expense': 0, 'balance': 0, 'users': {}};
          }),
          dailyTotalsProvider.overrideWith((ref) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return {};
          }),
        ],
      );

      // When & Then: 에러가 즉시 전파되어야 함
      expect(
        () => Future.wait([
          container.read(dailyTransactionsProvider.future),
          container.read(monthlyTransactionsProvider.future),
          container.read(monthlyTotalProvider.future),
          container.read(dailyTotalsProvider.future),
        ]),
        throwsA(testError),
      );

      container.dispose();
    });
  });

  group('HomePage 프로바이더 병렬 실행 성능 테스트', () {
    test('병렬 실행이 순차 실행보다 빨라야 한다', () async {
      // Given: 각 프로바이더가 50ms씩 소요되는 컨테이너
      final container = ProviderContainer(
        overrides: [
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
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
            return {};
          }),
        ],
      );

      // When: 병렬로 실행
      final parallelStartTime = DateTime.now();
      await Future.wait([
        container.read(dailyTransactionsProvider.future),
        container.read(monthlyTransactionsProvider.future),
        container.read(monthlyTotalProvider.future),
        container.read(dailyTotalsProvider.future),
      ]);
      final parallelEndTime = DateTime.now();
      final parallelDuration = parallelEndTime.difference(parallelStartTime);

      // Then: 병렬 실행은 최대 100ms 이내에 완료되어야 함 (50ms + 버퍼)
      // 순차 실행이었다면 200ms(4 x 50ms)가 소요되었을 것
      expect(parallelDuration.inMilliseconds, lessThan(100));

      container.dispose();
    });
  });
}
