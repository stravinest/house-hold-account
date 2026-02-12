import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/empty_state.dart';

void main() {
  group('EmptyState 위젯 테스트', () {
    testWidgets('필수 프로퍼티(icon, message)만 전달 시 정상 렌더링된다', (tester) async {
      // Given
      const testIcon = Icons.inbox;
      const testMessage = '데이터가 없습니다';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: testIcon,
              message: testMessage,
            ),
          ),
        ),
      );

      // Then
      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
    });

    testWidgets('subtitle이 제공되면 부가 설명이 표시된다', (tester) async {
      // Given
      const testIcon = Icons.search;
      const testMessage = '검색 결과가 없습니다';
      const testSubtitle = '다른 키워드로 검색해보세요';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: testIcon,
              message: testMessage,
              subtitle: testSubtitle,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testMessage), findsOneWidget);
      expect(find.text(testSubtitle), findsOneWidget);
    });

    testWidgets('subtitle이 null이면 부가 설명이 표시되지 않는다', (tester) async {
      // Given
      const testIcon = Icons.inbox;
      const testMessage = '데이터가 없습니다';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: testIcon,
              message: testMessage,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testMessage), findsOneWidget);
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      expect(textWidgets.length, 1);
    });

    testWidgets('action이 제공되면 액션 버튼이 표시된다', (tester) async {
      // Given
      const testIcon = Icons.category;
      const testMessage = '카테고리가 없습니다';
      const buttonText = '새로 만들기';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: testIcon,
              message: testMessage,
              action: ElevatedButton(
                onPressed: () {},
                child: const Text(buttonText),
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testMessage), findsOneWidget);
      expect(find.text(buttonText), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('action이 null이면 액션 버튼이 표시되지 않는다', (tester) async {
      // Given
      const testIcon = Icons.inbox;
      const testMessage = '데이터가 없습니다';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: testIcon,
              message: testMessage,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(ElevatedButton), findsNothing);
    });

    testWidgets('모든 프로퍼티를 제공하면 전체 구조가 올바르게 렌더링된다', (tester) async {
      // Given
      const testIcon = Icons.folder_open;
      const testMessage = '폴더가 비어있습니다';
      const testSubtitle = '파일을 추가해보세요';
      const buttonText = '파일 추가';
      var buttonTapped = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: testIcon,
              message: testMessage,
              subtitle: testSubtitle,
              action: ElevatedButton(
                onPressed: () {
                  buttonTapped = true;
                },
                child: const Text(buttonText),
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
      expect(find.text(testSubtitle), findsOneWidget);
      expect(find.text(buttonText), findsOneWidget);

      // When - 버튼 탭
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      // Then
      expect(buttonTapped, true);
    });
  });
}
