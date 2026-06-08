import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../utils/echo_coin_collect_sound.dart';
import 'echo_coin_icon.dart';

/// 回响币飞行轻动画（领取飞入 / 消耗飞出）。
abstract final class EchoCoinCollectOverlay {
  /// 回响币飞入余额区（签到、成就等）。
  static Future<void> playEarn(
    BuildContext context, {
    required int amount,
    Offset? from,
    GlobalKey? targetKey,
  }) {
    return _fly(
      context,
      amount: amount,
      from: from,
      to: null,
      targetKey: targetKey,
      spend: false,
    );
  }

  /// 兼容旧调用。
  static Future<void> play(
    BuildContext context, {
    required int totalCoins,
    Offset? from,
    GlobalKey? targetKey,
  }) =>
      playEarn(
        context,
        amount: totalCoins,
        from: from,
        targetKey: targetKey,
      );

  /// 回响币从余额区飞出到目标（小铺兑换、提前拆信等）。
  static Future<void> playSpend(
    BuildContext context, {
    required int amount,
    Offset? to,
    GlobalKey? sourceKey,
  }) {
    return _fly(
      context,
      amount: amount,
      from: null,
      to: to,
      sourceKey: sourceKey,
      spend: true,
    );
  }

  static Future<void> _fly(
    BuildContext context, {
    required int amount,
    Offset? from,
    Offset? to,
    GlobalKey? targetKey,
    GlobalKey? sourceKey,
    required bool spend,
  }) async {
    if (amount <= 0) return;

    final overlay = Overlay.of(context, rootOverlay: true);
    final media = MediaQuery.of(context);
    final wallet = _walletOffset(media, spend ? sourceKey : targetKey);

    final origin = from ??
        (spend
            ? wallet
            : Offset(media.size.width * 0.5, media.size.height * 0.42));
    final target = to ??
        (spend
            ? Offset(media.size.width * 0.5, media.size.height * 0.44)
            : wallet);

    final completer = Completer<void>();
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (ctx) => _EchoCoinCollectLayer(
        from: origin,
        to: target,
        particleCount: _particleCount(amount),
        spend: spend,
        onDone: () {
          entry.remove();
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );

    overlay.insert(entry);
    if (!spend) {
      unawaited(EchoCoinCollectSound.playBurst());
    }
    await completer.future;
  }

  static Offset _walletOffset(MediaQueryData media, GlobalKey? key) {
    final safeTop = media.padding.top;
    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final topLeft = box.localToGlobal(Offset.zero);
        return topLeft + Offset(box.size.width * 0.35, box.size.height * 0.5);
      }
    }
    return Offset(media.size.width - 56, safeTop + 18);
  }

  static int _particleCount(int coins) {
    if (coins <= 20) return 3;
    if (coins <= 50) return 4;
    if (coins <= 100) return 5;
    if (coins <= 300) return 6;
    return 7;
  }
}

class _EchoCoinCollectLayer extends StatefulWidget {
  const _EchoCoinCollectLayer({
    required this.from,
    required this.to,
    required this.particleCount,
    required this.onDone,
    this.spend = false,
  });

  final Offset from;
  final Offset to;
  final int particleCount;
  final VoidCallback onDone;
  final bool spend;

  @override
  State<_EchoCoinCollectLayer> createState() => _EchoCoinCollectLayerState();
}

class _EchoCoinCollectLayerState extends State<_EchoCoinCollectLayer>
    with SingleTickerProviderStateMixin {
  static const _staggerMs = 40;
  static const _flightMs = 420;

  final _rng = math.Random();
  late final List<_CoinParticle> _particles;
  late final AnimationController _master;
  late final int _totalMs;
  final _landed = <int>{};
  var _finished = false;

  @override
  void initState() {
    super.initState();
    _totalMs = _staggerMs * (widget.particleCount - 1) + _flightMs + 80;
    _master = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _totalMs),
    );

    _particles = List.generate(widget.particleCount, (i) {
      return _CoinParticle(
        index: i,
        scatter: Offset(
          (_rng.nextDouble() - 0.5) * 64,
          (_rng.nextDouble() - 0.5) * 40 - 10,
        ),
        control: Offset(
          (widget.from.dx + widget.to.dx) / 2 + (_rng.nextDouble() - 0.5) * 56,
          widget.spend
              ? math.max(widget.from.dy, widget.to.dy) +
                  48 +
                  _rng.nextDouble() * 36
              : math.min(widget.from.dy, widget.to.dy) -
                  64 -
                  _rng.nextDouble() * 40,
        ),
      );
    });

    _master.addListener(_onTick);
    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _complete();
      }
    });
    _master.forward();
  }

  void _onTick() {
    if (!mounted) return;
    final elapsedMs = _master.value * _totalMs;
    for (final particle in _particles) {
      if (_landed.contains(particle.index)) continue;
      final startMs = particle.index * _staggerMs;
      if (elapsedMs < startMs + _flightMs) continue;
      _landed.add(particle.index);
      if (!widget.spend) {
        EchoCoinCollectSound.playLand(index: particle.index);
      }
    }
  }

  void _complete() {
    if (_finished) return;
    _finished = true;
    if (!widget.spend) {
      unawaited(EchoCoinCollectSound.playFinish());
    }
    unawaited(HapticFeedback.lightImpact());
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDone();
    });
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  double _particleProgress(int index, double masterValue) {
    final elapsedMs = masterValue * _totalMs;
    final startMs = index * _staggerMs.toDouble();
    final raw = (elapsedMs - startMs) / _flightMs;
    if (raw <= 0) return 0;
    if (raw >= 1) return 1;
    return Curves.easeInOutCubic.transform(raw);
  }

  Offset _bezier(Offset a, Offset b, Offset c, double t) {
    final ab = Offset.lerp(a, c, t)!;
    final bc = Offset.lerp(c, b, t)!;
    return Offset.lerp(ab, bc, t)!;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _master,
        builder: (context, _) {
          final masterValue = _master.value;
          final pulseAnchor = widget.spend ? widget.from : widget.to;
          final pulse = _landed.isEmpty
              ? 1.0
              : 1.0 + math.min(_landed.length * 0.035, 0.16);

          return Stack(
            children: [
              for (final particle in _particles)
                _buildCoin(particle, masterValue),
              if (!widget.spend)
                Positioned(
                  left: pulseAnchor.dx - 12,
                  top: pulseAnchor.dy - 12,
                  child: Transform.scale(
                    scale: pulse,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFC99A3A).withValues(alpha: 0.16),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCoin(_CoinParticle particle, double masterValue) {
    final t = _particleProgress(particle.index, masterValue);
    if (t <= 0) return const SizedBox.shrink();

    final start = widget.from + particle.scatter * (1 - t);
    final position = _bezier(start, widget.to, particle.control, t);
    final scale = (0.4 + math.sin(t * math.pi) * 0.45).clamp(0.35, 0.95);
    final opacity = widget.spend
        ? (t < 0.08
            ? t / 0.08
            : t > 0.88
                ? (1 - t) / 0.12
                : 1.0)
        : (t < 0.06
            ? t / 0.06
            : t > 0.94
                ? (1 - t) / 0.06
                : 1.0);

    return Positioned(
      left: position.dx - 10,
      top: position.dy - 10,
      child: RepaintBoundary(
        child: Opacity(
          opacity: opacity.clamp(0.0, 1.0),
          child: Transform.rotate(
            angle: t * math.pi * 1.8,
            child: Transform.scale(
              scale: scale,
              child: const _CoinGlyph(),
            ),
          ),
        ),
      ),
    );
  }
}

class _CoinParticle {
  const _CoinParticle({
    required this.index,
    required this.scatter,
    required this.control,
  });

  final int index;
  final Offset scatter;
  final Offset control;
}

class _CoinGlyph extends StatelessWidget {
  const _CoinGlyph();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: EchoCoinIcon(size: 20, color: Color(0xFFC99A3A)),
    );
  }
}
