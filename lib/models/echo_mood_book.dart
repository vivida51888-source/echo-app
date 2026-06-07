import 'package:flutter/material.dart';

import '../services/echo_stats_service.dart';
import '../utils/diary_format.dart';
import 'weather_mood.dart';

/// 某一月的心情之书。
class EchoMoodBook {
  const EchoMoodBook({
    required this.year,
    required this.month,
    required this.stats,
    this.customTitle,
  });

  final int year;
  final int month;
  final EchoPeriodStatistics stats;
  final String? customTitle;

  bool get hasEntries => stats.hasDiaryActivity;

  String get defaultTitle => DiaryFormat.monthTitleShort(month);

  String get displayTitle =>
      (customTitle != null && customTitle!.isNotEmpty)
          ? customTitle!
          : defaultTitle;

  EchoMoodStat? get dominantMood => stats.dominantMood;

  Color get spineColor {
    if (!hasEntries) return WeatherMood.emptySpineColor;
    final mood = dominantMood;
    if (mood == null) return WeatherMood.emptySpineColor;
    return WeatherMood.spineColor(mood.display);
  }

  Color get spineHighlight => Color.lerp(spineColor, Colors.white, 0.22)!;

  Color get spineShadow => Color.lerp(spineColor, Colors.black, 0.18)!;

  String get dominantLabel =>
      dominantMood?.label ?? (hasEntries ? '多云' : '空白');

  String get dominantEmoji => dominantMood?.emoji ?? (hasEntries ? '⛅' : '—');
}
