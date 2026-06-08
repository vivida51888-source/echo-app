import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../models/diary.dart';
import '../navigation/app_page_route.dart';
import '../pages/diary_detail_page.dart';
import '../services/diary_service.dart';
import '../services/echo_reward_service.dart';
import '../services/echo_tree_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import 'echo_hint.dart';
import 'scale_tap.dart';

/// 提示词下方 · 横卧漂流瓶从左漂向右。
class DriftBottleLane extends StatefulWidget {
  const DriftBottleLane({super.key});

  static const laneHeight = 48.0;
  static const bottleWidth = 68.0;
  static const bottleHeight = 24.0;

  @override
  State<DriftBottleLane> createState() => _DriftBottleLaneState();
}

class _DriftBottleLaneState extends State<DriftBottleLane>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final laneW = constraints.maxWidth;
        return SizedBox(
          height: DriftBottleLane.laneHeight,
          width: laneW,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _drift,
                builder: (context, child) {
                  final t = _drift.value;
                  final phase = t * math.pi * 2;
                  final travel = laneW + DriftBottleLane.bottleWidth;
                  final x = -DriftBottleLane.bottleWidth * 0.15 + travel * t;

                  final bob = math.sin(phase + x * 0.035) * 2.0 +
                      math.sin(phase * 1.5 + 0.6) * 0.9;
                  final roll = math.sin(phase * 0.78 + x * 0.018 + 0.9) * 0.09 +
                      math.sin(phase * 1.7 + 0.2) * 0.025;

                  final centerY =
                      (DriftBottleLane.laneHeight - DriftBottleLane.bottleHeight) / 2;
                  final top = centerY + bob;

                  return Positioned(
                    left: x,
                    top: top,
                    child: Transform.rotate(
                      angle: roll,
                      alignment: Alignment.center,
                      child: child,
                    ),
                  );
                },
                child: ScaleTap(
                  onTap: () => showDriftBottleSheet(context),
                  scale: 0.94,
                  child: CustomPaint(
                    size: const Size(
                      DriftBottleLane.bottleWidth,
                      DriftBottleLane.bottleHeight,
                    ),
                    painter: const _DriftBottlePainter(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 横卧漂流瓶 · 柔蓝灰玻璃，瓶身磨砂刻字「回响」。
class _DriftBottlePainter extends CustomPainter {
  const _DriftBottlePainter();

  // 与暖纸背景协调的柔蓝灰玻璃
  static const _glassLight = Color(0xFFC5D8E2);
  static const _glassMid = Color(0xFF93B4C4);
  static const _glassDeep = Color(0xFF6F96A8);
  static const _glassEdge = Color(0xFF587889);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.46, h * 0.98),
        width: w * 0.56,
        height: h * 0.12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.06),
    );

    final body = _bottleBody(w, h);

    canvas.drawPath(
      body,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, h * 0.15),
          Offset(w, h * 0.88),
          [
            _glassLight.withValues(alpha: 0.95),
            _glassMid.withValues(alpha: 0.92),
            _glassDeep.withValues(alpha: 0.94),
          ],
          [0.0, 0.48, 1.0],
        ),
    );

    // 内缘柔光 + 瓶腹刻字（无标签纸，直接融于玻璃）
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.34, h * 0.42),
        width: w * 0.38,
        height: h * 0.55,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.10),
    );
    _paintEtchedText(canvas, w, h);
    canvas.restore();

    canvas.drawPath(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.65
        ..color = _glassEdge.withValues(alpha: 0.38),
    );

    // 瓶颈
    final neck = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.792, h * 0.22, w * 0.088, h * 0.56),
      Radius.circular(h * 0.12),
    );
    canvas.drawRRect(
      neck,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset(w * 0.79, h * 0.22),
          Offset(w * 0.88, h * 0.78),
          [_glassMid, _glassDeep],
        ),
    );

    // 瓶口金边
    canvas.drawArc(
      Rect.fromLTWH(w * 0.785, h * 0.18, w * 0.10, h * 0.22),
      math.pi * 0.15,
      math.pi * 0.7,
      false,
      Paint()
        ..color = const Color(0xFFD4C4AE).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.45,
    );

    // 软木塞
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.808, h * 0.06, w * 0.072, h * 0.20),
        Radius.circular(h * 0.05),
      ),
      Paint()..color = const Color(0xFFC4A882),
    );
    canvas.drawLine(
      Offset(w * 0.815, h * 0.11),
      Offset(w * 0.872, h * 0.11),
      Paint()
        ..color = const Color(0xFF9A8068).withValues(alpha: 0.35)
        ..strokeWidth = 0.35,
    );

    // 玻璃高光
    canvas.drawLine(
      Offset(w * 0.10, h * 0.28),
      Offset(w * 0.52, h * 0.24),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.36)
        ..strokeWidth = 1.3
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(w * 0.58, h * 0.30),
      Offset(w * 0.72, h * 0.46),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.16)
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round,
    );
  }

  /// 瓶腹磨砂刻字：浅影 + 高光，无贴纸。
  void _paintEtchedText(Canvas canvas, double w, double h) {
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.36, h * 0.50),
        width: w * 0.30,
        height: h * 0.38,
      ),
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );

    final text = tr('回响', 'Echo');
    final fontSize = h * 0.36;
    final letterSpacing = 2.4;

    TextPainter buildText({required Color color}) => TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w300,
              color: color,
              letterSpacing: letterSpacing,
              height: 1.0,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

    final shadow = buildText(color: _glassDeep.withValues(alpha: 0.28));
    final main = buildText(color: Colors.white.withValues(alpha: 0.52));
    final gloss = buildText(color: Colors.white.withValues(alpha: 0.18));

    final cx = w * 0.36;
    final cy = h * 0.50;
    final origin = Offset(cx - main.width / 2, cy - main.height / 2);

    shadow.paint(canvas, origin + const Offset(0.45, 0.55));
    main.paint(canvas, origin);
    gloss.paint(canvas, origin + const Offset(-0.25, -0.35));
  }

  Path _bottleBody(double w, double h) {
    return Path()
      ..moveTo(w * 0.04, h * 0.50)
      ..quadraticBezierTo(w * 0.01, h * 0.36, w * 0.05, h * 0.22)
      ..quadraticBezierTo(w * 0.10, h * 0.06, w * 0.28, h * 0.04)
      ..lineTo(w * 0.58, h * 0.04)
      ..quadraticBezierTo(w * 0.72, h * 0.06, w * 0.76, h * 0.16)
      ..lineTo(w * 0.792, h * 0.22)
      ..lineTo(w * 0.792, h * 0.78)
      ..lineTo(w * 0.76, h * 0.84)
      ..quadraticBezierTo(w * 0.72, h * 0.94, w * 0.58, h * 0.96)
      ..quadraticBezierTo(w * 0.28, h * 0.96, w * 0.10, h * 0.78)
      ..quadraticBezierTo(w * 0.02, h * 0.64, w * 0.04, h * 0.50)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> showDriftBottleSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.16),
    builder: (context) => const _DriftBottleSheet(),
  );
}

class _DriftBottleSheet extends StatefulWidget {
  const _DriftBottleSheet();

  @override
  State<_DriftBottleSheet> createState() => _DriftBottleSheetState();
}

class _DriftBottleSheetState extends State<_DriftBottleSheet>
    with SingleTickerProviderStateMixin {
  Diary? _diary;
  bool _loading = true;
  late final AnimationController _reveal;

  @override
  void initState() {
    super.initState();
    _reveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _draw();
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _draw({String? excludeId}) {
    setState(() => _loading = true);
    _reveal.reset();
    final picked =
        DiaryService.instance.randomDriftBottleDiary(excludeId: excludeId);
    setState(() {
      _diary = picked;
      _loading = false;
    });
    if (picked != null) {
      _reveal.forward();
    }
  }

  Future<void> _openFull(Diary diary) async {
    Navigator.pop(context);
    await Navigator.of(context).push<bool>(
      AppPageRoute<bool>(
        builder: (_) => DiaryDetailPage(diaryId: diary.id),
      ),
    );
  }

  Future<void> _replyToLetter(Diary diary) async {
    await EchoTreeService.instance.grantWaterForDriftReply(diary.id);
    await EchoRewardService.instance.onDriftReply();
    if (!mounted) return;
    Navigator.pop(context);
    if (!mounted) return;
    showEchoBriefHint(
      context,
      message: tr('善意已回响 · +10g 雨露', 'Kindness echoed · +10g dew'),
      tone: EchoBriefHintTone.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, bottom + 16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: EchoColors.nightSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFD5D0C8).withValues(alpha: 0.55),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: _loading
              ? _SheetStatus(message: tr('信笺上浮中…', 'Letter surfacing…'))
              : _diary == null
                  ? _EmptyLetter(onClose: () => Navigator.pop(context))
                  : FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _reveal,
                        curve: Curves.easeOut,
                      ),
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(CurvedAnimation(
                          parent: _reveal,
                          curve: Curves.easeOutCubic,
                        )),
                        child: _LetterContent(
                          diary: _diary!,
                          onRedraw: () => _draw(excludeId: _diary!.id),
                          onOpenFull: () => _openFull(_diary!),
                          onReply: () => _replyToLetter(_diary!),
                          onClose: () => Navigator.pop(context),
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _SheetStatus extends StatelessWidget {
  const _SheetStatus({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: EchoColors.nightTextSecondary,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _EmptyLetter extends StatelessWidget {
  const _EmptyLetter({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(title: tr('漂流瓶', 'Drift bottle')),
        const SizedBox(height: 20),
        Text(
          tr('还没有信漂回来', 'No letters have drifted in yet'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w300,
            color: EchoColors.momentTextPrimary,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          tr(
            '在篇章里把回响放进漂流瓶，就会从这里漂来',
            'Put an echo in a bottle from Chapters — it may drift here',
          ),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: EchoColors.nightTextSecondary.withValues(alpha: 0.95),
            height: 1.55,
          ),
        ),
        const SizedBox(height: 24),
        _SheetButton(label: tr('好的', 'OK'), onTap: onClose, primary: false),
      ],
    );
  }
}

class _LetterContent extends StatelessWidget {
  const _LetterContent({
    required this.diary,
    required this.onRedraw,
    required this.onOpenFull,
    required this.onReply,
    required this.onClose,
  });

  final Diary diary;
  final VoidCallback onRedraw;
  final VoidCallback onOpenFull;
  final VoidCallback onReply;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final preview = diary.content.trim();
    final clipped = preview.length > 180
        ? '${preview.substring(0, 180).trim()}…'
        : preview;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetHeader(title: tr('漂来的信', 'Drifted letter')),
        const SizedBox(height: 16),
        Text(
          DiaryFormat.dateLine(diary.createdAt),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: EchoColors.nightTextSecondary,
            letterSpacing: 0.6,
          ),
        ),
        if (diary.moodWeather != null) ...[
          const SizedBox(height: 8),
          Text(
            diary.moodWeather!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: EchoColors.momentTextPrimary,
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: EchoColors.homeBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            clipped,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w300,
              color: EchoColors.momentTextPrimary,
              height: 1.75,
              letterSpacing: 0.15,
            ),
          ),
        ),
        if (diary.hasAiInsight) ...[
          const SizedBox(height: 12),
          Text(
            diary.aiSummary,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              fontStyle: FontStyle.italic,
              color: EchoColors.momentTextWhisper.withValues(alpha: 0.95),
              height: 1.5,
            ),
          ),
        ],
        const SizedBox(height: 22),
        Row(
          children: [
            Expanded(
              child: _SheetButton(
                label: tr('换一封', 'Another'),
                onTap: onRedraw,
                primary: false,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SheetButton(
                label: tr('给予回响', 'Echo back'),
                onTap: onReply,
                primary: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ScaleTap(
          onTap: onOpenFull,
          scale: 0.98,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              tr('读全文', 'Read all'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.nightTextSecondary,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        ScaleTap(
          onTap: onClose,
          scale: 0.98,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text(
              tr('放回', 'Put back'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.momentTextWhisper,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: EchoColors.momentTextWhisper.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: EchoColors.momentTextPrimary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: primary
              ? EchoColors.nightAccent
              : EchoColors.homeBackground.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(12),
          border: primary
              ? null
              : Border.all(
                  color: const Color(0xFFD5D0C8).withValues(alpha: 0.6),
                  width: 0.5,
                ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: primary
                ? const Color(0xFFEEEBE4)
                : EchoColors.momentTextPrimary,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
