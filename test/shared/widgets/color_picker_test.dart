import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/color_picker.dart';

void main() {
  group('ColorPicker Widget Tests', () {
    testWidgets('색상 팔레트 12개를 2줄로 렌더링한다', (tester) async {
      // Given
      String selectedColor = '#A8D8EA';
      String? changedColor;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: (color) {
                changedColor = color;
              },
            ),
          ),
        ),
      );

      // Then
      final colorCircles = find.byType(InkWell);
      expect(colorCircles, findsNWidgets(12));

      final checkIcons = find.byIcon(Icons.check);
      expect(checkIcons, findsOneWidget);
    });

    testWidgets('선택된 색상에 체크 아이콘이 표시된다', (tester) async {
      // Given
      const selectedColor = '#FFB6A3';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      // Then
      final checkIcons = find.byIcon(Icons.check);
      expect(checkIcons, findsOneWidget);
    });

    testWidgets('색상 원을 탭하면 onColorSelected 콜백이 호출된다', (tester) async {
      // Given
      String selectedColor = '#A8D8EA';
      String? changedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: (color) {
                changedColor = color;
              },
            ),
          ),
        ),
      );

      // When
      final firstColorCircle = find.byType(InkWell).first;
      await tester.tap(firstColorCircle);
      await tester.pump();

      // Then
      expect(changedColor, isNotNull);
      expect(changedColor, equals('#A8D8EA'));
    });

    testWidgets('다른 색상을 선택하면 체크 아이콘이 이동한다', (tester) async {
      // Given
      String selectedColor = '#A8D8EA';

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: ColorPicker(
                  selectedColor: selectedColor,
                  onColorSelected: (color) {
                    setState(() {
                      selectedColor = color;
                    });
                  },
                ),
              );
            },
          ),
        ),
      );

      // When: 두 번째 색상 선택
      final secondColorCircle = find.byType(InkWell).at(1);
      await tester.tap(secondColorCircle);
      await tester.pumpAndSettle();

      // Then: 여전히 체크 아이콘은 하나만 표시
      final checkIcons = find.byIcon(Icons.check);
      expect(checkIcons, findsOneWidget);
    });

    testWidgets('12개의 색상이 ColorPicker.colors 팔레트와 일치한다', (tester) async {
      // Given
      const selectedColor = '#A8D8EA';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      // Then
      expect(ColorPicker.colors.length, equals(12));
      expect(ColorPicker.colors[0], equals('#A8D8EA'));
      expect(ColorPicker.colors[1], equals('#FFB6A3'));
    });

    testWidgets('색상 원의 터치 영역이 최소 크기를 만족한다', (tester) async {
      // Given
      const selectedColor = '#A8D8EA';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPicker(
              selectedColor: selectedColor,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      // Then
      final firstContainer = tester.widget<Container>(
        find.byType(Container).first,
      );
      expect(firstContainer.constraints?.minWidth, equals(44.0));
      expect(firstContainer.constraints?.minHeight, equals(44.0));
    });
  });
}
