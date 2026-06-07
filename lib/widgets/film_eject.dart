import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/photo_wall_material.dart';
import '../services/echo_stats_service.dart';
import '../models/film_frame_mood.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../utils/photo_wall_pin_sound.dart';
import 'film_frame_card.dart';
import 'film_frame_spec.dart';
import 'scale_tap.dart';

/// 单张胶片吐出动画 + 导出（逻辑与拍立得一致，样式为胶片边框）。
abstract final class FilmEject {
  static Future<void> present(
    BuildContext context, {
    required EchoPhotoStat photo,
    PhotoWallMaterial material = PhotoWallMaterial.plain,
  }) async {
    if (kIsWeb) return;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'film-eject',
      barrierColor: Colors.black.withValues(alpha: 0.42),
      transitionDuration: const Duration(milliseconds: 520),
      pageBuilder: (ctx, _, __) => _FilmEjectDialog(
        photo: photo,
        material: material,
      ),
      transitionBuilder: (ctx, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    );
  }
}

class _FilmEjectDialog extends StatefulWidget {
  const _FilmEjectDialog({
    required this.photo,
    required this.material,
  });

  final EchoPhotoStat photo;
  final PhotoWallMaterial material;

  @override
  State<_FilmEjectDialog> createState() => _FilmEjectDialogState();
}

class _FilmEjectDialogState extends State<_FilmEjectDialog>
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
          content: Text('胶片已保存到相册'),
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
        '${dir.path}/echo_film_${DateTime.now().millisecondsSinceEpoch}.png',
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
    return _FilmExportRenderer.renderToPng(
      imagePath: widget.photo.path,
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FilmFrameCard(
                  photo: widget.photo,
                  width: 260,
                  showDate: true,
                  dateLabel: dateLabel,
                  showShadow: true,
                ),
                const SizedBox(height: 28),
                Text(
                  '胶片已吐出',
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

abstract final class _FilmExportRenderer {
  static const _exportWidth = 280.0;

  static Future<Uint8List?> renderToPng({
    required String imagePath,
    double pixelRatio = 3,
  }) async {
    if (kIsWeb) return null;

    final frameH = _exportWidth / FilmFrameSpec.aspectRatio;

    final surfaceW = (_exportWidth * pixelRatio).ceil();
    final surfaceH = (frameH * pixelRatio).ceil();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(pixelRatio);

    final window = FilmFrameSpec.photoRect(_exportWidth, frameH);
    final radius = FilmFrameSpec.photoRadius(_exportWidth);
    final photoDst = RRect.fromRectAndRadius(window, Radius.circular(radius));
    final fullDst = Rect.fromLTWH(0, 0, _exportWidth, frameH);

    final templateBytes =
        await rootBundle.load(FilmFrameMood.templateAsset);
    final templateCodec = await ui.instantiateImageCodec(
      templateBytes.buffer.asUint8List(),
    );
    final templateFrame = await templateCodec.getNextFrame();
    final templateImage = templateFrame.image;
    canvas.drawImageRect(
      templateImage,
      Rect.fromLTWH(
        0,
        0,
        templateImage.width.toDouble(),
        templateImage.height.toDouble(),
      ),
      fullDst,
      Paint()..filterQuality = FilterQuality.high,
    );
    templateImage.dispose();

    final file = File(imagePath);
    if (file.existsSync()) {
      try {
        final bytes = await file.readAsBytes();
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;

        final src = Rect.fromLTWH(
          0,
          0,
          image.width.toDouble(),
          image.height.toDouble(),
        );
        final fitted = _coverRect(src.size, window.size);
        final bleed = FilmFrameSpec.photoCoverBleed;
        final dst = Rect.fromCenter(
          center: window.center,
          width: fitted.width * bleed,
          height: fitted.height * bleed,
        );

        canvas.save();
        canvas.clipRRect(photoDst);
        canvas.drawImageRect(
          image,
          src,
          dst,
          Paint()..filterQuality = FilterQuality.high,
        );
        canvas.restore();
        image.dispose();
      } catch (_) {
        canvas.drawRRect(
          photoDst,
          Paint()..color = EchoColors.dayDivider.withValues(alpha: 0.5),
        );
      }
    }

    final picture = recorder.endRecording();
    final surface = await picture.toImage(surfaceW, surfaceH);
    picture.dispose();

    final png = await surface.toByteData(format: ui.ImageByteFormat.png);
    surface.dispose();
    return png?.buffer.asUint8List();
  }

  static Size _coverRect(Size src, Size dst) {
    if (src.width <= 0 || src.height <= 0) return dst;
    final scale = (dst.width / src.width) > (dst.height / src.height)
        ? dst.width / src.width
        : dst.height / src.height;
    return Size(src.width * scale, src.height * scale);
  }
}
