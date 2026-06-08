import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';

enum EchoBriefHintTone {
  neutral,
  success,
  gentle,
}

OverlayEntry? _activeHintEntry;

/// 底部轻提示（浅色卡片 + 动画，替代黑框 SnackBar）。
void showEchoBriefHint(
  BuildContext context, {
  required String message,
  EchoBriefHintTone tone = EchoBriefHintTone.neutral,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 2400),
}) {
  _activeHintEntry?.remove();
  _activeHintEntry = null;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;

  void dismiss() {
    entry.remove();
    if (identical(_activeHintEntry, entry)) {
      _activeHintEntry = null;
    }
  }

  entry = OverlayEntry(
    builder: (ctx) => _EchoBriefHintLayer(
      message: message,
      tone: tone,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
      holdDuration: duration,
      onDismissed: dismiss,
    ),
  );

  _activeHintEntry = entry;
  overlay.insert(entry);
}

/// 与 [showEchoBriefHint] 相同，便于从 SnackBar 迁移。
void showEchoToast(
  BuildContext context,
  String message, {
  EchoBriefHintTone tone = EchoBriefHintTone.neutral,
  IconData? icon,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 2400),
}) {
  showEchoBriefHint(
    context,
    message: message,
    tone: tone,
    icon: icon,
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

class _EchoBriefHintLayer extends StatefulWidget {
  const _EchoBriefHintLayer({
    required this.message,
    required this.tone,
    required this.holdDuration,
    required this.onDismissed,
    this.icon,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final EchoBriefHintTone tone;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration holdDuration;
  final VoidCallback onDismissed;

  @override
  State<_EchoBriefHintLayer> createState() => _EchoBriefHintLayerState();
}

class _EchoBriefHintLayerState extends State<_EchoBriefHintLayer>
    with SingleTickerProviderStateMixin {
  static const _enterMs = 320;
  static const _exitMs = 220;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  Timer? _holdTimer;
  var _exiting = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _enterMs),
      reverseDuration: const Duration(milliseconds: _exitMs),
    );
    _opacity = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
    _holdTimer = Timer(widget.holdDuration, _startExit);
  }

  void _startExit() {
    if (_exiting || !mounted) return;
    _exiting = true;
    _controller.reverse().whenComplete(() {
      if (mounted) widget.onDismissed();
    });
  }

  void _onAction() {
    _holdTimer?.cancel();
    widget.onDismissed();
    widget.onAction?.call();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  IconData? get _resolvedIcon {
    if (widget.icon != null) return widget.icon;
    return switch (widget.tone) {
      EchoBriefHintTone.success => Icons.check_rounded,
      EchoBriefHintTone.gentle => Icons.info_outline_rounded,
      EchoBriefHintTone.neutral => null,
    };
  }

  Color get _iconFill {
    return switch (widget.tone) {
      EchoBriefHintTone.success => EchoColors.todoCompletedFill,
      EchoBriefHintTone.gentle => EchoColors.dayTextSecondary,
      EchoBriefHintTone.neutral => EchoColors.dayTextWhisper,
    };
  }

  Color get _iconSurface {
    return switch (widget.tone) {
      EchoBriefHintTone.success => EchoColors.todoCompletedSurface,
      EchoBriefHintTone.gentle => EchoColors.dayWriting.withValues(alpha: 0.9),
      EchoBriefHintTone.neutral => EchoColors.dayWriting.withValues(alpha: 0.75),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final resolvedIcon = _resolvedIcon;

    return Positioned(
      left: 20,
      right: 20,
      bottom: bottom + 16,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: EchoColors.daySurface,
                borderRadius: BorderRadius.circular(EchoRadii.lg),
                border: Border.all(
                  color: EchoColors.dayDivider.withValues(alpha: 0.75),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: EchoColors.dayTextPrimary.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (resolvedIcon != null) ...[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _iconSurface,
                          border: Border.all(
                            color: _iconFill.withValues(alpha: 0.22),
                            width: 0.5,
                          ),
                        ),
                        child: Icon(
                          resolvedIcon,
                          size: 17,
                          color: _iconFill,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Text(
                        widget.message,
                        style: TextStyle(
                          color: EchoColors.dayTextPrimary,
                          fontWeight: FontWeight.w300,
                          fontSize: 14,
                          height: 1.45,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    if (widget.actionLabel != null && widget.onAction != null) ...[
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _onAction,
                        behavior: HitTestBehavior.opaque,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 4,
                          ),
                          child: Text(
                            widget.actionLabel!,
                            style: TextStyle(
                              color: EchoColors.dayTextPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
