import 'package:flutter/material.dart';

import 'theme/echo_colors.dart';
import 'theme/echo_radii.dart';
import 'theme/echo_theme_extension.dart';
import 'theme/echo_typography.dart';
import 'services/theme_mode_service.dart';

class AppTheme {
  AppTheme._();

  // 兼容旧引用
  static Color get creamBackground => EchoColors.appBackground;
  static Color get textPrimary => EchoColors.dayTextPrimary;
  static Color get textSecondary => EchoColors.dayTextSecondary;

  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: EchoColors.appBackground,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerColor: EchoColors.dayDivider,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
        },
      ),
      colorScheme: ColorScheme.light(
        surface: EchoColors.appBackground,
        onSurface: EchoColors.dayTextPrimary,
        primary: EchoColors.dayTextPrimary,
        onPrimary: EchoColors.daySurface,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: EchoColors.appBackground,
        foregroundColor: EchoColors.dayTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: EchoColors.appBackground,
        elevation: 0,
        selectedItemColor: EchoColors.dayTextPrimary,
        unselectedItemColor: EchoColors.dayTextSecondary,
        type: BottomNavigationBarType.fixed,
        enableFeedback: false,
        selectedLabelStyle: EchoTypography.micro,
        unselectedLabelStyle: EchoTypography.micro,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: EchoColors.dayTextPrimary,
        contentTextStyle: EchoTypography.bodyMedium.copyWith(
          color: EchoColors.daySurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EchoColors.daySurface,
        hintStyle: EchoTypography.bodyMedium.copyWith(color: EchoColors.dayHint),
        labelStyle:
            EchoTypography.labelMedium.copyWith(color: EchoColors.dayTextSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: BorderSide(
            color: EchoColors.dayDivider.withValues(alpha: 0.8),
            width: 0.5,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: BorderSide(
            color: EchoColors.dayTextSecondary.withValues(alpha: 0.9),
            width: 1,
          ),
        ),
      ),
      iconTheme: IconThemeData(color: EchoColors.dayTextSecondary),
      listTileTheme: ListTileThemeData(
        iconColor: EchoColors.dayTextSecondary,
        textColor: EchoColors.dayTextPrimary,
      ),
    );

    return base.copyWith(
      extensions: const [EchoThemeColors.light],
      textTheme: TextTheme(
        displayLarge: EchoTypography.dayDisplayLarge,
        displayMedium: EchoTypography.dayDisplayMedium,
        titleLarge: EchoTypography.dayTitleLarge,
        titleMedium: EchoTypography.dayTitleMedium,
        bodyLarge: EchoTypography.dayBodyLarge,
        bodyMedium: EchoTypography.dayBodyMedium,
        labelLarge: EchoTypography.labelLarge.copyWith(
          color: EchoColors.dayTextPrimary,
        ),
        labelMedium: EchoTypography.dayLabelMedium,
        bodySmall: EchoTypography.dayCaption,
        labelSmall: EchoTypography.dayMicro,
      ),
    );
  }

  static ThemeData get dark {
    const bg = Color(0xFF121110);
    const surface = Color(0xFF242220);
    const primary = Color(0xFFF0EDE6);
    const secondary = Color(0xFF9A958C);
    const whisper = Color(0xFF6E6A64);
    const divider = Color(0xFF3A3835);
    const hint = Color(0xFF6E6A64);

    final colorScheme = const ColorScheme.dark(
      surface: bg,
      onSurface: primary,
      onSurfaceVariant: secondary,
      primary: primary,
      onPrimary: bg,
      secondary: secondary,
      onSecondary: primary,
      outline: divider,
      outlineVariant: divider,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      dividerColor: divider,
      disabledColor: whisper,
      iconTheme: const IconThemeData(color: secondary),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
          TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
        },
      ),
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: primary,
        iconTheme: IconThemeData(color: primary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: bg,
        elevation: 0,
        selectedItemColor: primary,
        unselectedItemColor: secondary,
        type: BottomNavigationBarType.fixed,
        enableFeedback: false,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: secondary,
        textColor: primary,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        titleTextStyle: EchoTypography.titleMedium.copyWith(color: primary),
        contentTextStyle: EchoTypography.bodyMedium.copyWith(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EchoRadii.lg),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: EchoTypography.bodyMedium.copyWith(color: hint),
        labelStyle: EchoTypography.labelMedium.copyWith(color: secondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: const BorderSide(color: divider, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: const BorderSide(color: secondary, width: 1),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return secondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return secondary.withValues(alpha: 0.45);
          }
          return divider;
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: surface,
        contentTextStyle: EchoTypography.bodyMedium.copyWith(color: primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
        ),
      ),
    );

    return base.copyWith(
      extensions: const [EchoThemeColors.dark],
      textTheme: TextTheme(
        displayLarge: EchoTypography.displayLarge.copyWith(color: primary),
        displayMedium: EchoTypography.displayMedium.copyWith(color: primary),
        titleLarge: EchoTypography.titleLarge.copyWith(color: primary),
        titleMedium: EchoTypography.titleMedium.copyWith(color: primary),
        bodyLarge: EchoTypography.bodyLarge.copyWith(color: primary),
        bodyMedium: EchoTypography.bodyMedium.copyWith(color: primary),
        labelLarge: EchoTypography.labelLarge.copyWith(color: primary),
        labelMedium: EchoTypography.labelMedium.copyWith(color: secondary),
        bodySmall: EchoTypography.caption.copyWith(color: secondary),
        labelSmall: EchoTypography.micro.copyWith(color: whisper),
      ),
    );
  }

  static ThemeMode resolveThemeMode(EchoThemeMode mode) {
    return mode == EchoThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
  }
}

class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.024),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}
