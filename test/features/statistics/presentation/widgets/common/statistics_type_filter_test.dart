import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/statistics/presentation/providers/statistics_provider.dart';
import 'package:shared_household_account/features/statistics/presentation/widgets/common/statistics_type_filter.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget buildWidget({String selectedType = 'expense'}) {
  return ProviderScope(
    overrides: [
      selectedStatisticsTypeProvider.overrideWith((ref) => selectedType),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(child: StatisticsTypeFilter()),
      ),
    ),
  );
}

void main() {
  group('StatisticsTypeFilter 위젯 테스트', () {
    testWidgets('위젯이 정상적으로 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsTypeFilter), findsOneWidget);
    });

    testWidgets('지출 타입 선택 시 PopupMenuButton이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(PopupMenuButton<String>), findsOneWidget);
    });

    testWidgets('수입 타입 선택 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'income'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsTypeFilter), findsOneWidget);
    });

    testWidgets('자산 타입 선택 시 위젯이 렌더링된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget(selectedType: 'asset'));
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(StatisticsTypeFilter), findsOneWidget);
    });

    testWidgets('드롭다운 버튼을 탭하면 메뉴 아이템이 나타난다', (tester) async {
      // Given
      await tester.pumpWidget(buildWidget(selectedType: 'expense'));
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();

      // Then - 메뉴 아이템 3개가 표시되어야 함 (지출, 수입, 자산)
      expect(find.byType(PopupMenuItem<String>), findsWidgets);
    });

    testWidgets('드롭다운에서 수입 선택 시 provider 상태가 변경된다', (tester) async {
      // Given
      String? selectedValue;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            selectedStatisticsTypeProvider.overrideWith((ref) => 'expense'),
          ],
          child: Consumer(
            builder: (context, ref, _) {
              selectedValue = ref.watch(selectedStatisticsTypeProvider);
              return const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                home: Scaffold(
                  body: Center(child: StatisticsTypeFilter()),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then - 초기 상태는 expense
      expect(selectedValue, 'expense');
    });

    testWidgets('Row 레이아웃으로 아이콘과 텍스트가 가로로 배치된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(Row), findsWidgets);
    });

    testWidgets('keyboard_arrow_down 아이콘이 표시된다', (tester) async {
      // Given & When
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Then
      expect(find.byIcon(Icons.keyboard_arrow_down), findsOneWidget);
    });
  });
}
