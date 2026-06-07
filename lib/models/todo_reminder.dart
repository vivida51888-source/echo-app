import 'todo_category.dart';
import 'todo_subtask.dart';

/// 轻量提醒，非任务管理。
enum TodoRepeat {
  none('不重复'),
  daily('每天'),
  alternateDay('隔天'),
  weekly('每周'),
  monthly('每月'),
  workday('工作日');

  const TodoRepeat(this.label);
  final String label;

  static TodoRepeat fromName(String name) =>
      TodoRepeat.values.firstWhere((e) => e.name == name, orElse: () => TodoRepeat.none);

  /// 编辑页选中该规则时的简短说明。
  String? get hint {
    switch (this) {
      case TodoRepeat.none:
        return '只提醒一次；安放后不再出现';
      case TodoRepeat.daily:
        return '每天在此时提醒；今日安放后推到明天同一时刻';
      case TodoRepeat.alternateDay:
        return '隔一天提醒一次；今日安放后推到后天同一时刻';
      case TodoRepeat.weekly:
        return '每周同一天、同一时刻（如每周三 9:00），不跳过周末与假日';
      case TodoRepeat.monthly:
        return '每月同一日、同一时刻（如每月 15 号 9:00）';
      case TodoRepeat.workday:
        return '按国务院法定节假日 · 周末与假日不提醒，调休上班日照常';
    }
  }
}

class TodoReminder {
  const TodoReminder({
    required this.id,
    required this.content,
    required this.reminderAt,
    this.repeat = TodoRepeat.none,
    this.note,
    this.category = TodoCategory.life,
    this.isImportant = false,
    this.completedAt,
    this.lastCompletedAt,
    this.sleepingAt,
    this.subtasks = const [],
    required this.createdAt,
  });

  final String id;
  final String content;
  final DateTime reminderAt;
  final TodoRepeat repeat;
  final String? note;
  final TodoCategory category;
  final bool isImportant;
  final DateTime? completedAt;
  final DateTime? lastCompletedAt;
  final DateTime? sleepingAt;
  final List<TodoSubtask> subtasks;
  final DateTime createdAt;

  bool get isSleeping => sleepingAt != null && !isPermanentlyCompleted;

  bool get isPermanentlyCompleted =>
      completedAt != null && repeat == TodoRepeat.none;

  bool get isCompleted => isPermanentlyCompleted;

  bool get hasSubtasks => subtasks.isNotEmpty;

  int get completedSubtaskCount =>
      subtasks.where((step) => step.completed).length;

  double get subtaskProgress =>
      hasSubtasks ? completedSubtaskCount / subtasks.length : 0;

  bool get allSubtasksCompleted =>
      hasSubtasks && completedSubtaskCount == subtasks.length;

  bool isDoneForDisplay(DateTime now) {
    if (isPermanentlyCompleted) return true;
    if (repeat != TodoRepeat.none && lastCompletedAt != null) {
      return _isSameDay(lastCompletedAt!, now);
    }
    return false;
  }

  bool isExpired(DateTime now) =>
      !isSleeping && !isDoneForDisplay(now) && reminderAt.isBefore(now);

  /// 提醒时间过后超过 [gracePeriod] 仍未安放 → 进入已休眠。
  bool shouldAutoSleep(
    DateTime now, {
    Duration gracePeriod = const Duration(minutes: 10),
  }) {
    if (isSleeping) return false;
    if (isDoneForDisplay(now)) return false;
    if (!reminderAt.isBefore(now)) return false;
    return now.difference(reminderAt) >= gracePeriod;
  }

  DateTime? get lastDoneAt => completedAt ?? lastCompletedAt;

  TodoReminder copyWith({
    String? content,
    DateTime? reminderAt,
    TodoRepeat? repeat,
    String? note,
    TodoCategory? category,
    bool? isImportant,
    DateTime? completedAt,
    DateTime? lastCompletedAt,
    DateTime? sleepingAt,
    List<TodoSubtask>? subtasks,
    bool clearCompleted = false,
    bool clearLastCompleted = false,
    bool clearSleeping = false,
    bool clearNote = false,
  }) {
    return TodoReminder(
      id: id,
      content: content ?? this.content,
      reminderAt: reminderAt ?? this.reminderAt,
      repeat: repeat ?? this.repeat,
      note: clearNote ? null : (note ?? this.note),
      category: category ?? this.category,
      isImportant: isImportant ?? this.isImportant,
      completedAt: clearCompleted ? null : (completedAt ?? this.completedAt),
      lastCompletedAt: clearLastCompleted
          ? null
          : (lastCompletedAt ?? this.lastCompletedAt),
      sleepingAt: clearSleeping ? null : (sleepingAt ?? this.sleepingAt),
      subtasks: subtasks ?? this.subtasks,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'reminderAt': reminderAt.toIso8601String(),
        'repeat': repeat.name,
        'note': note,
        'category': category.name,
        'isImportant': isImportant,
        'completedAt': completedAt?.toIso8601String(),
        'lastCompletedAt': lastCompletedAt?.toIso8601String(),
        'sleepingAt': sleepingAt?.toIso8601String(),
        'subtasks': subtasks.map((s) => s.toMap()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoReminder.fromMap(Map<dynamic, dynamic> map) {
    final rawSubtasks = map['subtasks'];
    final subtasks = <TodoSubtask>[];
    if (rawSubtasks is List) {
      for (final item in rawSubtasks) {
        if (item is Map) {
          subtasks.add(
            TodoSubtask.fromMap(Map<dynamic, dynamic>.from(item)),
          );
        }
      }
    }

    return TodoReminder(
      id: map['id'] as String,
      content: map['content'] as String? ?? '',
      reminderAt: DateTime.parse(map['reminderAt'] as String),
      repeat: TodoRepeat.fromName(map['repeat'] as String? ?? 'none'),
      note: map['note'] as String?,
      category: TodoCategory.fromName(map['category'] as String?),
      isImportant: map['isImportant'] as bool? ?? false,
      completedAt: map['completedAt'] != null
          ? DateTime.parse(map['completedAt'] as String)
          : null,
      lastCompletedAt: map['lastCompletedAt'] != null
          ? DateTime.parse(map['lastCompletedAt'] as String)
          : null,
      sleepingAt: map['sleepingAt'] != null
          ? DateTime.parse(map['sleepingAt'] as String)
          : null,
      subtasks: subtasks,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
