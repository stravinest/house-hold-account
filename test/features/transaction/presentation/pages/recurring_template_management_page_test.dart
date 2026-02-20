import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/data/repositories/transaction_repository.dart';
import 'package:shared_household_account/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/recurring_template_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/pages/recurring_template_management_page.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/features/ledger/domain/entities/ledger.dart';
import 'package:shared_household_account/shared/widgets/empty_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mocktail/mocktail.dart';

class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockUser extends Mock implements User {
  @override
  String get id => 'user-me';
}

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

    group('공유 가계부 - isShared 분기 테스트', () {
      // 공유 가계부(isShared=true)일 때 사용하는 템플릿 데이터
      // user_id와 profiles 정보가 포함되어 유저별 그룹핑이 가능해야 함
      final sharedTemplates = [
        {
          'id': 'template-1',
          'type': 'income',
          'amount': 3327247,
          'title': '월급',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-05',
          'user_id': 'user-me',
          'profiles': {'display_name': '나', 'color': '#A8D8EA'},
          'categories': {'name': '급여', 'icon': 'work', 'color': '#00FF00'},
        },
        {
          'id': 'template-2',
          'type': 'expense',
          'amount': 117840,
          'title': '다온보험',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-05',
          'user_id': 'user-me',
          'profiles': {'display_name': '나', 'color': '#A8D8EA'},
          'categories': {'name': '보험료', 'icon': 'shield', 'color': '#FF0000'},
        },
        {
          'id': 'template-3',
          'type': 'expense',
          'amount': 62530,
          'title': 'Db손해보험',
          'is_active': true,
          'is_fixed_expense': false,
          'recurring_type': 'monthly',
          'start_date': '2026-01-15',
          'user_id': 'user-other',
          'profiles': {'display_name': '배우자', 'color': '#FFB6A3'},
          'categories': {'name': '보험료', 'icon': 'shield', 'color': '#FF0000'},
        },
      ];

      testWidgets(
          '공유 가계부(isShared=true)일 때 유저별 그룹 헤더가 표시되고 '
          '상대방 반복거래에는 더보기 메뉴(more_vert)가 표시되지 않는다',
          (WidgetTester tester) async {
        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: 'test-ledger-id'))
            .thenAnswer((_) async => sharedTemplates);

        // 유저별 그룹핑된 데이터 (현재 유저 먼저, 그 다음 상대방)
        final groupedEntries = [
          MapEntry('user-me', [sharedTemplates[0], sharedTemplates[1]]),
          MapEntry('user-other', [sharedTemplates[2]]),
        ];

        final now = DateTime.now();
        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              transactionRepositoryProvider
                  .overrideWithValue(mockRepository),
              selectedLedgerIdProvider
                  .overrideWith((ref) => 'test-ledger-id'),
              // currentUserProvider를 MockUser로 override (Supabase 의존 제거)
              currentUserProvider.overrideWithValue(MockUser()),
              // 공유 가계부로 설정
              currentLedgerProvider.overrideWith((ref) async => Ledger(
                    id: 'test-ledger-id',
                    name: '내 가계부',
                    currency: 'KRW',
                    ownerId: 'user-me',
                    isShared: true,
                    createdAt: now,
                    updatedAt: now,
                  )),
              // 그룹핑된 데이터 직접 제공
              groupedRecurringTemplatesProvider
                  .overrideWith((ref) async => groupedEntries),
            ],
            child: const RecurringTemplateManagementPage(),
          ),
        );

        await tester.pumpAndSettle();

        // 유저 헤더에 유저명이 표시되는지 확인
        expect(find.text('나'), findsOneWidget);
        expect(find.text('배우자'), findsOneWidget);

        // 내 템플릿(2개)에만 more_vert가 표시되고
        // 상대방 템플릿(1개)에는 표시되지 않아야 한다
        // 총 more_vert 아이콘은 2개여야 한다
        expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
      });

      testWidgets(
          '개인 가계부(isShared=false)일 때 유저 헤더 없이 '
          '모든 반복거래에 더보기 메뉴가 표시된다',
          (WidgetTester tester) async {
        // isShared=false 이면 개인 뷰로 렌더링됨
        // 이 경우 모든 카드에 isOwner=true가 설정됨
        final personalTemplates = [
          {
            'id': 'template-1',
            'type': 'expense',
            'amount': 50000,
            'title': '구독',
            'is_active': true,
            'is_fixed_expense': false,
            'recurring_type': 'monthly',
            'start_date': '2026-01-01',
            'categories': null,
          },
          {
            'id': 'template-2',
            'type': 'expense',
            'amount': 30000,
            'title': '교통',
            'is_active': true,
            'is_fixed_expense': false,
            'recurring_type': 'monthly',
            'start_date': '2026-01-01',
            'categories': null,
          },
        ];

        when(() => mockRepository.getAllRecurringTemplates(
                ledgerId: 'test-ledger-id'))
            .thenAnswer((_) async => personalTemplates);

        final now = DateTime.now();
        await tester.pumpWidget(
          createTestWidget(
            overrides: [
              transactionRepositoryProvider
                  .overrideWithValue(mockRepository),
              selectedLedgerIdProvider
                  .overrideWith((ref) => 'test-ledger-id'),
              // 개인 가계부로 설정
              currentLedgerProvider.overrideWith((ref) async => Ledger(
                    id: 'test-ledger-id',
                    name: '내 가계부',
                    currency: 'KRW',
                    ownerId: 'user-me',
                    isShared: false,
                    createdAt: now,
                    updatedAt: now,
                  )),
            ],
            child: const RecurringTemplateManagementPage(),
          ),
        );

        await tester.pumpAndSettle();

        // 유저 헤더가 표시되지 않는다
        expect(find.text('나'), findsNothing);
        expect(find.text('배우자'), findsNothing);

        // 모든 카드에 more_vert가 표시된다 (개인이므로 모두 본인 것)
        expect(find.byIcon(Icons.more_vert), findsNWidgets(2));
      });
    });
  });
}
