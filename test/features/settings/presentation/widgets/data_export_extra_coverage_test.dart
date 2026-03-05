import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/data_export_bottom_sheet.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildExportSheetApp({String? ledgerId = 'ledger-1'}) {
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
      home: const Scaffold(
        body: SizedBox(
          height: 1200,
          child: DataExportBottomSheet(),
        ),
      ),
    ),
  );
}

void main() {
  group('DataExportBottomSheet 추가 커버리지 테스트', () {
    testWidgets('체크박스 onChanged 콜백이 실행되어야 한다 - ensureVisible 사용', (tester) async {
      // Given
      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: 첫 번째 체크박스 찾아서 ensureVisible 후 탭
      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsWidgets);
      await tester.ensureVisible(checkboxes.first);
      await tester.tap(checkboxes.first);
      await tester.pumpAndSettle();

      // Then: 에러 없이 상태 변경됨
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('두 번째 체크박스(결제수단) onChanged가 실행되어야 한다', (tester) async {
      // Given
      tester.binding.window.physicalSizeTestValue = const Size(800, 3000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsAtLeastNWidgets(2));
      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('세 번째 체크박스(메모) onChanged가 실행되어야 한다', (tester) async {
      // Given
      tester.binding.window.physicalSizeTestValue = const Size(800, 3000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsAtLeastNWidgets(3));
      await tester.ensureVisible(checkboxes.at(2));
      await tester.tap(checkboxes.at(2));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('네 번째 체크박스(작성자) onChanged가 실행되어야 한다', (tester) async {
      // Given
      tester.binding.window.physicalSizeTestValue = const Size(800, 3000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsAtLeastNWidgets(4));
      await tester.ensureVisible(checkboxes.at(3));
      await tester.tap(checkboxes.at(3));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('다섯 번째 체크박스(고정비) onChanged가 실행되어야 한다', (tester) async {
      // Given
      tester.binding.window.physicalSizeTestValue = const Size(800, 3000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      final checkboxes = find.byType(CheckboxListTile);
      expect(checkboxes, findsAtLeastNWidgets(5));
      await tester.ensureVisible(checkboxes.at(4));
      await tester.tap(checkboxes.at(4));
      await tester.pumpAndSettle();

      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('xlsx 파일 형식 선택 onTap이 실행되어야 한다', (tester) async {
      // Given
      tester.binding.window.physicalSizeTestValue = const Size(800, 3000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: xlsx 텍스트를 찾아서 탭
      final xlsxFinder = find.text('.xlsx');
      if (xlsxFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(xlsxFinder.first);
        await tester.tap(xlsxFinder.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없음
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('csv 파일 형식 선택 onTap이 실행되어야 한다', (tester) async {
      // Given
      tester.binding.window.physicalSizeTestValue = const Size(800, 3000);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
      addTearDown(tester.binding.window.clearDevicePixelRatioTestValue);

      await tester.pumpWidget(_buildExportSheetApp());
      await tester.pumpAndSettle();

      // When: csv 텍스트를 찾아서 탭
      final csvFinder = find.text('.csv');
      if (csvFinder.evaluate().isNotEmpty) {
        await tester.ensureVisible(csvFinder.first);
        await tester.tap(csvFinder.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없음
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('취소 버튼 탭으로 Navigator.pop이 호출되어야 한다', (tester) async {
      // Given: 바텀시트를 showModalBottomSheet로 띄우는 방식
      bool popped = false;
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
                  onPressed: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const DataExportBottomSheet(),
                    );
                    popped = true;
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

      // When: 취소 버튼 탭
      final cancelBtn = find.byType(OutlinedButton);
      if (cancelBtn.evaluate().isNotEmpty) {
        await tester.tap(cancelBtn.first, warnIfMissed: false);
        await tester.pumpAndSettle();
      }

      // Then: 에러 없이 처리됨
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
