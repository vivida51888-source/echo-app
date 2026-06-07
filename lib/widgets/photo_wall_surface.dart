import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/photo_wall_material.dart';
import '../theme/echo_colors.dart';

/// 照片墙背景：空白 / 软木 / 冰箱 / 四季自然景。
abstract final class PhotoWallSurfaceDecoration {
  static BorderRadius radius(bool compact) =>
      BorderRadius.circular(compact ? 10 : 14);

  static BoxDecoration box(
    PhotoWallMaterial material,
    bool compact, {
    String? customImagePath,
  }) {
    final radius = PhotoWallSurfaceDecoration.radius(compact);
    switch (material) {
      case PhotoWallMaterial.plain:
        return BoxDecoration(
          color: EchoColors.dayWriting.withValues(alpha: compact ? 0.45 : 0.55),
          borderRadius: radius,
          border: Border.all(
            color: EchoColors.dayDivider.withValues(alpha: 0.85),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(EchoColors.dayTextPrimary, 0.04),
        );
      case PhotoWallMaterial.cork:
        return BoxDecoration(
          color: const Color(0xFFEDE6DA),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_cork.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFFC4B49A).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF9A8870), 0.1),
        );
      case PhotoWallMaterial.fridge:
        return BoxDecoration(
          color: const Color(0xFFF5F0E8),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_fridge.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFFD8D0C4).withValues(alpha: 0.55),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF9A9088), 0.1),
        );
      case PhotoWallMaterial.travel:
        return BoxDecoration(
          color: const Color(0xFF0A0E18),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_travel.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFF3A4A6A).withValues(alpha: 0.45),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF050810), 0.2),
        );
      case PhotoWallMaterial.natureSpring:
        return BoxDecoration(
          color: const Color(0xFFE8F2EA),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_nature_spring.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFFB8C8B0).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF6A8870), 0.12),
        );
      case PhotoWallMaterial.natureSummer:
        return BoxDecoration(
          color: const Color(0xFFB8DCE8),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_nature_summer.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFF88B0C8).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF4A7088), 0.12),
        );
      case PhotoWallMaterial.natureAutumn:
        return BoxDecoration(
          color: const Color(0xFFE8C8A0),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_nature_autumn.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFFC89868).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF8A5838), 0.14),
        );
      case PhotoWallMaterial.natureWinter:
        return BoxDecoration(
          color: const Color(0xFFD4E2EE),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_nature_winter.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFF98A8B8).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: compact ? null : _softShadow(const Color(0xFF5A6A78), 0.14),
        );
      case PhotoWallMaterial.negative25:
        return BoxDecoration(
          color: const Color(0xFF1A1816),
          image: DecorationImage(
            image: const AssetImage('assets/images/photo_wall_negative25.png'),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withValues(alpha: compact ? 0.22 : 0.12),
              BlendMode.darken,
            ),
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFF4A443C).withValues(alpha: 0.55),
            width: 0.5,
          ),
          boxShadow: compact
              ? null
              : _softShadow(const Color(0xFF0A0908), 0.28),
        );
      case PhotoWallMaterial.filmWorkshop:
        return BoxDecoration(
          color: const Color(0xFF2A2218),
          image: const DecorationImage(
            image: AssetImage('assets/images/photo_wall_film_workshop.png'),
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          borderRadius: radius,
          border: Border.all(
            color: const Color(0xFF5A4A38).withValues(alpha: 0.5),
            width: 0.5,
          ),
          boxShadow: compact
              ? null
              : _softShadow(const Color(0xFF1A1410), 0.22),
        );
      case PhotoWallMaterial.custom:
        return _customBox(radius, compact, customImagePath);
    }
  }

  static BoxDecoration _customBox(
    BorderRadius radius,
    bool compact,
    String? customImagePath,
  ) {
    final hasImage = !kIsWeb &&
        customImagePath != null &&
        customImagePath.isNotEmpty &&
        File(customImagePath).existsSync();

    if (hasImage) {
      return BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.55),
          width: 0.5,
        ),
        boxShadow: compact ? null : _softShadow(EchoColors.dayTextPrimary, 0.06),
        image: DecorationImage(
          image: FileImage(File(customImagePath)),
          fit: BoxFit.cover,
        ),
      );
    }

    return BoxDecoration(
      color: EchoColors.dayWriting.withValues(alpha: compact ? 0.45 : 0.55),
      borderRadius: radius,
      border: Border.all(
        color: EchoColors.dayDivider.withValues(alpha: 0.85),
        width: 0.5,
      ),
    );
  }

  static List<BoxShadow>? _softShadow(Color color, double alpha) => [
        BoxShadow(
          color: color.withValues(alpha: alpha),
          blurRadius: 16,
          offset: const Offset(0, 5),
        ),
      ];

  static BoxDecoration _natureBox(
    BorderRadius radius,
    bool compact,
    List<Color> gradient,
    Color border,
  ) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: gradient,
        stops: const [0.0, 0.52, 1.0],
      ),
      borderRadius: radius,
      border: Border.all(color: border.withValues(alpha: 0.35), width: 0.6),
      boxShadow: compact ? null : _softShadow(border, 0.12),
    );
  }

  static CustomPainter? texturePainter(PhotoWallMaterial material) {
    if (material == PhotoWallMaterial.natureSpring ||
        material == PhotoWallMaterial.natureSummer ||
        material == PhotoWallMaterial.natureAutumn ||
        material == PhotoWallMaterial.natureWinter) {
      return null;
    }
    if (material.isNature) {
      return _NatureSceneryPainter(material);
    }
    return null;
  }
}

class PhotoWallSurface extends StatelessWidget {
  const PhotoWallSurface({
    super.key,
    required this.material,
    required this.compact,
    required this.child,
    this.customImagePath,
  });

  final PhotoWallMaterial material;
  final bool compact;
  final Widget child;
  final String? customImagePath;

  @override
  Widget build(BuildContext context) {
    final painter = PhotoWallSurfaceDecoration.texturePainter(material);
    final radius = PhotoWallSurfaceDecoration.radius(compact);

    return Container(
      width: double.infinity,
      decoration: PhotoWallSurfaceDecoration.box(
        material,
        compact,
        customImagePath: customImagePath,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            if (painter != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(painter: painter),
                ),
              ),
            child,
          ],
        ),
      ),
    );
  }
}

class _NatureSceneryPainter extends CustomPainter {
  const _NatureSceneryPainter(this.material);

  final PhotoWallMaterial material;

  @override
  void paint(Canvas canvas, Size size) {
    switch (material) {
      case PhotoWallMaterial.natureSpring:
        _paintSpring(canvas, size);
      case PhotoWallMaterial.natureSummer:
        _paintSummer(canvas, size);
      case PhotoWallMaterial.natureAutumn:
        _paintAutumn(canvas, size);
      case PhotoWallMaterial.natureWinter:
        _paintWinter(canvas, size);
      default:
        break;
    }
  }

  void _paintSpring(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 淡紫粉天光，区别于夏日的烈阳
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.55),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE8C0E0).withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.55)),
    );

    _drawClouds(canvas, w, h, 0.48, pinkTint: true);
    _drawHills(canvas, w, h, [
      (0.6, 0.1, const Color(0xFFB8D4B0), 3),
      (0.68, 0.08, const Color(0xFFA8C8A0), 7),
      (0.76, 0.07, const Color(0xFF98B890), 11),
    ]);
    _drawForeground(canvas, w, h, const Color(0xFF90B888).withValues(alpha: 0.28));
    _drawCherryTree(canvas, Offset(w * 0.1, h * 0.82), h * 0.2);
    _drawCherryTree(canvas, Offset(w * 0.88, h * 0.84), h * 0.16, mirror: true);
    _drawBlossoms(canvas, w, h, dense: true);
    _drawMist(canvas, w, h, 0.16);
    _drawWillow(canvas, Offset(w * 0.04, h * 0.72), h * 0.22);
  }

  void _paintSummer(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 晴野旷：晴光开阔的夏日野景
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h * 0.52),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF90C4E0).withValues(alpha: 0.24),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h * 0.52)),
    );

    _drawGlow(canvas, w, h, const Color(0xFFFFF0C8), 0.7, 0.11, 0.34);
    _drawGlow(canvas, w, h, const Color(0xFFE8F8FF), 0.28, 0.06, 0.18);

    _drawClouds(canvas, w, h, 0.4);
    _drawHills(canvas, w, h, [
      (0.6, 0.1, const Color(0xFF98C890), 3),
      (0.68, 0.08, const Color(0xFF88B878), 7),
      (0.76, 0.07, const Color(0xFF78A868), 11),
    ]);
    _drawForeground(
      canvas,
      w,
      h,
      const Color(0xFF78A868).withValues(alpha: 0.3),
    );
    _drawRoundTree(
      canvas,
      Offset(w * 0.08, h * 0.8),
      h * 0.14,
      const Color(0xFF68A058),
    );
    _drawRoundTree(
      canvas,
      Offset(w * 0.16, h * 0.84),
      h * 0.1,
      const Color(0xFF88B870),
    );
    _drawRoundTree(
      canvas,
      Offset(w * 0.9, h * 0.82),
      h * 0.12,
      const Color(0xFF70A860),
    );
    _drawWillow(canvas, Offset(w * 0.04, h * 0.72), h * 0.2);
    _drawSummerMotes(canvas, w, h);
  }

  void _paintAutumn(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawGlow(canvas, w, h, const Color(0xFFFFE8C8), 0.68, 0.16, 0.48);
    _drawClouds(canvas, w, h, 0.32);
    _drawHills(canvas, w, h, [
      (0.58, 0.13, const Color(0xFFC49060), 4),
      (0.67, 0.11, const Color(0xFFA87848), 8),
      (0.75, 0.09, const Color(0xFF8A6038), 12),
    ]);
    _drawForeground(canvas, w, h, const Color(0xFF7A5030).withValues(alpha: 0.35));
    _drawRoundTree(canvas, Offset(w * 0.08, h * 0.8), h * 0.14, const Color(0xFFD08040));
    _drawRoundTree(canvas, Offset(w * 0.16, h * 0.84), h * 0.1, const Color(0xFFB86830));
    _drawRoundTree(canvas, Offset(w * 0.9, h * 0.82), h * 0.12, const Color(0xFFC87838));
    _drawLeaves(canvas, w, h, warm: true);
  }

  void _paintWinter(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawClouds(canvas, w, h, 0.48);
    _drawHills(canvas, w, h, [
      (0.6, 0.12, const Color(0xFF9AAAB8), 5),
      (0.68, 0.1, const Color(0xFF8294A4), 9),
      (0.76, 0.08, const Color(0xFF6A7E90), 13),
    ], snowCaps: true);
    _drawForeground(canvas, w, h, const Color(0xFFE8EEF4).withValues(alpha: 0.55));
    _drawPine(canvas, Offset(w * 0.07, h * 0.78), h * 0.15, const Color(0xFF5A6878), snow: true);
    _drawPine(canvas, Offset(w * 0.91, h * 0.8), h * 0.13, const Color(0xFF5A6878), snow: true);
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.86, w, h * 0.14),
      Paint()..color = Colors.white.withValues(alpha: 0.22),
    );
  }

  void _drawGlow(
    Canvas canvas,
    double w,
    double h,
    Color color,
    double xFactor,
    double yFactor,
    double alpha,
  ) {
    canvas.drawCircle(
      Offset(w * xFactor, h * yFactor),
      w * 0.1,
      Paint()
        ..shader = RadialGradient(
          colors: [color.withValues(alpha: alpha), color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(
          center: Offset(w * xFactor, h * yFactor),
          radius: w * 0.1,
        )),
    );
  }

  void _drawClouds(
    Canvas canvas,
    double w,
    double h,
    double alpha, {
    bool pinkTint = false,
  }) {
    final base = pinkTint ? const Color(0xFFFFE8EE) : Colors.white;
    final cloud = Paint()..color = base.withValues(alpha: alpha);
    _drawCloud(canvas, cloud, Offset(w * 0.22, h * 0.14), w * 0.12);
    _drawCloud(canvas, cloud, Offset(w * 0.55, h * 0.1), w * 0.09);
    _drawCloud(
      canvas,
      cloud..color = base.withValues(alpha: alpha * 0.75),
      Offset(w * 0.72, h * 0.17),
      w * 0.08,
    );
  }

  void _drawHills(
    Canvas canvas,
    double w,
    double h,
    List<(double, double, Color, int)> layers, {
    bool snowCaps = false,
  }) {
    for (final layer in layers) {
      _drawHill(
        canvas,
        w,
        h,
        baseY: h * layer.$1,
        amplitude: h * layer.$2,
        color: layer.$3.withValues(alpha: 0.62),
        seed: layer.$4,
      );
      if (snowCaps) {
        _drawHill(
          canvas,
          w,
          h,
          baseY: h * (layer.$1 - 0.04),
          amplitude: h * layer.$2 * 0.45,
          color: Colors.white.withValues(alpha: 0.28),
          seed: layer.$4 + 100,
        );
      }
    }
  }

  void _drawForeground(Canvas canvas, double w, double h, Color color) {
    final foreground = Path()
      ..moveTo(0, h * 0.82)
      ..quadraticBezierTo(w * 0.35, h * 0.76, w * 0.62, h * 0.8)
      ..quadraticBezierTo(w * 0.88, h * 0.84, w, h * 0.78)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(foreground, Paint()..color = color);
  }

  void _drawMist(Canvas canvas, double w, double h, double alpha) {
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.45, w, h * 0.2),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: alpha),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, h * 0.45, w, h * 0.2)),
    );
  }

  void _drawBlossoms(Canvas canvas, double w, double h, {bool dense = false}) {
    final random = Random(23);
    final count = dense ? 28 : 18;
    final petal = Paint();
    for (var i = 0; i < count; i++) {
      petal.color = Color.lerp(
        const Color(0xFFFF9CB8),
        const Color(0xFFFFF0F5),
        random.nextDouble(),
      )!
          .withValues(alpha: random.nextDouble() * 0.4 + 0.18);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * w,
          h * 0.42 + random.nextDouble() * h * 0.48,
        ),
        random.nextDouble() * 2.6 + 0.8,
        petal,
      );
    }
  }

  void _drawCherryTree(
    Canvas canvas,
    Offset base,
    double height, {
    bool mirror = false,
  }) {
    final branch = Paint()
      ..color = const Color(0xFF6A5048).withValues(alpha: 0.45)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final dir = mirror ? -1.0 : 1.0;
    canvas.drawLine(base, base + Offset(-18 * dir, -height * 0.35), branch);
    canvas.drawLine(
      base + Offset(-8 * dir, -height * 0.2),
      base + Offset(22 * dir, -height * 0.42),
      branch,
    );
    canvas.drawLine(
      base + Offset(4 * dir, -height * 0.12),
      base + Offset(-14 * dir, -height * 0.38),
      branch,
    );

    final random = Random(mirror ? 41 : 29);
    for (var i = 0; i < 14; i++) {
      final cx = base.dx + (random.nextDouble() - 0.5) * height * 0.55;
      final cy = base.dy - height * (0.18 + random.nextDouble() * 0.38);
      canvas.drawCircle(
        Offset(cx, cy),
        random.nextDouble() * 5 + 3,
        Paint()
          ..color = Color.lerp(
            const Color(0xFFFFB0C8),
            const Color(0xFFFFE0EC),
            random.nextDouble(),
          )!
              .withValues(alpha: 0.75),
      );
    }
  }

  void _drawWillow(Canvas canvas, Offset top, double length) {
    final strand = Paint()
      ..color = const Color(0xFF88A878).withValues(alpha: 0.42)
      ..strokeWidth = 0.8;
    for (var i = 0; i < 7; i++) {
      final start = top + Offset(i * 4.0, 0);
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(
          start.dx + 6,
          start.dy + length * 0.5,
          start.dx - 2,
          start.dy + length,
        );
      canvas.drawPath(path, strand);
    }
  }

  void _drawSummerMotes(Canvas canvas, double w, double h) {
    final random = Random(52);
    final mote = Paint();
    for (var i = 0; i < 14; i++) {
      mote.color = Color.lerp(
        const Color(0xFFFFF8E0),
        const Color(0xFFD8F0C0),
        random.nextDouble(),
      )!
          .withValues(alpha: random.nextDouble() * 0.32 + 0.1);
      canvas.drawCircle(
        Offset(
          random.nextDouble() * w,
          h * 0.4 + random.nextDouble() * h * 0.42,
        ),
        random.nextDouble() * 2.0 + 0.6,
        mote,
      );
    }
  }

  void _drawLeaves(Canvas canvas, double w, double h, {required bool warm}) {
    final random = Random(37);
    final leaf = Paint();
    for (var i = 0; i < 14; i++) {
      leaf.color = Color.lerp(
        const Color(0xFFD87830),
        const Color(0xFFE8A848),
        random.nextDouble(),
      )!
          .withValues(alpha: random.nextDouble() * 0.4 + 0.2);
      canvas.drawCircle(
        Offset(random.nextDouble() * w, h * 0.5 + random.nextDouble() * h * 0.4),
        random.nextDouble() * 1.8 + 0.6,
        leaf,
      );
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, Offset center, double radius) {
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(
      center + Offset(radius * 0.7, radius * 0.15),
      radius * 0.72,
      paint,
    );
    canvas.drawCircle(
      center + Offset(-radius * 0.65, radius * 0.2),
      radius * 0.58,
      paint,
    );
  }

  void _drawHill(
    Canvas canvas,
    double w,
    double h, {
    required double baseY,
    required double amplitude,
    required Color color,
    required int seed,
  }) {
    final random = Random(seed);
    final path = Path()..moveTo(0, h);
    const segments = 6;
    for (var i = 0; i <= segments; i++) {
      final x = w * i / segments;
      final y = baseY + (random.nextDouble() - 0.5) * amplitude;
      if (i == 0) {
        path.lineTo(0, y);
      } else {
        final prevX = w * (i - 1) / segments;
        final cpX = (prevX + x) / 2;
        path.quadraticBezierTo(cpX, y - amplitude * 0.25, x, y);
      }
    }
    path.lineTo(w, h);
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  void _drawPine(
    Canvas canvas,
    Offset base,
    double height,
    Color foliageColor, {
    bool snow = false,
  }) {
    final trunk = Paint()
      ..color = (snow ? const Color(0xFF6A7480) : const Color(0xFF4E5F48))
          .withValues(alpha: 0.55);
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, height * 0.18),
        width: height * 0.08,
        height: height * 0.36,
      ),
      trunk,
    );
    final foliage = Paint()..color = foliageColor.withValues(alpha: 0.62);
    for (var i = 0; i < 3; i++) {
      final top = base.dy - height * (0.18 + i * 0.22);
      final width = height * (0.42 - i * 0.08);
      final path = Path()
        ..moveTo(base.dx, top)
        ..lineTo(base.dx - width / 2, top + height * 0.24)
        ..lineTo(base.dx + width / 2, top + height * 0.24)
        ..close();
      canvas.drawPath(path, foliage);
      if (snow) {
        canvas.drawPath(
          path,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.35)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }
  }

  void _drawRoundTree(Canvas canvas, Offset base, double height, Color color) {
    canvas.drawRect(
      Rect.fromCenter(
        center: base + Offset(0, height * 0.12),
        width: height * 0.1,
        height: height * 0.28,
      ),
      Paint()..color = const Color(0xFF6A5040).withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      base + Offset(0, -height * 0.18),
      height * 0.22,
      Paint()..color = color.withValues(alpha: 0.68),
    );
    canvas.drawCircle(
      base + Offset(-height * 0.14, -height * 0.08),
      height * 0.16,
      Paint()..color = color.withValues(alpha: 0.55),
    );
    canvas.drawCircle(
      base + Offset(height * 0.14, -height * 0.06),
      height * 0.15,
      Paint()..color = color.withValues(alpha: 0.5),
    );
  }

  @override
  bool shouldRepaint(covariant _NatureSceneryPainter oldDelegate) =>
      oldDelegate.material != material;
}

/// 照片固定方式：图钉 / 磁贴 / 木夹 / 胶带。
class PhotoWallAttachWidget extends StatelessWidget {
  const PhotoWallAttachWidget({
    super.key,
    required this.material,
    required this.width,
  });

  final PhotoWallMaterial material;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (material.usesPin) {
      return Positioned(
        top: -5,
        left: width * 0.38,
        child: Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: material == PhotoWallMaterial.cork
                ? const Color(0xFFB85C4A)
                : EchoColors.dayDivider.withValues(alpha: 0.82),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.55),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(alpha: 0.18),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }
    if (material.usesMagnet) {
      return Positioned(
        top: -3,
        left: width * 0.34,
        child: Container(
          width: 18,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF6E8498),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(alpha: 0.15),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }
    if (material.usesClip) {
      return Positioned(
        top: -3,
        left: width * 0.34,
        child: SizedBox(
          width: 16,
          height: 12,
          child: CustomPaint(
            painter: _WoodenClipPainter(),
          ),
        ),
      );
    }
    return Positioned(
      top: -4,
      left: width * 0.36,
      child: Transform.rotate(
        angle: -0.08,
        child: Container(
          width: 16,
          height: 7,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(1),
            border: Border.all(
              color: EchoColors.dayDivider.withValues(alpha: 0.55),
              width: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

class _WoodenClipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.18,
        size.height * 0.35,
        size.width * 0.64,
        size.height * 0.42,
      ),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFFC49A6C));
    final spring = Paint()
      ..color = const Color(0xFF8A8F94)
      ..strokeWidth = 1.2;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.42),
        width: size.width * 0.34,
        height: size.height * 0.34,
      ),
      3.4,
      2.4,
      false,
      spring,
    );
    canvas.drawLine(
      Offset(size.width * 0.22, size.height * 0.18),
      Offset(size.width * 0.38, size.height * 0.52),
      Paint()
        ..color = const Color(0xFFD4B088)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(size.width * 0.78, size.height * 0.18),
      Offset(size.width * 0.62, size.height * 0.52),
      Paint()
        ..color = const Color(0xFFB8895A)
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
