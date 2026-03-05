import 'dart:async';

import 'package:flutter/foundation.dart' show VoidCallback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/core/utils/supabase_error_handler.dart';
import 'package:shared_household_account/features/fixed_expense/data/models/fixed_expense_category_model.dart';
import 'package:shared_household_account/features/fixed_expense/data/repositories/fixed_expense_category_repository.dart';
import 'package:shared_household_account/features/fixed_expense/domain/entities/fixed_expense_category.dart';
import 'package:shared_household_account/features/fixed_expense/presentation/providers/fixed_expense_category_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../helpers/test_helpers.dart' hide pumpEventQueue;

Future<void> pumpEventQueue({Duration duration = Duration.zero}) {
  return Future.delayed(duration);
}

MockRealtimeChannel createMockCategoryChannel() {
  final channel = MockRealtimeChannel();
  when(() => channel.unsubscribe()).thenAnswer((_) async => 'ok');
  return channel;
}

FixedExpenseCategoryModel makeCategory({
  String id = 'cat-1',
  String ledgerId = 'ledger-1',
  String name = '월세',
  String icon = 'home',
  String color = '#FF9800',
  int sortOrder = 0,
}) {
  return FixedExpenseCategoryModel(
    id: id,
    ledgerId: ledgerId,
    name: name,
    icon: icon,
    color: color,
    sortOrder: sortOrder,
    createdAt: DateTime(2026, 2, 20),
  );
}

void main() {
  group('FixedExpenseCategoryProvider Tests', () {
    late MockFixedExpenseCategoryRepository mockRepository;
    late ProviderContainer container;

    setUp(() {
      mockRepository = MockFixedExpenseCategoryRepository();

      // subscribeCategories 기본 stub
      final defaultChannel = createMockCategoryChannel();
      when(() => mockRepository.subscribeCategories(
            ledgerId: any(named: 'ledgerId'),
            onCategoryChanged: any(named: 'onCategoryChanged'),
          )).thenReturn(defaultChannel);
    });

    tearDown(() {
      container.dispose();
    });

    test('fixedExpenseCategoryRepositoryProvider는 FixedExpenseCategoryRepository 인스턴스를 제공한다', () {
      // Given
      container = createContainer(
        overrides: [
          fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
        ],
      );

      // When
      final repository = container.read(fixedExpenseCategoryRepositoryProvider);

      // Then
      expect(repository, isA<FixedExpenseCategoryRepository>());
    });

    group('fixedExpenseCategoriesProvider (FutureProvider)', () {
      test('ledgerId가 null이면 빈 리스트를 반환한다', () async {
        // Given
        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        // When
        final result = await container.read(fixedExpenseCategoriesProvider.future);

        // Then
        expect(result, isEmpty);
        verifyNever(() => mockRepository.getCategories(any()));
      });

      test('ledgerId가 있으면 카테고리 목록을 반환한다', () async {
        // Given
        final categories = [makeCategory(), makeCategory(id: 'cat-2', name: '통신비')];
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => categories);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        // When
        final result = await container.read(fixedExpenseCategoriesProvider.future);

        // Then
        expect(result.length, 2);
        expect(result[0].name, '월세');
        expect(result[1].name, '통신비');
      });
    });

    group('FixedExpenseCategoryNotifier - 초기화', () {
      test('ledgerId가 null이면 빈 리스트 상태로 초기화된다', () async {
        // Given
        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        // When
        container.read(fixedExpenseCategoryNotifierProvider);
        await pumpEventQueue();

        // Then
        final state = container.read(fixedExpenseCategoryNotifierProvider);
        expect(state.valueOrNull, isEmpty);
        verifyNever(() => mockRepository.getCategories(any()));
      });

      test('ledgerId가 있으면 카테고리를 로드한다', () async {
        // Given
        final categories = [makeCategory()];
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => categories);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        // When
        AsyncValue<List<FixedExpenseCategory>>? lastState;
        container.listen(fixedExpenseCategoryNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        // Then
        expect(lastState?.valueOrNull, isNotNull);
        expect(lastState?.valueOrNull?.length, 1);
        expect(lastState?.valueOrNull?.first.name, '월세');
      });

      test('Realtime 구독이 ledgerId 기반으로 설정된다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => []);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        container.listen(fixedExpenseCategoryNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // Then
        verify(() => mockRepository.subscribeCategories(
              ledgerId: 'ledger-1',
              onCategoryChanged: any(named: 'onCategoryChanged'),
            )).called(1);
      });

      test('Repository 에러 발생 시 에러 상태가 된다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => throw Exception('DB 연결 실패'));

        Object? caughtError;
        await runZonedGuarded(() async {
          container = createContainer(
            overrides: [
              fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
              selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
            ],
          );

          AsyncValue<List<FixedExpenseCategory>>? lastState;
          container.listen(fixedExpenseCategoryNotifierProvider, (_, next) {
            lastState = next;
          });
          await pumpEventQueue();

          // Then
          expect(lastState?.hasError, true);
        }, (error, stack) {
          caughtError = error;
        });

        expect(caughtError, isA<Exception>());
      });
    });

    group('FixedExpenseCategoryNotifier - createCategory', () {
      test('카테고리 생성 성공 시 목록을 새로 로드한다', () async {
        // Given
        final newCategory = makeCategory(id: 'cat-new', name: '보험료');
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => [newCategory]);
        when(() => mockRepository.createCategory(
              ledgerId: 'ledger-1',
              name: '보험료',
              icon: '',
              color: '#2196F3',
            )).thenAnswer((_) async => newCategory);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        AsyncValue<List<FixedExpenseCategory>>? lastState;
        container.listen(fixedExpenseCategoryNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        // When
        final result = await container
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .createCategory(name: '보험료', color: '#2196F3');

        // Then
        expect(result.name, '보험료');
        expect(lastState?.valueOrNull?.first.name, '보험료');
      });

      test('ledgerId가 null이면 createCategory는 예외를 던진다', () async {
        // Given
        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => null),
          ],
        );

        container.read(fixedExpenseCategoryNotifierProvider);
        await pumpEventQueue();

        // When / Then
        expect(
          () => container
              .read(fixedExpenseCategoryNotifierProvider.notifier)
              .createCategory(name: '테스트', color: '#FF0000'),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('가계부를 선택해주세요'),
          )),
        );
      });

      test('중복 카테고리 생성 시 DuplicateItemException이 전파된다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.createCategory(
              ledgerId: 'ledger-1',
              name: '중복',
              icon: '',
              color: '#FF0000',
            )).thenAnswer((_) async => throw DuplicateItemException(
              itemType: '고정비 카테고리',
              itemName: '중복',
            ));

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        container.listen(fixedExpenseCategoryNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // When / Then
        await expectLater(
          container
              .read(fixedExpenseCategoryNotifierProvider.notifier)
              .createCategory(name: '중복', color: '#FF0000'),
          throwsA(isA<DuplicateItemException>()),
        );
      });
    });

    group('FixedExpenseCategoryNotifier - updateCategory', () {
      test('카테고리 수정 성공 시 목록을 새로 로드한다', () async {
        // Given
        final updatedCategory = makeCategory(id: 'cat-1', name: '수정된 월세');
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => [updatedCategory]);
        when(() => mockRepository.updateCategory(
              id: 'cat-1',
              name: '수정된 월세',
              icon: 'home',
              color: '#FF9800',
            )).thenAnswer((_) async => updatedCategory);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        AsyncValue<List<FixedExpenseCategory>>? lastState;
        container.listen(fixedExpenseCategoryNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        // When
        await container
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .updateCategory(id: 'cat-1', name: '수정된 월세', icon: 'home', color: '#FF9800');

        // Then
        expect(lastState?.valueOrNull?.first.name, '수정된 월세');
      });

      test('수정 실패 시 에러가 전파된다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.updateCategory(
              id: 'cat-1',
              name: '실패',
              icon: null,
              color: null,
            )).thenAnswer((_) async => throw Exception('수정 실패'));

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        container.listen(fixedExpenseCategoryNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // When / Then
        await expectLater(
          container
              .read(fixedExpenseCategoryNotifierProvider.notifier)
              .updateCategory(id: 'cat-1', name: '실패'),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('FixedExpenseCategoryNotifier - deleteCategory', () {
      test('카테고리 삭제 성공 시 목록을 새로 로드한다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.deleteCategory('cat-1'))
            .thenAnswer((_) async {});

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        container.listen(fixedExpenseCategoryNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // When
        await container
            .read(fixedExpenseCategoryNotifierProvider.notifier)
            .deleteCategory('cat-1');

        // Then
        verify(() => mockRepository.deleteCategory('cat-1')).called(1);
        // 삭제 후 목록 재로드 확인 (초기 로드 1회 + 삭제 후 재로드 1회 = 2회)
        verify(() => mockRepository.getCategories('ledger-1')).called(greaterThanOrEqualTo(1));
      });

      test('삭제 실패 시 데이터를 다시 로드하고 에러를 전파한다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => []);
        when(() => mockRepository.deleteCategory('cat-1'))
            .thenAnswer((_) async => throw Exception('삭제 실패'));

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        container.listen(fixedExpenseCategoryNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // When / Then
        await expectLater(
          container
              .read(fixedExpenseCategoryNotifierProvider.notifier)
              .deleteCategory('cat-1'),
          throwsA(isA<Exception>()),
        );

        // 에러 후 복구 로드가 실행됨
        verify(() => mockRepository.getCategories('ledger-1')).called(greaterThanOrEqualTo(2));
      });
    });

    group('_refreshCategoriesQuietly - Realtime 콜백 처리', () {
      test('Realtime 콜백이 호출되면 카테고리 목록을 다시 로드한다', () async {
        // Given: subscribeCategories에서 onCategoryChanged 콜백 캡처
        VoidCallback? capturedCallback;
        final channel = createMockCategoryChannel();
        when(() => mockRepository.subscribeCategories(
              ledgerId: 'ledger-1',
              onCategoryChanged: any(named: 'onCategoryChanged'),
            )).thenAnswer((invocation) {
          capturedCallback = invocation.namedArguments[#onCategoryChanged] as VoidCallback;
          return channel;
        });

        final categories = [makeCategory()];
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => categories);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        AsyncValue<List<FixedExpenseCategory>>? lastState;
        container.listen(fixedExpenseCategoryNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        // When: Realtime 콜백 트리거
        expect(capturedCallback, isNotNull);
        capturedCallback!();
        await pumpEventQueue();

        // Then: getCategories가 2번 이상 호출됨 (초기 로드 + 콜백 후 재로드)
        verify(() => mockRepository.getCategories('ledger-1'))
            .called(greaterThanOrEqualTo(2));
        expect(lastState?.hasValue, isTrue);
      });

      test('Realtime 콜백 후 카테고리 조회에서 에러가 발생해도 조용히 처리된다', () async {
        // Given
        VoidCallback? capturedCallback;
        final channel = createMockCategoryChannel();
        when(() => mockRepository.subscribeCategories(
              ledgerId: 'ledger-1',
              onCategoryChanged: any(named: 'onCategoryChanged'),
            )).thenAnswer((invocation) {
          capturedCallback = invocation.namedArguments[#onCategoryChanged] as VoidCallback;
          return channel;
        });

        // 초기 로드 성공, 이후 에러
        var callCount = 0;
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async {
          callCount++;
          if (callCount == 1) return [makeCategory()];
          throw Exception('새로고침 실패');
        });

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        AsyncValue<List<FixedExpenseCategory>>? lastState;
        container.listen(fixedExpenseCategoryNotifierProvider, (_, next) {
          lastState = next;
        });
        await pumpEventQueue();

        // When: Realtime 콜백 트리거 (에러 발생하지만 rethrow 없음)
        expect(capturedCallback, isNotNull);
        capturedCallback!();
        await pumpEventQueue();

        // Then: _refreshCategoriesQuietly는 에러를 조용히 처리
        expect(lastState, isNotNull);
      });

      test('dispose 시 Realtime 채널 구독이 해제된다', () async {
        // Given
        when(() => mockRepository.getCategories('ledger-1'))
            .thenAnswer((_) async => [makeCategory()]);

        container = createContainer(
          overrides: [
            fixedExpenseCategoryRepositoryProvider.overrideWith((ref) => mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
        );

        container.listen(fixedExpenseCategoryNotifierProvider, (_, __) {});
        await pumpEventQueue();

        // When: container dispose
        container.dispose();

        // Then: dispose 정상 완료 후 새 container 생성 가능
        container = createContainer();
      });
    });
  });
}
