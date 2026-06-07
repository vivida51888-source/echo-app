import 'package:flutter/material.dart';

/// 天气风格心情，可选不选（未选时默认多云）。
class WeatherMood {
  const WeatherMood(this.emoji, this.label);

  final String emoji;
  final String label;

  String get display => '$emoji $label';

  static const defaultMood = WeatherMood('⛅', '多云');

  static const List<WeatherMood> options = [
    WeatherMood('☀️', '晴'),
    defaultMood,
    WeatherMood('🌧', '小雨'),
    WeatherMood('⛈', '大雨'),
    WeatherMood('🌈', '彩虹'),
  ];

  static WeatherMood? fromDisplay(String? value) {
    if (value == null || value.isEmpty) return null;
    for (final mood in options) {
      if (mood.display == value) return mood;
    }
    return null;
  }

  static String resolveDisplay(String? value) {
    if (value == null || value.isEmpty) return defaultMood.display;
    return fromDisplay(value)?.display ?? defaultMood.display;
  }

  static WeatherMood resolve(String? value) =>
      fromDisplay(resolveDisplay(value)) ?? defaultMood;

  /// 拍立得白边 / 染边用色。
  static Color tintColor(String? moodDisplay) {
    switch (resolve(moodDisplay).label) {
      case '晴':
        return const Color(0xFFF8EDD8);
      case '小雨':
        return const Color(0xFFDCE6F0);
      case '大雨':
        return const Color(0xFFC8D4E4);
      case '彩虹':
        return const Color(0xFFF0E6F8);
      case '多云':
        return const Color(0xFFF1EBE3);
      default:
        return const Color(0xFFF1EBE3);
    }
  }

  /// 心情之书书脊色（当月主导情绪）。
  static Color spineColor(String? moodDisplay) {
    switch (resolve(moodDisplay).label) {
      case '晴':
        return const Color(0xFFD4A84B);
      case '小雨':
        return const Color(0xFF6B9DC4);
      case '大雨':
        return const Color(0xFF4A6B8A);
      case '彩虹':
        return const Color(0xFFB892D4);
      case '多云':
        return const Color(0xFFB0A896);
      default:
        return const Color(0xFFB0A896);
    }
  }

  static const emptySpineColor = Color(0xFFC8C4BC);

  /// 统计圆环 / 横条用色。
  Color get chartColor => spineColor(display);

  static Color chartColorFor(String? moodDisplay) =>
      resolve(moodDisplay).chartColor;
}
