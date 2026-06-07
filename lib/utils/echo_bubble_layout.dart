import 'dart:math' as math;
import 'dart:ui';

import '../models/echo_tree_growth.dart';
import '../models/echo_water_bubble.dart';

/// 雨露泡在树旁区域的随机落点（稳定、不重叠、可复现）。
abstract final class EchoBubbleLayout {
  static const minDist = 0.12;

  /// 为新泡挑选锚点（0–1 相对坐标，持久化后位置不变）。
  static BubbleAnchor pickAnchor({
    required int seed,
    required List<EchoWaterBubble> existing,
  }) {
    final occupied = existing.map((b) => b.anchor).toList();
    for (var attempt = 0; attempt < 20; attempt++) {
      final anchor = anchorFromSeed(seed, attempt);
      if (_isFarEnough(anchor, occupied)) return anchor;
    }
    final n = existing.length;
    final angle = -math.pi * 0.75 + n * 0.55;
    const r = 0.38;
    return BubbleAnchor(
      (0.5 + math.cos(angle) * r).clamp(0.1, 0.9),
      (0.42 + math.sin(angle) * r * 0.72).clamp(0.08, 0.78),
    );
  }

  static BubbleAnchor anchorFromSeed(int seed, [int attempt = 0]) {
    final s = seed.abs() + attempt * 1597;
    final angle = ((s % 628) / 100.0) - 0.4;
    final radius = 0.2 + (s % 41) / 100.0;
    final x = (0.5 + math.cos(angle) * radius).clamp(0.1, 0.9);
    final y = (0.44 + math.sin(angle) * radius * 0.78).clamp(0.06, 0.8);
    return BubbleAnchor(x, y);
  }

  static bool _isFarEnough(BubbleAnchor candidate, List<BubbleAnchor> occupied) {
    for (final o in occupied) {
      if (candidate.distanceTo(o) < minDist) return false;
    }
    return true;
  }

  static Offset toPixel(BubbleAnchor anchor, Size area) {
    const padH = 36.0;
    const padV = 32.0;
    return Offset(
      padH + anchor.x * (area.width - padH * 2),
      padV + anchor.y * (area.height - padV * 2),
    );
  }
}

/// 雨露泡视觉尺寸：整体更小，克数越高越大。
abstract final class EchoBubbleMetrics {
  static const minGrams = 3;
  static const maxGrams = 55;
  static const minDiameter = 34.0;
  static const maxDiameter = 50.0;

  static double diameterFor(int grams) {
    final t = ((grams - minGrams) / (maxGrams - minGrams)).clamp(0.0, 1.0);
    return minDiameter + (maxDiameter - minDiameter) * t;
  }

  static double hitAreaFor(int grams) => diameterFor(grams) + 12;

  static double gramsFontSize(int grams) {
    final t = ((grams - minGrams) / (maxGrams - minGrams)).clamp(0.0, 1.0);
    return 10.5 + t * 2.5;
  }
}

class BubbleAnchor {
  const BubbleAnchor(this.x, this.y);

  final double x;
  final double y;

  double distanceTo(BubbleAnchor other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }
}
