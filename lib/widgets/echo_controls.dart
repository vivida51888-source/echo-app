import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import 'scale_tap.dart';

enum EchoPrimaryButtonTone { night, day }

/// 主行动按钮。
class EchoPrimaryButton extends StatelessWidget {
  const EchoPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.tone = EchoPrimaryButtonTone.night,
    this.compact = false,
  });

  final String label;
  final VoidCallback onTap;
  final EchoPrimaryButtonTone tone;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isNight = tone == EchoPrimaryButtonTone.night;
    final fill = isNight ? EchoColors.nightAccent : EchoColors.dayTextPrimary;
    final text = isNight ? EchoColors.nightOnAccent : EchoColors.daySurface;

    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? EchoSpacing.xxl : EchoSpacing.xxxl + 8,
          vertical: compact ? EchoSpacing.sm + 2 : EchoSpacing.md,
        ),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(EchoRadii.pill),
          boxShadow: isNight
              ? [
                  BoxShadow(
                    color: EchoColors.nightAccent.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: EchoTypography.labelLarge.copyWith(
            color: text,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}

/// 分段切换（按周 / 按月等）。
class EchoSegmentedControl<T extends Object> extends StatelessWidget {
  const EchoSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    this.labelBuilder,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T)? labelBuilder;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.pill),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < segments.length; i++) ...[
              if (i > 0) const SizedBox(width: 2),
              _SegmentChip(
                label: labelBuilder?.call(segments[i]) ?? segments[i].toString(),
                selected: segments[i] == selected,
                onTap: () => onChanged(segments[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
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
      scale: 0.97,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: EchoSpacing.lg,
          vertical: EchoSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: selected ? EchoColors.insightSurface : Colors.transparent,
          borderRadius: BorderRadius.circular(EchoRadii.pill),
        ),
        child: Text(
          label,
          style: EchoTypography.labelLarge.copyWith(
            fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
            color: selected
                ? EchoColors.dayTextPrimary
                : EchoColors.dayTextSecondary,
          ),
        ),
      ),
    );
  }
}

/// 全宽分段切换：单一滑块指示器，避免双按钮同时动画产生伪影。
class EchoSlidingSegmentedControl<T extends Object> extends StatelessWidget {
  const EchoSlidingSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
    required this.labelBuilder,
    this.fontSize = 14,
    this.height = 38,
  });

  final List<T> segments;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelBuilder;
  final double fontSize;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = segments.indexOf(selected).clamp(0, segments.length - 1);

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: EchoColors.dayWriting.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentW = constraints.maxWidth / segments.length;
          return SizedBox(
            height: height,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  left: index * segmentW,
                  top: 0,
                  bottom: 0,
                  width: segmentW,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: EchoColors.daySurface,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: EchoColors.dayTextPrimary.withValues(
                            alpha: 0.06,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    for (final segment in segments)
                      Expanded(
                        child: ScaleTap(
                          onTap: () => onChanged(segment),
                          scale: 0.98,
                          child: Center(
                            child: Text(
                              labelBuilder(segment),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: fontSize,
                                fontWeight: segment == selected
                                    ? FontWeight.w400
                                    : FontWeight.w300,
                                color: segment == selected
                                    ? EchoColors.dayTextPrimary
                                    : EchoColors.dayTextSecondary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// 周/月区间导航：箭头切换 + 标题居中（篇章同款）。
class EchoPeriodNavigatorBar extends StatelessWidget {
  const EchoPeriodNavigatorBar({
    super.key,
    required this.title,
    required this.onPrevious,
    required this.onNext,
    this.canPrevious = true,
    this.canNext = true,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canPrevious;
  final bool canNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _arrow(Icons.chevron_left, canPrevious ? onPrevious : null),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
              letterSpacing: 0.2,
            ),
          ),
        ),
        _arrow(Icons.chevron_right, canNext ? onNext : null),
      ],
    );
  }

  Widget _arrow(IconData icon, VoidCallback? onTap) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.9,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 22,
          color: onTap != null
              ? EchoColors.dayTextSecondary
              : EchoColors.dayDivider,
        ),
      ),
    );
  }
}

/// 周/月区间导航：箭头切换 + 标题居中。
class EchoPeriodNavigator extends StatelessWidget {
  const EchoPeriodNavigator({
    super.key,
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleTap(
          onTap: onPrevious,
          scale: 0.9,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.chevron_left,
              size: 22,
              color: EchoColors.dayTextSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: EchoTypography.labelLarge.copyWith(
              color: EchoColors.dayTextPrimary,
            ),
          ),
        ),
        ScaleTap(
          onTap: onNext,
          scale: 0.9,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.chevron_right,
              size: 22,
              color: EchoColors.dayTextSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

/// 区间内容切换动画（不含滑动手势）。
class EchoPeriodContentSwitcher extends StatelessWidget {
  const EchoPeriodContentSwitcher({
    super.key,
    required this.periodKey,
    required this.slideDirection,
    required this.child,
  });

  final ValueKey<Object> periodKey;
  final int slideDirection;
  final Widget child;

  static const _slideOffset = 0.2;

  @override
  Widget build(BuildContext context) {
    final direction = slideDirection.clamp(-1, 1);
    final enterFrom = direction >= 0 ? _slideOffset : -_slideOffset;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.hardEdge,
          children: [
            ...previousChildren,
            ?currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        if (direction == 0) {
          return FadeTransition(opacity: animation, child: child);
        }
        final slide = Tween<Offset>(
          begin: Offset(enterFrom, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          ),
        );
        return ClipRect(
          child: SlideTransition(
            position: slide,
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          ),
        );
      },
      child: KeyedSubtree(
        key: periodKey,
        child: child,
      ),
    );
  }
}

/// 日期导航条：仅在此区域左右滑动切换区间。
class EchoPeriodSwipeNavigator extends StatefulWidget {
  const EchoPeriodSwipeNavigator({
    super.key,
    required this.title,
    required this.onPrevious,
    required this.onNext,
    this.canPrevious = true,
    this.canNext = true,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canPrevious;
  final bool canNext;

  @override
  State<EchoPeriodSwipeNavigator> createState() =>
      _EchoPeriodSwipeNavigatorState();
}

class _EchoPeriodSwipeNavigatorState extends State<EchoPeriodSwipeNavigator> {
  double _dragDx = 0;

  static const _minDistance = 64.0;
  static const _minVelocity = 280.0;

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if ((velocity <= -_minVelocity || _dragDx <= -_minDistance) &&
        widget.canNext) {
      widget.onNext();
    } else if ((velocity >= _minVelocity || _dragDx >= _minDistance) &&
        widget.canPrevious) {
      widget.onPrevious();
    }
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: EchoPeriodNavigator(
        title: widget.title,
        onPrevious: widget.canPrevious ? widget.onPrevious : () {},
        onNext: widget.canNext ? widget.onNext : () {},
      ),
    );
  }
}

/// 左右滑动切换区间，并带淡入滑动过渡（统计 / 留影 / 心情之书等共用）。
class EchoPeriodInteractiveLayer extends StatefulWidget {
  const EchoPeriodInteractiveLayer({
    super.key,
    required this.periodKey,
    required this.slideDirection,
    required this.onPrevious,
    required this.onNext,
    this.canPrevious = true,
    this.canNext = true,
    required this.child,
  });

  final ValueKey<Object> periodKey;
  final int slideDirection;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final bool canPrevious;
  final bool canNext;
  final Widget child;

  @override
  State<EchoPeriodInteractiveLayer> createState() =>
      _EchoPeriodInteractiveLayerState();
}

class _EchoPeriodInteractiveLayerState extends State<EchoPeriodInteractiveLayer> {
  double _dragDx = 0;

  static const _minDistance = 64.0;
  static const _minVelocity = 280.0;

  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if ((velocity <= -_minVelocity || _dragDx <= -_minDistance) &&
        widget.canNext) {
      widget.onNext();
    } else if ((velocity >= _minVelocity || _dragDx >= _minDistance) &&
        widget.canPrevious) {
      widget.onPrevious();
    }
    _dragDx = 0;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => _dragDx = 0,
      onHorizontalDragUpdate: (details) => _dragDx += details.delta.dx,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: EchoPeriodContentSwitcher(
        periodKey: widget.periodKey,
        slideDirection: widget.slideDirection,
        child: widget.child,
      ),
    );
  }
}
