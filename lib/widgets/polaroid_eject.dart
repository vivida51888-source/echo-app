import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/photo_wall_material.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../utils/photo_wall_pin_sound.dart';
import 'scale_tap.dart';

/// 单张拍立得吐出动画 + 导出分享。
abstract final class PolaroidEject {
  static Future<void> present(
    BuildContext context, {
    required EchoPhotoStat photo,
    PhotoWallMaterial material = PhotoWallMaterial.plain,
  }) async {
    if (kIsWeb) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'polaroid-eject',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (ctx, _, __) => _EjectDialog(
        photo: photo,
        material: material,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }
}

class _EjectDialog extends StatefulWidget {
  const _EjectDialog({
    required this.photo,
    required this.material,
  });

  final EchoPhotoStat photo;
  final PhotoWallMaterial material;

  @override
  State<_EjectDialog> createState() => _EjectDialogState();
}

class _EjectDialogState extends State<_EjectDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _slide;
  late final Animation<double> _scale;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    );
    _slide = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.88, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 1, curve: Curves.easeOutBack),
      ),
    );
    PhotoWallPinSound.playEject();
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (!await Gal.hasAccess()) {
        await Gal.requestAccess();
      }
      if (!await Gal.hasAccess()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('需要相册权限才能保存'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      final bytes = await _captureBytes();
      if (!mounted) return;
      if (bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存失败'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      await Gal.putImageBytes(bytes);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('拍立得已保存到相册'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _share() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final bytes = await _captureBytes();
      if (bytes == null) return;
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/echo_polaroid_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '来自 Echo 的留影',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List?> _captureBytes() {
    if (kIsWeb) return Future.value(null);
    final dateLabel = DiaryFormat.polaroidDateLabel(widget.photo.recordedAt);
    return _PolaroidExportMetrics.renderToPng(
      imagePath: widget.photo.path,
      dateLabel: dateLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = DiaryFormat.polaroidDateLabel(widget.photo.recordedAt);

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t = _slide.value;
            return Transform.translate(
              offset: Offset(0, -120 * (1 - t) + 24 * t),
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: PolaroidExportCard(
                    photo: widget.photo,
                    material: widget.material,
                    dateLabel: dateLabel,
                    showShadow: false,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '拍立得已吐出',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.daySurface.withValues(alpha: 0.92),
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ScaleTap(
                        onTap: _saving ? null : _save,
                        scale: 0.97,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: EchoColors.daySurface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _saving ? '处理中…' : '保存相册',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: EchoColors.dayTextPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ScaleTap(
                        onTap: _saving ? null : _share,
                        scale: 0.97,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: EchoColors.daySurface.withValues(
                                alpha: 0.75,
                              ),
                              width: 0.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '分享',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: EchoColors.daySurface.withValues(
                                alpha: 0.92,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ScaleTap(
                  onTap: () => Navigator.pop(context),
                  scale: 0.97,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      '放回墙上',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.daySurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 可导出的拍立得卡片（白边 + 日期水印，完整保留照片比例）。
class PolaroidExportCard extends StatefulWidget {
  const PolaroidExportCard({
    super.key,
    required this.photo,
    required this.material,
    required this.dateLabel,
    this.showShadow = true,
  });

  final EchoPhotoStat photo;
  final PhotoWallMaterial material;
  final String dateLabel;
  final bool showShadow;

  @override
  State<PolaroidExportCard> createState() => _PolaroidExportCardState();
}

class _PolaroidExportCardState extends State<PolaroidExportCard> {
  static const _frameW = 260.0;
  static const _pad = 18.0;
  static const _maxPhotoH = 360.0;

  Size? _imageSize;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
    _loadImageSize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precached || kIsWeb) return;
    final file = File(widget.photo.path);
    if (file.existsSync()) {
      _precached = true;
      precacheImage(FileImage(file), context);
    }
  }

  Future<void> _loadImageSize() async {
    final size = await _PolaroidExportMetrics.readSize(widget.photo.path);
    if (mounted) setState(() => _imageSize = size);
  }

  @override
  Widget build(BuildContext context) {
    final photo = _PolaroidExportMetrics.layoutPhoto(
      imageSize: _imageSize,
      frameWidth: _frameW,
      maxHeight: _maxPhotoH,
    );

    return Container(
      width: _frameW + _pad * 2,
      padding: const EdgeInsets.all(_pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: _frameW,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: SizedBox(
                  width: photo.width,
                  height: photo.height,
                  child: _PolaroidExportImage(path: widget.photo.path),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: _frameW,
            child: Text(
              widget.dateLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextSecondary.withValues(alpha: 0.85),
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Echo',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextWhisper.withValues(alpha: 0.7),
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// 导出专用：按容器完整显示，不做 cover 裁切。
class _PolaroidExportImage extends StatelessWidget {
  const _PolaroidExportImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.contain);
    }

    final file = File(path);
    if (!file.existsSync()) {
      return ColoredBox(
        color: EchoColors.dayDivider.withValues(alpha: 0.5),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 24,
          color: EchoColors.dayTextWhisper,
        ),
      );
    }

    return Image.file(
      file,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
    );
  }
}

abstract final class _PolaroidExportMetrics {
  static Future<Size?> readSize(String path) async {
    if (kIsWeb) return null;

    final file = File(path);
    if (!file.existsSync()) return null;

    try {
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final size = Size(image.width.toDouble(), image.height.toDouble());
      image.dispose();
      return size;
    } catch (_) {
      return null;
    }
  }

  /// 在拍立得相框内等比缩放，不裁切。
  static ({double width, double height}) layoutPhoto({
    required Size? imageSize,
    required double frameWidth,
    required double maxHeight,
    double fallbackHeight = 220,
  }) {
    if (imageSize == null ||
        imageSize.width <= 0 ||
        imageSize.height <= 0) {
      return (width: frameWidth, height: fallbackHeight);
    }

    final aspect = imageSize.width / imageSize.height;
    var width = frameWidth;
    var height = width / aspect;

    if (height > maxHeight) {
      height = maxHeight;
      width = height * aspect;
    }

    return (width: width, height: height);
  }

  /// 按拍立得精确尺寸绘制 PNG，避免 Widget 截图带来的多余白底。
  static Future<Uint8List?> renderToPng({
    required String imagePath,
    required String dateLabel,
    double pixelRatio = 3,
  }) async {
    if (kIsWeb) return null;

    const frameW = 260.0;
    const pad = 18.0;
    const maxPhotoH = 360.0;
    const gapAfterPhoto = 14.0;
    const gapBeforeEcho = 4.0;

    final imageSize = await readSize(imagePath);
    final photo = layoutPhoto(
      imageSize: imageSize,
      frameWidth: frameW,
      maxHeight: maxPhotoH,
    );

    final dateStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w300,
      color: EchoColors.dayTextSecondary.withValues(alpha: 0.85),
      letterSpacing: 0.6,
    );
    final echoStyle = TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w300,
      color: EchoColors.dayTextWhisper.withValues(alpha: 0.7),
      letterSpacing: 1.2,
    );

    final datePainter = TextPainter(
      text: TextSpan(text: dateLabel, style: dateStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: frameW);

    final echoPainter = TextPainter(
      text: TextSpan(text: 'Echo', style: echoStyle),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: frameW);

    final cardW = frameW + pad * 2;
    final cardH = pad +
        photo.height +
        gapAfterPhoto +
        datePainter.height +
        gapBeforeEcho +
        echoPainter.height +
        pad;

    final surfaceW = (cardW * pixelRatio).ceil();
    final surfaceH = (cardH * pixelRatio).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, cardW, cardH),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFFFFFFFF),
    );

    final photoLeft = pad + (frameW - photo.width) / 2;
    final photoTop = pad;
    final photoDst = Rect.fromLTWH(
      photoLeft,
      photoTop,
      photo.width,
      photo.height,
    );

    final file = File(imagePath);
    if (file.existsSync()) {
      try {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        canvas.save();
        canvas.clipRRect(
          RRect.fromRectAndRadius(photoDst, const Radius.circular(2)),
        );
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(
            0,
            0,
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          photoDst,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.restore();
        image.dispose();
      } catch (_) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(photoDst, const Radius.circular(2)),
          Paint()..color = EchoColors.dayDivider.withValues(alpha: 0.5),
        );
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(photoDst, const Radius.circular(2)),
        Paint()..color = EchoColors.dayDivider.withValues(alpha: 0.5),
      );
    }

    final dateY = pad + photo.height + gapAfterPhoto;
    datePainter.paint(
      canvas,
      Offset(pad + (frameW - datePainter.width) / 2, dateY),
    );

    final echoY = dateY + datePainter.height + gapBeforeEcho;
    echoPainter.paint(
      canvas,
      Offset(pad + (frameW - echoPainter.width) / 2, echoY),
    );

    final picture = recorder.endRecording();
    final surface = await picture.toImage(surfaceW, surfaceH);
    picture.dispose();

    final png = await surface.toByteData(format: ui.ImageByteFormat.png);
    surface.dispose();
    return png?.buffer.asUint8List();
  }
}
