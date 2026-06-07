import '../models/diary.dart';
import 'diary_service.dart';

/// 回响时间轴：按周/月筛选日记。
class EchoInsightService {
  EchoInsightService._();

  static final EchoInsightService instance = EchoInsightService._();

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime startOfWeek(DateTime date) {
    final d = dateOnly(date);
    return d.subtract(Duration(days: d.weekday - 1));
  }

  static DateTime endOfWeek(DateTime weekStart) {
    return weekStart.add(const Duration(days: 6));
  }

  static DateTime startOfMonth(int year, int month) => DateTime(year, month, 1);

  static DateTime endOfMonth(int year, int month) =>
      DateTime(year, month + 1, 0);

  List<Diary> diariesInRange(DateTime start, DateTime end) {
    final s = dateOnly(start);
    final e = dateOnly(end);
    return DiaryService.instance.diaries.where((d) {
      final day = dateOnly(d.createdAt);
      return !day.isBefore(s) && !day.isAfter(e);
    }).toList();
  }

  List<Diary> diariesInMonth(int year, int month) {
    return diariesInRange(
      startOfMonth(year, month),
      endOfMonth(year, month),
    );
  }

  List<Diary> diariesInWeek(DateTime weekStart) {
    final start = dateOnly(weekStart);
    return diariesInRange(start, endOfWeek(start));
  }

  /// 有日记的月份列表（新 → 旧），用于按月浏览切换。
  List<DateTime> monthsWithEntries() {
    final set = <String>{};
    for (final d in DiaryService.instance.diaries) {
      set.add('${d.createdAt.year}-${d.createdAt.month}');
    }
    final list = set.map((k) {
      final p = k.split('-');
      return DateTime(int.parse(p[0]), int.parse(p[1]));
    }).toList()
      ..sort((a, b) {
        if (a.year != b.year) return b.year.compareTo(a.year);
        return b.month.compareTo(a.month);
      });
    return list;
  }
}
