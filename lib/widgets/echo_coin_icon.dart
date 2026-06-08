import 'package:flutter/material.dart';

/// 回响币统一图标：金色圆币 + 涟漪纹。
class EchoCoinIcon extends StatelessWidget {
  const EchoCoinIcon({
    super.key,
    this.size = 18,
    this.color = const Color(0xFFC99A3A),
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _EchoCoinPainter(color: color),
      ),
    );
  }
}

class _EchoCoinPainter extends CustomPainter {
  _EchoCoinPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final fill = Paint()
      ..shader = RadialGradient(
        colors: [
          Color.lerp(color, Colors.white, 0.35)!,
          color,
          Color.lerp(color, Colors.black, 0.18)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, fill);

    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..color = Color.lerp(color, Colors.black, 0.25)!;
    canvas.drawCircle(center, radius * 0.92, rim);

    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.055
      ..color = Color.lerp(color, Colors.white, 0.45)!.withValues(alpha: 0.9);

    canvas.drawCircle(center, radius * 0.42, ripple);
    canvas.drawCircle(center, radius * 0.62, ripple);

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.05
      ..strokeCap = StrokeCap.round
      ..color = Color.lerp(color, Colors.white, 0.55)!;

    final arcRect = Rect.fromCircle(center: center, radius: radius * 0.28);
    canvas.drawArc(arcRect, 0.6, 2.0, false, arcPaint);
    canvas.drawArc(arcRect, 3.8, 2.0, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _EchoCoinPainter oldDelegate) =>
      oldDelegate.color != color;
}
