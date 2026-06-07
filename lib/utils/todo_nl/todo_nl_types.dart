import '../../models/todo_reminder.dart';

/// 原文中被识别为时间/重复语义的区间。
class TodoNlSpan {
  const TodoNlSpan(this.start, this.end);

  final int start;
  final int end;
}

class TodoNlTimeParts {
  const TodoNlTimeParts(this.hour, this.minute);

  final int hour;
  final int minute;
}

class TodoNlScheduleResult {
  const TodoNlScheduleResult({
    required this.reminderAt,
    required this.repeat,
    required this.matched,
    required this.spans,
  });

  final DateTime reminderAt;
  final TodoRepeat repeat;
  final bool matched;
  final List<TodoNlSpan> spans;
}
