import 'package:flutter/material.dart';

import '../l10n/localized.dart';

/// 一组协调的 Echo 纸色底（日间底 + 此刻底 + 衍生表面色）。
class EchoPalette {
  const EchoPalette({
    required this.dayBackground,
    required this.nightBackground,
    required this.daySurface,
    required this.dayWriting,
    required this.dayDivider,
    required this.dayNavBorder,
    required this.nightNavBorder,
    required this.nightSurface,
    required this.insightSurface,
    required this.sheetDivider,
  });

  final Color dayBackground;
  final Color nightBackground;
  final Color daySurface;
  final Color dayWriting;
  final Color dayDivider;
  final Color dayNavBorder;
  final Color nightNavBorder;
  final Color nightSurface;
  final Color insightSurface;
  final Color sheetDivider;
}

class EchoAppearancePreset {
  const EchoAppearancePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.palette,
    required this.previewDay,
    required this.previewNight,
    this.dualTone = false,
  });

  final String id;
  final String name;
  final String subtitle;
  final EchoPalette palette;
  final Color previewDay;
  final Color previewNight;

  /// 为 true 时「此刻」与「回响」使用两种深浅纸色（当前无预设启用）。
  final bool dualTone;
}

abstract final class EchoAppearancePresets {
  static const defaultId = 'warm_paper';

  /// 白净素纸底（浅灰分割，与其它纸色同一套结构）。
  static const pureWhite = EchoAppearancePreset(
    id: 'pure_white',
    name: '素白',
    subtitle: '白净素纸 · 清爽留白',
    previewDay: Color(0xFFFFFFFF),
    previewNight: Color(0xFFFFFFFF),
    palette: EchoPalette(
      dayBackground: Color(0xFFFFFFFF),
      nightBackground: Color(0xFFFFFFFF),
      daySurface: Color(0xFFFFFFFF),
      dayWriting: Color(0xFFF7F7F8),
      dayDivider: Color(0xFFE5E5EA),
      dayNavBorder: Color(0xFFE5E5EA),
      nightNavBorder: Color(0xFFE5E5EA),
      nightSurface: Color(0xFFF2F2F7),
      insightSurface: Color(0xFFF2F2F7),
      sheetDivider: Color(0xFFE5E5EA),
    ),
  );

  /// 由原「暮纸」更名，统一纸色（不再分此刻 / 回响双色）。
  static const warmPaper = EchoAppearancePreset(
    id: 'warm_paper',
    name: '暖纸',
    subtitle: '淡暖米纸 · 柔和护眼',
    previewDay: Color(0xFFF7F5F0),
    previewNight: Color(0xFFF7F5F0),
    palette: EchoPalette(
      dayBackground: Color(0xFFF7F5F0),
      nightBackground: Color(0xFFF7F5F0),
      daySurface: Color(0xFFFFFCF8),
      dayWriting: Color(0xFFF3EFE6),
      dayDivider: Color(0xFFEBE8E2),
      dayNavBorder: Color(0xFFE8E6E1),
      nightNavBorder: Color(0xFFE8E6E1),
      nightSurface: Color(0xFFF3EFE6),
      insightSurface: Color(0xFFF3EFE6),
      sheetDivider: Color(0xFFF0EDE8),
    ),
  );

  static const morningMist = EchoAppearancePreset(
    id: 'morning_mist',
    name: '粉霞',
    subtitle: '蔷薇粉纸 · 轻柔温馨',
    previewDay: Color(0xFFF6E2EC),
    previewNight: Color(0xFFEFD5E3),
    palette: EchoPalette(
      dayBackground: Color(0xFFF6E2EC),
      nightBackground: Color(0xFFEFD5E3),
      daySurface: Color(0xFFFFF4F8),
      dayWriting: Color(0xFFF2D8E4),
      dayDivider: Color(0xFFE8C4D4),
      dayNavBorder: Color(0xFFE2B8CC),
      nightNavBorder: Color(0xFFD8ACC4),
      nightSurface: Color(0xFFECD0DE),
      insightSurface: Color(0xFFF2D8E4),
      sheetDivider: Color(0xFFEED0DC),
    ),
  );

  static const apricotCream = EchoAppearancePreset(
    id: 'apricot_cream',
    name: '雾蓝',
    subtitle: '淡雾蓝纸 · 清朗通透',
    previewDay: Color(0xFFEEF4FA),
    previewNight: Color(0xFFE4EDF6),
    palette: EchoPalette(
      dayBackground: Color(0xFFEEF4FA),
      nightBackground: Color(0xFFE4EDF6),
      daySurface: Color(0xFFF8FBFE),
      dayWriting: Color(0xFFE4ECF4),
      dayDivider: Color(0xFFD4E0EC),
      dayNavBorder: Color(0xFFC8D8E6),
      nightNavBorder: Color(0xFFBCCEDE),
      nightSurface: Color(0xFFDCE6F0),
      insightSurface: Color(0xFFE4ECF4),
      sheetDivider: Color(0xFFDAE4EE),
    ),
  );

  static const mossWhisper = EchoAppearancePreset(
    id: 'moss_whisper',
    name: '绢黄',
    subtitle: '淡绢黄纸 · 明亮舒展',
    previewDay: Color(0xFFFAF6E8),
    previewNight: Color(0xFFF2ECD8),
    palette: EchoPalette(
      dayBackground: Color(0xFFFAF6E8),
      nightBackground: Color(0xFFF2ECD8),
      daySurface: Color(0xFFFFFDF6),
      dayWriting: Color(0xFFF0E8D4),
      dayDivider: Color(0xFFE6DCC4),
      dayNavBorder: Color(0xFFE0D4BA),
      nightNavBorder: Color(0xFFD6C8AE),
      nightSurface: Color(0xFFEAE2CE),
      insightSurface: Color(0xFFF0E8D4),
      sheetDivider: Color(0xFFECE4D0),
    ),
  );

  static const morningMistDeep = EchoAppearancePreset(
    id: 'morning_mist_deep',
    name: '绯霞',
    subtitle: '加深粉霞 · 更沉静',
    previewDay: Color(0xFFF2D0DE),
    previewNight: Color(0xFFEAC6D6),
    palette: EchoPalette(
      dayBackground: Color(0xFFF2D0DE),
      nightBackground: Color(0xFFEAC6D6),
      daySurface: Color(0xFFF8E4EC),
      dayWriting: Color(0xFFE6B8CC),
      dayDivider: Color(0xFFDCB0C4),
      dayNavBorder: Color(0xFFD4A6BA),
      nightNavBorder: Color(0xFFC89CB0),
      nightSurface: Color(0xFFE0B8CA),
      insightSurface: Color(0xFFE6B8CC),
      sheetDivider: Color(0xFFE4B4C8),
    ),
  );

  static const apricotCreamDeep = EchoAppearancePreset(
    id: 'apricot_cream_deep',
    name: '紫苑',
    subtitle: '浅紫纸色 · 静谧柔和',
    previewDay: Color(0xFFEDE6F4),
    previewNight: Color(0xFFE4DBEE),
    palette: EchoPalette(
      dayBackground: Color(0xFFEDE6F4),
      nightBackground: Color(0xFFE4DBEE),
      daySurface: Color(0xFFF7F4FA),
      dayWriting: Color(0xFFDDD2EA),
      dayDivider: Color(0xFFD0C4DE),
      dayNavBorder: Color(0xFFC6B8D6),
      nightNavBorder: Color(0xFFBAACCE),
      nightSurface: Color(0xFFD4CAE4),
      insightSurface: Color(0xFFDDD2EA),
      sheetDivider: Color(0xFFD8CFE8),
    ),
  );

  static const mossWhisperDeep = EchoAppearancePreset(
    id: 'moss_whisper_deep',
    name: '青岚',
    subtitle: '浅青岚纸 · 清爽自然',
    previewDay: Color(0xFFE4F2EE),
    previewNight: Color(0xFFD8EAE4),
    palette: EchoPalette(
      dayBackground: Color(0xFFE4F2EE),
      nightBackground: Color(0xFFD8EAE4),
      daySurface: Color(0xFFF0FAF7),
      dayWriting: Color(0xFFCDE6DE),
      dayDivider: Color(0xFFBDDAD0),
      dayNavBorder: Color(0xFFB2D0C6),
      nightNavBorder: Color(0xFFA6C4BA),
      nightSurface: Color(0xFFC4DDD4),
      insightSurface: Color(0xFFCDE6DE),
      sheetDivider: Color(0xFFC8E0D8),
    ),
  );

  static const all = [
    warmPaper,
    pureWhite,
    morningMist,
    morningMistDeep,
    apricotCream,
    apricotCreamDeep,
    mossWhisper,
    mossWhisperDeep,
  ];

  static EchoAppearancePreset byId(String? id) {
    for (final preset in all) {
      if (preset.id == id) return preset;
    }
    return switch (id) {
      'twilight_paper' || 'twilight_paper_deep' => warmPaper,
      'pure_white' => pureWhite,
      _ => warmPaper,
    };
  }
}

extension EchoAppearancePresetL10n on EchoAppearancePreset {
  String get localizedName => switch (id) {
        'pure_white' => tr('素白', 'Pure white'),
        'warm_paper' => tr('暖纸', 'Warm paper'),
        'morning_mist' => tr('粉霞', 'Rose dawn'),
        'morning_mist_deep' => tr('绯霞', 'Deep rose'),
        'apricot_cream' => tr('雾蓝', 'Mist blue'),
        'apricot_cream_deep' => tr('紫苑', 'Lavender'),
        'moss_whisper' => tr('绢黄', 'Silk gold'),
        'moss_whisper_deep' => tr('青岚', 'Green mist'),
        _ => name,
      };

  String get localizedSubtitle => switch (id) {
        'pure_white' => tr('白净素纸 · 清爽留白', 'Clean white · airy space'),
        'warm_paper' => tr('淡暖米纸 · 柔和护眼', 'Warm cream · easy on eyes'),
        'morning_mist' => tr('蔷薇粉纸 · 轻柔温馨', 'Rose pink · soft warmth'),
        'morning_mist_deep' => tr('加深粉霞 · 更沉静', 'Deeper rose · calmer'),
        'apricot_cream' => tr('淡雾蓝纸 · 清朗通透', 'Mist blue · clear air'),
        'apricot_cream_deep' => tr('浅紫纸色 · 静谧柔和', 'Soft lavender · quiet'),
        'moss_whisper' => tr('淡绢黄纸 · 明亮舒展', 'Silk gold · bright ease'),
        'moss_whisper_deep' => tr('浅青岚纸 · 清爽自然', 'Green mist · fresh'),
        _ => subtitle,
      };
}
