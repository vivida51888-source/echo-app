import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/echo_appearance_service.dart';
import '../services/theme_mode_service.dart';
import '../theme/echo_colors.dart';

/// 同步纸色预设与夜间模式，并刷新系统状态栏。
class EchoThemedScope extends StatelessWidget {
  const EchoThemedScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        EchoAppearanceService.instance,
        ThemeModeService.instance,
      ]),
      builder: (context, _) {
        final isDark = ThemeModeService.instance.isDark(context);
        EchoColors.setThemeAppearance(isDark: isDark);
        _applySystemChrome(isDark);

        return IconTheme(
          data: IconThemeData(
            color: isDark
                ? const Color(0xFF9A958C)
                : EchoColors.dayTextSecondary,
          ),
          child: DefaultTextStyle(
            style: TextStyle(color: EchoColors.dayTextPrimary),
            child: child,
          ),
        );
      },
    );
  }

  void _applySystemChrome(bool isDark) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: EchoColors.appBackground,
        systemNavigationBarIconBrightness:
            isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }
}

/// 页面级纸色底。
class EchoPageBackground extends StatelessWidget {
  const EchoPageBackground({
    super.key,
    required this.child,
    this.homeTone = false,
  });

  final Widget child;
  final bool homeTone;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: homeTone ? EchoColors.homeBackground : EchoColors.appBackground,
      child: child,
    );
  }
}
