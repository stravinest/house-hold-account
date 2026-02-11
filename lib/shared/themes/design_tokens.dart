/// 디자인 토큰 - 프로젝트 전체에서 사용되는 디자인 상수
///
/// 이 파일은 앱의 일관된 디자인 시스템을 유지하기 위한 토큰을 정의합니다.
/// 하드코딩된 값을 사용하지 말고 이 토큰을 참조하세요.
library;

/// 간격(Spacing) 토큰
///
/// 모든 padding, margin, gap에 이 값들을 사용하세요.
class Spacing {
  Spacing._();

  /// 4.0 - 매우 작은 간격 (컴포넌트 내부 미세 조정)
  static const double xs = 4.0;

  /// 8.0 - 작은 간격 (인접 요소 간)
  static const double sm = 8.0;

  /// 16.0 - 기본 간격 (대부분의 경우)
  static const double md = 16.0;

  /// 24.0 - 큰 간격 (섹션 간)
  static const double lg = 24.0;

  /// 32.0 - 매우 큰 간격 (화면 상단/하단 여백)
  static const double xl = 32.0;

  /// 48.0 - 특별히 큰 간격 (주요 섹션 분리)
  static const double xxl = 48.0;
}

/// 테두리 반경(Border Radius) 토큰
///
/// 모든 borderRadius, BorderRadius.circular에 이 값들을 사용하세요.
class BorderRadiusToken {
  BorderRadiusToken._();

  /// 4.0 - 매우 작은 요소 (태그, 작은 배지)
  static const double xs = 4.0;

  /// 8.0 - 작은 요소 (SnackBar, 작은 카드, 진행률 표시)
  static const double sm = 8.0;

  /// 12.0 - 기본 요소 (Card, Button, Input, Dialog) - **가장 많이 사용**
  static const double md = 12.0;

  /// 16.0 - 큰 요소 (FAB, 큰 컨테이너)
  static const double lg = 16.0;

  /// 20.0 - 매우 큰 요소 (배지, 시트 상단)
  static const double xl = 20.0;

  /// 완전한 원형 (CircleAvatar 등)
  static const double circular = 9999.0;
}

/// 고도(Elevation) 토큰
///
/// Material 3 기본값에 맞춰진 그림자 높이입니다.
class Elevation {
  Elevation._();

  /// 0.0 - 그림자 없음 (Flat 디자인)
  static const double none = 0.0;

  /// 1.0 - 매우 낮은 그림자 (약간의 구분)
  static const double low = 1.0;

  /// 2.0 - 기본 그림자 (Card, Button)
  static const double medium = 2.0;

  /// 4.0 - 높은 그림자 (Dialog, Menu)
  static const double high = 4.0;

  /// 8.0 - 매우 높은 그림자 (FAB, Drawer)
  static const double veryHigh = 8.0;
}

/// 아이콘 크기 토큰
///
/// 일관된 아이콘 크기를 위한 토큰입니다.
class IconSize {
  IconSize._();

  /// 16.0 - 매우 작은 아이콘 (인라인 아이콘)
  static const double xs = 16.0;

  /// 20.0 - 작은 아이콘 (버튼 내부)
  static const double sm = 20.0;

  /// 24.0 - 기본 아이콘 (대부분의 경우) - **Material 기본값**
  static const double md = 24.0;

  /// 32.0 - 큰 아이콘 (주요 액션)
  static const double lg = 32.0;

  /// 48.0 - 매우 큰 아이콘 (주요 상태 표시)
  static const double xl = 48.0;

  /// 64.0 - 특별히 큰 아이콘 (빈 상태 EmptyState)
  static const double xxl = 64.0;
}

/// 터치 타겟 크기 토큰
///
/// 접근성을 위한 최소 터치 영역 크기입니다.
/// Material Design 가이드라인: 최소 48x48dp
class TouchTarget {
  TouchTarget._();

  /// 44.0 - 최소 터치 영역 (iOS Human Interface Guidelines)
  static const double minimum = 44.0;

  /// 48.0 - 권장 터치 영역 (Material Design Guidelines) - **기본값**
  static const double recommended = 48.0;

  /// 56.0 - 큰 터치 영역 (FAB, 주요 버튼)
  static const double large = 56.0;
}

/// 애니메이션 지속 시간 토큰
///
/// 일관된 애니메이션 타이밍을 위한 토큰입니다.
class AnimationDuration {
  AnimationDuration._();

  /// 100ms - 매우 짧은 애니메이션 (호버, 포커스)
  static const duration100 = Duration(milliseconds: 100);

  /// 200ms - 짧은 애니메이션 (페이드, 스케일)
  static const duration200 = Duration(milliseconds: 200);

  /// 300ms - 기본 애니메이션 (대부분의 경우) - **Material 기본값**
  static const duration300 = Duration(milliseconds: 300);

  /// 500ms - 긴 애니메이션 (페이지 전환)
  static const duration500 = Duration(milliseconds: 500);

  /// 1000ms - 매우 긴 애니메이션 (특수 효과)
  static const duration1000 = Duration(milliseconds: 1000);
}

/// SnackBar 표시 시간 토큰
///
/// 일관된 SnackBar 표시 시간을 위한 토큰입니다.
class SnackBarDuration {
  SnackBarDuration._();

  /// 2초 - 짧은 메시지 (성공/실패 알림)
  static const short = Duration(seconds: 2);

  /// 4초 - 기본 메시지 (일반 알림)
  static const medium = Duration(seconds: 4);

  /// 6초 - 긴 메시지 (복잡한 설명이 필요한 알림)
  static const long = Duration(seconds: 6);
}

/// 결제수단 색상 팔레트
///
/// 결제수단 생성 시 사용할 수 있는 색상 목록입니다.
class PaymentMethodColors {
  PaymentMethodColors._();

  /// 결제수단 색상 팔레트 (Material Design 기반)
  static const List<String> palette = [
    '#4CAF50', // Green
    '#2196F3', // Blue
    '#F44336', // Red
    '#FF9800', // Orange
    '#9C27B0', // Purple
    '#00BCD4', // Cyan
    '#E91E63', // Pink
    '#795548', // Brown
    '#607D8B', // Blue Grey
    '#3F51B5', // Indigo
    '#009688', // Teal
    '#CDDC39', // Lime
  ];
}

/// 카테고리 색상 팔레트
///
/// 카테고리 생성/수정 시 사용할 수 있는 색상 목록입니다.
/// Material 400 계열 14색 기반
class CategoryColorPalette {
  CategoryColorPalette._();

  static const List<String> palette = [
    '#EF5350',
    '#FF7043',
    '#FFA726',
    '#FFCA28',
    '#66BB6A',
    '#26A69A',
    '#42A5F5',
    '#5C6BC0',
    '#AB47BC',
    '#7B1FA2',
    '#EC407A',
    '#78909C',
  ];
}

/// 사용 예시:
///
/// ```dart
/// // ❌ 하드코딩 (금지)
/// Padding(
///   padding: EdgeInsets.all(16),
///   child: Card(
///     shape: RoundedRectangleBorder(
///       borderRadius: BorderRadius.circular(12),
///     ),
///   ),
/// )
///
/// // ✅ 디자인 토큰 사용 (권장)
/// Padding(
///   padding: EdgeInsets.all(Spacing.md),
///   child: Card(
///     shape: RoundedRectangleBorder(
///       borderRadius: BorderRadius.circular(Radius.md),
///     ),
///   ),
/// )
/// ```
