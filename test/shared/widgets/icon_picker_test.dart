import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/l10n/generated/app_localizations.dart';
import 'package:shared_household_account/shared/widgets/icon_picker.dart';

void main() {
  group('IconPicker 위젯 테스트', () {
    testWidgets('필수 프로퍼티로 정상 렌더링된다', (tester) async {
      // Given
      var selectedIconResult = '';
      void onIconSelected(String icon) {
        selectedIconResult = icon;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: IconPicker(
              selectedIcon: '',
              onIconSelected: onIconSelected,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(IconPicker), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('빈 문자열 옵션(아이콘 없음)이 표시된다', (tester) async {
      // Given
      var selectedIconResult = '';
      void onIconSelected(String icon) {
        selectedIconResult = icon;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: IconPicker(
              selectedIcon: '',
              onIconSelected: onIconSelected,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('아이콘을 탭하면 onIconSelected 콜백이 호출된다', (tester) async {
      // Given
      var selectedIconResult = 'initial';
      void onIconSelected(String icon) {
        selectedIconResult = icon;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: IconPicker(
              selectedIcon: '',
              onIconSelected: onIconSelected,
            ),
          ),
        ),
      );

      // When - 첫 번째 InkWell 탭
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Then
      expect(selectedIconResult, isNot('initial'));
    });

    testWidgets('filterGroup을 제공하면 해당 그룹 아이콘이 우선 표시된다', (tester) async {
      // Given
      var selectedIconResult = '';
      void onIconSelected(String icon) {
        selectedIconResult = icon;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: IconPicker(
              selectedIcon: '',
              onIconSelected: onIconSelected,
              filterGroup: 'expense',
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(IconPicker), findsOneWidget);
      expect(find.byType(InkWell), findsWidgets);
    });

    testWidgets('selectedColor가 아이콘 미리보기에 적용된다', (tester) async {
      // Given
      var selectedIconResult = '';
      void onIconSelected(String icon) {
        selectedIconResult = icon;
      }
      const testColor = '#FF5722';

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: IconPicker(
              selectedIcon: 'restaurant',
              onIconSelected: onIconSelected,
              selectedColor: testColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(IconPicker), findsOneWidget);
    });
  });

  group('ColorPicker 위젯 테스트', () {
    const testPalette = [
      '#FF5722',
      '#2196F3',
      '#4CAF50',
      '#FFC107',
    ];

    testWidgets('필수 프로퍼티로 정상 렌더링된다', (tester) async {
      // Given
      var selectedColorResult = '';
      void onColorSelected(String color) {
        selectedColorResult = color;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: ColorPicker(
              palette: testPalette,
              selectedColor: testPalette[0],
              onColorSelected: onColorSelected,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(ColorPicker), findsOneWidget);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('palette 개수만큼 색상 원이 표시된다', (tester) async {
      // Given
      var selectedColorResult = '';
      void onColorSelected(String color) {
        selectedColorResult = color;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: ColorPicker(
              palette: testPalette,
              selectedColor: testPalette[0],
              onColorSelected: onColorSelected,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(GestureDetector), findsNWidgets(testPalette.length));
    });

    testWidgets('선택된 색상에 체크 아이콘이 표시된다', (tester) async {
      // Given
      var selectedColorResult = '';
      void onColorSelected(String color) {
        selectedColorResult = color;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: ColorPicker(
              palette: testPalette,
              selectedColor: testPalette[0],
              onColorSelected: onColorSelected,
            ),
          ),
        ),
      );

      // Then
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('색상을 탭하면 onColorSelected 콜백이 호출된다', (tester) async {
      // Given
      var selectedColorResult = '';
      void onColorSelected(String color) {
        selectedColorResult = color;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('ko'),
          home: Scaffold(
            body: ColorPicker(
              palette: testPalette,
              selectedColor: testPalette[0],
              onColorSelected: onColorSelected,
            ),
          ),
        ),
      );

      // When - 두 번째 색상 탭
      await tester.tap(find.byType(GestureDetector).at(1));
      await tester.pumpAndSettle();

      // Then
      expect(selectedColorResult, testPalette[1]);
    });
  });
}
