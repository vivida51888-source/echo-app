import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/echo_tree_growth.dart';

/// 手绘风格的回响之树，按 visualStage 呈现真实生长形态。
class EchoTreePainter extends CustomPainter {
  EchoTreePainter({
    required this.visualStage,
    required this.wilt,
    this.saturation = 1,
  });

  final int visualStage;
  final EchoTreeWiltLevel wilt;
  final double saturation;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final groundY = size.height * 0.88;

    _drawGround(canvas, size, cx, groundY);

    canvas.save();
    if (wilt.droop > 0) {
      canvas.translate(cx, groundY);
      canvas.rotate(wilt.droop);
      canvas.translate(-cx, -groundY);
    }

    switch (visualStage.clamp(0, 6)) {
      case 0:
        _drawSeed(canvas, cx, groundY);
      case 1:
        _drawSprout(canvas, cx, groundY, scale: 0.55);
      case 2:
        _drawSprout(canvas, cx, groundY, scale: 0.78);
      case 3:
        _drawYoungTree(canvas, cx, groundY, scale: 0.82);
      case 4:
        _drawYoungTree(canvas, cx, groundY, scale: 1.0);
      case 5:
        _drawMatureTree(canvas, cx, groundY, scale: 1.0);
      default:
        _drawMatureTree(canvas, cx, groundY, scale: 1.12);
    }

    canvas.restore();
  }

  void _drawGround(Canvas canvas, Size size, double cx, double groundY) {
    final soil = Paint()
      ..color = _c(const Color(0xFFC4A882), 0.55)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, groundY + 6),
        width: size.width * 0.72,
        height: size.height * 0.1,
      ),
      soil,
    );
  }

  void _drawSeed(Canvas canvas, double cx, double groundY) {
    final shell = Paint()..color = _c(const Color(0xFF8B6914));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, groundY - 8), width: 14, height: 18),
      shell,
    );
    final highlight = Paint()..color = _c(const Color(0xFFD4A84B), 0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 2, groundY - 11), width: 5, height: 6),
      highlight,
    );
  }

  void _drawSprout(Canvas canvas, double cx, double groundY, {required double scale}) {
    final trunkPaint = Paint()
      ..color = _c(const Color(0xFF8B6914))
      ..strokeWidth = 3 * scale
      ..strokeCap = StrokeCap.round;

    final trunkH = 28 * scale;
    canvas.drawLine(
      Offset(cx, groundY),
      Offset(cx, groundY - trunkH),
      trunkPaint,
    );

    _drawLeafCluster(
      canvas,
      Offset(cx, groundY - trunkH - 4),
      16 * scale,
      _c(const Color(0xFF6FAF82)),
    );
    if (scale > 0.65) {
      _drawLeafCluster(
        canvas,
        Offset(cx - 10 * scale, groundY - trunkH * 0.55),
        10 * scale,
        _c(const Color(0xFF7BA889)),
      );
      _drawLeafCluster(
        canvas,
        Offset(cx + 10 * scale, groundY - trunkH * 0.55),
        10 * scale,
        _c(const Color(0xFF7BA889)),
      );
    }
  }

  void _drawYoungTree(Canvas canvas, double cx, double groundY, {required double scale}) {
    final trunkPaint = Paint()
      ..color = _c(const Color(0xFF7A5C3A))
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round;

    final trunkH = 52 * scale;
    canvas.drawLine(
      Offset(cx, groundY),
      Offset(cx, groundY - trunkH),
      trunkPaint,
    );

    _drawBranch(canvas, cx, groundY - trunkH * 0.45, -0.55, 22 * scale);
    _drawBranch(canvas, cx, groundY - trunkH * 0.62, 0.48, 18 * scale);

    _drawCanopy(
      canvas,
      Offset(cx, groundY - trunkH - 14 * scale),
      34 * scale,
      _c(const Color(0xFF6FAF82)),
    );
    _drawCanopy(
      canvas,
      Offset(cx - 16 * scale, groundY - trunkH + 2),
      22 * scale,
      _c(const Color(0xFF7BA889), 0.9),
    );
    _drawCanopy(
      canvas,
      Offset(cx + 16 * scale, groundY - trunkH + 2),
      22 * scale,
      _c(const Color(0xFF7BA889), 0.9),
    );
  }

  void _drawMatureTree(Canvas canvas, double cx, double groundY, {required double scale}) {
    final trunkPaint = Paint()
      ..color = _c(const Color(0xFF6B4E2E))
      ..strokeWidth = 7 * scale
      ..strokeCap = StrokeCap.round;

    final trunkH = 68 * scale;
    canvas.drawLine(
      Offset(cx, groundY),
      Offset(cx, groundY - trunkH),
      trunkPaint,
    );

    _drawBranch(canvas, cx, groundY - trunkH * 0.35, -0.72, 30 * scale);
    _drawBranch(canvas, cx, groundY - trunkH * 0.52, 0.65, 28 * scale);
    _drawBranch(canvas, cx, groundY - trunkH * 0.68, -0.35, 20 * scale);
    _drawBranch(canvas, cx, groundY - trunkH * 0.78, 0.42, 18 * scale);

    _drawCanopy(
      canvas,
      Offset(cx, groundY - trunkH - 22 * scale),
      46 * scale,
      _c(const Color(0xFF5A9A6A)),
    );
    _drawCanopy(
      canvas,
      Offset(cx - 24 * scale, groundY - trunkH - 2),
      30 * scale,
      _c(const Color(0xFF6FAF82)),
    );
    _drawCanopy(
      canvas,
      Offset(cx + 24 * scale, groundY - trunkH - 2),
      30 * scale,
      _c(const Color(0xFF6FAF82)),
    );
    _drawCanopy(
      canvas,
      Offset(cx, groundY - trunkH - 38 * scale),
      28 * scale,
      _c(const Color(0xFF7BA889), 0.85),
    );
  }

  void _drawBranch(
    Canvas canvas,
    double cx,
    double y,
    double angle,
    double length,
  ) {
    final paint = Paint()
      ..color = _c(const Color(0xFF7A5C3A))
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final end = Offset(
      cx + math.cos(angle) * length,
      y + math.sin(angle) * length * 0.55,
    );
    canvas.drawLine(Offset(cx, y), end, paint);
  }

  void _drawCanopy(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()..color = color;
    canvas.drawCircle(center, radius * 0.55, paint);
    canvas.drawCircle(
      Offset(center.dx - radius * 0.35, center.dy + radius * 0.08),
      radius * 0.42,
      paint,
    );
    canvas.drawCircle(
      Offset(center.dx + radius * 0.35, center.dy + radius * 0.08),
      radius * 0.42,
      paint,
    );
  }

  void _drawLeafCluster(Canvas canvas, Offset center, double size, Color color) {
    final paint = Paint()..color = color;
    canvas.drawOval(
      Rect.fromCenter(center: center, width: size, height: size * 0.75),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - size * 0.28, center.dy + 2),
        width: size * 0.55,
        height: size * 0.42,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx + size * 0.28, center.dy + 2),
        width: size * 0.55,
        height: size * 0.42,
      ),
      paint,
    );
  }

  Color _c(Color color, [double alphaScale = 1]) {
    final a = (color.a * saturation * alphaScale).clamp(0.0, 1.0);
    return color.withValues(alpha: a);
  }

  @override
  bool shouldRepaint(covariant EchoTreePainter oldDelegate) {
    return oldDelegate.visualStage != visualStage ||
        oldDelegate.wilt != wilt ||
        oldDelegate.saturation != saturation;
  }
}
