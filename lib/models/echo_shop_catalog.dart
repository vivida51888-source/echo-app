import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import 'diary_stationery.dart';
import 'photo_wall_material.dart';

enum EchoShopCategory {
  dew,
  wall,
  stationery;

  String get label => switch (this) {
        EchoShopCategory.dew => tr('雨露', 'Dew'),
        EchoShopCategory.wall => tr('墙面皮肤', 'Wall skins'),
        EchoShopCategory.stationery => tr('信纸皮肤', 'Stationery'),
      };
}

enum EchoShopItemKind {
  storedDew,
  energyBubble,
  wallSkin,
  stationerySkin,
}

class EchoShopItem {
  const EchoShopItem({
    required this.id,
    required this.category,
    required this.kind,
    required this.price,
    required this.tint,
    required this.icon,
    this.dewGrams,
    this.wallMaterial,
    this.stationeryId,
  });

  final String id;
  final EchoShopCategory category;
  final EchoShopItemKind kind;
  final int price;
  final Color tint;
  final IconData icon;
  final int? dewGrams;
  final PhotoWallMaterial? wallMaterial;
  final String? stationeryId;

  String get name => switch (id) {
        'dew_s' => tr('雨露轻囊', 'Light dew'),
        'dew_m' => tr('雨露中囊', 'Dew flask'),
        'dew_l' => tr('雨露丰囊', 'Rich dew'),
        'wall_travel' => PhotoWallMaterial.travel.localizedLabel,
        'wall_spring' => PhotoWallMaterial.natureSpring.localizedLabel,
        'wall_summer' => PhotoWallMaterial.natureSummer.localizedLabel,
        'wall_autumn' => PhotoWallMaterial.natureAutumn.localizedLabel,
        'wall_winter' => PhotoWallMaterial.natureWinter.localizedLabel,
        'wall_film25' => PhotoWallMaterial.negative25.localizedLabel,
        'wall_film_workshop' => PhotoWallMaterial.filmWorkshop.localizedLabel,
        'paper_morning' => DiaryStationeries.morningLight.localizedName,
        'paper_sakura' => DiaryStationeries.sakuraNotes.localizedName,
        'paper_moon' => DiaryStationeries.moonBay.localizedName,
        'paper_clear' => DiaryStationeries.clearSky.localizedName,
        'paper_autumn' => DiaryStationeries.autumnStreet.localizedName,
        'paper_snow' => DiaryStationeries.snowDream.localizedName,
        'paper_sea' => DiaryStationeries.seaBreeze.localizedName,
        'paper_rain' => DiaryStationeries.rainyWindow.localizedName,
        _ => id,
      };

  bool get isConsumable =>
      kind == EchoShopItemKind.storedDew ||
      kind == EchoShopItemKind.energyBubble;

  bool get isSkin =>
      kind == EchoShopItemKind.wallSkin ||
      kind == EchoShopItemKind.stationerySkin;

  /// 小铺预览图（墙面 / 信纸使用真实资源）。
  String? get previewAsset {
    if (wallMaterial != null) {
      return switch (wallMaterial!) {
        PhotoWallMaterial.travel => 'assets/images/photo_wall_travel.png',
        PhotoWallMaterial.natureSpring =>
          'assets/images/photo_wall_nature_spring.png',
        PhotoWallMaterial.natureSummer =>
          'assets/images/photo_wall_nature_summer.png',
        PhotoWallMaterial.natureAutumn =>
          'assets/images/photo_wall_nature_autumn.png',
        PhotoWallMaterial.natureWinter =>
          'assets/images/photo_wall_nature_winter.png',
        PhotoWallMaterial.negative25 =>
          'assets/images/photo_wall_negative25.png',
        PhotoWallMaterial.filmWorkshop =>
          'assets/images/photo_wall_film_workshop.png',
        _ => null,
      };
    }
    if (stationeryId != null) {
      return DiaryStationeries.byId(stationeryId).assetPath;
    }
    return null;
  }
}

abstract final class EchoShopCatalog {
  /// 全部成就满星约可得回响币（用于皮肤定价参考）。
  static const maxAchievementCoins = 2895;

  /// 皮肤定价：全成就约可兑换 3–4 款。
  static const skinPrices = [680, 720, 760, 800, 840, 880, 920];

  static const all = [
    EchoShopItem(
      id: 'dew_s',
      category: EchoShopCategory.dew,
      kind: EchoShopItemKind.energyBubble,
      price: 45,
      tint: Color(0xFF7EADBE),
      icon: Icons.water_drop_outlined,
      dewGrams: 30,
    ),
    EchoShopItem(
      id: 'dew_m',
      category: EchoShopCategory.dew,
      kind: EchoShopItemKind.energyBubble,
      price: 95,
      tint: Color(0xFF6B9AB0),
      icon: Icons.opacity_outlined,
      dewGrams: 80,
    ),
    EchoShopItem(
      id: 'dew_l',
      category: EchoShopCategory.dew,
      kind: EchoShopItemKind.energyBubble,
      price: 180,
      tint: Color(0xFF5A8AA0),
      icon: Icons.waves_outlined,
      dewGrams: 180,
    ),
    EchoShopItem(
      id: 'wall_travel',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 680,
      tint: Color(0xFF8A7AA8),
      icon: Icons.auto_awesome_outlined,
      wallMaterial: PhotoWallMaterial.travel,
    ),
    EchoShopItem(
      id: 'wall_spring',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 720,
      tint: Color(0xFFE8A0B0),
      icon: Icons.filter_vintage_outlined,
      wallMaterial: PhotoWallMaterial.natureSpring,
    ),
    EchoShopItem(
      id: 'wall_summer',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 760,
      tint: Color(0xFF7BA889),
      icon: Icons.wb_sunny_outlined,
      wallMaterial: PhotoWallMaterial.natureSummer,
    ),
    EchoShopItem(
      id: 'wall_autumn',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 800,
      tint: Color(0xFFD4A84B),
      icon: Icons.park_outlined,
      wallMaterial: PhotoWallMaterial.natureAutumn,
    ),
    EchoShopItem(
      id: 'wall_winter',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 840,
      tint: Color(0xFF9BB0C4),
      icon: Icons.ac_unit_outlined,
      wallMaterial: PhotoWallMaterial.natureWinter,
    ),
    EchoShopItem(
      id: 'wall_film25',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 880,
      tint: Color(0xFF5A5A5A),
      icon: Icons.movie_filter_outlined,
      wallMaterial: PhotoWallMaterial.negative25,
    ),
    EchoShopItem(
      id: 'wall_film_workshop',
      category: EchoShopCategory.wall,
      kind: EchoShopItemKind.wallSkin,
      price: 920,
      tint: Color(0xFF8B7355),
      icon: Icons.camera_roll_outlined,
      wallMaterial: PhotoWallMaterial.filmWorkshop,
    ),
    EchoShopItem(
      id: 'paper_morning',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 680,
      tint: Color(0xFFD4A84B),
      icon: Icons.wb_twilight_outlined,
      stationeryId: 'morning_light',
    ),
    EchoShopItem(
      id: 'paper_sakura',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 720,
      tint: Color(0xFFE8A0B0),
      icon: Icons.local_florist_outlined,
      stationeryId: 'sakura_notes',
    ),
    EchoShopItem(
      id: 'paper_moon',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 760,
      tint: Color(0xFF6A5A8A),
      icon: Icons.nightlight_round_outlined,
      stationeryId: 'moon_bay',
    ),
    EchoShopItem(
      id: 'paper_clear',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 800,
      tint: Color(0xFF6FAF82),
      icon: Icons.wb_cloudy_outlined,
      stationeryId: 'clear_sky',
    ),
    EchoShopItem(
      id: 'paper_autumn',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 840,
      tint: Color(0xFFC98A5A),
      icon: Icons.eco_outlined,
      stationeryId: 'autumn_street',
    ),
    EchoShopItem(
      id: 'paper_snow',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 880,
      tint: Color(0xFF9BB0C4),
      icon: Icons.ac_unit_outlined,
      stationeryId: 'snow_dream',
    ),
    EchoShopItem(
      id: 'paper_sea',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 900,
      tint: Color(0xFF7A9AB0),
      icon: Icons.sailing_outlined,
      stationeryId: 'sea_breeze',
    ),
    EchoShopItem(
      id: 'paper_rain',
      category: EchoShopCategory.stationery,
      kind: EchoShopItemKind.stationerySkin,
      price: 920,
      tint: Color(0xFF6B645D),
      icon: Icons.grain_outlined,
      stationeryId: 'rainy_window',
    ),
  ];

  static List<EchoShopItem> forCategory(EchoShopCategory cat) =>
      all.where((i) => i.category == cat).toList();

  static EchoShopItem? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }
}
