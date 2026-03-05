import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/features/transaction/presentation/widgets/transaction_form_fields.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';

Widget _buildApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('ko'),
    home: Scaffold(body: child),
  );
}

void main() {
  group('TransactionTypeSelector 위젯 테스트', () {
    testWidgets('초기 선택값이 expense일 때 올바르게 렌더링된다', (tester) async {
      // Given
      String changedType = '';

      // When
      await tester.pumpWidget(
        _buildApp(
          TransactionTypeSelector(
            selectedType: 'expense',
            onTypeChanged: (type) => changedType = type,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: SegmentedButton이 렌더링되어야 함
      expect(find.byType(SegmentedButton<String>), findsOneWidget);
    });

    testWidgets('income 타입 선택 시 콜백이 호출된다', (tester) async {
      // Given
      String changedType = 'expense';

      await tester.pumpWidget(
        _buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return TransactionTypeSelector(
                selectedType: changedType,
                onTypeChanged: (type) => setState(() => changedType = type),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 수입 버튼 탭
      await tester.tap(find.byIcon(Icons.add_circle_outline));
      await tester.pumpAndSettle();

      // Then
      expect(changedType, 'income');
    });

    testWidgets('asset 타입 선택 시 콜백이 호출된다', (tester) async {
      // Given
      String changedType = 'expense';

      await tester.pumpWidget(
        _buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              return TransactionTypeSelector(
                selectedType: changedType,
                onTypeChanged: (type) => setState(() => changedType = type),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When: 자산 버튼 탭
      await tester.tap(find.byIcon(Icons.savings_outlined));
      await tester.pumpAndSettle();

      // Then
      expect(changedType, 'asset');
    });
  });

  group('TitleInputField 위젯 테스트', () {
    testWidgets('초기 상태에서 TextFormField가 렌더링된다', (tester) async {
      // Given
      final controller = TextEditingController();

      // When
      await tester.pumpWidget(
        _buildApp(TitleInputField(controller: controller)),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TextFormField), findsOneWidget);

      controller.dispose();
    });

    testWidgets('텍스트 입력 시 controller에 값이 반영된다', (tester) async {
      // Given
      final controller = TextEditingController();

      await tester.pumpWidget(
        _buildApp(TitleInputField(controller: controller)),
      );
      await tester.pumpAndSettle();

      // When
      await tester.enterText(find.byType(TextFormField), '점심 식사');
      await tester.pump();

      // Then
      expect(controller.text, '점심 식사');

      controller.dispose();
    });
  });

  group('AmountInputField 위젯 테스트', () {
    testWidgets('초기 상태에서 TextFormField가 렌더링된다', (tester) async {
      // Given
      final controller = TextEditingController(text: '0');
      final focusNode = FocusNode();

      // When
      await tester.pumpWidget(
        _buildApp(
          AmountInputField(
            controller: controller,
            focusNode: focusNode,
            isInstallmentMode: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then
      expect(find.byType(TextFormField), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });

    testWidgets('isInstallmentMode=true일 때 TextFormField가 렌더링된다', (tester) async {
      // Given
      final controller = TextEditingController(text: '50000');
      final focusNode = FocusNode();

      // When
      await tester.pumpWidget(
        _buildApp(
          AmountInputField(
            controller: controller,
            focusNode: focusNode,
            isInstallmentMode: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: TextFormField가 렌더링되어야 함
      expect(find.byType(TextFormField), findsOneWidget);

      controller.dispose();
      focusNode.dispose();
    });
  });

  group('DateSelectorTile 위젯 테스트', () {
    testWidgets('선택된 날짜가 표시된다', (tester) async {
      // Given
      final testDate = DateTime(2026, 1, 15);
      var tapped = false;

      // When
      await tester.pumpWidget(
        _buildApp(
          DateSelectorTile(
            selectedDate: testDate,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Then: ListTile이 렌더링되어야 함
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('탭 시 onTap 콜백이 호출된다', (tester) async {
      // Given
      final testDate = DateTime(2026, 1, 15);
      var tapped = false;

      await tester.pumpWidget(
        _buildApp(
          DateSelectorTile(
            selectedDate: testDate,
            onTap: () => tapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // When
      await tester.tap(find.byType(ListTile));
      await tester.pump();

      // Then
      expect(tapped, isTrue);
    });
  });
}
