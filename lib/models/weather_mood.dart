import 'package:flutter/material.dart';

import '../l10n/localized.dart';

/// 天气风格心情，可选不选（未选时默认多云）。
class WeatherMood {
  const WeatherMood(this.emoji, this.labelZh, this.labelEn);

  final String emoji;
  final String labelZh;
  final String labelEn;

  String get label => tr(labelZh, labelEn);

  String get display => '$emoji $label';

  static const defaultMood = WeatherMood('⛅', '多云', 'Cloudy');

  static const List<WeatherMood> options = [
    WeatherMood('☀️', '晴', 'Sunny'),
    defaultMood,
    WeatherMood('🌧', '小雨', 'Drizzle'),
    WeatherMood('⛈', '大雨', 'Storm'),
    WeatherMood('🌈', '彩虹', 'Rainbow'),
  ];

  static WeatherMood? fromDisplay(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final mood in options) {
      if (mood.display == value) return mood;
      if (value.contains(mood.emoji)) return mood;
      if (value.contains(mood.labelZh) || value.contains(mood.labelEn)) {
        return mood;
      }
    }
    return null;
  }

  static String resolveDisplay(String? value) {
    if (value == null || value.isEmpty) return defaultMood.display;
    return fromDisplay(value)?.display ?? defaultMood.display;
  }

  static WeatherMood resolve(String? value) =>
      fromDisplay(resolveDisplay(value)) ?? defaultMood;

  static Color tintColor(String? moodDisplay) {
    switch (resolve(moodDisplay).emoji) {
      case '☀️':
        return const Color(0xFFF8EDD8);
      case '🌧':
        return const Color(0xFFDCE6F0);
      case '⛈':
        return const Color(0xFFC8D4E4);
      case '🌈':
        return const Color(0xFFF0E6F8);
      case '⛅':
      default:
        return const Color(0xFFF1EBE3);
    }
  }

  static Color spineColor(String? moodDisplay) {
    switch (resolve(moodDisplay).emoji) {
      case '☀️':
        return const Color(0xFFD4A84B);
      case '🌧':
        return const Color(0xFF6B9DC4);
      case '⛈':
        return const Color(0xFF4A6B8A);
      case '🌈':
        return const Color(0xFFB892D4);
      case '⛅':
      default:
        return const Color(0xFFB0A896);
    }
  }

  static const emptySpineColor = Color(0xFFC8C4BC);

  Color get chartColor => spineColor(display);

  static Color chartColorFor(String? moodDisplay) =>
      resolve(moodDisplay).chartColor;
}
