import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/themes/design_tokens.dart';

/// 페이지 전환 애니메이션 유틸리티
///
/// GoRouter에서 사용할 수 있는 커스텀 페이지 전환을 정의합니다.
/// 디자인 토큰의 AnimationDuration을 사용하여 일관된 타이밍을 유지합니다.

/// 슬라이드 전환 (오른쪽에서 왼쪽)
///
/// 일반적인 푸시 네비게이션에 사용합니다.
/// iOS/Android 기본 전환과 유사한 동작입니다.
CustomTransitionPage<T> slideTransition<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: AnimationDuration.duration300,
    reverseTransitionDuration: AnimationDuration.duration300,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      final secondaryTween = Tween(
        begin: Offset.zero,
        end: const Offset(-0.3, 0.0),
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(
        position: animation.drive(tween),
        child: SlideTransition(
          position: secondaryAnimation.drive(secondaryTween),
          child: child,
        ),
      );
    },
  );
}

/// 페이드 전환
///
/// 인증 페이지, 스플래시 등 부드러운 전환이 필요한 곳에 사용합니다.
CustomTransitionPage<T> fadeTransition<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: AnimationDuration.duration200,
    reverseTransitionDuration: AnimationDuration.duration200,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
  );
}

/// 페이드 + 스케일 전환
///
/// 모달이나 다이얼로그처럼 강조가 필요한 전환에 사용합니다.
CustomTransitionPage<T> fadeScaleTransition<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: AnimationDuration.duration300,
    reverseTransitionDuration: AnimationDuration.duration200,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final fadeAnimation = CurveTween(
        curve: Curves.easeOut,
      ).animate(animation);

      final scaleAnimation = Tween<double>(
        begin: 0.95,
        end: 1.0,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);

      return FadeTransition(
        opacity: fadeAnimation,
        child: ScaleTransition(scale: scaleAnimation, child: child),
      );
    },
  );
}

/// 슬라이드 업 전환 (아래에서 위로)
///
/// 풀스크린 모달이나 시트에 사용합니다.
CustomTransitionPage<T> slideUpTransition<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: AnimationDuration.duration300,
    reverseTransitionDuration: AnimationDuration.duration300,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final tween = Tween(
        begin: const Offset(0.0, 1.0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));

      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

/// 전환 없음
///
/// 즉시 전환이 필요한 경우에 사용합니다.
CustomTransitionPage<T> noTransition<T>({
  required LocalKey key,
  required Widget child,
  String? name,
}) {
  return CustomTransitionPage<T>(
    key: key,
    name: name,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}
