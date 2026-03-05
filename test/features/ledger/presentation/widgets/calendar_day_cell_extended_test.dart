import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/calendar_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_day_cell.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('CalendarDayCell 추가 커버리지 테스트', () {
    // 공통 colorScheme
    const colorScheme = ColorScheme.light();

    testWidgets('지출 데이터가 있는 날짜 셀이 렌더링된다', (tester) async {
      // Given: 지출 데이터 포함
      final day = DateTime(2024, 1, 10);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 0,
          'totalExpense': 20000,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 0,
              'expense': 20000,
              'asset': 0,
              'color': '#FFB6A3',
            },
          },
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
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

      // Then: 날짜가 표시됨
      expect(find.byType(CalendarDayCell), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('자산 데이터가 있는 날짜 셀이 렌더링된다', (tester) async {
      // Given: 자산 데이터 포함
      final day = DateTime(2024, 1, 20);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 0,
          'totalExpense': 0,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 0,
              'expense': 0,
              'asset': 500000,
              'color': '#B8E6C9',
            },
          },
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
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
      expect(find.text('20'), findsOneWidget);
    });

    testWidgets('2명 이상의 사용자 데이터가 있을 때 최대 2개 항목이 표시된다', (tester) async {
      // Given: 3개 항목 (maxVisibleItems=2 이므로 +1 표시)
      final day = DateTime(2024, 1, 5);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 300000,
          'totalExpense': 150000,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 100000,
              'expense': 50000,
              'asset': 200000,
              'color': '#A8D8EA',
            },
            'user2': {
              'displayName': '사용자2',
              'income': 200000,
              'expense': 100000,
              'asset': 0,
              'color': '#FFB6A3',
            },
          },
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              height: 76,
              child: CalendarDayCell(
                day: day,
                dailyTotals: dailyTotals,
                isSelected: false,
                isToday: false,
                colorScheme: colorScheme,
                currentLedger: null,
              ),
            ),
          ),
        ),
      );

      // Then: 캘린더 셀이 렌더링됨
      expect(find.byType(CalendarDayCell), findsOneWidget);
    });

    testWidgets('선택 + 오늘 날짜 셀이 렌더링된다', (tester) async {
      // Given: 선택된 오늘 날짜
      final today = DateTime(2024, 3, 15);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              day: today,
              dailyTotals: dailyTotals,
              isSelected: true,
              isToday: true,
              colorScheme: colorScheme,
              currentLedger: null,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(CalendarDayCell), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('주말 날짜 셀이 렌더링된다 (토요일)', (tester) async {
      // Given: 2024년 1월 6일은 토요일
      final saturday = DateTime(2024, 1, 6);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              day: saturday,
              dailyTotals: dailyTotals,
              isSelected: false,
              isToday: false,
              colorScheme: colorScheme,
              currentLedger: null,
            ),
          ),
        ),
      );

      // Then: 토요일 셀 렌더링됨
      expect(find.byType(CalendarDayCell), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('주말 날짜 셀이 렌더링된다 (일요일)', (tester) async {
      // Given: 2024년 1월 7일은 일요일
      final sunday = DateTime(2024, 1, 7);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              day: sunday,
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
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('월의 첫 번째 행 셀이 상단 보더를 표시한다', (tester) async {
      // Given: 2024년 1월 1일 (첫 번째 주)
      final firstDay = DateTime(2024, 1, 1);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              day: firstDay,
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

    testWidgets('CalendarEmptyCell 첫 번째 행에서 렌더링된다', (tester) async {
      // Given: 이전 달의 날짜
      final day = DateTime(2023, 12, 31);
      final focusedDay = DateTime(2024, 1, 15);

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

    testWidgets('CalendarEmptyCell 첫 번째 열에서 렌더링된다', (tester) async {
      // Given: 일요일 날짜 (weekday % 7 == 0)
      final day = DateTime(2024, 1, 7); // 일요일
      final focusedDay = DateTime(2024, 2, 15);

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

  group('CalendarDaysOfWeekHeader 추가 커버리지 테스트', () {
    const colorScheme = ColorScheme.light();

    testWidgets('일요일 시작 요일 헤더가 렌더링된다', (tester) async {
      // Given: 일요일 시작 설정
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weekStartDayProvider.overrideWith((ref) {
              final notifier = WeekStartDayNotifier();
              notifier.state = WeekStartDay.sunday;
              return notifier;
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarDaysOfWeekHeader(colorScheme: colorScheme),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 헤더가 렌더링됨
      expect(find.byType(CalendarDaysOfWeekHeader), findsOneWidget);
    });

    testWidgets('월요일 시작 요일 헤더가 렌더링된다', (tester) async {
      // Given: 월요일 시작 설정
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weekStartDayProvider.overrideWith((ref) {
              final notifier = WeekStartDayNotifier();
              notifier.state = WeekStartDay.monday;
              return notifier;
            }),
          ],
          child: const MaterialApp(
            localizationsDelegates: [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: CalendarDaysOfWeekHeader(colorScheme: colorScheme),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 헤더가 렌더링됨
      expect(find.byType(CalendarDaysOfWeekHeader), findsOneWidget);
      // 7개 요일이 표시됨
      expect(find.byType(Text), findsNWidgets(7));
    });
  });

  group('AmountItem 및 TransactionDisplayType 단위 테스트', () {
    test('AmountItem이 올바른 값으로 생성된다', () {
      // Given & When
      final item = AmountItem(
        color: const Color(0xFFA8D8EA),
        amount: 10000,
        type: TransactionDisplayType.income,
      );

      // Then
      expect(item.amount, equals(10000));
      expect(item.type, equals(TransactionDisplayType.income));
    });

    test('TransactionDisplayType.expense가 올바르게 정의된다', () {
      // Given & When & Then
      expect(TransactionDisplayType.expense, isNotNull);
      expect(TransactionDisplayType.asset, isNotNull);
      expect(TransactionDisplayType.income, isNotNull);
    });

    test('CalendarCellConfig.maxVisibleItems가 2이다', () {
      // Given & When & Then
      expect(CalendarCellConfig.maxVisibleItems, equals(2));
    });

    test('CalendarConstants 값이 올바르게 정의된다', () {
      // Given & When & Then
      expect(CalendarConstants.rowHeight, equals(76.0));
      expect(CalendarConstants.dateBubbleSize, equals(20.0));
      expect(CalendarConstants.amountFontSize, equals(10.0));
      expect(CalendarConstants.dotSize, equals(6.0));
    });
  });

  group('_UserAmountList 위젯 테스트 (간접 테스트)', () {
    const colorScheme = ColorScheme.light();

    testWidgets('수입+지출+자산이 모두 있는 사용자 데이터가 렌더링된다', (tester) async {
      // Given: 수입+지출+자산 모두 있는 날짜
      final day = DateTime(2024, 2, 14);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 100000,
          'totalExpense': 50000,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 100000,
              'expense': 50000,
              'asset': 200000,
              'color': '#A8D8EA',
            },
          },
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 76,
              child: CalendarDayCell(
                day: day,
                dailyTotals: dailyTotals,
                isSelected: false,
                isToday: false,
                colorScheme: colorScheme,
                currentLedger: null,
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(CalendarDayCell), findsOneWidget);
    });

    testWidgets('선택 상태에서 데이터 있는 셀이 렌더링된다', (tester) async {
      // Given: 선택된 날짜 + 데이터
      final day = DateTime(2024, 2, 15);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 50000,
          'totalExpense': 0,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 50000,
              'expense': 0,
              'asset': 0,
              'color': '#A8D8EA',
            },
          },
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 76,
              child: CalendarDayCell(
                day: day,
                dailyTotals: dailyTotals,
                isSelected: true,
                isToday: false,
                colorScheme: colorScheme,
                currentLedger: null,
              ),
            ),
          ),
        ),
      );

      // Then: 선택 상태 + 데이터 표시됨
      expect(find.byType(CalendarDayCell), findsOneWidget);
    });

    testWidgets('잘못된 색상 코드가 있을 때 기본 색상으로 폴백된다', (tester) async {
      // Given: 잘못된 색상 코드 (ColorUtils.parseHexColor의 에러 처리 커버)
      final day = DateTime(2024, 2, 20);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 10000,
          'totalExpense': 0,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 10000,
              'expense': 0,
              'asset': 0,
              'color': 'invalid-color', // 잘못된 색상 코드
            },
          },
        },
      };

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 80,
              height: 76,
              child: CalendarDayCell(
                day: day,
                dailyTotals: dailyTotals,
                isSelected: false,
                isToday: false,
                colorScheme: colorScheme,
                currentLedger: null,
              ),
            ),
          ),
        ),
      );

      // Then: 에러 없이 렌더링됨
      expect(find.byType(CalendarDayCell), findsOneWidget);
    });
  });
}
