import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';

/// Echo 小插画：手绘感、低饱和，用于空状态与轻点缀。
enum EchoCharmKind {
  sprout,
  envelope,
  polaroid,
  imprint,
  diary,
  cloud,
  milestone,
  wallCalendar,
}

enum EchoCharmTone { day, night }

class EchoCharm extends StatefulWidget {
  const EchoCharm({
    super.key,
    required this.kind,
    this.size = 88,
    this.tone = EchoCharmTone.day,
    this.animate = true,
  });

  final EchoCharmKind kind;
  final double size;
  final EchoCharmTone tone;
  final bool animate;

  @override
  State<EchoCharm> createState() => _EchoCharmState();
}

class _EchoCharmState extends State<EchoCharm>
    with SingleTickerProviderStateMixin {
  AnimationController? _float;

  @override
  void initState() {
    super.initState();
    if (widget.animate) {
      _float = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2800),
      )..repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _float?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget charm = CustomPaint(
      size: Size.square(widget.size),
      painter: _EchoCharmPainter(
        kind: widget.kind,
        tone: widget.tone,
      ),
    );

    if (_float != null) {
      charm = AnimatedBuilder(
        animation: _float!,
        builder: (context, child) {
          final t = CurvedAnimation(
            parent: _float!,
            curve: Curves.easeInOut,
          ).value;
          return Transform.translate(
            offset: Offset(0, -3 * t),
            child: child,
          );
        },
        child: charm,
      );
    }

    return charm;
  }
}

class _EchoCharmPainter extends CustomPainter {
  const _EchoCharmPainter({
    required this.kind,
    required this.tone,
  });

  final EchoCharmKind kind;
  final EchoCharmTone tone;

  bool get _night => tone == EchoCharmTone.night;

  Color _c(Color day, [Color? night, double alpha = 1]) {
    final base = _night ? (night ?? day) : day;
    return base.withValues(alpha: alpha);
  }

  @override
  void paint(Canvas canvas, Size size) {
    switch (kind) {
      case EchoCharmKind.sprout:
        _paintSprout(canvas, size);
      case EchoCharmKind.envelope:
        _paintEnvelope(canvas, size);
      case EchoCharmKind.polaroid:
        _paintPolaroid(canvas, size);
      case EchoCharmKind.imprint:
        _paintImprint(canvas, size);
      case EchoCharmKind.diary:
        _paintDiary(canvas, size);
      case EchoCharmKind.cloud:
        _paintCloud(canvas, size);
      case EchoCharmKind.milestone:
        _paintMilestone(canvas, size);
      case EchoCharmKind.wallCalendar:
        _paintWallCalendar(canvas, size);
    }
  }

  void _paintSprout(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final pot = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.78),
        width: w * 0.42,
        height: h * 0.18,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      pot,
      Paint()..color = _c(const Color(0xFFC4A882), const Color(0xFF9A8878)),
    );
    canvas.drawRRect(
      pot,
      Paint()
        ..color = _c(const Color(0xFF8B6840), const Color(0xFF6A5A48), 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final stem = Paint()
      ..color = _c(const Color(0xFF6A9A62), const Color(0xFF5A8060))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.5, h * 0.68),
      Offset(w * 0.5, h * 0.42),
      stem,
    );

    final leaf = Paint()
      ..color = _c(const Color(0xFF8CB878), const Color(0xFF7AA080));
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.38, h * 0.5),
        width: w * 0.22,
        height: h * 0.12,
      ),
      leaf,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.62, h * 0.46),
        width: w * 0.2,
        height: h * 0.11,
      ),
      leaf,
    );

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.38),
      w * 0.07,
      Paint()..color = _c(const Color(0xFFA8D898), const Color(0xFF90B898)),
    );
  }

  void _paintEnvelope(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.18, h * 0.32, w * 0.64, h * 0.42),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(
      body,
      Paint()..color = _c(const Color(0xFFF3EFE6), const Color(0xFFE4E0D8)),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = _c(EchoColors.dayDivider, const Color(0xFFD5D0C8), 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    final flap = Path()
      ..moveTo(w * 0.18, h * 0.32)
      ..lineTo(w * 0.5, h * 0.5)
      ..lineTo(w * 0.82, h * 0.32);
    canvas.drawPath(
      flap,
      Paint()
        ..color = _c(const Color(0xFFE8E2D8), const Color(0xFFD8D2C8))
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      flap,
      Paint()
        ..color = _c(EchoColors.dayDivider, const Color(0xFFD5D0C8), 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    canvas.drawCircle(
      Offset(w * 0.5, h * 0.38),
      w * 0.055,
      Paint()..color = _c(const Color(0xFFE8A0A8), const Color(0xFFD89098)),
    );
  }

  void _paintPolaroid(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void card(double left, double top, double rot, double alpha) {
      canvas.save();
      canvas.translate(left + w * 0.18, top + h * 0.22);
      canvas.rotate(rot);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.36, height: h * 0.34),
        const Radius.circular(2),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = _c(EchoColors.daySurface, const Color(0xFFEEEBE4), alpha),
      );
      canvas.drawRRect(
        rect,
        Paint()
          ..color = _c(EchoColors.dayDivider, const Color(0xFFD5D0C8), alpha * 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(0, -h * 0.03),
          width: w * 0.28,
          height: h * 0.18,
        ),
        Paint()
          ..color = _c(const Color(0xFFD8D4CC), const Color(0xFFC8C4BC), alpha * 0.7),
      );
      canvas.restore();
    }

    card(w * 0.08, h * 0.18, -0.12, 0.85);
    card(w * 0.28, h * 0.08, 0.08, 1);
    card(w * 0.48, h * 0.2, 0.14, 0.9);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.62, h * 0.14),
          width: w * 0.12,
          height: h * 0.05,
        ),
        const Radius.circular(1),
      ),
      Paint()..color = _c(const Color(0xFFE8E2D8), const Color(0xFFD8D2C8), 0.8),
    );
  }

  void _paintImprint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final card = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.52),
        width: w * 0.52,
        height: h * 0.48,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      card,
      Paint()..color = _c(const Color(0xFFE8F0E8), const Color(0xFFD8E4DC)),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..color = _c(const Color(0xFF9AB898), const Color(0xFF8AA890), 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    for (var row = 0; row < 3; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(w * (0.34 + col * 0.12), h * (0.4 + row * 0.1)),
          w * 0.018,
          Paint()
            ..color = _c(const Color(0xFF9AB898), const Color(0xFF8AA890), 0.35),
        );
      }
    }

    final heart = Path()
      ..moveTo(w * 0.5, h * 0.66)
      ..cubicTo(
        w * 0.42, h * 0.58,
        w * 0.34, h * 0.64,
        w * 0.5, h * 0.74,
      )
      ..cubicTo(
        w * 0.66, h * 0.64,
        w * 0.58, h * 0.58,
        w * 0.5, h * 0.66,
      );
    canvas.drawPath(
      heart,
      Paint()..color = _c(const Color(0xFFE8A0A8), const Color(0xFFD89098)),
    );
  }

  void _paintDiary(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cover = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.54),
        width: w * 0.46,
        height: h * 0.5,
      ),
      Radius.circular(w * 0.025),
    );
    canvas.drawRRect(
      cover,
      Paint()..color = _c(const Color(0xFFD4C4A8), const Color(0xFFC4B498)),
    );
    canvas.drawRRect(
      cover,
      Paint()
        ..color = _c(const Color(0xFF9A8468), const Color(0xFF8A7860), 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.27, h * 0.34, w * 0.4, h * 0.36),
        const Radius.circular(1),
      ),
      Paint()..color = _c(EchoColors.daySurface, const Color(0xFFEEEBE4), 0.92),
    );

    final line = Paint()
      ..color = _c(EchoColors.dayDivider, const Color(0xFFD5D0C8), 0.8)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 4; i++) {
      final y = h * (0.42 + i * 0.07);
      canvas.drawLine(Offset(w * 0.32, y), Offset(w * 0.62, y), line);
    }

    canvas.drawCircle(
      Offset(w * 0.34, h * 0.38),
      w * 0.018,
      Paint()..color = _c(const Color(0xFFE8A878), const Color(0xFFD89868)),
    );
  }

  void _paintCloud(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cloud = Paint()
      ..color = _c(const Color(0xFFE8EEF5), const Color(0xFFD8DEE8));

    canvas.drawCircle(Offset(w * 0.35, h * 0.48), w * 0.14, cloud);
    canvas.drawCircle(Offset(w * 0.52, h * 0.42), w * 0.17, cloud);
    canvas.drawCircle(Offset(w * 0.68, h * 0.48), w * 0.13, cloud);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.52, h * 0.54),
          width: w * 0.46,
          height: h * 0.16,
        ),
        Radius.circular(w * 0.08),
      ),
      cloud,
    );

    canvas.drawCircle(
      Offset(w * 0.44, h * 0.5),
      w * 0.012,
      Paint()..color = _c(EchoColors.dayTextWhisper, EchoColors.nightTextWhisper),
    );
    canvas.drawCircle(
      Offset(w * 0.58, h * 0.5),
      w * 0.012,
      Paint()..color = _c(EchoColors.dayTextWhisper, EchoColors.nightTextWhisper),
    );

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w * 0.51, h * 0.56),
        width: w * 0.06,
        height: h * 0.03,
      ),
      0.1,
      math.pi - 0.2,
      false,
      Paint()
        ..color = _c(const Color(0xFFE8A0A8), const Color(0xFFD89098), 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintMilestone(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final line = Paint()
      ..color = _c(const Color(0xFF9AB898), const Color(0xFF8AA890), 0.45)
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.1, h * 0.74), Offset(w * 0.9, h * 0.74), line);

    final post = Paint()
      ..color = _c(const Color(0xFF8AA890), const Color(0xFF7A9880))
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.74), Offset(w * 0.5, h * 0.4), post);

    final stone = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.28),
        width: w * 0.3,
        height: h * 0.2,
      ),
      Radius.circular(w * 0.05),
    );
    canvas.drawRRect(
      stone,
      Paint()..color = _c(const Color(0xFFE6EFE8), const Color(0xFFD8E4DC)),
    );
    canvas.drawRRect(
      stone,
      Paint()
        ..color = _c(const Color(0xFF9AB898), const Color(0xFF8AA890), 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    canvas.drawLine(
      Offset(w * 0.42, h * 0.28),
      Offset(w * 0.58, h * 0.28),
      Paint()
        ..color = _c(const Color(0xFF9AB898), const Color(0xFF8AA890), 0.65)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
  }

  void _paintWallCalendar(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ring = Paint()
      ..color = _c(const Color(0xFFB8C0CC), const Color(0xFFA8B0BC), 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawCircle(Offset(w * 0.38, h * 0.22), w * 0.028, ring);
    canvas.drawCircle(Offset(w * 0.62, h * 0.22), w * 0.028, ring);

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.26, h * 0.28, w * 0.48, h * 0.54),
      Radius.circular(w * 0.03),
    );
    canvas.drawRRect(
      body,
      Paint()..color = _c(EchoColors.daySurface, const Color(0xFFEEEBE4)),
    );
    canvas.drawRRect(
      body,
      Paint()
        ..color = _c(EchoColors.dayDivider, const Color(0xFFD5D0C8), 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.9,
    );

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(w * 0.26, h * 0.28, w * 0.48, h * 0.12),
        topLeft: Radius.circular(w * 0.03),
        topRight: Radius.circular(w * 0.03),
      ),
      Paint()..color = _c(const Color(0xFFD8E2EE), const Color(0xFFC8D2DE)),
    );

    final dot = Paint()
      ..color = _c(EchoColors.dayDivider, const Color(0xFFD5D0C8), 0.75);
    for (var row = 0; row < 2; row++) {
      for (var col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(w * (0.34 + col * 0.12), h * (0.5 + row * 0.1)),
          w * 0.016,
          dot,
        );
      }
    }

    canvas.drawCircle(
      Offset(w * 0.58, h * 0.6),
      w * 0.028,
      Paint()
        ..color = _c(const Color(0xFFE8A0A8), const Color(0xFFD89098), 0.35),
    );
    canvas.drawCircle(
      Offset(w * 0.58, h * 0.6),
      w * 0.028,
      Paint()
        ..color = _c(const Color(0xFFE8A0A8), const Color(0xFFD89098), 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  @override
  bool shouldRepaint(covariant _EchoCharmPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.tone != tone;
}
