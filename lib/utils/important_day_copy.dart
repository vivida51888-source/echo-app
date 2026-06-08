import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/localized.dart';
import '../models/important_day.dart';
import '../theme/echo_colors.dart';

/// 重要日展示与通知文案。
abstract final class ImportantDayCopy {
  static String get pageTitle =>
      tr('印记 · 重要日', 'Marks · Important days');
  static String get pageSubtitle => tr(
        '待来日看倒计时，起点日看累计',
        'Upcoming: countdown · Since: elapsed',
      );
  static String get anchorSectionTitle => tr('起点日', 'Since');
  static String get anchorSectionSubtitle =>
      tr('从选定日期起累计', 'Count from a start date');
  static String get anchorMetricLabel => tr('累计', 'Elapsed');
  static String get annualSectionTitle => tr('待来日', 'Upcoming');
  static String get annualSectionSubtitle =>
      tr('距下次还有', 'Until next');
  static String get annualHighlight => tr('还有', 'In');
  static String get notificationTitle => tr('Echo 记得', 'Echo remembers');
  static String get notificationChannelName =>
      tr('印记提醒', 'Mark reminders');
  static String get notificationChannelDescription => tr(
        '重要日前后，Echo 会轻轻唤起，不催促，只陪伴',
        'Echo gently reminds you around important days',
      );

  static Map<int, String> get remindOptions => {
        0: tr('当天', 'On the day'),
        1: tr('提前 1 天', '1 day before'),
        3: tr('提前 3 天', '3 days before'),
        7: tr('提前 7 天', '7 days before'),
      };

  /// 起点日 · 已发生：暖绿调。
  static Color get anchorSectionTint => EchoColors.isDark
      ? const Color(0xFF1E2A22)
      : const Color(0xFFE6EFE8);
  static Color get anchorCardTint => EchoColors.isDark
      ? const Color(0xFF242C26)
      : const Color(0xFFF2F7F3);

  /// 待来日 · 尚未到来：淡雾蓝。
  static Color get annualSectionTint => EchoColors.isDark
      ? const Color(0xFF1E242C)
      : const Color(0xFFE8ECF3);
  static Color get annualCardTint => EchoColors.isDark
      ? const Color(0xFF242830)
      : const Color(0xFFF4F6FA);

  static Color get anchorAccent => EchoColors.isDark
      ? EchoColors.todoCompletedFill
      : const Color(0xFF6FAF82);
  static Color get annualAccent => EchoColors.isDark
      ? const Color(0xFF8AA8C8)
      : const Color(0xFF7A8FA8);
  static Color get anchorHighlightTint => EchoColors.isDark
      ? EchoColors.todoCompletedFill
      : const Color(0xFF5F9B72);
  static Color get annualHighlightTint => EchoColors.isDark
      ? const Color(0xFF8AA8C8)
      : const Color(0xFF6B7F9C);

  static String dateLabel(ImportantDay day) {
    if (day.isAnchor || day.startYear != null) {
      return tr(
        '${day.startYear} 年 ${day.month} 月 ${day.day} 日',
        "${day.startYear}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}",
      );
    }
    return tr('每年 ${day.month} 月 ${day.day} 日', 'Every year · ${day.month}/${day.day}');
  }

  static String anchorMilestoneHint(ImportantDayKind kind) {
    if (kind.isRomantic) {
      return tr(
        '满 52 / 99 / 520 / 1314 天，以及每年整，早上 9:00 提醒',
        'Days 52 / 99 / 520 / 1314 & yearly anniversaries · 9:00 AM',
      );
    }
    return tr(
      '满 100 天，以及每年整，早上 9:00 提醒',
      'Day 100 & yearly anniversaries · 9:00 AM',
    );
  }

  static ImportantDayListMetric listMetric(ImportantDay day, [DateTime? now]) {
    if (day.isAnchor) {
      final parts = day.elapsedParts(now);
      final elapsed = day.daysElapsed(now);
      if (parts == null || elapsed == null) {
        return const ImportantDayListMetric.word('—');
      }
      if (parts.years >= 1) {
        return ImportantDayListMetric.duration(
          years: parts.years,
          days: parts.days,
        );
      }
      return ImportantDayListMetric.days(elapsed);
    }

    final until = day.daysUntil(now);
    return ImportantDayListMetric.countdown(
      count: until,
      suffix: tr('天', 'd'),
    );
  }

  static String listDetailLine(ImportantDay day, [DateTime? now]) {
    if (day.isAnchor) {
      final start = day.anchorStart;
      if (start == null) return day.kind.localizedLabel;
      final y = start.year.toString();
      final m = start.month.toString().padLeft(2, '0');
      final d = start.day.toString().padLeft(2, '0');
      return tr('始于 $y.$m.$d · ${day.kind.localizedLabel}', 'Since $y.$m.$d · ${day.kind.localizedLabel}');
    }
    return tr('每年 ${day.month} 月 ${day.day} 日 · ${day.kind.localizedLabel}', 'Every ${day.month}/${day.day} · ${day.kind.localizedLabel}');
  }

  static String? listWhisperLine(ImportantDay day, [DateTime? now]) {
    if (day.isAnchor) {
      final hit = day.milestoneOn(now);
      if (hit != null) {
        return tr('今天 · ${milestoneShortLabel(hit)}', 'Today · ${milestoneShortLabel(hit)}');
      }
      final next = day.nextMilestone(now);
      if (next == null) return null;
      final until = day.daysUntil(now);
      return tr('距${milestoneShortLabel(next)}还有 $until 天', '$until d until ${milestoneShortLabel(next)}');
    }
    return null;
  }

  static String milestoneShortLabel(ImportantDayMilestoneHit hit) {
    if (hit.dayCount != null) {
      return tr('满 ${hit.dayCount} 天', 'Day ${hit.dayCount}');
    }
    if (hit.yearCount != null) {
      return tr('满 ${hit.yearCount} 年', 'Year ${hit.yearCount}');
    }
    return '';
  }

  static String countdownLabel(ImportantDay day, [DateTime? now]) {
    final days = day.daysUntil(now);
    if (days == 0) return tr('就是今天', 'Today');
    if (days == 1) return tr('明天', 'Tomorrow');
    return tr('还有 $days 天', 'In $days days');
  }

  static String? homeWhisper(ImportantDay day, [DateTime? now]) {
    if (day.isAnchor) {
      final hit = day.milestoneOn(now);
      if (hit != null) return homeWhisperMilestone(day, hit);
      return null;
    }
    if (!day.isToday(now)) return null;

    final years = day.yearsSince(now);
    if (day.kind == ImportantDayKind.birthday) {
      return tr('今天是「${day.title}」的生日。', 'Today is «${day.title}»\'s birthday.');
    }
    if (years != null && years > 1) {
      return tr('今天是「${day.title}」的第 $years 年。', 'Today marks year $years of «${day.title}».');
    }
    return tr(
      '今天是「${day.title}」—— 一个被 Echo 轻轻记得的日子。',
      'Today is «${day.title}» — a day Echo gently remembers.',
    );
  }

  static String homeWhisperAdvance(ImportantDay day, int daysUntil) {
    final label = day.kind == ImportantDayKind.birthday
        ? (tr('「${day.title}」的生日', '«${day.title}»\'s birthday'))
        : (tr('「${day.title}」', '«${day.title}»'));

    if (daysUntil == 1) {
      return tr('明天是$label。', 'Tomorrow is $label.');
    }
    if (daysUntil == 3) {
      return tr('三天后是$label。', 'In three days: $label.');
    }
    if (daysUntil == 7) {
      return tr('七天后是$label。', 'In seven days: $label.');
    }
    return tr('$daysUntil天后是$label。', 'In $daysUntil days: $label.');
  }

  static String homeWhisperMilestone(
    ImportantDay day,
    ImportantDayMilestoneHit hit,
  ) {
    final title = day.title;
    if (hit.dayCount != null) {
      return tr('「$title」今天满 ${hit.dayCount} 天了。', '«$title» reaches day ${hit.dayCount} today.');
    }
    if (hit.yearCount != null) {
      return tr('「$title」今天满 ${hit.yearCount} 年了。', '«$title» reaches year ${hit.yearCount} today.');
    }
    return tr(
      '「$title」—— 一个值得被 Echo 轻轻记得的刻度。',
      '«$title» — a milestone worth remembering.',
    );
  }

  static String notificationBody(ImportantDay day, int daysBefore) {
    final title = day.title;
    final years = day.yearsSince(
      DateTime(DateTime.now().year, day.month, day.day),
    );

    if (daysBefore == 0) {
      if (day.kind == ImportantDayKind.birthday) {
        return tr(
          '今天是「$title」的生日。若想留些什么，Echo 在这里。',
          'Today is «$title»\'s birthday. Echo is here if you want to write.',
        );
      }
      if (years != null && years > 1) {
        return tr('今天是「$title」的第 $years 年。', 'Today is year $years of «$title».');
      }
      return tr(
        '今天是「$title」。若想留些什么，Echo 在这里。',
        'Today is «$title». Echo is here if you want to write.',
      );
    }
    if (daysBefore == 1) {
      return tr('明天就是「$title」了。', 'Tomorrow is «$title».');
    }
    if (daysBefore == 3) {
      return tr('还有三天，就是「$title」。', 'Three days until «$title».');
    }
    if (daysBefore == 7) {
      return tr('还有一周，到了「$title」。', 'One week until «$title».');
    }
    return tr('快到了「$title」的日子。', '«$title» is coming up soon.');
  }

  static String notificationBodyMilestone(
    ImportantDay day,
    ImportantDayMilestoneHit hit,
  ) {
    final title = day.title;
    if (hit.dayCount != null) {
      return tr(
        '「$title」今天满 ${hit.dayCount} 天了。若想留些什么，Echo 在这里。',
        '«$title» reaches day ${hit.dayCount} today. Echo is here if you want to write.',
      );
    }
    if (hit.yearCount != null) {
      return tr(
        '「$title」今天满 ${hit.yearCount} 年了。若想留些什么，Echo 在这里。',
        '«$title» reaches year ${hit.yearCount} today. Echo is here if you want to write.',
      );
    }
    return tr(
      '「$title」到了一个新的刻度。',
      '«$title» has reached a new milestone.',
    );
  }

  static String milestoneSlot(ImportantDayMilestoneHit hit) {
    if (hit.dayCount != null) return 'd${hit.dayCount}';
    if (hit.yearCount != null) return 'y${hit.yearCount}';
    return 'x';
  }
}

enum ImportantDayMetricStyle { word, days, duration, countdown }

class ImportantDayListMetric {
  const ImportantDayListMetric._({
    required this.style,
    this.word,
    this.days,
    this.years,
    this.durationDays,
    this.caption,
  });

  const ImportantDayListMetric.word(String value)
      : this._(style: ImportantDayMetricStyle.word, word: value);

  const ImportantDayListMetric.days(int count)
      : this._(style: ImportantDayMetricStyle.days, days: count);

  const ImportantDayListMetric.duration({
    required int years,
    required int days,
  }) : this._(
          style: ImportantDayMetricStyle.duration,
          years: years,
          durationDays: days,
        );

  const ImportantDayListMetric.countdown({
    required int count,
    required String suffix,
  }) : this._(
          style: ImportantDayMetricStyle.countdown,
          days: count,
          caption: suffix,
        );

  final ImportantDayMetricStyle style;
  final String? word;
  final int? days;
  final int? years;
  final int? durationDays;
  final String? caption;
}
