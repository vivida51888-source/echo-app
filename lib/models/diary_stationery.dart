import 'package:flutter/material.dart';

import '../l10n/localized.dart';

/// 日记写作信纸预设。
class DiaryStationery {
  const DiaryStationery({
    required this.id,
    required this.name,
    required this.subtitle,
    this.assetPath,
    this.extensionColor = const Color(0xFFF7F2EA),
    this.lightForeground = false,
    this.contentPanelColor,
    this.readabilityVeil = false,
    this.readabilityVeilGradient,
    this.extensionFadeColor,
  });

  final String id;
  final String name;
  final String subtitle;

  /// 竖向信纸图；为 null 时使用 App 纸色底。
  final String? assetPath;

  /// 信纸图下方延伸的纸本色（长文时填充）。
  final Color extensionColor;

  /// 深色信纸时使用浅色前景（正文与图标）。
  final bool lightForeground;

  /// 写作区半透明衬底，提升复杂背景上的可读性。
  final Color? contentPanelColor;

  /// 信纸上的极淡渐变蒙层（无框，不遮挡画面）。
  final bool readabilityVeil;

  /// 自定义蒙层渐变；未设置时用默认。
  final LinearGradient? readabilityVeilGradient;

  /// 长文区底部渐亮纸色，避免延伸区过黑。
  final Color? extensionFadeColor;

  bool get hasImage => assetPath != null;

  Color get scrollSurfaceColor => extensionFadeColor ?? extensionColor;

  bool get needsContentPanel => contentPanelColor != null;
}

abstract final class DiaryStationeries {
  static const defaultId = 'plain';

  static const plain = DiaryStationery(
    id: 'plain',
    name: '素纸',
    subtitle: '留白纸色 · 专注文字',
  );

  static const morningLight = DiaryStationery(
    id: 'morning_light',
    name: '晨光纸笺',
    subtitle: '暖光树影 · 碎花角饰',
    assetPath: 'assets/images/stationery_morning_light.png',
    extensionColor: Color(0xFFF3EDE4),
  );

  static const sakuraNotes = DiaryStationery(
    id: 'sakura_notes',
    name: '樱花札记',
    subtitle: '淡粉樱枝 · 和纸边框',
    assetPath: 'assets/images/stationery_sakura_notes.png',
    extensionColor: Color(0xFFFFF5F3),
  );

  static const moonBay = DiaryStationery(
    id: 'moon_bay',
    name: '月湾灯影',
    subtitle: '星夜露台 · 湾上灯火',
    assetPath: 'assets/images/stationery_moon_bay.png',
    extensionColor: Color(0xFF3A3358),
    lightForeground: true,
    readabilityVeil: true,
  );

  static const clearSky = DiaryStationery(
    id: 'clear_sky',
    name: '晴空物语',
    subtitle: '碧波绿叶 · 冰饮花影',
    assetPath: 'assets/images/stationery_clear_sky.png',
    extensionColor: Color(0xFFF5F9F4),
  );

  static const snowDream = DiaryStationery(
    id: 'snow_dream',
    name: '雪梦絮语',
    subtitle: '雪夜灯枝 · 远村微光',
    assetPath: 'assets/images/stationery_snow_dream.png',
    extensionColor: Color(0xFFF2F5F9),
  );

  static const autumnStreet = DiaryStationery(
    id: 'autumn_street',
    name: '秋日长街',
    subtitle: '暖枫便笺 · 木栅秋色',
    assetPath: 'assets/images/stationery_autumn_street.png',
    extensionColor: Color(0xFFFFF9F0),
  );

  static const seaBreeze = DiaryStationery(
    id: 'sea_breeze',
    name: '海风纸页',
    subtitle: '椰影邮戳 · 远帆轻浪',
    assetPath: 'assets/images/stationery_sea_breeze.png',
    extensionColor: Color(0xFFF6FAFC),
  );

  static const rainyWindow = DiaryStationery(
    id: 'rainy_window',
    name: '雨窗记事',
    subtitle: '细雨橱窗 · 街灯回响',
    assetPath: 'assets/images/stationery_rainy_window.png',
    extensionColor: Color(0xFF4A443F),
    extensionFadeColor: Color(0xFF6B645D),
    lightForeground: true,
    readabilityVeil: true,
    readabilityVeilGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x26000000),
        Color(0x00000000),
        Color(0x08000000),
        Color(0x18000000),
      ],
      stops: [0.0, 0.22, 0.62, 1.0],
    ),
  );

  static const all = [
    plain,
    morningLight,
    moonBay,
    sakuraNotes,
    clearSky,
    autumnStreet,
    snowDream,
    seaBreeze,
    rainyWindow,
  ];

  static DiaryStationery byId(String? id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return plain;
  }
}

extension DiaryStationeryL10n on DiaryStationery {
  String get localizedName => switch (id) {
        'plain' => tr('素纸', 'Plain'),
        'morning_light' => tr('晨光纸笺', 'Morning light'),
        'sakura_notes' => tr('樱花札记', 'Sakura notes'),
        'moon_bay' => tr('月湾灯影', 'Moon bay'),
        'clear_sky' => tr('晴空物语', 'Clear sky'),
        'snow_dream' => tr('雪梦絮语', 'Snow dream'),
        'autumn_street' => tr('秋日长街', 'Autumn street'),
        'sea_breeze' => tr('海风纸页', 'Sea breeze'),
        'rainy_window' => tr('雨窗记事', 'Rainy window'),
        _ => name,
      };

  String get localizedSubtitle => switch (id) {
        'plain' => tr('留白纸色 · 专注文字', 'Blank paper · focus on words'),
        'morning_light' => tr('暖光树影 · 碎花角饰', 'Warm light · floral corners'),
        'sakura_notes' => tr('淡粉樱枝 · 和纸边框', 'Pale sakura · washi border'),
        'moon_bay' => tr('星夜露台 · 湾上灯火', 'Starry terrace · bay lights'),
        'clear_sky' => tr('碧波绿叶 · 冰饮花影', 'Green leaves · summer drink'),
        'snow_dream' => tr('雪夜灯枝 · 远村微光', 'Snow night · distant glow'),
        'autumn_street' => tr('暖枫便笺 · 木栅秋色', 'Maple notes · autumn fence'),
        'sea_breeze' => tr('椰影邮戳 · 远帆轻浪', 'Palm stamp · distant sail'),
        'rainy_window' => tr('细雨橱窗 · 街灯回响', 'Rain on glass · street lamps'),
        _ => subtitle,
      };
}
