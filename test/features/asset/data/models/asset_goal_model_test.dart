import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/asset/data/models/asset_goal_model.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';

void main() {
  group('AssetGoalModel', () {
    final testCreatedAt = DateTime(2026, 2, 12, 10, 0, 0);
    final testUpdatedAt = DateTime(2026, 2, 12, 11, 0, 0);
    final testTargetDate = DateTime(2026, 12, 31);
    final testCategoryIds = ['cat-1', 'cat-2'];

    final assetGoalModel = AssetGoalModel(
      id: 'test-id',
      ledgerId: 'ledger-id',
      title: '내 집 마련',
      targetAmount: 100000000,
      targetDate: testTargetDate,
      assetType: 'real_estate',
      categoryIds: testCategoryIds,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      createdBy: 'user-id',
    );

    test('AssetGoal 엔티티를 확장한다', () {
      expect(assetGoalModel, isA<AssetGoal>());
    });

    group('fromJson', () {
      test('JSON에서 올바르게 역직렬화된다', () {
        final json = {
          'id': 'json-id',
          'ledger_id': 'ledger-id',
          'title': '자동차 구매',
          'target_amount': 50000000,
          'target_date': '2026-12-31',
          'asset_type': 'car',
          'category_ids': ['cat-1', 'cat-2'],
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'creator-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.id, 'json-id');
        expect(result.ledgerId, 'ledger-id');
        expect(result.title, '자동차 구매');
        expect(result.targetAmount, 50000000);
        expect(result.targetDate, DateTime.parse('2026-12-31'));
        expect(result.assetType, 'car');
        expect(result.categoryIds, ['cat-1', 'cat-2']);
        expect(result.createdAt, DateTime.parse('2026-02-12T10:00:00.000'));
        expect(result.updatedAt, DateTime.parse('2026-02-12T11:00:00.000'));
        expect(result.createdBy, 'creator-id');
      });

      test('targetDate가 null인 경우를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': 'savings',
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.targetDate, null);
      });

      test('assetType이 null인 경우를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.assetType, null);
      });

      test('categoryIds가 null인 경우를 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': 'savings',
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.categoryIds, null);
      });

      test('빈 categoryIds 배열을 역직렬화한다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': 'savings',
          'category_ids': [],
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.categoryIds, []);
      });

      test('다양한 날짜 형식을 파싱한다', () {
        final json1 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': '2026-12-31',
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000Z',
          'updated_at': '2026-02-12T11:00:00.000Z',
          'created_by': 'user-id',
        };

        final json2 = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': '2026-12-31',
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00',
          'updated_at': '2026-02-12T11:00:00',
          'created_by': 'user-id',
        };

        final result1 = AssetGoalModel.fromJson(json1);
        final result2 = AssetGoalModel.fromJson(json2);

        expect(result1.createdAt.year, 2026);
        expect(result1.createdAt.month, 2);
        expect(result1.createdAt.day, 12);
        expect(result2.createdAt.year, 2026);
      });
    });

    group('toJson', () {
      test('JSON으로 올바르게 직렬화된다', () {
        final json = assetGoalModel.toJson();

        expect(json['id'], 'test-id');
        expect(json['ledger_id'], 'ledger-id');
        expect(json['title'], '내 집 마련');
        expect(json['target_amount'], 100000000);
        expect(json['target_date'], '2026-12-31');
        expect(json['asset_type'], 'real_estate');
        expect(json['category_ids'], testCategoryIds);
        expect(json['created_at'], isA<String>());
        expect(json['updated_at'], isA<String>());
        expect(json['created_by'], 'user-id');
      });

      test('targetDate가 DATE 형식(YYYY-MM-DD)으로 직렬화된다', () {
        final json = assetGoalModel.toJson();

        expect(json['target_date'], '2026-12-31');
      });

      test('targetDate가 null인 경우 포함되지 않는다', () {
        final model = AssetGoalModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          title: '목표',
          targetAmount: 1000000,
          targetDate: null,
          assetType: 'savings',
          categoryIds: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          createdBy: 'user-id',
        );

        final json = model.toJson();

        expect(json.containsKey('target_date'), false);
      });

      test('모든 필드가 JSON에 포함된다', () {
        final json = assetGoalModel.toJson();

        expect(json.containsKey('id'), true);
        expect(json.containsKey('ledger_id'), true);
        expect(json.containsKey('title'), true);
        expect(json.containsKey('target_amount'), true);
        expect(json.containsKey('target_date'), true);
        expect(json.containsKey('asset_type'), true);
        expect(json.containsKey('category_ids'), true);
        expect(json.containsKey('created_at'), true);
        expect(json.containsKey('updated_at'), true);
        expect(json.containsKey('created_by'), true);
      });
    });

    group('toInsertJson', () {
      test('삽입용 JSON을 올바르게 만든다', () {
        final json = assetGoalModel.toInsertJson();

        expect(json['ledger_id'], 'ledger-id');
        expect(json['title'], '내 집 마련');
        expect(json['target_amount'], 100000000);
        expect(json['target_date'], '2026-12-31');
        expect(json['asset_type'], 'real_estate');
        expect(json['category_ids'], testCategoryIds);
        expect(json['created_by'], 'user-id');
      });

      test('id, created_at, updated_at은 포함되지 않는다', () {
        final json = assetGoalModel.toInsertJson();

        expect(json.containsKey('id'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('updated_at'), false);
      });

      test('targetDate가 null인 경우 포함되지 않는다', () {
        final model = AssetGoalModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          title: '목표',
          targetAmount: 1000000,
          targetDate: null,
          assetType: 'savings',
          categoryIds: ['cat-1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          createdBy: 'user-id',
        );

        final json = model.toInsertJson();

        expect(json.containsKey('target_date'), false);
      });

      test('assetType이 null인 경우 포함되지 않는다', () {
        final model = AssetGoalModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          title: '목표',
          targetAmount: 1000000,
          targetDate: testTargetDate,
          assetType: null,
          categoryIds: ['cat-1'],
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          createdBy: 'user-id',
        );

        final json = model.toInsertJson();

        expect(json.containsKey('asset_type'), false);
      });

      test('categoryIds가 null인 경우 포함되지 않는다', () {
        final model = AssetGoalModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          title: '목표',
          targetAmount: 1000000,
          targetDate: testTargetDate,
          assetType: 'savings',
          categoryIds: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          createdBy: 'user-id',
        );

        final json = model.toInsertJson();

        expect(json.containsKey('category_ids'), false);
      });
    });

    group('toUpdateJson', () {
      test('업데이트용 JSON을 올바르게 만든다', () {
        final json = assetGoalModel.toUpdateJson();

        expect(json['title'], '내 집 마련');
        expect(json['target_amount'], 100000000);
        expect(json['target_date'], '2026-12-31');
        expect(json['asset_type'], 'real_estate');
        expect(json['category_ids'], testCategoryIds);
        expect(json['updated_at'], isA<String>());
      });

      test('id, ledger_id, created_at, created_by는 포함되지 않는다', () {
        final json = assetGoalModel.toUpdateJson();

        expect(json.containsKey('id'), false);
        expect(json.containsKey('ledger_id'), false);
        expect(json.containsKey('created_at'), false);
        expect(json.containsKey('created_by'), false);
      });

      test('targetDate가 null인 경우 포함되지 않는다', () {
        final model = AssetGoalModel(
          id: 'test-id',
          ledgerId: 'ledger-id',
          title: '목표',
          targetAmount: 1000000,
          targetDate: null,
          assetType: 'savings',
          categoryIds: null,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          createdBy: 'user-id',
        );

        final json = model.toUpdateJson();

        expect(json.containsKey('target_date'), false);
      });

      test('updated_at이 포함된다', () {
        final json = assetGoalModel.toUpdateJson();

        expect(json.containsKey('updated_at'), true);
        expect(json['updated_at'], isA<String>());
      });
    });

    group('fromJson -> toJson 왕복 변환', () {
      test('데이터가 손실 없이 변환된다', () {
        final originalJson = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '내 집 마련',
          'target_amount': 100000000,
          'target_date': '2026-12-31',
          'asset_type': 'real_estate',
          'category_ids': ['cat-1', 'cat-2'],
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final model = AssetGoalModel.fromJson(originalJson);
        final convertedJson = model.toJson();

        expect(convertedJson['id'], originalJson['id']);
        expect(convertedJson['ledger_id'], originalJson['ledger_id']);
        expect(convertedJson['title'], originalJson['title']);
        expect(convertedJson['target_amount'], originalJson['target_amount']);
        expect(convertedJson['target_date'], originalJson['target_date']);
        expect(convertedJson['asset_type'], originalJson['asset_type']);
        expect(convertedJson['category_ids'], originalJson['category_ids']);
        expect(convertedJson['created_by'], originalJson['created_by']);
      });
    });

    group('엣지 케이스', () {
      test('빈 문자열 제목을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.title, '');
      });

      test('매우 긴 제목을 처리할 수 있다', () {
        final longTitle = '목표' * 500;
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': longTitle,
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.title, longTitle);
      });

      test('0원 목표 금액을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 0,
          'target_date': null,
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.targetAmount, 0);
      });

      test('매우 큰 목표 금액을 처리할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 9999999999999,
          'target_date': null,
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.targetAmount, 9999999999999);
      });

      test('많은 카테고리 ID를 처리할 수 있다', () {
        final manyIds = List.generate(100, (index) => 'cat-$index');
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': null,
          'category_ids': manyIds,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.categoryIds, manyIds);
        expect(result.categoryIds!.length, 100);
      });

      test('과거 날짜를 목표 날짜로 설정할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': '2020-01-01',
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.targetDate, DateTime.parse('2020-01-01'));
      });

      test('먼 미래 날짜를 목표 날짜로 설정할 수 있다', () {
        final json = {
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': '2100-12-31',
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-02-12T10:00:00.000',
          'updated_at': '2026-02-12T11:00:00.000',
          'created_by': 'user-id',
        };

        final result = AssetGoalModel.fromJson(json);

        expect(result.targetDate, DateTime.parse('2100-12-31'));
      });
    });

    group('대출 목표(GoalType.loan) 직렬화/역직렬화', () {
      final loanJson = <String, dynamic>{
        'id': 'loan-goal-1',
        'ledger_id': 'ledger-id',
        'title': '주택담보대출',
        'target_amount': 300000000,
        'target_date': '2034-01-01',
        'asset_type': null,
        'category_ids': null,
        'created_at': '2026-01-01T00:00:00.000',
        'updated_at': '2026-01-01T00:00:00.000',
        'created_by': 'user-id',
        'goal_type': 'loan',
        'loan_amount': 300000000,
        'repayment_method': 'equal_principal_interest',
        'annual_interest_rate': 3.5,
        'start_date': '2026-01-01',
        'monthly_payment': 1740000,
        'is_manual_payment': false,
        'memo': '1금융권 대출',
        'extra_repaid_amount': 5000000,
        'previous_interest_rate': 3.0,
        'rate_changed_at': '2026-02-01',
      };

      test('loan 타입 JSON을 올바르게 역직렬화한다', () {
        final result = AssetGoalModel.fromJson(loanJson);

        expect(result.goalType, GoalType.loan);
        expect(result.loanAmount, 300000000);
        expect(result.repaymentMethod, RepaymentMethod.equalPrincipalInterest);
        expect(result.annualInterestRate, 3.5);
        expect(result.startDate, DateTime.parse('2026-01-01'));
        expect(result.monthlyPayment, 1740000);
        expect(result.isManualPayment, false);
        expect(result.memo, '1금융권 대출');
        expect(result.extraRepaidAmount, 5000000);
        expect(result.previousInterestRate, 3.0);
        expect(result.rateChangedAt, DateTime.parse('2026-02-01'));
      });

      test('goal_type이 loan이면 GoalType.loan으로 역직렬화된다', () {
        final json = Map<String, dynamic>.from(loanJson)
          ..['goal_type'] = 'loan';
        final result = AssetGoalModel.fromJson(json);
        expect(result.goalType, GoalType.loan);
      });

      test('goal_type이 asset이면 GoalType.asset으로 역직렬화된다', () {
        final json = Map<String, dynamic>.from(loanJson)
          ..['goal_type'] = 'asset';
        final result = AssetGoalModel.fromJson(json);
        expect(result.goalType, GoalType.asset);
      });

      test('goal_type이 null이면 GoalType.asset(기본값)으로 역직렬화된다', () {
        final json = <String, dynamic>{
          'id': 'test-id',
          'ledger_id': 'ledger-id',
          'title': '목표',
          'target_amount': 1000000,
          'target_date': null,
          'asset_type': null,
          'category_ids': null,
          'created_at': '2026-01-01T00:00:00.000',
          'updated_at': '2026-01-01T00:00:00.000',
          'created_by': 'user-id',
        };
        final result = AssetGoalModel.fromJson(json);
        expect(result.goalType, GoalType.asset);
      });

      test('모든 대출 상환 방식이 올바르게 역직렬화된다', () {
        final methods = {
          'equal_principal_interest': RepaymentMethod.equalPrincipalInterest,
          'equal_principal': RepaymentMethod.equalPrincipal,
          'bullet': RepaymentMethod.bullet,
          'graduated': RepaymentMethod.graduated,
        };

        for (final entry in methods.entries) {
          final json = Map<String, dynamic>.from(loanJson)
            ..['repayment_method'] = entry.key;
          final result = AssetGoalModel.fromJson(json);
          expect(result.repaymentMethod, entry.value);
        }
      });

      test('repayment_method가 null이면 null로 역직렬화된다', () {
        final json = Map<String, dynamic>.from(loanJson)
          ..['repayment_method'] = null;
        final result = AssetGoalModel.fromJson(json);
        expect(result.repaymentMethod, isNull);
      });

      test('is_manual_payment가 true인 경우를 역직렬화한다', () {
        final json = Map<String, dynamic>.from(loanJson)
          ..['is_manual_payment'] = true;
        final result = AssetGoalModel.fromJson(json);
        expect(result.isManualPayment, true);
      });

      test('extra_repaid_amount가 없으면 기본값 0으로 역직렬화된다', () {
        final json = Map<String, dynamic>.from(loanJson)
          ..remove('extra_repaid_amount');
        final result = AssetGoalModel.fromJson(json);
        expect(result.extraRepaidAmount, 0);
      });

      test('annual_interest_rate가 정수 형태로 제공되어도 double로 변환된다', () {
        final json = Map<String, dynamic>.from(loanJson)
          ..['annual_interest_rate'] = 4;
        final result = AssetGoalModel.fromJson(json);
        expect(result.annualInterestRate, 4.0);
        expect(result.annualInterestRate, isA<double>());
      });

      test('대출 목표를 toInsertJson으로 직렬화하면 대출 필드가 포함된다', () {
        final loanModel = AssetGoalModel(
          id: 'loan-1',
          ledgerId: 'ledger-id',
          title: '주택담보대출',
          targetAmount: 300000000,
          targetDate: DateTime(2034, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          createdBy: 'user-id',
          goalType: GoalType.loan,
          loanAmount: 300000000,
          repaymentMethod: RepaymentMethod.equalPrincipalInterest,
          annualInterestRate: 3.5,
          startDate: DateTime(2026, 1, 1),
          monthlyPayment: 1740000,
          isManualPayment: false,
          memo: '메모',
          extraRepaidAmount: 0,
        );

        final json = loanModel.toInsertJson();

        expect(json['goal_type'], 'loan');
        expect(json['loan_amount'], 300000000);
        expect(json['repayment_method'], 'equal_principal_interest');
        expect(json['annual_interest_rate'], 3.5);
        expect(json['monthly_payment'], 1740000);
        expect(json['is_manual_payment'], false);
        expect(json['memo'], '메모');
        expect(json['extra_repaid_amount'], 0);
      });

      test('대출 목표를 toUpdateJson으로 직렬화하면 대출 필드가 포함된다', () {
        final loanModel = AssetGoalModel(
          id: 'loan-1',
          ledgerId: 'ledger-id',
          title: '주택담보대출',
          targetAmount: 300000000,
          targetDate: DateTime(2034, 1, 1),
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
          createdBy: 'user-id',
          goalType: GoalType.loan,
          loanAmount: 300000000,
          repaymentMethod: RepaymentMethod.bullet,
          annualInterestRate: 2.5,
          startDate: DateTime(2026, 1, 1),
          isManualPayment: true,
          extraRepaidAmount: 10000000,
          previousInterestRate: 3.0,
          rateChangedAt: DateTime(2026, 2, 1),
        );

        final json = loanModel.toUpdateJson();

        expect(json['goal_type'], 'loan');
        expect(json['loan_amount'], 300000000);
        expect(json['repayment_method'], 'bullet');
        expect(json['annual_interest_rate'], 2.5);
        expect(json['is_manual_payment'], true);
        expect(json['extra_repaid_amount'], 10000000);
        expect(json['previous_interest_rate'], 3.0);
      });
    });
  });
}
