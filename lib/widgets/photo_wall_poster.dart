import 'package:flutter/material.dart';

import '../models/photo_wall_material.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import 'echo_photo_wall.dart';

/// 保存相册用的留影海报。
class EchoPhotoWallPoster extends StatelessWidget {
  const EchoPhotoWallPoster({
    super.key,
    required this.periodTitle,
    required this.caption,
    required this.isWeekly,
    required this.items,
    required this.material,
    this.customWallPath,
    this.width = 340,
  });

  final String periodTitle;
  final String caption;
  final bool isWeekly;
  final List<EchoWallPin> items;
  final PhotoWallMaterial material;
  final String? customWallPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            EchoColors.daySurface,
            EchoColors.dayWriting.withValues(alpha: 0.85),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            periodTitle,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextPrimary,
              letterSpacing: -0.2,
              height: 1.25,
            ),
          ),
          if (caption.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              caption.trim(),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w300,
                fontStyle: FontStyle.italic,
                color: EchoColors.dayTextPrimary,
                height: 1.65,
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            height: 0.5,
            color: EchoColors.dayDivider.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 20),
          EchoPhotoWall(
            items: items,
            isWeekly: isWeekly,
            material: material,
            customWallPath: customWallPath,
            enablePinAnimation: false,
          ),
          const SizedBox(height: 22),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 18,
                  height: 0.5,
                  color: EchoColors.dayTextWhisper.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  'Echo · 回响',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextWhisper,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
