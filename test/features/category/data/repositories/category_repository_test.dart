import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/core/utils/supabase_error_handler.dart';
import 'package:shared_household_account/features/category/data/models/category_model.dart';
import 'package:shared_household_account/features/category/data/repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

class FakePostgresChangeFilter extends Fake implements PostgresChangeFilter {}

void main() {
  late MockSupabaseClient mockClient;
  late CategoryRepository repository;

  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(FakePostgresChangeFilter());
  });

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
    String ledgerId = 'ledger-1',
  }) {
    return {
      'id': id,
      'ledger_id': ledgerId,
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
      // Given
      final mockData = [
        _makeCategoryData(id: 'cat-1', name: '식비', sortOrder: 1),
        _makeCategoryData(id: 'cat-2', name: '교통', icon: 'train', color: '#33FF57', sortOrder: 2),
      ];

      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      // When
      final result = await repository.getCategories('ledger-1');

      // Then
      expect(result, isA<List<CategoryModel>>());
      expect(result.length, 2);
      expect(result[0].name, '식비');
      expect(result[1].name, '교통');
    });

    test('카테고리가 없을 때 빈 리스트를 반환한다', () async {
      // Given
      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When
      final result = await repository.getCategories('ledger-1');

      // Then
      expect(result, isEmpty);
    });
  });

  group('CategoryRepository - getCategoriesByType', () {
    test('타입별 카테고리 조회 시 해당 타입의 카테고리만 반환한다', () async {
      // Given
      final mockData = [
        _makeCategoryData(id: 'cat-1', name: '급여', icon: 'work', color: '#4CAF50', type: 'income'),
      ];

      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      // When
      final result = await repository.getCategoriesByType(
          ledgerId: 'ledger-1', type: 'income');

      // Then
      expect(result.length, 1);
      expect(result[0].type, 'income');
      expect(result[0].name, '급여');
    });

    test('자산 타입 카테고리를 조회한다', () async {
      // Given
      final mockData = [
        _makeCategoryData(id: 'cat-1', name: '정기예금', icon: 'savings', color: '#2196F3', type: 'asset'),
      ];

      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: mockData));

      // When
      final result = await repository.getCategoriesByType(
          ledgerId: 'ledger-1', type: 'asset');

      // Then
      expect(result.length, 1);
      expect(result[0].type, 'asset');
    });
  });

  group('CategoryRepository - createCategory', () {
    test('카테고리 생성 시 sort_order가 자동으로 증가하며 생성된다', () async {
      // Given
      final newCat = _makeCategoryData(
          id: 'cat-new', name: '문화생활', icon: 'movie', color: '#9C27B0', sortOrder: 6);

      int callCount = 0;
      when(() => mockClient.from('categories')).thenAnswer((_) {
        callCount++;
        if (callCount == 1) {
          // sort_order 조회
          return FakeSupabaseQueryBuilder(
            selectData: [{'sort_order': 5}],
            maybeSingleData: {'sort_order': 5},
            hasMaybeSingleData: true,
          );
        }
        // insert 결과
        return FakeSupabaseQueryBuilder(
          selectData: [newCat],
          singleData: newCat,
        );
      });

      // When
      final result = await repository.createCategory(
        ledgerId: 'ledger-1',
        name: '문화생활',
        icon: 'movie',
        color: '#9C27B0',
        type: 'expense',
      );

      // Then
      expect(result, isA<CategoryModel>());
      expect(result.id, 'cat-new');
      expect(result.sortOrder, 6);
    });

    test('기존 카테고리가 없을 때 sort_order 1로 생성된다', () async {
      // Given: maybeSingle이 null 반환 (기존 카테고리 없음)
      final newCat = _makeCategoryData(
          id: 'cat-new', name: '첫번째', icon: 'star', color: '#FF0000', sortOrder: 1);

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
        return FakeSupabaseQueryBuilder(
          selectData: [newCat],
          singleData: newCat,
        );
      });

      // When
      final result = await repository.createCategory(
        ledgerId: 'ledger-1',
        name: '첫번째',
        icon: 'star',
        color: '#FF0000',
        type: 'income',
      );

      // Then
      expect(result.id, 'cat-new');
    });

    test('동일한 이름의 카테고리 생성 시 DuplicateItemException을 던진다', () async {
      // Given: insert에서 duplicate 에러 발생
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
        throw PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        );
      });

      // When & Then
      await expectLater(
        () => repository.createCategory(
          ledgerId: 'ledger-1',
          name: '식비',
          icon: 'restaurant',
          color: '#FF5733',
          type: 'expense',
        ),
        throwsA(isA<DuplicateItemException>()),
      );
    });

    test('일반 에러 발생 시 그대로 rethrow한다', () async {
      // Given: 일반 예외 발생
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
        throw PostgrestException(
          message: '권한 없음',
          code: '42501',
        );
      });

      // When & Then
      await expectLater(
        () => repository.createCategory(
          ledgerId: 'ledger-1',
          name: '테스트',
          icon: 'test',
          color: '#000000',
          type: 'expense',
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });

  group('CategoryRepository - updateCategory', () {
    test('이름만 업데이트할 때 name 필드만 포함된 요청을 보낸다', () async {
      // Given
      final updated = _makeCategoryData(name: '음식');

      when(() => mockClient.from('categories')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      // When
      final result = await repository.updateCategory(id: 'cat-1', name: '음식');

      // Then
      expect(result.name, '음식');
    });

    test('아이콘만 업데이트할 때 icon 필드만 포함된 요청을 보낸다', () async {
      // Given
      final updated = _makeCategoryData(icon: 'local_dining');

      when(() => mockClient.from('categories')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      // When
      final result = await repository.updateCategory(id: 'cat-1', icon: 'local_dining');

      // Then
      expect(result.icon, 'local_dining');
    });

    test('색상만 업데이트할 때 color 필드만 포함된 요청을 보낸다', () async {
      // Given
      final updated = _makeCategoryData(color: '#00FF00');

      when(() => mockClient.from('categories')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      // When
      final result = await repository.updateCategory(id: 'cat-1', color: '#00FF00');

      // Then
      expect(result.color, '#00FF00');
    });

    test('sortOrder를 업데이트할 수 있다', () async {
      // Given
      final updated = _makeCategoryData(sortOrder: 5);

      when(() => mockClient.from('categories')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      // When
      final result = await repository.updateCategory(id: 'cat-1', sortOrder: 5);

      // Then
      expect(result.sortOrder, 5);
    });

    test('모든 필드를 한 번에 업데이트할 수 있다', () async {
      // Given
      final updated = _makeCategoryData(
        name: '새이름',
        icon: 'new_icon',
        color: '#FFFFFF',
        sortOrder: 10,
      );

      when(() => mockClient.from('categories')).thenAnswer((_) =>
          FakeSupabaseQueryBuilder(
              selectData: [updated], singleData: updated));

      // When
      final result = await repository.updateCategory(
        id: 'cat-1',
        name: '새이름',
        icon: 'new_icon',
        color: '#FFFFFF',
        sortOrder: 10,
      );

      // Then
      expect(result.name, '새이름');
      expect(result.icon, 'new_icon');
      expect(result.color, '#FFFFFF');
      expect(result.sortOrder, 10);
    });

    test('중복 이름으로 업데이트 시 DuplicateItemException을 던진다', () async {
      // Given
      when(() => mockClient.from('categories')).thenAnswer((_) {
        throw PostgrestException(
          message: 'duplicate key value violates unique constraint',
          code: '23505',
        );
      });

      // When & Then
      await expectLater(
        () => repository.updateCategory(id: 'cat-1', name: '중복이름'),
        throwsA(isA<DuplicateItemException>()),
      );
    });
  });

  group('CategoryRepository - deleteCategory', () {
    test('카테고리 삭제 시 올바른 ID로 DELETE 쿼리를 실행한다', () async {
      // Given
      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When & Then: 에러 없이 완료되면 성공
      await repository.deleteCategory('cat-1');
      verify(() => mockClient.from('categories')).called(1);
    });

    test('다른 ID로도 삭제 가능하다', () async {
      // Given
      when(() => mockClient.from('categories'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(selectData: []));

      // When
      await repository.deleteCategory('different-cat-id');

      // Then
      verify(() => mockClient.from('categories')).called(1);
    });
  });

  group('CategoryRepository - reorderCategories', () {
    test('카테고리 순서 변경 시 RPC 함수를 호출한다', () async {
      // Given
      when(() => mockClient.rpc('batch_reorder_categories',
              params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(null));

      // When
      await repository.reorderCategories(['cat-3', 'cat-1', 'cat-2']);

      // Then
      verify(() => mockClient.rpc('batch_reorder_categories',
          params: any(named: 'params'))).called(1);
    });

    test('빈 리스트로 순서 변경 요청도 처리한다', () async {
      // Given
      when(() => mockClient.rpc('batch_reorder_categories',
              params: any(named: 'params')))
          .thenAnswer((_) => FakePostgrestFilterBuilder<dynamic>(null));

      // When
      await repository.reorderCategories([]);

      // Then: 에러 없이 완료
      verify(() => mockClient.rpc('batch_reorder_categories',
          params: any(named: 'params'))).called(1);
    });
  });

  group('CategoryRepository - subscribeCategories', () {
    test('subscribeCategories 호출 시 channel을 반환하고 구독을 등록한다', () async {
      // Given: MockRealtimeChannel과 channel 설정
      final mockChannel = MockRealtimeChannel();
      when(() => mockClient.channel(any())).thenReturn(mockChannel);
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      // When
      final result = repository.subscribeCategories(
        ledgerId: 'ledger-1',
        onCategoryChanged: () {},
      );

      // Then: channel이 반환됨
      expect(result, isA<RealtimeChannel>());
      verify(() => mockClient.channel(any())).called(1);
      verify(() => mockChannel.subscribe()).called(1);
    });

    test('subscribeCategories는 ledgerId에 맞는 채널명을 사용한다', () async {
      // Given
      final mockChannel = MockRealtimeChannel();
      when(() => mockClient.channel('categories_changes_my-ledger'))
          .thenReturn(mockChannel);
      when(
        () => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        ),
      ).thenReturn(mockChannel);
      when(() => mockChannel.subscribe()).thenReturn(mockChannel);

      // When
      repository.subscribeCategories(
        ledgerId: 'my-ledger',
        onCategoryChanged: () {},
      );

      // Then: 올바른 채널명으로 구독
      verify(() => mockClient.channel('categories_changes_my-ledger')).called(1);
    });
  });

  group('CategoryRepository - 생성자 테스트', () {
    test('CategoryModel.toCreateJson은 올바른 형식의 JSON을 반환한다', () {
      // Given & When
      final json = CategoryModel.toCreateJson(
        ledgerId: 'ledger-1',
        name: '테스트',
        icon: 'test',
        color: '#FF0000',
        type: 'expense',
        sortOrder: 3,
      );

      // Then
      expect(json['ledger_id'], 'ledger-1');
      expect(json['name'], '테스트');
      expect(json['icon'], 'test');
      expect(json['color'], '#FF0000');
      expect(json['type'], 'expense');
      expect(json['is_default'], false);
      expect(json['sort_order'], 3);
    });
  });
}
