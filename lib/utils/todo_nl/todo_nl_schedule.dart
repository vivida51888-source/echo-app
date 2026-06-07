import '../../models/todo_reminder.dart';
import '../todo_schedule.dart';
import 'todo_nl_category.dart';
import 'todo_nl_types.dart';

/// 从中文语句中提取提醒时间与重复规则。
abstract final class TodoNlScheduleExtractor {
  static TodoNlScheduleResult extract(String text, DateTime reference) {
    final spans = <TodoNlSpan>[];
    var repeat = TodoRepeat.none;
    DateTime? reminderAt;
    var matched = false;

    // 1. 每月固定日
    final monthly = _parseMonthly(text, spans, reference);
    if (monthly != null) {
      repeat = TodoRepeat.monthly;
      reminderAt = monthly;
      matched = true;
    }

    // 2. 每周固定星期
    if (repeat == TodoRepeat.none) {
      final weeklyDay = _parseWeeklyDay(
        text,
        spans,
        reference,
        onRepeat: (r) => repeat = r,
      );
      if (weeklyDay != null) {
        reminderAt ??= weeklyDay;
        matched = true;
      }
    }

    // 3. 重复关键词（隔天 / 每天 / …）
    repeat = _parseRepeat(text, spans, repeat);

    // 4. 相对时长
    final relativeAt = _parseRelativeDuration(text, spans, reference);
    if (relativeAt != null) {
      reminderAt = relativeAt;
      matched = true;
    }

    // 5. 截止型：周五之前、月底前
    if (relativeAt == null) {
      final deadline = _parseDeadline(text, spans, reference);
      if (deadline != null) {
        reminderAt = deadline;
        matched = true;
      }
    }

    // 6. 语境时刻：下午出门前
    final contextual = _parseContextualTime(
      _mask(text, spans),
      spans,
      reference,
    );
    if (contextual != null && relativeAt == null) {
      reminderAt = contextual;
      matched = true;
    }

    // 7. 绝对日期
    final date = _parseAbsoluteDate(_mask(text, spans), spans, reference);

    // 8. 时刻
    var time = _parseClockTime(_mask(text, spans), spans);
    time ??= _parsePeriodFallback(_mask(text, spans), spans);

    // 9. 无「每月」前缀但「15号交房租」→ 推断按月
    if (repeat == TodoRepeat.none &&
        monthly == null &&
        TodoNlCategoryResolver.suggestsMonthly(text)) {
      final dom = _parseDayOfMonthOnly(text, spans);
      if (dom != null) {
        repeat = TodoRepeat.monthly;
        reminderAt = TodoSchedule.monthlyOnDay(reference, dom);
        matched = true;
      }
    }

    // 合并日期 + 时刻
    if (relativeAt == null && contextual == null) {
      if (date != null || time != null) {
        matched = true;
        reminderAt = _combine(reference, date, time, fallback: reminderAt);
      } else if (reminderAt == null && repeat != TodoRepeat.none) {
        reminderAt = reference.add(const Duration(hours: 1));
        matched = true;
      }
    }

    return TodoNlScheduleResult(
      reminderAt: reminderAt ?? reference.add(const Duration(hours: 1)),
      repeat: repeat,
      matched: matched,
      spans: spans,
    );
  }

  static String _mask(String text, List<TodoNlSpan> spans) {
    if (spans.isEmpty) return text;
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final hit = spans.any((s) => i >= s.start && i < s.end);
      buffer.write(hit ? ' ' : text[i]);
    }
    return buffer.toString();
  }

  static DateTime? _parseMonthly(String text, List<TodoNlSpan> spans, DateTime ref) {
    final patterns = <RegExp>[
      RegExp(r'每(?:个)?月(\d{1,2})[号日]'),
      RegExp(r'每月([零一二两三四五六七八九十\d]{1,2})[号日]'),
      RegExp(r'每个月(\d{1,2})[号日]'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final day = _parseNumberToken(match.group(1)!);
      if (day == null || day < 1 || day > 31) continue;
      spans.add(TodoNlSpan(match.start, match.end));
      return TodoSchedule.monthlyOnDay(ref, day);
    }
    return null;
  }

  static int? _parseDayOfMonthOnly(String text, List<TodoNlSpan> spans) {
    final match = RegExp(r'(?<![月年])(\d{1,2})[号日]').firstMatch(text);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    if (day == null || day < 1 || day > 31) return null;
    spans.add(TodoNlSpan(match.start, match.end));
    return day;
  }

  static TodoRepeat _parseRepeat(
    String text,
    List<TodoNlSpan> spans,
    TodoRepeat current,
  ) {
    if (current == TodoRepeat.monthly || current == TodoRepeat.weekly) {
      return current;
    }

    final patterns = <(RegExp, TodoRepeat)>[
      (RegExp(r'(?:每个)?工作日'), TodoRepeat.workday),
      (RegExp(r'隔(?:一)?天|隔天|隔日|每隔一天|每隔天|隔一天'), TodoRepeat.alternateDay),
      (RegExp(r'每天|每日'), TodoRepeat.daily),
      (
        RegExp(r'每周(?!([一二三四五六日天]))|每个星期(?!([一二三四五六日天]))'),
        TodoRepeat.weekly,
      ),
    ];

    for (final (pattern, rule) in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        spans.add(TodoNlSpan(match.start, match.end));
        return rule;
      }
    }
    return current;
  }

  static DateTime? _parseWeeklyDay(
    String text,
    List<TodoNlSpan> spans,
    DateTime now, {
    required void Function(TodoRepeat value) onRepeat,
  }) {
    final weekend = RegExp(r'每(?:个)?周末').firstMatch(text);
    if (weekend != null) {
      onRepeat(TodoRepeat.weekly);
      spans.add(TodoNlSpan(weekend.start, weekend.end));
      return TodoSchedule.weekdayAt(now, DateTime.saturday, hour: 10);
    }

    final patterns = <RegExp>[
      RegExp(r'每(?:个)?(?:周|星期|礼拜)([一二三四五六日天])'),
      RegExp(r'每逢(?:周|星期|礼拜)([一二三四五六日天])'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      onRepeat(TodoRepeat.weekly);
      spans.add(TodoNlSpan(match.start, match.end));
      return TodoSchedule.weekdayAt(
        now,
        _weekdayFromToken(match.group(1)!),
        hour: 9,
      );
    }
    return null;
  }

  static DateTime? _parseDeadline(String text, List<TodoNlSpan> spans, DateTime ref) {
    final patterns = <(RegExp, DateTime Function(Match))>[
      (
        RegExp(r'月底(?:之)?前|月底前|月末(?:之)?前'),
        (_) => TodoSchedule.endOfMonthAt(ref),
      ),
      (
        RegExp(r'本(?:月|个月)底(?:之)?前'),
        (_) => TodoSchedule.endOfMonthAt(ref),
      ),
      (
        RegExp(r'(?:周|星期|礼拜)?([一二三四五六日天])(?:之)?前'),
        (m) => TodoSchedule.weekdayAt(ref, _weekdayFromToken(m.group(1)!)),
      ),
      (
        RegExp(r'下(?:周|星期|礼拜)([一二三四五六日天])(?:之)?前'),
        (m) {
          final start = ref.subtract(Duration(days: ref.weekday - 1));
          final day = start.add(Duration(days: _weekdayFromToken(m.group(1)!) - 1 + 7));
          return DateTime(day.year, day.month, day.day, 18, 0);
        },
      ),
    ];

    for (final (pattern, builder) in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      spans.add(TodoNlSpan(match.start, match.end));
      return builder(match);
    }
    return null;
  }

  static DateTime? _parseContextualTime(
    String masked,
    List<TodoNlSpan> spans,
    DateTime ref,
  ) {
    const defaults = <String, int>{
      '出门前': 14,
      '下班前': 17,
      '睡觉前': 22,
      '睡前': 22,
      '吃饭前': 11,
      '开会前': 9,
      '上班前': 8,
      '到家前': 19,
    };

    final pattern = RegExp(
      r'(上午|下午|晚上|早上|傍晚)?(出门前|下班前|睡觉前|睡前|吃饭前|开会前|上班前|到家前)',
    );
    final match = pattern.firstMatch(masked);
    if (match == null) return null;

    final period = match.group(1);
    final cue = match.group(2)!;
    var hour = defaults[cue] ?? 14;
    if (period == '上午' || period == '早上') hour = hour.clamp(6, 11);
    if (period == '下午') hour = hour < 12 ? hour + 12 : hour;
    if (period == '晚上' || period == '傍晚') hour = hour < 12 ? hour + 12 : hour;

    spans.add(TodoNlSpan(match.start, match.end));
    final today = TodoSchedule.dateOnly(ref);
    var target = DateTime(today.year, today.month, today.day, hour, 0);
    if (!target.isAfter(ref)) {
      final tomorrow = today.add(const Duration(days: 1));
      target = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, hour, 0);
    }
    return target;
  }

  static DateTime? _parseRelativeDuration(
    String text,
    List<TodoNlSpan> spans,
    DateTime reference,
  ) {
    final patterns = <(RegExp, Duration Function(Match))>[
      (
        RegExp(r'半个?(?:小时|钟头)(?:之)?后'),
        (_) => const Duration(minutes: 30),
      ),
      (
        RegExp(r'([零一二两三四五六七八九十\d]+)(?:个)?(?:半)?(?:小时|钟头|h|H)(?:之)?后'),
        (m) {
          final value = _parseNumberToken(m.group(1)!);
          if (value == null) return Duration.zero;
          final half = m.group(0)!.contains('半');
          return Duration(minutes: value * 60 + (half ? 30 : 0));
        },
      ),
      (
        RegExp(r'([零一二两三四五六七八九十\d]+)(?:个)?(?:分钟|分|min)(?:之)?后'),
        (m) {
          final value = _parseNumberToken(m.group(1)!);
          return value == null ? Duration.zero : Duration(minutes: value);
        },
      ),
      (
        RegExp(r'([零一二两三四五六七八九十\d]+)(?:个)?天(?:之)?后'),
        (m) {
          final value = _parseNumberToken(m.group(1)!);
          return value == null ? Duration.zero : Duration(days: value);
        },
      ),
      (RegExp(r'马上|立即|现在就'), (_) => const Duration(minutes: 5)),
    ];

    for (final (pattern, builder) in patterns) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      final duration = builder(match);
      if (duration <= Duration.zero) continue;
      spans.add(TodoNlSpan(match.start, match.end));
      return reference.add(duration);
    }
    return null;
  }

  static DateTime? _parseAbsoluteDate(String text, List<TodoNlSpan> spans, DateTime now) {
    final today = TodoSchedule.dateOnly(now);
    final ordered = <(RegExp, DateTime Function(Match))>[
      (RegExp(r'大后天'), (_) => today.add(const Duration(days: 3))),
      (RegExp(r'后天'), (_) => today.add(const Duration(days: 2))),
      (RegExp(r'明早|明天早上|明日早'), (_) => today.add(const Duration(days: 1))),
      (RegExp(r'明天|明日'), (_) => today.add(const Duration(days: 1))),
      (RegExp(r'今天|今日'), (_) => today),
      (
        RegExp(r'下(?:周|星期|礼拜)([一二三四五六日天])'),
        (m) {
          final start = today.subtract(Duration(days: today.weekday - 1));
          return start.add(Duration(days: _weekdayFromToken(m.group(1)!) - 1 + 7));
        },
      ),
      (
        RegExp(r'(?<![每])(?:周|星期|礼拜)([一二三四五六日天])'),
        (m) {
          final delta = (_weekdayFromToken(m.group(1)!) - today.weekday + 7) % 7;
          return today.add(Duration(days: delta));
        },
      ),
      (
        RegExp(r'(\d{1,2})月(\d{1,2})[日号]?'),
        (m) {
          final month = int.parse(m.group(1)!);
          final day = int.parse(m.group(2)!);
          var year = now.year;
          var candidate = DateTime(year, month, day);
          if (candidate.isBefore(today)) {
            candidate = DateTime(year + 1, month, day);
          }
          return TodoSchedule.dateOnly(candidate);
        },
      ),
    ];

    for (final (pattern, builder) in ordered) {
      final match = pattern.firstMatch(text);
      if (match == null) continue;
      spans.add(TodoNlSpan(match.start, match.end));
      return builder(match);
    }
    return null;
  }

  static TodoNlTimeParts? _parseClockTime(String masked, List<TodoNlSpan> spans) {
    final patterns = <(RegExp, TodoNlTimeParts? Function(Match))>[
      (
        RegExp(r'(凌晨|清晨|早上|上午|中午|下午|傍晚|晚上|夜里)?(\d{1,2})[:：](\d{2})'),
        (m) => _buildTime(
          period: m.group(1),
          hour: int.parse(m.group(2)!),
          minute: int.parse(m.group(3)!),
        ),
      ),
      (
        RegExp(
          r'(凌晨|清晨|早上|上午|中午|下午|傍晚|晚上|夜里)?(\d{1,2})[点](?:钟)?半',
        ),
        (m) => _buildTime(
          period: m.group(1),
          hour: int.parse(m.group(2)!),
          minute: 30,
        ),
      ),
      (
        RegExp(
          r'(凌晨|清晨|早上|上午|中午|下午|傍晚|晚上|夜里)?(\d{1,2})[点](?:钟)?(?!半)',
        ),
        (m) => _buildTime(
          period: m.group(1),
          hour: int.parse(m.group(2)!),
          minute: 0,
        ),
      ),
      (
        RegExp(
          r'(凌晨|清晨|早上|上午|中午|下午|傍晚|晚上|夜里)?([零一二两三四五六七八九十]{1,3})[点:：]?钟?半',
        ),
        (m) {
          final hour = _parseNumberToken(m.group(2)!);
          return hour == null
              ? null
              : _buildTime(period: m.group(1), hour: hour, minute: 30);
        },
      ),
      (
        RegExp(
          r'(凌晨|清晨|早上|上午|中午|下午|傍晚|晚上|夜里)?([零一二两三四五六七八九十]{1,3})[点:：]钟?(?!半)',
        ),
        (m) {
          final hour = _parseNumberToken(m.group(2)!);
          return hour == null
              ? null
              : _buildTime(period: m.group(1), hour: hour, minute: 0);
        },
      ),
    ];

    TodoNlTimeParts? best;
    TodoNlSpan? bestSpan;
    for (final (pattern, builder) in patterns) {
      final match = pattern.firstMatch(masked);
      if (match == null) continue;
      final value = builder(match);
      if (value == null) continue;
      if (bestSpan == null || match.start < bestSpan.start) {
        best = value;
        bestSpan = TodoNlSpan(match.start, match.end);
      }
    }
    if (bestSpan != null) {
      spans.add(bestSpan);
      return best;
    }
    return null;
  }

  static TodoNlTimeParts? _parsePeriodFallback(String masked, List<TodoNlSpan> spans) {
    const defaults = <String, (int, int)>{
      '凌晨': (5, 0),
      '清晨': (6, 0),
      '早上': (8, 0),
      '上午': (9, 0),
      '中午': (12, 0),
      '下午': (15, 0),
      '傍晚': (18, 0),
      '晚上': (20, 0),
      '夜里': (21, 0),
    };

    int? bestIndex;
    (int, int)? bestTime;
    String? bestKey;

    for (final entry in defaults.entries) {
      final idx = masked.indexOf(entry.key);
      if (idx < 0) continue;
      if (bestIndex == null || idx < bestIndex) {
        bestIndex = idx;
        bestTime = entry.value;
        bestKey = entry.key;
      }
    }

    if (bestIndex == null || bestTime == null || bestKey == null) return null;
    spans.add(TodoNlSpan(bestIndex, bestIndex + bestKey.length));
    return TodoNlTimeParts(bestTime.$1, bestTime.$2);
  }

  static DateTime _combine(
    DateTime reference,
    DateTime? date,
    TodoNlTimeParts? time, {
    DateTime? fallback,
  }) {
    if (date == null && time == null) {
      return fallback ?? reference.add(const Duration(hours: 1));
    }

    // 已有「每周三」等 fallback 时，只补时刻，不改成今天/明天。
    if (date == null && time != null && fallback != null) {
      final day = TodoSchedule.dateOnly(fallback);
      return DateTime(day.year, day.month, day.day, time.hour, time.minute);
    }

    final day = date ?? TodoSchedule.dateOnly(fallback ?? reference);
    final parts = time ?? TodoNlTimeParts(9, 0);
    var result = DateTime(day.year, day.month, day.day, parts.hour, parts.minute);
    if (!result.isAfter(reference) && date == null && fallback == null) {
      final tomorrow = day.add(const Duration(days: 1));
      result = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        parts.hour,
        parts.minute,
      );
    }
    return result;
  }

  static TodoNlTimeParts? _buildTime({
    required String? period,
    required int hour,
    required int minute,
  }) {
    if (hour < 0 || hour > 24 || minute < 0 || minute > 59) return null;
    final h = _applyPeriod(period, hour);
    if (h == null) return null;
    return TodoNlTimeParts(h, minute);
  }

  static int? _applyPeriod(String? period, int hour) {
    if (period == null || period.isEmpty) {
      if (hour >= 1 && hour <= 6) return hour + 12;
      if (hour == 12) return 12;
      return hour <= 24 ? hour % 24 : null;
    }
    switch (period) {
      case '凌晨':
      case '清晨':
        return hour <= 5 ? hour : hour;
      case '早上':
      case '上午':
        return hour <= 12 ? hour : hour;
      case '中午':
        return hour <= 12 ? (hour == 12 ? 12 : hour + 12) : hour;
      case '下午':
      case '傍晚':
        return hour < 12 ? hour + 12 : hour;
      case '晚上':
      case '夜里':
        return hour < 12 ? hour + 12 : hour;
      default:
        return hour <= 24 ? hour % 24 : null;
    }
  }

  static int? _parseNumberToken(String token) {
    if (RegExp(r'^\d+$').hasMatch(token)) {
      return int.tryParse(token);
    }
    const map = {
      '零': 0,
      '一': 1,
      '二': 2,
      '两': 2,
      '三': 3,
      '四': 4,
      '五': 5,
      '六': 6,
      '七': 7,
      '八': 8,
      '九': 9,
      '十': 10,
      '十一': 11,
      '十二': 12,
      '十五': 15,
      '二十': 20,
      '三十': 30,
    };
    if (map.containsKey(token)) return map[token];
    if (token.length == 2 && token.startsWith('十')) {
      final tail = map[token.substring(1)];
      if (tail != null) return 10 + tail;
    }
    return null;
  }

  static int _weekdayFromToken(String token) {
    const map = {
      '一': DateTime.monday,
      '二': DateTime.tuesday,
      '三': DateTime.wednesday,
      '四': DateTime.thursday,
      '五': DateTime.friday,
      '六': DateTime.saturday,
      '日': DateTime.sunday,
      '天': DateTime.sunday,
    };
    return map[token] ?? DateTime.monday;
  }

  static String extractTaskBody(String text, List<TodoNlSpan> spans) {
    if (spans.isEmpty) return text;

    final sorted = List<TodoNlSpan>.from(spans)
      ..sort((a, b) => a.start.compareTo(b.start));

    final merged = <TodoNlSpan>[];
    for (final span in sorted) {
      if (merged.isEmpty || span.start > merged.last.end) {
        merged.add(span);
      } else if (span.end > merged.last.end) {
        merged[merged.length - 1] = TodoNlSpan(merged.last.start, span.end);
      }
    }

    final buffer = StringBuffer();
    var cursor = 0;
    for (final span in merged) {
      if (span.start > cursor) {
        buffer.write(text.substring(cursor, span.start));
      }
      cursor = span.end;
    }
    if (cursor < text.length) {
      buffer.write(text.substring(cursor));
    }
    return buffer.toString();
  }
}
