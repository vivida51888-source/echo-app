import 'package:flutter/material.dart';

import '../l10n/localized.dart';

/// 回响拾遗：情绪小铺可收集的纪念物。
enum EchoCollectibleKind {
  focusFlower,
  timeSeed,
  resonanceShell;

  static EchoCollectibleKind fromName(String? raw) => switch (raw) {
        'focus_flower' => EchoCollectibleKind.focusFlower,
        'time_seed' => EchoCollectibleKind.timeSeed,
        'resonance_shell' => EchoCollectibleKind.resonanceShell,
        _ => EchoCollectibleKind.focusFlower,
      };
}

extension EchoCollectibleKindX on EchoCollectibleKind {
  String get name => switch (this) {
        EchoCollectibleKind.focusFlower => tr('专注之花', 'Focus flower'),
        EchoCollectibleKind.timeSeed => tr('时间种子', 'Time seed'),
        EchoCollectibleKind.resonanceShell =>
          tr('共鸣贝壳', 'Resonance shell'),
      };

  String get shopHint => switch (this) {
        EchoCollectibleKind.focusFlower => tr(
              '连续完成待办，会生长出专注之花',
              'Complete tasks on a streak to grow a focus flower',
            ),
        EchoCollectibleKind.timeSeed => tr(
              '在未来信箱里存一封信，立刻得到时间种子',
              'Seal a letter in Future Mail to earn a time seed',
            ),
        EchoCollectibleKind.resonanceShell => tr(
              '拾起漂流瓶并给予回响，获得共鸣贝壳',
              'Reply to a drift bottle to earn a resonance shell',
            ),
      };

  String get earnDetail => switch (this) {
        EchoCollectibleKind.focusFlower => tr(
              '连续 3 / 7 / 14 天完成待办',
              '3 / 7 / 14-day task streaks',
            ),
        EchoCollectibleKind.timeSeed =>
          tr('每封存一封信', 'Each sealed letter'),
        EchoCollectibleKind.resonanceShell =>
          tr('每次给予漂流瓶回响', 'Each drift bottle reply'),
      };

  IconData get icon => switch (this) {
        EchoCollectibleKind.focusFlower => Icons.local_florist_outlined,
        EchoCollectibleKind.timeSeed => Icons.grain_rounded,
        EchoCollectibleKind.resonanceShell => Icons.water_drop_outlined,
      };

  Color get tint => switch (this) {
        EchoCollectibleKind.focusFlower => const Color(0xFF7FAF82),
        EchoCollectibleKind.timeSeed => const Color(0xFF8A7AA8),
        EchoCollectibleKind.resonanceShell => const Color(0xFF7A9AB0),
      };

  String get storageName => switch (this) {
        EchoCollectibleKind.focusFlower => 'focus_flower',
        EchoCollectibleKind.timeSeed => 'time_seed',
        EchoCollectibleKind.resonanceShell => 'resonance_shell',
      };
}

class EchoCollectibleItem {
  const EchoCollectibleItem({
    required this.id,
    required this.kind,
    required this.earnedAt,
    this.sourceId,
    this.streakDays,
  });

  final String id;
  final EchoCollectibleKind kind;
  final DateTime earnedAt;
  final String? sourceId;
  final int? streakDays;

  bool get isRare =>
      kind == EchoCollectibleKind.focusFlower && (streakDays ?? 0) >= 7;

  String get displayName {
    if (kind == EchoCollectibleKind.focusFlower) {
      final days = streakDays ?? 0;
      if (days >= 14) {
        return tr('专注之花·珍', 'Focus flower · Rare');
      }
      if (days >= 7) {
        return tr('专注之花·稀', 'Focus flower · Special');
      }
      return kind.name;
    }
    return kind.name;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'kind': kind.storageName,
        'earnedAt': earnedAt.toIso8601String(),
        if (sourceId != null) 'sourceId': sourceId,
        if (streakDays != null) 'streakDays': streakDays,
      };

  factory EchoCollectibleItem.fromMap(Map<dynamic, dynamic> map) {
    return EchoCollectibleItem(
      id: map['id'] as String,
      kind: EchoCollectibleKind.fromName(map['kind'] as String?),
      earnedAt: DateTime.parse(map['earnedAt'] as String),
      sourceId: map['sourceId'] as String?,
      streakDays: map['streakDays'] as int?,
    );
  }
}
