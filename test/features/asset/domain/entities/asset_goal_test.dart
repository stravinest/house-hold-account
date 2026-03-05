import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';

void main() {
  group('GoalType 열거형', () {
    test('asset과 loan 두 가지 타입이 있어야 한다', () {
      expect(GoalType.values.length, 2);
      expect(GoalType.values, containsAll([GoalType.asset, GoalType.loan]));
    });
  });

  group('RepaymentMethod 열거형', () {
    test('네 가지 상환 방식이 있어야 한다', () {
      expect(RepaymentMethod.values.length, 4);
      expect(
        RepaymentMethod.values,
        containsAll([
          RepaymentMethod.equalPrincipalInterest,
          RepaymentMethod.equalPrincipal,
          RepaymentMethod.bullet,
          RepaymentMethod.graduated,
        ]),
      );
    });
  });

  group('RepaymentMethodExtension - toJson', () {
    test('equalPrincipalInterest는 equal_principal_interest로 직렬화되어야 한다', () {
      expect(
        RepaymentMethod.equalPrincipalInterest.toJson(),
        'equal_principal_interest',
      );
    });

    test('equalPrincipal은 equal_principal로 직렬화되어야 한다', () {
      expect(RepaymentMethod.equalPrincipal.toJson(), 'equal_principal');
    });

    test('bullet은 bullet으로 직렬화되어야 한다', () {
      expect(RepaymentMethod.bullet.toJson(), 'bullet');
    });

    test('graduated는 graduated로 직렬화되어야 한다', () {
      expect(RepaymentMethod.graduated.toJson(), 'graduated');
    });
  });

  group('RepaymentMethodExtension - fromJson', () {
    test('equal_principal_interest 문자열을 equalPrincipalInterest로 역직렬화해야 한다', () {
      expect(
        RepaymentMethodExtension.fromJson('equal_principal_interest'),
        RepaymentMethod.equalPrincipalInterest,
      );
    });

    test('equal_principal 문자열을 equalPrincipal로 역직렬화해야 한다', () {
      expect(
        RepaymentMethodExtension.fromJson('equal_principal'),
        RepaymentMethod.equalPrincipal,
      );
    });

    test('bullet 문자열을 bullet으로 역직렬화해야 한다', () {
      expect(
        RepaymentMethodExtension.fromJson('bullet'),
        RepaymentMethod.bullet,
      );
    });

    test('graduated 문자열을 graduated로 역직렬화해야 한다', () {
      expect(
        RepaymentMethodExtension.fromJson('graduated'),
        RepaymentMethod.graduated,
      );
    });

    test('알 수 없는 값은 기본값 equalPrincipalInterest를 반환해야 한다', () {
      expect(
        RepaymentMethodExtension.fromJson('unknown_method'),
        RepaymentMethod.equalPrincipalInterest,
      );
    });

    test('toJson -> fromJson 왕복 변환이 일관성 있어야 한다', () {
      for (final method in RepaymentMethod.values) {
        final json = method.toJson();
        final restored = RepaymentMethodExtension.fromJson(json);
        expect(restored, method);
      }
    });
  });

  group('AssetGoal 엔티티', () {
    final now = DateTime(2026, 3, 5);

    test('기본값이 올바르게 설정되어야 한다', () {
      // Given
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'ledger-1',
        title: '비상금',
        targetAmount: 10000000,
        createdAt: now,
        updatedAt: now,
        createdBy: 'user-1',
      );

      // Then
      expect(goal.goalType, GoalType.asset);
      expect(goal.isManualPayment, false);
      expect(goal.extraRepaidAmount, 0);
      expect(goal.targetDate, isNull);
      expect(goal.assetType, isNull);
      expect(goal.categoryIds, isNull);
      expect(goal.loanAmount, isNull);
      expect(goal.repaymentMethod, isNull);
      expect(goal.annualInterestRate, isNull);
      expect(goal.startDate, isNull);
      expect(goal.monthlyPayment, isNull);
      expect(goal.memo, isNull);
      expect(goal.previousInterestRate, isNull);
      expect(goal.rateChangedAt, isNull);
    });

    test('대출 목표 생성 시 대출 관련 필드가 올바르게 설정되어야 한다', () {
      // Given
      final startDate = DateTime(2026, 1, 1);
      final targetDate = DateTime(2034, 1, 1);

      final goal = AssetGoal(
        id: 'loan-1',
        ledgerId: 'ledger-1',
        title: '주택담보대출',
        targetAmount: 300000000,
        createdAt: now,
        updatedAt: now,
        createdBy: 'user-1',
        goalType: GoalType.loan,
        loanAmount: 300000000,
        repaymentMethod: RepaymentMethod.equalPrincipalInterest,
        annualInterestRate: 3.5,
        startDate: startDate,
        targetDate: targetDate,
        monthlyPayment: 1740000,
        isManualPayment: false,
        memo: '1금융권 대출',
        extraRepaidAmount: 5000000,
        previousInterestRate: 3.0,
        rateChangedAt: DateTime(2026, 2, 1),
      );

      // Then
      expect(goal.goalType, GoalType.loan);
      expect(goal.loanAmount, 300000000);
      expect(goal.repaymentMethod, RepaymentMethod.equalPrincipalInterest);
      expect(goal.annualInterestRate, 3.5);
      expect(goal.startDate, startDate);
      expect(goal.targetDate, targetDate);
      expect(goal.monthlyPayment, 1740000);
      expect(goal.isManualPayment, false);
      expect(goal.memo, '1금융권 대출');
      expect(goal.extraRepaidAmount, 5000000);
      expect(goal.previousInterestRate, 3.0);
    });

    group('copyWith', () {
      late AssetGoal baseGoal;

      setUp(() {
        baseGoal = AssetGoal(
          id: 'goal-1',
          ledgerId: 'ledger-1',
          title: '비상금',
          targetAmount: 10000000,
          createdAt: now,
          updatedAt: now,
          createdBy: 'user-1',
        );
      });

      test('title만 변경하면 나머지 필드는 유지되어야 한다', () {
        // When
        final updated = baseGoal.copyWith(title: '긴급자금');

        // Then
        expect(updated.title, '긴급자금');
        expect(updated.id, 'goal-1');
        expect(updated.ledgerId, 'ledger-1');
        expect(updated.targetAmount, 10000000);
        expect(updated.createdBy, 'user-1');
      });

      test('targetAmount만 변경하면 나머지 필드는 유지되어야 한다', () {
        // When
        final updated = baseGoal.copyWith(targetAmount: 20000000);

        // Then
        expect(updated.targetAmount, 20000000);
        expect(updated.title, '비상금');
      });

      test('goalType을 loan으로 변경할 수 있어야 한다', () {
        // When
        final updated = baseGoal.copyWith(goalType: GoalType.loan);

        // Then
        expect(updated.goalType, GoalType.loan);
      });

      test('extraRepaidAmount를 변경할 수 있어야 한다', () {
        // When
        final updated = baseGoal.copyWith(extraRepaidAmount: 1000000);

        // Then
        expect(updated.extraRepaidAmount, 1000000);
      });

      test('repaymentMethod를 변경할 수 있어야 한다', () {
        // When
        final updated = baseGoal.copyWith(
          repaymentMethod: RepaymentMethod.equalPrincipal,
        );

        // Then
        expect(updated.repaymentMethod, RepaymentMethod.equalPrincipal);
      });

      test('annualInterestRate를 변경할 수 있어야 한다', () {
        // When
        final updated = baseGoal.copyWith(annualInterestRate: 4.5);

        // Then
        expect(updated.annualInterestRate, 4.5);
      });

      test('이전 이자율 및 변경일을 설정할 수 있어야 한다', () {
        // Given
        final rateChangedAt = DateTime(2026, 2, 1);

        // When
        final updated = baseGoal.copyWith(
          previousInterestRate: 3.0,
          rateChangedAt: rateChangedAt,
        );

        // Then
        expect(updated.previousInterestRate, 3.0);
        expect(updated.rateChangedAt, rateChangedAt);
      });

      test('인자 없이 copyWith 호출 시 동일한 값을 가진 새 객체를 반환해야 한다', () {
        // When
        final copy = baseGoal.copyWith();

        // Then
        expect(copy.id, baseGoal.id);
        expect(copy.title, baseGoal.title);
        expect(copy.targetAmount, baseGoal.targetAmount);
        expect(copy.goalType, baseGoal.goalType);
      });
    });
  });
}
