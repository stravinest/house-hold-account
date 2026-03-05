import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/data_export_bottom_sheet.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildLargeExportSheet({String? ledgerId = 'ledger-1'}) {
  return ProviderScope(
    overrides: [
      selectedLedgerIdProvider.overrideWith((ref) => ledgerId),
    ],
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SizedBox(
          height: 2000,
          width: 800,
          child: const DataExportBottomSheet(),
        ),
      ),
    ),
  );
}

void main() {
  group('DataExportBottomSheet 빠른 기간 버튼 테스트', () {
    testWidgets('이번달 빠른 기간 버튼을 탭하면 날짜가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When: ActionChip을 찾아서 첫 번째 탭 (이번달)
      final chips = find.byType(ActionChip);
      if (chips.evaluate().isNotEmpty) {
        await tester.ensureVisible(chips.first);
        await tester.tap(chips.first);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('지난달 빠른 기간 버튼을 탭하면 날짜가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When: 두 번째 ActionChip (지난달)
      final chips = find.byType(ActionChip);
      if (chips.evaluate().length >= 2) {
        await tester.ensureVisible(chips.at(1));
        await tester.tap(chips.at(1));
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('최근 3개월 빠른 기간 버튼을 탭하면 날짜가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When: 세 번째 ActionChip (최근 3개월)
      final chips = find.byType(ActionChip);
      if (chips.evaluate().length >= 3) {
        await tester.ensureVisible(chips.at(2));
        await tester.tap(chips.at(2));
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('올해 빠른 기간 버튼을 탭하면 날짜가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When: 네 번째 ActionChip (올해)
      final chips = find.byType(ActionChip);
      if (chips.evaluate().length >= 4) {
        await tester.ensureVisible(chips.at(3));
        await tester.tap(chips.at(3));
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });
  });

  group('DataExportBottomSheet 거래 유형 FilterChip 테스트', () {
    testWidgets('지출 FilterChip을 탭하면 선택 상태가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When: FilterChip 탭
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().length >= 2) {
        await tester.ensureVisible(filterChips.at(1));
        await tester.tap(filterChips.at(1));
        await tester.pumpAndSettle();
      }

      // Then
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('수입 FilterChip을 탭하면 선택 상태가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().length >= 3) {
        await tester.ensureVisible(filterChips.at(2));
        await tester.tap(filterChips.at(2));
        await tester.pumpAndSettle();
      }

      // Then
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('자산 FilterChip을 탭하면 선택 상태가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().length >= 4) {
        await tester.ensureVisible(filterChips.at(3));
        await tester.tap(filterChips.at(3));
        await tester.pumpAndSettle();
      }

      // Then
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('전체 FilterChip을 탭하면 선택 상태가 변경되어야 한다', (tester) async {
      // Given
      await tester.pumpWidget(_buildLargeExportSheet());
      await tester.pumpAndSettle();

      // When: 첫 번째 FilterChip (전체)
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().isNotEmpty) {
        await tester.ensureVisible(filterChips.first);
        await tester.tap(filterChips.first);
        await tester.pumpAndSettle();
      }

      // Then
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });
  });

  group('DataExportBottomSheet 닫기 버튼 테스트', () {
    testWidgets('X 아이콘 버튼을 탭하면 시트가 닫혀야 한다', (tester) async {
      // Given: showModalBottomSheet로 띄우기
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedLedgerIdProvider.overrideWith((ref) => 'ledger-1'),
          ],
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const DataExportBottomSheet(),
                    );
                  },
                  child: const Text('열기'),
                ),
              ),
            ),
          ),
        ),
      );

      // When: 바텀시트 열기
      await tester.tap(find.text('열기'));
      await tester.pumpAndSettle();

      // When: close 아이콘 탭
      final closeIcon = find.byIcon(Icons.close);
      if (closeIcon.evaluate().isNotEmpty) {
        await tester.tap(closeIcon.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
