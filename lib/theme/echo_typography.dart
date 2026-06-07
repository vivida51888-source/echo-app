import 'package:flutter/material.dart';

import 'echo_colors.dart';

/// Echo 排版层级：轻、疏、可读。
abstract final class EchoTypography {
  static const displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.8,
    height: 1.15,
  );

  static const displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.5,
    height: 1.2,
  );

  static const titleLarge = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.2,
    height: 1.6,
  );

  static const titleMedium = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static const bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const bodyMedium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w300,
    height: 1.65,
  );

  static const labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.4,
  );

  static const labelMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    height: 1.5,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.3,
    height: 1.45,
  );

  static const micro = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.3,
  );

  static TextStyle onPrimary(Color color) => displayMedium.copyWith(color: color);
  static TextStyle onSecondary(Color color) => labelMedium.copyWith(color: color);
  static TextStyle onWhisper(Color color) => caption.copyWith(color: color);

  static TextStyle get dayDisplayLarge =>
      displayLarge.copyWith(color: EchoColors.dayTextPrimary);
  static TextStyle get dayDisplayMedium =>
      displayMedium.copyWith(color: EchoColors.dayTextPrimary);
  static TextStyle get dayTitleLarge =>
      titleLarge.copyWith(color: EchoColors.dayTextPrimary);
  static TextStyle get dayTitleMedium =>
      titleMedium.copyWith(color: EchoColors.dayTextPrimary);
  static TextStyle get dayBodyLarge =>
      bodyLarge.copyWith(color: EchoColors.dayTextPrimary);
  static TextStyle get dayBodyMedium =>
      bodyMedium.copyWith(color: EchoColors.dayTextPrimary);
  static TextStyle get dayLabelMedium =>
      labelMedium.copyWith(color: EchoColors.dayTextSecondary);
  static TextStyle get dayCaption =>
      caption.copyWith(color: EchoColors.dayTextWhisper);
  static TextStyle get dayMicro =>
      micro.copyWith(color: EchoColors.dayTextWhisper);

  static TextStyle nightDisplayMedium =
      displayMedium.copyWith(color: EchoColors.nightTextPrimary);
  static TextStyle nightTitleLarge =
      titleLarge.copyWith(color: EchoColors.nightTextPrimary);
  static TextStyle nightLabelMedium =
      labelMedium.copyWith(color: EchoColors.nightTextSecondary);
  static TextStyle nightCaption =
      caption.copyWith(color: EchoColors.nightTextWhisper);
}
