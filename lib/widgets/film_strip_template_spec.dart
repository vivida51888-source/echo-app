import 'dart:ui';

/// 图一胶卷模板（1024×575）上五格画面的归一化坐标。
abstract final class FilmStripTemplateSpec {
  static const assetPath = 'assets/images/film_strip_template_5.png';

  static const srcWidth = 1024.0;
  static const srcHeight = 575.0;

  static const aspectRatio = srcWidth / srcHeight;

  static const frameCount = 5;

  /// 画面区相对条带的位置（对齐模板实测）。
  static const photoTop = 0.157;
  static const photoHeight = 0.690;
  static const photoLeft = 0.0078;
  static const photoGap = 0.0044;

  static double get frameWidthFrac {
    final inner = 1 - 2 * photoLeft - photoGap * (frameCount - 1);
    return inner / frameCount;
  }

  static Rect frameRect(int index) {
    assert(index >= 0 && index < frameCount);
    final fw = frameWidthFrac;
    return Rect.fromLTWH(
      photoLeft + index * (fw + photoGap),
      photoTop,
      fw,
      photoHeight,
    );
  }

  static double frameRadius(double stripHeight) =>
      (stripHeight * photoHeight * 0.028).clamp(3.0, 8.0);
}
