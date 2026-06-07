import 'echo_water_bubble.dart';

abstract final class EchoTreeBubbleRules {
  static const backfillPoolDiaryId = '__echo_backfill__';

  static const diaryBaseGrams = 5;
  static const backfillPoolGrams = 3;
  static const dailyTodoGrams = 5;
  static const futureLetterGrams = 50;
  static const driftReplyGrams = 10;

  /// 连续写日记额外奖励（含当天基础 5g 之外的加成）。
  static int streakBonus(int streakDays) {
    if (streakDays >= 7) return 20;
    if (streakDays == 6) return 15;
    if (streakDays == 5) return 10;
    if (streakDays == 4) return 8;
    if (streakDays == 3) return 5;
    return 0;
  }

  static int diaryTotalGrams(int streakDays) =>
      diaryBaseGrams + streakBonus(streakDays);
}

/// 回响之树成长阶段与雨露计算（单棵树，长期累积）。
abstract final class EchoTreeGrowthModel {
  static const bubbleMaxAge = Duration(days: 2);

  static const _namedStages = [
    '种子期',
    '萌芽期',
    '幼苗期',
    '成长期',
    '壮苗期',
    '小树期',
    '枝茂期',
    '茁壮期',
    '成树期',
    '古树期',
  ];

  /// 各阶段累计浇水量（约 2–3 年日常记录可达古树期）。
  static const _stageThresholds = [
    0,
    60,
    180,
    400,
    720,
    1150,
    1700,
    2400,
    3250,
    4300,
  ];

  static const _postAncientStepGrams = 750;

  static int waterRequiredForStage(int stage) {
    if (stage <= 0) return 0;
    if (stage < _stageThresholds.length) {
      return _stageThresholds[stage];
    }
    var water = _stageThresholds.last;
    for (var s = _stageThresholds.length; s <= stage; s++) {
      water += _postAncientStepGrams;
    }
    return water;
  }

  static int stageForLifeWater(int lifeWater) {
    var stage = 0;
    while (waterRequiredForStage(stage + 1) <= lifeWater) {
      stage++;
      if (stage > 5000) break;
    }
    return stage;
  }

  static String stageLabel(int stage) {
    if (stage < _namedStages.length) return _namedStages[stage];
    final rings = stage - _namedStages.length + 1;
    return '守护期 · $rings';
  }

  /// 0–6 对应可视化形态；更高阶段复用最成熟形态。
  static int visualStageFor(int stage) {
    if (stage <= 0) return 0;
    if (stage <= 2) return stage;
    if (stage <= 4) return 3;
    if (stage <= 6) return 4;
    if (stage <= 8) return 5;
    return 6;
  }

  static EchoTreeGrowth growthFor(int lifeWater) {
    final stage = stageForLifeWater(lifeWater);
    return EchoTreeGrowth(
      stage: stage,
      stageLabel: stageLabel(stage),
      visualStage: visualStageFor(stage),
      lifeWater: lifeWater,
      waterForCurrentStage: waterRequiredForStage(stage),
      waterForNextStage: waterRequiredForStage(stage + 1),
    );
  }
}

enum EchoTreeWiltLevel {
  none,
  mild,
  soft,
}

extension EchoTreeWiltLevelX on EchoTreeWiltLevel {
  double get saturation {
    switch (this) {
      case EchoTreeWiltLevel.none:
        return 1;
      case EchoTreeWiltLevel.mild:
        return 0.82;
      case EchoTreeWiltLevel.soft:
        return 0.62;
    }
  }

  double get droop {
    switch (this) {
      case EchoTreeWiltLevel.none:
        return 0;
      case EchoTreeWiltLevel.mild:
        return 0.018;
      case EchoTreeWiltLevel.soft:
        return 0.035;
    }
  }
}
