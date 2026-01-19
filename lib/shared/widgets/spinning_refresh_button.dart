import 'package:flutter/material.dart';

import '../themes/design_tokens.dart';

/// 스피닝 효과가 있는 새로고침 버튼
///
/// 새로고침 중일 때 아이콘이 회전합니다.
class SpinningRefreshButton extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final String? tooltip;
  final double iconSize;
  final Color? iconColor;

  const SpinningRefreshButton({
    super.key,
    required this.onRefresh,
    this.tooltip,
    this.iconSize = IconSize.sm,
    this.iconColor,
  });

  @override
  State<SpinningRefreshButton> createState() => _SpinningRefreshButtonState();
}

class _SpinningRefreshButtonState extends State<SpinningRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });
    _controller.repeat();

    try {
      await widget.onRefresh();
    } finally {
      _controller.stop();
      _controller.reset();
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.iconColor ?? Theme.of(context).colorScheme.onSurface;

    return IconButton(
      icon: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.rotate(
            angle: _controller.value * 2 * 3.14159,
            child: child,
          );
        },
        child: Icon(Icons.refresh, size: widget.iconSize, color: color),
      ),
      tooltip: widget.tooltip,
      onPressed: _handleRefresh,
    );
  }
}
