import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_day_cell.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('CalendarView 위젯 관련 기본 테스트', () {
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
}
