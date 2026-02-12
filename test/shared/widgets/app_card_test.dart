import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/app_card.dart';

void main() {
  group('AppCard 위젯 테스트', () {
    testWidgets('필수 프로퍼티(child)만 전달 시 기본 스타일로 렌더링된다', (tester) async {
      // Given
      const childText = '카드 내용';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text(childText),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(childText), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('onTap이 제공되면 InkWell로 감싸져 탭 가능하다', (tester) async {
      // Given
      const childText = '탭 가능 카드';
      var tapped = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () {
                tapped = true;
              },
              child: const Text(childText),
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(InkWell), findsOneWidget);

      // When - 카드 탭
      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      // Then
      expect(tapped, true);
    });

    testWidgets('onTap이 null이면 InkWell이 없다', (tester) async {
      // Given
      const childText = '일반 카드';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              child: Text(childText),
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('padding을 커스텀하면 해당 패딩이 적용된다', (tester) async {
      // Given
      const childText = '커스텀 패딩';
      const customPadding = EdgeInsets.all(24.0);

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: customPadding,
              child: Text(childText),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(childText), findsOneWidget);
      final paddings = tester.widgetList<Padding>(find.byType(Padding));
      final hasPadding = paddings.any((p) => p.padding == customPadding);
      expect(hasPadding, true);
    });

    testWidgets('margin을 설정하면 카드에 외부 여백이 적용된다', (tester) async {
      // Given
      const childText = '마진 카드';
      const customMargin = EdgeInsets.all(16.0);

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              margin: customMargin,
              child: Text(childText),
            ),
          ),
        ),
      );

      // Then
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, customMargin);
    });

    testWidgets('elevation을 설정하면 카드에 고도가 적용된다', (tester) async {
      // Given
      const childText = '고도 카드';
      const customElevation = 4.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              elevation: customElevation,
              child: Text(childText),
            ),
          ),
        ),
      );

      // Then
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, customElevation);
    });

    testWidgets('모든 프로퍼티를 제공하면 전체 구조가 올바르게 렌더링된다', (tester) async {
      // Given
      const childText = '완전한 카드';
      const customPadding = EdgeInsets.all(20.0);
      const customMargin = EdgeInsets.symmetric(horizontal: 12.0);
      const customElevation = 2.0;
      var tapped = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              padding: customPadding,
              margin: customMargin,
              elevation: customElevation,
              onTap: () {
                tapped = true;
              },
              child: const Text(childText),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(childText), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(InkWell), findsOneWidget);

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, customMargin);
      expect(card.elevation, customElevation);

      // When - 카드 탭
      await tester.tap(find.byType(AppCard));
      await tester.pumpAndSettle();

      // Then
      expect(tapped, true);
    });
  });
}
