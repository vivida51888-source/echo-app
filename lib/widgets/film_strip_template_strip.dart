import 'package:flutter/material.dart';

import '../models/photo_wall_material.dart';
import '../services/echo_stats_service.dart';
import '../utils/diary_format.dart';
import 'film_strip_template_spec.dart';
import 'photo_wall_thumb.dart';
import 'scale_tap.dart';

/// 以图一 PNG 为底，仅在窗格内替换为用户照片。
class FilmStripTemplateStrip extends StatelessWidget {
  const FilmStripTemplateStrip({
    super.key,
    required this.photos,
    required this.width,
    required this.material,
    required this.compact,
    required this.showDates,
    required this.enableActions,
    required this.onTapPhoto,
    required this.onEjectPhoto,
  });

  final List<EchoPhotoStat> photos;
  final double width;
  final PhotoWallMaterial material;
  final bool compact;
  final bool showDates;
  final bool enableActions;
  final void Function(EchoPhotoStat photo) onTapPhoto;
  final void Function(EchoPhotoStat photo, VoidCallback flipToFront) onEjectPhoto;

  @override
  Widget build(BuildContext context) {
    final height = width / FilmStripTemplateSpec.aspectRatio;
    final radius = FilmStripTemplateSpec.frameRadius(height);
    final framesVisible = compact ? 3 : FilmStripTemplateSpec.frameCount;

    Widget strip = SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            FilmStripTemplateSpec.assetPath,
            fit: BoxFit.fill,
            width: width,
            height: height,
          ),
          for (var i = 0; i < FilmStripTemplateSpec.frameCount; i++)
            _frameSlot(
              index: i,
              stripWidth: width,
              stripHeight: height,
              radius: radius,
              filled: i < photos.length,
              photo: i < photos.length ? photos[i] : null,
            ),
        ],
      ),
    );

    if (compact && framesVisible < FilmStripTemplateSpec.frameCount) {
      final clipW = width * (framesVisible / FilmStripTemplateSpec.frameCount);
      strip = ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: framesVisible / FilmStripTemplateSpec.frameCount,
          child: SizedBox(
            width: width,
            height: height,
            child: strip,
          ),
        ),
      );
      return SizedBox(width: clipW, height: height, child: strip);
    }

    return strip;
  }

  Widget _frameSlot({
    required int index,
    required double stripWidth,
    required double stripHeight,
    required double radius,
    required bool filled,
    required EchoPhotoStat? photo,
  }) {
    final rect = FilmStripTemplateSpec.frameRect(index);
    final left = rect.left * stripWidth;
    final top = rect.top * stripHeight;
    final w = rect.width * stripWidth;
    final h = rect.height * stripHeight;

    if (!filled || photo == null) {
      return Positioned(
        left: left,
        top: top,
        width: w,
        height: h,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: const ColoredBox(color: Color(0xFF0A0908)),
        ),
      );
    }

    final flipKey = GlobalKey<_TemplateCellFlipState>();

    return Positioned(
      left: left,
      top: top,
      width: w,
      height: h,
      child: _TemplateCellFlip(
        key: flipKey,
        photo: photo,
        width: w,
        height: h,
        radius: radius,
        material: material,
        showDate: showDates,
        compact: compact,
        enableActions: enableActions,
        onTap: () => onTapPhoto(photo),
        onEject: enableActions
            ? () {
                onEjectPhoto(photo, () => flipKey.currentState?.flipToFront());
              }
            : null,
      ),
    );
  }
}

class _TemplateCellFlip extends StatefulWidget {
  const _TemplateCellFlip({
    super.key,
    required this.photo,
    required this.width,
    required this.height,
    required this.radius,
    required this.material,
    required this.showDate,
    required this.compact,
    required this.enableActions,
    required this.onTap,
    this.onEject,
  });

  final EchoPhotoStat photo;
  final double width;
  final double height;
  final double radius;
  final PhotoWallMaterial material;
  final bool showDate;
  final bool compact;
  final bool enableActions;
  final VoidCallback onTap;
  final VoidCallback? onEject;

  @override
  State<_TemplateCellFlip> createState() => _TemplateCellFlipState();
}

class _TemplateCellFlipState extends State<_TemplateCellFlip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flipToFront() => _controller.reverse();

  void _toggle() {
    if (_controller.isCompleted) {
      _controller.reverse();
    } else {
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DiaryFormat.listDateLabel(widget.photo.recordedAt);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.enableActions ? _toggle : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final angle = _controller.value * 3.141592653589793;
          final isBack = angle > 1.5707963267948966;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            child: isBack
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(3.141592653589793),
                    child: _TemplateCellBack(
                      width: widget.width,
                      height: widget.height,
                      radius: widget.radius,
                      onEject: widget.onEject,
                    ),
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(widget.radius),
                    child: ColoredBox(
                      color: const Color(0xFF0A0908),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Opacity(
                            opacity: widget.material.polaroidImageOpacity,
                            child: PhotoWallThumb(
                              path: widget.photo.path,
                              fit: BoxFit.contain,
                            ),
                          ),
                          if (widget.showDate)
                            Positioned(
                              left: 5,
                              bottom: 4,
                              child: Text(
                                dateLabel,
                                style: TextStyle(
                                  fontSize: widget.compact ? 7 : 8,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.9),
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
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _TemplateCellBack extends StatelessWidget {
  const _TemplateCellBack({
    required this.width,
    required this.height,
    required this.radius,
    this.onEject,
  });

  final double width;
  final double height;
  final double radius;
  final VoidCallback? onEject;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: ColoredBox(
        color: const Color(0xFF1A1816),
        child: Center(
          child: onEject != null
              ? ScaleTap(
                  onTap: onEject!,
                  scale: 0.98,
                  child: Text(
                    '吐出拍立得',
                    style: TextStyle(
                      fontSize: (width * 0.09).clamp(7.0, 10.0),
                      color: const Color(0xFF9A9088),
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}
