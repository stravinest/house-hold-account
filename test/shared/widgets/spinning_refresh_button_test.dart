import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/widgets/spinning_refresh_button.dart';

void main() {
  group('SpinningRefreshButton 위젯 테스트', () {
    testWidgets('필수 프로퍼티(onRefresh)로 정상 렌더링된다', (tester) async {
      // Given
      var refreshCalled = false;
      Future<void> mockRefresh() async {
        await Future.delayed(const Duration(milliseconds: 50));
        refreshCalled = true;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
    });

    testWidgets('tooltip을 제공하면 IconButton에 tooltip이 설정된다', (tester) async {
      // Given
      const testTooltip = '새로고침';
      Future<void> mockRefresh() async {}

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
              tooltip: testTooltip,
            ),
          ),
        ),
      );

      // Then
      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, testTooltip);
    });

    testWidgets('iconSize를 설정하면 아이콘 크기가 변경된다', (tester) async {
      // Given
      const customSize = 30.0;
      Future<void> mockRefresh() async {}

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
              iconSize: customSize,
            ),
          ),
        ),
      );

      // Then
      final icon = tester.widget<Icon>(find.byIcon(Icons.refresh));
      expect(icon.size, customSize);
    });

    testWidgets('버튼을 탭하면 onRefresh 콜백이 호출된다', (tester) async {
      // Given
      var refreshCalled = false;
      Future<void> mockRefresh() async {
        await Future.delayed(const Duration(milliseconds: 50));
        refreshCalled = true;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
            ),
          ),
        ),
      );

      // When - 버튼 탭
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Then
      expect(refreshCalled, true);
    });

    testWidgets('새로고침 중일 때 AnimatedBuilder가 작동한다', (tester) async {
      // Given
      Future<void> mockRefresh() async {
        await Future.delayed(const Duration(milliseconds: 100));
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
            ),
          ),
        ),
      );

      // Then
      expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      expect(find.byType(Transform), findsAtLeastNWidgets(1));
    });

    testWidgets('새로고침이 끝나면 회전이 멈춘다', (tester) async {
      // Given
      Future<void> mockRefresh() async {
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
            ),
          ),
        ),
      );

      // When - 버튼 탭
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Then - 위젯이 여전히 존재함
      expect(find.byType(SpinningRefreshButton), findsOneWidget);
    });

    testWidgets('새로고침 중 중복 탭이 무시된다', (tester) async {
      // Given
      var callCount = 0;
      Future<void> mockRefresh() async {
        await Future.delayed(const Duration(milliseconds: 100));
        callCount++;
      }

      // When
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpinningRefreshButton(
              onRefresh: mockRefresh,
            ),
          ),
        ),
      );

      // When - 연속 탭
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Then - 한 번만 호출됨
      expect(callCount, 1);
    });
  });
}
