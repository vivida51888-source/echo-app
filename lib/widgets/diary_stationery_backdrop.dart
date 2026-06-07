import 'package:flutter/material.dart';

import '../models/diary_stationery.dart';

/// 写作区背后的竖向信纸：顶部铺图，下方用纸本色延伸。
class DiaryStationeryBackdrop extends StatelessWidget {
  const DiaryStationeryBackdrop({
    super.key,
    required this.stationery,
  });

  final DiaryStationery stationery;

  static const _veilGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x33000000),
      Color(0x00000000),
      Color(0x14000000),
      Color(0x52000000),
    ],
    stops: [0.0, 0.2, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    final asset = stationery.assetPath;
    if (asset == null) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.fitWidth,
              alignment: Alignment.topCenter,
            ),
            Expanded(
              child: stationery.extensionFadeColor != null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            stationery.extensionColor,
                            stationery.extensionFadeColor!,
                          ],
                        ),
                      ),
                    )
                  : ColoredBox(color: stationery.extensionColor),
            ),
          ],
        ),
        if (stationery.readabilityVeil)
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient:
                      stationery.readabilityVeilGradient ?? _veilGradient,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
