import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/statistics/data/repositories/statistics_repository.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  group('StatisticsProvider Tests', () {
    late MockStatisticsRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockStatisticsRepository();
    });

    tearDown(() {
      container.dispose();
    });

    test('statisticsRepositoryProvider는 StatisticsRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          statisticsRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(statisticsRepositoryProvider);

      // Then
      expect(repository, isA<StatisticsRepository>());
    });

    // 엔티티 구조가 변경되어 복잡한 테스트는 통합 테스트에서 검증
  });

  group('CategoryDetailState 모델 테스트', () {
    test('기본 생성자로 생성 시 모든 속성이 기본값으로 초기화된다', () {
      // Given & When: 기본 생성자로 생성
      const state = CategoryDetailState();

      // Then: 모든 속성이 기본값
      expect(state.isOpen, false);
      expect(state.categoryId, '');
      expect(state.categoryName, '');
      expect(state.categoryColor, '');
      expect(state.categoryIcon, '');
      expect(state.categoryPercentage, 0);
      expect(state.type, 'expense');
      expect(state.totalAmount, 0);
    });

    test('named 파라미터로 생성 시 지정된 값이 올바르게 저장된다', () {
      // Given & When: named 파라미터로 생성
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-123',
        categoryName: '식비',
        categoryColor: '#FF5722',
        categoryIcon: 'restaurant',
        categoryPercentage: 35.5,
        type: 'income',
        totalAmount: 150000,
      );

      // Then: 지정된 값 검증
      expect(state.isOpen, true);
      expect(state.categoryId, 'cat-123');
      expect(state.categoryName, '식비');
      expect(state.categoryColor, '#FF5722');
      expect(state.categoryIcon, 'restaurant');
      expect(state.categoryPercentage, 35.5);
      expect(state.type, 'income');
      expect(state.totalAmount, 150000);
    });

    test('isOpen이 false인 경우 팝업이 닫힌 상태를 나타낸다', () {
      // Given: isOpen이 false인 상태
      const state = CategoryDetailState(isOpen: false);

      // When & Then
      expect(state.isOpen, false, reason: '팝업이 닫힌 상태여야 한다');
    });

    test('isOpen이 true인 경우 팝업이 열린 상태를 나타낸다', () {
      // Given: isOpen이 true인 상태
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-123',
        categoryName: '교통비',
      );

      // When & Then
      expect(state.isOpen, true, reason: '팝업이 열린 상태여야 한다');
      expect(state.categoryId.isNotEmpty, true, reason: '카테고리 ID가 있어야 한다');
    });

    test('type이 expense, income, asset 중 하나로 설정된다', () {
      // Given: 각 타입별 상태 생성
      const expenseState = CategoryDetailState(type: 'expense');
      const incomeState = CategoryDetailState(type: 'income');
      const assetState = CategoryDetailState(type: 'asset');

      // Then: type 검증
      expect(expenseState.type, 'expense');
      expect(incomeState.type, 'income');
      expect(assetState.type, 'asset');
    });

    test('categoryPercentage는 0부터 100 사이의 값을 가진다', () {
      // Given: 다양한 퍼센티지 값
      const state1 = CategoryDetailState(categoryPercentage: 0);
      const state2 = CategoryDetailState(categoryPercentage: 50.5);
      const state3 = CategoryDetailState(categoryPercentage: 100);

      // Then: 퍼센티지 범위 검증
      expect(state1.categoryPercentage, 0);
      expect(state2.categoryPercentage, 50.5);
      expect(state3.categoryPercentage, 100);
      expect(state1.categoryPercentage >= 0 && state1.categoryPercentage <= 100, true);
      expect(state2.categoryPercentage >= 0 && state2.categoryPercentage <= 100, true);
      expect(state3.categoryPercentage >= 0 && state3.categoryPercentage <= 100, true);
    });

    test('미지정 카테고리(_uncategorized_)도 올바르게 표현된다', () {
      // Given: 미지정 카테고리 상태
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: '_uncategorized_',
        categoryName: '미지정',
        categoryColor: '#9E9E9E',
        categoryIcon: '',
        categoryPercentage: 15.0,
        type: 'expense',
        totalAmount: 50000,
      );

      // Then
      expect(state.categoryId, '_uncategorized_');
      expect(state.categoryName, '미지정');
      expect(state.categoryColor, '#9E9E9E');
      expect(state.categoryIcon, '');
    });

    test('고정비 카테고리(_fixed_expense_)도 올바르게 표현된다', () {
      // Given: 고정비 카테고리 상태
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: '_fixed_expense_',
        categoryName: '고정비',
        categoryColor: '#FF9800',
        categoryIcon: 'push_pin',
        categoryPercentage: 60.0,
        type: 'expense',
        totalAmount: 500000,
      );

      // Then
      expect(state.categoryId, '_fixed_expense_');
      expect(state.categoryName, '고정비');
      expect(state.categoryColor, '#FF9800');
      expect(state.categoryIcon, 'push_pin');
    });

    test('totalAmount가 0인 경우에도 정상적으로 처리된다', () {
      // Given: 총액이 0인 상태
      const state = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-123',
        categoryName: '식비',
        totalAmount: 0,
      );

      // Then
      expect(state.totalAmount, 0);
      expect(state.categoryPercentage, 0, reason: '총액이 0이면 퍼센티지도 0이어야 한다');
    });

    test('여러 카테고리 상태를 동시에 관리할 수 있다', () {
      // Given: 여러 카테고리 상태 리스트
      final states = [
        const CategoryDetailState(
          isOpen: true,
          categoryId: 'cat-1',
          categoryName: '식비',
          categoryPercentage: 40.0,
          type: 'expense',
          totalAmount: 200000,
        ),
        const CategoryDetailState(
          isOpen: false,
          categoryId: 'cat-2',
          categoryName: '교통비',
          categoryPercentage: 30.0,
          type: 'expense',
          totalAmount: 150000,
        ),
        const CategoryDetailState(
          isOpen: false,
          categoryId: 'cat-3',
          categoryName: '급여',
          categoryPercentage: 100.0,
          type: 'income',
          totalAmount: 3000000,
        ),
      ];

      // Then: 각 상태가 독립적으로 관리됨
      expect(states.length, 3);
      expect(states[0].isOpen, true);
      expect(states[1].isOpen, false);
      expect(states[2].isOpen, false);
      expect(states[0].type, 'expense');
      expect(states[2].type, 'income');
    });

    test('동일한 값으로 생성된 두 상태는 같은 데이터를 가진다', () {
      // Given: 동일한 값으로 두 개의 상태 생성
      const state1 = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-123',
        categoryName: '식비',
        categoryColor: '#FF5722',
        categoryIcon: 'restaurant',
        categoryPercentage: 35.5,
        type: 'expense',
        totalAmount: 150000,
      );

      const state2 = CategoryDetailState(
        isOpen: true,
        categoryId: 'cat-123',
        categoryName: '식비',
        categoryColor: '#FF5722',
        categoryIcon: 'restaurant',
        categoryPercentage: 35.5,
        type: 'expense',
        totalAmount: 150000,
      );

      // Then: 모든 속성이 동일
      expect(state1.isOpen, state2.isOpen);
      expect(state1.categoryId, state2.categoryId);
      expect(state1.categoryName, state2.categoryName);
      expect(state1.categoryColor, state2.categoryColor);
      expect(state1.categoryIcon, state2.categoryIcon);
      expect(state1.categoryPercentage, state2.categoryPercentage);
      expect(state1.type, state2.type);
      expect(state1.totalAmount, state2.totalAmount);
    });

    test('카테고리 색상이 HEX 형식으로 저장된다', () {
      // Given: 다양한 색상 값
      const state1 = CategoryDetailState(categoryColor: '#FF5722'); // 빨강
      const state2 = CategoryDetailState(categoryColor: '#4CAF50'); // 초록
      const state3 = CategoryDetailState(categoryColor: '#2196F3'); // 파랑
      const state4 = CategoryDetailState(categoryColor: '#9E9E9E'); // 회색

      // Then: HEX 형식 검증
      expect(state1.categoryColor.startsWith('#'), true);
      expect(state1.categoryColor.length, 7); // #RRGGBB
      expect(state2.categoryColor.startsWith('#'), true);
      expect(state3.categoryColor.startsWith('#'), true);
      expect(state4.categoryColor.startsWith('#'), true);
    });
  });
}
