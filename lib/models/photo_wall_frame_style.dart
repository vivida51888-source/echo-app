/// 照片墙上单张照片的呈现样式。
enum PhotoWallFrameStyle {
  polaroid,
  filmStrip;

  String get label => switch (this) {
        PhotoWallFrameStyle.polaroid => '拍立得',
        PhotoWallFrameStyle.filmStrip => '胶片',
      };

  static PhotoWallFrameStyle fromName(String? raw) => switch (raw) {
        'film_strip' || 'film' => PhotoWallFrameStyle.filmStrip,
        _ => PhotoWallFrameStyle.polaroid,
      };

  String get storageName => switch (this) {
        PhotoWallFrameStyle.polaroid => 'polaroid',
        PhotoWallFrameStyle.filmStrip => 'film_strip',
      };
}

/// 各样式下的相框尺寸。
abstract final class PhotoWallFrameMetrics {
  static double frameHeight({
    required PhotoWallFrameStyle style,
    required double stripWidth,
    required double imageHeight,
    required bool compact,
    required bool showDate,
  }) {
    switch (style) {
      case PhotoWallFrameStyle.polaroid:
        if (compact) return imageHeight + 12;
        return imageHeight + (showDate ? 17 : 12);
      case PhotoWallFrameStyle.filmStrip:
        return imageHeight;
    }
  }
}
