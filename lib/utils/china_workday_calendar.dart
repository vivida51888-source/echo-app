/// 中国法定节假日与调休工作日（国务院公布安排）。
///
/// 已内置 2024–2026 年数据；未覆盖年份仅按周一至周五判断。
abstract final class ChinaWorkdayCalendar {
  static const _supportedYears = {2024, 2025, 2026};

  /// 全体公民放假的日期（含落在工作日的法定假日）。
  static const _holidays = {
    // 2024
    '2024-01-01',
    '2024-02-10', '2024-02-11', '2024-02-12', '2024-02-13',
    '2024-02-14', '2024-02-15', '2024-02-16', '2024-02-17',
    '2024-04-04', '2024-04-05', '2024-04-06',
    '2024-05-01', '2024-05-02', '2024-05-03', '2024-05-04', '2024-05-05',
    '2024-06-10',
    '2024-09-15', '2024-09-16', '2024-09-17',
    '2024-10-01', '2024-10-02', '2024-10-03', '2024-10-04',
    '2024-10-05', '2024-10-06', '2024-10-07',
    // 2025
    '2025-01-01',
    '2025-01-28', '2025-01-29', '2025-01-30', '2025-01-31',
    '2025-02-01', '2025-02-02', '2025-02-03', '2025-02-04',
    '2025-04-04', '2025-04-05', '2025-04-06',
    '2025-05-01', '2025-05-02', '2025-05-03', '2025-05-04', '2025-05-05',
    '2025-05-31', '2025-06-01', '2025-06-02',
    '2025-10-01', '2025-10-02', '2025-10-03', '2025-10-04',
    '2025-10-05', '2025-10-06', '2025-10-07', '2025-10-08',
    // 2026
    '2026-01-01', '2026-01-02', '2026-01-03',
    '2026-02-15', '2026-02-16', '2026-02-17', '2026-02-18', '2026-02-19',
    '2026-02-20', '2026-02-21', '2026-02-22', '2026-02-23',
    '2026-04-04', '2026-04-05', '2026-04-06',
    '2026-05-01', '2026-05-02', '2026-05-03', '2026-05-04', '2026-05-05',
    '2026-06-19', '2026-06-20', '2026-06-21',
    '2026-09-25', '2026-09-26', '2026-09-27',
    '2026-10-01', '2026-10-02', '2026-10-03', '2026-10-04',
    '2026-10-05', '2026-10-06', '2026-10-07',
  };

  /// 调休上班日（通常是周末）。
  static const _extraWorkdays = {
    // 2024
    '2024-02-04', '2024-02-18',
    '2024-04-28', '2024-05-11',
    '2024-09-29', '2024-10-12',
    // 2025
    '2025-01-26', '2025-02-08',
    '2025-04-27',
    '2025-09-28', '2025-10-11',
    // 2026
    '2026-01-04',
    '2026-02-14', '2026-02-28',
    '2026-05-09',
    '2026-09-20',
    '2026-10-10',
  };

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String _key(DateTime d) {
    final day = dateOnly(d);
    return '${day.year}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  static bool _hasYearData(int year) => _supportedYears.contains(year);

  /// 是否为工作日（含调休上班，排除周末与法定假日）。
  static bool isWorkday(DateTime date) {
    final key = _key(date);
    if (_extraWorkdays.contains(key)) return true;
    if (_holidays.contains(key)) return false;

    if (_hasYearData(date.year)) {
      final weekday = date.weekday;
      return weekday >= DateTime.monday && weekday <= DateTime.friday;
    }

    // 未收录年份：仅按周一至周五。
    final weekday = date.weekday;
    return weekday >= DateTime.monday && weekday <= DateTime.friday;
  }

  /// 将提醒时间落在最近的工作日（保留时分）。
  static DateTime ensureWorkdayReminder(DateTime reminderAt, {DateTime? now}) {
    final anchor = now ?? DateTime.now();
    if (isWorkday(reminderAt) && reminderAt.isAfter(anchor)) {
      return reminderAt;
    }
    return nextOccurrenceAfter(
      anchor,
      hour: reminderAt.hour,
      minute: reminderAt.minute,
    );
  }

  /// 严格晚于 [after] 的下一个工作提醒时刻。
  static DateTime nextOccurrenceAfter(
    DateTime after, {
    required int hour,
    required int minute,
  }) {
    var day = dateOnly(after);
    for (var i = 0; i < 400; i++) {
      if (isWorkday(day)) {
        final candidate = DateTime(day.year, day.month, day.day, hour, minute);
        if (candidate.isAfter(after)) return candidate;
      }
      day = day.add(const Duration(days: 1));
    }
    return DateTime(after.year, after.month, after.day, hour, minute)
        .add(const Duration(days: 1));
  }
}
