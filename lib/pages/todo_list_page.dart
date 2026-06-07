import 'package:flutter/material.dart';

import '../models/todo_category.dart';
import '../models/todo_reminder.dart';
import '../navigation/app_page_route.dart';
import '../pages/keepsakes_page.dart';
import '../services/echo_collectible_service.dart';
import '../services/echo_stats_service.dart';
import '../services/todo_notification_service.dart';
import '../services/todo_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../l10n/echo_strings.dart';
import '../services/locale_service.dart';
import '../utils/todo_copy.dart';
import '../utils/todo_schedule.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_charm.dart';
import '../widgets/echo_controls.dart';
import '../widgets/echo_empty_state.dart';
import '../widgets/echo_page_header.dart';
import '../widgets/echo_themed_scope.dart';
import '../widgets/scale_tap.dart';
import '../widgets/todo_list_card.dart';
import '../widgets/todo_quick_add.dart';
import '../widgets/todo_stats_panel.dart';
import 'todo_edit_page.dart';
import 'write_diary_page.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final _service = TodoService.instance;
  final _statusPageController = PageController();

  TodoListTab _tab = TodoListTab.pending;
  TodoTimeHorizon _horizon = TodoTimeHorizon.today;
  TodoListFilterMode _filterMode = TodoListFilterMode.all;
  TodoCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _service.rolloverIfNeeded();
      await _service.processAutoSleep();
      await TodoNotificationService.instance.purgeExpiredTodos();
    });
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    _statusPageController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  void _selectStatusTab(TodoListTab tab) {
    if (_tab == tab) return;
    final index = TodoListTab.values.indexOf(tab);
    final distance = (index - TodoListTab.values.indexOf(_tab)).abs();
    setState(() => _tab = tab);
    if (!_statusPageController.hasClients) return;
    if (distance > 1) {
      _statusPageController.jumpToPage(index);
      return;
    }
    _statusPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _onStatusPageChanged(int index) {
    final tab = TodoListTab.values[index];
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  int get _horizonIndex =>
      TodoTimeHorizon.displayOrder.indexOf(_horizon).clamp(0, 3);

  void _shiftHorizon(int delta) {
    final next = _horizonIndex + delta;
    if (next < 0 || next >= TodoTimeHorizon.displayOrder.length) return;
    setState(() => _horizon = TodoTimeHorizon.displayOrder[next]);
  }

  Future<void> _openCreate() async {
    await openTodoEditPage(context);
  }

  Future<void> _openHorizonStats() async {
    final now = DateTime.now();
    final stats = EchoStatsService.instance.todoHorizonStatistics(_horizon, now);
    final rangeLabel = TodoSchedule.horizonStatsRangeLabel(_horizon, now);
    final title = TodoSchedule.horizonStatsTitle(_horizon);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: EchoColors.daySurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 24 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: EchoColors.dayDivider.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                rangeLabel,
                style: EchoTypography.labelMedium.copyWith(
                  color: EchoColors.dayTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: EchoTypography.displayMedium.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 20),
              TodoStatsPanel(stats: stats),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openEdit(TodoReminder todo) async {
    await openTodoEditPage(context, existing: todo);
  }

  Future<void> _syncNotification(TodoReminder todo) async {
    if (todo.isPermanentlyCompleted || todo.isSleeping) {
      await TodoNotificationService.instance.cancel(todo.id);
    } else {
      await TodoNotificationService.instance.schedule(todo);
    }
  }

  Future<void> _toggleComplete(TodoReminder todo) async {
    final wasDone = todo.isDoneForDisplay(DateTime.now());
    await _service.toggleComplete(todo.id);
    final updated = _service.getById(todo.id);
    if (updated == null) return;

    if (wasDone) {
      await _syncNotification(updated);
      return;
    }

    final earned = EchoCollectibleService.instance.takeLastEarned();
    if (earned != null && mounted) {
      showCollectibleEarnedSnack(context, earned);
    }

    if (updated.isPermanentlyCompleted) {
      await TodoNotificationService.instance.cancel(todo.id);
      return;
    }

    await _syncNotification(updated);
    if (!mounted || updated.repeat == TodoRepeat.none) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${TodoCopy.nextReminder} · ${_formatTime(updated.reminderAt)}',
          style: TextStyle(fontWeight: FontWeight.w300),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _toggleSubtask(TodoReminder todo, String subtaskId) async {
    await _service.toggleSubtask(todo.id, subtaskId);
    final updated = _service.getById(todo.id);
    if (updated != null) await _syncNotification(updated);
  }

  Future<void> _wake(TodoReminder todo) async {
    await _service.wake(todo.id);
    final updated = _service.getById(todo.id);
    if (updated != null) await _syncNotification(updated);
  }

  Future<void> _rescheduleTonight(TodoReminder todo) async {
    await _service.rescheduleTonight(todo.id);
    final updated = _service.getById(todo.id);
    if (updated != null) await _syncNotification(updated);
  }

  Future<void> _rescheduleTomorrow(TodoReminder todo) async {
    await _service.rescheduleTomorrowMorning(todo.id);
    final updated = _service.getById(todo.id);
    if (updated != null) await _syncNotification(updated);
  }

  Future<void> _toDiary(TodoReminder todo) async {
    await Navigator.of(context).push<bool>(
      AppPageRoute<bool>(
        builder: (_) => WriteDiaryPage(
          initialContent: TodoCopy.diarySeed(todo.content),
        ),
      ),
    );
  }

  Future<void> _showActions(TodoReminder todo) async {
    final now = DateTime.now();
    final action = await showEchoActionSheet<String>(
      context: context,
      actions: [
        if (todo.isSleeping)
          const EchoActionSheetItem(label: TodoCopy.wake, value: 'wake'),
        if (todo.isDoneForDisplay(now) || todo.isPermanentlyCompleted)
          const EchoActionSheetItem(label: TodoCopy.toDiary, value: 'diary'),
        if (!todo.isDoneForDisplay(now) && !todo.isSleeping)
          const EchoActionSheetItem(label: TodoCopy.markDone, value: 'done'),
        if (_filterMode == TodoListFilterMode.all && !todo.isImportant)
          const EchoActionSheetItem(
            label: TodoCopy.moveToImportant,
            value: 'important',
          ),
        if (todo.isImportant &&
            (_filterMode == TodoListFilterMode.all ||
                _filterMode == TodoListFilterMode.important))
          const EchoActionSheetItem(
            label: TodoCopy.removeFromImportant,
            value: 'unimportant',
          ),
        const EchoActionSheetItem(label: TodoCopy.edit, value: 'edit'),
        if (!todo.isDoneForDisplay(now) &&
            !todo.isSleeping &&
            todo.isExpired(now))
          const EchoActionSheetItem(
            label: TodoCopy.reschedule,
            value: 'reschedule',
          ),
        const EchoActionSheetItem(
          label: TodoCopy.delete,
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'wake':
        await _wake(todo);
      case 'done':
        await _toggleComplete(todo);
      case 'diary':
        await _toDiary(todo);
      case 'important':
        await _service.setImportant(todo.id, true);
      case 'unimportant':
        await _service.setImportant(todo.id, false);
      case 'edit':
        await _openEdit(todo);
      case 'reschedule':
        await _openEdit(todo);
      case 'delete':
        final confirm = await showEchoActionSheet<bool>(
          context: context,
          message: TodoCopy.deleteConfirm,
          actions: const [
            EchoActionSheetItem(
              label: TodoCopy.delete,
              value: true,
              isDestructive: true,
            ),
          ],
        );
        if (confirm == true) {
          await TodoNotificationService.instance.cancel(todo.id);
          await _service.delete(todo.id);
        }
    }
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}月${dt.day}日 · ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  List<TodoReminder> _filterCategory(List<TodoReminder> items) {
    return switch (_filterMode) {
      TodoListFilterMode.all => items,
      TodoListFilterMode.important =>
        items.where((t) => t.isImportant).toList(),
      TodoListFilterMode.category =>
        items.where((t) => t.category == _selectedCategory).toList(),
    };
  }

  bool get _categoryFiltered => _filterMode == TodoListFilterMode.category;

  bool get _importantFiltered => _filterMode == TodoListFilterMode.important;

  List<TodoReminder> _itemsForTab(TodoListTab tab, DateTime now) {
    final base = switch (tab) {
      TodoListTab.pending => _service.activeItems(now),
      TodoListTab.sleeping => _service.sleepingItems(),
      TodoListTab.completed => _service.completedItems(now),
    };
    return _filterCategory(base);
  }

  List<TodoReminder> _visibleItems(TodoListTab tab, DateTime now) {
    final scoped = _itemsForTab(tab, now);
    if (tab == TodoListTab.completed) {
      return scoped
          .where((todo) {
            final doneAt = todo.lastDoneAt;
            if (doneAt == null) return false;
            return TodoSchedule.horizonForDate(
                  TodoSchedule.dateOnly(doneAt),
                  now,
                ) ==
                _horizon;
          })
          .toList()
        ..sort((a, b) => b.lastDoneAt!.compareTo(a.lastDoneAt!));
    }
    return TodoSchedule.filterByHorizon(scoped, _horizon, now)
        .where((todo) => !todo.isDoneForDisplay(now))
        .toList();
  }

  String _horizonNavTitle(DateTime now) {
    return '${_horizon.label} · ${TodoSchedule.horizonStatsRangeLabel(_horizon, now)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    return EchoPageBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListenableBuilder(
              listenable: LocaleService.instance,
              builder: (context, _) {
                final s = EchoStrings.of();
                return EchoPageHeader(
                  title: s.todoTitle,
                  subtitle: s.todoSubtitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ScaleTap(
                        onTap: _openHorizonStats,
                        scale: 0.9,
                        child: Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.insights_outlined,
                            size: 22,
                            color: EchoColors.dayTextSecondary,
                          ),
                        ),
                      ),
                      ScaleTap(
                        onTap: _openCreate,
                        scale: 0.92,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(4, 8, 0, 8),
                          child: Icon(
                            Icons.add,
                            size: 24,
                            color: EchoColors.dayTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: _TodoStatusHubStrip(
                selected: _tab,
                onSelect: _selectStatusTab,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EchoPeriodNavigatorBar(
                title: _horizonNavTitle(now),
                canPrevious: _horizonIndex > 0,
                canNext: _horizonIndex < TodoTimeHorizon.displayOrder.length - 1,
                onPrevious: () => _shiftHorizon(-1),
                onNext: () => _shiftHorizon(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
              child: SizedBox(
                height: 34,
                child: TodoCategoryFilterBar(
                  filterMode: _filterMode,
                  selectedCategory: _selectedCategory,
                  onFilterChanged: (mode, category) => setState(() {
                    _filterMode = mode;
                    _selectedCategory = category;
                  }),
                  echoStyle: true,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _statusPageController,
                onPageChanged: _onStatusPageChanged,
                children: [
                  _TodoStatusList(
                    items: _visibleItems(TodoListTab.pending, now),
                    tab: TodoListTab.pending,
                    horizon: _horizon,
                    now: now,
                    categoryFiltered: _categoryFiltered,
                    importantFiltered: _importantFiltered,
                    onTap: _openEdit,
                    onLongPress: _showActions,
                    onToggleComplete: _toggleComplete,
                    onToggleSubtask: _toggleSubtask,
                    onRescheduleTonight: _rescheduleTonight,
                    onRescheduleTomorrow: _rescheduleTomorrow,
                  ),
                  _TodoStatusList(
                    items: _visibleItems(TodoListTab.sleeping, now),
                    tab: TodoListTab.sleeping,
                    horizon: _horizon,
                    now: now,
                    categoryFiltered: _categoryFiltered,
                    importantFiltered: _importantFiltered,
                    onTap: _showActions,
                    onLongPress: _showActions,
                    onToggleComplete: (_) {},
                  ),
                  _TodoStatusList(
                    items: _visibleItems(TodoListTab.completed, now),
                    tab: TodoListTab.completed,
                    horizon: _horizon,
                    now: now,
                    categoryFiltered: _categoryFiltered,
                    importantFiltered: _importantFiltered,
                    onTap: _showActions,
                    onLongPress: _showActions,
                    onToggleComplete: _toggleComplete,
                    onToDiary: _toDiary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoStatusHubStrip extends StatelessWidget {
  const _TodoStatusHubStrip({
    required this.selected,
    required this.onSelect,
  });

  final TodoListTab selected;
  final ValueChanged<TodoListTab> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < TodoListTab.values.length; i++) ...[
          if (i > 0) const SizedBox(width: EchoSpacing.xxs),
          Expanded(
            child: _TodoStatusHubTab(
              tab: TodoListTab.values[i],
              selected: TodoListTab.values[i] == selected,
              onTap: () => onSelect(TodoListTab.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _TodoStatusHubTab extends StatelessWidget {
  const _TodoStatusHubTab({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final TodoListTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tint = tab.hubTint;
    final iconColor = selected ? tint : EchoColors.dayTextWhisper;

    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: EchoSpacing.xs,
          horizontal: EchoSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tint.withValues(alpha: 0.1)
              : EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.sm),
          border: Border.all(
            color: selected
                ? tint.withValues(alpha: 0.28)
                : EchoColors.dayDivider,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(tab.hubIcon, size: 17, color: iconColor),
            const SizedBox(height: 3),
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EchoTypography.labelMedium.copyWith(
                color: selected
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodoStatusList extends StatelessWidget {
  const _TodoStatusList({
    required this.items,
    required this.tab,
    required this.horizon,
    required this.now,
    required this.categoryFiltered,
    required this.importantFiltered,
    required this.onTap,
    required this.onLongPress,
    required this.onToggleComplete,
    this.onToggleSubtask,
    this.onRescheduleTonight,
    this.onRescheduleTomorrow,
    this.onToDiary,
  });

  final List<TodoReminder> items;
  final TodoListTab tab;
  final TodoTimeHorizon horizon;
  final DateTime now;
  final bool categoryFiltered;
  final bool importantFiltered;
  final void Function(TodoReminder todo) onTap;
  final void Function(TodoReminder todo) onLongPress;
  final void Function(TodoReminder todo) onToggleComplete;
  final void Function(TodoReminder todo, String subtaskId)? onToggleSubtask;
  final void Function(TodoReminder todo)? onRescheduleTonight;
  final void Function(TodoReminder todo)? onRescheduleTomorrow;
  final void Function(TodoReminder todo)? onToDiary;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      final showCharm = tab == TodoListTab.pending &&
          horizon == TodoTimeHorizon.today &&
          !categoryFiltered &&
          !importantFiltered;
      if (showCharm) {
        return Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 36),
            child: EchoEmptyState(
              charm: EchoCharmKind.sprout,
              message: TodoCopy.emptyPending,
            ),
          ),
        );
      }
      return Center(
        child: Text(
          _emptyMessage,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextSecondary,
          ),
        ),
      );
    }

    final expired = tab == TodoListTab.pending
        ? items.where((t) => t.isExpired(now)).toList()
        : <TodoReminder>[];
    final rest = tab == TodoListTab.pending
        ? items.where((t) => !t.isExpired(now)).toList()
        : items;

    final children = <Widget>[];

    if (expired.isNotEmpty) {
      children.add(_SectionLabel(TodoCopy.expiredLabel));
      for (final todo in expired) {
        children.add(_buildCard(todo, expired: true));
      }
    }

    if (horizon == TodoTimeHorizon.future && rest.isNotEmpty) {
      for (final entry in _futureGroups(rest).entries) {
        children.add(_SectionLabel(entry.key));
        for (final todo in entry.value) {
          children.add(_buildCard(todo));
        }
      }
    } else {
      if (rest.isNotEmpty && expired.isNotEmpty) {
        children.add(_SectionLabel(horizon.label));
      }
      for (final todo in rest) {
        children.add(_buildCard(todo));
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.md),
          border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(
              horizontal: EchoSpacing.md,
              vertical: EchoSpacing.xs,
            ),
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemCount: children.length,
            separatorBuilder: (context, index) {
              final child = children[index];
              if (child is _SectionLabel) {
                return const SizedBox(height: 12);
              }
              return Divider(
                height: 1,
                color: EchoColors.dayDivider.withValues(alpha: 0.55),
              );
            },
            itemBuilder: (context, index) => children[index],
          ),
        ),
      ),
    );
  }

  Map<String, List<TodoReminder>> _futureGroups(List<TodoReminder> rest) {
    final groups = <String, List<TodoReminder>>{};
    for (final todo in rest) {
      final day = TodoSchedule.dateOnly(
        TodoSchedule.effectiveReminderAt(todo, now),
      );
      final key = TodoSchedule.monthGroupLabel(
        TodoSchedule.monthGroupKey(day),
      );
      groups.putIfAbsent(key, () => []).add(todo);
    }
    return Map.fromEntries(
      groups.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  String get _emptyMessage {
    if (importantFiltered) return '还没有标记为重要的待办';
    if (categoryFiltered) return '这一分类还没有待办';
    if (tab == TodoListTab.sleeping) return TodoCopy.emptySleeping;
    if (tab == TodoListTab.completed) return '这一段时间还没有安放的待办';
    return switch (horizon) {
      TodoTimeHorizon.today => TodoCopy.emptyPending,
      TodoTimeHorizon.thisWeek => '这一段时间还没有安排',
      TodoTimeHorizon.thisMonth => '这一段时间还没有安排',
      TodoTimeHorizon.future => '还没有远期规划',
    };
  }

  Widget _buildCard(TodoReminder todo, {bool expired = false}) {
    return TodoListCard(
      todo: todo,
      now: now,
      placed: tab == TodoListTab.completed,
      showCategoryBadge: !categoryFiltered,
      showImportantBadge: !importantFiltered,
      dimmed: tab == TodoListTab.sleeping,
      onTap: () => onTap(todo),
      onLongPress: () => onLongPress(todo),
      onToggleComplete: () => onToggleComplete(todo),
      onToggleSubtask: onToggleSubtask == null
          ? null
          : (step) => onToggleSubtask!(todo, step.id),
      onToDiary: onToDiary == null ? null : () => onToDiary!(todo),
      onRescheduleTonight: expired &&
              onRescheduleTonight != null &&
              !todo.isDoneForDisplay(now)
          ? () => onRescheduleTonight!(todo)
          : null,
      onRescheduleTomorrow: expired &&
              onRescheduleTomorrow != null &&
              !todo.isDoneForDisplay(now)
          ? () => onRescheduleTomorrow!(todo)
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        text,
        style: EchoTypography.micro.copyWith(
          color: EchoColors.dayTextWhisper,
          letterSpacing: 0.8,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
