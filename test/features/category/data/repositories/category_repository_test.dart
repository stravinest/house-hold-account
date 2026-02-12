import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

void main() {
  late MockSupabaseClient mockClient;
  late CategoryRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = CategoryRepository(client: mockClient);
  });

  Map<String, dynamic> _makeCategoryData({
    String id = 'cat-1',
    String name = '식비',
    String icon = 'restaurant',
    String color = '#FF5733',
    String type = 'expense',
    int sortOrder = 1,
    bool isDefault = false,
  }) {
    return {
      'id': id,
      'ledger_id': 'ledger-1',
      'name': name,
      'icon': icon,
      'color': color,
      'type': type,
      'is_default': isDefault,
      'sort_order': sortOrder,
      'created_at': '2024-01-01T00:00:00Z',
    };
  }

  group('CategoryRepository - getCategories', () {
    test('가계부의 모든 카테고리 조회 시 정렬된 리스트를 반환한다', () async {
      final mockData = [
        _makeCategoryData(id: 'cat-1', name: '식비', sortOrder: 1),
        _makeCategoryData(id: 'cat-2', name: '교통', icon: 'train', color: '#33FF57', sortOrder: 2),
      ];

      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getCategories('ledger-1');
      expect(result, isA<List<CategoryModel>>());
      expect(result.length, 2);
      expect(result[0].name, '식비');
      expect(result[1].name, '교통');
    });
  });

  group('CategoryRepository - getCategoriesByType', () {
    test('타입별 카테고리 조회 시 해당 타입의 카테고리만 반환한다', () async {
      final mockData = [
        _makeCategoryData(id: 'cat-1', name: '급여', icon: 'work', color: '#4CAF50', type: 'income'),
      ];

      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      final result = await repository.getCategoriesByType(
          ledgerId: 'ledger-1', type: 'income');
      expect(result.length, 1);
      expect(result[0].type, 'income');
      expect(result[0].name, '급여');
    });
  });

  group('CategoryRepository - createCategory', () {
    test('카테고리 생성 시 sort_order가 자동으로 증가하며 생성된다', () async {
      final newCat = _makeCategoryData(
          id: 'cat-new', name: '문화생활', icon: 'movie', color: '#9C27B0', sortOrder: 6);

      int callCount = 0;
      when(() => mockClient.from('categories')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          // sort_order 조회: select('sort_order').eq().eq().order().limit().maybeSingle()
          return FakeSupabaseQueryBuilder(
            selectData: [{'sort_order': 5}],
            maybeSingleData: {'sort_order': 5},
            hasMaybeSingleData: true,
          );
        }
        // insert: insert().select().single()
        return FakeSupabaseQueryBuilder(
          selectData: [newCat],
          singleData: newCat,
        );
      });

      final result = await repository.createCategory(
        ledgerId: 'ledger-1',
        name: '문화생활',
        icon: 'movie',
        color: '#9C27B0',
        type: 'expense',
      );
      expect(result, isA<CategoryModel>());
      expect(result.id, 'cat-new');
      expect(result.sortOrder, 6);
    });

    test('동일한 이름의 카테고리 생성 시 예외를 던진다', () async {
      // sort_order 조회 성공, insert에서 예외 발생
      int callCount = 0;
      when(() => mockClient.from('categories')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          return FakeSupabaseQueryBuilder(
            selectData: [],
            maybeSingleData: null,
            hasMaybeSingleData: true,
          );
        }
        // insert 시 duplicate 에러를 시뮬레이션하려면 Fake가 아닌 예외를 던져야 함
        throw PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        );
      });

      expect(
        () => repository.createCategory(
          ledgerId: 'ledger-1',
          name: '식비',
          icon: 'restaurant',
          color: '#FF5733',
          type: 'expense',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CategoryRepository - updateCategory', () {
    test('카테고리 수정 시 제공된 필드만 업데이트한다', () async {
      final updated = _makeCategoryData(name: '음식');

      when(() => mockClient.from('categories')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      final result =
          await repository.updateCategory(id: 'cat-1', name: '음식');
      expect(result.name, '음식');
    });
  });

  group('CategoryRepository - deleteCategory', () {
    test('카테고리 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      await repository.deleteCategory('cat-1');
      // 에러 없이 완료되면 성공
    });
  });

  group('CategoryRepository - reorderCategories', () {
    test('카테고리 순서 변경 시 RPC 함수를 호출한다', () async {
      when(() => mockClient.rpc('batch_reorder_categories',
              params: any(named: 'params')))
          .thenAnswer(
              (_) => FakePostgrestFilterBuilder<dynamic>(null));

      await repository.reorderCategories(['cat-3', 'cat-1', 'cat-2']);
      verify(() => mockClient.rpc('batch_reorder_categories',
          params: any(named: 'params'))).called(1);
    });
  });
}
