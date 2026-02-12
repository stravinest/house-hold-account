import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/category_icon.dart';

void main() {
  group('CategoryIcon 위젯 테스트', () {
    testWidgets('유효한 icon 이름을 전달하면 Material Icon이 표시된다', (tester) async {
      // Given
      const iconName = 'restaurant';
      const categoryName = '식비';
      const categoryColor = '#FF5722';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(Icon), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.restaurant);
    });

    testWidgets('icon이 비어있으면 카테고리명 첫 글자가 표시된다', (tester) async {
      // Given
      const iconName = '';
      const categoryName = '식비';
      const categoryColor = '#FF5722';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('식'), findsOneWidget);
    });

    testWidgets('icon이 비어있고 name도 비어있으면 물음표가 표시된다', (tester) async {
      // Given
      const iconName = '';
      const categoryName = '';
      const categoryColor = '#FF5722';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('iconMap에 없는 icon 이름을 전달하면 기본 category 아이콘이 표시된다', (tester) async {
      // Given
      const iconName = 'unknown_icon';
      const categoryName = '기타';
      const categoryColor = '#9E9E9E';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(Icon), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.category);
    });

    testWidgets('size를 small로 설정하면 작은 크기로 렌더링된다', (tester) async {
      // Given
      const iconName = 'home';
      const categoryName = '주거';
      const categoryColor = '#2196F3';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
              size: CategoryIconSize.small,
            ),
          ),
        ),
      );

      // Then
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, CategoryIconSize.small.dimension);
      expect(container.constraints?.maxHeight, CategoryIconSize.small.dimension);
    });

    testWidgets('size를 medium으로 설정하면 중간 크기로 렌더링된다', (tester) async {
      // Given
      const iconName = 'shopping_cart';
      const categoryName = '쇼핑';
      const categoryColor = '#4CAF50';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
              size: CategoryIconSize.medium,
            ),
          ),
        ),
      );

      // Then
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, CategoryIconSize.medium.dimension);
      expect(container.constraints?.maxHeight, CategoryIconSize.medium.dimension);
    });

    testWidgets('size를 large로 설정하면 큰 크기로 렌더링된다', (tester) async {
      // Given
      const iconName = 'trending_up';
      const categoryName = '투자';
      const categoryColor = '#FFC107';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
              size: CategoryIconSize.large,
            ),
          ),
        ),
      );

      // Then
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.constraints?.maxWidth, CategoryIconSize.large.dimension);
      expect(container.constraints?.maxHeight, CategoryIconSize.large.dimension);
    });

    testWidgets('color가 정상적으로 파싱되어 배경색에 적용된다', (tester) async {
      // Given
      const iconName = 'account_balance';
      const categoryName = '은행';
      const categoryColor = '#FF9800';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
            ),
          ),
        ),
      );

      // Then
      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration as BoxDecoration;
      expect(decoration.color, isNotNull);
    });

    testWidgets('icon 이름 앞뒤 공백이 제거되어 정상적으로 매칭된다', (tester) async {
      // Given
      const iconName = '  work  ';
      const categoryName = '급여';
      const categoryColor = '#673AB7';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CategoryIcon(
              icon: iconName,
              name: categoryName,
              color: categoryColor,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(Icon), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.work);
    });
  });
}
