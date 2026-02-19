import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/domain/entities/transaction.dart';

void main() {
  group('Transaction 할부 관련 getter 테스트', () {
    final baseDate = DateTime(2026, 1, 15);
    final baseTransaction = Transaction(
      id: 'test-id',
      ledgerId: 'ledger-id',
      userId: 'user-id',
      amount: 20000,
      type: 'expense',
      date: baseDate,
      isRecurring: false,
      createdAt: baseDate,
      updatedAt: baseDate,
    );

    group('isInstallment getter', () {
      test('title에 "할부" 포함 + isRecurring=true + recurringEndDate 있으면 true를 반환한다', () {
        // Given: 할부 거래 조건 모두 충족
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 6, 15),
        );

        // When & Then
        expect(transaction.isInstallment, true);
      });

      test('title에 "할부"가 없으면 false를 반환한다', () {
        // Given: title에 "할부" 없음
        final transaction = baseTransaction.copyWith(
          title: '일반 거래',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 6, 15),
        );

        // When & Then
        expect(transaction.isInstallment, false);
      });

      test('isRecurring이 false면 false를 반환한다', () {
        // Given: 반복 거래가 아님
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: false,
          recurringEndDate: DateTime(2026, 6, 15),
        );

        // When & Then
        expect(transaction.isInstallment, false);
      });

      test('recurringEndDate가 null이면 false를 반환한다', () {
        // Given: 종료일 없음
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          recurringEndDate: null,
        );

        // When & Then
        expect(transaction.isInstallment, false);
      });

      test('title이 null이면 false를 반환한다', () {
        // Given: title이 null
        final transaction = baseTransaction.copyWith(
          title: null,
          isRecurring: true,
          recurringEndDate: DateTime(2026, 6, 15),
        );

        // When & Then
        expect(transaction.isInstallment, false);
      });
    });

    group('installmentTotalMonths getter', () {
      test('2026-01부터 2026-06까지 할부는 6개월을 반환한다', () {
        // Given: 2026년 1월 ~ 6월 할부
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 6, 15),
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentTotalMonths, 6);
      });

      test('2026-01부터 2026-01까지 할부는 1개월을 반환한다', () {
        // Given: 같은 달 시작/종료
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 1, 15),
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentTotalMonths, 1);
      });

      test('연도를 넘어가는 할부도 정확하게 계산한다 (2025-11부터 2026-02까지 4개월)', () {
        // Given: 연도 경계를 넘는 할부
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 2, 15),
          recurringTemplateStartDate: DateTime(2025, 11, 15),
        );

        // When & Then
        expect(transaction.installmentTotalMonths, 4);
      });

      test('recurringTemplateStartDate가 null이면 createdAt 기반으로 추정한다', () {
        // Given: 템플릿 시작일 없음, createdAt=2026-01-15 -> 추정 시작일=2026-01-01
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          recurringEndDate: DateTime(2026, 6, 15),
          recurringTemplateStartDate: null,
        );

        // When & Then: 2026-01 ~ 2026-06 = 6개월
        expect(transaction.installmentTotalMonths, 6);
      });

      test('isInstallment가 false면 0을 반환한다', () {
        // Given: 할부가 아닌 거래
        final transaction = baseTransaction.copyWith(
          title: '일반 거래',
          isRecurring: false,
          recurringEndDate: null,
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentTotalMonths, 0);
      });
    });

    group('installmentCurrentMonth getter', () {
      test('시작일 2026-01, 거래일 2026-01이면 1회차를 반환한다', () {
        // Given: 첫 번째 달
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          date: DateTime(2026, 1, 15),
          recurringEndDate: DateTime(2026, 6, 15),
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentCurrentMonth, 1);
      });

      test('시작일 2026-01, 거래일 2026-03이면 3회차를 반환한다', () {
        // Given: 세 번째 달
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          date: DateTime(2026, 3, 15),
          recurringEndDate: DateTime(2026, 6, 15),
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentCurrentMonth, 3);
      });

      test('시작일 2026-01, 거래일 2026-06이면 6회차를 반환한다', () {
        // Given: 마지막 달
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          date: DateTime(2026, 6, 15),
          recurringEndDate: DateTime(2026, 6, 15),
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentCurrentMonth, 6);
      });

      test('연도를 넘어가는 할부의 회차도 정확하게 계산한다 (2025-11 시작, 2026-01 거래 = 3회차)', () {
        // Given: 연도 경계를 넘는 할부
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          date: DateTime(2026, 1, 15),
          recurringEndDate: DateTime(2026, 2, 15),
          recurringTemplateStartDate: DateTime(2025, 11, 15),
        );

        // When & Then
        expect(transaction.installmentCurrentMonth, 3);
      });

      test('recurringTemplateStartDate가 null이면 createdAt 기반으로 회차를 추정한다', () {
        // Given: 템플릿 시작일 없음, createdAt=2026-01-15 -> 추정 시작일=2026-01-01
        final transaction = baseTransaction.copyWith(
          title: '카드 할부',
          isRecurring: true,
          date: DateTime(2026, 3, 15),
          recurringEndDate: DateTime(2026, 6, 15),
          recurringTemplateStartDate: null,
        );

        // When & Then: 2026-01 ~ 2026-03 = 3회차
        expect(transaction.installmentCurrentMonth, 3);
      });

      test('isInstallment가 false면 0을 반환한다', () {
        // Given: 할부가 아닌 거래
        final transaction = baseTransaction.copyWith(
          title: '일반 거래',
          isRecurring: false,
          date: DateTime(2026, 3, 15),
          recurringEndDate: null,
          recurringTemplateStartDate: DateTime(2026, 1, 15),
        );

        // When & Then
        expect(transaction.installmentCurrentMonth, 0);
      });
    });
  });
}
