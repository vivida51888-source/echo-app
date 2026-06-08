import 'package:flutter/material.dart';

import '../l10n/localized.dart';

/// 成就分类（个人成就列表分区）。
enum EchoAchievementCategory {
  writing,
  tasks,
  growth,
  expression;

  String get label => switch (this) {
        EchoAchievementCategory.writing =>
          tr('写作回响', 'Writing echoes'),
        EchoAchievementCategory.tasks => tr('待办安放', 'Tasks done'),
        EchoAchievementCategory.growth => tr('成长收集', 'Growth'),
        EchoAchievementCategory.expression =>
          tr('心情表达', 'Mood & photos'),
      };
}

enum EchoAchievementId {
  diaryDays,
  writingStreak,
  totalEntries,
  todosDone,
  todoStreak,
  futureLetters,
  driftReplies,
  lifeWater,
  photosPinned,
  moodDays,
  importantMarks,
  treeStage,
  weekRhythm,
  nightWriter,
  morningWriter,
}

class EchoAchievementTier {
  const EchoAchievementTier(this.threshold, this.coinReward);

  final int threshold;
  final int coinReward;
}

class EchoAchievementDef {
  const EchoAchievementDef({
    required this.id,
    required this.category,
    required this.icon,
    required this.tint,
    required this.tiers,
  });

  final EchoAchievementId id;
  final EchoAchievementCategory category;
  final IconData icon;
  final Color tint;
  final List<EchoAchievementTier> tiers;

  String get name => switch (id) {
        EchoAchievementId.diaryDays => tr('记下日子', 'Days remembered'),
        EchoAchievementId.writingStreak =>
          tr('连续回响', 'Writing streak'),
        EchoAchievementId.totalEntries => tr('篇章收藏家', 'Chapter keeper'),
        EchoAchievementId.todosDone => tr('安放小事', 'Tasks placed'),
        EchoAchievementId.todoStreak => tr('连续安放', 'Task streak'),
        EchoAchievementId.futureLetters => tr('未来信使', 'Future messenger'),
        EchoAchievementId.driftReplies => tr('漂流回响', 'Drift replies'),
        EchoAchievementId.lifeWater => tr('浇灌之树', 'Tree gardener'),
        EchoAchievementId.photosPinned => tr('墙面策展', 'Wall curator'),
        EchoAchievementId.moodDays => tr('心情观测', 'Mood watcher'),
        EchoAchievementId.importantMarks => tr('重要印记', 'Marked days'),
        EchoAchievementId.treeStage => tr('树之阶段', 'Tree milestones'),
        EchoAchievementId.weekRhythm => tr('周律回响', 'Weekly rhythm'),
        EchoAchievementId.nightWriter => tr('夜写者', 'Night writer'),
        EchoAchievementId.morningWriter => tr('晨写者', 'Morning writer'),
      };

  String get hint => switch (id) {
        EchoAchievementId.diaryDays =>
          tr('有回响的日子', 'Days with an echo'),
        EchoAchievementId.writingStreak =>
          tr('连续写日记', 'Consecutive writing days'),
        EchoAchievementId.totalEntries =>
          tr('累计篇章数', 'Total entries'),
        EchoAchievementId.todosDone =>
          tr('累计安放待办', 'Tasks completed'),
        EchoAchievementId.todoStreak =>
          tr('连续完成待办', 'Consecutive task days'),
        EchoAchievementId.futureLetters =>
          tr('封存未来信', 'Letters sealed'),
        EchoAchievementId.driftReplies =>
          tr('给予漂流瓶回响', 'Drift bottle replies'),
        EchoAchievementId.lifeWater =>
          tr('累计浇下雨露', 'Total dew poured (g)'),
        EchoAchievementId.photosPinned =>
          tr('回响附带照片', 'Photos in echoes'),
        EchoAchievementId.moodDays =>
          tr('标记心情的天数', 'Days with mood marked'),
        EchoAchievementId.importantMarks =>
          tr('添加重要日', 'Important days added'),
        EchoAchievementId.treeStage =>
          tr('回响之树阶段', 'Echo tree stage'),
        EchoAchievementId.weekRhythm =>
          tr('一周写下 3+ 天', 'Weeks with 3+ writing days'),
        EchoAchievementId.nightWriter =>
          tr('22:00 后写回响', 'Entries after 10 PM'),
        EchoAchievementId.morningWriter =>
          tr('8:00 前写回响', 'Entries before 8 AM'),
      };

  String get storageKey => id.name;

  /// 下一颗星的目标说明（海岛奇兵式进度文案）。
  String nextGoalText(int progress, int claimedStars) {
    if (claimedStars >= tiers.length) {
      return tr('已满三星', 'Three stars earned');
    }
    final tier = tiers[claimedStars];
    final need = tier.threshold;
    final remain = (need - progress).clamp(0, need);
    if (progress >= need) {
      return tr('可领取 · +${tier.coinReward} 回响币', 'Ready · +${tier.coinReward} coins');
    }
    return tr('$progress / $need · 还差 $remain · +${tier.coinReward} 回响币', '$progress / $need · $remain to go · +${tier.coinReward} coins');
  }

  int starCount(int claimedStars) => claimedStars.clamp(0, tiers.length);

  /// 某一档成就的完整说明（详情弹窗用）。
  String tierRequirementDetail(int tierIndex) {
    final tier = tiers[tierIndex];
    return tr('第 ${tierIndex + 1} 颗星：$hint，达成 ${tier.threshold} · +${tier.coinReward} 回响币', 'Star ${tierIndex + 1}: $hint — reach ${tier.threshold} · +${tier.coinReward} Echo coins');
  }

  String progressSummary(int progress, int claimedStars) {
    if (claimedStars >= tiers.length) {
      return tr('三项成就已全部达成', 'All three stars earned');
    }
    final next = tiers[claimedStars];
    final remain = (next.threshold - progress).clamp(0, next.threshold);
    return tr('当前进度 $progress · 距下一颗星还差 $remain', 'Current progress: $progress · $remain until next star');
  }
}

abstract final class EchoAchievements {
  static const all = [
    EchoAchievementDef(
      id: EchoAchievementId.diaryDays,
      category: EchoAchievementCategory.writing,
      icon: Icons.edit_note_outlined,
      tint: Color(0xFF7BA889),
      tiers: [
        EchoAchievementTier(3, 20),
        EchoAchievementTier(14, 45),
        EchoAchievementTier(30, 90),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.writingStreak,
      category: EchoAchievementCategory.writing,
      icon: Icons.local_fire_department_outlined,
      tint: Color(0xFFE8A838),
      tiers: [
        EchoAchievementTier(3, 25),
        EchoAchievementTier(7, 55),
        EchoAchievementTier(30, 120),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.totalEntries,
      category: EchoAchievementCategory.writing,
      icon: Icons.menu_book_outlined,
      tint: Color(0xFF8A7AA8),
      tiers: [
        EchoAchievementTier(10, 20),
        EchoAchievementTier(50, 50),
        EchoAchievementTier(100, 100),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.weekRhythm,
      category: EchoAchievementCategory.writing,
      icon: Icons.calendar_view_week_outlined,
      tint: Color(0xFF6B8CAE),
      tiers: [
        EchoAchievementTier(2, 25),
        EchoAchievementTier(8, 60),
        EchoAchievementTier(24, 130),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.nightWriter,
      category: EchoAchievementCategory.writing,
      icon: Icons.nightlight_outlined,
      tint: Color(0xFF6A5A8A),
      tiers: [
        EchoAchievementTier(3, 20),
        EchoAchievementTier(15, 50),
        EchoAchievementTier(40, 100),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.morningWriter,
      category: EchoAchievementCategory.writing,
      icon: Icons.wb_sunny_outlined,
      tint: Color(0xFFD4A84B),
      tiers: [
        EchoAchievementTier(3, 20),
        EchoAchievementTier(15, 50),
        EchoAchievementTier(40, 100),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.todosDone,
      category: EchoAchievementCategory.tasks,
      icon: Icons.check_circle_outline,
      tint: Color(0xFF6FAF82),
      tiers: [
        EchoAchievementTier(5, 20),
        EchoAchievementTier(25, 50),
        EchoAchievementTier(100, 110),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.todoStreak,
      category: EchoAchievementCategory.tasks,
      icon: Icons.bolt_outlined,
      tint: Color(0xFF5A9E78),
      tiers: [
        EchoAchievementTier(3, 25),
        EchoAchievementTier(7, 55),
        EchoAchievementTier(14, 100),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.futureLetters,
      category: EchoAchievementCategory.growth,
      icon: Icons.mark_email_unread_outlined,
      tint: Color(0xFF9B87C4),
      tiers: [
        EchoAchievementTier(1, 30),
        EchoAchievementTier(5, 65),
        EchoAchievementTier(15, 120),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.driftReplies,
      category: EchoAchievementCategory.growth,
      icon: Icons.water_outlined,
      tint: Color(0xFF7A9AB0),
      tiers: [
        EchoAchievementTier(1, 25),
        EchoAchievementTier(10, 60),
        EchoAchievementTier(30, 130),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.lifeWater,
      category: EchoAchievementCategory.growth,
      icon: Icons.water_drop_outlined,
      tint: Color(0xFF7EADBE),
      tiers: [
        EchoAchievementTier(100, 25),
        EchoAchievementTier(500, 60),
        EchoAchievementTier(2000, 130),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.treeStage,
      category: EchoAchievementCategory.growth,
      icon: Icons.park_outlined,
      tint: Color(0xFF5A8A5E),
      tiers: [
        EchoAchievementTier(2, 30),
        EchoAchievementTier(5, 70),
        EchoAchievementTier(8, 140),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.photosPinned,
      category: EchoAchievementCategory.expression,
      icon: Icons.photo_library_outlined,
      tint: Color(0xFFB8956A),
      tiers: [
        EchoAchievementTier(5, 20),
        EchoAchievementTier(20, 50),
        EchoAchievementTier(50, 100),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.moodDays,
      category: EchoAchievementCategory.expression,
      icon: Icons.cloud_outlined,
      tint: Color(0xFF6B8CAE),
      tiers: [
        EchoAchievementTier(7, 25),
        EchoAchievementTier(30, 60),
        EchoAchievementTier(90, 120),
      ],
    ),
    EchoAchievementDef(
      id: EchoAchievementId.importantMarks,
      category: EchoAchievementCategory.expression,
      icon: Icons.favorite_border_rounded,
      tint: Color(0xFFC98A8A),
      tiers: [
        EchoAchievementTier(1, 20),
        EchoAchievementTier(5, 50),
        EchoAchievementTier(15, 100),
      ],
    ),
  ];

  static EchoAchievementDef byId(EchoAchievementId id) =>
      all.firstWhere((a) => a.id == id);

  static List<EchoAchievementDef> forCategory(EchoAchievementCategory cat) =>
      all.where((a) => a.category == cat).toList();
}

/// 刚解锁的成就档位（用于 SnackBar）。
class EchoAchievementUnlock {
  const EchoAchievementUnlock({
    required this.achievement,
    required this.tierIndex,
    required this.coins,
  });

  final EchoAchievementDef achievement;
  final int tierIndex;
  final int coins;

  String get message => tr(
        '「${achievement.name}」获得第 ${tierIndex + 1} 颗星 · +$coins 回响币',
        '${achievement.name} · star ${tierIndex + 1} · +$coins Echo coins',
      );
}
