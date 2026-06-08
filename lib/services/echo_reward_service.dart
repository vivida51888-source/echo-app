import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/localized.dart';
import '../models/diary_stationery.dart';
import '../models/echo_achievement.dart';
import '../models/echo_shop_catalog.dart';
import '../models/photo_wall_material.dart';
import 'diary_service.dart';
import 'echo_tree_service.dart';
import 'future_letter_service.dart';
import 'important_day_service.dart';
import 'echo_plus_service.dart';
import 'todo_service.dart';

/// 回响币、成就与个人仓库 / 情绪小铺。
class EchoRewardService extends ChangeNotifier {
  EchoRewardService._();

  static final EchoRewardService instance = EchoRewardService._();

  static const _boxName = 'echo_rewards';
  static const _coinsKey = 'coins';
  static const _claimedKey = 'claimed_tiers';
  static const _unlocksKey = 'shop_unlocks';
  static const _todoDaysKey = 'todo_completion_days';
  static const _driftRepliesKey = 'drift_replies';
  static const _migratedKey = 'migrated_collectibles_v1';
  static const _unreadUnlocksKey = 'unread_unlocks';

  Box<dynamic>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  /// [EchoPlusService] 权益变化时刷新皮肤解锁状态。
  void onPlusEntitlementChanged() => notifyListeners();

  int get coins => _box?.get(_coinsKey) as int? ?? 0;

  int get unreadAchievementCount => _unreadUnlockKeys.length;

  List<String> get _unreadUnlockKeys {
    final raw = _box?.get(_unreadUnlocksKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw.map((e) => e as String).toList();
  }

  /// 取出未读成就并清空（用于个人成就页飞币动画）。
  List<EchoAchievementUnlock> takeUnreadUnlocks() {
    final keys = List<String>.from(_unreadUnlockKeys);
    if (keys.isEmpty) return const [];
    _box?.put(_unreadUnlocksKey, <String>[]);
    notifyListeners();
    return keys.map(_unlockFromKey).whereType<EchoAchievementUnlock>().toList();
  }

  Future<void> grantCoins(int amount) async {
    if (amount <= 0) return;
    await _addCoins(amount);
    notifyListeners();
  }

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    await _migrateFromCollectiblesIfNeeded();
    _ready = true;
    await syncAchievements();
    notifyListeners();
  }

  Set<String> get unlockedShopIds {
    final raw = _box?.get(_unlocksKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e as String).toSet();
  }

  Map<String, int> get _claimedTiers {
    final raw = _box?.get(_claimedKey) as Map<dynamic, dynamic>?;
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k as String, v as int));
  }

  int claimedTierLevel(EchoAchievementId id) =>
      _claimedTiers[id.name] ?? 0;

  bool isWallUnlocked(PhotoWallMaterial material) {
    if (PhotoWallMaterial.basic.contains(material) ||
        material == PhotoWallMaterial.custom) {
      return true;
    }
    if (EchoPlusService.instance.isActive) return true;
    for (final item in EchoShopCatalog.all) {
      if (item.wallMaterial == material &&
          unlockedShopIds.contains(item.id)) {
        return true;
      }
    }
    return false;
  }

  bool isStationeryUnlocked(String stationeryId) {
    if (stationeryId == DiaryStationeries.plain.id) return true;
    if (EchoPlusService.instance.isActive) return true;
    for (final item in EchoShopCatalog.all) {
      if (item.stationeryId == stationeryId &&
          unlockedShopIds.contains(item.id)) {
        return true;
      }
    }
    return false;
  }

  bool isShopItemOwned(EchoShopItem item) {
    if (item.isConsumable) return false;
    return unlockedShopIds.contains(item.id);
  }

  bool canAfford(EchoShopItem item) => coins >= item.price;

  bool canAffordCoins(int amount) => coins >= amount;

  Future<bool> spendCoins(int amount) async {
    if (_box == null || amount <= 0 || coins < amount) return false;
    await _addCoins(-amount);
    notifyListeners();
    return true;
  }

  int progressFor(EchoAchievementDef def) => switch (def.id) {
        EchoAchievementId.diaryDays => _uniqueDiaryDays,
        EchoAchievementId.writingStreak => EchoTreeService.instance.writingStreak,
        EchoAchievementId.totalEntries => DiaryService.instance.diaries.length,
        EchoAchievementId.todosDone => _todosCompletedTotal,
        EchoAchievementId.todoStreak => todoCompletionStreak,
        EchoAchievementId.futureLetters => FutureLetterService.instance.items.length,
        EchoAchievementId.driftReplies => _driftReplies,
        EchoAchievementId.lifeWater => EchoTreeService.instance.lifeWater,
        EchoAchievementId.photosPinned => _photoCount,
        EchoAchievementId.moodDays => _moodDayCount,
        EchoAchievementId.importantMarks =>
          ImportantDayService.instance.items.length,
        EchoAchievementId.treeStage => EchoTreeService.instance.growth.stage,
        EchoAchievementId.weekRhythm => _weekRhythmCount,
        EchoAchievementId.nightWriter => _entriesAfterHour(22),
        EchoAchievementId.morningWriter => _entriesBeforeHour(8),
      };

  int tierReached(EchoAchievementDef def) {
    final value = progressFor(def);
    var reached = 0;
    for (var i = 0; i < def.tiers.length; i++) {
      if (value >= def.tiers[i].threshold) reached = i + 1;
    }
    return reached;
  }

  /// 完成待办后更新连续天数并同步成就。
  Future<void> onTodoCompleted([DateTime? now]) async {
    if (_box == null) return;
    final day = _dateOnly(now ?? DateTime.now());
    final days = _todoCompletionDays..add(day);
    await _box!.put(
      _todoDaysKey,
      days.map((d) => d.toIso8601String()).toList(),
    );
    await syncAchievements(recordFeedback: true);
  }

  Future<void> onDriftReply() async {
    if (_box == null) return;
    final count = _driftReplies + 1;
    await _box!.put(_driftRepliesKey, count);
    await syncAchievements(recordFeedback: true);
  }

  Future<void> onDiaryActivity() async =>
      syncAchievements(recordFeedback: true);

  Future<void> onFutureLetterSealed() async =>
      syncAchievements(recordFeedback: true);

  Future<void> onTreeActivity() async =>
      syncAchievements(recordFeedback: true);

  Future<List<EchoAchievementUnlock>> syncAchievements({
    bool recordFeedback = false,
  }) async {
    if (_box == null) return [];
    final claimed = Map<String, int>.from(_claimedTiers);
    final unlocks = <EchoAchievementUnlock>[];

    for (final def in EchoAchievements.all) {
      final reached = tierReached(def);
      final already = claimed[def.storageKey] ?? 0;
      // 已领取档位永不回退：删除日记等导致进度下降时不会重复发奖。
      if (reached < already) continue;
      for (var tier = already; tier < reached; tier++) {
        final reward = def.tiers[tier].coinReward;
        await _addCoins(reward);
        claimed[def.storageKey] = tier + 1;
        final unlock = EchoAchievementUnlock(
          achievement: def,
          tierIndex: tier,
          coins: reward,
        );
        unlocks.add(unlock);
      }
    }

    await _box!.put(_claimedKey, claimed);
    if (unlocks.isNotEmpty) {
      if (recordFeedback) {
        await _markUnread(unlocks);
      }
      notifyListeners();
    }
    return unlocks;
  }

  Future<void> _markUnread(List<EchoAchievementUnlock> unlocks) async {
    if (_box == null || unlocks.isEmpty) return;
    final keys = List<String>.from(_unreadUnlockKeys);
    var changed = false;
    for (final unlock in unlocks) {
      final key = _unlockKey(unlock);
      if (!keys.contains(key)) {
        keys.add(key);
        changed = true;
      }
    }
    if (changed) {
      await _box!.put(_unreadUnlocksKey, keys);
    }
  }

  static String _unlockKey(EchoAchievementUnlock unlock) =>
      '${unlock.achievement.id.name}:${unlock.tierIndex}';

  static EchoAchievementUnlock? _unlockFromKey(String key) {
    final parts = key.split(':');
    if (parts.length != 2) return null;
    final tierIndex = int.tryParse(parts[1]);
    if (tierIndex == null) return null;
    try {
      final id = EchoAchievementId.values.byName(parts[0]);
      final def = EchoAchievements.byId(id);
      if (tierIndex < 0 || tierIndex >= def.tiers.length) return null;
      return EchoAchievementUnlock(
        achievement: def,
        tierIndex: tierIndex,
        coins: def.tiers[tierIndex].coinReward,
      );
    } catch (_) {
      return null;
    }
  }

  Future<EchoPurchaseResult> purchase(EchoShopItem item) async {
    if (_box == null) {
      return EchoPurchaseResult.failed(tr('尚未就绪', 'Not ready yet'));
    }
    if (!item.isConsumable && isShopItemOwned(item)) {
      return EchoPurchaseResult.failed(tr('已拥有', 'Already owned'));
    }
    if (coins < item.price) {
      return EchoPurchaseResult.failed(tr('回响币不足', 'Not enough Echo coins'));
    }

    await _addCoins(-item.price);

    switch (item.kind) {
      case EchoShopItemKind.storedDew:
      case EchoShopItemKind.energyBubble:
        await EchoTreeService.instance.spawnShopBubble(item.dewGrams!);
      case EchoShopItemKind.wallSkin:
      case EchoShopItemKind.stationerySkin:
        final unlocks = {...unlockedShopIds, item.id};
        await _box!.put(_unlocksKey, unlocks.toList());
    }

    notifyListeners();
    return EchoPurchaseResult.success(item);
  }

  int get todoCompletionStreak => _streakEndingOn(DateTime.now());

  Set<DateTime> get _todoCompletionDays {
    final raw = _box?.get(_todoDaysKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => _dateOnly(DateTime.parse(e as String))).toSet();
  }

  int get _driftReplies => _box?.get(_driftRepliesKey) as int? ?? 0;

  int get _uniqueDiaryDays {
    final days = <DateTime>{};
    for (final diary in DiaryService.instance.diaries) {
      days.add(_dateOnly(diary.createdAt));
    }
    return days.length;
  }

  int get _photoCount {
    var count = 0;
    for (final diary in DiaryService.instance.diaries) {
      count += diary.images.length;
    }
    return count;
  }

  int get _moodDayCount {
    final days = <DateTime>{};
    for (final diary in DiaryService.instance.diaries) {
      if (diary.moodWeather != null && diary.moodWeather!.trim().isNotEmpty) {
        days.add(_dateOnly(diary.createdAt));
      }
    }
    return days.length;
  }

  int get _todosCompletedTotal {
    final now = DateTime.now();
    return TodoService.instance.completedItems(now).length;
  }

  int get _weekRhythmCount {
    final weekMap = <String, int>{};
    for (final diary in DiaryService.instance.diaries) {
      final d = _dateOnly(diary.createdAt);
      final weekStart = d.subtract(Duration(days: d.weekday - 1));
      final key = '${weekStart.year}-${weekStart.month}-${weekStart.day}';
      weekMap[key] = (weekMap[key] ?? 0) + 1;
    }
    return weekMap.values.where((c) => c >= 3).length;
  }

  int _entriesAfterHour(int hour) {
    var count = 0;
    for (final diary in DiaryService.instance.diaries) {
      if (diary.createdAt.hour >= hour) count++;
    }
    return count;
  }

  int _entriesBeforeHour(int hour) {
    var count = 0;
    for (final diary in DiaryService.instance.diaries) {
      if (diary.createdAt.hour < hour) count++;
    }
    return count;
  }

  Future<void> _addCoins(int delta) async {
    final next = (coins + delta).clamp(0, 999999);
    await _box?.put(_coinsKey, next);
  }

  Future<void> _migrateFromCollectiblesIfNeeded() async {
    if (_box == null) return;
    if (_box!.get(_migratedKey) == true) return;

    try {
      final legacy = await Hive.openBox<dynamic>('echo_collectibles');
      final raw = legacy.get('items') as List<dynamic>?;
      if (raw != null && raw.isNotEmpty) {
        await _addCoins(raw.length * 25);
      }
      final tiers = legacy.get('granted_flower_tiers') as List<dynamic>?;
      if (tiers != null) {
        await _addCoins(tiers.length * 15);
      }
    } catch (_) {}

    await _box!.put(_migratedKey, true);
  }

  int _streakEndingOn(DateTime day) {
    final dates = _todoCompletionDays;
    if (dates.isEmpty) return 0;
    var cursor = _dateOnly(day);
    var streak = 0;
    while (dates.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);
}

class EchoPurchaseResult {
  const EchoPurchaseResult._({this.item, this.error});

  final EchoShopItem? item;
  final String? error;

  bool get ok => item != null;

  factory EchoPurchaseResult.success(EchoShopItem item) =>
      EchoPurchaseResult._(item: item);

  factory EchoPurchaseResult.failed(String message) =>
      EchoPurchaseResult._(error: message);
}
