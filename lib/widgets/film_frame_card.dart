import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/film_frame_mood.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import 'film_frame_spec.dart';

/// 胶片：底层模板（含棋盘格占位）+ 上层照片 [cover] 铺满开窗。
class FilmFrameCard extends StatelessWidget {
  const FilmFrameCard({
    super.key,
    required this.photo,
    required this.width,
    this.height,
    this.showDate = false,
    this.dateLabel,
    this.showShadow = false,
  });

  final EchoPhotoStat photo;
  final double width;
  /// 墙上缩略时传入，与拍立得画面区同高；未指定则用模板原比例。
  final double? height;
  final bool showDate;
  final String? dateLabel;
  final bool showShadow;

  double get naturalHeight => width / FilmFrameSpec.aspectRatio;

  @override
  Widget build(BuildContext context) {
    final slotH = height;
    final wallSlot =
        slotH != null && (slotH - naturalHeight).abs() >= 0.5;

    final frame = _FilmFrameContent(
      photo: photo,
      width: width,
      height: naturalHeight,
      showDate: showDate,
      dateLabel: dateLabel,
      wallSlot: wallSlot,
    );

    if (!wallSlot) {
      return _FilmFrameShell(
        width: width,
        height: naturalHeight,
        showShadow: showShadow,
        child: frame,
      );
    }

    return _FilmFrameShell(
      width: width,
      height: slotH,
      showShadow: showShadow,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          child: frame,
        ),
      ),
    );
  }
}

class _FilmFrameShell extends StatelessWidget {
  const _FilmFrameShell({
    required this.width,
    required this.height,
    required this.child,
    this.showShadow = false,
  });

  final double width;
  final double height;
  final Widget child;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: showShadow
          ? BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: EchoColors.dayTextPrimary.withValues(alpha: 0.14),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            )
          : null,
      child: child,
    );
  }
}

class _FilmFrameContent extends StatelessWidget {
  const _FilmFrameContent({
    required this.photo,
    required this.width,
    required this.height,
    required this.showDate,
    this.wallSlot = false,
    this.dateLabel,
  });

  final EchoPhotoStat photo;
  final double width;
  final double height;
  final bool showDate;
  final bool wallSlot;
  final String? dateLabel;

  @override
  Widget build(BuildContext context) {
    final window = wallSlot
        ? FilmFrameSpec.photoRectForWall(width, height)
        : FilmFrameSpec.photoRect(width, height);
    final radius = wallSlot
        ? FilmFrameSpec.photoRadiusForWall(width)
        : FilmFrameSpec.photoRadius(width);
    final coverBleed = wallSlot
        ? FilmFrameSpec.photoWallCoverBleed
        : FilmFrameSpec.photoCoverBleed;
    // 圆角开窗四角需从中心放大；吐出胶片等大图同样适用。
    const coverAlign = Alignment.center;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        fit: StackFit.expand,
        children: [
          Image.asset(
            FilmFrameMood.templateAsset,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
          ),
          Positioned(
            left: window.left,
            top: window.top,
            width: window.width,
            height: window.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(radius),
              child: Transform.scale(
                scale: coverBleed,
                alignment: coverAlign,
                child: _FilmPhotoCover(path: photo.path),
              ),
            ),
          ),
          if (showDate && dateLabel != null)
            Positioned(
              left: window.left + 5,
              bottom: height - window.bottom + 4,
              child: Text(
                dateLabel!,
                style: TextStyle(
                  fontSize: (width * 0.09).clamp(6.0, 9.0),
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.88),
                  shadows: const [
                    Shadow(
                      color: Color(0xE6000000),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilmPhotoCover extends StatelessWidget {
  const _FilmPhotoCover({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        filterQuality: FilterQuality.medium,
        gaplessPlayback: true,
      );
    }

    final file = File(path);
    if (!file.existsSync()) {
      return ColoredBox(
        color: EchoColors.dayDivider.withValues(alpha: 0.45),
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 20,
            color: EchoColors.dayTextWhisper,
          ),
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
    );
  }
}
