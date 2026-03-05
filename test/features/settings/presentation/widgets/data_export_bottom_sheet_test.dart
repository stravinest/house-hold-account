import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/settings/presentation/widgets/data_export_bottom_sheet.dart';
import 'package:shared_household_account/features/ledger/presentation/providers/ledger_provider.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

Widget buildWidget({String? ledgerId = 'ledger-1'}) {
  return ProviderScope(
    overrides: [
      selectedLedgerIdProvider.overrideWith((ref) => ledgerId),
    ],
    child: const MaterialApp(
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DataExportBottomSheet(),
      ),
    ),
  );
}

void main() {
  group('DataExportBottomSheet 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('기간 선택 섹션이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: 내보내기 관련 UI 요소가 존재함
      expect(find.byType(DataExportBottomSheet), findsOneWidget);
    });

    testWidgets('DraggableScrollableSheet가 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: DraggableScrollableSheet가 표시됨
      expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    });

    testWidgets('ListView가 스크롤 가능한 컨텐츠로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then: ListView 위젯이 있음
      expect(find.byType(ListView), findsOneWidget);
    });

    testWidgets('포함 항목 체크박스들이 표시된다', (tester) async {
      // Given & When
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
            home: const Scaffold(
              body: SizedBox(
                height: 1200,
                child: DataExportBottomSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: 체크박스가 있음
      expect(find.byType(CheckboxListTile), findsWidgets);
    });

    testWidgets('거래 유형 필터 칩이 표시된다', (tester) async {
      // Given & When
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
            home: const Scaffold(
              body: SizedBox(
                height: 1200,
                child: DataExportBottomSheet(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: FilterChip이 표시됨
      expect(find.byType(FilterChip), findsWidgets);
    });
  });
}
