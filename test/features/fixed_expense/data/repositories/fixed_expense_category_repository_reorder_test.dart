import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/mock_supabase.dart';

class MockSupabaseRpcBuilder extends Fake implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<S> then<S>(FutureOr<S> Function(dynamic value) onValue, {Function? onError}) {
    return Future<dynamic>.value(null).then<S>(onValue, onError: onError);
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late FixedExpenseCategoryRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = FixedExpenseCategoryRepository(client: mockClient);
  });

  group('FixedExpenseCategoryRepository - reorderCategories', () {
    test('카테고리 순서 변경 시 RPC를 호출한다', () async {
      // Given
      final categoryIds = ['cat-1', 'cat-2', 'cat-3'];
      when(() => mockClient.rpc(
            'batch_reorder_fixed_expense_categories',
            params: any(named: 'params'),
          )).thenAnswer((_) => MockSupabaseRpcBuilder());

      // When
      await repository.reorderCategories(categoryIds);

      // Then
      verify(() => mockClient.rpc(
            'batch_reorder_fixed_expense_categories',
            params: {'p_category_ids': categoryIds},
          )).called(1);
    });

    test('RPC 실패 시 에러를 전파한다', () async {
      // Given
      when(() => mockClient.rpc(
            'batch_reorder_fixed_expense_categories',
            params: any(named: 'params'),
          )).thenAnswer((_) => throw Exception('RPC 실패'));

      // When / Then
      expect(
        () => repository.reorderCategories(['cat-1', 'cat-2']),
        throwsA(isA<Exception>()),
      );
    });

    test('빈 리스트로 순서 변경 시 RPC를 호출한다', () async {
      // Given
      when(() => mockClient.rpc(
            'batch_reorder_fixed_expense_categories',
            params: any(named: 'params'),
          )).thenAnswer((_) => MockSupabaseRpcBuilder());

      // When
      await repository.reorderCategories([]);

      // Then
      verify(() => mockClient.rpc(
            'batch_reorder_fixed_expense_categories',
            params: {'p_category_ids': []},
          )).called(1);
    });
  });

  group('FixedExpenseCategoryRepository - getCategories 에러 처리', () {
    test('DB 에러 발생 시 예외를 전파한다', () async {
      // Given
      when(() => mockClient.from('fixed_expense_categories'))
          .thenAnswer((_) => throw Exception('연결 오류'));

      // When / Then
      expect(
        () => repository.getCategories('ledger-1'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('FixedExpenseCategoryRepository - updateCategory 에러 처리', () {
    test('DB 에러 발생 시 예외를 전파한다', () async {
      // Given
      when(() => mockClient.from('fixed_expense_categories'))
          .thenAnswer((_) => throw Exception('업데이트 오류'));

      // When / Then
      expect(
        () => repository.updateCategory(id: 'cat-1', name: '업데이트실패'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('FixedExpenseCategoryRepository - deleteCategory 에러 처리', () {
    test('DB 에러 발생 시 예외를 전파한다', () async {
      // Given
      when(() => mockClient.from('fixed_expense_categories'))
          .thenAnswer((_) => throw Exception('삭제 오류'));

      // When / Then
      expect(
        () => repository.deleteCategory('cat-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
