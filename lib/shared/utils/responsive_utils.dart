import 'package:flutter/material.dart';

/// 반응형 레이아웃 유틸리티
///
/// 화면 크기에 따라 다른 레이아웃을 제공합니다.
/// Material 3 가이드라인을 따릅니다.

/// 반응형 브레이크포인트
class Breakpoints {
  Breakpoints._();

  /// 모바일 최대 너비 (< 600dp)
  static const double mobile = 600;

  /// 태블릿 최대 너비 (600-900dp)
  static const double tablet = 900;

  /// 데스크탑 (> 900dp)
  /// 가계부 앱에서는 주로 태블릿까지만 고려
}

/// 디바이스 타입
enum DeviceType { mobile, tablet, desktop }

/// 반응형 유틸리티 확장
extension ResponsiveExtension on BuildContext {
  /// 현재 화면 너비
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// 현재 화면 높이
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// 현재 디바이스 타입
  DeviceType get deviceType {
    final width = screenWidth;
    if (width < Breakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < Breakpoints.tablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  /// 모바일인지 확인
  bool get isMobile => deviceType == DeviceType.mobile;

  /// 태블릿인지 확인
  bool get isTablet => deviceType == DeviceType.tablet;

  /// 데스크탑인지 확인
  bool get isDesktop => deviceType == DeviceType.desktop;

  /// 태블릿 이상인지 확인 (사이드 네비게이션 표시 기준)
  bool get isTabletOrLarger =>
      deviceType == DeviceType.tablet || deviceType == DeviceType.desktop;

  /// 가로 모드인지 확인
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// 세로 모드인지 확인
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;

  /// 콘텐츠 최대 너비 (태블릿/데스크탑에서 중앙 정렬용)
  double get maxContentWidth {
    if (isMobile) {
      return screenWidth;
    } else if (isTablet) {
      return 600; // 태블릿에서도 모바일 너비 유지
    } else {
      return 840; // 데스크탑 최대 콘텐츠 너비
    }
  }
}

/// 반응형 위젯 빌더
///
/// 화면 크기에 따라 다른 위젯을 렌더링합니다.
class ResponsiveBuilder extends StatelessWidget {
  /// 모바일 레이아웃 (필수)
  final Widget mobile;

  /// 태블릿 레이아웃 (선택, 없으면 모바일 사용)
  final Widget? tablet;

  /// 데스크탑 레이아웃 (선택, 없으면 태블릿 또는 모바일 사용)
  final Widget? desktop;

  const ResponsiveBuilder({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;

    switch (deviceType) {
      case DeviceType.desktop:
        return desktop ?? tablet ?? mobile;
      case DeviceType.tablet:
        return tablet ?? mobile;
      case DeviceType.mobile:
        return mobile;
    }
  }
}

/// 콘텐츠 중앙 정렬 래퍼
///
/// 태블릿/데스크탑에서 콘텐츠를 중앙에 배치하고 최대 너비를 제한합니다.
class CenteredContent extends StatelessWidget {
  final Widget child;

  /// 최대 너비 (기본값: 600)
  final double maxWidth;

  /// 배경색 (선택)
  final Color? backgroundColor;

  const CenteredContent({
    super.key,
    required this.child,
    this.maxWidth = 600,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

/// 적응형 패딩
///
/// 화면 크기에 따라 자동으로 패딩을 조절합니다.
class AdaptivePadding extends StatelessWidget {
  final Widget child;

  /// 모바일 패딩 (기본값: 16)
  final double mobilePadding;

  /// 태블릿 패딩 (기본값: 24)
  final double tabletPadding;

  /// 데스크탑 패딩 (기본값: 32)
  final double desktopPadding;

  const AdaptivePadding({
    super.key,
    required this.child,
    this.mobilePadding = 16,
    this.tabletPadding = 24,
    this.desktopPadding = 32,
  });

  @override
  Widget build(BuildContext context) {
    final deviceType = context.deviceType;
    final padding = switch (deviceType) {
      DeviceType.mobile => mobilePadding,
      DeviceType.tablet => tabletPadding,
      DeviceType.desktop => desktopPadding,
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: child,
    );
  }
}
