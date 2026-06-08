import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';
import 'echo_coin_icon.dart';

enum EchoMomentToastKind {
  success,
  coins,
}

/// 与写完日记「已放进回响」一致的居中浮层反馈。
Future<void> showEchoMomentToast(
  BuildContext context, {
  required String message,
  EchoMomentToastKind kind = EchoMomentToastKind.success,
}) async {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final completer = Completer<void>();
  late OverlayEntry entry;

  entry = OverlayEntry(
    builder: (ctx) => _EchoMomentToastLayer(
      message: message,
      kind: kind,
      onComplete: () {
        entry.remove();
        if (!completer.isCompleted) completer.complete();
      },
    ),
  );

  overlay.insert(entry);
  return completer.future;
}

class _EchoMomentToastLayer extends StatefulWidget {
  const _EchoMomentToastLayer({
    required this.message,
    required this.kind,
    required this.onComplete,
  });

  final String message;
  final EchoMomentToastKind kind;
  final VoidCallback onComplete;

  @override
  State<_EchoMomentToastLayer> createState() => _EchoMomentToastLayerState();
}

class _EchoMomentToastLayerState extends State<_EchoMomentToastLayer>
    with SingleTickerProviderStateMixin {
  static const _enterMs = 520;
  static const _holdMs = 720;
  static const _exitMs = 180;

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _enterMs + _holdMs + _exitMs),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.82, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: _enterMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _holdMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: _exitMs.toDouble(),
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: _enterMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: _holdMs.toDouble(),
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: _exitMs.toDouble(),
      ),
    ]).animate(_controller);

    _controller.forward().whenComplete(() {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCoins = widget.kind == EchoMomentToastKind.coins;
    const coinTint = Color(0xFFC99A3A);

    return IgnorePointer(
      child: FadeTransition(
        opacity: _opacity,
        child: ColoredBox(
          color: EchoColors.appBackground.withValues(alpha: 0.92),
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCoins
                          ? coinTint.withValues(alpha: 0.14)
                          : EchoColors.todoCompletedSurface,
                      border: Border.all(
                        color: isCoins
                            ? coinTint.withValues(alpha: 0.38)
                            : EchoColors.todoCompletedBorder,
                        width: 0.5,
                      ),
                    ),
                    child: isCoins
                        ? const Center(
                            child: EchoCoinIcon(size: 28),
                          )
                        : Icon(
                            Icons.check,
                            size: 28,
                            color: EchoColors.todoCompletedFill,
                          ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      widget.message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextPrimary,
                        letterSpacing: 0.4,
                        height: 1.45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
