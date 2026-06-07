import 'package:flutter/material.dart';

import '../models/todo_reminder.dart';
import '../models/todo_subtask.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../utils/todo_copy.dart';
import '../utils/todo_schedule.dart';
import 'scale_tap.dart';

class TodoListCard extends StatefulWidget {
  const TodoListCard({
    super.key,
    required this.todo,
    required this.now,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    this.onToggleSubtask,
    this.onToDiary,
    this.onRescheduleTonight,
    this.onRescheduleTomorrow,
    this.dimmed = false,
    this.placed = false,
    this.showCategoryBadge = false,
    this.showImportantBadge = false,
  });

  final TodoReminder todo;
  final DateTime now;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onToggleComplete;
  final void Function(TodoSubtask subtask)? onToggleSubtask;
  final VoidCallback? onToDiary;
  final VoidCallback? onRescheduleTonight;
  final VoidCallback? onRescheduleTomorrow;
  final bool dimmed;
  final bool placed;
  final bool showCategoryBadge;
  final bool showImportantBadge;

  @override
  State<TodoListCard> createState() => _TodoListCardState();
}

class _TodoListCardState extends State<TodoListCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final todo = widget.todo;
    final now = widget.now;
    final expired = todo.isExpired(now);
    final done = todo.isDoneForDisplay(now);
    final sleeping = todo.isSleeping;
    final when = done && todo.lastDoneAt != null
        ? todo.lastDoneAt!
        : todo.reminderAt;
    final showQuickReschedule =
        widget.onRescheduleTonight != null &&
        widget.onRescheduleTomorrow != null;
    final showSubtasks = todo.hasSubtasks &&
        widget.onToggleSubtask != null &&
        !done &&
        !sleeping;
    final mutedDone = done && !widget.placed;
    final accent = todo.category.color;

    return Opacity(
      opacity: widget.dimmed ? 0.72 : 1,
      child: ScaleTap(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        scale: 0.99,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodoTimeBadge(
                when: when,
                tint: mutedDone ? EchoColors.todoCompletedFill : accent,
                done: mutedDone,
              ),
              const SizedBox(width: EchoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: EchoTypography.bodyMedium.copyWith(
                        color: mutedDone
                            ? EchoColors.dayTextPrimary.withValues(alpha: 0.62)
                            : EchoColors.dayTextPrimary,
                        height: 1.45,
                        decoration:
                            mutedDone ? TextDecoration.lineThrough : null,
                        decorationColor:
                            EchoColors.dayTextWhisper.withValues(alpha: 0.5),
                      ),
                    ),
                    if (todo.note != null && todo.note!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        todo.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EchoTypography.caption.copyWith(
                          color: EchoColors.dayTextSecondary,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    _TodoMetaRow(
                      todo: todo,
                      showCategory: widget.showCategoryBadge,
                      showImportant: widget.showImportantBadge,
                      expired: expired,
                      done: done,
                      sleeping: sleeping,
                    ),
                    if (showSubtasks) ...[
                      const SizedBox(height: 6),
                      ScaleTap(
                        onTap: () => setState(() => _expanded = !_expanded),
                        scale: 0.98,
                        child: Text(
                          _expanded
                              ? '收起'
                              : '${todo.completedSubtaskCount}/${todo.subtasks.length} 步骤',
                          style: EchoTypography.micro.copyWith(
                            color: EchoColors.dayTextWhisper,
                          ),
                        ),
                      ),
                      if (_expanded) ...[
                        const SizedBox(height: 8),
                        for (final step in todo.subtasks)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: ScaleTap(
                              onTap: () => widget.onToggleSubtask!(step),
                              scale: 0.98,
                              child: Row(
                                children: [
                                  Icon(
                                    step.completed
                                        ? Icons.check_circle
                                        : Icons.radio_button_unchecked,
                                    size: 14,
                                    color: step.completed
                                        ? todo.category.color
                                        : EchoColors.dayTextWhisper,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      step.title,
                                      style:
                                          EchoTypography.labelMedium.copyWith(
                                        color: step.completed
                                            ? EchoColors.dayTextWhisper
                                            : EchoColors.dayTextSecondary,
                                        decoration: step.completed
                                            ? TextDecoration.lineThrough
                                            : null,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                    if (showQuickReschedule) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _QuickLink(
                            label: TodoCopy.rescheduleTonight,
                            onTap: widget.onRescheduleTonight!,
                          ),
                          const SizedBox(width: 14),
                          _QuickLink(
                            label: TodoCopy.rescheduleTomorrow,
                            onTap: widget.onRescheduleTomorrow!,
                          ),
                        ],
                      ),
                    ],
                    if (done && widget.onToDiary != null && !widget.placed) ...[
                      const SizedBox(height: 10),
                      ScaleTap(
                        onTap: widget.onToDiary!,
                        scale: 0.98,
                        child: Text(
                          TodoCopy.toDiary,
                          style: EchoTypography.labelLarge.copyWith(
                            color: EchoColors.dayTextPrimary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!sleeping) ...[
                const SizedBox(width: EchoSpacing.xs),
                ScaleTap(
                  onTap: widget.onToggleComplete,
                  scale: 0.9,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      done
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 20,
                      color: done
                          ? EchoColors.todoCompletedFill
                          : EchoColors.dayTextWhisper.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: EchoSpacing.xs, top: 4),
                  child: Icon(
                    Icons.nights_stay_outlined,
                    size: 18,
                    color: EchoColors.dayTextWhisper.withValues(alpha: 0.8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodoMetaRow extends StatelessWidget {
  const _TodoMetaRow({
    required this.todo,
    required this.showCategory,
    required this.showImportant,
    required this.expired,
    required this.done,
    required this.sleeping,
  });

  final TodoReminder todo;
  final bool showCategory;
  final bool showImportant;
  final bool expired;
  final bool done;
  final bool sleeping;

  @override
  Widget build(BuildContext context) {
    final accent = todo.category.color;
    final importantAccent = EchoColors.todoImportant;
    final trailing = <Widget>[];

    if (todo.repeat != TodoRepeat.none) {
      trailing.add(_MetaText(todo.repeat.label));
    }
    if (expired && !done && !sleeping) {
      trailing.add(_MetaText(TodoCopy.expiredLabel, emphasis: true));
    }

    final leading = <Widget>[];
    if (showImportant && todo.isImportant) {
      leading.addAll([
        Icon(Icons.bookmark_rounded, size: 12, color: importantAccent),
        const SizedBox(width: 4),
        Text(
          TodoCopy.importantCategory,
          style: EchoTypography.caption.copyWith(
            color: importantAccent,
            fontWeight: FontWeight.w400,
          ),
        ),
      ]);
    }
    if (showCategory) {
      if (leading.isNotEmpty) {
        leading.add(
          Text(
            ' · ',
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayDivider,
            ),
          ),
        );
      }
      leading.addAll([
        Icon(todo.category.icon, size: 12, color: accent),
        const SizedBox(width: 4),
        Text(
          todo.category.label,
          style: EchoTypography.caption.copyWith(
            color: accent,
            fontWeight: FontWeight.w400,
          ),
        ),
      ]);
    }

    return Row(
      children: [
        ...leading,
        if (leading.isNotEmpty && trailing.isNotEmpty)
          Text(
            ' · ',
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayDivider,
            ),
          ),
        for (var i = 0; i < trailing.length; i++) ...[
          if (i > 0)
            Text(
              ' · ',
              style: EchoTypography.caption.copyWith(
                color: EchoColors.dayDivider,
              ),
            ),
          trailing[i],
        ],
      ],
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.text, {this.emphasis = false});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: EchoTypography.caption.copyWith(
        color: emphasis ? EchoColors.dayTextSecondary : EchoColors.dayTextWhisper,
        fontWeight: FontWeight.w300,
      ),
    );
  }
}

/// 篇章 Hub 同款时间块：浅底 + 细边框，与列表纸色区分。
class _TodoTimeBadge extends StatelessWidget {
  const _TodoTimeBadge({
    required this.when,
    required this.tint,
    required this.done,
  });

  final DateTime when;
  final Color tint;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DiaryFormat.listDateLabel(when);
    final timeLabel =
        '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';
    final weekday = TodoSchedule.isSameDay(
          TodoSchedule.dateOnly(when),
          TodoSchedule.dateOnly(DateTime.now()),
        )
        ? null
        : DiaryFormat.weekdayLabel(when);

    return Container(
      width: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: 0.12),
          EchoColors.dayWriting.withValues(alpha: 0.72),
        ),
        borderRadius: BorderRadius.circular(EchoRadii.sm),
        border: Border.all(
          color: tint.withValues(alpha: done ? 0.22 : 0.32),
          width: 0.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: EchoTypography.micro.copyWith(
              color: EchoColors.dayTextSecondary,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            timeLabel,
            textAlign: TextAlign.center,
            style: EchoTypography.labelMedium.copyWith(
              color: done
                  ? EchoColors.todoCompletedFill.withValues(alpha: 0.85)
                  : tint.withValues(alpha: 0.92),
              fontWeight: FontWeight.w400,
              letterSpacing: -0.2,
            ),
          ),
          if (weekday != null) ...[
            const SizedBox(height: 2),
            Text(
              weekday,
              textAlign: TextAlign.center,
              style: EchoTypography.micro.copyWith(
                color: tint.withValues(alpha: 0.75),
                fontWeight: FontWeight.w300,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Text(
        label,
        style: EchoTypography.labelLarge.copyWith(
          color: EchoColors.dayTextPrimary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
