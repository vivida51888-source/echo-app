import 'package:flutter/material.dart';

import 'echo_tree_growth.dart';
import '../utils/echo_bubble_layout.dart';

/// 雨露来源（用于区分视觉样式）。
enum EchoWaterBubbleKind {
  diary,
  backfill,
  todo,
  futureLetter,
  driftBottle,
}

/// 待收集的一滴雨露（类似能量泡）。
class EchoWaterBubble {
  const EchoWaterBubble({
    required this.id,
    required this.diaryId,
    required this.grams,
    required this.createdAt,
    required this.layoutSeed,
    this.streakDays = 1,
    this.anchorX,
    this.anchorY,
  });

  final String id;
  final String diaryId;
  final int grams;
  final DateTime createdAt;
  final int layoutSeed;
  final int streakDays;
  final double? anchorX;
  final double? anchorY;

  Duration get age => DateTime.now().difference(createdAt);

  Duration get timeLeft => EchoTreeGrowthModel.bubbleMaxAge - age;

  bool get isExpired => timeLeft <= Duration.zero;

  bool get isUrgent => timeLeft.inHours < 6;

  /// ≥1 天显示「N 天后」，不足 1 天再显示小时/分钟。
  String get timeLeftLabel => EchoWaterBubble.formatTimeLeft(timeLeft);

  static String formatTimeLeft(Duration left) {
    if (left <= Duration.zero) return '即将消失';

    if (left.inHours >= 24) {
      return '${left.inHours ~/ 24} 天后消失';
    }
    if (left.inHours >= 1) {
      return '${left.inHours} 小时后消失';
    }

    final minutes = left.inMinutes;
    if (minutes >= 1) return '$minutes 分钟后消失';

    return '即将消失';
  }

  bool get isBackfillPool =>
      diaryId == EchoTreeBubbleRules.backfillPoolDiaryId;

  EchoWaterBubbleKind get kind {
    if (isBackfillPool) return EchoWaterBubbleKind.backfill;
    if (diaryId.startsWith('todo_all_')) return EchoWaterBubbleKind.todo;
    if (diaryId.startsWith('future_letter_')) {
      return EchoWaterBubbleKind.futureLetter;
    }
    if (diaryId.startsWith('drift_reply_')) {
      return EchoWaterBubbleKind.driftBottle;
    }
    return EchoWaterBubbleKind.diary;
  }

  String? get kindLabel {
    switch (kind) {
      case EchoWaterBubbleKind.todo:
        return '待办';
      case EchoWaterBubbleKind.futureLetter:
        return '未来信';
      case EchoWaterBubbleKind.driftBottle:
        return '漂流';
      case EchoWaterBubbleKind.backfill:
        return '补记';
      case EchoWaterBubbleKind.diary:
        return null;
    }
  }

  BubbleAnchor get anchor {
    if (anchorX != null && anchorY != null) {
      return BubbleAnchor(anchorX!, anchorY!);
    }
    return EchoBubbleLayout.anchorFromSeed(layoutSeed);
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'diaryId': diaryId,
        'grams': grams,
        'createdAt': createdAt.toIso8601String(),
        'layoutSeed': layoutSeed,
        'streakDays': streakDays,
        if (anchorX != null) 'anchorX': anchorX,
        if (anchorY != null) 'anchorY': anchorY,
      };

  factory EchoWaterBubble.fromMap(Map<dynamic, dynamic> map) {
    return EchoWaterBubble(
      id: map['id'] as String,
      diaryId: map['diaryId'] as String,
      grams: map['grams'] as int? ?? 10,
      createdAt: DateTime.parse(map['createdAt'] as String),
      layoutSeed: map['layoutSeed'] as int? ?? 0,
      streakDays: map['streakDays'] as int? ?? 1,
      anchorX: (map['anchorX'] as num?)?.toDouble(),
      anchorY: (map['anchorY'] as num?)?.toDouble(),
    );
  }
}

/// 雨露泡配色：日记保持绿色，待办 / 未来信 / 漂流瓶各自独立色系。
class EchoBubblePalette {
  const EchoBubblePalette({
    required this.gradient,
    required this.textColor,
    required this.gainColor,
  });

  final List<Color> gradient;
  final Color textColor;
  final Color gainColor;

  static EchoBubblePalette forBubble(EchoWaterBubble bubble) {
    if (bubble.kind == EchoWaterBubbleKind.diary && bubble.streakDays > 1) {
      return _diaryStreak;
    }
    return switch (bubble.kind) {
      EchoWaterBubbleKind.todo => _todo,
      EchoWaterBubbleKind.futureLetter => _futureLetter,
      EchoWaterBubbleKind.driftBottle => _driftBottle,
      EchoWaterBubbleKind.backfill => _backfill,
      EchoWaterBubbleKind.diary => _diary,
    };
  }

  static const _diary = EchoBubblePalette(
    gradient: [Color(0xFFE8FF8A), Color(0xFF7BC47F)],
    textColor: Color(0xFF2D5016),
    gainColor: Color(0xFF7BA889),
  );

  static const _diaryStreak = EchoBubblePalette(
    gradient: [Color(0xFFFFF3B0), Color(0xFF8BC48A)],
    textColor: Color(0xFF2D5016),
    gainColor: Color(0xFF7BA889),
  );

  static const _backfill = EchoBubblePalette(
    gradient: [Color(0xFFE8EDE0), Color(0xFF9BB08F)],
    textColor: Color(0xFF3D5038),
    gainColor: Color(0xFF8FA888),
  );

  static const _todo = EchoBubblePalette(
    gradient: [Color(0xFFC9E8FF), Color(0xFF6F9DC4)],
    textColor: Color(0xFF1A4560),
    gainColor: Color(0xFF6F9DC4),
  );

  static const _futureLetter = EchoBubblePalette(
    gradient: [Color(0xFFF3E8FF), Color(0xFFC9A0E0)],
    textColor: Color(0xFF4A3560),
    gainColor: Color(0xFFB892D4),
  );

  static const _driftBottle = EchoBubblePalette(
    gradient: [Color(0xFFD5ECF5), Color(0xFF7EADBE)],
    textColor: Color(0xFF2A5566),
    gainColor: Color(0xFF7EADBE),
  );
}

/// 成长进度（由累计浇水量决定，可长期累积）。
class EchoTreeGrowth {
  const EchoTreeGrowth({
    required this.stage,
    required this.stageLabel,
    required this.visualStage,
    required this.lifeWater,
    required this.waterForCurrentStage,
    required this.waterForNextStage,
  });

  final int stage;
  final String stageLabel;
  final int visualStage;
  final int lifeWater;
  final int waterForCurrentStage;
  final int waterForNextStage;

  int? get waterToNext {
    if (waterForNextStage <= waterForCurrentStage) return null;
    return waterForNextStage - lifeWater;
  }

  double get progress {
    if (waterForNextStage <= waterForCurrentStage) return 1;
    final span = waterForNextStage - waterForCurrentStage;
    final gained = lifeWater - waterForCurrentStage;
    return (gained / span).clamp(0.0, 1.0);
  }

  String? get companionLabel {
    if (stage < 9) return null;
    if (stage == 9) return '古树已养成';
    final seasons = stage - 8;
    return '守护 $seasons 季';
  }
}
