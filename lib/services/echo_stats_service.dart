import 'dart:io';

import 'package:flutter/foundation.dart';

import '../models/diary.dart';
import '../models/todo_category.dart';
import '../models/weather_mood.dart';
import '../utils/todo_schedule.dart';
import 'echo_insight_service.dart';
import 'todo_service.dart';

/// 统计期内的一张回响照片。
class EchoPhotoStat {
  const EchoPhotoStat({
    required this.path,
    required this.diaryId,
    required this.recordedAt,
    required this.moodWeather,
    required this.previewLine,
  });

  final String path;
  final String diaryId;
  final DateTime recordedAt;
  final String moodWeather;
  final String previewLine;
}

/// 照片墙上的一枚拍立得。
class EchoWallPin {
  const EchoWallPin({required this.photo});

  final EchoPhotoStat photo;

  int get layoutSeed => photo.path.hashCode;
}

/// 某一天的记录概况（用于日历 / 星座条）。
class EchoDayStat {
  const EchoDayStat({
    required this.date,
    required this.hasDiary,
    required this.entryCount,
    this.moodWeather,
    this.primaryDiaryId,
    this.diaryIds = const [],
  });

  final DateTime date;
  final bool hasDiary;
  final int entryCount;
  final String? moodWeather;
  /// 当天最新一篇回响 id（用于跳转）。
  final String? primaryDiaryId;
  final List<String> diaryIds;
}

/// 心情出现次数。
class EchoMoodStat {
  const EchoMoodStat({
    required this.display,
    required this.emoji,
    required this.label,
    required this.count,
  });

  final String display;
  final String emoji;
  final String label;
  final int count;
}

/// 待办分类完成概况。
class EchoCategoryStat {
  const EchoCategoryStat({
    required this.category,
    required this.completedCount,
    required this.scheduledCount,
  });

  final TodoCategory category;
  final int completedCount;
  final int scheduledCount;

  /// 已完成件数（兼容旧用法）。
  int get count => completedCount;

  double get completionRate {
    if (scheduledCount == 0) return completedCount > 0 ? 1 : 0;
    return (completedCount / scheduledCount).clamp(0.0, 1.0);
  }
}

/// 某周 / 某月的 Echo 统计快照。
class EchoPeriodStatistics {
  const EchoPeriodStatistics({
    required this.start,
    required this.end,
    required this.isWeekly,
    required this.days,
    required this.diaryDayCount,
    required this.diaryEntryCount,
    required this.moods,
    required this.todoCompleted,
    required this.todoScheduled,
    required this.categories,
    required this.photos,
    required this.wallPins,
    this.todoSpanLabel = '',
    this.openEnded = false,
  });

  final DateTime start;
  final DateTime end;
  final bool isWeekly;
  final List<EchoDayStat> days;
  final int diaryDayCount;
  final int diaryEntryCount;
  final List<EchoMoodStat> moods;
  final int todoCompleted;
  final int todoScheduled;
  final List<EchoCategoryStat> categories;
  final List<EchoPhotoStat> photos;
  final List<EchoWallPin> wallPins;

  /// 待办概况文案前缀，如「今日」「本周」；空则回退到周/月。
  final String todoSpanLabel;

  /// 结束日未限定（未来规划等）。
  final bool openEnded;

  int get photoCount => photos.length;

  int get periodDayCount => days.length;

  double get todoCompletionRate {
    if (todoScheduled == 0) return todoCompleted > 0 ? 1 : 0;
    return (todoCompleted / todoScheduled).clamp(0.0, 1.0);
  }

  EchoMoodStat? get dominantMood => moods.isEmpty ? null : moods.first;

  bool get hasDiaryActivity => diaryDayCount > 0;
  bool get hasTodoActivity => todoCompleted > 0 || todoScheduled > 0;
  bool get hasMoodActivity => moods.isNotEmpty;
  bool get hasPhotos => photos.isNotEmpty;

  /// 五种天象心情各占一天数（含 0 天）。
  List<EchoMoodStat> get allMoodSlots {
    final byLabel = {for (final m in moods) m.label: m};
    return [
      for (final mood in WeatherMood.options)
        byLabel[mood.label] ??
            EchoMoodStat(
              display: mood.display,
              emoji: mood.emoji,
              label: mood.label,
              count: 0,
            ),
    ];
  }

  int get totalMoodDays => moods.fold(0, (sum, m) => sum + m.count);
}

/// 从本地日记与待办聚合周 / 月统计。
class EchoStatsService {
  EchoStatsService._();

  static final EchoStatsService instance = EchoStatsService._();

  EchoPeriodStatistics currentWeek([DateTime? now]) {
    final anchor = now ?? DateTime.now();
    final start = EchoInsightService.startOfWeek(anchor);
    return weekStatistics(start);
  }

  EchoPeriodStatistics currentMonth([DateTime? now]) {
    final anchor = now ?? DateTime.now();
    return monthStatistics(anchor.year, anchor.month);
  }

  EchoPeriodStatistics weekStatistics(DateTime weekStart) {
    final start = EchoInsightService.dateOnly(weekStart);
    final end = EchoInsightService.endOfWeek(start);
    return _build(start, end, isWeekly: true);
  }

  EchoPeriodStatistics monthStatistics(int year, int month) {
    final start = EchoInsightService.startOfMonth(year, month);
    final end = EchoInsightService.endOfMonth(year, month);
    return _build(start, end, isWeekly: false);
  }

  /// 待办页：按当前时间视野（今日 / 本周 / 本月 / 未来）聚合待办统计。
  EchoPeriodStatistics todoHorizonStatistics(
    TodoTimeHorizon horizon, [
    DateTime? now,
  ]) {
    final anchor = now ?? DateTime.now();
    final range = TodoSchedule.horizonStatsRange(horizon, anchor);
    final start = range.start;
    final end = range.end;

    final scheduled = switch (horizon) {
      TodoTimeHorizon.future => TodoService.instance.activeItems(anchor).where((t) {
          final day = TodoSchedule.dateOnly(
            TodoSchedule.effectiveReminderAt(t, anchor),
          );
          return !day.isBefore(start);
        }).toList(),
      _ when end != null => TodoService.instance.scheduledInRange(start, end),
      _ => TodoService.instance
          .activeItems(anchor)
          .where((t) => TodoSchedule.horizonFor(t, anchor) == horizon)
          .toList(),
    };
    final completed = TodoService.instance.completedInRange(start, end);

    final categoryCompleted = <TodoCategory, int>{};
    final categoryScheduled = <TodoCategory, int>{};
    for (final todo in completed) {
      categoryCompleted[todo.category] =
          (categoryCompleted[todo.category] ?? 0) + 1;
    }
    for (final todo in scheduled) {
      categoryScheduled[todo.category] =
          (categoryScheduled[todo.category] ?? 0) + 1;
    }

    final categories = TodoCategory.values
        .map(
          (category) => EchoCategoryStat(
            category: category,
            completedCount: categoryCompleted[category] ?? 0,
            scheduledCount: categoryScheduled[category] ?? 0,
          ),
        )
        .where((c) => c.completedCount > 0 || c.scheduledCount > 0)
        .toList()
      ..sort((a, b) {
        final byCompleted = b.completedCount.compareTo(a.completedCount);
        if (byCompleted != 0) return byCompleted;
        return b.scheduledCount.compareTo(a.scheduledCount);
      });

    return EchoPeriodStatistics(
      start: start,
      end: end ?? start,
      isWeekly: horizon == TodoTimeHorizon.thisWeek ||
          horizon == TodoTimeHorizon.today,
      days: const [],
      diaryDayCount: 0,
      diaryEntryCount: 0,
      moods: const [],
      todoCompleted: completed.length,
      todoScheduled: scheduled.length,
      categories: categories,
      photos: const [],
      wallPins: const [],
      todoSpanLabel: TodoSchedule.horizonStatsSpanLabel(horizon),
      openEnded: end == null,
    );
  }

  EchoPeriodStatistics previousPeriod(EchoPeriodStatistics current) {
    if (current.isWeekly) {
      return weekStatistics(
        current.start.subtract(const Duration(days: 7)),
      );
    }
    final anchor = DateTime(current.start.year, current.start.month - 1);
    return monthStatistics(anchor.year, anchor.month);
  }

  EchoPeriodStatistics _build(
    DateTime start,
    DateTime end, {
    required bool isWeekly,
  }) {
    final diaries = EchoInsightService.instance.diariesInRange(start, end);
    final days = _buildDays(start, end, diaries);
    final moods = _buildMoods(diaries);
    final photos = _buildPhotos(diaries);
    final wallPins = _buildWallPins(photos);
    final completed = TodoService.instance.completedInRange(start, end);
    final scheduled = TodoService.instance.scheduledInRange(start, end);

    final categoryCompleted = <TodoCategory, int>{};
    final categoryScheduled = <TodoCategory, int>{};
    for (final todo in completed) {
      categoryCompleted[todo.category] =
          (categoryCompleted[todo.category] ?? 0) + 1;
    }
    for (final todo in scheduled) {
      categoryScheduled[todo.category] =
          (categoryScheduled[todo.category] ?? 0) + 1;
    }

    final categories = TodoCategory.values
        .map(
          (category) => EchoCategoryStat(
            category: category,
            completedCount: categoryCompleted[category] ?? 0,
            scheduledCount: categoryScheduled[category] ?? 0,
          ),
        )
        .where((c) => c.completedCount > 0 || c.scheduledCount > 0)
        .toList()
      ..sort((a, b) {
        final byCompleted = b.completedCount.compareTo(a.completedCount);
        if (byCompleted != 0) return byCompleted;
        return b.scheduledCount.compareTo(a.scheduledCount);
      });

    return EchoPeriodStatistics(
      start: start,
      end: end,
      isWeekly: isWeekly,
      days: days,
      diaryDayCount: days.where((d) => d.hasDiary).length,
      diaryEntryCount: diaries.length,
      moods: moods,
      todoCompleted: completed.length,
      todoScheduled: scheduled.length,
      categories: categories,
      photos: photos,
      wallPins: wallPins,
    );
  }

  List<EchoDayStat> _buildDays(
    DateTime start,
    DateTime end,
    List<Diary> diaries,
  ) {
    final byDate = <DateTime, List<Diary>>{};
    for (final diary in diaries) {
      final day = EchoInsightService.dateOnly(diary.createdAt);
      byDate.putIfAbsent(day, () => []).add(diary);
    }

    final days = <EchoDayStat>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      final entries = byDate[cursor] ?? [];
      String? mood;
      if (entries.isNotEmpty) {
        entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        mood = WeatherMood.resolveDisplay(entries.first.moodWeather);
      }
      days.add(
        EchoDayStat(
          date: cursor,
          hasDiary: entries.isNotEmpty,
          entryCount: entries.length,
          moodWeather: mood,
          primaryDiaryId: entries.isNotEmpty ? entries.first.id : null,
          diaryIds: entries.map((e) => e.id).toList(),
        ),
      );
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  List<EchoMoodStat> _buildMoods(List<Diary> diaries) {
    final freq = <String, int>{};
    for (final diary in diaries) {
      final mood = WeatherMood.resolveDisplay(diary.moodWeather);
      freq[mood] = (freq[mood] ?? 0) + 1;
    }

    final stats = freq.entries.map((entry) {
      final parsed = WeatherMood.fromDisplay(entry.key);
      return EchoMoodStat(
        display: entry.key,
        emoji: parsed?.emoji ?? entry.key.split(' ').first,
        label: parsed?.label ?? entry.key,
        count: entry.value,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));

    return stats;
  }

  List<EchoPhotoStat> _buildPhotos(List<Diary> diaries) {
    final sorted = List<Diary>.from(diaries)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final photos = <EchoPhotoStat>[];
    for (final diary in sorted) {
      for (final path in diary.images) {
        if (!kIsWeb && !File(path).existsSync()) continue;
        photos.add(
          EchoPhotoStat(
            path: path,
            diaryId: diary.id,
            recordedAt: diary.createdAt,
            moodWeather: WeatherMood.resolveDisplay(diary.moodWeather),
            previewLine: _previewLine(diary.content),
          ),
        );
      }
    }
    return photos;
  }

  String _previewLine(String content) {
    final line = content.split('\n').first.trim();
    if (line.isEmpty) return '这一篇还没有文字';
    if (line.length <= 40) return line;
    return '${line.substring(0, 40)}…';
  }

  List<EchoWallPin> _buildWallPins(List<EchoPhotoStat> photos) {
    return photos.map((photo) => EchoWallPin(photo: photo)).toList();
  }
}
