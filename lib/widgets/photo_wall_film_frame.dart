import 'dart:math' as math;

import 'film_strip_template_spec.dart';

/// 胶卷墙布局：每条使用图一模板，按模板宽高比排布。
class FilmStripWallLayout {
  const FilmStripWallLayout({
    required this.rows,
    required this.frameWidth,
    required this.imageHeight,
    required this.stripHeight,
    required this.totalHeight,
  });

  final List<FilmStripRowLayout> rows;
  final double frameWidth;
  final double imageHeight;
  final double stripHeight;
  final double totalHeight;

  static FilmStripWallLayout compute({
    required int count,
    required double wallWidth,
    required bool compact,
    required List<int> seeds,
  }) {
    if (count == 0) {
      return const FilmStripWallLayout(
        rows: [],
        frameWidth: 0,
        imageHeight: 0,
        stripHeight: 0,
        totalHeight: 0,
      );
    }

    final framesPer =
        compact ? 3 : FilmStripTemplateSpec.frameCount;
    final stripHeight = wallWidth / FilmStripTemplateSpec.aspectRatio;
    final frameWidth = wallWidth * FilmStripTemplateSpec.frameWidthFrac;
    final imageHeight = stripHeight * FilmStripTemplateSpec.photoHeight;
    final verticalGap = compact ? 12.0 : 16.0;

    final rows = <FilmStripRowLayout>[];
    var top = 0.0;

    for (var start = 0; start < count; start += framesPer) {
      final n = math.min(framesPer, count - start);

      rows.add(
        FilmStripRowLayout(
          top: top,
          stripWidth: wallWidth,
          frameWidth: frameWidth,
          imageHeight: imageHeight,
          startIndex: start,
          count: n,
        ),
      );

      top += stripHeight + verticalGap;
    }

    return FilmStripWallLayout(
      rows: rows,
      frameWidth: frameWidth,
      imageHeight: imageHeight,
      stripHeight: stripHeight,
      totalHeight: top + 4,
    );
  }
}

class FilmStripRowLayout {
  const FilmStripRowLayout({
    required this.top,
    required this.stripWidth,
    required this.frameWidth,
    required this.imageHeight,
    required this.startIndex,
    required this.count,
  });

  final double top;
  final double stripWidth;
  final double frameWidth;
  final double imageHeight;
  final int startIndex;
  final int count;
}
