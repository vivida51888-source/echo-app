import 'package:flutter/material.dart';

import '../models/echo_appearance_preset.dart';

/// Echo 双色调系统：深夜「此刻」与日间「回响」。
/// 纸色底可通过外观设置切换；深色模式下背景/表面/正文色跟随 [setDarkMode]。
abstract final class EchoColors {
  static EchoPalette _palette = EchoAppearancePresets.warmPaper.palette;
  static String _presetId = EchoAppearancePresets.defaultId;
  static bool _isDark = false;

  static const _darkBg = Color(0xFF121110);
  static const _darkSurface = Color(0xFF242220);
  static const _darkDivider = Color(0xFF3A3835);
  static const _darkBgElevated = Color(0xFF1A1917);

  static const _lightTextPrimary = Color(0xFF1C1C1E);
  static const _lightTextSecondary = Color(0xFF8E8E93);
  static const _lightHint = Color(0xFFB8B4AC);
  static const _lightTextWhisper = Color(0xFFB5B0A8);
  static const _lightSheetHandle = Color(0xFFE5E2DC);

  static const _darkTextPrimary = Color(0xFFF0EDE6);
  static const _darkTextSecondary = Color(0xFF9A958C);
  static const _darkHint = Color(0xFF6E6A64);
  static const _darkTextWhisper = Color(0xFF6E6A64);
  static const _darkSheetHandle = Color(0xFF3A3835);

  static void applyPreset(EchoAppearancePreset preset) {
    _palette = preset.palette;
    _presetId = preset.id;
  }

  static void setDarkMode(bool value) {
    setThemeAppearance(isDark: value);
  }

  static void setThemeAppearance({required bool isDark}) {
    if (_isDark == isDark) return;
    _isDark = isDark;
  }

  static bool get isDark => _isDark;
  static EchoPalette get palette => _palette;
  static String get presetId => _presetId;

  static bool get usesDualTone => false;

  static Color get appBackground =>
      _isDark ? _darkBg : _palette.dayBackground;

  static Color get homeBackground => _isDark
      ? _darkBg
      : (usesDualTone ? _palette.nightBackground : _palette.dayBackground);

  static Color navBorderFor({required bool isHomeTab}) {
    if (_isDark) return _darkDivider;
    if (usesDualTone && isHomeTab) return _palette.nightNavBorder;
    return _palette.dayNavBorder;
  }

  static Color systemNavBarFor({required bool isHomeTab}) =>
      isHomeTab ? homeBackground : appBackground;

  static Color get nightBackground =>
      _isDark ? _darkBg : _palette.nightBackground;
  static Color get nightSurface => _isDark ? _darkSurface : _palette.nightSurface;
  static Color get dayBackground =>
      _isDark ? _darkBg : _palette.dayBackground;
  static Color get daySurface => _isDark ? _darkSurface : _palette.daySurface;
  static Color get dayWriting => _isDark ? _darkBgElevated : _palette.dayWriting;
  static Color get dayDivider => _isDark ? _darkDivider : _palette.dayDivider;
  static Color get dayNavBorder => _isDark ? _darkDivider : _palette.dayNavBorder;
  static Color get nightNavBorder =>
      _isDark ? _darkDivider : _palette.nightNavBorder;
  static Color get insightSurface =>
      _isDark ? _darkSurface : _palette.insightSurface;
  static Color get sheetDivider => _isDark ? _darkDivider : _palette.sheetDivider;

  // —— 此刻 · 首页双色调（仅浅色默认主题）——
  static const nightTextPrimary = Color(0xFF2C2A28);
  static const nightTextSecondary = Color(0xFF7A756D);
  static const nightTextWhisper = Color(0xFFA8A39A);
  static const nightAccent = Color(0xFF2C2A28);
  static const nightOnAccent = Color(0xFFEEEBE4);

  /// 日间/通用正文色（夜间模式下自动变为浅色）。
  static Color get dayTextPrimary =>
      _isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get dayTextSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get dayHint => _isDark ? _darkHint : _lightHint;
  static Color get dayTextWhisper =>
      _isDark ? _darkTextWhisper : _lightTextWhisper;
  static Color get sheetHandle =>
      _isDark ? _darkSheetHandle : _lightSheetHandle;

  static const destructive = Color(0xFFFF3B30);

  static Color get onSurface => dayTextPrimary;
  static Color get onSurfaceSecondary => dayTextSecondary;
  static Color get onSurfaceWhisper => dayTextWhisper;

  /// 「此刻」首页文案：双色调用纸色深字，夜间模式用浅色字。
  static Color get momentTextPrimary =>
      usesDualTone ? nightTextPrimary : dayTextPrimary;
  static Color get momentTextSecondary =>
      usesDualTone ? nightTextSecondary : dayTextSecondary;
  static Color get momentTextWhisper =>
      usesDualTone ? nightTextWhisper : dayTextWhisper;
  static Color get momentSurface =>
      usesDualTone ? nightSurface : daySurface;
  static Color get momentAccent =>
      usesDualTone ? nightAccent : dayTextPrimary;
  static Color get momentOnAccent =>
      usesDualTone ? nightOnAccent : dayBackground;

  static Color sectionCardFill([Color? base]) =>
      (base ?? daySurface).withValues(alpha: _isDark ? 0.55 : 0.5);

  static Color get todoCompletedFill =>
      _isDark ? const Color(0xFF5A8F68) : const Color(0xFF7BA889);
  static Color get todoCompletedSurface =>
      _isDark ? const Color(0xFF1E2A22) : const Color(0xFFE6F2E8);
  static Color get todoCompletedBorder =>
      _isDark ? const Color(0xFF3D5245) : const Color(0xFFC5DCC9);

  static Color get todoImportant =>
      _isDark ? const Color(0xFFD4A574) : const Color(0xFFB8844A);

  /// 主行动按钮：暖色浅底，替代纯黑实心块。
  static Color get primaryButtonFill => _isDark
      ? const Color(0xFF2E2C29)
      : dayWriting.withValues(alpha: 0.92);
  static Color get primaryButtonBorder => _isDark
      ? const Color(0xFF4A4743)
      : dayDivider.withValues(alpha: 0.85);
  static Color get primaryButtonText => dayTextPrimary;
}
