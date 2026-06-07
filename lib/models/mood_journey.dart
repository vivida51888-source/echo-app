import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/weather_mood.dart';
import '../services/echo_stats_service.dart';
import '../utils/diary_format.dart';

/// 沿途风景类型（对应写作时选的天气）。
enum MoodSceneryKind {
  empty,
  sunny,
  cloudy,
  lightRain,
  heavyRain,
  rainbow,
}

abstract final class MoodJourneyLayout {
  static const segmentWidth = 252.0;
  static const startSegmentWidth = 256.0;
  static const finishSegmentWidth = 268.0;
  static const sceneHeight = 228.0;
  static const cyclistViewportRatio = 0.32;

  /// 启程拱门中心（距起点段左缘）。
  static const startDoorCenterX = 198.0;

  /// 驿站拱门中心（距终点段左缘），与骑车人停靠对齐。
  static const finishDoorCenterX = 56.0;

  /// 匀速滚动：像素/秒
  static const rideSpeedPxPerSec = 115.0;

  static double scrollWidth(int dayCount) =>
      startSegmentWidth + dayCount * segmentWidth + finishSegmentWidth;

  /// 骑车到驿站门口时的滚动偏移。
  static double scrollToFinishDoor(int dayCount, double viewportWidth) {
    final doorWorldX =
        startSegmentWidth + dayCount * segmentWidth + finishDoorCenterX;
    final target = doorWorldX - viewportWidth * cyclistViewportRatio;
    final maxScroll = scrollWidth(dayCount) - viewportWidth;
    return target.clamp(0.0, math.max(0.0, maxScroll));
  }

  /// 视口内骑车人对应的路段索引（不含起点/终点段）。
  static int segmentIndexAtScroll(double scrollOffset, double viewportWidth) {
    final x =
        scrollOffset + viewportWidth * cyclistViewportRatio - startSegmentWidth;
    return (x / segmentWidth).floor();
  }

  /// 连续相同心情 / 连续未书写：仅首段显示天气角标。
  static List<bool> moodLabelFlags(List<EchoDayStat> days) {
    if (days.isEmpty) return [];
    final flags = List<bool>.filled(days.length, false);
    for (var i = 0; i < days.length; i++) {
      if (i == 0 || _segmentGroupKey(days[i - 1]) != _segmentGroupKey(days[i])) {
        flags[i] = true;
      }
    }
    return flags;
  }

  static String _segmentGroupKey(EchoDayStat day) {
    if (!day.hasDiary) return '__empty__';
    return WeatherMood.resolve(day.moodWeather).label;
  }

  static MoodSceneryKind sceneryFor(EchoDayStat day) {
    if (!day.hasDiary) return MoodSceneryKind.empty;
    return sceneryForLabel(WeatherMood.resolve(day.moodWeather).label);
  }

  static MoodSceneryKind sceneryForLabel(String label) => switch (label) {
        '晴' => MoodSceneryKind.sunny,
        '小雨' => MoodSceneryKind.lightRain,
        '大雨' => MoodSceneryKind.heavyRain,
        '彩虹' => MoodSceneryKind.rainbow,
        _ => MoodSceneryKind.cloudy,
      };

  static List<MoodJourneyWeek> weeksInMonth(List<EchoDayStat> monthDays) {
    if (monthDays.isEmpty) return [];
    final weeks = <MoodJourneyWeek>[];
    var bucket = <EchoDayStat>[];
    var index = 0;
    for (final day in monthDays) {
      if (bucket.isNotEmpty && day.date.weekday == DateTime.monday) {
        weeks.add(MoodJourneyWeek(days: bucket, index: index++));
        bucket = [];
      }
      bucket.add(day);
    }
    if (bucket.isNotEmpty) {
      weeks.add(MoodJourneyWeek(days: bucket, index: index));
    }
    return weeks;
  }

  /// 月视图：每段 = 一周，风景取该周出现最多的心情天气。
  static List<MoodJourneySegmentView> monthSegments(List<EchoDayStat> monthDays) {
    return [
      for (final week in weeksInMonth(monthDays))
        MoodJourneySegmentView(
          stat: week.toRepresentativeStat(),
          cornerLabel: '第 ${week.index + 1} 周',
          weekRange: DiaryFormat.dateRange(week.days.first.date, week.days.last.date),
        ),
    ];
  }

  /// 周视图：每段 = 一天。
  static List<MoodJourneySegmentView> dailySegments(List<EchoDayStat> days) {
    return [
      for (final day in days)
        MoodJourneySegmentView(
          stat: day,
          cornerLabel: '${day.date.month}/${day.date.day}',
        ),
    ];
  }
}

/// 卷轴上的一段（天或周）。
class MoodJourneySegmentView {
  const MoodJourneySegmentView({
    required this.stat,
    required this.cornerLabel,
    this.weekRange,
  });

  final EchoDayStat stat;
  final String cornerLabel;
  final String? weekRange;
}

class MoodJourneyWeek {
  const MoodJourneyWeek({required this.days, required this.index});

  final List<EchoDayStat> days;
  final int index;

  String get label {
    if (days.isEmpty) return '第 ${index + 1} 周';
    return '第 ${index + 1} 周 · ${DiaryFormat.dateRange(days.first.date, days.last.date)}';
  }

  EchoMoodStat? get dominantMood {
    final freq = <String, int>{};
    for (final day in days) {
      if (!day.hasDiary || day.moodWeather == null) continue;
      final mood = WeatherMood.resolveDisplay(day.moodWeather);
      freq[mood] = (freq[mood] ?? 0) + 1;
    }
    if (freq.isEmpty) return null;
    final top = freq.entries.reduce((a, b) => a.value >= b.value ? a : b);
    final parsed = WeatherMood.fromDisplay(top.key);
    return EchoMoodStat(
      display: top.key,
      emoji: parsed?.emoji ?? '⛅',
      label: parsed?.label ?? top.key,
      count: top.value,
    );
  }

  /// 月地图一段：用该周主调心情代表整段风景。
  EchoDayStat toRepresentativeStat() {
    final dominant = dominantMood;
    final withDiary = days.where((d) => d.hasDiary).toList();
    final ids = <String>[];
    for (final d in withDiary) {
      ids.addAll(d.diaryIds);
    }
    EchoDayStat? anchor;
    for (final d in withDiary) {
      if (anchor == null || d.date.isAfter(anchor.date)) anchor = d;
    }
    return EchoDayStat(
      date: days.first.date,
      hasDiary: dominant != null,
      entryCount: withDiary.fold(0, (a, d) => a + d.entryCount),
      moodWeather: dominant?.display,
      primaryDiaryId: anchor?.primaryDiaryId,
      diaryIds: ids,
    );
  }
}

/// 每种天气的简短沿途描述（底部状态栏用）。
String moodSceneryCaption(MoodSceneryKind kind) => switch (kind) {
      MoodSceneryKind.sunny => '晴空铺展，路旁野花在风里轻轻摇',
      MoodSceneryKind.cloudy => '云层缓缓聚拢，光变得柔和',
      MoodSceneryKind.lightRain => '细雨斜落，路面映出浅浅水光',
      MoodSceneryKind.heavyRain => '雨势渐紧，远方轮廓沉入雾中',
      MoodSceneryKind.rainbow => '雨霁天青，彩虹轻轻架在路尽头',
      MoodSceneryKind.empty => '尚未写下，这一段还蒙着薄雾',
    };

/// 全段共用的地平线 / 路面高度（保证段与段对齐）。
abstract final class RoadGeometry {
  static const groundTopRatio = 0.50;
  static const roadTopRatio = 0.74;
  static const roadDashRatio = 0.805;

  static double groundTop(Size size) => size.height * groundTopRatio;
  static double roadTop(Size size) => size.height * roadTopRatio;
  static double roadDashY(Size size) => size.height * roadDashRatio;

  /// 远景丘陵 —— 各段同一轮廓，只换色。
  static void paintHill(Canvas canvas, Size size, Color color, double alpha) {
    final top = groundTop(size);
    final road = roadTop(size);
    final path = Path()
      ..moveTo(0, top + 6)
      ..quadraticBezierTo(size.width * 0.22, top - 20, size.width * 0.48, top + 2)
      ..quadraticBezierTo(size.width * 0.74, top - 16, size.width, top + 4)
      ..lineTo(size.width, road)
      ..lineTo(0, road)
      ..close();
    canvas.drawPath(path, Paint()..color = color.withValues(alpha: alpha));
  }

  /// 路旁用地（麦田/草地/湿地）— 统一顶底。
  static void paintGroundBand(Canvas canvas, Size size, Color color, double alpha) {
    canvas.drawRect(
      Rect.fromLTRB(0, groundTop(size), size.width, roadTop(size)),
      Paint()..color = color.withValues(alpha: alpha),
    );
  }
}
