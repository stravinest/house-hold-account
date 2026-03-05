import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_household_account/config/page_transitions.dart';

void main() {
  group('slideTransition 테스트', () {
    test('CustomTransitionPage를 반환해야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideTransition<void>(key: key, child: child);

      // Then
      expect(page, isA<CustomTransitionPage>());
    });

    test('전달된 key가 올바르게 설정되어야 한다', () {
      // Given
      const key = ValueKey('slide-key');
      const child = SizedBox();

      // When
      final page = slideTransition<void>(key: key, child: child);

      // Then
      expect(page.key, key);
    });

    test('transitionDuration이 300ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideTransition<void>(key: key, child: child);

      // Then
      expect(page.transitionDuration, const Duration(milliseconds: 300));
    });

    test('reverseTransitionDuration이 300ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideTransition<void>(key: key, child: child);

      // Then
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 300));
    });

    test('name 파라미터를 설정할 수 있어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideTransition<void>(
        key: key,
        child: child,
        name: 'test-route',
      );

      // Then
      expect(page.name, 'test-route');
    });
  });

  group('fadeTransition 테스트', () {
    test('CustomTransitionPage를 반환해야 한다', () {
      // Given
      const key = ValueKey('fade-test');
      const child = SizedBox();

      // When
      final page = fadeTransition<void>(key: key, child: child);

      // Then
      expect(page, isA<CustomTransitionPage>());
    });

    test('transitionDuration이 200ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeTransition<void>(key: key, child: child);

      // Then
      expect(page.transitionDuration, const Duration(milliseconds: 200));
    });

    test('reverseTransitionDuration이 200ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeTransition<void>(key: key, child: child);

      // Then
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 200));
    });
  });

  group('fadeScaleTransition 테스트', () {
    test('CustomTransitionPage를 반환해야 한다', () {
      // Given
      const key = ValueKey('fade-scale-test');
      const child = SizedBox();

      // When
      final page = fadeScaleTransition<void>(key: key, child: child);

      // Then
      expect(page, isA<CustomTransitionPage>());
    });

    test('transitionDuration이 300ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeScaleTransition<void>(key: key, child: child);

      // Then
      expect(page.transitionDuration, const Duration(milliseconds: 300));
    });

    test('reverseTransitionDuration이 200ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeScaleTransition<void>(key: key, child: child);

      // Then
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 200));
    });
  });

  group('slideUpTransition 테스트', () {
    test('CustomTransitionPage를 반환해야 한다', () {
      // Given
      const key = ValueKey('slide-up-test');
      const child = SizedBox();

      // When
      final page = slideUpTransition<void>(key: key, child: child);

      // Then
      expect(page, isA<CustomTransitionPage>());
    });

    test('transitionDuration이 300ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideUpTransition<void>(key: key, child: child);

      // Then
      expect(page.transitionDuration, const Duration(milliseconds: 300));
    });
  });

  group('noTransition 테스트', () {
    test('CustomTransitionPage를 반환해야 한다', () {
      // Given
      const key = ValueKey('no-transition-test');
      const child = SizedBox();

      // When
      final page = noTransition<void>(key: key, child: child);

      // Then
      expect(page, isA<CustomTransitionPage>());
    });

    test('transitionDuration이 0이어야 한다 (즉시 전환)', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = noTransition<void>(key: key, child: child);

      // Then
      expect(page.transitionDuration, Duration.zero);
    });

    test('reverseTransitionDuration이 0이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = noTransition<void>(key: key, child: child);

      // Then
      expect(page.reverseTransitionDuration, Duration.zero);
    });
  });

  group('전환 유형 비교 테스트', () {
    test('slideTransition이 fadeTransition보다 긴 duration을 가진다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final slidePage = slideTransition<void>(key: key, child: child);
      final fadePage = fadeTransition<void>(key: key, child: child);

      // Then
      expect(
        slidePage.transitionDuration.inMilliseconds,
        greaterThan(fadePage.transitionDuration.inMilliseconds),
      );
    });

    test('noTransition이 가장 짧은 duration을 가진다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final noPage = noTransition<void>(key: key, child: child);
      final fadePage = fadeTransition<void>(key: key, child: child);

      // Then
      expect(
        noPage.transitionDuration.inMilliseconds,
        lessThan(fadePage.transitionDuration.inMilliseconds),
      );
    });
  });

  group('slideUpTransition 추가 테스트', () {
    test('전달된 key가 올바르게 설정되어야 한다', () {
      // Given
      const key = ValueKey('slide-up-key');
      const child = SizedBox();

      // When
      final page = slideUpTransition<void>(key: key, child: child);

      // Then
      expect(page.key, key);
    });

    test('reverseTransitionDuration이 300ms이어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideUpTransition<void>(key: key, child: child);

      // Then
      expect(page.reverseTransitionDuration, const Duration(milliseconds: 300));
    });

    test('name 파라미터를 설정할 수 있어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = slideUpTransition<void>(
        key: key,
        child: child,
        name: 'slide-up-route',
      );

      // Then
      expect(page.name, 'slide-up-route');
    });
  });

  group('noTransition 추가 테스트', () {
    test('전달된 key가 올바르게 설정되어야 한다', () {
      // Given
      const key = ValueKey('no-transition-key');
      const child = SizedBox();

      // When
      final page = noTransition<void>(key: key, child: child);

      // Then
      expect(page.key, key);
    });

    test('name 파라미터를 설정할 수 있어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = noTransition<void>(
        key: key,
        child: child,
        name: 'no-transition-route',
      );

      // Then
      expect(page.name, 'no-transition-route');
    });
  });

  group('fadeScaleTransition 추가 테스트', () {
    test('전달된 key가 올바르게 설정되어야 한다', () {
      // Given
      const key = ValueKey('fade-scale-key');
      const child = SizedBox();

      // When
      final page = fadeScaleTransition<void>(key: key, child: child);

      // Then
      expect(page.key, key);
    });

    test('name 파라미터를 설정할 수 있어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeScaleTransition<void>(
        key: key,
        child: child,
        name: 'fade-scale-route',
      );

      // Then
      expect(page.name, 'fade-scale-route');
    });
  });

  group('fadeTransition 추가 테스트', () {
    test('전달된 key가 올바르게 설정되어야 한다', () {
      // Given
      const key = ValueKey('fade-key');
      const child = SizedBox();

      // When
      final page = fadeTransition<void>(key: key, child: child);

      // Then
      expect(page.key, key);
    });

    test('name 파라미터를 설정할 수 있어야 한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeTransition<void>(
        key: key,
        child: child,
        name: 'fade-route',
      );

      // Then
      expect(page.name, 'fade-route');
    });

    test('name 파라미터 없이도 생성 가능하다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox();

      // When
      final page = fadeTransition<void>(key: key, child: child);

      // Then
      expect(page.name, isNull);
    });
  });

  group('모든 전환 타입 child 전달 테스트', () {
    test('slideTransition이 child 위젯을 포함한다', () {
      // Given
      const key = ValueKey('test');
      final child = Container(color: const Color(0xFF000000));

      // When
      final page = slideTransition<void>(key: key, child: child);

      // Then
      expect(page.child, isA<Widget>());
    });

    test('fadeTransition이 child 위젯을 포함한다', () {
      // Given
      const key = ValueKey('test');
      const child = Text('테스트');

      // When
      final page = fadeTransition<void>(key: key, child: child);

      // Then
      expect(page.child, isA<Widget>());
    });

    test('fadeScaleTransition이 child 위젯을 포함한다', () {
      // Given
      const key = ValueKey('test');
      const child = SizedBox(width: 100, height: 100);

      // When
      final page = fadeScaleTransition<void>(key: key, child: child);

      // Then
      expect(page.child, isA<Widget>());
    });

    test('slideUpTransition이 child 위젯을 포함한다', () {
      // Given
      const key = ValueKey('test');
      const child = Placeholder();

      // When
      final page = slideUpTransition<void>(key: key, child: child);

      // Then
      expect(page.child, isA<Widget>());
    });

    test('noTransition이 child 위젯을 포함한다', () {
      // Given
      const key = ValueKey('test');
      const child = ColoredBox(color: Color(0xFFFFFFFF));

      // When
      final page = noTransition<void>(key: key, child: child);

      // Then
      expect(page.child, isA<Widget>());
    });
  });

  group('transitionsBuilder 실행 테스트', () {
    testWidgets('slideTransition의 transitionsBuilder가 SlideTransition 위젯을 빌드한다', (tester) async {
      // Given
      const key = ValueKey('slide-builder-test');
      const child = SizedBox(key: Key('inner'), width: 100, height: 100);
      final page = slideTransition<void>(key: key, child: child);

      // When: transitionsBuilder를 직접 호출하여 위젯 렌더링
      final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
        AnimationController(vsync: tester, duration: const Duration(milliseconds: 300))
          ..value = 0.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              animation,
              animation,
              child,
            ),
          ),
        ),
      );

      // Then: SlideTransition 위젯이 렌더링됨
      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('fadeTransition의 transitionsBuilder가 FadeTransition 위젯을 빌드한다', (tester) async {
      // Given
      const key = ValueKey('fade-builder-test');
      const child = SizedBox(width: 50, height: 50);
      final page = fadeTransition<void>(key: key, child: child);

      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 200),
      )..value = 0.5;
      final animation = controller.view;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              animation,
              animation,
              child,
            ),
          ),
        ),
      );

      // Then: FadeTransition 위젯이 렌더링됨
      expect(find.byType(FadeTransition), findsWidgets);
    });

    testWidgets('fadeScaleTransition의 transitionsBuilder가 FadeTransition과 ScaleTransition 위젯을 빌드한다', (tester) async {
      // Given
      const key = ValueKey('fade-scale-builder-test');
      const child = SizedBox(width: 50, height: 50);
      final page = fadeScaleTransition<void>(key: key, child: child);

      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
      )..value = 0.5;
      final animation = controller.view;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              animation,
              animation,
              child,
            ),
          ),
        ),
      );

      // Then: FadeTransition과 ScaleTransition이 렌더링됨
      expect(find.byType(FadeTransition), findsWidgets);
      expect(find.byType(ScaleTransition), findsWidgets);
    });

    testWidgets('slideUpTransition의 transitionsBuilder가 SlideTransition 위젯을 빌드한다', (tester) async {
      // Given
      const key = ValueKey('slide-up-builder-test');
      const child = SizedBox(width: 50, height: 50);
      final page = slideUpTransition<void>(key: key, child: child);

      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 300),
      )..value = 0.5;
      final animation = controller.view;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              animation,
              animation,
              child,
            ),
          ),
        ),
      );

      // Then: SlideTransition 위젯이 렌더링됨
      expect(find.byType(SlideTransition), findsWidgets);
    });

    testWidgets('noTransition의 transitionsBuilder가 child 위젯을 그대로 반환한다', (tester) async {
      // Given
      const key = ValueKey('no-transition-builder-test');
      const child = SizedBox(key: Key('no-anim-child'), width: 50, height: 50);
      final page = noTransition<void>(key: key, child: child);

      final controller = AnimationController(
        vsync: tester,
        duration: Duration.zero,
      )..value = 1.0;
      final animation = controller.view;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => page.transitionsBuilder(
              context,
              animation,
              animation,
              child,
            ),
          ),
        ),
      );

      // Then: child 위젯이 그대로 렌더링됨 (애니메이션 없음)
      expect(find.byKey(const Key('no-anim-child')), findsOneWidget);
    });
  });
}
