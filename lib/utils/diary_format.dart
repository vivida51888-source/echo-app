import 'package:intl/intl.dart';

abstract final class DiaryFormat {
  static const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const monthNames = [
    '',
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ];

  static String dateLine(DateTime date, {bool english = false}) {
    if (english) {
      final weekday = _enWeekdays[date.weekday - 1];
      final month = DateFormat.MMM('en_US').format(date);
      return '$month ${date.day} · $weekday';
    }
    final weekday = weekdays[date.weekday - 1];
    return '${date.month}月${date.day}日 · $weekday';
  }

  /// 拍立得导出：含年份，不含星期。
  static String polaroidDateLabel(DateTime date) =>
      '${date.year}年${date.month}月${date.day}日';

  static String dateShort(DateTime date) {
    final weekday = weekdays[date.weekday - 1];
    return '$weekday · ${date.month}月${date.day}日';
  }

  static String monthTitle(int year, int month) => '$year年${monthNames[month]}';

  static String monthTitleShort(int month) => monthNames[month];

  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.month}/${start.day} – ${end.month}/${end.day}';
    }
    if (start.year == end.year) {
      return '${start.month}/${start.day} – ${end.month}/${end.day}';
    }
    return '${start.year}/${start.month}/${start.day} – '
        '${end.year}/${end.month}/${end.day}';
  }

  static String weekSectionTitle(DateTime weekStart, DateTime weekEnd) {
    return dateRange(weekStart, weekEnd);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isYesterday(DateTime date) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, y);
  }

  static String listDateLabel(DateTime date) {
    if (isToday(date)) return '今天';
    if (isYesterday(date)) return '昨天';
    return '${date.month}月${date.day}日';
  }

  static String weekdayLabel(DateTime date) => weekdays[date.weekday - 1];

  /// 星期圆章用字：一 … 日。
  static String weekdayGlyph(DateTime date) {
    const glyphs = ['一', '二', '三', '四', '五', '六', '日'];
    return glyphs[date.weekday - 1];
  }

  /// 首行作标题；过长则截断。
  static String deriveTitle(String content) {
    final firstLine = content.split('\n').first.trim();
    if (firstLine.isEmpty) return '';
    if (firstLine.length <= 28) return firstLine;
    return '${firstLine.substring(0, 28)}…';
  }
}
