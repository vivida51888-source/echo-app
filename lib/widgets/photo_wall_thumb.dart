import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/echo_colors.dart';

class PhotoWallThumb extends StatelessWidget {
  const PhotoWallThumb({super.key, required this.path, this.fit = BoxFit.cover});

  final String path;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: fit);
    }

    final file = File(path);
    if (!file.existsSync()) {
      return ColoredBox(
        color: EchoColors.dayDivider.withValues(alpha: 0.5),
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 16,
          color: EchoColors.dayTextWhisper,
        ),
      );
    }

    return Image.file(file, fit: fit);
  }
}
