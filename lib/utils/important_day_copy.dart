import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/important_day.dart';

/// 重要日展示与通知文案。
abstract final class ImportantDayCopy {
  static const pageTitle = '印记 · 重要日';
  static const pageSubtitle = '待来日看倒计时，起点日看累计';
  static const anchorSectionTitle = '起点日';
  static const anchorSectionSubtitle = '从选定日期起累计';
  static const anchorMetricLabel = '累计';
  static const annualSectionTitle = '待来日';
  static const annualSectionSubtitle = '距下次还有';
  static const annualHighlight = '还有';
  static const notificationTitle = 'Echo 记得';
  static const notificationChannelName = '印记提醒';
  static const notificationChannelDescription =
      '重要日前后，Echo 会轻轻唤起，不催促，只陪伴';

  static const remindOptions = <int, String>{
    0: '当天',
    1: '提前 1 天',
    3: '提前 3 天',
    7: '提前 7 天',
  };

  /// 起点日 · 已发生：暖绿调。
  static const anchorSectionTint = Color(0xFFE6EFE8);
  static const anchorCardTint = Color(0xFFF2F7F3);

  /// 待来日 · 尚未到来：淡雾蓝。
  static const annualSectionTint = Color(0xFFE8ECF3);
  static const annualCardTint = Color(0xFFF4F6FA);

  static String dateLabel(ImportantDay day) {
    if (day.isAnchor || day.startYear != null) {
      return '${day.startYear} 年 ${day.month} 月 ${day.day} 日';
    }
    return '每年 ${day.month} 月 ${day.day} 日';
  }

  static String anchorMilestoneHint(ImportantDayKind kind) {
    if (kind.isRomantic) {
      return '满 52 / 99 / 520 / 1314 天，以及每年整，早上 9:00 提醒';
    }
    return '满 100 天，以及每年整，早上 9:00 提醒';
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
      suffix: '天',
    );
  }

  static String listDetailLine(ImportantDay day, [DateTime? now]) {
    if (day.isAnchor) {
      final start = day.anchorStart;
      if (start == null) return day.kind.label;
      final y = start.year.toString();
      final m = start.month.toString().padLeft(2, '0');
      final d = start.day.toString().padLeft(2, '0');
      return '始于 $y.$m.$d · ${day.kind.label}';
    }
    return '每年 ${day.month} 月 ${day.day} 日 · ${day.kind.label}';
  }

  static String? listWhisperLine(ImportantDay day, [DateTime? now]) {
    if (day.isAnchor) {
      final hit = day.milestoneOn(now);
      if (hit != null) return '今天 · ${milestoneShortLabel(hit)}';
      final next = day.nextMilestone(now);
      if (next == null) return null;
      final until = day.daysUntil(now);
      return '距${milestoneShortLabel(next)}还有 $until 天';
    }
    return null;
  }

  static String milestoneShortLabel(ImportantDayMilestoneHit hit) {
    if (hit.dayCount != null) return '满 ${hit.dayCount} 天';
    if (hit.yearCount != null) return '满 ${hit.yearCount} 年';
    return '';
  }

  static String countdownLabel(ImportantDay day, [DateTime? now]) {
    final days = day.daysUntil(now);
    if (days == 0) return '就是今天';
    if (days == 1) return '明天';
    return '还有 $days 天';
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
      return '今天是「${day.title}」的生日。';
    }
    if (years != null && years > 1) {
      return '今天是「${day.title}」的第 $years 年。';
    }
    return '今天是「${day.title}」—— 一个被 Echo 轻轻记得的日子。';
  }

  static String homeWhisperAdvance(ImportantDay day, int daysUntil) {
    final label = day.kind == ImportantDayKind.birthday
        ? '「${day.title}」的生日'
        : '「${day.title}」';

    if (daysUntil == 1) return '明天是$label。';
    if (daysUntil == 3) return '三天后是$label。';
    if (daysUntil == 7) return '七天后是$label。';
    return '$daysUntil天后是$label。';
  }

  static String homeWhisperMilestone(
    ImportantDay day,
    ImportantDayMilestoneHit hit,
  ) {
    final title = day.title;
    if (hit.dayCount != null) {
      return '「$title」今天满 ${hit.dayCount} 天了。';
    }
    if (hit.yearCount != null) {
      return '「$title」今天满 ${hit.yearCount} 年了。';
    }
    return '「$title」—— 一个值得被 Echo 轻轻记得的刻度。';
  }

  static String notificationBody(ImportantDay day, int daysBefore) {
    final title = day.title;
    final years = day.yearsSince(
      DateTime(DateTime.now().year, day.month, day.day),
    );

    if (daysBefore == 0) {
      if (day.kind == ImportantDayKind.birthday) {
        return '今天是「$title」的生日。若想留些什么，Echo 在这里。';
      }
      if (years != null && years > 1) {
        return '今天是「$title」的第 $years 年。';
      }
      return '今天是「$title」。若想留些什么，Echo 在这里。';
    }
    if (daysBefore == 1) {
      return '明天就是「$title」了。';
    }
    if (daysBefore == 3) {
      return '还有三天，就是「$title」。';
    }
    if (daysBefore == 7) {
      return '还有一周，到了「$title」。';
    }
    return '快到了「$title」的日子。';
  }

  static String notificationBodyMilestone(
    ImportantDay day,
    ImportantDayMilestoneHit hit,
  ) {
    final title = day.title;
    if (hit.dayCount != null) {
      return '「$title」今天满 ${hit.dayCount} 天了。若想留些什么，Echo 在这里。';
    }
    if (hit.yearCount != null) {
      return '「$title」今天满 ${hit.yearCount} 年了。';
    }
    return '「$title」到了一个新的刻度。';
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
