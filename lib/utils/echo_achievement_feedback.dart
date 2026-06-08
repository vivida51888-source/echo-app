import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../models/echo_achievement.dart';
import '../pages/keepsakes_page.dart';
import '../services/echo_reward_service.dart';
import '../widgets/echo_coin_collect_overlay.dart';
import '../widgets/echo_hint.dart';

/// 打开个人成就时播放飞币动画（仅视觉，币已在解锁时入账）。
Future<void> playAchievementCoinAnimation(
  BuildContext context, {
  GlobalKey? coinTargetKey,
}) async {
  final batch = EchoRewardService.instance.takeUnreadUnlocks();
  if (batch.isEmpty || !context.mounted) return;

  final totalCoins = batch.fold<int>(0, (sum, u) => sum + u.coins);
  await EchoCoinCollectOverlay.play(
    context,
    totalCoins: totalCoins,
    targetKey: coinTargetKey,
  );
}

void showAchievementUnlockSnack(
  BuildContext context,
  EchoAchievementUnlock unlock,
) {
  _showUnlockSnack(context, [unlock]);
}

void _showUnlockSnack(
  BuildContext context,
  List<EchoAchievementUnlock> unlocks,
) {
  if (unlocks.isEmpty) return;

  final message = unlocks.length == 1
      ? unlocks.first.message
      : tr(
          '达成 ${unlocks.length} 项成就 · +${unlocks.fold<int>(0, (s, u) => s + u.coins)} 回响币',
          '${unlocks.length} achievements · +${unlocks.fold<int>(0, (s, u) => s + u.coins)} Echo coins',
        );

  showEchoBriefHint(
    context,
    message: message,
    tone: EchoBriefHintTone.success,
    actionLabel: tr('查看', 'View'),
    onAction: () => openPersonalAchievementsPage(context),
  );
}
