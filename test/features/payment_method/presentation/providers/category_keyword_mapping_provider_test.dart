import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_household_account/features/payment_method/data/models/category_keyword_mapping_model.dart';
import 'package:shared_household_account/features/payment_method/data/repositories/category_keyword_mapping_repository.dart';
import 'package:shared_household_account/features/payment_method/presentation/providers/category_keyword_mapping_provider.dart';

import '../../../../helpers/test_providers.dart' hide pumpEventQueue;

class MockCategoryKeywordMappingRepository extends Mock
    implements CategoryKeywordMappingRepository {}

CategoryKeywordMappingModel _makeMapping({
  String id = 'mapping-1',
  String keyword = '스타벅스',
  String categoryId = 'cat-food',
  String sourceType = 'sms',
  String paymentMethodId = 'pm-1',
  String ledgerId = 'ledger-1',
}) {
  return CategoryKeywordMappingModel(
    id: id,
    paymentMethodId: paymentMethodId,
    ledgerId: ledgerId,
    keyword: keyword,
    categoryId: categoryId,
    sourceType: sourceType,
    createdBy: 'user-1',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockCategoryKeywordMappingRepository mockRepository;

  setUp(() {
    mockRepository = MockCategoryKeywordMappingRepository();
  });

  group('categoryKeywordMappingsProvider', () {
    test('paymentMethodId로 키워드 매핑 목록을 반환한다', () async {
      final mappings = [_makeMapping(), _makeMapping(id: 'mapping-2', keyword: 'GS25')];
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => mappings);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        categoryKeywordMappingsProvider((
          paymentMethodId: 'pm-1',
          sourceType: null,
        )).future,
      );
      expect(result.length, 2);
      expect(result[0].keyword, '스타벅스');
    });

    test('sourceType 필터를 적용하여 조회한다', () async {
      final mappings = [_makeMapping(sourceType: 'notification')];
      when(() => mockRepository.getByPaymentMethod(
            'pm-1',
            sourceType: 'notification',
          )).thenAnswer((_) async => mappings);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        categoryKeywordMappingsProvider((
          paymentMethodId: 'pm-1',
          sourceType: 'notification',
        )).future,
      );
      expect(result.length, 1);
      expect(result[0].sourceType, 'notification');
    });
  });

  group('categoryKeywordMappingsByLedgerProvider', () {
    test('ledgerId로 키워드 매핑 전체 목록을 반환한다', () async {
      final mappings = [_makeMapping(), _makeMapping(id: 'mapping-2', keyword: 'GS25')];
      when(() => mockRepository.getByLedger('ledger-1', sourceType: null))
          .thenAnswer((_) async => mappings);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        categoryKeywordMappingsByLedgerProvider((
          ledgerId: 'ledger-1',
          sourceType: null,
        )).future,
      );
      expect(result.length, 2);
    });

    test('sourceType 필터로 가계부별 매핑을 조회한다', () async {
      final mappings = [_makeMapping(sourceType: 'sms')];
      when(() => mockRepository.getByLedger('ledger-1', sourceType: 'sms'))
          .thenAnswer((_) async => mappings);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      final result = await container.read(
        categoryKeywordMappingsByLedgerProvider((
          ledgerId: 'ledger-1',
          sourceType: 'sms',
        )).future,
      );
      expect(result.length, 1);
      expect(result[0].sourceType, 'sms');
    });
  });

  group('CategoryKeywordMappingNotifier - loadMappings', () {
    test('paymentMethodId가 null이면 빈 리스트로 초기화된다', () async {
      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      // autoDispose provider를 살아있게 유지
      container.listen(
        categoryKeywordMappingNotifierProvider(null),
        (_, __) {},
        fireImmediately: true,
      );

      await Future.delayed(Duration.zero);
      final state = container.read(
        categoryKeywordMappingNotifierProvider(null),
      );
      expect(state, isA<AsyncData<List<CategoryKeywordMappingModel>>>());
      expect(state.value, isEmpty);
    });

    test('paymentMethodId가 있으면 매핑 목록을 로드한다', () async {
      final mappings = [_makeMapping()];
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => mappings);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      await notifier.loadMappings();

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state, isA<AsyncData<List<CategoryKeywordMappingModel>>>());
      expect(state.value?.length, 1);
      expect(state.value?[0].keyword, '스타벅스');
    });

    test('sourceType 필터를 적용하여 로드한다', () async {
      final mappings = [_makeMapping(sourceType: 'notification')];
      when(() => mockRepository.getByPaymentMethod(
            'pm-1',
            sourceType: 'notification',
          )).thenAnswer((_) async => mappings);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      await notifier.loadMappings(sourceType: 'notification');

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state.value?.length, 1);
      expect(state.value?[0].sourceType, 'notification');
    });

    test('Repository 에러 시 error 상태로 전환한다', () async {
      // 첫 번째(생성자)는 성공, 두 번째는 에러
      var callCount = 0;
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return [];
        throw Exception('DB 에러');
      });

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      // 생성자 초기 로드 완료 대기
      await Future.delayed(const Duration(milliseconds: 100));

      // 두 번째 호출 - 에러 발생 (loadMappings는 rethrow 안 함)
      await notifier.loadMappings();

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state, isA<AsyncError<List<CategoryKeywordMappingModel>>>());
    });
  });

  group('CategoryKeywordMappingNotifier - create', () {
    test('키워드 매핑을 생성하고 목록을 갱신한다', () async {
      final newMapping = _makeMapping(id: 'mapping-new', keyword: '이디야');
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => []);
      when(() => mockRepository.create(
            paymentMethodId: 'pm-1',
            ledgerId: 'ledger-1',
            keyword: '이디야',
            categoryId: 'cat-cafe',
            sourceType: 'sms',
            createdBy: 'user-1',
          )).thenAnswer((_) async => newMapping);

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // 생성 후 loadMappings 호출 시 새 목록 반환
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => [newMapping]);

      await notifier.create(
        ledgerId: 'ledger-1',
        keyword: '이디야',
        categoryId: 'cat-cafe',
        sourceType: 'sms',
        createdBy: 'user-1',
      );

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state.value?.length, 1);
      expect(state.value?[0].keyword, '이디야');
    });

    test('paymentMethodId가 null이면 create가 아무것도 하지 않는다', () async {
      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider(null),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider(null).notifier,
      );

      // repository.create가 호출되지 않아야 함
      await notifier.create(
        ledgerId: 'ledger-1',
        keyword: '이디야',
        categoryId: 'cat-cafe',
        sourceType: 'sms',
        createdBy: 'user-1',
      );

      verifyNever(() => mockRepository.create(
            paymentMethodId: any(named: 'paymentMethodId'),
            ledgerId: any(named: 'ledgerId'),
            keyword: any(named: 'keyword'),
            categoryId: any(named: 'categoryId'),
            sourceType: any(named: 'sourceType'),
            createdBy: any(named: 'createdBy'),
          ));
    });

    test('create 실패 시 error 상태로 전환하고 예외를 rethrow한다', () async {
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => []);
      when(() => mockRepository.create(
            paymentMethodId: any(named: 'paymentMethodId'),
            ledgerId: any(named: 'ledgerId'),
            keyword: any(named: 'keyword'),
            categoryId: any(named: 'categoryId'),
            sourceType: any(named: 'sourceType'),
            createdBy: any(named: 'createdBy'),
          )).thenThrow(Exception('생성 실패'));

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      await expectLater(
        notifier.create(
          ledgerId: 'ledger-1',
          keyword: '이디야',
          categoryId: 'cat-cafe',
          sourceType: 'sms',
          createdBy: 'user-1',
        ),
        throwsA(isA<Exception>()),
      );

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state, isA<AsyncError<List<CategoryKeywordMappingModel>>>());
    });
  });

  group('CategoryKeywordMappingNotifier - delete', () {
    test('ID로 키워드 매핑을 삭제하고 목록을 갱신한다', () async {
      final mapping = _makeMapping();
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => [mapping]);
      when(() => mockRepository.delete('mapping-1'))
          .thenAnswer((_) async {});

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      // 삭제 후 loadMappings 호출 시 빈 목록 반환
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => []);

      await notifier.delete('mapping-1');

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state.value, isEmpty);
    });

    test('delete 실패 시 error 상태로 전환하고 예외를 rethrow한다', () async {
      when(() => mockRepository.getByPaymentMethod('pm-1', sourceType: null))
          .thenAnswer((_) async => [_makeMapping()]);
      when(() => mockRepository.delete('mapping-1'))
          .thenThrow(Exception('삭제 실패'));

      final container = createContainer(
        overrides: [
          categoryKeywordMappingRepositoryProvider
              .overrideWith((_) => mockRepository),
        ],
      );
      addTearDown(container.dispose);

      container.listen(
        categoryKeywordMappingNotifierProvider('pm-1'),
        (_, __) {},
        fireImmediately: true,
      );

      final notifier = container.read(
        categoryKeywordMappingNotifierProvider('pm-1').notifier,
      );
      await Future.delayed(const Duration(milliseconds: 100));

      await expectLater(
        notifier.delete('mapping-1'),
        throwsA(isA<Exception>()),
      );

      final state = container.read(
        categoryKeywordMappingNotifierProvider('pm-1'),
      );
      expect(state, isA<AsyncError<List<CategoryKeywordMappingModel>>>());
    });
  });
}
