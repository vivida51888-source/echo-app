import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/locale_service.dart';
import '../utils/locale_assets.dart';

/// 启动闪屏：全屏展示品牌图，淡入 → 停留 → 淡出后进入主界面。
class EchoSplashGate extends StatefulWidget {
  const EchoSplashGate({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 3),
    this.fadeIn = const Duration(milliseconds: 350),
    this.fadeOut = const Duration(milliseconds: 400),
  });

  final Widget child;
  final Duration duration;
  final Duration fadeIn;
  final Duration fadeOut;

  @override
  State<EchoSplashGate> createState() => _EchoSplashGateState();
}

class _EchoSplashGateState extends State<EchoSplashGate>
    with SingleTickerProviderStateMixin {
  static const _splashBackdrop = Color(0xFFF7F2EC);

  late final AnimationController _opacity;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _opacity = AnimationController(vsync: this, value: 0);
    _runSplashSequence();
  }

  Future<void> _runSplashSequence() async {
    await _opacity.animateTo(
      1,
      duration: widget.fadeIn,
      curve: Curves.easeOut,
    );
    await Future<void>.delayed(widget.duration);
    if (!mounted) return;
    await _opacity.animateTo(
      0,
      duration: widget.fadeOut,
      curve: Curves.easeIn,
    );
    if (!mounted) return;
    setState(() => _showSplash = false);
  }

  @override
  void dispose() {
    _opacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showSplash) {
      return widget.child;
    }

    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final asset = LocaleAssets.splashScreen();

        return ColoredBox(
          color: _splashBackdrop,
          child: FadeTransition(
            opacity: _opacity,
            child: _SplashScreen(assetPath: asset),
          ),
        );
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.assetPath});

  final String assetPath;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _EchoSplashGateState._splashBackdrop,
      child: SizedBox.expand(
        child: Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
