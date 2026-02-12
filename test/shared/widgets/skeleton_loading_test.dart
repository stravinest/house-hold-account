import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/skeleton_loading.dart';

void main() {
  group('SkeletonBox 위젯 테스트', () {
    testWidgets('필수 프로퍼티(width, height)로 정상 렌더링된다', (tester) async {
      // Given
      const testWidth = 100.0;
      const testHeight = 50.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(
              width: testWidth,
              height: testHeight,
            ),
          ),
        ),
      );

      // Then
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SkeletonBox),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, testWidth);
      expect(container.constraints?.maxHeight, testHeight);
    });

    testWidgets('borderRadius를 커스텀하면 해당 반경이 적용된다', (tester) async {
      // Given
      const testWidth = 100.0;
      const testHeight = 50.0;
      const customRadius = 10.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBox(
              width: testWidth,
              height: testHeight,
              borderRadius: customRadius,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonCircle 위젯 테스트', () {
    testWidgets('size를 전달하면 원형으로 렌더링된다', (tester) async {
      // Given
      const circleSize = 40.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCircle(size: circleSize),
          ),
        ),
      );

      // Then
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(SkeletonCircle),
          matching: find.byType(Container),
        ),
      );
      expect(container.constraints?.maxWidth, circleSize);
      expect(container.constraints?.maxHeight, circleSize);
    });
  });

  group('SkeletonLine 위젯 테스트', () {
    testWidgets('기본값으로 렌더링되면 너비 무한, 높이 16이다', (tester) async {
      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLine(),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonLine), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('width와 height를 커스텀하면 해당 크기로 렌더링된다', (tester) async {
      // Given
      const customWidth = 200.0;
      const customHeight = 20.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonLine(
              width: customWidth,
              height: customHeight,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonLine), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonCard 위젯 테스트', () {
    testWidgets('기본값으로 렌더링되면 높이 80, 너비 무한이다', (tester) async {
      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });

    testWidgets('height와 width를 커스텀하면 해당 크기로 렌더링된다', (tester) async {
      // Given
      const customHeight = 100.0;
      const customWidth = 300.0;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonCard(
              height: customHeight,
              width: customWidth,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });

  group('SkeletonTransactionItem 위젯 테스트', () {
    testWidgets('아이콘, 텍스트 라인들이 포함된 구조로 렌더링된다', (tester) async {
      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTransactionItem(),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonTransactionItem), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonLine), findsNWidgets(3));
    });

    testWidgets('Row와 Column 레이아웃으로 구성되어 있다', (tester) async {
      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonTransactionItem(),
          ),
        ),
      );

      // Then
      expect(find.byType(Row), findsOneWidget);
      expect(find.byType(Column), findsOneWidget);
    });
  });

  group('SkeletonListView 위젯 테스트', () {
    testWidgets('기본 itemCount 5개로 렌더링된다', (tester) async {
      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListView(),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonListView), findsOneWidget);
      expect(find.byType(SkeletonTransactionItem), findsNWidgets(5));
    });

    testWidgets('itemCount를 커스텀하면 해당 개수만큼 렌더링된다', (tester) async {
      // Given
      const customCount = 3;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonListView(itemCount: customCount),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonTransactionItem), findsNWidgets(customCount));
    });

    testWidgets('커스텀 itemBuilder를 제공하면 해당 빌더로 렌더링된다', (tester) async {
      // Given
      const customCount = 2;
      Widget customBuilder(BuildContext context, int index) {
        return const SkeletonCard();
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SkeletonListView(
              itemCount: customCount,
              itemBuilder: customBuilder,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(SkeletonCard), findsNWidgets(customCount));
      expect(find.byType(SkeletonTransactionItem), findsNothing);
    });
  });
}
