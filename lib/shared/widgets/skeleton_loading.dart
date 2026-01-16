import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../themes/design_tokens.dart';

/// 스켈레톤 로딩 위젯 - Shimmer 효과가 적용된 로딩 플레이스홀더
///
/// CircularProgressIndicator 대신 사용하여 레이아웃 시프트를 방지하고
/// 더 나은 사용자 경험을 제공합니다.
///
/// 사용 예시:
/// ```dart
/// // 기본 박스 스켈레톤
/// SkeletonBox(width: 100, height: 20)
///
/// // 원형 스켈레톤 (아바타용)
/// SkeletonCircle(size: 40)
///
/// // 텍스트 라인 스켈레톤
/// SkeletonLine(width: double.infinity)
///
/// // 카드 모양 스켈레톤
/// SkeletonCard(height: 100)
/// ```
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius,
    super.key,
  });

  /// 스켈레톤의 너비
  final double width;

  /// 스켈레톤의 높이
  final double height;

  /// 테두리 반경 (기본값: BorderRadiusToken.sm)
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(
            borderRadius ?? BorderRadiusToken.sm,
          ),
        ),
      ),
    );
  }
}

/// 원형 스켈레톤 로딩 위젯
///
/// 주로 아바타나 프로필 이미지 로딩 시 사용합니다.
class SkeletonCircle extends StatelessWidget {
  const SkeletonCircle({
    required this.size,
    super.key,
  });

  /// 원의 지름
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: baseColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

/// 텍스트 라인 스켈레톤 위젯
///
/// 한 줄 텍스트의 로딩 상태를 표현합니다.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    this.width = double.infinity,
    this.height = 16.0,
    super.key,
  });

  /// 라인의 너비 (기본값: 전체 너비)
  final double width;

  /// 라인의 높이 (기본값: 16.0)
  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadiusToken.xs,
    );
  }
}

/// 카드 모양 스켈레톤 위젯
///
/// 리스트 아이템이나 카드 컴포넌트의 로딩 상태를 표현합니다.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({
    this.height = 80.0,
    this.width = double.infinity,
    super.key,
  });

  /// 카드의 높이
  final double height;

  /// 카드의 너비 (기본값: 전체 너비)
  final double width;

  @override
  Widget build(BuildContext context) {
    return SkeletonBox(
      width: width,
      height: height,
      borderRadius: BorderRadiusToken.md,
    );
  }
}

/// 트랜잭션 리스트 아이템 스켈레톤
///
/// 거래 내역 리스트의 로딩 상태를 표현합니다.
/// 아이콘, 텍스트, 금액이 포함된 구조를 모방합니다.
class SkeletonTransactionItem extends StatelessWidget {
  const SkeletonTransactionItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Row(
        children: [
          const SkeletonCircle(size: 40),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(
                  width: MediaQuery.of(context).size.width * 0.4,
                  height: 16,
                ),
                const SizedBox(height: Spacing.xs),
                SkeletonLine(
                  width: MediaQuery.of(context).size.width * 0.25,
                  height: 12,
                ),
              ],
            ),
          ),
          const SizedBox(width: Spacing.md),
          SkeletonLine(
            width: MediaQuery.of(context).size.width * 0.2,
            height: 18,
          ),
        ],
      ),
    );
  }
}

/// 스켈레톤 리스트 뷰
///
/// 여러 개의 스켈레톤 아이템을 리스트로 표시합니다.
class SkeletonListView extends StatelessWidget {
  const SkeletonListView({
    this.itemCount = 5,
    this.itemBuilder,
    super.key,
  });

  /// 표시할 스켈레톤 아이템 개수
  final int itemCount;

  /// 커스텀 스켈레톤 아이템 빌더
  /// null인 경우 기본 SkeletonTransactionItem을 사용합니다.
  final Widget Function(BuildContext context, int index)? itemBuilder;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemBuilder: itemBuilder ??
          (context, index) => const SkeletonTransactionItem(),
    );
  }
}
