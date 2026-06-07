import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/mood_journey.dart';
import '../../models/weather_mood.dart';
import '../../services/echo_stats_service.dart';
import '../../theme/echo_colors.dart';
import 'scenery_theme.dart';

/// 绘制一段完整沿途风景（可指定主题与透明度）。
class _SceneryCanvas {
  _SceneryCanvas({
    required this.canvas,
    required this.size,
    required this.theme,
    required this.alpha,
    required this.seed,
    required this.time,
    this.roadOffsetX = 0,
    this.isEmpty = false,
  });

  final Canvas canvas;
  final Size size;
  final SceneryTheme theme;
  final double alpha;
  final int seed;
  final double time;
  final double roadOffsetX;
  final bool isEmpty;

  void paintAll() {
    if (isEmpty) {
      _paintEmpty();
      return;
    }
    _sky();
    if (theme.sunAlpha > 0.02) _sun();
    if (theme.cloudDensity > 0.04) _clouds();
    if (theme.rainbowStrength > 0.04) _rainbow();
    RoadGeometry.paintHill(canvas, size, theme.hill, alpha * 0.52);
    RoadGeometry.paintGroundBand(canvas, size, theme.ground, alpha * 0.82);
    if (theme.flowerWarmth > 0.08) _meadow();
    _road(drawDashes: true);
    if (theme.rainIntensity > 0.04) _rain();
    if (theme.fog > 0.04) _fog();
  }

  /// 未书写：纯色块 + 薄雾，不画虚线 / 雨丝 / 云（避免段边界出现灰色线条）。
  void _paintEmpty() {
    _sky();
    RoadGeometry.paintHill(canvas, size, theme.hill, alpha * 0.38);
    RoadGeometry.paintGroundBand(canvas, size, theme.ground, alpha * 0.55);
    _road(drawDashes: false);
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.16, size.width, RoadGeometry.groundTop(size)),
      Paint()..color = Colors.white.withValues(alpha: 0.42 * alpha),
    );
  }

  void _sky() {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.skyTop.withValues(alpha: alpha),
            theme.skyMid.withValues(alpha: alpha),
            theme.skyBottom.withValues(alpha: alpha),
          ],
          stops: const [0.0, 0.42, RoadGeometry.groundTopRatio],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _sun() {
    final sun = Offset(size.width * 0.78, size.height * 0.12);
    final glow = theme.sunAlpha * alpha;
    canvas.drawCircle(
      sun,
      34,
      Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.14 * glow),
    );
    canvas.drawCircle(
      sun,
      22,
      Paint()..color = const Color(0xFFFFD54F).withValues(alpha: 0.32 * glow),
    );
    canvas.drawCircle(
      sun,
      14,
      Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.95 * glow),
    );
  }

  void _clouds() {
    final density = theme.cloudDensity;
    final positions = [
      Offset(size.width * 0.22, size.height * 0.1),
      Offset(size.width * 0.52, size.height * 0.07),
      Offset(size.width * 0.78, size.height * 0.11),
    ];
    for (var i = 0; i < positions.length; i++) {
      final w = 38.0 + i * 10 + density * 18;
      _softCloud(positions[i], w, density * alpha);
    }
    if (density > 0.55) {
      _stormMass(Offset(size.width * 0.42, size.height * 0.05), 68, density * alpha);
    }
  }

  void _softCloud(Offset c, double w, double a) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.88 * a);
    canvas.drawCircle(c, w * 0.28, p);
    canvas.drawCircle(Offset(c.dx - w * 0.24, c.dy + 3), w * 0.22, p);
    canvas.drawCircle(Offset(c.dx + w * 0.22, c.dy + 1), w * 0.26, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 5), width: w * 0.72, height: w * 0.18),
        const Radius.circular(8),
      ),
      p,
    );
  }

  void _stormMass(Offset c, double w, double a) {
    final p = Paint()..color = const Color(0xFF546E7A).withValues(alpha: 0.82 * a);
    canvas.drawCircle(c, w * 0.3, p);
    canvas.drawCircle(Offset(c.dx - w * 0.28, c.dy + 6), w * 0.26, p);
    canvas.drawCircle(Offset(c.dx + w * 0.26, c.dy + 4), w * 0.28, p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy + 8), width: w * 0.88, height: w * 0.2),
        const Radius.circular(6),
      ),
      p,
    );
  }

  void _rainbow() {
    const bands = [
      Color(0xFFE57373),
      Color(0xFFFFB74D),
      Color(0xFFFFF176),
      Color(0xFF81C784),
      Color(0xFF64B5F6),
      Color(0xFFBA68C8),
    ];
    final strength = theme.rainbowStrength * alpha;
    final center = Offset(size.width * 0.48, RoadGeometry.groundTop(size) + 22);
    for (var i = 0; i < bands.length; i++) {
      canvas.drawArc(
        Rect.fromCenter(center: center, width: 196 - i * 10, height: 78 - i * 4.5),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = bands[i].withValues(alpha: 0.82 * strength)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5.5,
      );
    }
    final pulse = 0.5 + math.sin(time * math.pi * 2) * 0.5;
    canvas.drawCircle(
      Offset(size.width * 0.48, RoadGeometry.groundTop(size) - 10),
      3 + pulse * 2.5,
      Paint()..color = Colors.white.withValues(alpha: 0.55 * strength),
    );
  }

  void _meadow() {
    final warmth = theme.flowerWarmth;
    final gTop = RoadGeometry.groundTop(size);
    final gBot = RoadGeometry.roadTop(size);
    final rnd = math.Random(seed);
    for (var i = 0; i < 22; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = gTop + rnd.nextDouble() * (gBot - gTop);
      final hue = rnd.nextBool()
          ? const Color(0xFFE8C96A)
          : (rnd.nextBool() ? const Color(0xFFF4A4A4) : const Color(0xFFB8D4A8));
      canvas.drawCircle(
        Offset(x, y),
        1.2 + rnd.nextDouble() * 1.8,
        Paint()..color = hue.withValues(alpha: 0.55 * warmth * alpha),
      );
    }
    final flowerY = gTop + (gBot - gTop) * 0.58;
    for (var i = 0; i < 3; i++) {
      _wildflower(Offset(28 + i * 72.0, flowerY), warmth * alpha, seed + i);
    }
  }

  void _wildflower(Offset base, double a, int s) {
    canvas.drawLine(
      base,
      Offset(base.dx, base.dy - 18),
      Paint()
        ..color = const Color(0xFF689F6A).withValues(alpha: 0.85 * a)
        ..strokeWidth = 2,
    );
    final rnd = math.Random(s);
    final petal = Color.lerp(
      const Color(0xFFFFB4A2),
      const Color(0xFFFFD180),
      rnd.nextDouble(),
    )!;
    for (var i = 0; i < 6; i++) {
      final ang = i * math.pi / 3;
      canvas.drawCircle(
        Offset(base.dx + math.cos(ang) * 5.5, base.dy - 20 + math.sin(ang) * 5.5),
        3,
        Paint()..color = petal.withValues(alpha: 0.9 * a),
      );
    }
    canvas.drawCircle(
      Offset(base.dx, base.dy - 20),
      3.5,
      Paint()..color = const Color(0xFF8D6E63).withValues(alpha: 0.85 * a),
    );
  }

  void _road({required bool drawDashes}) {
    final top = RoadGeometry.roadTop(size);
    final wet = theme.wet.clamp(0.0, 1.0);
    final topColor = Color.lerp(theme.roadDryTop, theme.roadWetTop, wet)!;
    final botColor = Color.lerp(theme.roadDryBottom, theme.roadWetBottom, wet)!;
    if (theme.flooded > 0.2) {
      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width, size.height - top),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF546E7A).withValues(alpha: alpha),
              const Color(0xFF37474F).withValues(alpha: alpha),
            ],
          ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, top, size.width, size.height - top),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              topColor.withValues(alpha: alpha),
              botColor.withValues(alpha: alpha),
            ],
          ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
      );
    }

    if (!drawDashes) return;

    final dashY = RoadGeometry.roadDashY(size);
    final dashAlpha = (wet > 0.3 ? 0.48 : 0.72) * alpha;
    final dash = Paint()
      ..color = const Color(0xFFF5F0DC).withValues(alpha: dashAlpha)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dashPeriod = 26.0;
    const dashLen = 12.0;
    const dashStart = 6.0;
    var x = dashStart - (roadOffsetX % dashPeriod);
    while (x < size.width + dashLen) {
      if (x >= -dashLen) {
        canvas.drawLine(
          Offset(x.clamp(0.0, size.width), dashY),
          Offset((x + dashLen).clamp(0.0, size.width), dashY),
          dash,
        );
      }
      x += dashPeriod;
    }

    if (wet > 0.25) {
      for (var i = 0; i < 4; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(24.0 + i * 58 + math.sin(time + i) * 2, dashY + 7),
            width: 26 + wet * 12,
            height: 6 + wet * 4,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.16 * wet * alpha),
        );
      }
    }
  }

  void _rain() {
    final intensity = theme.rainIntensity;
    final rnd = math.Random(seed);
    final count = (28 + intensity * 48).round();
    final stroke = 1.0 + intensity * 1.4;
    final speed = 50 + intensity * 70;
    final ceiling = RoadGeometry.groundTop(size);
    const edge = 20.0;
    final innerW = math.max(1.0, size.width - edge * 2);
    final p = Paint()
      ..color = Colors.white.withValues(alpha: (0.28 + intensity * 0.42) * alpha)
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < count; i++) {
      final x = edge + rnd.nextDouble() * innerW;
      final y = (rnd.nextDouble() * ceiling + time * speed + i * 19) % ceiling;
      canvas.drawLine(Offset(x, y), Offset(x - 5 - intensity * 2, y + 12 + intensity * 4), p);
    }
  }

  void _fog() {
    canvas.drawRect(
      Rect.fromLTRB(0, size.height * 0.18, size.width, RoadGeometry.groundTop(size)),
      Paint()..color = Colors.white.withValues(alpha: theme.fog * 0.38 * alpha),
    );
  }
}

/// 一段公路沿途风景（每段独立绘制，无段间过渡）。
class RoadSegmentPainter extends CustomPainter {
  RoadSegmentPainter({
    required this.day,
    required this.time,
    this.roadOffsetX = 0,
  });

  final EchoDayStat day;
  final double time;
  final double roadOffsetX;

  @override
  void paint(Canvas canvas, Size size) {
    final kind = MoodJourneyLayout.sceneryFor(day);
    final seed = day.date.day + day.date.month * 17;

    _SceneryCanvas(
      canvas: canvas,
      size: size,
      theme: SceneryTheme.forKind(kind),
      alpha: 1.0,
      seed: seed,
      time: time,
      roadOffsetX: roadOffsetX,
      isEmpty: kind == MoodSceneryKind.empty,
    ).paintAll();
  }

  @override
  bool shouldRepaint(covariant RoadSegmentPainter old) =>
      old.day != day || old.time != time || old.roadOffsetX != roadOffsetX;
}

/// 起点「回响启程」— 与终点驿站对称的仪式感。
class StartSegmentPainter extends CustomPainter {
  StartSegmentPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFE8B4BC),
            Color(0xFFF5D0C4),
            Color(0xFF9EC5E8),
            Color(0xFFB8D8F0),
          ],
          stops: const [0.0, 0.28, 0.58, RoadGeometry.groundTopRatio],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final sun = Offset(size.width * 0.18, size.height * 0.14);
    canvas.drawCircle(sun, 28, Paint()..color = const Color(0xFFFFE082).withValues(alpha: 0.2));
    canvas.drawCircle(sun, 16, Paint()..color = const Color(0xFFFFF8E1).withValues(alpha: 0.85));

    RoadGeometry.paintHill(canvas, size, const Color(0xFF6FA868), 0.48);
    RoadGeometry.paintGroundBand(canvas, size, const Color(0xFFD4C4A0), 0.78);

    final top = RoadGeometry.roadTop(size);
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, size.height - top),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF9A8B72), Color(0xFF6B5D48)],
        ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
    );

    final dashY = RoadGeometry.roadDashY(size);
    final dash = Paint()
      ..color = const Color(0xFFF5F0DC).withValues(alpha: 0.82)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, dashY), Offset(x + 12, dashY), dash);
    }

    // 起点线（绿白格）
    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(
            size.width - 26 + col * 8.0,
            top + 4 + row * 8,
            8,
            8,
          ),
          Paint()
            ..color = (row + col) % 2 == 0
                ? Colors.white
                : const Color(0xFF2E7D32),
        );
      }
    }

    _drawMilestone(canvas, Offset(size.width * 0.12, RoadGeometry.groundTop(size) + 20));
    _drawArch(canvas, Offset(MoodJourneyLayout.startDoorCenterX, top - 8));
    _drawPlaque(canvas, size);
  }

  void _drawMilestone(Canvas canvas, Offset base) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base, width: 14, height: 22),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawCircle(
      Offset(base.dx, base.dy - 16),
      5,
      Paint()..color = const Color(0xFFD4AF37).withValues(alpha: 0.9),
    );
  }

  void _drawArch(Canvas canvas, Offset base) {
    final p = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(base.dx, base.dy - 22), width: 64, height: 48),
      math.pi,
      math.pi,
      false,
      p,
    );
    canvas.drawLine(Offset(base.dx - 32, base.dy - 22), Offset(base.dx - 32, base.dy + 4), p);
    canvas.drawLine(Offset(base.dx + 32, base.dy - 22), Offset(base.dx + 32, base.dy + 4), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(base.dx, base.dy - 24), width: 66, height: 5),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    for (final dx in [-24.0, 24.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(base.dx + dx, base.dy - 30), width: 10, height: 14),
        Paint()..color = const Color(0xFF81C784).withValues(alpha: 0.88),
      );
    }
  }

  void _drawPlaque(Canvas canvas, Size size) {
    final cx = MoodJourneyLayout.startDoorCenterX;
    final baseY = RoadGeometry.roadTop(size) - 8;
    const plaqueW = 56.0;
    const plaqueH = 17.0;
    final center = Offset(cx, baseY - 30);
    final sway = math.sin(time * math.pi * 2 + 0.8) * 0.028;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sway);
    canvas.translate(-center.dx, -center.dy);

    final boardTop = center.dy - plaqueH / 2;
    final ropeTop = baseY - 46;
    for (final dx in [-17.0, 17.0]) {
      canvas.drawLine(
        Offset(cx + dx * 0.35, ropeTop),
        Offset(center.dx + dx, boardTop - 0.5),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 1.0,
      );
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: plaqueW, height: plaqueH),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF5D4037), Color(0xFF3E2723)],
        ).createShader(rect.outerRect),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFF81C784),
    );

    final title = TextPainter(
      text: const TextSpan(
        text: '回响启程',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFFE8F5E9),
          letterSpacing: 1.4,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset(center.dx - title.width / 2, center.dy - title.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant StartSegmentPainter old) => old.time != time;
}

/// 终点「回响驿站」— 仪式感动画 + 与全段对齐的路面。
class FinishSegmentPainter extends CustomPainter {
  FinishSegmentPainter({required this.time});

  final double time;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [
            Color(0xFFFF9A76),
            Color(0xFFFFCC80),
            Color(0xFF90CAF9),
            Color(0xFF81C784),
          ],
          stops: const [0.0, 0.32, 0.55, RoadGeometry.groundTopRatio],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    RoadGeometry.paintHill(canvas, size, const Color(0xFF2E7D32), 0.58);
    RoadGeometry.paintGroundBand(canvas, size, const Color(0xFF66BB6A), 0.82);

    final top = RoadGeometry.roadTop(size);
    canvas.drawRect(
      Rect.fromLTWH(0, top, size.width, size.height - top),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFD4A84B), Color(0xFF8B6914)],
        ).createShader(Rect.fromLTWH(0, top, size.width, size.height - top)),
    );

    final dashY = RoadGeometry.roadDashY(size);
    final dash = Paint()
      ..color = const Color(0xFFFFF8E1).withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (var x = 6.0; x < size.width; x += 26) {
      canvas.drawLine(Offset(x, dashY), Offset(x + 12, dashY), dash);
    }

    for (var row = 0; row < 4; row++) {
      for (var col = 0; col < 2; col++) {
        canvas.drawRect(
          Rect.fromLTWH(10 + col * 8.0, top + 4 + row * 8, 8, 8),
          Paint()..color = (row + col) % 2 == 0 ? Colors.white : const Color(0xFF212121),
        );
      }
    }

    _drawEchoTree(canvas, Offset(size.width * 0.58, RoadGeometry.groundTop(size) + 18));
    _drawArch(canvas, Offset(MoodJourneyLayout.finishDoorCenterX, top - 8));
    _drawPlaque(canvas, size);
  }

  void _drawEchoTree(Canvas canvas, Offset base) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(base.dx, base.dy - 10), width: 10, height: 28),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFF5D4037),
    );
    for (final dx in [-16.0, 0.0, 16.0]) {
      canvas.drawCircle(
        Offset(base.dx + dx, base.dy - 32),
        dx == 0 ? 24 : 16,
        Paint()..color = const Color(0xFF388E3C),
      );
    }
  }

  void _drawArch(Canvas canvas, Offset base) {
    final p = Paint()
      ..color = const Color(0xFF8D6E63)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(center: Offset(base.dx, base.dy - 22), width: 64, height: 48),
      math.pi,
      math.pi,
      false,
      p,
    );
    canvas.drawLine(Offset(base.dx - 32, base.dy - 22), Offset(base.dx - 32, base.dy + 4), p);
    canvas.drawLine(Offset(base.dx + 32, base.dy - 22), Offset(base.dx + 32, base.dy + 4), p);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(base.dx, base.dy - 24), width: 66, height: 5),
        const Radius.circular(1.5),
      ),
      Paint()..color = const Color(0xFF6D4C41),
    );
    for (final dx in [-24.0, 24.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(base.dx + dx, base.dy - 30), width: 10, height: 14),
        Paint()..color = const Color(0xFFFF7043).withValues(alpha: 0.9),
      );
    }
  }

  void _drawPlaque(Canvas canvas, Size size) {
    final cx = MoodJourneyLayout.finishDoorCenterX;
    final baseY = RoadGeometry.roadTop(size) - 8;
    const plaqueW = 56.0;
    const plaqueH = 17.0;
    final center = Offset(cx, baseY - 30);
    final sway = math.sin(time * math.pi * 2) * 0.032;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sway);
    canvas.translate(-center.dx, -center.dy);

    final boardTop = center.dy - plaqueH / 2;
    final ropeTop = baseY - 46;
    for (final dx in [-17.0, 17.0]) {
      canvas.drawLine(
        Offset(cx + dx * 0.35, ropeTop),
        Offset(center.dx + dx, boardTop - 0.5),
        Paint()
          ..color = const Color(0xFF4E342E)
          ..strokeWidth = 1.0,
      );
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: plaqueW, height: plaqueH),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFF5D4037), Color(0xFF3E2723)],
        ).createShader(rect.outerRect),
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = const Color(0xFFD4AF37),
    );

    final title = TextPainter(
      text: const TextSpan(
        text: '回响驿站',
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFF8E1),
          letterSpacing: 1.6,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    title.paint(canvas, Offset(center.dx - title.width / 2, center.dy - title.height / 2));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant FinishSegmentPainter old) => old.time != time;
}

class JourneyStartSegment extends StatelessWidget {
  const JourneyStartSegment({super.key, required this.time, this.isMonthView = false});

  final double time;
  final bool isMonthView;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MoodJourneyLayout.startSegmentWidth,
      height: MoodJourneyLayout.sceneHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: StartSegmentPainter(time: time)),
          Positioned(
            top: 10,
            left: 10,
            child: Text(
              isMonthView ? '这一月，从这里出发' : '这一段，从这里出发',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextSecondary.withValues(alpha: 0.92),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 8,
            child: Text(
              '启程 · 心情地图',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.95),
                shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodRoadSegment extends StatelessWidget {
  const MoodRoadSegment({
    super.key,
    required this.day,
    required this.time,
    required this.onTap,
    required this.showMoodLabel,
    required this.cornerLabel,
    this.segmentIndex = 0,
  });

  final EchoDayStat day;
  final double time;
  final VoidCallback? onTap;
  final bool showMoodLabel;
  final String cornerLabel;
  final int segmentIndex;

  @override
  Widget build(BuildContext context) {
    final mood = day.hasDiary ? WeatherMood.resolve(day.moodWeather) : null;
    final kind = MoodJourneyLayout.sceneryFor(day);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MoodJourneyLayout.segmentWidth,
        height: MoodJourneyLayout.sceneHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: RoadSegmentPainter(
                  day: day,
                  time: time,
                  roadOffsetX: segmentIndex * MoodJourneyLayout.segmentWidth,
                ),
              ),
            ),
            Positioned(
              left: 8,
              top: 6,
              child: showMoodLabel
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EchoColors.daySurface.withValues(alpha: 0.88),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: EchoColors.dayDivider.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        mood != null ? '${mood.emoji} ${mood.label}' : '未书写',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Positioned(
              right: 8,
              top: 6,
              child: Text(
                cornerLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: EchoColors.dayTextSecondary.withValues(alpha: 0.9),
                ),
              ),
            ),
            if (showMoodLabel)
              Positioned(
                left: 8,
                bottom: 6,
                right: 8,
                child: Text(
                  moodSceneryCaption(kind),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w300,
                    color: Colors.white.withValues(alpha: day.hasDiary ? 0.92 : 0.55),
                    shadows: const [Shadow(color: Colors.black26, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 终点驿站（Widget 文字 + 背景画）。
class JourneyFinishSegment extends StatelessWidget {
  const JourneyFinishSegment({
    super.key,
    required this.days,
    required this.time,
    this.isMonthView = false,
  });

  final List<EchoDayStat> days;
  final double time;
  final bool isMonthView;

  @override
  Widget build(BuildContext context) {
    final moods = <String>{};
    for (final d in days) {
      if (d.hasDiary) moods.add(WeatherMood.resolve(d.moodWeather).emoji);
    }
    final count = days.where((d) => d.hasDiary).length;

    return SizedBox(
      width: MoodJourneyLayout.finishSegmentWidth,
      height: MoodJourneyLayout.sceneHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(painter: FinishSegmentPainter(time: time)),
          Positioned(
            top: 10,
            right: 10,
            child: Text(
              isMonthView ? '这一月，已存档' : '这一段，已存档',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextSecondary.withValues(alpha: 0.9),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          if (moods.isNotEmpty)
            Positioned(
              top: 48,
              left: 0,
              right: 0,
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 4,
                children: moods.map((e) => Text(e, style: TextStyle(fontSize: 15))).toList(),
              ),
            ),
          Positioned(
            left: 12,
            bottom: 8,
            child: Text(
              '抵达 · $count 天回响已收录',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JourneyCyclistPainter extends CustomPainter {
  JourneyCyclistPainter({required this.phase, required this.riding});

  final double phase;
  final bool riding;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.68;

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy + 12), width: 40, height: 8),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );

    const r = 13.0;
    final rear = Offset(cx - 16, cy + 2);
    final front = Offset(cx + 16, cy + 2);
    _wheel(canvas, rear, r, phase);
    _wheel(canvas, front, r, phase);

    final frame = Paint()
      ..color = const Color(0xFF455A64)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(rear, front, frame);
    canvas.drawLine(rear, Offset(cx - 2, cy - 16), frame);
    canvas.drawLine(Offset(cx - 2, cy - 16), front, frame);

    final crank = phase * math.pi * 2;
    final hub = Offset(cx - 2, cy + 2);
    final pedal = Offset(hub.dx + math.cos(crank) * 7, hub.dy + math.sin(crank) * 7);
    canvas.drawLine(hub, pedal, frame);

    final head = Offset(cx, cy - 28);
    canvas.drawCircle(head.translate(0, -7), 6, Paint()..color = const Color(0xFFFFE0B2));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: head, width: 12, height: 18),
        const Radius.circular(5),
      ),
      Paint()..color = riding ? const Color(0xFF42A5F5) : const Color(0xFF66BB6A),
    );
  }

  void _wheel(Canvas canvas, Offset c, double r, double phase) {
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (var i = 0; i < 4; i++) {
      final a = phase * math.pi * 2 + i * math.pi / 2;
      canvas.drawLine(
        c,
        Offset(c.dx + math.cos(a) * r, c.dy + math.sin(a) * r),
        Paint()
          ..color = const Color(0xFF757575)
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant JourneyCyclistPainter old) =>
      old.phase != phase || old.riding != riding;
}
