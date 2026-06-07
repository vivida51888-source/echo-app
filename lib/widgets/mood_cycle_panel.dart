import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/weather_mood.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_typography.dart';
import 'echo_charm.dart';
import 'echo_empty_state.dart';

/// 「阴晴圆缺」— 五种天象心情的圆环与横条统计。
class MoodCyclePanel extends StatelessWidget {
  const MoodCyclePanel({super.key, required this.stats});

  final EchoPeriodStatistics stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasMoodActivity) {
      return const _EmptyStatCard(
        charm: EchoCharmKind.cloud,
        message: '这一段还没有标记心情\n写回响时选一种天气，阴晴圆缺会慢慢显形',
      );
    }

    final slots = stats.allMoodSlots;
    final total = stats.totalMoodDays;
    final span = stats.isWeekly ? '本周' : '本月';
    final dominant = stats.dominantMood;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: MoodCycleRingPainter(
                    moods: slots,
                    total: total,
                    strokeWidth: 5,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$total',
                      style: EchoTypography.displayMedium.copyWith(
                        fontSize: 26,
                        color: EchoColors.dayTextPrimary,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '天',
                      style: EchoTypography.caption.copyWith(
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          dominant != null
              ? '$span · 主调 ${dominant.emoji} ${dominant.label}'
              : '$span · 已标记 $total 天',
          textAlign: TextAlign.center,
          style: EchoTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextSecondary,
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '五种天象',
            style: EchoTypography.caption.copyWith(
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextWhisper,
              letterSpacing: 0.3,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...slots.map((m) => MoodDayBar(mood: m, total: total)),
      ],
    );
  }
}

class MoodDayBar extends StatelessWidget {
  const MoodDayBar({
    super.key,
    required this.mood,
    required this.total,
  });

  final EchoMoodStat mood;
  final int total;

  @override
  Widget build(BuildContext context) {
    final color = WeatherMood.chartColorFor(mood.display);
    final share = total > 0 ? mood.count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(mood.emoji, style: TextStyle(fontSize: 15)),
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            child: Text(
              mood.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextSecondary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final fillW = constraints.maxWidth * share;
                return Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    if (fillW > 0)
                      Container(
                        width: fillW,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '${mood.count} 天',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MoodCycleRingPainter extends CustomPainter {
  const MoodCycleRingPainter({
    required this.moods,
    required this.total,
    required this.strokeWidth,
  });

  final List<EchoMoodStat> moods;
  final int total;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = EchoColors.dayDivider.withValues(alpha: 0.45),
    );

    if (total <= 0) return;

    final active = moods.where((m) => m.count > 0).toList();
    if (active.isEmpty) return;

    const gap = 0.05;
    var start = -math.pi / 2;

    for (var i = 0; i < active.length; i++) {
      final mood = active[i];
      final share = mood.count / total;
      var sweep = share * math.pi * 2;
      if (active.length > 1) {
        sweep = (sweep - gap).clamp(0.0, math.pi * 2);
      }
      if (sweep <= 0) continue;

      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round
          ..color = WeatherMood.chartColorFor(mood.display).withValues(alpha: 0.85),
      );
      start += sweep + (active.length > 1 ? gap : 0);
    }
  }

  @override
  bool shouldRepaint(covariant MoodCycleRingPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.moods != moods;
  }
}

class _EmptyStatCard extends StatelessWidget {
  const _EmptyStatCard({
    required this.charm,
    required this.message,
  });

  final EchoCharmKind charm;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: EchoColors.daySurface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
      ),
      child: EchoEmptyState(
        charm: charm,
        message: message,
        compact: true,
      ),
    );
  }
}
