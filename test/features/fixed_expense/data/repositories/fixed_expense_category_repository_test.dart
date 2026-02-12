import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/core/utils/supabase_error_handler.dart';
import 'package:shared_household_account/features/fixed_expense/data/models/fixed_expense_category_model.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late FixedExpenseCategoryRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = FixedExpenseCategoryRepository(client: mockClient);
  });

  group('FixedExpenseCategoryRepository - getCategories', () {
    test('가계부의 모든 고정비 카테고리를 sort_order 순으로 조회한다', () async {
      final mockData = [
        {
          'id': 'cat-1',
          'ledger_id': 'ledger-1',
          'name': '월세',
          'icon': '🏠',
          'color': '#FF9800',
          'sort_order': 0,
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'cat-2',
          'ledger_id': 'ledger-1',
          'name': '통신비',
          'icon': '📱',
          'color': '#4CAF50',
          'sort_order': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: mockData),
      );

      final result = await repository.getCategories('ledger-1');

      expect(result, isA<List<FixedExpenseCategoryModel>>());
      expect(result.length, 2);
      expect(result[0].name, '월세');
      expect(result[1].name, '통신비');
    });

    test('빈 결과인 경우 빈 리스트를 반환한다', () async {
      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      final result = await repository.getCategories('ledger-1');

      expect(result, isEmpty);
    });
  });

  group('FixedExpenseCategoryRepository - createCategory', () {
    test('고정비 카테고리 생성 시 올바른 sort_order로 생성된다', () async {
      final mockMaxOrderData = {
        'sort_order': 3,
      };

      final mockCreateResponse = {
        'id': 'cat-new',
        'ledger_id': 'ledger-1',
        'name': '보험료',
        'icon': '🛡️',
        'color': '#2196F3',
        'sort_order': 4,
        'created_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: mockMaxOrderData,
          hasMaybeSingleData: true,
          singleData: mockCreateResponse,
        ),
      );

      final result = await repository.createCategory(
        ledgerId: 'ledger-1',
        name: '보험료',
        icon: '🛡️',
        color: '#2196F3',
      );

      expect(result, isA<FixedExpenseCategoryModel>());
      expect(result.name, '보험료');
      expect(result.sortOrder, 4);
    });

    test('카테고리가 없는 경우 sort_order는 1로 설정된다', () async {
      final mockCreateResponse = {
        'id': 'cat-new',
        'ledger_id': 'ledger-1',
        'name': '첫 번째 카테고리',
        'icon': '',
        'color': '#9E9E9E',
        'sort_order': 1,
        'created_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: null,
          hasMaybeSingleData: true,
          singleData: mockCreateResponse,
        ),
      );

      final result = await repository.createCategory(
        ledgerId: 'ledger-1',
        name: '첫 번째 카테고리',
        color: '#9E9E9E',
      );

      expect(result.sortOrder, 1);
    });

    test('중복된 카테고리 이름으로 생성 시 DuplicateItemException을 던진다', () async {
      final mockMaxOrderData = {
        'sort_order': 1,
      };

      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          maybeSingleData: mockMaxOrderData,
          hasMaybeSingleData: true,
        ),
      );

      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => throw PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
      );

      expect(
        () => repository.createCategory(
          ledgerId: 'ledger-1',
          name: '중복 카테고리',
          color: '#FF5733',
        ),
        throwsA(isA<DuplicateItemException>()),
      );
    });
  });

  group('FixedExpenseCategoryRepository - updateCategory', () {
    test('고정비 카테고리 수정 시 제공된 필드만 업데이트된다', () async {
      final mockUpdateResponse = {
        'id': 'cat-1',
        'ledger_id': 'ledger-1',
        'name': '수정된 카테고리',
        'icon': '✨',
        'color': '#E91E63',
        'sort_order': 0,
        'created_at': DateTime.now().toIso8601String(),
      };

      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(singleData: mockUpdateResponse),
      );

      final result = await repository.updateCategory(
        id: 'cat-1',
        name: '수정된 카테고리',
        icon: '✨',
        color: '#E91E63',
      );

      expect(result, isA<FixedExpenseCategoryModel>());
      expect(result.name, '수정된 카테고리');
      expect(result.icon, '✨');
      expect(result.color, '#E91E63');
    });

    test('중복된 이름으로 수정 시 DuplicateItemException을 던진다', () async {
      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => throw PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        ),
      );

      expect(
        () => repository.updateCategory(
          id: 'cat-1',
          name: '중복 카테고리',
        ),
        throwsA(isA<DuplicateItemException>()),
      );
    });
  });

  group('FixedExpenseCategoryRepository - deleteCategory', () {
    test('고정비 카테고리 삭제 시 DELETE 쿼리가 실행된다', () async {
      when(() => mockClient.from('fixed_expense_categories')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(selectData: []),
      );

      await repository.deleteCategory('cat-1');
    });
  });

  // RPC 테스트는 실제 통합 테스트에서 수행

  group('FixedExpenseCategoryRepository - subscribeCategories', () {
    test('실시간 구독 채널이 생성된다', () {
      final mockChannel = MockRealtimeChannel();

      when(() => mockClient.channel('fixed_expense_categories_changes_ledger-1'))
          .thenReturn(mockChannel);

      when(() => mockChannel.onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'house',
            table: 'fixed_expense_categories',
            filter: any(named: 'filter'),
            callback: any(named: 'callback'),
          )).thenReturn(mockChannel);

      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      final channel = repository.subscribeCategories(
        ledgerId: 'ledger-1',
        onCategoryChanged: () {},
      );

      expect(channel, isA<RealtimeChannel>());
    });
  });
}
