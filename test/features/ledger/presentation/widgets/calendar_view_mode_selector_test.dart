import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/calendar_view_provider.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_view_mode_selector.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildTestApp({
  required CalendarViewMode selectedMode,
  required ValueChanged<CalendarViewMode> onModeChanged,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(
      body: CalendarViewModeSelector(
        selectedMode: selectedMode,
        onModeChanged: onModeChanged,
      ),
    ),
  );
}

void main() {
  group('CalendarViewModeSelector 위젯 테스트', () {
    testWidgets('선택된 모드에 따라 올바른 탭이 활성화된다', (tester) async {
      // Given
      CalendarViewMode? changedMode;

      // When
      await tester.pumpWidget(
        _buildTestApp(
          selectedMode: CalendarViewMode.daily,
          onModeChanged: (mode) => changedMode = mode,
        ),
      );
      await tester.pump();

      // Then
      expect(find.text('일'), findsOneWidget);
      expect(find.text('주'), findsOneWidget);
      expect(find.text('월'), findsOneWidget);
      expect(changedMode, isNull);
    });

    testWidgets('일간 탭을 탭하면 콜백이 호출된다', (tester) async {
      // Given
      CalendarViewMode? changedMode;

      await tester.pumpWidget(
        _buildTestApp(
          selectedMode: CalendarViewMode.monthly,
          onModeChanged: (mode) => changedMode = mode,
        ),
      );
      await tester.pump();

      // When - 일 탭 클릭
      await tester.tap(find.text('일'));
      await tester.pumpAndSettle();

      // Then
      expect(changedMode, CalendarViewMode.daily);
    });

    testWidgets('주간 탭을 탭하면 콜백이 호출된다', (tester) async {
      // Given
      CalendarViewMode? changedMode;

      await tester.pumpWidget(
        _buildTestApp(
          selectedMode: CalendarViewMode.daily,
          onModeChanged: (mode) => changedMode = mode,
        ),
      );
      await tester.pump();

      // When - 주 탭 클릭
      await tester.tap(find.text('주'));
      await tester.pumpAndSettle();

      // Then
      expect(changedMode, CalendarViewMode.weekly);
    });

    testWidgets('월간 탭을 탭하면 콜백이 호출된다', (tester) async {
      // Given
      CalendarViewMode? changedMode;

      await tester.pumpWidget(
        _buildTestApp(
          selectedMode: CalendarViewMode.daily,
          onModeChanged: (mode) => changedMode = mode,
        ),
      );
      await tester.pump();

      // When - 월 탭 클릭
      await tester.tap(find.text('월'));
      await tester.pumpAndSettle();

      // Then
      expect(changedMode, CalendarViewMode.monthly);
    });

    testWidgets('각 모드에 맞는 아이콘이 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          selectedMode: CalendarViewMode.daily,
          onModeChanged: (_) {},
        ),
      );
      await tester.pump();

      // Then
      expect(find.byIcon(Icons.view_day), findsOneWidget);
      expect(find.byIcon(Icons.view_week_outlined), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_outlined), findsOneWidget);
    });

    testWidgets('선택된 탭은 강조 표시된다', (tester) async {
      // Given
      await tester.pumpWidget(
        _buildTestApp(
          selectedMode: CalendarViewMode.weekly,
          onModeChanged: (_) {},
        ),
      );
      await tester.pump();

      // Then - 선택된 아이콘(weekly)이 표시되는지 확인
      expect(find.byIcon(Icons.view_week), findsOneWidget);
    });
  });
}
