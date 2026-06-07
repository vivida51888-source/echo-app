import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/echo_water_bubble.dart';
import '../utils/echo_bubble_layout.dart';

/// 过期雨露落地破碎动画（打开树场景时播放）。
class EchoBubbleShatterLayer extends StatefulWidget {
  const EchoBubbleShatterLayer({
    super.key,
    required this.bubbles,
    required this.sceneSize,
    required this.onComplete,
  });

  final List<EchoWaterBubble> bubbles;
  final Size sceneSize;
  final VoidCallback onComplete;

  @override
  State<EchoBubbleShatterLayer> createState() => _EchoBubbleShatterLayerState();
}

class _EchoBubbleShatterLayerState extends State<EchoBubbleShatterLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900 + widget.bubbles.length * 180),
    );
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete();
      }
    });
    _controller.forward();
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            size: widget.sceneSize,
            painter: _ShatterPainter(
              bubbles: widget.bubbles,
              sceneSize: widget.sceneSize,
              progress: _controller.value,
            ),
          );
        },
      ),
    );
  }
}

class _ShatterPainter extends CustomPainter {
  _ShatterPainter({
    required this.bubbles,
    required this.sceneSize,
    required this.progress,
  });

  final List<EchoWaterBubble> bubbles;
  final Size sceneSize;
  final double progress;

  static const _groundInset = 10.0;
  static const _fallEnd = 0.72;
  static const _shatterEnd = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < bubbles.length; i++) {
      _paintBubble(canvas, bubbles[i], i);
    }
  }

  void _paintBubble(Canvas canvas, EchoWaterBubble bubble, int index) {
    final start = EchoBubbleLayout.toPixel(bubble.anchor, sceneSize);
    final groundY = sceneSize.height - _groundInset;
    final fallDistance = (groundY - start.dy).clamp(24.0, sceneSize.height);
    final diameter = EchoBubbleMetrics.diameterFor(bubble.grams);
    final stagger = index * 0.12;
    final local = ((progress - stagger) / (1 - stagger * 0.6)).clamp(0.0, 1.0);
    if (local <= 0) return;

    final palette = EchoBubblePalette.forBubble(bubble);
    final inner = palette.gradient;

    if (local < _fallEnd) {
      final t = Curves.easeInCubic.transform(local / _fallEnd);
      final y = start.dy + fallDistance * t;
      final wobble = math.sin(t * math.pi * 3) * (1 - t) * 2.5;
      _drawOrb(
        canvas,
        Offset(start.dx + wobble, y),
        diameter,
        inner,
        opacity: 1.0,
      );
      return;
    }

    final shatterT =
        Curves.easeOutCubic.transform((local - _fallEnd) / (_shatterEnd - _fallEnd));
    final impact = Offset(start.dx, groundY);

    _drawSplash(canvas, impact, diameter, inner, shatterT);

    final seed = bubble.layoutSeed;
    const fragments = 7;
    for (var f = 0; f < fragments; f++) {
      final angle = (f / fragments) * math.pi * 2 + seed * 0.01;
      final speed = diameter * (0.35 + (f % 3) * 0.12);
      final dx = math.cos(angle) * speed * shatterT;
      final dy = -math.sin(angle).abs() * speed * 0.55 * shatterT +
          shatterT * shatterT * diameter * 0.45;
      final fragR = diameter * 0.11 * (1 - shatterT * 0.65);
      final opacity = (1 - shatterT).clamp(0.0, 1.0);
      if (opacity <= 0.02 || fragR <= 0.5) continue;

      final paint = Paint()
        ..color = inner[f.isEven ? 0 : 1].withValues(alpha: opacity * 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(impact + Offset(dx, dy - diameter * 0.08), fragR, paint);
    }

    if (shatterT < 0.35) {
      _drawOrb(
        canvas,
        impact - Offset(0, diameter * 0.08),
        diameter * (1 - shatterT * 1.8),
        inner,
        opacity: (1 - shatterT * 2.8).clamp(0.0, 1.0),
      );
    }
  }

  void _drawOrb(
    Canvas canvas,
    Offset center,
    double diameter,
    List<Color> inner, {
    required double opacity,
  }) {
    if (opacity <= 0.02 || diameter <= 1) return;
    final rect = Rect.fromCircle(center: center, radius: diameter / 2);
    final gradient = RadialGradient(
      colors: [
        inner[0].withValues(alpha: opacity * 0.98),
        inner[1].withValues(alpha: opacity * 0.72),
      ],
      stops: const [0.22, 1],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawCircle(center, diameter / 2, paint);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: opacity * 0.82)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, diameter / 2 - 0.6, border);
  }

  void _drawSplash(
    Canvas canvas,
    Offset center,
    double diameter,
    List<Color> inner,
    double t,
  ) {
    final splashW = diameter * (0.9 + t * 1.4);
    final splashH = diameter * 0.16 * (1 - t * 0.5);
    final opacity = (0.35 * (1 - t)).clamp(0.0, 0.35);
    if (opacity <= 0.01) return;

    final paint = Paint()
      ..color = inner[1].withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, diameter * 0.04),
        width: splashW,
        height: splashH,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ShatterPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
