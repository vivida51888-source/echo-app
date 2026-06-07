import 'dart:ui';

/// 胶片模板画面区（与 [film_frame_template.png] 对齐，归一化坐标）。
abstract final class FilmFrameSpec {
  static const srcWidth = 768.0;
  static const srcHeight = 1024.0;

  static const aspectRatio = srcWidth / srcHeight;

  /// 模板内棋盘格开窗（扫描校准，略外扩以盖住边缘）。
  static const photoLeft = 0.094;
  static const photoTop = 0.048;
  static const photoWidth = 0.815;
  static const photoHeight = 0.902;

  /// 照片略放大，避免 cover 取整或圆角裁切露出棋盘格。
  static const photoCoverBleed = 1.03;

  /// 留影墙缩略格：圆角处需更大 cover，避免左上/右上露棋盘格。
  static const photoWallCoverBleed = 1.09;

  static Rect photoRect(double frameWidth, double frameHeight) => Rect.fromLTWH(
        photoLeft * frameWidth,
        photoTop * frameHeight,
        photoWidth * frameWidth,
        photoHeight * frameHeight,
      );

  /// 留影墙缩略：开窗四向外扩（尤其上沿与左右上角）。
  static Rect photoRectForWall(double frameWidth, double frameHeight) {
    final base = photoRect(frameWidth, frameHeight);
    final bleedX = (frameWidth * 0.02).clamp(2.5, 10.0);
    final bleedTop = (frameHeight * 0.018).clamp(2.5, 12.0);
    final bleedBottom = (frameHeight * 0.01).clamp(1.5, 8.0);
    return Rect.fromLTRB(
      base.left - bleedX,
      base.top - bleedTop,
      base.right + bleedX,
      base.bottom + bleedBottom,
    );
  }

  static double photoRadius(double frameWidth) =>
      (frameWidth * photoWidth * 0.052).clamp(6.0, 18.0);

  /// 墙上略减圆角，减轻对角露底。
  static double photoRadiusForWall(double frameWidth) =>
      (photoRadius(frameWidth) * 0.88).clamp(4.0, 14.0);

  static ({int left, int top, int right, int bottom}) photoPixelWindow(
    int imageWidth,
    int imageHeight,
  ) =>
      (
        left: (imageWidth * photoLeft).round(),
        top: (imageHeight * photoTop).round(),
        right: (imageWidth * (photoLeft + photoWidth)).round(),
        bottom: (imageHeight * (photoTop + photoHeight)).round(),
      );
}
