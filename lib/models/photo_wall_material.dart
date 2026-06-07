import 'photo_wall_frame_style.dart';

/// 照片墙背景材质。
enum PhotoWallMaterial {
  plain('空白墙'),
  cork('软木板'),
  fridge('冰箱贴'),
  travel('银河匣'),
  natureSpring('樱语季'),
  natureSummer('晴光屿'),
  natureAutumn('枫拾间'),
  natureWinter('雪梦湾'),
  custom('自定义'),
  negative25('25号底片'),
  filmWorkshop('胶片工坊');

  const PhotoWallMaterial(this.label);
  final String label;

  static const basic = [plain, cork, fridge, travel];

  /// 胶片样式下的墙面选项。
  static const filmWall = [negative25, filmWorkshop];

  static List<PhotoWallMaterial> pickerOptions(PhotoWallFrameStyle frameStyle) {
    if (frameStyle == PhotoWallFrameStyle.filmStrip) return filmWall;
    return [...basic, ...natureSeasons, custom];
  }

  static const natureSeasons = [
    natureSpring,
    natureSummer,
    natureAutumn,
    natureWinter,
  ];

  static PhotoWallMaterial fromName(String name) {
    switch (name) {
      case 'frost':
      case 'nature':
        return PhotoWallMaterial.natureSpring;
      case 'concrete':
        return PhotoWallMaterial.plain;
      case 'negative_25':
      case 'film_negative_25':
        return PhotoWallMaterial.negative25;
      case 'film_workshop':
        return PhotoWallMaterial.filmWorkshop;
      case 'linen':
        return PhotoWallMaterial.plain;
    }
    return PhotoWallMaterial.values.firstWhere(
      (e) => e.name == name,
      orElse: () => PhotoWallMaterial.plain,
    );
  }

  bool get isNature => natureSeasons.contains(this);

  bool get isCustom => this == PhotoWallMaterial.custom;

  bool get usesPin =>
      this == PhotoWallMaterial.plain || this == PhotoWallMaterial.cork;

  bool get usesMagnet => this == PhotoWallMaterial.fridge;

  bool get usesClip => isNature;

  bool get usesTape =>
      this == PhotoWallMaterial.plain ||
      this == PhotoWallMaterial.custom ||
      this == PhotoWallMaterial.negative25 ||
      this == PhotoWallMaterial.filmWorkshop ||
      this == PhotoWallMaterial.travel;

  bool get isFilmWall => filmWall.contains(this);

  bool get isTravelWall => this == PhotoWallMaterial.travel;

  bool get isSceneImageWall =>
      this == PhotoWallMaterial.natureSpring ||
      this == PhotoWallMaterial.natureSummer ||
      this == PhotoWallMaterial.natureAutumn ||
      this == PhotoWallMaterial.natureWinter;

  /// 无照片时仅展示墙面底图（场景类墙面）。
  bool get showsEmptyWallOnly =>
      isFilmWall || isTravelWall || isSceneImageWall || isCustom;

  /// 无照片时墙面预览高度（仅露出底图）。
  double emptyWallPreviewHeight(double width, {bool compact = false}) {
    if (!showsEmptyWallOnly) return 0;
    if (isFilmWall || isTravelWall || isSceneImageWall) {
      return width * (compact ? 0.5 : 0.58);
    }
    return width * (compact ? 0.48 : 0.54);
  }

  /// Hub 无照片时仅展示墙面底图的高度。
  double hubEmptyPreviewHeight(double width, {bool compact = false}) {
    final dedicated = emptyWallPreviewHeight(width, compact: compact);
    if (dedicated > 0) return dedicated;
    if (this == PhotoWallMaterial.cork || this == PhotoWallMaterial.fridge) {
      return width * (compact ? 0.5 : 0.58);
    }
    if (isNature) return width * (compact ? 0.45 : 0.52);
    return width * (compact ? 0.42 : 0.48);
  }

  /// 无照片时 25 号底片墙的展示高度（仅露出底图）。
  double filmWallPreviewHeight(double width, {bool compact = false}) =>
      emptyWallPreviewHeight(width, compact: compact);

  /// 自定义墙面：拍立得更透，露出底图。
  bool get usesTranslucentPolaroid => isCustom;

  double get polaroidFrameAlpha => isCustom ? 0.28 : 1.0;

  double get polaroidImageOpacity => isCustom ? 0.78 : 1.0;

  double get polaroidShadowAlpha => isCustom ? 0.06 : 0.12;
}
