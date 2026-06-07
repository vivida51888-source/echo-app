import '../models/weather_mood.dart';
import '../services/echo_stats_service.dart';

/// 统计页 · 根据近期心情生成一句温柔概括。
abstract final class MoodTrendCopy {
  static String periodWhisper(EchoPeriodStatistics stats) {
    final span = stats.isWeekly ? '这一周' : '这一月';
    final moodDays = stats.days.where((d) => d.moodWeather != null).toList();

    if (moodDays.isEmpty) {
      if (stats.hasDiaryActivity) {
        return '$span写了几笔回响，还没选天象心情——选一种天气，趋势会慢慢显形';
      }
      return '$span还静着，写回响时选一种天气，沿途风景会慢慢亮起来';
    }

    final recent = _recentMoodDays(moodDays, stats.isWeekly ? 5 : 7);
    final dominant = _dominantLabel(recent);
    final trend = _detectTrend(recent);

    return _phraseFor(span, dominant, trend, recent.length);
  }

  static List<EchoDayStat> _recentMoodDays(
    List<EchoDayStat> moodDays,
    int take,
  ) {
    final sorted = List<EchoDayStat>.from(moodDays)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.take(take).toList();
  }

  static String _dominantLabel(List<EchoDayStat> recent) {
    final freq = <String, int>{};
    for (final day in recent) {
      final label = WeatherMood.resolve(day.moodWeather).label;
      freq[label] = (freq[label] ?? 0) + 1;
    }
    var best = WeatherMood.defaultMood.label;
    var bestCount = 0;
    for (final entry in freq.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  /// 近几天是否由阴转晴、由晴转雨等。
  static _MoodTrend _detectTrend(List<EchoDayStat> recent) {
    if (recent.length < 2) return _MoodTrend.steady;
    final ordered = List<EchoDayStat>.from(recent)
      ..sort((a, b) => a.date.compareTo(b.date));
    final scores = ordered
        .map((d) => _brightness(WeatherMood.resolve(d.moodWeather).label))
        .toList();
    final delta = scores.last - scores.first;
    if (delta >= 1.2) return _MoodTrend.brightening;
    if (delta <= -1.2) return _MoodTrend.softening;
    if (_isMixed(scores)) return _MoodTrend.mixed;
    return _MoodTrend.steady;
  }

  static bool _isMixed(List<double> scores) {
    if (scores.length < 3) return false;
    var swings = 0;
    for (var i = 1; i < scores.length; i++) {
      if ((scores[i] - scores[i - 1]).abs() >= 1.5) swings++;
    }
    return swings >= 2;
  }

  static double _brightness(String label) {
    switch (label) {
      case '晴':
        return 4;
      case '彩虹':
        return 3.5;
      case '多云':
        return 2.5;
      case '小雨':
        return 1.5;
      case '大雨':
        return 0.5;
      default:
        return 2.5;
    }
  }

  static String _phraseFor(
    String span,
    String dominant,
    _MoodTrend trend,
    int sampleDays,
  ) {
    if (trend == _MoodTrend.brightening) {
      return switch (dominant) {
        '晴' || '彩虹' => '近几天心色慢慢亮起来，$span像在等一场好天气',
        '小雨' || '大雨' => '雨里也有转晴的迹象，$span不必急着晴朗，慢慢来就好',
        _ => '近几天心绪在回暖，$span像云缝间漏进一点光',
      };
    }
    if (trend == _MoodTrend.softening) {
      return switch (dominant) {
        '小雨' || '大雨' => '近几天多是小雨，$span适合把心事写慢一点，不必撑得太满',
        '多云' => '近几天心绪偏静，$span像一层薄云，轻轻盖着也没关系',
        _ => '近几天节奏慢下来，$span留一点空白，给自己喘口气',
      };
    }
    if (trend == _MoodTrend.mixed) {
      return '$span阴晴交替，像寻常日子——有亮有暗，都算被好好走过';
    }

    return switch (dominant) {
      '晴' => sampleDays <= 2
          ? '近几天多是晴天，$span心里也留着一点暖'
          : '$span多半晴朗，把好心情轻轻记下来吧',
      '彩虹' => '$span偶尔遇见彩虹，那些瞬间值得被留下来',
      '小雨' => '$span常是小雨，细细碎碎的心情，也需要被接住',
      '大雨' => '近几天雨意偏浓，$span若觉得沉，写几个字也好',
      _ => '$span多云的时候最多，不晴不雨，也是一种安稳',
    };
  }
}

enum _MoodTrend { steady, brightening, softening, mixed }
