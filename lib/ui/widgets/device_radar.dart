import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/haptics.dart';
import '../../data/models/device.dart';
import 'device_avatar.dart';

/// Animated radar used as the hero element of the Nearby screen.
class DeviceRadar extends StatefulWidget {
  const DeviceRadar({
    super.key,
    required this.devices,
    required this.onSelect,
    required this.localName,
    this.scanning = false,
  });

  final List<Device> devices;
  final ValueChanged<Device> onSelect;
  final String localName;
  final bool scanning;

  @override
  State<DeviceRadar> createState() => _DeviceRadarState();
}

class _DeviceRadarState extends State<DeviceRadar>
    with TickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimations();
  }

  @override
  void didUpdateWidget(covariant DeviceRadar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanning != oldWidget.scanning) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    if (widget.scanning) {
      if (!_sweep.isAnimating) _sweep.repeat();
      if (!_pulse.isAnimating) _pulse.repeat();
      return;
    }
    _sweep
      ..stop()
      ..value = 0;
    _pulse
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    _sweep.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 320.0;
        final availableHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : 380.0;
        final size = math.min(math.min(available, availableHeight), 380.0);
        final dots = widget.devices.take(6).toList();
        final dotSize = (size * 0.125).clamp(34.0, 52.0);
        final localSize = (size * 0.235).clamp(64.0, 104.0);
        final orbit = size * 0.36;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: AnimatedBuilder(
                      animation: Listenable.merge([_sweep, _pulse]),
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _RadarPainter(
                            sweep: _sweep.value,
                            pulse: _pulse.value,
                            scanning: widget.scanning,
                            brand: palette.brand,
                            cyan: AppColors.cyan,
                            hairline: palette.hairline,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                if (size > 220)
                  for (var i = 0; i < dots.length; i++)
                    _orbitDot(
                      device: dots[i],
                      index: i,
                      total: dots.length,
                      size: size,
                      orbit: orbit,
                      dotSize: dotSize,
                    ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          AnimatedBuilder(
                            animation: _pulse,
                            builder: (context, child) {
                              return Container(
                                width: localSize +
                                    (localSize * 0.5 * _pulse.value),
                                height: localSize +
                                    (localSize * 0.5 * _pulse.value),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: palette.brand.withValues(
                                      alpha: 0.22 * (1 - _pulse.value),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          LocalDeviceAvatar(size: localSize),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surface.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: palette.hairline),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: AppColors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: size * 0.55,
                              ),
                              child: Text(
                                widget.localName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textStyles.labelSmall?.copyWith(
                                  color: palette.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _orbitDot({
    required Device device,
    required int index,
    required int total,
    required double size,
    required double orbit,
    required double dotSize,
  }) {
    final angle = -math.pi / 2 + (2 * math.pi / total) * index + 0.32;
    final x = size / 2 + orbit * math.cos(angle);
    final y = size / 2 + orbit * math.sin(angle);
    final labelWidth = math.max(dotSize + 26, 78.0);

    return Positioned(
      left: x - labelWidth / 2,
      top: y - dotSize / 2,
      width: labelWidth,
      child: Tooltip(
        message: device.name,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            if (!device.isOnline) return;
            Haptics.tap();
            widget.onSelect(device);
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 400),
                opacity: device.isOnline ? 1 : 0.45,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: device.isOnline
                        ? [
                            BoxShadow(
                              color: device.kind.gradient.colors.first
                                  .withValues(alpha: 0.45),
                              blurRadius: 18,
                            ),
                          ]
                        : null,
                  ),
                  child: DeviceAvatar(
                    icon: device.kind.icon,
                    gradient: device.kind.gradient,
                    size: dotSize,
                    glow: false,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textStyles.labelSmall?.copyWith(
                  fontSize: 9.5,
                  color: context.palette.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  _RadarPainter({
    required this.sweep,
    required this.pulse,
    required this.scanning,
    required this.brand,
    required this.cyan,
    required this.hairline,
  });

  final double sweep;
  final double pulse;
  final bool scanning;
  final Color brand;
  final Color cyan;
  final Color hairline;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;

    final ringPaint = Paint()
      ..color = hairline.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final factor in [0.42, 0.62, 0.82, 0.99]) {
      canvas.drawCircle(center, radius * factor, ringPaint);
    }

    final axisPaint = Paint()
      ..color = hairline.withValues(alpha: 0.3)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(center.dx - radius, center.dy),
      Offset(center.dx + radius, center.dy),
      axisPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      axisPaint,
    );

    final angle = sweep * 2 * math.pi - math.pi / 2;
    final rect = Rect.fromCircle(center: center, radius: radius * 0.99);
    final shader = SweepGradient(
      colors: [
        brand.withValues(alpha: 0),
        brand.withValues(alpha: scanning ? 0.34 : 0.2),
        brand.withValues(alpha: 0),
      ],
      stops: const [0, 0.11, 0.24],
      transform: GradientRotation(angle),
    ).createShader(rect);
    canvas.drawCircle(center, radius * 0.99, Paint()..shader = shader);

    final edge = Offset(
      center.dx + radius * 0.99 * math.cos(angle),
      center.dy + radius * 0.99 * math.sin(angle),
    );
    canvas.drawLine(
      center,
      edge,
      Paint()
        ..color = cyan.withValues(alpha: 0.45)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );

    for (final offset in [0.0, 0.5]) {
      final t = (pulse + offset) % 1;
      final ringRadius = radius * (0.2 + 0.8 * t);
      canvas.drawCircle(
        center,
        ringRadius,
        Paint()
          ..color = brand.withValues(alpha: (1 - t) * 0.24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweep != sweep ||
        oldDelegate.pulse != pulse ||
        oldDelegate.scanning != scanning ||
        oldDelegate.brand != brand;
  }
}
