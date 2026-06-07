import 'package:flutter/material.dart';

import '../models/diary_stationery.dart';
import '../theme/echo_colors.dart';

/// 写作页前景色与控件样式（随信纸变化）。
class DiaryWriteChrome {
  const DiaryWriteChrome({
    required this.textPrimary,
    required this.textSecondary,
    required this.textWhisper,
    required this.divider,
    required this.saveFill,
    required this.saveLabel,
    required this.toolbarBorder,
    this.textShadows,
    this.iconColor,
  });

  final Color textPrimary;
  final Color textSecondary;
  final Color textWhisper;
  final Color divider;
  final Color saveFill;
  final Color saveLabel;
  final Color toolbarBorder;
  final List<Shadow>? textShadows;
  final Color? iconColor;

  Color get effectiveIconColor => iconColor ?? textSecondary;

  TextStyle textStyle({
    required Color color,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w300,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      shadows: textShadows,
    );
  }

  static const _softGlowShadows = [
    Shadow(color: Color(0x99000000), blurRadius: 12, offset: Offset(0, 2)),
    Shadow(color: Color(0x66000000), blurRadius: 5, offset: Offset(0, 1)),
  ];

  static const _nightGlowShadows = [
    Shadow(color: Color(0xCC000000), blurRadius: 18, offset: Offset(0, 2)),
    Shadow(color: Color(0x99000000), blurRadius: 8, offset: Offset(0, 1)),
    Shadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0, 0)),
  ];

  static const _nightStationeryChrome = DiaryWriteChrome(
    textPrimary: Color(0xFFFBF8F3),
    textSecondary: Color(0xFFE8E2DA),
    textWhisper: Color(0xFFC9C3BB),
    divider: Color(0x66FFFFFF),
    saveFill: Color(0xFFF0EDE6),
    saveLabel: Color(0xFF2A2340),
    toolbarBorder: Color(0x33FFFFFF),
    textShadows: _nightGlowShadows,
    iconColor: Color(0xFFE8E2DA),
  );

  static bool _usesNightGlow(DiaryStationery stationery) =>
      stationery.id == DiaryStationeries.moonBay.id ||
      stationery.id == DiaryStationeries.rainyWindow.id;

  factory DiaryWriteChrome.forStationery(DiaryStationery stationery) {
    if (_usesNightGlow(stationery)) {
      return _nightStationeryChrome;
    }
    if (stationery.lightForeground) {
      return const DiaryWriteChrome(
        textPrimary: Color(0xFFF8F5F0),
        textSecondary: Color(0xFFD8D2CA),
        textWhisper: Color(0xFFB0AAA2),
        divider: Color(0x55FFFFFF),
        saveFill: Color(0xFFF0EDE6),
        saveLabel: Color(0xFF2A2340),
        toolbarBorder: Color(0x33FFFFFF),
        textShadows: _softGlowShadows,
      );
    }
    return DiaryWriteChrome(
      textPrimary: EchoColors.dayTextPrimary,
      textSecondary: EchoColors.dayTextSecondary,
      textWhisper: EchoColors.dayTextWhisper,
      divider: EchoColors.dayDivider.withValues(alpha: 0.5),
      saveFill: EchoColors.dayTextPrimary,
      saveLabel: EchoColors.daySurface,
      toolbarBorder: EchoColors.dayDivider.withValues(alpha: 0.5),
    );
  }
}
