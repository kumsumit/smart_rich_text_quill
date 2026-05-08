import 'package:flutter/material.dart';

/// A simple shimmering/pulsing placeholder shown while images or files load.
class SrqLoadingPlaceholder extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius? borderRadius;

  const SrqLoadingPlaceholder({
    super.key,
    this.height = 100,
    this.width = double.infinity,
    this.borderRadius,
  });

  @override
  State<SrqLoadingPlaceholder> createState() => _SrqLoadingPlaceholderState();
}

class _SrqLoadingPlaceholderState extends State<SrqLoadingPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Colors.grey.shade300.withValues(alpha: _animation.value),
            borderRadius: widget.borderRadius ?? BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.image_outlined,
              color: Colors.white70,
              size: 24,
            ),
          ),
        );
      },
    );
  }
}
