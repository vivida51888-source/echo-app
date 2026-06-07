import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 礼花筒 · 紧凑尺寸，纸屑高抛。
class FinishConfettiPopper extends StatelessWidget {
  const FinishConfettiPopper({super.key, required this.progress});

  final double progress;

  static const canvasW = 84.0;
  static const canvasH = 108.0;
  static const mouth = Offset(24, 66);

  static const _colors = [
    Color(0xFFE53935),
    Color(0xFFFFB300),
    Color(0xFF1E88E5),
    Color(0xFFEC407A),
    Color(0xFF43A047),
    Color(0xFF8E24AA),
  ];

  static final _particles = _buildParticles();

  static List<_Particle> _buildParticles() {
    final rnd = math.Random(11);
    return List.generate(34, (i) {
      return _Particle(
        angle: -math.pi * 0.92 + rnd.nextDouble() * math.pi * 0.62,
        speed: 38 + rnd.nextDouble() * 58,
        color: _colors[i % _colors.length],
        size: 2.5 + rnd.nextDouble() * 2.8,
        spin: rnd.nextDouble() * math.pi * 2,
        delay: rnd.nextDouble() * 0.12,
        round: rnd.nextDouble() > 0.5,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final burst = ((progress - 0.05) / 0.95).clamp(0.0, 1.0);
    final kick = progress > 0 && progress < 0.2
        ? math.sin(progress / 0.2 * math.pi) * 0.1
        : 0.0;

    return SizedBox(
      width: canvasW,
      height: canvasH,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final p in _particles)
            if (burst > p.delay)
              _ConfettiPieceWidget(
                particle: p,
                t: ((burst - p.delay) / (1 - p.delay)).clamp(0.0, 1.0),
              ),
          Positioned(
            right: 4,
            bottom: 0,
            child: Transform.rotate(
              angle: -0.68 + kick,
              alignment: Alignment.bottomCenter,
              child: _PopperTube(flare: (progress / 0.22).clamp(0.0, 1.0)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Particle {
  const _Particle({
    required this.angle,
    required this.speed,
    required this.color,
    required this.size,
    required this.spin,
    required this.delay,
    required this.round,
  });

  final double angle;
  final double speed;
  final Color color;
  final double size;
  final double spin;
  final double delay;
  final bool round;
}

class _ConfettiPieceWidget extends StatelessWidget {
  const _ConfettiPieceWidget({required this.particle, required this.t});

  final _Particle particle;
  final double t;

  @override
  Widget build(BuildContext context) {
    final fly = Curves.easeOut.transform(t);
    final dist = particle.speed * fly;
    const mouth = FinishConfettiPopper.mouth;
    final x = mouth.dx + math.cos(particle.angle) * dist;
    final y = mouth.dy + math.sin(particle.angle) * dist * 1.05 + t * t * 14;
    final alpha = (1 - t * 0.42).clamp(0.0, 1.0);

    return Positioned(
      left: x,
      top: y,
      child: Transform.rotate(
        angle: particle.spin + t * math.pi * 3,
        child: Opacity(
          opacity: alpha,
          child: particle.round
              ? Container(
                  width: particle.size,
                  height: particle.size,
                  decoration: BoxDecoration(
                    color: particle.color,
                    shape: BoxShape.circle,
                  ),
                )
              : Container(
                  width: particle.size,
                  height: particle.size * 0.42,
                  decoration: BoxDecoration(
                    color: particle.color,
                    borderRadius: BorderRadius.circular(0.8),
                  ),
                ),
        ),
      ),
    );
  }
}

class _PopperTube extends StatelessWidget {
  const _PopperTube({required this.flare});

  final double flare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 42,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 5,
            child: Column(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8D6E63),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF6D4C41),
                      width: 0.5,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 5,
                  color: const Color(0xFF795548),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            child: Container(
              width: 12,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(1.5),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFE8C547),
                    Color(0xFFD4AF37),
                    Color(0xFFC9A030),
                    Color(0xFFD4AF37),
                  ],
                  stops: [0.0, 0.35, 0.65, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 1.5,
                    offset: Offset(0.5, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  2,
                  (_) => Container(
                    height: 0.8,
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    color: const Color(0xFFB8960C).withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 36,
            child: _CrimpedTop(flare: flare),
          ),
        ],
      ),
    );
  }
}

class _CrimpedTop extends StatelessWidget {
  const _CrimpedTop({required this.flare});

  final double flare;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 13,
      height: 8 + flare * 5,
      child: CustomPaint(
        painter: _CrimpPainter(flare: flare),
      ),
    );
  }
}

class _CrimpPainter extends CustomPainter {
  _CrimpPainter({required this.flare});

  final double flare;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()..moveTo(0, h);
    for (var i = 0; i <= 6; i++) {
      final x = w * i / 6;
      final y = i.isEven ? h * 0.15 : h * 0.55;
      path.lineTo(x, y);
    }
    path.lineTo(w, h);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFFF8E1),
            const Color(0xFFFFECB3).withValues(alpha: 0.9),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    if (flare > 0) {
      for (var i = 0; i < 4; i++) {
        final x = w * (0.2 + i * 0.18);
        canvas.drawLine(
          Offset(x, h * 0.2),
          Offset(x + (i - 1.5) * 2 * flare, -4 * flare),
          Paint()
            ..color = const Color(0xFFFFF59D).withValues(alpha: 0.75)
            ..strokeWidth = 0.8
            ..strokeCap = StrokeCap.round,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _CrimpPainter oldDelegate) =>
      oldDelegate.flare != flare;
}
