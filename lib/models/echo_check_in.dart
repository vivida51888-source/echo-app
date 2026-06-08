import 'package:flutter/material.dart';

import '../l10n/localized.dart';

enum EchoCheckInRewardKind { coins, bubble, combo }

class EchoCheckInReward {
  const EchoCheckInReward({
    required this.kind,
    this.coins = 0,
    this.bubbleGrams = 0,
  });

  final EchoCheckInRewardKind kind;
  final int coins;
  final int bubbleGrams;

  bool get isEmpty => coins <= 0 && bubbleGrams <= 0;

  String get shortLabel => switch (kind) {
        EchoCheckInRewardKind.coins => tr('$coins', '$coins'),
        EchoCheckInRewardKind.bubble => tr('${bubbleGrams}g', '${bubbleGrams}g'),
        EchoCheckInRewardKind.combo =>
          tr('$coins+${bubbleGrams}g', '$coins+${bubbleGrams}g'),
      };

  String get label => switch (kind) {
        EchoCheckInRewardKind.coins => tr(
              '+$coins 回响币',
              '+$coins Echo coins',
            ),
        EchoCheckInRewardKind.bubble => tr(
              '+${bubbleGrams}g 能量泡',
              '+${bubbleGrams}g energy bubble',
            ),
        EchoCheckInRewardKind.combo => tr(
              '+$coins 币 · +${bubbleGrams}g 泡',
              '+$coins coins · +${bubbleGrams}g bubble',
            ),
      };

  EchoCheckInReward doubled() => EchoCheckInReward(
        kind: kind,
        coins: coins * 2,
        bubbleGrams: bubbleGrams * 2,
      );
}

/// 当月签到：按日历日发放；周日奖励翻倍。
abstract final class EchoCheckInRewards {
  static EchoCheckInReward forDate(DateTime date) {
    final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
    final base = _baseForDay(date.day, daysInMonth);
    if (date.weekday == DateTime.sunday) return base.doubled();
    return base;
  }

  static EchoCheckInReward _baseForDay(int day, int daysInMonth) {
    if (day == daysInMonth) {
      return const EchoCheckInReward(
        kind: EchoCheckInRewardKind.combo,
        coins: 6,
        bubbleGrams: 8,
      );
    }
    if (day == 15) {
      return const EchoCheckInReward(
        kind: EchoCheckInRewardKind.combo,
        coins: 4,
        bubbleGrams: 6,
      );
    }
    if (day % 7 == 0) {
      return const EchoCheckInReward(
        kind: EchoCheckInRewardKind.coins,
        coins: 5,
      );
    }
    return switch (day % 4) {
      1 => const EchoCheckInReward(
          kind: EchoCheckInRewardKind.coins,
          coins: 3,
        ),
      2 => const EchoCheckInReward(
          kind: EchoCheckInRewardKind.bubble,
          bubbleGrams: 4,
        ),
      3 => const EchoCheckInReward(
          kind: EchoCheckInRewardKind.coins,
          coins: 4,
        ),
      _ => const EchoCheckInReward(
          kind: EchoCheckInRewardKind.bubble,
          bubbleGrams: 5,
        ),
    };
  }
}

/// 签到日历配色：工作日深蓝、周日紫色。
abstract final class EchoCheckInColors {
  static bool isSunday(DateTime date) => date.weekday == DateTime.sunday;

  static Color dateBackground(DateTime date, {required bool dimmed}) {
    final base = isSunday(date)
        ? const Color(0xFFF3EBFF)
        : const Color(0xFFE8F1FB);
    return dimmed ? base.withValues(alpha: 0.45) : base;
  }

  static Color dateText(DateTime date, {required bool dimmed}) {
    final base = isSunday(date)
        ? const Color(0xFF6B4E8A)
        : const Color(0xFF3D5A80);
    return dimmed ? base.withValues(alpha: 0.45) : base;
  }

  static Color rewardBackground(DateTime date, {required bool dimmed}) {
    final base = isSunday(date)
        ? const Color(0xFF6B4E8A)
        : const Color(0xFF2E4A6E);
    return dimmed ? base.withValues(alpha: 0.32) : base.withValues(alpha: 0.92);
  }

  static Color rewardBorder(DateTime date, {required bool dimmed}) {
    final base = isSunday(date)
        ? const Color(0xFF8A6AA8)
        : const Color(0xFF4A6A94);
    return dimmed ? base.withValues(alpha: 0.35) : base;
  }
}
