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

    testWidgets('태블릿 크기(700dp)에서 tabletPadding을 적용한다', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
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
        equals(const EdgeInsets.symmetric(horizontal: 24)),
      );
    });

    testWidgets('데스크탑 크기(1200dp)에서 desktopPadding을 적용한다', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
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
        equals(const EdgeInsets.symmetric(horizontal: 32)),
      );
    });
  });

  group('ResponsiveBuilder - 태블릿/데스크탑', () {
    testWidgets('태블릿 크기(700dp)에서 tablet 위젯을 렌더링한다', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
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

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Desktop'), findsNothing);
    });

    testWidgets('데스크탑 크기(1200dp)에서 desktop 위젯을 렌더링한다', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
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

      expect(find.text('Desktop'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
      expect(find.text('Tablet'), findsNothing);
    });

    testWidgets('desktop이 null이고 데스크탑 크기일 때 tablet으로 fallback한다', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: const Text('Mobile'),
            tablet: const Text('Tablet'),
          ),
        ),
      );

      expect(find.text('Tablet'), findsOneWidget);
      expect(find.text('Mobile'), findsNothing);
    });

    testWidgets('desktop과 tablet이 모두 null이고 데스크탑 크기일 때 mobile로 fallback한다',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ResponsiveBuilder(
            mobile: const Text('Mobile'),
          ),
        ),
      );

      expect(find.text('Mobile'), findsOneWidget);
    });
  });

  group('CenteredContent - backgroundColor', () {
    testWidgets('backgroundColor를 지정하면 Container에 색상이 적용된다', (tester) async {
      const testColor = Color(0xFFFF0000);

      await tester.pumpWidget(
        const MaterialApp(
          home: CenteredContent(
            backgroundColor: testColor,
            child: Text('Content'),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, equals(testColor));
    });

    testWidgets('backgroundColor가 null이면 Container에 색상이 없다', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CenteredContent(
            child: const Text('Content'),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      expect(container.color, isNull);
    });
  });

  group('ResponsiveExtension', () {
    testWidgets('모바일 크기에서 screenWidth가 화면 너비를 반환한다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double capturedWidth;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedWidth = context.screenWidth;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedWidth, equals(400.0));
    });

    testWidgets('모바일 크기에서 screenHeight가 화면 높이를 반환한다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double capturedHeight;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedHeight = context.screenHeight;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedHeight, equals(800.0));
    });

    testWidgets('모바일 크기에서 isMobile이 true이다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool capturedIsMobile;
      late bool capturedIsTablet;
      late bool capturedIsDesktop;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedIsMobile = context.isMobile;
              capturedIsTablet = context.isTablet;
              capturedIsDesktop = context.isDesktop;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedIsMobile, isTrue);
      expect(capturedIsTablet, isFalse);
      expect(capturedIsDesktop, isFalse);
    });

    testWidgets('태블릿 크기에서 isTablet이 true이다', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool capturedIsMobile;
      late bool capturedIsTablet;
      late bool capturedIsDesktop;
      late bool capturedIsTabletOrLarger;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedIsMobile = context.isMobile;
              capturedIsTablet = context.isTablet;
              capturedIsDesktop = context.isDesktop;
              capturedIsTabletOrLarger = context.isTabletOrLarger;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedIsMobile, isFalse);
      expect(capturedIsTablet, isTrue);
      expect(capturedIsDesktop, isFalse);
      expect(capturedIsTabletOrLarger, isTrue);
    });

    testWidgets('데스크탑 크기에서 isDesktop이 true이고 isTabletOrLarger도 true이다',
        (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool capturedIsDesktop;
      late bool capturedIsTabletOrLarger;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedIsDesktop = context.isDesktop;
              capturedIsTabletOrLarger = context.isTabletOrLarger;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedIsDesktop, isTrue);
      expect(capturedIsTabletOrLarger, isTrue);
    });

    testWidgets('모바일 크기에서 isTabletOrLarger가 false이다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool capturedIsTabletOrLarger;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedIsTabletOrLarger = context.isTabletOrLarger;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedIsTabletOrLarger, isFalse);
    });

    testWidgets('모바일에서 maxContentWidth는 screenWidth와 같다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double capturedMaxContentWidth;
      late double capturedScreenWidth;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedMaxContentWidth = context.maxContentWidth;
              capturedScreenWidth = context.screenWidth;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedMaxContentWidth, equals(capturedScreenWidth));
    });

    testWidgets('태블릿에서 maxContentWidth는 600이다', (tester) async {
      tester.view.physicalSize = const Size(700, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double capturedMaxContentWidth;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedMaxContentWidth = context.maxContentWidth;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedMaxContentWidth, equals(600.0));
    });

    testWidgets('데스크탑에서 maxContentWidth는 840이다', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late double capturedMaxContentWidth;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedMaxContentWidth = context.maxContentWidth;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedMaxContentWidth, equals(840.0));
    });

    testWidgets('가로 모드에서 isLandscape가 true이고 isPortrait가 false이다', (tester) async {
      tester.view.physicalSize = const Size(800, 400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool capturedIsLandscape;
      late bool capturedIsPortrait;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedIsLandscape = context.isLandscape;
              capturedIsPortrait = context.isPortrait;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedIsLandscape, isTrue);
      expect(capturedIsPortrait, isFalse);
    });

    testWidgets('세로 모드에서 isPortrait가 true이고 isLandscape가 false이다', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      late bool capturedIsLandscape;
      late bool capturedIsPortrait;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              capturedIsLandscape = context.isLandscape;
              capturedIsPortrait = context.isPortrait;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(capturedIsLandscape, isFalse);
      expect(capturedIsPortrait, isTrue);
    });
  });
}
