import 'package:flutter/material.dart';

/// 按屏幕宽度适配边距与栅格列数。
abstract final class EchoLayout {
  static double pageHorizontalPadding(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return 16;
    if (w < 400) return 20;
    return 24;
  }

  static int shopGridColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 600) return 3;
    return 2;
  }

  static double shopGridSpacing(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w < 360 ? 10 : 12;
  }

  static int repeatChipColumns(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return 2;
    if (w < 400) return 3;
    return 3;
  }
}
