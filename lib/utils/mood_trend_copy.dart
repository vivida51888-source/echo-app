import '../l10n/localized.dart';
import '../models/weather_mood.dart';
import '../services/echo_stats_service.dart';

/// 统计页 · 根据近期心情生成一句温柔概括。
abstract final class MoodTrendCopy {
  static String periodWhisper(EchoPeriodStatistics stats) {
    final span = stats.isWeekly
        ? tr('这一周', 'This week')
        : tr('这一月', 'This month');
    final moodDays = stats.days.where((d) => d.moodWeather != null).toList();

    if (moodDays.isEmpty) {
      if (stats.hasDiaryActivity) {
        return tr(
          '$span写了几笔回响，还没选天象心情——选一种天气，趋势会慢慢显形',
          '$span you wrote a few echoes — pick a weather mood and trends will emerge',
        );
      }
      return tr(
        '$span还静着，写回响时选一种天气，沿途风景会慢慢亮起来',
        '$span is quiet — choose a weather mood when you write and the view will brighten',
      );
    }

    final recent = _recentMoodDays(moodDays, stats.isWeekly ? 5 : 7);
    final dominant = _dominantEmoji(recent);
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

  static String _dominantEmoji(List<EchoDayStat> recent) {
    final freq = <String, int>{};
    for (final day in recent) {
      final emoji = WeatherMood.resolve(day.moodWeather).emoji;
      freq[emoji] = (freq[emoji] ?? 0) + 1;
    }
    var best = WeatherMood.defaultMood.emoji;
    var bestCount = 0;
    for (final entry in freq.entries) {
      if (entry.value > bestCount) {
        best = entry.key;
        bestCount = entry.value;
      }
    }
    return best;
  }

  static _MoodTrend _detectTrend(List<EchoDayStat> recent) {
    if (recent.length < 2) return _MoodTrend.steady;
    final ordered = List<EchoDayStat>.from(recent)
      ..sort((a, b) => a.date.compareTo(b.date));
    final scores = ordered
        .map((d) => _brightness(WeatherMood.resolve(d.moodWeather).emoji))
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

  static double _brightness(String emoji) {
    switch (emoji) {
      case '☀️':
        return 4;
      case '🌈':
        return 3.5;
      case '⛅':
        return 2.5;
      case '🌧':
        return 1.5;
      case '⛈':
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
        '☀️' || '🌈' => tr(
            '近几天心色慢慢亮起来，$span像在等一场好天气',
            'Your mood is brightening — $span feels like waiting for fair weather',
          ),
        '🌧' || '⛈' => tr(
            '雨里也有转晴的迹象，$span不必急着晴朗，慢慢来就好',
            'Hints of clearing after rain — $span need not rush to sunshine',
          ),
        _ => tr(
            '近几天心绪在回暖，$span像云缝间漏进一点光',
            'Your heart is warming — $span catches light through the clouds',
          ),
      };
    }
    if (trend == _MoodTrend.softening) {
      return switch (dominant) {
        '🌧' || '⛈' => tr(
            '近几天多是小雨，$span适合把心事写慢一点，不必撑得太满',
            'Mostly rainy lately — $span is for slower writing, not holding it all in',
          ),
        '⛅' => tr(
            '近几天心绪偏静，$span像一层薄云，轻轻盖着也没关系',
            'A quieter mood — $span like thin clouds, gently covering is fine',
          ),
        _ => tr(
            '近几天节奏慢下来，$span留一点空白，给自己喘口气',
            'The pace slowed — $span leaves room to breathe',
          ),
      };
    }
    if (trend == _MoodTrend.mixed) {
      return tr(
        '$span阴晴交替，像寻常日子——有亮有暗，都算被好好走过',
        '$span shifts between sun and rain — ordinary days, well walked',
      );
    }

    return switch (dominant) {
      '☀️' => sampleDays <= 2
          ? tr(
              '近几天多是晴天，$span心里也留着一点暖',
              'Mostly sunny lately — $span keeps a little warmth',
            )
          : tr(
              '$span多半晴朗，把好心情轻轻记下来吧',
              '$span has been mostly sunny — note the good moments',
            ),
      '🌈' => tr(
          '$span偶尔遇见彩虹，那些瞬间值得被留下来',
          '$span caught a rainbow — those moments are worth keeping',
        ),
      '🌧' => tr(
          '$span常是小雨，细细碎碎的心情，也需要被接住',
          '$span often drizzles — small feelings deserve to be held',
        ),
      '⛈' => tr(
          '近几天雨意偏浓，$span若觉得沉，写几个字也好',
          'Heavy rain lately — if $span feels heavy, a few words help',
        ),
      _ => tr(
          '$span多云的时候最多，不晴不雨，也是一种安稳',
          '$span is mostly cloudy — neither sun nor rain, still steady',
        ),
    };
  }
}

enum _MoodTrend { steady, brightening, softening, mixed }
