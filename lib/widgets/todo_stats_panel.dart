import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_typography.dart';
import 'echo_charm.dart';
import 'echo_empty_state.dart';

/// 待办总览徽章（按总完成率划分）。
class TodoOverviewBadge {
  const TodoOverviewBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  static TodoOverviewBadge? forStats(EchoPeriodStatistics stats) {
    if (!stats.hasTodoActivity) return null;

    final span = stats.todoSpanLabel.isNotEmpty
        ? stats.todoSpanLabel
        : (stats.isWeekly ? '本周' : '本月');
    if (stats.todoScheduled <= 0) {
      return TodoOverviewBadge(
        label: '安放$span',
        icon: Icons.check_circle_outline_rounded,
        color: EchoColors.todoCompletedFill,
      );
    }

    final rate = stats.todoCompletionRate;
    if (rate >= 0.8) {
      return TodoOverviewBadge(
        label: '高效$span',
        icon: Icons.bolt_rounded,
        color: const Color(0xFFE8A838),
      );
    }
    if (rate >= 0.6) {
      return TodoOverviewBadge(
        label: '充实$span',
        icon: Icons.trending_up_rounded,
        color: const Color(0xFF6FAF82),
      );
    }
    if (rate >= 0.4) {
      return TodoOverviewBadge(
        label: '平和$span',
        icon: Icons.self_improvement_outlined,
        color: const Color(0xFF6B8CAE),
      );
    }
    return TodoOverviewBadge(
      label: '缓行$span',
      icon: Icons.directions_walk_rounded,
      color: EchoColors.dayTextSecondary,
    );
  }
}

/// 待办页 / 统计用的待办概况（圆环 + 总览条 + 分类横条）。
class TodoStatsPanel extends StatelessWidget {
  const TodoStatsPanel({
    super.key,
    required this.stats,
    this.compact = false,
  });

  final EchoPeriodStatistics stats;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasTodoActivity) {
      return const _EmptyStatCard(
        charm: EchoCharmKind.sprout,
        message: '这一段还没有待办记录\n想到什么，轻轻记下就好',
      );
    }

    final rate = stats.todoCompletionRate;
    final span = stats.todoSpanLabel.isNotEmpty
        ? stats.todoSpanLabel
        : (stats.isWeekly ? '本周' : '本月');
    final badge = TodoOverviewBadge.forStats(stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (badge != null) ...[
          _TodoOverviewBar(
            badge: badge,
            rate: rate,
            completed: stats.todoCompleted,
            scheduled: stats.todoScheduled,
            span: span,
          ),
          SizedBox(height: compact ? 16 : 20),
        ],
        Center(
          child: SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(96, 96),
                  painter: TodoCategoryRingPainter(
                    categories: stats.categories,
                    completed: stats.todoCompleted,
                    scheduled: stats.todoScheduled,
                    strokeWidth: 5,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${stats.todoCompleted}',
                      style: EchoTypography.displayMedium.copyWith(
                        fontSize: 26,
                        color: EchoColors.dayTextPrimary,
                        height: 1,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      stats.todoScheduled > 0
                          ? '/ ${stats.todoScheduled}'
                          : '已安放',
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
          stats.todoScheduled > 0
              ? '$span完成 ${(rate * 100).round()}% 的约定'
              : '$span安放了 ${stats.todoCompleted} 件',
          textAlign: TextAlign.center,
          style: EchoTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextSecondary,
          ),
        ),
        if (stats.categories.isNotEmpty) ...[
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '分类完成度',
              style: EchoTypography.caption.copyWith(
                fontWeight: FontWeight.w400,
                color: EchoColors.todoCompletedFill,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...stats.categories.map((c) => TodoCategoryBar(stat: c)),
        ],
      ],
    );
  }
}

class _TodoOverviewBar extends StatelessWidget {
  const _TodoOverviewBar({
    required this.badge,
    required this.rate,
    required this.completed,
    required this.scheduled,
    required this.span,
  });

  final TodoOverviewBadge badge;
  final double rate;
  final int completed;
  final int scheduled;
  final String span;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: badge.color.withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(badge.icon, size: 18, color: badge.color),
              const SizedBox(width: 8),
              Text(
                badge.label,
                style: EchoTypography.labelLarge.copyWith(
                  color: badge.color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (scheduled > 0)
                Text(
                  '${(rate * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: badge.color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: scheduled > 0 ? rate : 1,
              minHeight: 5,
              backgroundColor: badge.color.withValues(alpha: 0.12),
              color: badge.color.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            scheduled > 0
                ? '$span · $completed / $scheduled 件约定'
                : '$span · 已安放 $completed 件',
            style: EchoTypography.micro.copyWith(
              color: EchoColors.dayTextWhisper,
              fontWeight: FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}

class TodoCategoryBar extends StatelessWidget {
  const TodoCategoryBar({super.key, required this.stat});

  final EchoCategoryStat stat;

  @override
  Widget build(BuildContext context) {
    final rate = stat.completionRate;
    final percent = (rate * 100).round();
    final color = stat.category.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(stat.category.icon, size: 16, color: color),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text(
              stat.category.label,
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
                final fillW = constraints.maxWidth * rate;
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
                          color: color.withValues(alpha: 0.72),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 78,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  '$percent%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: color,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _fractionLabel(stat),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextWhisper,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fractionLabel(EchoCategoryStat stat) {
    if (stat.scheduledCount > 0) {
      return '${stat.completedCount}/${stat.scheduledCount}';
    }
    if (stat.completedCount > 0) {
      return '${stat.completedCount} 件';
    }
    return '0';
  }
}

/// 圆环：整体完成占比内，按分类完成量切分不同颜色。
class TodoCategoryRingPainter extends CustomPainter {
  const TodoCategoryRingPainter({
    required this.categories,
    required this.completed,
    required this.scheduled,
    required this.strokeWidth,
  });

  final List<EchoCategoryStat> categories;
  final int completed;
  final int scheduled;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = EchoColors.todoCompletedBorder.withValues(alpha: 0.35);

    canvas.drawArc(rect, 0, math.pi * 2, false, track);

    if (completed <= 0) return;

    final overallRate =
        scheduled > 0 ? (completed / scheduled).clamp(0.0, 1.0) : 1.0;
    final filledSweep = overallRate * math.pi * 2;
    final segments = categories.where((c) => c.completedCount > 0).toList();
    if (segments.isEmpty) return;

    const gap = 0.04;
    var start = -math.pi / 2;

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final share = seg.completedCount / completed;
      var sweep = share * filledSweep;
      if (segments.length > 1) {
        sweep = (sweep - gap).clamp(0.0, filledSweep);
      }
      if (sweep <= 0) continue;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = seg.category.color.withValues(alpha: 0.82);

      canvas.drawArc(rect, start, sweep, false, paint);
      start += sweep + (segments.length > 1 ? gap : 0);
    }
  }

  @override
  bool shouldRepaint(covariant TodoCategoryRingPainter oldDelegate) {
    return oldDelegate.completed != completed ||
        oldDelegate.scheduled != scheduled ||
        oldDelegate.categories != categories;
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
