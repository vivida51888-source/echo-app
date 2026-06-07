import 'package:flutter/material.dart';

import '../models/echo_tree_growth.dart';
import '../theme/echo_colors.dart';
import 'echo_tree_painter.dart';

/// 回响之树可视化：手绘生长 + 萎蔫效果。
class EchoTreeVisual extends StatelessWidget {
  const EchoTreeVisual({
    super.key,
    required this.visualStage,
    required this.wilt,
    this.width = 160,
    this.height = 200,
    this.showWiltHint = true,
  });

  final int visualStage;
  final EchoTreeWiltLevel wilt;
  final double width;
  final double height;
  final bool showWiltHint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.matrix(
            _saturationMatrix(wilt.saturation),
          ),
          child: SizedBox(
            width: width,
            height: height,
            child: CustomPaint(
              painter: EchoTreePainter(
                visualStage: visualStage,
                wilt: wilt,
                saturation: wilt.saturation,
              ),
            ),
          ),
        ),
        if (showWiltHint && wilt != EchoTreeWiltLevel.none) ...[
          const SizedBox(height: 6),
          Text(
            wilt == EchoTreeWiltLevel.soft ? '有点蔫了…' : '微微发蔫',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextWhisper.withValues(
                alpha: wilt == EchoTreeWiltLevel.soft ? 0.95 : 0.8,
              ),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  List<double> _saturationMatrix(double saturation) {
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;
    final sr = (1 - saturation) * lumR;
    final sg = (1 - saturation) * lumG;
    final sb = (1 - saturation) * lumB;

    return [
      sr + saturation, sg, sb, 0, 0,
      sr, sg + saturation, sb, 0, 0,
      sr, sg, sb + saturation, 0, 0,
      0, 0, 0, 1, 0,
    ];
  }
}
