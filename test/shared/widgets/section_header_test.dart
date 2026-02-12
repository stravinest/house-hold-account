import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/section_header.dart';

void main() {
  group('SectionHeader 위젯 테스트', () {
    testWidgets('필수 프로퍼티(title)만 전달 시 제목이 표시된다', (tester) async {
      // Given
      const testTitle = '섹션 제목';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: testTitle),
          ),
        ),
      );

      // Then
      expect(find.text(testTitle), findsOneWidget);
    });

    testWidgets('icon이 제공되면 아이콘이 제목 앞에 표시된다', (tester) async {
      // Given
      const testTitle = '카테고리';
      const testIcon = Icons.category;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: testTitle,
              icon: testIcon,
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testTitle), findsOneWidget);
      expect(find.byIcon(testIcon), findsOneWidget);
    });

    testWidgets('icon이 null이면 아이콘이 표시되지 않는다', (tester) async {
      // Given
      const testTitle = '섹션 제목';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: testTitle),
          ),
        ),
      );

      // Then
      expect(find.text(testTitle), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('trailing이 제공되면 제목 뒤에 위젯이 표시된다', (tester) async {
      // Given
      const testTitle = '최근 거래';
      const trailingText = '더보기';

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: testTitle,
              trailing: TextButton(
                onPressed: () {},
                child: const Text(trailingText),
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(trailingText), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('trailing이 null이면 trailing 위젯이 표시되지 않는다', (tester) async {
      // Given
      const testTitle = '섹션 제목';

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(title: testTitle),
          ),
        ),
      );

      // Then
      expect(find.text(testTitle), findsOneWidget);
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('모든 프로퍼티를 제공하면 전체 구조가 올바르게 렌더링된다', (tester) async {
      // Given
      const testTitle = '통계';
      const testIcon = Icons.bar_chart;
      const trailingText = '전체보기';
      var trailingTapped = false;

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: testTitle,
              icon: testIcon,
              trailing: TextButton(
                onPressed: () {
                  trailingTapped = true;
                },
                child: const Text(trailingText),
              ),
            ),
          ),
        ),
      );

      // Then
      expect(find.byIcon(testIcon), findsOneWidget);
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(trailingText), findsOneWidget);

      // When - trailing 버튼 탭
      await tester.tap(find.byType(TextButton));
      await tester.pumpAndSettle();

      // Then
      expect(trailingTapped, true);
    });

    testWidgets('Row 내부에서 제목이 Expanded로 감싸져 있어 가용 공간을 차지한다', (tester) async {
      // Given
      const testTitle = '긴 제목입니다 긴 제목입니다';
      const testIcon = Icons.info;

      // When
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SectionHeader(
              title: testTitle,
              icon: testIcon,
            ),
          ),
        ),
      );

      // Then
      final row = tester.widget<Row>(find.byType(Row));
      final expanded = row.children.whereType<Expanded>().first;
      expect(expanded, isNotNull);
    });
  });
}
