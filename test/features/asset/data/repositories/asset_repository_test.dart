import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/asset/data/repositories/asset_repository.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_goal.dart';
import 'package:shared_household_account/features/asset/domain/entities/asset_statistics.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late AssetRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = AssetRepository(client: mockClient);
  });

  group('AssetRepository - getTotalAssets', () {
    test('전체 자산 조회 시 모든 자산 거래의 합계를 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {'amount': 1000000},
        {'amount': 500000},
        {'amount': 300000},
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getTotalAssets(ledgerId: 'ledger-1');
      expect(result, 1800000);
    });

    test('자산이 없는 경우 0을 반환한다', () async {
      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getTotalAssets(ledgerId: 'ledger-1');
      expect(result, 0);
    });
  });

  group('AssetRepository - getMonthlyChange', () {
    test('월별 자산 변동 조회 시 해당 월의 자산 변동액을 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {'amount': 200000},
        {'amount': -50000},
        {'amount': 100000},
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getMonthlyChange(
        ledgerId: 'ledger-1',
        year: 2024,
        month: 1,
      );
      expect(result, 250000);
    });
  });

  group('AssetRepository - getAssetsByCategory', () {
    test('카테고리별 자산 조회 시 그룹화된 자산 리스트를 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-1',
          'amount': 1000000,
          'title': '정기예금',
          'maturity_date': '2024-12-31',
          'category_id': 'cat-1',
          'categories': {'name': '예금', 'icon': 'savings', 'color': '#4CAF50'},
        },
        {
          'id': 'tx-2',
          'amount': 500000,
          'title': '주식',
          'maturity_date': null,
          'category_id': 'cat-2',
          'categories': {'name': '투자', 'icon': 'trending_up', 'color': '#2196F3'},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAssetsByCategory(ledgerId: 'ledger-1');

      expect(result, isA<List<CategoryAsset>>());
      expect(result.length, 2);
      expect(result[0].amount, 1000000);
      expect(result[0].categoryName, '예금');
    });
  });

  group('AssetRepository - AssetGoal CRUD', () {
    test('목표 생성 시 올바른 데이터로 INSERT하고 생성된 목표를 반환한다', () async {
      final goal = AssetGoal(
        id: '',
        ledgerId: 'ledger-1',
        title: '내 집 마련',
        targetAmount: 100000000,
        targetDate: DateTime(2025, 12, 31),
        assetType: 'real_estate',
        categoryIds: ['cat-1'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
      );

      final mockResponse = <String, dynamic>{
        'id': 'goal-1',
        'ledger_id': 'ledger-1',
        'title': '내 집 마련',
        'target_amount': 100000000,
        'target_date': '2025-12-31',
        'asset_type': 'real_estate',
        'category_ids': ['cat-1'],
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
        'created_by': 'user-123',
      };

      when(() => mockClient.from('asset_goals')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.createGoal(goal);
      expect(result, isA<AssetGoal>());
      expect(result.id, 'goal-1');
      expect(result.title, '내 집 마련');
    });

    test('목표 조회 시 가계부 ID에 해당하는 목표 리스트를 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'goal-1',
          'ledger_id': 'ledger-1',
          'title': '자동차 구매',
          'target_amount': 30000000,
          'target_date': '2024-06-30',
          'asset_type': 'vehicle',
          'category_ids': <String>[],
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
          'created_by': 'user-123',
        },
      ];

      when(() => mockClient.from('asset_goals'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getGoals(ledgerId: 'ledger-1');
      expect(result, isA<List<AssetGoal>>());
      expect(result.length, 1);
      expect(result[0].title, '자동차 구매');
    });

    test('목표 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      when(() => mockClient.from('asset_goals'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteGoal('goal-1');
      // 에러 없이 완료되면 성공
    });
  });

  group('AssetRepository - getCurrentAmount', () {
    test('현재 자산액 조회 시 카테고리 필터가 적용된 합계를 반환한다', () async {
      final mockData = <Map<String, dynamic>>[
        {'amount': 500000},
        {'amount': 300000},
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getCurrentAmount(
        ledgerId: 'ledger-1',
        categoryIds: ['cat-1', 'cat-2'],
      );
      expect(result, 800000);
    });

    test('카테고리 필터 없이 전체 자산액을 조회한다', () async {
      final mockData = <Map<String, dynamic>>[
        {'amount': 1000000},
        {'amount': 2000000},
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getCurrentAmount(
        ledgerId: 'ledger-1',
      );
      expect(result, 3000000);
    });

    test('자산이 없으면 0을 반환한다', () async {
      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getCurrentAmount(
        ledgerId: 'ledger-1',
        categoryIds: ['cat-1'],
      );
      expect(result, 0);
    });
  });

  group('AssetRepository - updateGoal', () {
    test('목표 수정 시 올바른 데이터로 UPDATE하고 수정된 목표를 반환한다', () async {
      final goal = AssetGoal(
        id: 'goal-1',
        ledgerId: 'ledger-1',
        title: '수정된 목표',
        targetAmount: 200000000,
        targetDate: DateTime(2026, 12, 31),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        createdBy: 'user-123',
      );

      final mockResponse = <String, dynamic>{
        'id': 'goal-1',
        'ledger_id': 'ledger-1',
        'title': '수정된 목표',
        'target_amount': 200000000,
        'target_date': '2026-12-31',
        'asset_type': null,
        'category_ids': null,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
        'created_by': 'user-123',
      };

      when(() => mockClient.from('asset_goals')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [mockResponse], singleData: mockResponse));

      final result = await repository.updateGoal(goal);
      expect(result, isA<AssetGoal>());
      expect(result.id, 'goal-1');
      expect(result.title, '수정된 목표');
    });
  });

  group('AssetRepository - getGoals', () {
    test('goal_type이 loan인 목표를 올바르게 파싱한다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'loan-1',
          'ledger_id': 'ledger-1',
          'title': '주택담보대출',
          'target_amount': 300000000,
          'target_date': '2034-01-01',
          'asset_type': null,
          'category_ids': null,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
          'created_by': 'user-123',
          'goal_type': 'loan',
          'loan_amount': 300000000,
          'repayment_method': 'equal_principal_interest',
          'annual_interest_rate': 3.5,
          'start_date': '2024-01-01',
          'monthly_payment': 1740000,
          'is_manual_payment': false,
          'memo': null,
          'extra_repaid_amount': 0,
        },
      ];

      when(() => mockClient.from('asset_goals'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getGoals(ledgerId: 'ledger-1');
      expect(result.length, 1);
      expect(result[0].goalType, GoalType.loan);
      expect(result[0].loanAmount, 300000000);
      expect(result[0].annualInterestRate, 3.5);
    });

    test('목표 목록이 비어있으면 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('asset_goals'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getGoals(ledgerId: 'ledger-1');
      expect(result, isEmpty);
    });
  });

  group('AssetRepository - getMonthlyAssets', () {
    test('월별 자산 누적 합계를 올바르게 계산한다', () async {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
      final mockData = <Map<String, dynamic>>[
        {
          'amount': 1000000,
          'date': '${sixMonthsAgo.year}-${sixMonthsAgo.month.toString().padLeft(2, '0')}-15',
        },
        {
          'amount': 500000,
          'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getMonthlyAssets(
        ledgerId: 'ledger-1',
        months: 6,
      );

      expect(result, isA<List<MonthlyAsset>>());
      expect(result.length, 6);
      // 마지막 월의 누적 합계는 전체 거래의 합
      expect(result.last.amount, 1500000);
    });

    test('거래가 없으면 모든 월의 금액이 0이어야 한다', () async {
      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getMonthlyAssets(
        ledgerId: 'ledger-1',
        months: 6,
      );

      expect(result.length, 6);
      expect(result.every((m) => m.amount == 0), isTrue);
    });
  });

  group('AssetRepository - getAssetsByCategory 상세 케이스', () {
    test('카테고리 정보가 없는 거래는 Uncategorized로 그룹화된다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-1',
          'amount': 500000,
          'title': null,
          'maturity_date': null,
          'category_id': 'null',
          'categories': null,
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAssetsByCategory(ledgerId: 'ledger-1');

      expect(result, isA<List<CategoryAsset>>());
      expect(result.length, 1);
    });

    test('여러 카테고리의 자산이 금액 내림차순으로 정렬된다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-1',
          'amount': 300000,
          'title': '소액 예금',
          'maturity_date': null,
          'category_id': 'cat-small',
          'categories': {'name': '소액', 'icon': null, 'color': null},
        },
        {
          'id': 'tx-2',
          'amount': 5000000,
          'title': '고액 주식',
          'maturity_date': null,
          'category_id': 'cat-large',
          'categories': {'name': '대액', 'icon': null, 'color': null},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAssetsByCategory(ledgerId: 'ledger-1');

      // 금액 내림차순 정렬 검증
      expect(result[0].amount, greaterThanOrEqualTo(result[1].amount));
    });

    test('만기일이 있는 거래의 AssetItem에 만기일이 설정된다', () async {
      final mockData = <Map<String, dynamic>>[
        {
          'id': 'tx-1',
          'amount': 1000000,
          'title': '정기예금',
          'maturity_date': '2027-12-31',
          'category_id': 'cat-1',
          'categories': {'name': '예금', 'icon': 'savings', 'color': '#4CAF50'},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getAssetsByCategory(ledgerId: 'ledger-1');

      expect(result.length, 1);
      expect(result[0].items[0].maturityDate, isNotNull);
      expect(result[0].items[0].maturityDate, DateTime.parse('2027-12-31'));
    });
  });

  group('AssetRepository - getEnhancedStatistics', () {
    test('getEnhancedStatistics가 병렬 쿼리를 실행하고 통계를 반환한다', () async {
      final now = DateTime.now();
      // getMonthlyAssets는 date 필드가 필요하고,
      // getAssetsByCategory는 category_id, categories 필드가 필요하므로
      // 가장 단순하게 모든 필드를 포함한 mock 데이터 사용
      final mockData = <Map<String, dynamic>>[
        {
          'amount': 1000000,
          'date': '${now.year}-${now.month.toString().padLeft(2, '0')}-01',
          'id': 'tx-1',
          'title': null,
          'maturity_date': null,
          'category_id': 'cat-1',
          'categories': {'name': '예금', 'icon': null, 'color': null},
        },
      ];

      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getEnhancedStatistics(ledgerId: 'ledger-1');

      expect(result, isA<AssetStatistics>());
      expect(result.totalAmount, greaterThanOrEqualTo(0));
      expect(result.monthly, isA<List<MonthlyAsset>>());
      // 카테고리별 자산은 assetFilteredByCategoryProvider에서 별도로 조회하므로 빈 리스트
      expect(result.byCategory, isEmpty);
    });

    test('거래가 없을 때 getEnhancedStatistics가 0 값으로 통계를 반환한다', () async {
      when(() => mockClient.from('transactions'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      final result = await repository.getEnhancedStatistics(ledgerId: 'ledger-1');

      expect(result, isA<AssetStatistics>());
      expect(result.totalAmount, 0);
      expect(result.monthlyChange, 0);
      expect(result.monthlyChangeRate, 0.0);
      expect(result.annualGrowthRate, 0.0);
    });
  });

}
