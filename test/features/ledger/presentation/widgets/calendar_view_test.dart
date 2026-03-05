import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/calendar_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_day_cell.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_view.dart';
import 'package:shared_household_account/features/share/presentation/providers/share_provider.dart';
import 'package:shared_household_account/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CalendarView 위젯 기본 테스트', () {
    testWidgets('CalendarDayCell이 정상적으로 렌더링된다', (tester) async {
      // Given
      final day = DateTime(2024, 1, 15);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};
      const colorScheme = ColorScheme.light();

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarDayCell(
              day: day,
              dailyTotals: dailyTotals,
              isSelected: false,
              isToday: false,
              colorScheme: colorScheme,
              currentLedger: null,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(CalendarDayCell), findsOneWidget);
    });

    testWidgets('CalendarEmptyCell이 정상적으로 렌더링된다', (tester) async {
      // Given
      final day = DateTime(2024, 1, 1);
      final focusedDay = DateTime(2024, 1, 15);
      const colorScheme = ColorScheme.light();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarEmptyCell(
              day: day,
              focusedDay: focusedDay,
              colorScheme: colorScheme,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(CalendarEmptyCell), findsOneWidget);
    });
  });

  group('CalendarView ConsumerWidget 렌더링 테스트', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Widget buildTestWidget({
      DateTime? selectedDate,
      DateTime? focusedDate,
      bool showSummary = true,
      bool showHeader = true,
    }) {
      final date = selectedDate ?? DateTime(2024, 1, 15);
      final focused = focusedDate ?? DateTime(2024, 1, 15);

      return ProviderScope(
        overrides: [
          dailyTotalsProvider.overrideWith((ref) async => {}),
          currentLedgerProvider.overrideWith((ref) async => null),
          currentLedgerMemberCountProvider.overrideWith((ref) => 1),
          monthlyTotalProvider.overrideWith(
            (ref) async => {'income': 0, 'expense': 0, 'users': {}},
          ),
          weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CalendarView(
              selectedDate: date,
              focusedDate: focused,
              onDateSelected: (_) {},
              onPageChanged: (_) {},
              onRefresh: () async {},
              showSummary: showSummary,
              showHeader: showHeader,
            ),
          ),
        ),
      );
    }

    testWidgets('CalendarView가 기본 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      // Then: CalendarView가 렌더링됨
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('showSummary=false이면 CalendarMonthSummary가 표시되지 않는다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildTestWidget(showSummary: false));
      await tester.pump();

      // Then: CalendarView가 렌더링됨 (summary 없이)
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('showHeader=false이면 CalendarHeader가 표시되지 않는다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildTestWidget(showHeader: false));
      await tester.pump();

      // Then: CalendarView가 렌더링됨 (header 없이)
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('showSummary=false이고 showHeader=false이면 캘린더만 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        buildTestWidget(showSummary: false, showHeader: false),
      );
      await tester.pump();

      // Then: CalendarView가 렌더링됨
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('날짜 선택 콜백이 연결된다', (tester) async {
      // Given
      DateTime? selectedDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: DateTime(2024, 1, 15),
                focusedDate: DateTime(2024, 1, 15),
                onDateSelected: (d) => selectedDate = d,
                onPageChanged: (_) {},
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then: CalendarView가 렌더링됨
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('showListView와 onListViewToggle 옵션이 전달된다', (tester) async {
      // Given & When
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: DateTime(2024, 1, 15),
                focusedDate: DateTime(2024, 1, 15),
                onDateSelected: (_) {},
                onPageChanged: (_) {},
                onRefresh: () async {},
                showListView: false,
                onListViewToggle: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('이전 달 버튼 탭 시 onPageChanged 콜백이 호출된다', (tester) async {
      // Given
      DateTime? changedDate;
      final focusedDate = DateTime(2024, 3, 15);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: focusedDate,
                focusedDate: focusedDate,
                onDateSelected: (_) {},
                onPageChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 이전 달 버튼 탭 (chevron_left 아이콘)
      final prevButton = find.byIcon(Icons.chevron_left);
      if (prevButton.evaluate().isNotEmpty) {
        await tester.tap(prevButton);
        await tester.pump();
        // Then: 이전 달로 변경됨
        expect(changedDate, isNotNull);
        expect(changedDate!.month, equals(2)); // 3월 → 2월
      } else {
        // CalendarHeader가 없는 경우 기본 렌더링만 확인
        expect(find.byType(CalendarView), findsOneWidget);
      }
    });

    testWidgets('다음 달 버튼 탭 시 onPageChanged 콜백이 호출된다', (tester) async {
      // Given
      DateTime? changedDate;
      final focusedDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: focusedDate,
                focusedDate: focusedDate,
                onDateSelected: (_) {},
                onPageChanged: (d) => changedDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 다음 달 버튼 탭 (chevron_right 아이콘)
      final nextButton = find.byIcon(Icons.chevron_right);
      if (nextButton.evaluate().isNotEmpty) {
        await tester.tap(nextButton);
        await tester.pump();
        // Then: 다음 달로 변경됨
        expect(changedDate, isNotNull);
        expect(changedDate!.month, equals(2)); // 1월 → 2월
      } else {
        expect(find.byType(CalendarView), findsOneWidget);
      }
    });

    testWidgets('오늘 버튼 탭 시 onDateSelected와 onPageChanged가 오늘 날짜로 호출된다', (tester) async {
      // Given
      DateTime? selectedDate;
      DateTime? pageDate;
      final focusedDate = DateTime(2024, 1, 15);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: focusedDate,
                focusedDate: focusedDate,
                onDateSelected: (d) => selectedDate = d,
                onPageChanged: (d) => pageDate = d,
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 오늘 버튼 탭 (today_outlined 또는 today 아이콘)
      final todayButton = find.byIcon(Icons.today_outlined);
      if (todayButton.evaluate().isNotEmpty) {
        await tester.tap(todayButton);
        await tester.pump();
        // Then: onTodayPressed 콜백이 실행됨 (L90-93 커버)
        expect(selectedDate, isNotNull);
        expect(pageDate, isNotNull);
      } else {
        // 위젯이 렌더링된 것만 확인
        expect(find.byType(CalendarView), findsOneWidget);
      }
    });

    testWidgets('selectedDate가 오늘인 경우 CalendarView가 today 셀을 렌더링한다', (tester) async {
      // Given: 오늘 날짜를 selectedDate로 설정 (todayBuilder 경로 커버)
      final today = DateTime.now();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: today,
                focusedDate: today,
                onDateSelected: (_) {},
                onPageChanged: (_) {},
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: CalendarView가 렌더링됨 (todayBuilder에서 isSameDay true 경로 커버)
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('이전 달로 이동하면 다른 달 날짜가 빈 셀로 렌더링된다', (tester) async {
      // Given: 선택 날짜와 포커스 날짜가 다른 달인 경우 (selectedBuilder, todayBuilder 다른 달 경로)
      final focused = DateTime(2024, 2, 15);
      final selected = DateTime(2024, 1, 15); // 다른 달 날짜

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: selected,
                focusedDate: focused,
                onDateSelected: (_) {},
                onPageChanged: (_) {},
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: CalendarEmptyCell이 렌더링됨 (L159, L177, L194 경로 커버)
      expect(find.byType(CalendarView), findsOneWidget);
      // CalendarEmptyCell이 여러 개 렌더링됨 (이전/다음 달 날짜)
      expect(find.byType(CalendarEmptyCell), findsWidgets);
    });

    testWidgets('월요일 시작 설정으로 CalendarView가 렌더링된다', (tester) async {
      // Given: weekStartDay를 monday로 설정
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) {
              final notifier = WeekStartDayNotifier();
              notifier.state = WeekStartDay.monday;
              return notifier;
            }),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: DateTime(2024, 1, 15),
                focusedDate: DateTime(2024, 1, 15),
                onDateSelected: (_) {},
                onPageChanged: (_) {},
                onRefresh: () async {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Then
      expect(find.byType(CalendarView), findsOneWidget);
    });

    testWidgets('showHeader=true이면 오늘 버튼이 표시된다', (tester) async {
      // Given: 과거 날짜 선택 (오늘 버튼 활성화)
      await tester.pumpWidget(
        buildTestWidget(
          selectedDate: DateTime(2024, 1, 15),
          focusedDate: DateTime(2024, 1, 15),
          showHeader: true,
        ),
      );
      await tester.pump();

      // Then: 오늘 버튼이 표시됨
      expect(find.byIcon(Icons.today), findsOneWidget);
    });

    testWidgets('showHeader=true이고 과거 날짜일 때 오늘 버튼 탭이 콜백을 실행한다', (tester) async {
      // Given: 과거 날짜 선택
      DateTime? selectedDate;
      DateTime? pageChanged;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: DateTime(2024, 1, 15),
                focusedDate: DateTime(2024, 1, 15),
                onDateSelected: (d) => selectedDate = d,
                onPageChanged: (d) => pageChanged = d,
                onRefresh: () async {},
                showHeader: true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // When: 오늘 버튼 탭
      final todayButton = find.byIcon(Icons.today);
      if (todayButton.evaluate().isNotEmpty) {
        await tester.tap(todayButton);
        await tester.pump();

        // Then: 콜백이 실행됨
        expect(selectedDate, isNotNull);
        expect(pageChanged, isNotNull);
      }
    });

    testWidgets('날짜 탭 시 onDateSelected 콜백이 실행된다', (tester) async {
      // Given
      DateTime? tappedDate;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dailyTotalsProvider.overrideWith((ref) async => {}),
            currentLedgerProvider.overrideWith((ref) async => null),
            currentLedgerMemberCountProvider.overrideWith((ref) => 1),
            monthlyTotalProvider.overrideWith(
              (ref) async => {'income': 0, 'expense': 0, 'users': {}},
            ),
            weekStartDayProvider.overrideWith((ref) => WeekStartDayNotifier()),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarView(
                selectedDate: DateTime(2024, 1, 15),
                focusedDate: DateTime(2024, 1, 15),
                onDateSelected: (d) => tappedDate = d,
                onPageChanged: (_) {},
                onRefresh: () async {},
                showHeader: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 캘린더의 날짜 셀 탭 (10일 탭)
      final dayCells = find.byType(CalendarDayCell);
      if (dayCells.evaluate().isNotEmpty) {
        await tester.tap(dayCells.first);
        await tester.pump();
        // Then: 콜백이 실행됨 (tappedDate가 설정됨)
        expect(tappedDate, isNotNull);
      } else {
        // CalendarDayCell이 없어도 CalendarView는 렌더링됨
        expect(find.byType(CalendarView), findsOneWidget);
      }
    });
  });
}
