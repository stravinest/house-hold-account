import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/recurring_template_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

void main() {
  late MockTransactionRepository mockRepository;
  late ProviderContainer container;

  setUp(() {
    mockRepository = MockTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(mockRepository),
        selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('RecurringTemplateNotifier', () {
    group('toggle', () {
      test('템플릿 활성/비활성 토글 시 repository.toggleRecurringTemplate을 올바른 인자로 호출한다',
          () async {
        when(() => mockRepository.toggleRecurringTemplate('template-1', true))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.toggle('template-1', true);

        verify(() => mockRepository.toggleRecurringTemplate('template-1', true))
            .called(1);
      });

      test('토글 성공 시 상태가 AsyncValue.data(null)로 변경된다', () async {
        when(() => mockRepository.toggleRecurringTemplate('template-1', false))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.toggle('template-1', false);

        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncData<void>>());
      });

      test('토글 실패 시 에러 상태로 변경되고 rethrow한다', () async {
        final testError = Exception('토글 실패');
        when(() => mockRepository.toggleRecurringTemplate('template-1', true))
            .thenThrow(testError);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        expect(
          () => notifier.toggle('template-1', true),
          throwsA(isA<Exception>()),
        );

        // 비동기 작업 완료 대기
        await Future.delayed(Duration.zero);

        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncError<void>>());
      });

      test('토글 성공 시 recurringTemplatesProvider를 무효화하여 목록을 새로고침한다',
          () async {
        when(() => mockRepository.toggleRecurringTemplate('template-1', true))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => [
                  {'id': 'template-1', 'is_active': true}
                ]);

        // recurringTemplatesProvider를 먼저 읽어서 구독 상태 만들기
        container.read(recurringTemplatesProvider);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);
        await notifier.toggle('template-1', true);

        // invalidate 후 다시 fetch되므로 getAllRecurringTemplates가 호출됨
        verify(() => mockRepository.getAllRecurringTemplates(
            ledgerId: 'test-ledger-id')).called(greaterThanOrEqualTo(1));
      });
    });

    group('update', () {
      test('템플릿 업데이트 시 repository.updateRecurringTemplate을 올바른 인자로 호출한다',
          () async {
        when(() => mockRepository.updateRecurringTemplate(
              'template-1',
              amount: 50000,
              title: '월세',
              clearEndDate: false,
            )).thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.update('template-1', amount: 50000, title: '월세');

        verify(() => mockRepository.updateRecurringTemplate(
              'template-1',
              amount: 50000,
              title: '월세',
              clearEndDate: false,
            )).called(1);
      });

      test('clearEndDate를 true로 전달하면 repository에 정확히 전달된다', () async {
        when(() => mockRepository.updateRecurringTemplate(
              'template-1',
              clearEndDate: true,
            )).thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.update('template-1', clearEndDate: true);

        verify(() => mockRepository.updateRecurringTemplate(
              'template-1',
              clearEndDate: true,
            )).called(1);
      });

      test('업데이트 성공 시 상태가 AsyncValue.data(null)로 변경된다', () async {
        when(() => mockRepository.updateRecurringTemplate(
              'template-1',
              amount: 30000,
              clearEndDate: false,
            )).thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.update('template-1', amount: 30000);

        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncData<void>>());
      });

      test('업데이트 실패 시 에러 상태로 변경되고 rethrow한다', () async {
        final testError = Exception('업데이트 실패');
        when(() => mockRepository.updateRecurringTemplate(
              'template-1',
              amount: 30000,
              clearEndDate: false,
            )).thenThrow(testError);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        expect(
          () => notifier.update('template-1', amount: 30000),
          throwsA(isA<Exception>()),
        );

        await Future.delayed(Duration.zero);

        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncError<void>>());
      });

      test('업데이트 성공 시 recurringTemplatesProvider를 무효화한다', () async {
        when(() => mockRepository.updateRecurringTemplate(
              'template-1',
              recurringType: 'weekly',
              clearEndDate: false,
            )).thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        container.read(recurringTemplatesProvider);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);
        await notifier.update('template-1', recurringType: 'weekly');

        verify(() => mockRepository.getAllRecurringTemplates(
            ledgerId: 'test-ledger-id')).called(greaterThanOrEqualTo(1));
      });
    });

    group('delete', () {
      test('템플릿 삭제 시 repository.deleteRecurringTemplate을 올바른 ID로 호출한다',
          () async {
        when(() => mockRepository.deleteRecurringTemplate('template-1'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.delete('template-1');

        verify(() => mockRepository.deleteRecurringTemplate('template-1'))
            .called(1);
      });

      test('삭제 성공 시 상태가 AsyncValue.data(null)로 변경된다', () async {
        when(() => mockRepository.deleteRecurringTemplate('template-1'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        await notifier.delete('template-1');

        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncData<void>>());
      });

      test('삭제 실패 시 에러 상태로 변경되고 rethrow한다', () async {
        final testError = Exception('삭제 실패');
        when(() => mockRepository.deleteRecurringTemplate('template-1'))
            .thenThrow(testError);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);

        expect(
          () => notifier.delete('template-1'),
          throwsA(isA<Exception>()),
        );

        await Future.delayed(Duration.zero);

        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncError<void>>());
      });

      test('삭제 성공 시 recurringTemplatesProvider를 무효화한다', () async {
        when(() => mockRepository.deleteRecurringTemplate('template-1'))
            .thenAnswer((_) async {});
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        container.read(recurringTemplatesProvider);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);
        await notifier.delete('template-1');

        verify(() => mockRepository.getAllRecurringTemplates(
            ledgerId: 'test-ledger-id')).called(greaterThanOrEqualTo(1));
      });
    });

    group('초기 상태', () {
      test('생성 직후 상태는 AsyncValue.data(null)이다', () {
        final state = container.read(recurringTemplateNotifierProvider);
        expect(state, isA<AsyncData<void>>());
      });
    });

    group('로딩 상태 전환', () {
      test('toggle 호출 시 로딩 상태를 거친 후 완료 상태로 전환된다', () async {
        final states = <AsyncValue<void>>[];

        when(() => mockRepository.toggleRecurringTemplate('template-1', true))
            .thenAnswer((_) async {
          // repository 호출 시점에서 상태 캡처
          states.add(container.read(recurringTemplateNotifierProvider));
        });
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: any(named: 'ledgerId')))
            .thenAnswer((_) async => []);

        final notifier =
            container.read(recurringTemplateNotifierProvider.notifier);
        await notifier.toggle('template-1', true);

        // repository 호출 시점에는 로딩 상태여야 한다
        expect(states.first, isA<AsyncLoading<void>>());

        // 완료 후에는 data 상태여야 한다
        final finalState = container.read(recurringTemplateNotifierProvider);
        expect(finalState, isA<AsyncData<void>>());
      });
    });
  });

  group('update - fixedExpenseCategoryId 파라미터', () {
    test('fixedExpenseCategoryId를 포함하여 업데이트하면 repository에 정확히 전달된다',
        () async {
      when(() => mockRepository.updateRecurringTemplate(
            'template-1',
            fixedExpenseCategoryId: 'fixed-cat-1',
            clearEndDate: false,
          )).thenAnswer((_) async {});
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      final notifier =
          container.read(recurringTemplateNotifierProvider.notifier);

      await notifier.update('template-1', fixedExpenseCategoryId: 'fixed-cat-1');

      verify(() => mockRepository.updateRecurringTemplate(
            'template-1',
            fixedExpenseCategoryId: 'fixed-cat-1',
            clearEndDate: false,
          )).called(1);
    });

    test('모든 파라미터를 동시에 전달하면 repository에 모두 정확히 전달된다', () async {
      final endDate = DateTime(2027, 12, 31);
      when(() => mockRepository.updateRecurringTemplate(
            'template-1',
            amount: 100000,
            title: '새 제목',
            memo: '메모 내용',
            recurringType: 'yearly',
            endDate: endDate,
            clearEndDate: false,
            categoryId: 'cat-1',
            paymentMethodId: 'pm-1',
            fixedExpenseCategoryId: 'fixed-cat-1',
          )).thenAnswer((_) async {});
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      final notifier =
          container.read(recurringTemplateNotifierProvider.notifier);

      await notifier.update(
        'template-1',
        amount: 100000,
        title: '새 제목',
        memo: '메모 내용',
        recurringType: 'yearly',
        endDate: endDate,
        categoryId: 'cat-1',
        paymentMethodId: 'pm-1',
        fixedExpenseCategoryId: 'fixed-cat-1',
      );

      verify(() => mockRepository.updateRecurringTemplate(
            'template-1',
            amount: 100000,
            title: '새 제목',
            memo: '메모 내용',
            recurringType: 'yearly',
            endDate: endDate,
            clearEndDate: false,
            categoryId: 'cat-1',
            paymentMethodId: 'pm-1',
            fixedExpenseCategoryId: 'fixed-cat-1',
          )).called(1);
    });

    test('endDate와 clearEndDate를 동시에 전달하면 clearEndDate가 false로 설정된다',
        () async {
      final endDate = DateTime(2027, 6, 30);
      when(() => mockRepository.updateRecurringTemplate(
            'template-1',
            endDate: endDate,
            clearEndDate: false,
          )).thenAnswer((_) async {});
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      final notifier =
          container.read(recurringTemplateNotifierProvider.notifier);

      await notifier.update('template-1', endDate: endDate);

      verify(() => mockRepository.updateRecurringTemplate(
            'template-1',
            endDate: endDate,
            clearEndDate: false,
          )).called(1);
    });
  });

  group('연속 작업 시나리오', () {
    test('toggle 후 바로 delete를 호출하면 모두 정상적으로 처리된다', () async {
      when(() => mockRepository.toggleRecurringTemplate('template-1', false))
          .thenAnswer((_) async {});
      when(() => mockRepository.deleteRecurringTemplate('template-1'))
          .thenAnswer((_) async {});
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      final notifier =
          container.read(recurringTemplateNotifierProvider.notifier);

      await notifier.toggle('template-1', false);
      await notifier.delete('template-1');

      verify(() => mockRepository.toggleRecurringTemplate('template-1', false))
          .called(1);
      verify(() => mockRepository.deleteRecurringTemplate('template-1'))
          .called(1);

      final state = container.read(recurringTemplateNotifierProvider);
      expect(state, isA<AsyncData<void>>());
    });

    test('서로 다른 템플릿에 대한 작업을 순차적으로 수행할 수 있다', () async {
      when(() => mockRepository.toggleRecurringTemplate('template-1', true))
          .thenAnswer((_) async {});
      when(() => mockRepository.toggleRecurringTemplate('template-2', false))
          .thenAnswer((_) async {});
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: any(named: 'ledgerId')))
          .thenAnswer((_) async => []);

      final notifier =
          container.read(recurringTemplateNotifierProvider.notifier);

      await notifier.toggle('template-1', true);
      await notifier.toggle('template-2', false);

      verify(() => mockRepository.toggleRecurringTemplate('template-1', true))
          .called(1);
      verify(() => mockRepository.toggleRecurringTemplate('template-2', false))
          .called(1);
    });
  });

  group('recurringTemplatesProvider', () {
    test('selectedLedgerId가 null이면 빈 목록을 반환한다', () async {
      final nullContainer = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => null),
        ],
      );

      final result = await nullContainer.read(recurringTemplatesProvider.future);
      expect(result, isEmpty);

      nullContainer.dispose();
    });

    test('selectedLedgerId가 있으면 repository에서 템플릿 목록을 조회한다', () async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 50000,
          'is_active': true,
          'recurring_type': 'monthly',
        },
        {
          'id': 'template-2',
          'type': 'income',
          'amount': 3000000,
          'is_active': false,
          'recurring_type': 'monthly',
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      final result =
          await container.read(recurringTemplatesProvider.future);

      expect(result, hasLength(2));
      expect(result[0]['id'], 'template-1');
      expect(result[1]['amount'], 3000000);
    });
  });
}
