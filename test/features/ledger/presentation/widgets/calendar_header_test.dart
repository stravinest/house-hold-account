import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/widgets/calendar_header.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

void main() {
  group('CalendarHeader 위젯 테스트', () {
    testWidgets('기본 렌더링이 정상적으로 된다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 15);
      bool todayPressed = false;
      bool refreshCalled = false;
      bool listViewToggled = false;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {
                todayPressed = true;
              },
              onPreviousMonth: () {},
              onNextMonth: () {},
              onRefresh: () async {
                refreshCalled = true;
              },
              showListView: false,
              onListViewToggle: () {
                listViewToggled = true;
              },
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(CalendarHeader), findsOneWidget);
      expect(todayPressed, isFalse);
      expect(refreshCalled, isFalse);
      expect(listViewToggled, isFalse);
    });

    testWidgets('이전 월 버튼이 작동한다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 15);
      bool previousCalled = false;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {},
              onPreviousMonth: () {
                previousCalled = true;
              },
              onNextMonth: () {},
              onRefresh: () async {},
              showListView: false,
              onListViewToggle: () {},
            ),
          ),
        ),
      );

      final leftButton = find.byIcon(Icons.chevron_left);
      expect(leftButton, findsOneWidget);

      await tester.tap(leftButton);
      await tester.pumpAndSettle();

      // Then
      expect(previousCalled, isTrue);
    });

    testWidgets('다음 월 버튼이 작동한다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 15);
      bool nextCalled = false;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {},
              onPreviousMonth: () {},
              onNextMonth: () {
                nextCalled = true;
              },
              onRefresh: () async {},
              showListView: false,
              onListViewToggle: () {},
            ),
          ),
        ),
      );

      final rightButton = find.byIcon(Icons.chevron_right);
      expect(rightButton, findsOneWidget);

      await tester.tap(rightButton);
      await tester.pumpAndSettle();

      // Then
      expect(nextCalled, isTrue);
    });

    testWidgets('새로고침 버튼이 작동한다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 15);
      bool refreshCalled = false;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {},
              onPreviousMonth: () {},
              onNextMonth: () {},
              onRefresh: () async {
                refreshCalled = true;
              },
              showListView: false,
              onListViewToggle: () {},
            ),
          ),
        ),
      );

      final refreshIcon = find.byIcon(Icons.refresh);
      expect(refreshIcon, findsOneWidget);

      await tester.tap(refreshIcon);
      await tester.pumpAndSettle();

      // Then
      expect(refreshCalled, isTrue);
    });

    testWidgets('리스트 뷰 토글이 작동한다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 15);
      bool listViewToggled = false;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {},
              onPreviousMonth: () {},
              onNextMonth: () {},
              onRefresh: () async {},
              showListView: false,
              onListViewToggle: () {
                listViewToggled = true;
              },
            ),
          ),
        ),
      );

      final listIcon = find.byIcon(Icons.format_list_bulleted);
      expect(listIcon, findsOneWidget);

      await tester.tap(listIcon);
      await tester.pumpAndSettle();

      // Then
      expect(listViewToggled, isTrue);
    });

    testWidgets('오늘 버튼이 오늘이 아닐 때 작동한다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 10);
      bool todayPressed = false;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {
                todayPressed = true;
              },
              onPreviousMonth: () {},
              onNextMonth: () {},
              onRefresh: () async {},
              showListView: false,
              onListViewToggle: () {},
            ),
          ),
        ),
      );

      final todayIcon = find.byIcon(Icons.today);
      expect(todayIcon, findsOneWidget);

      await tester.tap(todayIcon);
      await tester.pumpAndSettle();

      // Then
      expect(todayPressed, isTrue);
    });

    testWidgets('중복 새로고침 요청이 방지된다', (tester) async {
      // Given
      final focusedDate = DateTime(2024, 1, 15);
      final selectedDate = DateTime(2024, 1, 15);
      int refreshCount = 0;

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
            body: CalendarHeader(
              focusedDate: focusedDate,
              selectedDate: selectedDate,
              onTodayPressed: () {},
              onPreviousMonth: () {},
              onNextMonth: () {},
              onRefresh: () async {
                refreshCount++;
                await Future.delayed(const Duration(milliseconds: 100));
              },
              showListView: false,
              onListViewToggle: () {},
            ),
          ),
        ),
      );

      final refreshIcon = find.byIcon(Icons.refresh);

      await tester.tap(refreshIcon);
      await tester.tap(refreshIcon);
      await tester.pumpAndSettle();

      // Then - 한 번만 호출되어야 함
      expect(refreshCount, equals(1));
    });
  });
}
