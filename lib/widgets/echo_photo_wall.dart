import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gal/gal.dart';

import '../models/photo_wall_frame_style.dart';
import '../models/photo_wall_material.dart';
import '../models/weather_mood.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_stats_service.dart';
import '../services/photo_wall_settings_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import 'echo_charm.dart';
import 'echo_empty_state.dart';
import '../utils/photo_wall_pin_sound.dart';
import 'film_frame_card.dart';
import 'photo_eject.dart';
import 'photo_wall_surface.dart';
import 'photo_wall_thumb.dart';
import 'scale_tap.dart';

/// 将照片墙 / 海报保存到系统相册。
class EchoPhotoWallExport {
  EchoPhotoWallExport._();

  static Future<bool> saveToGallery(GlobalKey boundaryKey) async {
    if (kIsWeb) return false;

    final context = boundaryKey.currentContext;
    if (context == null) return false;

    final boundary = context.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return false;

    if (!await Gal.hasAccess()) {
      await Gal.requestAccess();
    }
    if (!await Gal.hasAccess()) return false;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return false;

    await Gal.putImageBytes(byteData.buffer.asUint8List());
    return true;
  }

  /// 离屏渲染海报后导出，避免影响当前页面布局。
  static Future<bool> savePoster({
    required BuildContext context,
    required Widget poster,
  }) async {
    if (kIsWeb) return false;

    final boundaryKey = GlobalKey();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: -10000,
        top: 0,
        child: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: boundaryKey,
            child: poster,
          ),
        ),
      ),
    );

    Overlay.of(context).insert(entry);
    await Future<void>.delayed(const Duration(milliseconds: 150));

    try {
      return await saveToGallery(boundaryKey);
    } finally {
      entry.remove();
    }
  }
}

/// Echo 生活感照片墙。
class EchoPhotoWall extends StatefulWidget {
  const EchoPhotoWall({
    super.key,
    required this.items,
    required this.isWeekly,
    this.compact = false,
    this.boundaryKey,
    this.emptyMessage,
    this.periodKey,
    this.material,
    this.customWallPath,
    this.enablePinAnimation = true,
    this.pinAnimationScope = 'wall',
    this.enablePolaroidActions = false,
    this.showDates,
  });

  final List<EchoWallPin> items;
  final bool isWeekly;
  final bool compact;
  final GlobalKey? boundaryKey;
  final String? emptyMessage;
  /// 区分周/月切换，避免整墙重播动效。
  final String? periodKey;
  final PhotoWallMaterial? material;
  final String? customWallPath;
  final bool enablePinAnimation;
  /// 与 [enablePinAnimation] 配合，Hub / 留影详情各自记录是否已播放。
  final String pinAnimationScope;
  /// 长按翻转、背面吐出拍立得（Hub / 对照 / 导出应关闭）。
  final bool enablePolaroidActions;
  /// 为 null 时读取 [PhotoWallSettingsService.showPhotoDates]。
  final bool? showDates;

  @override
  State<EchoPhotoWall> createState() => _EchoPhotoWallState();
}

class _EchoPhotoWallState extends State<EchoPhotoWall> {
  @override
  void initState() {
    super.initState();
    PhotoWallSettingsService.instance.addListener(_onSettingsChanged);
  }

  @override
  void dispose() {
    PhotoWallSettingsService.instance.removeListener(_onSettingsChanged);
    super.dispose();
  }

  void _onSettingsChanged() {
    if (mounted) setState(() {});
  }

  bool get _showDates {
    if (widget.compact) return false;
    return widget.showDates ??
        PhotoWallSettingsService.instance.showPhotoDates;
  }

  @override
  Widget build(BuildContext context) {
    final display = widget.items;
    final material = widget.compact
        ? PhotoWallMaterial.plain
        : (widget.material ?? PhotoWallMaterial.plain);
    final frameStyle = PhotoWallSettingsService.instance.frameStyle;
    final isFilm = frameStyle == PhotoWallFrameStyle.filmStrip;
    final usePinDrop =
        widget.enablePinAnimation && !widget.compact && !isFilm;

    if (display.isEmpty) {
      final hubWallOnly =
          !widget.compact && widget.pinAnimationScope == 'hub';
      if (hubWallOnly) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxW = constraints.maxWidth;
            final width = maxW.isFinite && maxW > 0 ? maxW : 320.0;
            final height = material.hubEmptyPreviewHeight(width);
            return PhotoWallSurface(
              material: material,
              compact: widget.compact,
              customImagePath: widget.customWallPath,
              child: SizedBox(height: height),
            );
          },
        );
      }
      return PhotoWallSurface(
        material: material,
        compact: widget.compact,
        customImagePath: widget.customWallPath,
        child: Center(
          child: EchoEmptyState(
            charm: EchoCharmKind.polaroid,
            compact: widget.compact,
            message: widget.emptyMessage ??
                (widget.compact
                    ? '还没有照片'
                    : '这一段还没有照片\n写作时添上一张，这里会慢慢拼成一面墙'),
          ),
        ),
      );
    }

    final wall = PhotoWallSurface(
      material: material,
      compact: widget.compact,
      customImagePath: widget.customWallPath,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const inset = 16.0;
          final wallWidth = constraints.maxWidth - inset * 2;

          final layouts = PhotoWallLayout.compute(
            count: display.length,
            wallWidth: wallWidth,
            isWeekly: widget.isWeekly,
            compact: widget.compact,
            frameStyle: frameStyle,
            showDates: _showDates,
            seeds: display.map((p) => p.layoutSeed).toList(),
          );

          var totalHeight = layouts.totalHeight;
          final frameHeight = layouts.items.isEmpty
              ? 0.0
              : PhotoWallFrameMetrics.frameHeight(
                  style: frameStyle,
                  stripWidth: layouts.items.first.width,
                  imageHeight: layouts.items.first.imageHeight,
                  compact: widget.compact,
                  showDate: _showDates,
                );

          final pinLayers = <Widget>[];
          for (var i = 0; i < display.length; i++) {
            final path = display[i].photo.path;
            final layout = layouts.items[i];
            final left = layout.left;
            final top = layout.top;
            final bottom = top + frameHeight + layout.width * layout.rotation.abs() * 0.2;
            if (bottom > totalHeight) totalHeight = bottom;

            final flipKey = GlobalKey<_FlipWallPhotoState>();

            final photo = FlipWallPhoto(
              key: flipKey,
              photo: display[i].photo,
              width: layout.width,
              imageHeight: layout.imageHeight,
              showDate: _showDates,
              material: material,
              frameStyle: frameStyle,
              compact: widget.compact,
              onEject: widget.enablePolaroidActions
                  ? () {
                      PhotoEject.present(
                        context,
                        photo: display[i].photo,
                        material: material,
                      ).then((_) {
                        flipKey.currentState?.flipToFront();
                      });
                    }
                  : null,
            );

            final framed = usePinDrop
                ? _PinDropPhoto(
                    key: ValueKey(
                      '${widget.periodKey ?? 'wall'}-$path',
                    ),
                    photoPath: path,
                    pinAnimationScope: widget.pinAnimationScope,
                    baseRotation: layout.rotation,
                    material: material,
                    staggerIndex: display.length - 1 - i,
                    enabled: true,
                    child: photo,
                  )
                : Transform.rotate(
                    angle: layout.rotation,
                    child: photo,
                  );

            pinLayers.add(
              Positioned(
                left: left,
                top: top,
                child: _PolaroidInteraction(
                  enableFlip: widget.enablePolaroidActions,
                  onFlip: () => flipKey.currentState?.toggleFlip(),
                  onTapImage: () => openPhotoLightbox(
                    context,
                    display[i].photo.path,
                    photo: display[i].photo,
                    material: material,
                  ),
                  child: framed,
                ),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(inset, inset, inset, 12),
            child: SizedBox(
              width: wallWidth,
              height: totalHeight + 8,
              child: Stack(
                clipBehavior: Clip.none,
                children: pinLayers,
              ),
            ),
          );
        },
      ),
    );

    if (widget.boundaryKey == null) return wall;

    return RepaintBoundary(
      key: widget.boundaryKey,
      child: wall,
    );
  }

}

/// 新照片从上方轻轻落下、微旋转落定。
class _PinDropPhoto extends StatefulWidget {
  const _PinDropPhoto({
    super.key,
    required this.photoPath,
    required this.pinAnimationScope,
    required this.baseRotation,
    required this.material,
    required this.staggerIndex,
    required this.enabled,
    required this.child,
  });

  final String photoPath;
  final String pinAnimationScope;
  final double baseRotation;
  final PhotoWallMaterial material;
  final int staggerIndex;
  final bool enabled;
  final Widget child;

  @override
  State<_PinDropPhoto> createState() => _PinDropPhotoState();
}

class _PinDropPhotoState extends State<_PinDropPhoto>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double>? _drop;
  Animation<double>? _spin;
  Animation<double>? _develop;
  bool _playedSound = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(covariant _PinDropPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photoPath != widget.photoPath ||
        oldWidget.pinAnimationScope != widget.pinAnimationScope ||
        oldWidget.enabled != widget.enabled) {
      _controller?.dispose();
      _controller = null;
      _drop = null;
      _spin = null;
      _develop = null;
      _playedSound = false;
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    final shouldAnimate = widget.enabled &&
        !PhotoWallSettingsService.instance.isPinSeenInScope(
          widget.photoPath,
          widget.pinAnimationScope,
        );

    if (!shouldAnimate) return;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _drop = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutBack,
    );
    _develop = CurvedAnimation(
      parent: _controller!,
      curve: const Interval(0, 0.62, curve: Curves.easeOut),
    );
    _spin = Tween<double>(begin: -0.12, end: 0).animate(
      CurvedAnimation(
        parent: _controller!,
        curve: const Interval(0.15, 1, curve: Curves.easeOutCubic),
      ),
    );

    Future<void>.delayed(Duration(milliseconds: widget.staggerIndex * 90), () {
      if (!mounted || _controller == null) return;
      if (!_playedSound) {
        _playedSound = true;
        PhotoWallPinSound.play(widget.material);
      }
      _controller!.forward().whenComplete(() {
        PhotoWallSettingsService.instance.markPinSeenInScope(
          widget.photoPath,
          widget.pinAnimationScope,
        );
      });
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final controller = _controller;
    if (controller == null) {
      return Transform.rotate(
        angle: widget.baseRotation,
        child: child,
      );
    }

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = _drop!.value;
        final extraSpin = _spin!.value;
        final develop = _develop!.value;
        final body = Transform.rotate(
          angle: widget.baseRotation + extraSpin,
          child: Opacity(
            opacity: 0.42 + develop * 0.58,
            child: child,
          ),
        );

        return Transform.translate(
          offset: Offset(0, -48 * (1 - t)),
          child: develop < 0.98
              ? ColorFiltered(
                  colorFilter: ColorFilter.matrix(
                    _developMatrix(1 - develop),
                  ),
                  child: body,
                )
              : body,
        );
      },
    );
  }
}

List<double> _developMatrix(double sepiaStrength) {
  final s = sepiaStrength.clamp(0.0, 1.0);
  final r = 0.393 * s + (1 - s);
  final g = 0.769 * s;
  final b = 0.189 * s;
  final g2 = 0.349 * s + (1 - s);
  final g3 = 0.686 * s;
  final g4 = 0.168 * s;
  final b2 = 0.272 * s;
  final b3 = 0.534 * s;
  final b4 = 0.131 * s + (1 - s);
  return [
    r, g, b, 0, 0,
    g2, g3, g4, 0, 0,
    b2, b3, b4, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

/// 两面墙对照：上一段 vs 当前。
class EchoPhotoWallCompare extends StatelessWidget {
  const EchoPhotoWallCompare({
    required this.current,
    required this.previous,
    required this.isWeekly,
  });

  final EchoPeriodStatistics current;
  final EchoPeriodStatistics previous;
  final bool isWeekly;

  @override
  Widget build(BuildContext context) {
    final prevLabel = isWeekly ? '上周' : '上月';
    final currLabel = isWeekly ? '本周' : '本月';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CompareColumn(
            label: prevLabel,
            count: previous.photoCount,
            child: EchoPhotoWall(
              items: previous.wallPins,
              isWeekly: isWeekly,
              compact: true,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CompareColumn(
            label: currLabel,
            count: current.photoCount,
            child: EchoPhotoWall(
              items: current.wallPins,
              isWeekly: isWeekly,
              compact: true,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompareColumn extends StatelessWidget {
  const _CompareColumn({
    required this.label,
    required this.count,
    required this.child,
  });

  final String label;
  final int count;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: EchoColors.dayTextSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '$count 张',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextWhisper,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class PhotoWallLayoutItem {
  const PhotoWallLayoutItem({
    required this.left,
    required this.top,
    required this.width,
    required this.imageHeight,
    required this.rotation,
  });

  final double left;
  final double top;
  final double width;
  final double imageHeight;
  final double rotation;
}

class PhotoWallLayout {
  const PhotoWallLayout({required this.items, required this.totalHeight});

  final List<PhotoWallLayoutItem> items;
  final double totalHeight;

  static double _unit(int seed, int salt) {
    var h = seed ^ (salt * 0x9E3779B9);
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = ((h >> 16) ^ h) * 0x45d9f3b;
    h = (h >> 16) ^ h;
    return (h.abs() % 10000) / 10000.0;
  }

  static PhotoWallLayout compute({
    required int count,
    required double wallWidth,
    required bool isWeekly,
    required bool compact,
    required PhotoWallFrameStyle frameStyle,
    required bool showDates,
    required List<int> seeds,
  }) {
    if (count == 0) {
      return const PhotoWallLayout(items: [], totalHeight: 0);
    }

    final columns = _columnCount(
      isWeekly: isWeekly,
      compact: compact,
    );
    final horizontalGap = compact ? 6.0 : 8.0;
    final verticalGap = compact ? 8.0 : 11.0;
    final cellWidth =
        (wallWidth - horizontalGap * (columns - 1)) / columns;
    final imageHeight = cellWidth * (compact ? 0.78 : 0.82);
    final frameHeight = PhotoWallFrameMetrics.frameHeight(
      style: frameStyle,
      stripWidth: cellWidth,
      imageHeight: imageHeight,
      compact: compact,
      showDate: showDates,
    );

    final items = <PhotoWallLayoutItem>[];
    var rowBottom = 0.0;

    for (var i = 0; i < count; i++) {
      final seed = seeds[i];
      final s1 = _unit(seed, i);
      final s2 = _unit(seed, i + 17);
      final s3 = _unit(seed, i + 29);

      final row = i ~/ columns;
      final col = i % columns;

      final rotation = frameStyle == PhotoWallFrameStyle.filmStrip
          ? (s3 - 0.5) * (compact ? 0.04 : 0.05)
          : (s3 - 0.5) * (compact ? 0.06 : 0.08);
      final left = col * (cellWidth + horizontalGap);
      final top = row * (frameHeight + verticalGap);

      items.add(
        PhotoWallLayoutItem(
          left: left + (s1 - 0.5) * 2,
          top: top + (s2 - 0.5) * 2,
          width: cellWidth,
          imageHeight: imageHeight,
          rotation: rotation,
        ),
      );

      final bottom = top + frameHeight + cellWidth * rotation.abs() * 0.2;
      if (bottom > rowBottom) rowBottom = bottom;
    }

    return PhotoWallLayout(
      items: items,
      totalHeight: rowBottom + 6,
    );
  }

  static int _columnCount({
    required bool isWeekly,
    required bool compact,
  }) {
    if (compact) return 3;
    return 5;
  }
}

/// 长按翻转 / 轻点放大。
class _PolaroidInteraction extends StatelessWidget {
  const _PolaroidInteraction({
    required this.enableFlip,
    required this.onFlip,
    required this.onTapImage,
    required this.child,
  });

  final bool enableFlip;
  final VoidCallback onFlip;
  final VoidCallback onTapImage;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: enableFlip ? onFlip : null,
      onTap: onTapImage,
      child: child,
    );
  }
}

class FlipWallPhoto extends StatefulWidget {
  const FlipWallPhoto({
    super.key,
    required this.photo,
    required this.width,
    required this.imageHeight,
    required this.showDate,
    this.material = PhotoWallMaterial.plain,
    this.frameStyle = PhotoWallFrameStyle.polaroid,
    this.compact = false,
    this.onEject,
  });

  final EchoPhotoStat photo;
  final double width;
  final double imageHeight;
  final bool showDate;
  final PhotoWallMaterial material;
  final PhotoWallFrameStyle frameStyle;
  final bool compact;
  final VoidCallback? onEject;

  @override
  State<FlipWallPhoto> createState() => _FlipWallPhotoState();
}

class _FlipWallPhotoState extends State<FlipWallPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _showBack = false;

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

  void toggleFlip() {
    _toggleFlip();
  }

  void flipToFront() {
    if (!_showBack) return;
    _toggleFlip();
  }

  void _toggleFlip() {
    setState(() => _showBack = !_showBack);
    if (_showBack) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DiaryFormat.listDateLabel(widget.photo.recordedAt);
    final isFilm = widget.frameStyle == PhotoWallFrameStyle.filmStrip;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
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
                    child: isFilm
                        ? _FilmFrameBack(
                            width: widget.width,
                            height: widget.imageHeight,
                            onEject: widget.onEject,
                          )
                        : _PolaroidBack(
                            width: widget.width,
                            imageHeight: widget.imageHeight,
                            tint: WeatherMood.tintColor(widget.photo.moodWeather),
                            material: widget.material,
                            onEject: widget.onEject,
                          ),
                  )
                : isFilm
                    ? FilmFrameCard(
                        photo: widget.photo,
                        width: widget.width,
                        height: widget.imageHeight,
                        showDate: widget.showDate,
                        dateLabel: dateLabel,
                      )
                    : _PolaroidFront(
                        width: widget.width,
                        imageHeight: widget.imageHeight,
                        tint: WeatherMood.tintColor(widget.photo.moodWeather),
                        showDate: widget.showDate,
                        dateLabel: dateLabel,
                        path: widget.photo.path,
                        material: widget.material,
                      ),
          );
      },
    );
  }
}

class _FilmFrameBack extends StatelessWidget {
  const _FilmFrameBack({
    required this.width,
    required this.height,
    this.onEject,
  });

  final double width;
  final double height;
  final VoidCallback? onEject;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ColoredBox(
        color: const Color(0xFF1A1816),
        child: Center(
          child: onEject != null
              ? ScaleTap(
                  onTap: onEject!,
                  scale: 0.98,
                  child: Text(
                    '吐出胶片',
                    style: TextStyle(
                      fontSize: (width * 0.11).clamp(7.5, 10.0),
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF9A9088),
                      letterSpacing: 0.35,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

class _PolaroidFront extends StatelessWidget {
  const _PolaroidFront({
    required this.width,
    required this.imageHeight,
    required this.tint,
    required this.showDate,
    required this.dateLabel,
    required this.path,
    this.material = PhotoWallMaterial.plain,
  });

  final double width;
  final double imageHeight;
  final Color tint;
  final bool showDate;
  final String dateLabel;
  final String path;
  final PhotoWallMaterial material;

  @override
  Widget build(BuildContext context) {
    final frameTint = material.usesTranslucentPolaroid
        ? tint.withValues(alpha: material.polaroidFrameAlpha)
        : tint;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: width,
          decoration: BoxDecoration(
            color: frameTint,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: frameTint.withValues(
                alpha: material.usesTranslucentPolaroid ? 0.45 : 0.6,
              ),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(
                  alpha: material.polaroidShadowAlpha,
                ),
                blurRadius: 8,
                offset: const Offset(1, 3),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(4, 4, 4, showDate ? 5 : 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(1),
                child: SizedBox(
                  width: width - 8,
                  height: imageHeight,
                  child: Opacity(
                    opacity: material.polaroidImageOpacity,
                    child: PhotoWallThumb(path: path),
                  ),
                ),
              ),
              if (showDate) ...[
                const SizedBox(height: 2),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextWhisper,
                    height: 1.1,
                  ),
                ),
              ],
            ],
          ),
        ),
        PhotoWallAttachWidget(material: material, width: width),
      ],
    );
  }
}

class _PolaroidBack extends StatelessWidget {
  const _PolaroidBack({
    required this.width,
    required this.imageHeight,
    required this.tint,
    this.onEject,
    this.material = PhotoWallMaterial.plain,
  });

  final double width;
  final double imageHeight;
  final Color tint;
  final VoidCallback? onEject;
  final PhotoWallMaterial material;

  @override
  Widget build(BuildContext context) {
    final bodyHeight = imageHeight + 18;
    final backAlpha = material.usesTranslucentPolaroid ? 0.42 : 0.92;

    return Container(
      width: width,
      height: bodyHeight,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: backAlpha),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(
            alpha: material.usesTranslucentPolaroid ? 0.45 : 0.8,
          ),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(
              alpha: material.polaroidShadowAlpha,
            ),
            blurRadius: 8,
            offset: const Offset(1, 3),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: onEject != null
          ? ScaleTap(
              onTap: onEject!,
              scale: 0.98,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Text(
                  '吐出拍立得',
                  style: TextStyle(
                    fontSize: (width * 0.11).clamp(7.5, 9.5),
                    fontWeight: FontWeight.w400,
                    color: EchoColors.dayTextSecondary,
                    letterSpacing: 0.35,
                  ),
                ),
              ),
            )
          : null,
    );
  }
}

void openPhotoLightbox(
  BuildContext context,
  String path, {
  EchoPhotoStat? photo,
  PhotoWallMaterial material = PhotoWallMaterial.plain,
}) {
  Navigator.of(context).push(
    AppPageRoute<void>(
      builder: (_) => _PhotoLightbox(
        path: path,
        photo: photo,
        material: material,
      ),
    ),
  );
}

class _PhotoLightbox extends StatelessWidget {
  const _PhotoLightbox({
    required this.path,
    this.photo,
    this.material = PhotoWallMaterial.plain,
  });

  final String path;
  final EchoPhotoStat? photo;
  final PhotoWallMaterial material;

  @override
  Widget build(BuildContext context) {
    final ejectLabel =
        PhotoWallSettingsService.instance.frameStyle ==
                PhotoWallFrameStyle.filmStrip
            ? '吐出胶片'
            : '吐出拍立得';

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.94),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: Center(
                      child: PhotoWallThumb(
                        path: path,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: ScaleTap(
                onTap: () => Navigator.pop(context),
                scale: 0.92,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
          if (photo != null)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ScaleTap(
                    onTap: () {
                      Navigator.pop(context);
                      PhotoEject.present(
                        context,
                        photo: photo!,
                        material: material,
                      );
                    },
                    scale: 0.97,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        ejectLabel,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: Colors.white70,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
