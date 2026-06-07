import 'package:flutter/material.dart';

import '../models/todo_category.dart';
import '../models/todo_reminder.dart';
import '../models/todo_subtask.dart';
import '../navigation/app_page_route.dart';
import '../services/todo_service.dart';
import '../services/todo_notification_service.dart';
import '../theme/echo_colors.dart';
import '../utils/todo_copy.dart';
import '../utils/todo_natural_language.dart';
import '../utils/todo_schedule.dart';
import '../widgets/scale_tap.dart';

class TodoEditPage extends StatefulWidget {
  const TodoEditPage({super.key, this.existing});

  final TodoReminder? existing;

  bool get isEditing => existing != null;

  @override
  State<TodoEditPage> createState() => _TodoEditPageState();
}

const _relativeReminderPresets = [
  (label: '30分钟后', duration: Duration(minutes: 30)),
  (label: '1小时后', duration: Duration(hours: 1)),
  (label: '2小时后', duration: Duration(hours: 2)),
  (label: '3小时后', duration: Duration(hours: 3)),
];

class _TodoEditPageState extends State<TodoEditPage> {
  final _contentController = TextEditingController();
  final _noteController = TextEditingController();
  final _subtaskController = TextEditingController();

  late DateTime _reminderAt;
  late TodoRepeat _repeat;
  late TodoCategory _category;
  late List<TodoSubtask> _subtasks;

  TodoNaturalLanguageResult? _parsed;
  bool _showManual = false;
  bool _scheduleManual = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _contentController.text = existing.content;
      _noteController.text = existing.note ?? '';
      _reminderAt = existing.reminderAt;
      _repeat = existing.repeat;
      _category = existing.category;
      _subtasks = List.of(existing.subtasks);
      _showManual = true;
    } else {
      _reminderAt = DateTime.now().add(const Duration(hours: 1));
      _repeat = TodoRepeat.none;
      _category = TodoCategory.life;
      _subtasks = [];
    }
    _contentController.addListener(_onContentChanged);
  }

  @override
  void dispose() {
    _contentController.removeListener(_onContentChanged);
    _contentController.dispose();
    _noteController.dispose();
    _subtaskController.dispose();
    super.dispose();
  }

  void _onContentChanged() {
    final text = _contentController.text.trim();
    final parsed = text.isEmpty ? null : TodoNaturalLanguage.parse(text);
    setState(() {
      _parsed = parsed;
      if (parsed != null && parsed.matched && !_scheduleManual) {
        _reminderAt = parsed.reminderAt;
        _repeat = parsed.repeat;
        _category = parsed.category;
      }
    });
  }

  void _markScheduleManual() {
    if (!_scheduleManual) setState(() => _scheduleManual = true);
  }

  Future<void> _pickDate() async {
    _markScheduleManual();
    final date = await showDatePicker(
      context: context,
      initialDate: _reminderAt,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: EchoColors.dayTextPrimary,
            onPrimary: EchoColors.daySurface,
            surface: EchoColors.daySurface,
          ),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() {
        _reminderAt = DateTime(
          date.year,
          date.month,
          date.day,
          _reminderAt.hour,
          _reminderAt.minute,
        );
      });
    }
  }

  Future<void> _pickReminderDateTime() async {
    _markScheduleManual();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: EchoColors.daySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                '改日期',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextPrimary,
                ),
              ),
              onTap: () => Navigator.pop(context, 'date'),
            ),
            ListTile(
              title: Text(
                '改时间',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextPrimary,
                ),
              ),
              onTap: () => Navigator.pop(context, 'time'),
            ),
          ],
        ),
      ),
    );
    if (action == 'date') {
      await _pickDate();
    } else if (action == 'time') {
      await _pickTime();
    }
  }

  Future<void> _pickTime() async {
    _markScheduleManual();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: EchoColors.dayTextPrimary,
            onPrimary: EchoColors.daySurface,
            surface: EchoColors.daySurface,
          ),
        ),
        child: child!,
      ),
    );
    if (time != null) {
      setState(() {
        _reminderAt = DateTime(
          _reminderAt.year,
          _reminderAt.month,
          _reminderAt.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  void _addSubtask() {
    final title = _subtaskController.text.trim();
    if (title.isEmpty) return;
    setState(() {
      _subtasks = [
        ..._subtasks,
        TodoSubtask(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          title: title,
        ),
      ];
      _subtaskController.clear();
    });
  }

  void _removeSubtask(String id) {
    setState(() {
      _subtasks = _subtasks.where((s) => s.id != id).toList();
    });
  }

  Future<void> _save() async {
    final raw = _contentController.text.trim();
    if (raw.isEmpty) return;

    final parsed = TodoNaturalLanguage.parse(raw);
    final content = parsed.matched ? parsed.content : raw;
    if (content.isEmpty) return;

    final useParsed = parsed.matched && !_scheduleManual;
    final reminderAt = useParsed ? parsed.reminderAt : _reminderAt;
    final repeat = useParsed ? parsed.repeat : _repeat;
    final category = useParsed ? parsed.category : _category;

    final service = TodoService.instance;
    final note = _noteController.text.trim();
    final notificationsReady =
        await TodoNotificationService.instance.ensureReadyForReminders();

    if (widget.isEditing) {
      final original = widget.existing!;
      final updated = original.copyWith(
        content: content,
        reminderAt: reminderAt,
        repeat: repeat,
        note: note.isEmpty ? null : note,
        category: category,
        subtasks: _subtasks,
        clearCompleted: true,
        clearSleeping: true,
      );
      await service.update(original.id, updated);
      await TodoNotificationService.instance.cancel(original.id);
      await TodoNotificationService.instance.schedule(updated);
    } else {
      final id = await service.add(
        content: content,
        reminderAt: reminderAt,
        repeat: repeat,
        note: note.isEmpty ? null : note,
        category: category,
        subtasks: _subtasks,
      );
      final added = service.getById(id);
      if (added != null) {
        await TodoNotificationService.instance.schedule(added);
      }
    }

    if (mounted) {
      if (!notificationsReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '请在系统设置中允许通知，才能收到温柔提醒',
              style: TextStyle(fontWeight: FontWeight.w300),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      Navigator.pop(context, true);
    }
  }

  void _setReminder(DateTime value) {
    _markScheduleManual();
    setState(() => _reminderAt = value);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.month}月${dt.day}日 · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  int? _matchingPresetIndex() {
    final now = DateTime.now();
    for (var i = 0; i < _relativeReminderPresets.length; i++) {
      final target = now.add(_relativeReminderPresets[i].duration);
      if ((_reminderAt.difference(target).inMinutes).abs() <= 2) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final parsed = _parsed;
    final showPreview = parsed != null && parsed.matched && !widget.isEditing;

    return Scaffold(
      backgroundColor: EchoColors.daySurface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  ScaleTap(
                    onTap: () => Navigator.pop(context),
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.close,
                        size: 22,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ScaleTap(
                    onTap: _save,
                    scale: 0.95,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Text(
                        '记下',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _contentController,
                      autofocus: !widget.isEditing,
                      maxLines: 3,
                      minLines: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextPrimary,
                        height: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: TodoCopy.createHint,
                        hintStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayHint,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                    if (showPreview) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _category.color.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _category.color.withValues(alpha: 0.22),
                            width: 0.5,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              TodoCopy.parsePreview,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w300,
                                color: EchoColors.dayTextWhisper,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              parsed.content.isEmpty ? rawFallback(parsed) : parsed.content,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: EchoColors.dayTextPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${_formatDateTime(_reminderAt)} · ${_category.label}${_repeat == TodoRepeat.none ? '' : ' · ${_repeat.label}'}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: EchoColors.dayTextSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    ScaleTap(
                      onTap: () => setState(() => _showManual = !_showManual),
                      scale: 0.98,
                      child: Row(
                        children: [
                          Text(
                            TodoCopy.manualSettings,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: EchoColors.dayTextSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _showManual
                                ? Icons.expand_less
                                : Icons.expand_more,
                            size: 18,
                            color: EchoColors.dayTextWhisper,
                          ),
                        ],
                      ),
                    ),
                    if (_showManual) ...[
                      const SizedBox(height: 20),
                      Text(
                        TodoCopy.categoryLabel,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TodoCategory.values.map((cat) {
                          final selected = _category == cat;
                          return _CategoryChip(
                            category: cat,
                            selected: selected,
                            onTap: () {
                              _markScheduleManual();
                              setState(() => _category = cat);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '提醒时间',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          for (var i = 0;
                              i < _relativeReminderPresets.length;
                              i++) ...[
                            if (i > 0) const SizedBox(width: 8),
                            Expanded(
                              child: _QuickTimeChip(
                                label: _relativeReminderPresets[i].label,
                                selected: _matchingPresetIndex() == i,
                                onTap: () => _setReminder(
                                  TodoSchedule.after(
                                    DateTime.now(),
                                    _relativeReminderPresets[i].duration,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      ScaleTap(
                        onTap: _pickReminderDateTime,
                        scale: 0.98,
                        child: _PickerRow(
                          label: '自定义',
                          value: _formatDateTime(_reminderAt),
                          selected: _matchingPresetIndex() == null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '重复',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: TodoRepeat.values.map((rule) {
                          final selected = _repeat == rule;
                          return ScaleTap(
                            onTap: () {
                              _markScheduleManual();
                              setState(() => _repeat = rule);
                            },
                            scale: 0.96,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? EchoColors.dayWriting
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: selected
                                      ? EchoColors.dayDivider
                                      : EchoColors.dayDivider
                                          .withValues(alpha: 0.5),
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                rule.label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: selected
                                      ? EchoColors.dayTextPrimary
                                      : EchoColors.dayTextSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      if (_repeat.hint case final hint?) ...[
                        const SizedBox(height: 10),
                        Text(
                          hint,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: EchoColors.dayTextWhisper,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                    const SizedBox(height: 28),
                    Text(
                      TodoCopy.subtasksLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_subtasks.isNotEmpty)
                      ..._subtasks.map(
                        (step) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.drag_handle_rounded,
                                size: 16,
                                color: EchoColors.dayTextWhisper
                                    .withValues(alpha: 0.6),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                    color: EchoColors.dayTextPrimary,
                                  ),
                                ),
                              ),
                              ScaleTap(
                                onTap: () => _removeSubtask(step.id),
                                scale: 0.9,
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: EchoColors.dayTextWhisper,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _subtaskController,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _addSubtask(),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              color: EchoColors.dayTextPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: TodoCopy.subtaskHint,
                              hintStyle: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                color: EchoColors.dayHint,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        ScaleTap(
                          onTap: _addSubtask,
                          scale: 0.92,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: EchoColors.dayWriting,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '添加',
                              style: TextStyle(
                                fontSize: 12,
                                color: EchoColors.dayTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextPrimary,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: TodoCopy.noteHint,
                        hintStyle: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayHint,
                        ),
                        border: InputBorder.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String rawFallback(TodoNaturalLanguageResult parsed) => '待办';
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final TodoCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? category.color.withValues(alpha: 0.14)
              : EchoColors.appBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? category.color.withValues(alpha: 0.55)
                : EchoColors.dayDivider.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(category.icon, size: 16, color: category.color),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
                color: selected ? category.color : EchoColors.dayTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickTimeChip extends StatelessWidget {
  const _QuickTimeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? EchoColors.dayWriting
              : EchoColors.appBackground,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? EchoColors.dayTextPrimary.withValues(alpha: 0.35)
                : EchoColors.dayDivider.withValues(alpha: 0.8),
            width: selected ? 1 : 0.5,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
            color: selected
                ? EchoColors.dayTextPrimary
                : EchoColors.dayTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.label,
    required this.value,
    this.selected = false,
  });

  final String label;
  final String value;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: selected ? EchoColors.dayWriting : EchoColors.appBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? EchoColors.dayTextPrimary.withValues(alpha: 0.35)
              : Colors.transparent,
          width: selected ? 1 : 0,
        ),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool?> openTodoEditPage(
  BuildContext context, {
  TodoReminder? existing,
}) {
  return Navigator.of(context).push<bool>(
    AppPageRoute<bool>(builder: (_) => TodoEditPage(existing: existing)),
  );
}
