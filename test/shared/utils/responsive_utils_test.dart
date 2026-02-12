import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_household_account/shared/utils/responsive_utils.dart';

void main() {
  group('Breakpoints', () {
    test('모바일 브레이크포인트가 600이다', () {
      expect(Breakpoints.mobile, equals(600));
    });

    test('태블릿 브레이크포인트가 900이다', () {
      expect(Breakpoints.tablet, equals(900));
    });
  });

  group('DeviceType 로직', () {
    test('너비 < 600이면 mobile', () {
      const width = 599.0;
      final type = width < Breakpoints.mobile
          ? DeviceType.mobile
          : width < Breakpoints.tablet
              ? DeviceType.tablet
              : DeviceType.desktop;
      expect(type, equals(DeviceType.mobile));
    });

    test('너비 = 600이면 tablet', () {
      const width = 600.0;
      final type = width < Breakpoints.mobile
          ? DeviceType.mobile
          : width < Breakpoints.tablet
              ? DeviceType.tablet
              : DeviceType.desktop;
      expect(type, equals(DeviceType.tablet));
    });

    test('너비 = 899이면 tablet', () {
      const width = 899.0;
      final type = width < Breakpoints.mobile
          ? DeviceType.mobile
          : width < Breakpoints.tablet
              ? DeviceType.tablet
              : DeviceType.desktop;
      expect(type, equals(DeviceType.tablet));
    });

    test('너비 = 900이면 desktop', () {
      const width = 900.0;
      final type = width < Breakpoints.mobile
          ? DeviceType.mobile
          : width < Breakpoints.tablet
              ? DeviceType.tablet
              : DeviceType.desktop;
      expect(type, equals(DeviceType.desktop));
    });

    test('너비 > 900이면 desktop', () {
      const width = 1920.0;
      final type = width < Breakpoints.mobile
          ? DeviceType.mobile
          : width < Breakpoints.tablet
              ? DeviceType.tablet
              : DeviceType.desktop;
      expect(type, equals(DeviceType.desktop));
    });
  });

  group('ResponsiveBuilder', () {
    testWidgets('모바일 크기에서 mobile 위젯을 렌더링한다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: const Text('Mobile'),
            tablet: const Text('Tablet'),
            desktop: const Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
      expect(find.text('Tablet'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('tablet이 null이면 mobile로 fallback한다', (tester) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: const Text('Mobile'),
            desktop: const Text('Desktop'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
    });
  });

  group('CenteredContent', () {
    testWidgets('자식 위젯을 중앙에 배치한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CenteredContent(
            child: const Text('Content'),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(Center), findsOneWidget);
    });

    testWidgets('maxWidth 제약을 적용한다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CenteredContent(
            maxWidth: 500,
            child: const Text('Content'),
          ),
        ),
      );

      final constrainedBox = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      ).last;
      expect(constrainedBox.constraints.maxWidth, equals(500));
    });

    testWidgets('기본 maxWidth는 600이다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CenteredContent(
            child: const Text('Content'),
          ),
        ),
      );

      final constrainedBox = tester.widgetList<ConstrainedBox>(
        find.byType(ConstrainedBox),
      ).last;
      expect(constrainedBox.constraints.maxWidth, equals(600));
    });
  });

  group('AdaptivePadding', () {
    testWidgets('모바일에서 기본 패딩 16을 적용한다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePadding(
            child: const Text('Content'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(
        padding.padding,
        equals(const EdgeInsets.symmetric(horizontal: 16)),
      );
    });

    testWidgets('커스텀 패딩을 적용할 수 있다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: AdaptivePadding(
            mobilePadding: 8,
            tabletPadding: 12,
            desktopPadding: 20,
            child: const Text('Content'),
          ),
        ),
      );

      final padding = tester.widget<Padding>(find.byType(Padding));
      expect(padding.padding, equals(const EdgeInsets.symmetric(horizontal: 8)));
    });
  });
}
