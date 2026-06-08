import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/todo_category.dart';
import '../models/todo_reminder.dart';
import '../models/todo_subtask.dart';
import '../utils/china_workday_calendar.dart';
import '../utils/todo_schedule.dart';
import 'echo_reward_service.dart';
import 'echo_tree_service.dart';

class TodoService extends ChangeNotifier {
  TodoService._();

  static final TodoService instance = TodoService._();

  static const _boxName = 'echo_todos';
  static const _rolloverKey = '__last_rollover_day__';

  /// 提醒到期后，超过此时间未安放则自动进入已休眠。
  static const sleepGracePeriod = Duration(minutes: 10);

  Box<dynamic>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    if (_box!.isEmpty) {
      await _seedSamples();
    }
    await rolloverIfNeeded();
    await processAutoSleep();
    _ready = true;
    notifyListeners();
  }

  /// 提醒过期超过 [sleepGracePeriod] 仍未安放 → 自动休眠。
  Future<void> processAutoSleep([DateTime? now]) async {
    if (_box == null) return;

    final current = now ?? DateTime.now();
    var changed = false;

    for (final todo in List<TodoReminder>.from(_items)) {
      if (!todo.shouldAutoSleep(current, gracePeriod: sleepGracePeriod)) {
        continue;
      }
      await _put(todo.copyWith(sleepingAt: current));
      changed = true;
    }

    if (changed) notifyListeners();
  }

  /// 跨日后清除前一日仍未安放的休眠待办（统计视为未完成）。
  Future<List<String>> purgeStaleSleepingTodos([DateTime? now]) async {
    if (_box == null) return [];

    final today = _dateOnly(now ?? DateTime.now());
    final removed = <String>[];

    for (final todo in List<TodoReminder>.from(_items)) {
      if (!todo.isSleeping) continue;
      final reminderDay = _dateOnly(todo.reminderAt);
      if (!reminderDay.isBefore(today)) continue;
      await _box!.delete(todo.id);
      removed.add(todo.id);
    }

    if (removed.isNotEmpty) notifyListeners();
    return removed;
  }

  /// 跨日：清空昨日「已安放」的一次性待办；重复项清除昨日完成标记。
  Future<void> rolloverIfNeeded() async {
    if (_box == null) return;

    final today = _dateOnly(DateTime.now());
    final lastRaw = _box!.get(_rolloverKey) as String?;
    if (lastRaw != null) {
      final lastDay = _dateOnly(DateTime.parse(lastRaw));
      if (!lastDay.isBefore(today)) return;
    }

    for (final todo in List<TodoReminder>.from(_items)) {
      if (todo.isPermanentlyCompleted && todo.completedAt != null) {
        if (_dateOnly(todo.completedAt!).isBefore(today)) {
          await _box!.delete(todo.id);
        }
        continue;
      }

      if (todo.repeat != TodoRepeat.none &&
          todo.lastCompletedAt != null &&
          _dateOnly(todo.lastCompletedAt!).isBefore(today)) {
        await _put(todo.copyWith(clearLastCompleted: true));
      }
    }

    await purgeStaleSleepingTodos(today);
    await _box!.put(_rolloverKey, today.toIso8601String());
    await processAutoSleep(today);
    notifyListeners();
  }

  Future<void> _seedSamples() async {
    final now = DateTime.now();
    final samples = [
      TodoReminder(
        id: 'seed_t1',
        content: '早点睡觉',
        reminderAt: now.add(const Duration(hours: 2)),
        note: '十一点前放下手机',
        category: TodoCategory.health,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      TodoReminder(
        id: 'seed_t2',
        content: '给妈妈打电话',
        reminderAt: now.subtract(const Duration(hours: 3)),
        category: TodoCategory.social,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      TodoReminder(
        id: 'seed_t3',
        content: '晨间散步十分钟',
        reminderAt: now.subtract(const Duration(days: 1)),
        category: TodoCategory.health,
        completedAt: now.subtract(const Duration(hours: 5)),
        createdAt: now.subtract(const Duration(days: 3)),
      ),
    ];
    for (final todo in samples) {
      await _box!.put(todo.id, todo.toMap());
    }
  }

  static bool _isTodoMapEntry(dynamic key, dynamic value) =>
      key is String && !key.startsWith('__') && value is Map;

  List<TodoReminder> get _items {
    if (_box == null) return [];
    final list = <TodoReminder>[];
    for (final key in _box!.keys) {
      final raw = _box!.get(key);
      if (_isTodoMapEntry(key, raw)) {
        list.add(
          TodoReminder.fromMap(Map<dynamic, dynamic>.from(raw as Map)),
        );
      }
    }
    return list;
  }

  List<TodoReminder> get items => List.unmodifiable(_items);

  Future<void> _put(TodoReminder todo) async {
    await _box!.put(todo.id, todo.toMap());
    notifyListeners();
  }

  List<TodoReminder> activeItems(DateTime now) {
    return _items
        .where((t) => !t.isPermanentlyCompleted && !t.isSleeping)
        .toList()
      ..sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
  }

  List<TodoReminder> sleepingItems() {
    return _items.where((t) => t.isSleeping).toList()
      ..sort((a, b) => b.sleepingAt!.compareTo(a.sleepingAt!));
  }

  List<TodoReminder> pendingItems(DateTime now) => activeItems(now);

  List<TodoReminder> completedItems([DateTime? now]) {
    final today = _dateOnly(now ?? DateTime.now());
    return _items
        .where((t) {
          if (!t.isDoneForDisplay(now ?? DateTime.now())) return false;
          final doneAt = t.lastDoneAt;
          if (doneAt == null) return false;
          return _dateOnly(doneAt) == today;
        })
        .toList()
      ..sort((a, b) => b.lastDoneAt!.compareTo(a.lastDoneAt!));
  }

  TodoReminder? getById(String id) {
    final raw = _box?.get(id);
    if (raw is! Map) return null;
    return TodoReminder.fromMap(Map<dynamic, dynamic>.from(raw));
  }

  Future<String> add({
    required String content,
    required DateTime reminderAt,
    TodoRepeat repeat = TodoRepeat.none,
    String? note,
    TodoCategory category = TodoCategory.life,
    List<TodoSubtask> subtasks = const [],
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final normalizedAt = _normalizeReminder(reminderAt, repeat);
    final todo = TodoReminder(
      id: id,
      content: content,
      reminderAt: normalizedAt,
      repeat: repeat,
      note: note?.trim().isEmpty == true ? null : note?.trim(),
      category: category,
      subtasks: subtasks,
      createdAt: DateTime.now(),
    );
    await _put(todo);
    return id;
  }

  Future<void> update(String id, TodoReminder updated) async {
    final raw = _box?.get(id);
    if (raw is! Map) return;
    final normalized = updated.copyWith(
      reminderAt: _normalizeReminder(updated.reminderAt, updated.repeat),
    );
    await _put(normalized);
  }

  Future<void> complete(String id) async {
    final todo = getById(id);
    if (todo == null) return;
    final now = DateTime.now();

    if (todo.repeat == TodoRepeat.none) {
      await _put(todo.copyWith(completedAt: now, clearLastCompleted: true));
      await EchoTreeService.instance.checkDailyTodoBonus(now);
      await EchoRewardService.instance.onTodoCompleted(now);
      return;
    }

    final next = TodoSchedule.nextOccurrence(todo, after: now);
    await _put(
      todo.copyWith(
        clearCompleted: true,
        lastCompletedAt: now,
        reminderAt: next,
      ),
    );
    await EchoTreeService.instance.checkDailyTodoBonus(now);
    await EchoRewardService.instance.onTodoCompleted(now);
  }

  Future<void> uncomplete(String id) async {
    final todo = getById(id);
    if (todo == null) return;

    if (todo.repeat != TodoRepeat.none &&
        todo.lastCompletedAt != null &&
        todo.completedAt == null) {
      await _put(todo.copyWith(clearLastCompleted: true));
      return;
    }

    await _put(todo.copyWith(clearCompleted: true, clearLastCompleted: true));
  }

  Future<void> toggleComplete(String id) async {
    final todo = getById(id);
    if (todo == null) return;
    final now = DateTime.now();
    if (todo.isDoneForDisplay(now)) {
      await uncomplete(id);
    } else {
      await complete(id);
    }
  }

  Future<void> reschedule(String id, DateTime reminderAt) async {
    final todo = getById(id);
    if (todo == null) return;
    await _put(
      todo.copyWith(
        reminderAt: reminderAt,
        clearCompleted: true,
        clearLastCompleted: true,
      ),
    );
  }

  Future<void> rescheduleTonight(String id) async {
    await reschedule(id, TodoSchedule.tonightAt(DateTime.now()));
  }

  Future<void> rescheduleTomorrowMorning(String id) async {
    await reschedule(id, TodoSchedule.tomorrowMorning(DateTime.now()));
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _normalizeReminder(DateTime reminderAt, TodoRepeat repeat) {
    if (repeat == TodoRepeat.workday) {
      return ChinaWorkdayCalendar.ensureWorkdayReminder(reminderAt);
    }
    return reminderAt;
  }

  List<TodoReminder> completedInRange(DateTime start, [DateTime? end]) {
    final s = _dateOnly(start);
    final e = end == null ? null : _dateOnly(end);
    return _items
        .where((t) {
          final at = t.lastDoneAt;
          if (at == null) return false;
          final day = _dateOnly(at);
          if (day.isBefore(s)) return false;
          if (e != null && day.isAfter(e)) return false;
          return true;
        })
        .toList()
      ..sort((a, b) => b.lastDoneAt!.compareTo(a.lastDoneAt!));
  }

  List<TodoReminder> scheduledInRange(DateTime start, [DateTime? end]) {
    final s = _dateOnly(start);
    final e = end == null ? null : _dateOnly(end);
    return _items
        .where((t) {
          final day = _dateOnly(t.reminderAt);
          if (day.isBefore(s)) return false;
          if (e != null && day.isAfter(e)) return false;
          return true;
        })
        .toList()
      ..sort((a, b) => a.reminderAt.compareTo(b.reminderAt));
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    notifyListeners();
  }

  Future<void> sleep(String id) async {
    final todo = getById(id);
    if (todo == null || todo.isPermanentlyCompleted) return;
    await _put(todo.copyWith(sleepingAt: DateTime.now()));
  }

  Future<void> wake(String id) async {
    final todo = getById(id);
    if (todo == null || !todo.isSleeping) return;
    await _put(todo.copyWith(clearSleeping: true));
  }

  Future<void> setImportant(String id, bool value) async {
    final todo = getById(id);
    if (todo == null || todo.isImportant == value) return;
    await _put(todo.copyWith(isImportant: value));
  }

  Future<void> addSubtask(String todoId, String title) async {
    final todo = getById(todoId);
    if (todo == null) return;
    final trimmed = title.trim();
    if (trimmed.isEmpty) return;
    final step = TodoSubtask(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: trimmed,
    );
    await _put(todo.copyWith(subtasks: [...todo.subtasks, step]));
  }

  Future<void> toggleSubtask(String todoId, String subtaskId) async {
    final todo = getById(todoId);
    if (todo == null) return;
    final now = DateTime.now();
    final updated = todo.subtasks.map((step) {
      if (step.id != subtaskId) return step;
      final completed = !step.completed;
      return step.copyWith(
        completed: completed,
        completedAt: completed ? now : null,
        clearCompletedAt: !completed,
      );
    }).toList();
    var next = todo.copyWith(subtasks: updated);
    if (next.hasSubtasks && next.allSubtasksCompleted && !next.isDoneForDisplay(now)) {
      if (next.repeat == TodoRepeat.none) {
        next = next.copyWith(completedAt: now, clearLastCompleted: true);
      } else {
        final nextAt = TodoSchedule.nextOccurrence(next, after: now);
        next = next.copyWith(
          clearCompleted: true,
          lastCompletedAt: now,
          reminderAt: nextAt,
        );
      }
      await _put(next);
      await EchoTreeService.instance.checkDailyTodoBonus(now);
      await EchoRewardService.instance.onTodoCompleted(now);
      return;
    }
    await _put(next);
  }

  Future<void> removeSubtask(String todoId, String subtaskId) async {
    final todo = getById(todoId);
    if (todo == null) return;
    await _put(
      todo.copyWith(
        subtasks: todo.subtasks.where((s) => s.id != subtaskId).toList(),
      ),
    );
  }

  Future<void> updateSubtasks(String todoId, List<TodoSubtask> subtasks) async {
    final todo = getById(todoId);
    if (todo == null) return;
    await _put(todo.copyWith(subtasks: subtasks));
  }
}