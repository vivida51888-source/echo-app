import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../models/future_letter.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../utils/future_letter_copy.dart';
import 'scale_tap.dart';

/// 未来来信视觉状态。
enum FutureLetterVisualState {
  sealed,
  ready,
  opened,
}

/// 列表中的信封卡片。
class FutureLetterEnvelopeTile extends StatelessWidget {
  const FutureLetterEnvelopeTile({
    super.key,
    required this.letter,
    required this.state,
    required this.onDelete,
    this.footer,
  });

  final FutureLetter letter;
  final FutureLetterVisualState state;
  final VoidCallback onDelete;
  final Widget? footer;

  static const _envelopeHeight = 118.0;

  @override
  Widget build(BuildContext context) {
    final status = FutureLetterCopy.listStatus(letter);
    final dueLine = tr(
      '${DiaryFormat.listDateLabel(letter.deliverAt)} 送达',
      'Due ${DiaryFormat.listDateLabel(letter.deliverAt)}',
    );
    final isOpened = state == FutureLetterVisualState.opened;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _envelopeHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  painter: _EnvelopePainter(
                    state: state,
                    isDark: EchoColors.isDark,
                  ),
                  size: const Size(double.infinity, _envelopeHeight),
                ),
                Positioned(
                  left: 20,
                  right: 68,
                  top: isOpened ? 28 : 74,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isOpened) ...[
                        Text(
                          letter.previewLine(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w300,
                            color: EchoColors.dayTextPrimary,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      Text(
                        status,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: state == FutureLetterVisualState.ready
                              ? EchoColors.dayTextPrimary
                              : EchoColors.dayTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueLine,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          color: EchoColors.dayTextWhisper,
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 6,
                  left: 4,
                  child: ScaleTap(
                    onTap: onDelete,
                    scale: 0.9,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.more_horiz,
                        size: 18,
                        color: EchoColors.dayTextWhisper.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: footer!,
              ),
            ),
        ],
      ),
    );
  }
}

class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter({
    required this.state,
    required this.isDark,
  });

  final FutureLetterVisualState state;
  final bool isDark;

  static const _bodyTop = 28.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, _bodyTop, w, size.height - _bodyTop),
      const Radius.circular(8),
    );

    canvas.drawShadow(
      Path()..addRRect(bodyRect),
      Colors.black.withValues(alpha: isDark ? 0.32 : 0.14),
      12,
      false,
    );

    if (state == FutureLetterVisualState.opened) {
      _paintOpened(canvas, size, bodyRect);
      return;
    }

    _paintKraftPanel(canvas, bodyRect, isFlap: false);
    _paintFlap(canvas, w);
    _paintStamp(canvas, Rect.fromLTWH(w - 54, _bodyTop + 10, 40, 48));

    final sealCenter = Offset(w * 0.5, _bodyTop + 42);
    if (state == FutureLetterVisualState.sealed) {
      _paintWaxSeal(canvas, sealCenter);
    } else {
      _paintBrokenSeal(canvas, sealCenter);
    }
  }

  void _paintOpened(Canvas canvas, Size size, RRect bodyRect) {
    _paintKraftPanel(canvas, bodyRect, isFlap: false);

    final letterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(16, 4, size.width - 32, size.height - _bodyTop - 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      letterRect,
      Paint()
        ..shader = ui.Gradient.linear(
          letterRect.outerRect.topLeft,
          letterRect.outerRect.bottomLeft,
          isDark
              ? [const Color(0xFF454139), const Color(0xFF3A3632)]
              : [const Color(0xFFFFFCF6), const Color(0xFFF5F0E6)],
        ),
    );
    canvas.drawRRect(
      letterRect,
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    final flapBack = Path()
      ..moveTo(0, _bodyTop)
      ..lineTo(size.width * 0.5, 8)
      ..lineTo(size.width, _bodyTop);
    _paintKraftPath(canvas, flapBack, isFlap: true);
  }

  Color get _bodyColor => isDark ? const Color(0xFF353230) : const Color(0xFFEDE6D8);

  Color get _flapColor => isDark ? const Color(0xFF3A3632) : const Color(0xFFE4DDD0);

  Color get _edgeColor => isDark
      ? Colors.white.withValues(alpha: 0.1)
      : Colors.black.withValues(alpha: 0.08);

  void _paintKraftPanel(Canvas canvas, RRect rect, {required bool isFlap}) {
    canvas.drawRRect(
      rect,
      Paint()..color = isFlap ? _flapColor : _bodyColor,
    );
    canvas.drawRRect(
      rect,
      Paint()
        ..color = _edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.6,
    );
  }

  void _paintKraftPath(Canvas canvas, Path path, {required bool isFlap}) {
    canvas.drawPath(path, Paint()..color = isFlap ? _flapColor : _bodyColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = _edgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );
  }

  void _paintFlap(Canvas canvas, double w) {
    final flapDepth =
        state == FutureLetterVisualState.ready ? 12.0 : 44.0;
    final flapPath = Path()
      ..moveTo(0, _bodyTop)
      ..lineTo(w * 0.5, _bodyTop + flapDepth)
      ..lineTo(w, _bodyTop)
      ..close();

    _paintKraftPath(canvas, flapPath, isFlap: true);

    final innerShadow = Path()
      ..moveTo(w * 0.2, _bodyTop + 2)
      ..lineTo(w * 0.5, _bodyTop + flapDepth - 3)
      ..lineTo(w * 0.8, _bodyTop + 2);
    canvas.drawPath(
      innerShadow,
      Paint()
        ..color = Colors.black.withValues(alpha: isDark ? 0.18 : 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5),
    );
  }

  void _paintStamp(Canvas canvas, Rect rect) {
    _paintPerforatedBorder(canvas, rect);

    final inner = rect.deflate(3);
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(1.5)),
      Paint()
        ..shader = ui.Gradient.linear(
          inner.topLeft,
          inner.bottomRight,
          isDark
              ? [const Color(0xFF4A4540), const Color(0xFF3E3A36)]
              : [const Color(0xFFFFF9F0), const Color(0xFFF3EBDD)],
        ),
    );

    final postmarkCenter = inner.center;
    const postRadius = 12.0;
    final stampInk = const Color(0xFFB85C5C).withValues(alpha: isDark ? 0.6 : 0.75);
    canvas.drawCircle(
      postmarkCenter,
      postRadius,
      Paint()
        ..color = stampInk
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
    canvas.drawCircle(
      postmarkCenter,
      postRadius - 3.5,
      Paint()
        ..color = stampInk.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65,
    );

    _paintStampText(
      canvas,
      'ECHO',
      postmarkCenter + const Offset(0, -1),
      7,
      stampInk,
      FontWeight.w600,
    );
    _paintStampText(
      canvas,
      tr('未来', 'FUTURE'),
      postmarkCenter + const Offset(0, 8),
      4.8,
      stampInk.withValues(alpha: 0.8),
      FontWeight.w400,
    );
    _paintRippleMark(canvas, postmarkCenter, 4);
  }

  void _paintPerforatedBorder(Canvas canvas, Rect rect) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(2)),
      Paint()
        ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.5,
    );

    const tooth = 3.0;
    final toothPaint = Paint()
      ..color = EchoColors.appBackground.withValues(alpha: isDark ? 0.88 : 0.96)
      ..style = PaintingStyle.fill;

    for (var x = rect.left + tooth; x < rect.right - tooth; x += tooth * 2) {
      canvas.drawCircle(Offset(x, rect.top), 1.2, toothPaint);
      canvas.drawCircle(Offset(x, rect.bottom), 1.2, toothPaint);
    }
    for (var y = rect.top + tooth; y < rect.bottom - tooth; y += tooth * 2) {
      canvas.drawCircle(Offset(rect.left, y), 1.2, toothPaint);
      canvas.drawCircle(Offset(rect.right, y), 1.2, toothPaint);
    }
  }

  void _paintRippleMark(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFB85C5C).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (var i = 1; i <= 2; i++) {
      canvas.drawCircle(center, radius * i * 0.55, paint);
    }
  }

  void _paintStampText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    Color color,
    FontWeight weight,
  ) {
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.center,
        fontSize: fontSize,
        fontWeight: weight,
      ),
    )
      ..pushStyle(ui.TextStyle(color: color, letterSpacing: 0.5))
      ..addText(text);
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: 34));
    canvas.drawParagraph(
      paragraph,
      center - Offset(paragraph.maxIntrinsicWidth / 2, paragraph.height / 2),
    );
  }

  void _paintWaxSeal(Canvas canvas, Offset center) {
    const radius = 14.0;
    canvas.drawCircle(
      center + const Offset(0, 1.5),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = ui.Gradient.radial(
          center - const Offset(3, 4),
          radius * 1.1,
          [
            const Color(0xFFD49090),
            const Color(0xFFB86868),
            const Color(0xFF9A4E4E),
          ],
          [0.0, 0.55, 1.0],
        ),
    );
    canvas.drawCircle(
      center - const Offset(4, 5),
      radius * 0.2,
      Paint()..color = Colors.white.withValues(alpha: 0.2),
    );
    _paintRippleMark(canvas, center, 3);
  }

  void _paintBrokenSeal(Canvas canvas, Offset center) {
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..shader = ui.Gradient.radial(
          center,
          11,
          [
            const Color(0xFFD49090).withValues(alpha: 0.5),
            const Color(0xFF9A4E4E).withValues(alpha: 0.3),
          ],
        ),
    );
    final crack = Paint()
      ..color = const Color(0xFF5A3A32).withValues(alpha: 0.5)
      ..strokeWidth = 0.9;
    canvas.drawLine(
      Offset(center.dx - 6, center.dy - 4),
      Offset(center.dx + 6, center.dy + 5),
      crack,
    );
  }

  @override
  bool shouldRepaint(covariant _EnvelopePainter oldDelegate) =>
      oldDelegate.state != state || oldDelegate.isDark != isDark;
}
