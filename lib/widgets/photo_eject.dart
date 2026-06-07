import 'package:flutter/material.dart';

import '../models/photo_wall_frame_style.dart';
import '../models/photo_wall_material.dart';
import '../services/echo_stats_service.dart';
import '../services/photo_wall_settings_service.dart';
import 'film_eject.dart';
import 'polaroid_eject.dart';

/// 按当前照片样式导出：拍立得 / 单张胶片。
abstract final class PhotoEject {
  static Future<void> present(
    BuildContext context, {
    required EchoPhotoStat photo,
    PhotoWallMaterial material = PhotoWallMaterial.plain,
  }) {
    if (PhotoWallSettingsService.instance.frameStyle ==
        PhotoWallFrameStyle.filmStrip) {
      return FilmEject.present(
        context,
        photo: photo,
        material: material,
      );
    }
    return PolaroidEject.present(
      context,
      photo: photo,
      material: material,
    );
  }
}
