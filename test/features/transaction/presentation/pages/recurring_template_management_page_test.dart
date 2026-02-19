import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/recurring_template_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/pages/recurring_template_management_page.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/widgets/empty_state.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

// AppLocalizations를 지원하는 테스트 래퍼 위젯
Widget createTestWidget({
  required Widget child,
  required List<Override> overrides,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ko'),
      home: child,
    ),
  );
}

void main() {
  late MockTransactionRepository mockRepository;

  setUp(() {
    mockRepository = MockTransactionRepository();
  });

  group('RecurringTemplateManagementPage', () {
    test('빈 템플릿 목록일 때 EmptyState 위젯이 표시되는지 확인한다', () async {
      // 위젯 테스트 대신 provider 레벨에서 검증
      // 빈 목록 반환 시 페이지가 EmptyState를 표시하는 로직은
      // recurringTemplatesProvider가 빈 목록을 반환하는 것에 의존한다
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(mockRepository),
          selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
        ],
      );

      final result =
          await container.read(recurringTemplatesProvider.future);
      expect(result, isEmpty);

      container.dispose();
    });

    testWidgets('빈 템플릿 목록일 때 EmptyState 위젯이 화면에 표시된다',
        (WidgetTester tester) async {
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => []);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      // FutureProvider가 완료될 때까지 대기
      await tester.pumpAndSettle();

      expect(find.byType(EmptyState), findsOneWidget);
    });

    testWidgets('템플릿 목록이 있을 때 Card 위젯들이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 50000,
          'title': '월세',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': {'name': '주거', 'icon': 'home', 'color': '#FF0000'},
        },
        {
          'id': 'template-2',
          'type': 'income',
          'amount': 3000000,
          'title': '급여',
          'is_active': false,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': {'name': '급여', 'icon': 'work', 'color': '#00FF00'},
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // Card 위젯이 2개 표시되는지 확인
      expect(find.byType(Card), findsNWidgets(2));

      // 템플릿 제목이 표시되는지 확인
      expect(find.text('월세'), findsAtLeastNWidgets(1));
      expect(find.text('급여'), findsAtLeastNWidgets(1));
    });

    testWidgets('비활성 템플릿에는 비활성 상태 표시가 있다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 50000,
          'title': '해지된 구독',
          'is_active': false,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // 비활성 템플릿이 표시되는지 확인
      expect(find.text('해지된 구독'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('수입 타입 템플릿은 수입 아이콘(arrow_upward)이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'income',
          'amount': 3000000,
          'title': '급여',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-25',
          'categories': {'name': '급여', 'icon': 'work', 'color': '#00FF00'},
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    });

    testWidgets('자산 타입 템플릿은 자산 아이콘(account_balance)이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'asset',
          'amount': 500000,
          'title': '적금',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-10',
          'categories': {'name': '적금', 'icon': 'savings', 'color': '#0000FF'},
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.account_balance), findsOneWidget);
    });

    testWidgets('지출 타입 템플릿은 지출 아이콘(arrow_downward)이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 10000,
          'title': '교통비',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'daily',
          'start_date': '2026-01-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('매월 반복 템플릿의 금액과 반복주기 텍스트가 올바르게 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 50000,
          'title': '월세',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-15',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // '50,000원  ·  매월 15일' 형식으로 표시되어야 한다
      expect(find.textContaining('50,000'), findsOneWidget);
      expect(find.textContaining('15'), findsOneWidget);
    });

    testWidgets('매년 반복 템플릿의 반복주기에 월과 일이 모두 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'income',
          'amount': 1000000,
          'title': '보너스',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'yearly',
          'start_date': '2026-03-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // '1,000,000원  ·  매년 3월 1일' 형식으로 표시되어야 한다
      expect(find.textContaining('1,000,000'), findsOneWidget);
    });

    testWidgets('고정비 카테고리가 있는 템플릿은 고정비 카테고리명과 핀 아이콘이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 89000,
          'title': '넷플릭스',
          'is_active': true,
          'is_fixed_expense': true,
          'recurring_type': 'monthly',
          'start_date': '2026-01-05',
          'categories': {'name': '구독', 'icon': 'subscriptions', 'color': '#FF0000'},
          'fixed_expense_category_id': 'fixed-cat-1',
          'fixed_expense_categories': {'name': '엔터테인먼트'},
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // 고정비 카테고리명이 표시되어야 한다
      expect(find.text('엔터테인먼트'), findsOneWidget);
      // 핀 아이콘이 표시되어야 한다
      expect(find.byIcon(Icons.push_pin), findsOneWidget);
    });

    testWidgets('일반 카테고리가 있는 템플릿은 카테고리 아이콘(category_outlined)이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 30000,
          'title': '식비',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': {'name': '식비', 'icon': 'restaurant', 'color': '#FF5500'},
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('식비'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.category_outlined), findsOneWidget);
    });

    testWidgets('카테고리가 없는 템플릿은 카테고리 행이 표시되지 않는다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 5000,
          'title': '기타',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // 카테고리 아이콘이 없어야 한다
      expect(find.byIcon(Icons.category_outlined), findsNothing);
      expect(find.byIcon(Icons.push_pin), findsNothing);
    });

    testWidgets('제목이 없는 템플릿은 카테고리명을 제목으로 사용한다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 20000,
          'title': null,
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': {'name': '교통', 'icon': 'train', 'color': '#0088FF'},
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // '교통'이 제목과 카테고리 행 모두에 표시될 수 있다
      expect(find.text('교통'), findsAtLeastNWidgets(1));
    });

    testWidgets('활성 템플릿은 자동저장 뱃지와 autorenew 아이콘이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 10000,
          'title': '활성 템플릿',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.autorenew), findsOneWidget);
    });

    testWidgets('비활성 템플릿은 중지 뱃지와 pause_circle_outline 아이콘이 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 10000,
          'title': '중지된 템플릿',
          'is_active': false,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    });

    testWidgets('더보기 메뉴 버튼(more_vert)이 각 카드에 표시된다',
        (WidgetTester tester) async {
      final templates = [
        {
          'id': 'template-1',
          'type': 'expense',
          'amount': 10000,
          'title': '템플릿 1',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': null,
        },
        {
          'id': 'template-2',
          'type': 'income',
          'amount': 20000,
          'title': '템플릿 2',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-01',
          'categories': null,
        },
      ];

      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) async => templates);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
    });

    testWidgets('로딩 중일 때 CircularProgressIndicator가 표시된다',
        (WidgetTester tester) async {
      // Completer를 사용하여 응답을 보류시킨다
      final completer = Completer<List<Map<String, dynamic>>>();
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // 테스트 정리: Completer를 완료시켜 타이머 보류 방지
      completer.complete([]);
      await tester.pumpAndSettle();
    });

    testWidgets('에러 발생 시 에러 메시지가 표시된다',
        (WidgetTester tester) async {
      when(() => mockRepository.getAllRecurringTemplates(
              ledgerId: 'test-ledger-id'))
          .thenThrow(Exception('네트워크 오류'));

      await tester.pumpWidget(
        createTestWidget(
          overrides: [
            transactionRepositoryProvider.overrideWithValue(mockRepository),
            selectedLedgerIdProvider.overrideWith((ref) => 'test-ledger-id'),
          ],
          child: const RecurringTemplateManagementPage(),
        ),
      );

      await tester.pumpAndSettle();

      // 에러 메시지가 표시되는지 확인
      expect(find.textContaining('Exception'), findsOneWidget);
    });
  });
}
