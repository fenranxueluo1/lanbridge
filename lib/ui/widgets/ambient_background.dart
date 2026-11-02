import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';

/// Soft aurora wash used behind every screen.
class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final dark = context.isDark;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: palette.bg),
        Positioned(
          top: -200,
          right: -140,
          child: _Glow(
            color: AppColors.brand.withValues(alpha: dark ? 0.30 : 0.18),
            size: 560,
          ),
        ),
        Positioned(
          bottom: -260,
          left: -180,
          child: _Glow(
            color: AppColors.sky.withValues(alpha: dark ? 0.20 : 0.12),
            size: 620,
          ),
        ),
        if (!dark)
          ColoredBox(color: Colors.white.withValues(alpha: 0.12)),
        child,
      ],
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0, 1],
          ),
        ),
      ),
    );
  }
}

/// Page entrance animation used sparingly to keep the UI alive on first paint.
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 14,
  });

  final Widget child;
  final Duration delay;
  final double offset;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  );

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) {
        return Opacity(
          opacity: curved.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - curved.value) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
