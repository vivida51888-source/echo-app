import 'package:flutter/material.dart';

/// 随 Material 明暗主题切换的正文色（供 [ThemeExtension] 使用）。
@immutable
class EchoThemeColors extends ThemeExtension<EchoThemeColors> {
  const EchoThemeColors({
    required this.textPrimary,
    required this.textSecondary,
    required this.textWhisper,
    required this.accent,
    required this.onAccent,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textWhisper;
  final Color accent;
  final Color onAccent;

  static const light = EchoThemeColors(
    textPrimary: Color(0xFF1C1C1E),
    textSecondary: Color(0xFF8E8E93),
    textWhisper: Color(0xFFB5B0A8),
    accent: Color(0xFF1C1C1E),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = EchoThemeColors(
    textPrimary: Color(0xFFF0EDE6),
    textSecondary: Color(0xFF9A958C),
    textWhisper: Color(0xFF6E6A64),
    accent: Color(0xFFF0EDE6),
    onAccent: Color(0xFF121110),
  );

  @override
  EchoThemeColors copyWith({
    Color? textPrimary,
    Color? textSecondary,
    Color? textWhisper,
    Color? accent,
    Color? onAccent,
  }) {
    return EchoThemeColors(
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textWhisper: textWhisper ?? this.textWhisper,
      accent: accent ?? this.accent,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  EchoThemeColors lerp(EchoThemeColors? other, double t) {
    if (other == null) return this;
    return EchoThemeColors(
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textWhisper: Color.lerp(textWhisper, other.textWhisper, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

extension EchoThemeColorsContext on BuildContext {
  EchoThemeColors get echoTheme =>
      Theme.of(this).extension<EchoThemeColors>() ?? EchoThemeColors.light;
}
