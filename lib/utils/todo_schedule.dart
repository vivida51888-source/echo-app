import 'package:flutter/material.dart';

import '../models/todo_reminder.dart';
import '../services/echo_insight_service.dart';
import 'china_workday_calendar.dart';

/// 待办列表时间分组（卡片内细粒度）。
enum TodoTimeGroup {
  expired('还在等你'),
  today('今天'),
  tomorrow('明天'),
  thisWeek('本周'),
  later('更晚');

  const TodoTimeGroup(this.label);
  final String label;
}

/// 待办页顶栏时间视野（互斥四档）。
enum TodoTimeHorizon {
  today('今日'),
  thisWeek('本周'),
  thisMonth('本月'),
  future('未来');

  const TodoTimeHorizon(this.label);
  final String label;

  static const displayOrder = [
    TodoTimeHorizon.today,
    TodoTimeHorizon.thisWeek,
    TodoTimeHorizon.thisMonth,
    TodoTimeHorizon.future,
  ];

  /// 顶栏与视野带的主题色。
  static Color accentFor(TodoTimeHorizon horizon) => switch (horizon) {
        TodoTimeHorizon.today => const Color(0xFF6FAF82),
        TodoTimeHorizon.thisWeek => const Color(0xFF6B8CAE),
        TodoTimeHorizon.thisMonth => const Color(0xFFB8956A),
        TodoTimeHorizon.future => const Color(0xFF9B87C4),
      };
}

abstract final class TodoSchedule {
  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// 统计弹层与顶栏导航的日期区间（本周 = 自然周周一至周日，与回响统计一致）。
  static ({DateTime start, DateTime? end}) horizonStatsRange(
    TodoTimeHorizon horizon,
    DateTime now,
  ) {
    final today = dateOnly(now);
    final weekStart = dateOnly(EchoInsightService.startOfWeek(now));
    final weekEnd = dateOnly(EchoInsightService.endOfWeek(weekStart));
    final monthEnd = dateOnly(EchoInsightService.endOfMonth(now.year, now.month));

    return switch (horizon) {
      TodoTimeHorizon.today => (start: today, end: today),
      TodoTimeHorizon.thisWeek => (start: weekStart, end: weekEnd),
      TodoTimeHorizon.thisMonth => (
          start: weekEnd.add(const Duration(days: 1)),
          end: monthEnd,
        ),
      TodoTimeHorizon.future => (
          start: _addMonthsDateOnly(today, 1),
          end: null,
        ),
    };
  }

  static String horizonStatsTitle(TodoTimeHorizon horizon) => switch (horizon) {
        TodoTimeHorizon.today => '今日概况',
        TodoTimeHorizon.thisWeek => '本周概况',
        TodoTimeHorizon.thisMonth => '本月概况',
        TodoTimeHorizon.future => '未来概况',
      };

  static String horizonStatsSpanLabel(TodoTimeHorizon horizon) =>
      horizon.label;

  static String horizonStatsRangeLabel(TodoTimeHorizon horizon, DateTime now) {
    final range = horizonStatsRange(horizon, now);
    final start = range.start;
    final end = range.end;

    if (end != null && start.isAfter(end)) {
      return switch (horizon) {
        TodoTimeHorizon.thisWeek => '本周暂无更多安排',
        TodoTimeHorizon.thisMonth => '${now.month} 月 · 暂无更多',
        _ => '${start.month} 月 ${start.day} 日',
      };
    }
    if (end != null && isSameDay(start, end)) {
      return '${start.month} 月 ${start.day} 日';
    }
    if (end != null) {
      return '${start.month} 月 ${start.day} 日 – ${end.month} 月 ${end.day} 日';
    }
    return '自 ${start.year} 年 ${start.month} 月 ${start.day} 日起';
  }

  static DateTime _addMonthsDateOnly(DateTime day, int months) {
    var month = day.month + months;
    var year = day.year;
    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.day.clamp(1, lastDay);
    return DateTime(year, month, safeDay);
  }

  /// 今晚 22:00；若已过则排到明晚。
  static DateTime tonightAt(DateTime now) {
    var target = DateTime(now.year, now.month, now.day, 22, 0);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  /// 明天早上 9:00。
  static DateTime tomorrowMorning(DateTime now) {
    final day = dateOnly(now).add(const Duration(days: 1));
    return DateTime(day.year, day.month, day.day, 9, 0);
  }

  /// 本周六 10:00（若已是周六且已过，则下周六）。
  static DateTime weekendMorning(DateTime now) {
    final today = dateOnly(now);
    final daysUntilSaturday = (DateTime.saturday - today.weekday + 7) % 7;
    var day = today.add(Duration(days: daysUntilSaturday));
    var target = DateTime(day.year, day.month, day.day, 10, 0);
    if (!target.isAfter(now)) {
      day = day.add(const Duration(days: 7));
      target = DateTime(day.year, day.month, day.day, 10, 0);
    }
    return target;
  }

  static DateTime after(DateTime now, Duration offset) => now.add(offset);

  static DateTime nextOccurrence(TodoReminder todo, {required DateTime after}) {
    if (todo.repeat == TodoRepeat.none) return todo.reminderAt;

    switch (todo.repeat) {
      case TodoRepeat.none:
        return todo.reminderAt;
      case TodoRepeat.workday:
        if (ChinaWorkdayCalendar.isWorkday(todo.reminderAt) &&
            todo.reminderAt.isAfter(after)) {
          return todo.reminderAt;
        }
        return ChinaWorkdayCalendar.nextOccurrenceAfter(
          after,
          hour: todo.reminderAt.hour,
          minute: todo.reminderAt.minute,
        );
      case TodoRepeat.daily:
        var next = todo.reminderAt;
        while (!next.isAfter(after)) {
          next = next.add(const Duration(days: 1));
        }
        return next;
      case TodoRepeat.alternateDay:
        var next = todo.reminderAt;
        while (!next.isAfter(after)) {
          next = next.add(const Duration(days: 2));
        }
        return next;
      case TodoRepeat.weekly:
        var next = todo.reminderAt;
        while (!next.isAfter(after)) {
          next = next.add(const Duration(days: 7));
        }
        return next;
      case TodoRepeat.monthly:
        var next = todo.reminderAt;
        while (!next.isAfter(after)) {
          next = _addMonthsKeepingDay(
            next,
            1,
            day: todo.reminderAt.day,
            hour: todo.reminderAt.hour,
            minute: todo.reminderAt.minute,
          );
        }
        return next;
    }
  }

  static DateTime _addMonthsKeepingDay(
    DateTime from,
    int months, {
    required int day,
    required int hour,
    required int minute,
  }) {
    var month = from.month + months;
    var year = from.year;
    while (month > 12) {
      month -= 12;
      year++;
    }
    while (month < 1) {
      month += 12;
      year--;
    }
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, lastDay);
    return DateTime(year, month, safeDay, hour, minute);
  }

  /// 当月最后一天 [hour]:[minute]；若已过则取下月最后一天。
  static DateTime endOfMonthAt(
    DateTime reference, {
    int hour = 18,
    int minute = 0,
  }) {
    var year = reference.year;
    var month = reference.month;
    var target = DateTime(year, month + 1, 0, hour, minute);
    if (!target.isAfter(reference)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      target = DateTime(year, month + 1, 0, hour, minute);
    }
    return target;
  }

  /// 某 weekday 当日 [hour]:[minute]；若已过则取下一周。
  static DateTime weekdayAt(
    DateTime reference,
    int weekday, {
    int hour = 18,
    int minute = 0,
  }) {
    final today = dateOnly(reference);
    final delta = (weekday - today.weekday + 7) % 7;
    var day = today.add(Duration(days: delta));
    var target = DateTime(day.year, day.month, day.day, hour, minute);
    if (!target.isAfter(reference)) {
      day = day.add(const Duration(days: 7));
      target = DateTime(day.year, day.month, day.day, hour, minute);
    }
    return target;
  }

  /// 每月 [dayOfMonth] 日 [hour]:[minute]；若本月已过则取下月。
  static DateTime monthlyOnDay(
    DateTime reference,
    int dayOfMonth, {
    int hour = 9,
    int minute = 0,
  }) {
    var year = reference.year;
    var month = reference.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = dayOfMonth.clamp(1, lastDay);
    var target = DateTime(year, month, safeDay, hour, minute);
    if (!target.isAfter(reference)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      final nextLast = DateTime(year, month + 1, 0).day;
      final nextDay = dayOfMonth.clamp(1, nextLast);
      target = DateTime(year, month, nextDay, hour, minute);
    }
    return target;
  }

  static TodoTimeGroup groupFor(TodoReminder todo, DateTime now) {
    if (todo.isDoneForDisplay(now) && todo.repeat != TodoRepeat.none) {
      return TodoTimeGroup.today;
    }

    if (!todo.isDoneForDisplay(now) && todo.isExpired(now)) {
      return TodoTimeGroup.expired;
    }

    final reminderDay = dateOnly(todo.reminderAt);
    final today = dateOnly(now);
    final tomorrow = today.add(const Duration(days: 1));
    final weekEnd = dateOnly(
      EchoInsightService.endOfWeek(EchoInsightService.startOfWeek(now)),
    );

    if (isSameDay(reminderDay, today)) return TodoTimeGroup.today;
    if (isSameDay(reminderDay, tomorrow)) return TodoTimeGroup.tomorrow;
    if (!reminderDay.isAfter(weekEnd)) return TodoTimeGroup.thisWeek;
    return TodoTimeGroup.later;
  }

  static Map<TodoTimeGroup, List<TodoReminder>> groupActive(
    List<TodoReminder> items,
    DateTime now,
  ) {
    final map = {
      for (final g in TodoTimeGroup.values) g: <TodoReminder>[],
    };

    for (final todo in items) {
      map[groupFor(todo, now)]!.add(todo);
    }

    for (final list in map.values) {
      list.sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
    }

    return map;
  }

  static const displayOrder = [
    TodoTimeGroup.expired,
    TodoTimeGroup.today,
    TodoTimeGroup.tomorrow,
    TodoTimeGroup.thisWeek,
    TodoTimeGroup.later,
  ];

  /// 列表展示用的有效提醒时刻（重复项今日已安放 → 下次 occurrence）。
  static DateTime effectiveReminderAt(TodoReminder todo, DateTime now) {
    if (todo.isDoneForDisplay(now) && todo.repeat != TodoRepeat.none) {
      return nextOccurrence(todo, after: now);
    }
    return todo.reminderAt;
  }

  static TodoTimeHorizon horizonFor(TodoReminder todo, DateTime now) {
    if (!todo.isDoneForDisplay(now) && todo.isExpired(now)) {
      return TodoTimeHorizon.today;
    }
    return horizonForDate(dateOnly(effectiveReminderAt(todo, now)), now);
  }

  static TodoTimeHorizon horizonForDate(DateTime day, DateTime now) {
    final today = dateOnly(now);
    final weekStart = dateOnly(EchoInsightService.startOfWeek(now));
    final weekEnd = dateOnly(EchoInsightService.endOfWeek(weekStart));
    final monthEnd = dateOnly(EchoInsightService.endOfMonth(now.year, now.month));

    if (!day.isAfter(today)) {
      return TodoTimeHorizon.today;
    }
    if (!day.isAfter(weekEnd)) {
      return TodoTimeHorizon.thisWeek;
    }
    if (!day.isAfter(monthEnd)) {
      return TodoTimeHorizon.thisMonth;
    }
    return TodoTimeHorizon.future;
  }

  static List<TodoReminder> filterByHorizon(
    List<TodoReminder> items,
    TodoTimeHorizon horizon,
    DateTime now,
  ) {
    return items
        .where((todo) => horizonFor(todo, now) == horizon)
        .toList()
      ..sort((a, b) => effectiveReminderAt(a, now).compareTo(
            effectiveReminderAt(b, now),
          ));
  }

  static Map<TodoTimeHorizon, int> countByHorizon(
    List<TodoReminder> items,
    DateTime now,
  ) {
    final counts = {
      for (final h in TodoTimeHorizon.displayOrder) h: 0,
    };
    for (final todo in items) {
      counts[horizonFor(todo, now)] = counts[horizonFor(todo, now)]! + 1;
    }
    return counts;
  }

  /// 顶栏当前视野的说明文案（与 [horizonStatsRangeLabel] 一致）。
  static String horizonSubtitle(TodoTimeHorizon horizon, DateTime now) {
    if (horizon == TodoTimeHorizon.future) {
      return '${horizonStatsRangeLabel(horizon, now)} · 规划与目标';
    }
    return horizonStatsRangeLabel(horizon, now);
  }

  /// 「未来」视野下按月份分组键（yyyy-MM）。
  static String monthGroupKey(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}';

  static String monthGroupLabel(String key) {
    final parts = key.split('-');
    if (parts.length != 2) return key;
    return '${parts[0]} 年 ${int.parse(parts[1])} 月';
  }
}
