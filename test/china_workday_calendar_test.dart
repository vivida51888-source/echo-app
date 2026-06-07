import 'package:echo_app/models/todo_reminder.dart';
import 'package:echo_app/utils/china_workday_calendar.dart';
import 'package:echo_app/utils/todo_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('2026 spring festival weekend is not workday', () {
    expect(ChinaWorkdayCalendar.isWorkday(DateTime(2026, 2, 15)), false);
    expect(ChinaWorkdayCalendar.isWorkday(DateTime(2026, 2, 14)), true);
  });

  test('2026 labor day holiday and makeup workday', () {
    expect(ChinaWorkdayCalendar.isWorkday(DateTime(2026, 5, 1)), false);
    expect(ChinaWorkdayCalendar.isWorkday(DateTime(2026, 5, 9)), true);
  });

  test('workday repeat skips weekend to next workday', () {
    final todo = TodoReminder(
      id: 't1',
      content: '周报',
      reminderAt: DateTime(2026, 5, 8, 9, 0),
      repeat: TodoRepeat.workday,
      createdAt: DateTime(2026, 5, 8, 8, 0),
    );
    final next = TodoSchedule.nextOccurrence(
      todo,
      after: DateTime(2026, 5, 8, 10, 0),
    );
    // 2026-05-09 为劳动节调休上班（周六）
    expect(next, DateTime(2026, 5, 9, 9, 0));
  });
}
