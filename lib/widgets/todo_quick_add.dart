import 'package:flutter/material.dart';

import '../models/todo_category.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_typography.dart';
import '../utils/todo_copy.dart';
import 'scale_tap.dart';

/// 待办列表状态分段（待完成 / 已休眠 / 已安放）。
enum TodoListTab {
  pending,
  sleeping,
  completed,
}

extension TodoListTabUi on TodoListTab {
  String get label => switch (this) {
        TodoListTab.pending => TodoCopy.pendingSection,
        TodoListTab.sleeping => TodoCopy.sleepingSection,
        TodoListTab.completed => TodoCopy.completedSection,
      };

  IconData get hubIcon => switch (this) {
        TodoListTab.pending => Icons.wb_sunny_outlined,
        TodoListTab.sleeping => Icons.nights_stay_outlined,
        TodoListTab.completed => Icons.check_circle_outline,
      };

  Color get hubTint => switch (this) {
        TodoListTab.pending => const Color(0xFF6FAF82),
        TodoListTab.sleeping => const Color(0xFF7A8FA8),
        TodoListTab.completed => const Color(0xFF7BA889),
      };
}

enum TodoListFilterMode { all, important, category }

/// 分类筛选条。
class TodoCategoryFilterBar extends StatelessWidget {
  const TodoCategoryFilterBar({
    super.key,
    this.selected,
    this.onChanged,
    this.filterMode = TodoListFilterMode.all,
    this.selectedCategory,
    this.onFilterChanged,
    this.compact = false,
    this.minimal = false,
    this.echoStyle = false,
  });

  final TodoCategory? selected;
  final ValueChanged<TodoCategory?>? onChanged;
  final TodoListFilterMode filterMode;
  final TodoCategory? selectedCategory;
  final void Function(TodoListFilterMode mode, TodoCategory? category)?
      onFilterChanged;
  final bool compact;
  final bool minimal;
  final bool echoStyle;

  @override
  Widget build(BuildContext context) {
    if (echoStyle) {
      final categoryCount = TodoCategory.values.length;
      return ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: categoryCount + 2,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _EchoFilterChip(
              label: TodoCopy.allCategories,
              selected: filterMode == TodoListFilterMode.all,
              onTap: () => onFilterChanged?.call(TodoListFilterMode.all, null),
            );
          }
          if (index == 1) {
            return _EchoFilterChip(
              label: TodoCopy.importantCategory,
              icon: Icons.bookmark_outline_rounded,
              tint: EchoColors.todoImportant,
              selected: filterMode == TodoListFilterMode.important,
              onTap: () =>
                  onFilterChanged?.call(TodoListFilterMode.important, null),
            );
          }
          final category = TodoCategory.values[index - 2];
          return _EchoFilterChip(
            label: category.localizedLabel,
            icon: category.icon,
            tint: category.color,
            selected:
                filterMode == TodoListFilterMode.category &&
                selectedCategory == category,
            onTap: () =>
                onFilterChanged?.call(TodoListFilterMode.category, category),
          );
        },
      );
    }

    if (minimal) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _MinimalFilter(
              label: TodoCopy.allCategories,
              selected: selected == null,
              color: EchoColors.dayTextSecondary,
              onTap: () => onChanged?.call(null),
            ),
            for (final category in TodoCategory.values) ...[
              Text(
                ' · ',
                style: EchoTypography.caption.copyWith(
                  color: EchoColors.dayDivider,
                ),
              ),
              _MinimalFilter(
                label: category.localizedLabel,
                selected: selected == category,
                color: category.color,
                onTap: () => onChanged?.call(category),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: TodoCategory.values.length + 1,
      separatorBuilder: (_, index) => SizedBox(width: compact ? 6 : 8),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _FilterChip(
            label: TodoCopy.allCategories,
            selected: selected == null,
            color: EchoColors.dayTextSecondary,
            compact: compact,
            onTap: () => onChanged?.call(null),
          );
        }
        final category = TodoCategory.values[index - 1];
        return _FilterChip(
          label: category.localizedLabel,
          selected: selected == category,
          color: category.color,
          icon: category.icon,
          compact: compact,
          onTap: () => onChanged?.call(category),
        );
      },
    );
  }
}

class _EchoFilterChip extends StatelessWidget {
  const _EchoFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.tint,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final accent = tint ?? EchoColors.dayTextSecondary;
    final iconColor = selected
        ? EchoColors.daySurface
        : accent.withValues(alpha: 0.88);
    final textColor = selected
        ? EchoColors.daySurface
        : EchoColors.dayTextSecondary;

    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? (tint ?? EchoColors.dayTextPrimary)
              : EchoColors.dayWriting.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: !selected && tint != null
              ? Border.all(color: accent.withValues(alpha: 0.22), width: 0.5)
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w300,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MinimalFilter extends StatelessWidget {
  const _MinimalFilter({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Text(
        label,
        style: EchoTypography.caption.copyWith(
          color: selected ? color : EchoColors.dayTextWhisper,
          fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
    this.icon,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final Color color;
  final IconData? icon;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12,
          vertical: compact ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? color.withValues(alpha: 0.5)
                : EchoColors.dayDivider.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: EchoTypography.caption.copyWith(
                color: selected ? color : EchoColors.dayTextSecondary,
                fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
