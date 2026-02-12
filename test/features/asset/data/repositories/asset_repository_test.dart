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
  });
}
