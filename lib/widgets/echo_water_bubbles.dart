import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/localized.dart';
import '../models/echo_water_bubble.dart';
import '../theme/echo_colors.dart';
import '../utils/echo_bubble_layout.dart';

/// 随机漂在树周围的雨露泡，点击即可收集。
class EchoWaterBubbleLayer extends StatelessWidget {
  const EchoWaterBubbleLayer({
    super.key,
    required this.bubbles,
    required this.onCollect,
    required this.sceneSize,
  });

  final List<EchoWaterBubble> bubbles;
  final ValueChanged<String> onCollect;
  final Size sceneSize;

  @override
  Widget build(BuildContext context) {
    if (bubbles.isEmpty) return const SizedBox.shrink();

    final shown = List<EchoWaterBubble>.from(bubbles)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return SizedBox(
      width: sceneSize.width,
      height: sceneSize.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (var i = 0; i < shown.length; i++)
            _Bubble(
              key: ValueKey(shown[i].id),
              bubble: shown[i],
              index: i,
              sceneSize: sceneSize,
              onCollect: () => onCollect(shown[i].id),
            ),
        ],
      ),
    );
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    super.key,
    required this.bubble,
    required this.index,
    required this.sceneSize,
    required this.onCollect,
  });

  final EchoWaterBubble bubble;
  final int index;
  final Size sceneSize;
  final VoidCallback onCollect;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with TickerProviderStateMixin {
  late final AnimationController _float;
  late final AnimationController _pulse;
  late final AnimationController _urgent;
  Timer? _countdownTimer;
  bool _collecting = false;
  bool _showGain = false;

  @override
  void initState() {
    super.initState();
    final phase = widget.index * 0.17;
    _float = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2600 + widget.index * 240),
    )..value = phase % 1.0;
    _float.repeat(reverse: true);

    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _urgent = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.bubble.isUrgent) _urgent.repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (!mounted || _collecting) return;
      final urgent = widget.bubble.isUrgent;
      if (urgent && !_urgent.isAnimating) {
        _urgent.repeat(reverse: true);
      } else if (!urgent && _urgent.isAnimating) {
        _urgent.stop();
        _urgent.reset();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _float.dispose();
    _pulse.dispose();
    _urgent.dispose();
    super.dispose();
  }

  Offset _center() =>
      EchoBubbleLayout.toPixel(widget.bubble.anchor, widget.sceneSize);

  Future<void> _onTap() async {
    if (_collecting) return;
    setState(() {
      _collecting = true;
      _showGain = true;
    });
    HapticFeedback.lightImpact();

    await Future<void>.delayed(const Duration(milliseconds: 420));
    if (!mounted) return;
    widget.onCollect();
  }

  @override
  Widget build(BuildContext context) {
    final center = _center();
    final diameter = EchoBubbleMetrics.diameterFor(widget.bubble.grams);
    final hit = EchoBubbleMetrics.hitAreaFor(widget.bubble.grams);
    final isStreak = widget.bubble.streakDays >= 2;
    final urgent = widget.bubble.isUrgent;
    final palette = EchoBubblePalette.forBubble(widget.bubble);

    return Positioned(
      left: center.dx - hit / 2,
      top: center.dy - hit / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: SizedBox(
          width: hit,
          height: hit + 16,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              AnimatedBuilder(
                animation: Listenable.merge([_float, _pulse, _urgent]),
                builder: (context, child) {
                  final driftY = math.sin(_float.value * math.pi * 2) * 6;
                  final driftX = math.cos(_float.value * math.pi * 2 + 0.6) * 3;
                  final scale = _collecting
                      ? 0.1
                      : (1.0 + _pulse.value * 0.06 + (urgent ? _urgent.value * 0.04 : 0));
                  final opacity = _collecting ? 0.0 : 1.0;

                  return Transform.translate(
                    offset: Offset(driftX, driftY),
                    child: Transform.scale(
                      scale: scale,
                      child: Opacity(opacity: opacity, child: child),
                    ),
                  );
                },
                child: _BubbleOrb(
                  diameter: diameter,
                  grams: widget.bubble.grams,
                  streakDays: widget.bubble.streakDays,
                  kindLabel: widget.bubble.kindLabel,
                  palette: palette,
                  isStreak: isStreak,
                  isBackfill: widget.bubble.isBackfillPool,
                  urgent: urgent,
                ),
              ),
              if (_showGain)
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 520),
                  onEnd: () {},
                  builder: (context, t, _) {
                    return Transform.translate(
                      offset: Offset(0, -28 - t * 36),
                      child: Opacity(
                        opacity: (1 - t).clamp(0.0, 1.0),
                        child: Text(
                          '+${widget.bubble.grams}g',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.gainColor.withValues(alpha: 0.95),
                            shadows: [
                              Shadow(
                                color: Colors.white.withValues(alpha: 0.9),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              if (!_collecting)
                Positioned(
                  bottom: 0,
                  child: Text(
                    widget.bubble.timeLeftLabel,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w300,
                      color: urgent
                          ? EchoColors.destructive.withValues(alpha: 0.75)
                          : EchoColors.dayTextWhisper,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BubbleOrb extends StatelessWidget {
  const _BubbleOrb({
    required this.diameter,
    required this.grams,
    required this.streakDays,
    required this.kindLabel,
    required this.palette,
    required this.isStreak,
    required this.isBackfill,
    required this.urgent,
  });

  final double diameter;
  final int grams;
  final int streakDays;
  final String? kindLabel;
  final EchoBubblePalette palette;
  final bool isStreak;
  final bool isBackfill;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    final inner = palette.gradient;
    final gramsFont = EchoBubbleMetrics.gramsFontSize(grams);
    final borderW = isStreak ? 2.0 : 1.5;
    final caption = streakDays > 1
        ? (tr('连 $streakDays 天', '$streakDays-day streak'))
        : (isBackfill ? tr('补记', 'Backfill') : kindLabel);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            inner[0].withValues(alpha: 0.98),
            inner[1].withValues(alpha: 0.72),
          ],
          stops: const [0.22, 1],
        ),
        boxShadow: [
          BoxShadow(
            color: inner[1].withValues(alpha: urgent ? 0.5 : 0.36),
            blurRadius: urgent ? diameter * 0.34 : diameter * 0.24,
            spreadRadius: urgent ? 1.5 : 0,
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isStreak ? 0.95 : 0.82),
          width: borderW,
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${grams}g',
            style: TextStyle(
              fontSize: gramsFont,
              fontWeight: FontWeight.w600,
              color: palette.textColor,
              height: 1,
            ),
          ),
          if (caption != null) ...[
            SizedBox(height: diameter > 42 ? 2 : 1),
            Text(
              caption,
              style: TextStyle(
                fontSize: diameter > 42 ? 8.5 : 8,
                fontWeight: FontWeight.w500,
                color: palette.textColor.withValues(alpha: 0.75),
                height: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
