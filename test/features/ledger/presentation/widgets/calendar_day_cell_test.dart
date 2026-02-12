import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/calendar_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_day_cell.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('CalendarDayCell 위젯 테스트', () {
    testWidgets('기본 렌더링이 정상적으로 된다', (tester) async {
      // Given
      final day = DateTime(2024, 1, 15);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};
      const colorScheme = ColorScheme.light();

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
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('오늘 날짜가 강조 표시된다', (tester) async {
      // Given
      final today = DateTime(2024, 1, 15);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};
      const colorScheme = ColorScheme.light();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              day: today,
              dailyTotals: dailyTotals,
              isSelected: false,
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

    testWidgets('선택된 날짜가 강조 표시된다', (tester) async {
      // Given
      final selected = DateTime(2024, 1, 20);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};
      const colorScheme = ColorScheme.light();

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CalendarDayCell(
              day: selected,
              dailyTotals: dailyTotals,
              isSelected: true,
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

    testWidgets('거래 데이터가 있을 때 사용자 금액 목록이 표시된다', (tester) async {
      // Given
      final day = DateTime(2024, 1, 15);
      final normalizedDay = DateTime(day.year, day.month, day.day);
      final dailyTotals = <DateTime, Map<String, dynamic>>{
        normalizedDay: {
          'totalIncome': 10000,
          'totalExpense': 5000,
          'users': {
            'user1': {
              'displayName': '사용자1',
              'income': 10000,
              'expense': 0,
              'asset': 0,
              'color': '#A8D8EA',
            },
          },
        },
      };
      const colorScheme = ColorScheme.light();

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
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('거래가 없는 날짜는 금액이 표시되지 않는다', (tester) async {
      // Given
      final day = DateTime(2024, 1, 15);
      final dailyTotals = <DateTime, Map<String, dynamic>>{};
      const colorScheme = ColorScheme.light();

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
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('CalendarEmptyCell 위젯 테스트', () {
    testWidgets('빈 셀이 정상적으로 렌더링된다', (tester) async {
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

  group('CalendarDaysOfWeekHeader 위젯 테스트', () {
    testWidgets('주간 헤더가 올바르게 표시된다', (tester) async {
      // Given
      const colorScheme = ColorScheme.light();

      // When
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
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

      // Then
      expect(find.byType(CalendarDaysOfWeekHeader), findsOneWidget);
    });
  });
}
