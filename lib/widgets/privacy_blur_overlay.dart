import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../services/privacy_service.dart';
import '../theme/echo_colors.dart';

/// 多任务切换时叠加「老花眼」式强模糊，避免清晰内容出现在最近任务里。
class PrivacyBlurOverlay extends StatefulWidget {
  const PrivacyBlurOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<PrivacyBlurOverlay> createState() => _PrivacyBlurOverlayState();
}

class _PrivacyBlurOverlayState extends State<PrivacyBlurOverlay> {
  final _boundaryKey = GlobalKey();
  ui.Image? _snapshot;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    PrivacyService.instance.addListener(_onPrivacyChanged);
  }

  @override
  void dispose() {
    PrivacyService.instance.removeListener(_onPrivacyChanged);
    _snapshot?.dispose();
    super.dispose();
  }

  void _onPrivacyChanged() {
    if (PrivacyService.instance.showOverlay) {
      _scheduleCapture();
    } else {
      _snapshot?.dispose();
      if (mounted) {
        setState(() {
          _snapshot = null;
          _capturing = false;
        });
      }
    }
  }

  void _scheduleCapture() {
    if (_capturing) return;
    _capturing = true;
    SchedulerBinding.instance.scheduleFrameCallback((_) async {
      await SchedulerBinding.instance.endOfFrame;
      if (!mounted || !PrivacyService.instance.showOverlay) {
        _capturing = false;
        return;
      }
      await _captureSnapshot();
      _capturing = false;
    });
  }

  Future<void> _captureSnapshot() async {
    final renderObject = _boundaryKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final boundary = renderObject;
    if (!boundary.attached) return;

    try {
      final ratio = View.of(context).devicePixelRatio.clamp(1.0, 2.0);
      final image = await boundary.toImage(pixelRatio: ratio);
      if (!mounted || !PrivacyService.instance.showOverlay) {
        image.dispose();
        return;
      }
      _snapshot?.dispose();
      setState(() => _snapshot = image);
    } catch (_) {
      // 截图失败时仍显示磨砂兜底层
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PrivacyService.instance,
      builder: (context, _) {
        final show = PrivacyService.instance.showOverlay;
        if (show && _snapshot == null && !_capturing) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleCapture());
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              key: _boundaryKey,
              child: widget.child,
            ),
            if (show)
              Positioned.fill(
                child: _PresbyopiaVeil(
                  snapshot: _snapshot,
                  isDark: EchoColors.isDark,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// 低饱和 + 略降对比，模拟「看不清」的观感。
const _presbyopiaColorFilter = ColorFilter.matrix(<double>[
  0.45, 0.22, 0.18, 0, 8,
  0.18, 0.45, 0.18, 0, 8,
  0.18, 0.20, 0.42, 0, 8,
  0, 0, 0, 0.92, 0,
]);

class _PresbyopiaVeil extends StatelessWidget {
  const _PresbyopiaVeil({
    required this.snapshot,
    required this.isDark,
  });

  final ui.Image? snapshot;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: snapshot != null
          ? _BlurredSnapshot(image: snapshot!, isDark: isDark)
          : _FrostedFallback(isDark: isDark),
    );
  }
}

class _BlurredSnapshot extends StatelessWidget {
  const _BlurredSnapshot({required this.image, required this.isDark});

  final ui.Image image;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final mist = isDark
        ? const Color(0xFF1A1816).withValues(alpha: 0.22)
        : const Color(0xFFF5F0E6).withValues(alpha: 0.18);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColorFiltered(
            colorFilter: _presbyopiaColorFilter,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 52, sigmaY: 52),
              child: RawImage(
                image: image,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.low,
              ),
            ),
          ),
          ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: RawImage(
              image: image,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
            ),
          ),
          ColoredBox(color: mist),
          // 轻微「散光」感：叠一层极淡的径向高光
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.2),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.06 : 0.14),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 截图完成前的即时磨砂（不用高透明度白底，避免多任务里变成白板）。
class _FrostedFallback extends StatelessWidget {
  const _FrostedFallback({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = isDark ? const Color(0xFF121110) : const Color(0xFFEEEBE4);
    final haze = isDark ? const Color(0xFF3A3835) : const Color(0xFFD8D2C8);

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 36, sigmaY: 36),
            child: const SizedBox.expand(),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  base.withValues(alpha: 0.55),
                  haze.withValues(alpha: 0.65),
                  base.withValues(alpha: 0.75),
                ],
              ),
            ),
          ),
          ColorFiltered(
            colorFilter: _presbyopiaColorFilter,
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}
