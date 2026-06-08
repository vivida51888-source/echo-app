import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/localized.dart';
import '../models/diary.dart';
import '../models/echo_tree_growth.dart';
import '../models/echo_water_bubble.dart';
import '../models/future_letter.dart';
import '../utils/diary_format.dart';
import '../utils/echo_bubble_layout.dart';
import '../utils/todo_schedule.dart';
import 'diary_service.dart';
import 'echo_reward_service.dart';
import 'todo_service.dart';

/// 回响之树：写回响得雨露泡 → 收集 → 浇水成长。
class EchoTreeService extends ChangeNotifier {
  EchoTreeService._();

  static final EchoTreeService instance = EchoTreeService._();

  static const _boxName = 'echo_tree';
  static const _storedWaterKey = 'stored_water';
  static const _lifeWaterKey = 'life_water';
  static const _bubblesKey = 'pending_bubbles';
  static const _rewardedKey = 'rewarded_diary_ids';
  static const _rewardedRecordDaysKey = 'rewarded_record_days';
  static const _streakEligibleDaysKey = 'streak_eligible_days';
  static const _rewardedBonusesKey = 'rewarded_bonus_keys';

  Box<dynamic>? _box;
  bool _ready = false;
  final List<EchoWaterBubble> _shatterQueue = [];

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _ready = true;
    await _pruneExpiredBubbles(persist: true, queueForShatter: true);
    await _migrateBubbleRulesIfNeeded();
    await _normalizeStoredBubbles();
    DiaryService.instance.addListener(_onDiariesChanged);
    notifyListeners();
  }

  void _onDiariesChanged() => notifyListeners();

  int get storedWater => _box?.get(_storedWaterKey) as int? ?? 0;

  int get lifeWater => _box?.get(_lifeWaterKey) as int? ?? 0;

  EchoTreeGrowth get growth => EchoTreeGrowthModel.growthFor(lifeWater);

  int get growthStage => growth.stage;

  int get visualStage => growth.visualStage;

  List<EchoWaterBubble> get pendingBubbles {
    final raw = _box?.get(_bubblesKey) as List<dynamic>?;
    if (raw == null) return [];
    final now = DateTime.now();
    final valid = raw
        .map((e) => EchoWaterBubble.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((b) => now.difference(b.createdAt) < EchoTreeGrowthModel.bubbleMaxAge)
        .toList();
    return _capPending(valid);
  }

  /// 仅按 2 日有效期保留，不限制份数。
  static List<EchoWaterBubble> _capPending(List<EchoWaterBubble> bubbles) {
    final sorted = List<EchoWaterBubble>.from(bubbles)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  Future<void> _normalizeStoredBubbles() async {
    if (_box == null) return;
    final raw = _box!.get(_bubblesKey) as List<dynamic>?;
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now();
    final valid = raw
        .map((e) => EchoWaterBubble.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .where((b) => now.difference(b.createdAt) < EchoTreeGrowthModel.bubbleMaxAge)
        .toList();
    final capped = _capPending(valid);
    if (capped.length != valid.length) {
      await _saveBubbles(capped);
    }
  }

  int get pendingWaterTotal =>
      pendingBubbles.fold(0, (sum, b) => sum + b.grams);

  bool get hasPendingBubbles => pendingBubbles.isNotEmpty;

  bool get hasShatterQueue => _shatterQueue.isNotEmpty;

  /// 取出待播放落地破碎动画的过期雨露（内存队列，一次性消费）。
  List<EchoWaterBubble> takeShatterQueue() {
    final queued = List<EchoWaterBubble>.from(_shatterQueue);
    _shatterQueue.clear();
    return queued;
  }

  int get writingStreak => _streakEndingOn(DateTime.now());

  Set<String> get _rewardedDiaryIds {
    final raw = _box?.get(_rewardedKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Set<DateTime> get _diaryDates {
    final set = <DateTime>{};
    for (final diary in DiaryService.instance.diaries) {
      set.add(_dateOnly(diary.createdAt));
    }
    return set;
  }

  Set<DateTime> get _rewardedRecordDays => _readDaySet(_rewardedRecordDaysKey);

  Set<DateTime> get _streakEligibleDays => _readDaySet(_streakEligibleDaysKey);

  Set<String> get _rewardedBonusKeys {
    final raw = _box?.get(_rewardedBonusesKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e.toString()).toSet();
  }

  Set<DateTime> _readDaySet(String key) {
    final raw = _box?.get(key) as List<dynamic>?;
    if (raw == null) return {};
    final set = <DateTime>{};
    for (final value in raw) {
      try {
        set.add(_dateOnly(DateTime.parse(value as String)));
      } catch (_) {}
    }
    return set;
  }

  Future<void> _writeDaySet(String key, Set<DateTime> days) async {
    final sorted = days.toList()..sort((a, b) => a.compareTo(b));
    await _box?.put(
      key,
      sorted.map((d) => _dateOnly(d).toIso8601String()).toList(),
    );
  }

  Future<void> _migrateBubbleRulesIfNeeded() async {
    if (_box == null) return;

    if (!_box!.containsKey(_streakEligibleDaysKey)) {
      await _writeDaySet(_streakEligibleDaysKey, _diaryDates);
    }
    if (!_box!.containsKey(_rewardedRecordDaysKey)) {
      final days = <DateTime>{};
      for (final id in _rewardedDiaryIds) {
        final diary = DiaryService.instance.getDiaryById(id);
        if (diary != null) {
          days.add(_dateOnly(diary.createdAt));
        }
      }
      await _writeDaySet(_rewardedRecordDaysKey, days);
    }
  }

  bool _isBackfill(Diary diary, DateTime savedAt) {
    final recorded = _dateOnly(diary.createdAt);
    final saved = _dateOnly(savedAt);
    return recorded.isBefore(saved);
  }

  int _diaryCountOnDay(DateTime day, {String? excludeId}) {
    final target = _dateOnly(day);
    var count = 0;
    for (final diary in DiaryService.instance.diaries) {
      if (excludeId != null && diary.id == excludeId) continue;
      if (_dateOnly(diary.createdAt) == target) count++;
    }
    return count;
  }

  Future<void> grantWaterForFutureLetter(FutureLetter letter) async {
    if (_box == null) return;
    await _grantBonusBubble(
      rewardKey: 'future_letter_${letter.id}',
      grams: EchoTreeBubbleRules.futureLetterGrams,
      layoutSeed: letter.id.hashCode,
    );
  }

  Future<void> grantWaterForDriftReply(String diaryId) async {
    if (_box == null) return;
    await _grantBonusBubble(
      rewardKey: 'drift_reply_$diaryId',
      grams: EchoTreeBubbleRules.driftReplyGrams,
      layoutSeed: diaryId.hashCode,
    );
  }

  Future<void> checkDailyTodoBonus([DateTime? now]) async {
    if (_box == null) return;
    final day = _dateOnly(now ?? DateTime.now());
    if (!allTodayTodosCompleted(day)) return;

    await _grantBonusBubble(
      rewardKey: 'todo_all_${day.toIso8601String()}',
      grams: EchoTreeBubbleRules.dailyTodoGrams,
      layoutSeed: day.hashCode,
    );
  }

  bool allTodayTodosCompleted(DateTime day) {
    final now = day;
    final active = TodoService.instance.activeItems(now);
    final grouped = TodoSchedule.groupActive(active, now);
    final todayTodos = [
      ...grouped[TodoTimeGroup.expired]!,
      ...grouped[TodoTimeGroup.today]!,
    ];
    if (todayTodos.isEmpty) return false;
    return todayTodos.every((todo) => todo.isDoneForDisplay(now));
  }

  Future<void> _grantBonusBubble({
    required String rewardKey,
    required int grams,
    required int layoutSeed,
    int streakDays = 1,
  }) async {
    if (_box == null) return;
    if (_rewardedBonusKeys.contains(rewardKey)) return;

    await _pruneExpiredBubbles(persist: true);

    final existing = List<EchoWaterBubble>.from(pendingBubbles);
    final anchor = EchoBubbleLayout.pickAnchor(
      seed: layoutSeed,
      existing: existing,
    );
    final bubble = EchoWaterBubble(
      id: '${rewardKey}_${DateTime.now().microsecondsSinceEpoch}',
      diaryId: rewardKey,
      grams: grams,
      createdAt: DateTime.now(),
      layoutSeed: layoutSeed,
      streakDays: streakDays,
      anchorX: anchor.x,
      anchorY: anchor.y,
    );

    existing.add(bubble);
    await _saveBubbles(existing);

    final bonuses = _rewardedBonusKeys..add(rewardKey);
    await _box!.put(_rewardedBonusesKey, bonuses.toList());
    notifyListeners();
  }

  Future<void> grantWaterForDiary(
    Diary diary, {
    required bool isNewSave,
    required DateTime savedAt,
  }) async {
    if (_box == null) return;
    if (!isNewSave) return;
    if (_rewardedDiaryIds.contains(diary.id)) return;

    await _pruneExpiredBubbles(persist: true);

    if (_isBackfill(diary, savedAt)) {
      await _grantBackfillWater(diary);
      return;
    }

    final recordDay = _dateOnly(diary.createdAt);
    if (_rewardedRecordDays.contains(recordDay)) {
      await _markRewarded(diary.id);
      return;
    }
    if (_diaryCountOnDay(recordDay, excludeId: diary.id) > 0) {
      await _markRewarded(diary.id);
      return;
    }

    final streakDays = _streakEligibleDays;
    streakDays.add(recordDay);
    await _writeDaySet(_streakEligibleDaysKey, streakDays);

    final streak = _streakEndingOn(recordDay);
    final existing = List<EchoWaterBubble>.from(pendingBubbles);
    final anchor = EchoBubbleLayout.pickAnchor(
      seed: diary.id.hashCode,
      existing: existing,
    );
    final bubble = EchoWaterBubble(
      id: '${diary.id}_${DateTime.now().microsecondsSinceEpoch}',
      diaryId: diary.id,
      grams: _waterForDiary(streak: streak),
      createdAt: DateTime.now(),
      layoutSeed: diary.id.hashCode,
      streakDays: streak,
      anchorX: anchor.x,
      anchorY: anchor.y,
    );

    existing.add(bubble);
    await _saveBubbles(existing);

    final rewardedDays = _rewardedRecordDays..add(recordDay);
    await _writeDaySet(_rewardedRecordDaysKey, rewardedDays);
    await _markRewarded(diary.id);
    notifyListeners();
  }

  Future<void> _grantBackfillWater(Diary diary) async {
    await _markRewarded(diary.id);

    final existing = List<EchoWaterBubble>.from(pendingBubbles);
    final hasBackfillBubble = existing.any((b) => b.isBackfillPool);
    if (hasBackfillBubble) {
      notifyListeners();
      return;
    }

    final anchor = EchoBubbleLayout.pickAnchor(
      seed: EchoTreeBubbleRules.backfillPoolDiaryId.hashCode,
      existing: existing,
    );
    final bubble = EchoWaterBubble(
      id: 'backfill_${DateTime.now().microsecondsSinceEpoch}',
      diaryId: EchoTreeBubbleRules.backfillPoolDiaryId,
      grams: EchoTreeBubbleRules.backfillPoolGrams,
      createdAt: DateTime.now(),
      layoutSeed: EchoTreeBubbleRules.backfillPoolDiaryId.hashCode,
      streakDays: 1,
      anchorX: anchor.x,
      anchorY: anchor.y,
    );

    existing.add(bubble);
    await _saveBubbles(existing);
    notifyListeners();
  }

  Future<void> collectBubble(String bubbleId) async {
    await _pruneExpiredBubbles(persist: true);
    final bubbles = pendingBubbles;
    final index = bubbles.indexWhere((b) => b.id == bubbleId);
    if (index < 0) return;

    final bubble = bubbles.removeAt(index);
    await _saveBubbles(bubbles);
    await _box?.put(_storedWaterKey, storedWater + bubble.grams);
    notifyListeners();
  }

  Future<void> collectAllBubbles() async {
    await _pruneExpiredBubbles(persist: true);
    if (pendingBubbles.isEmpty) return;
    final total = pendingWaterTotal;
    await _saveBubbles([]);
    await _box?.put(_storedWaterKey, storedWater + total);
    notifyListeners();
  }

  Future<bool> waterTree() async {
    if (storedWater <= 0) return false;
    final add = storedWater;
    await _box?.put(_lifeWaterKey, lifeWater + add);
    await _box?.put(_storedWaterKey, 0);
    await EchoRewardService.instance.onTreeActivity();
    notifyListeners();
    return true;
  }

  /// 情绪小铺：直接增加待浇雨露。
  Future<void> grantShopStoredDew(int grams) async {
    if (grams <= 0) return;
    await _box?.put(_storedWaterKey, storedWater + grams);
    notifyListeners();
  }

  /// 签到奖励：每日最多一颗能量泡。
  Future<void> spawnCheckInBubble(int grams, {required String dayKey}) async {
    await _grantBonusBubble(
      rewardKey: 'checkin_$dayKey',
      grams: grams,
      layoutSeed: dayKey.hashCode,
    );
  }

  /// 情绪小铺：在树旁生成一颗能量泡。
  Future<void> spawnShopBubble(int grams) async {
    if (grams <= 0) return;
    final existing = List<EchoWaterBubble>.from(pendingBubbles);
    final anchor = EchoBubbleLayout.pickAnchor(
      seed: DateTime.now().microsecondsSinceEpoch,
      existing: existing,
    );
    final bubble = EchoWaterBubble(
      id: 'shop_${DateTime.now().microsecondsSinceEpoch}',
      diaryId: 'shop_bonus_${DateTime.now().microsecondsSinceEpoch}',
      grams: grams,
      createdAt: DateTime.now(),
      layoutSeed: DateTime.now().microsecondsSinceEpoch,
      streakDays: 1,
      anchorX: anchor.x,
      anchorY: anchor.y,
    );
    existing.add(bubble);
    await _saveBubbles(existing);
    notifyListeners();
  }

  Future<void> refreshBubbles() async {
    await _pruneExpiredBubbles(persist: true);
    notifyListeners();
  }

  int get uniqueDiaryDays => _diaryDates.length;

  int get totalEntries => DiaryService.instance.diaries.length;

  int get daysSinceLastDiary {
    final latest = DiaryService.instance.latestEntry;
    if (latest == null) return 999;
    final today = _dateOnly(DateTime.now());
    final last = _dateOnly(latest.createdAt);
    return today.difference(last).inDays;
  }

  EchoTreeWiltLevel get wiltLevel {
    final gap = daysSinceLastDiary;
    if (gap <= 1) return EchoTreeWiltLevel.none;
    if (gap <= 3) return EchoTreeWiltLevel.mild;
    return EchoTreeWiltLevel.soft;
  }

  String get statusWhisper {
    final g = growth;
    final gap = daysSinceLastDiary;

    if (hasPendingBubbles) {
      return tr('有 ${pendingBubbles.length} 滴雨露在树旁等你收集', '${pendingBubbles.length} dew drops waiting by the tree');
    }
    if (storedWater > 0) {
      return tr(
        '已收集 ${storedWater}g 雨露，点浇水让它长高',
        'Collected ${storedWater}g dew — tap to water and grow',
      );
    }

    if (lifeWater == 0 && totalEntries == 0) {
      return tr(
        '写下第一篇回响，雨露就会落在树旁',
        'Write your first echo and dew will gather by the tree',
      );
    }

    if (gap >= 4) {
      return tr('已经 $gap 天没写回响了，它在轻轻等你', '$gap days without an echo — it waits gently');
    }
    if (gap >= 2) {
      return tr('有 $gap 天没写，叶子微微耷下来了', '$gap days without writing — leaves droop a little');
    }

    final latest = DiaryService.instance.latestEntry;
    if (latest != null && DiaryFormat.isToday(latest.createdAt)) {
      if (writingStreak >= 2) {
        return tr('连续 $writingStreak 天，今天的雨露更丰沛', '$writingStreak-day streak — today\'s dew is richer');
      }
      return tr('今天写过回响了，${g.stageLabel}在慢慢长高', 'Wrote today — ${g.stageLabel} grows slowly');
    }

    if (g.companionLabel != null) {
      return tr('累计浇下 ${g.lifeWater}g 雨露，${g.companionLabel}', '${g.lifeWater}g dew poured — ${g.companionLabel}');
    }
    return tr('${g.stageLabel} · 累计 ${g.lifeWater}g 雨露', '${g.stageLabel} · ${g.lifeWater}g dew total');
  }

  String? get nextStageHint {
    final g = growth;
    final remain = g.waterToNext;
    if (remain == null) return null;
    final next = EchoTreeGrowthModel.stageLabel(g.stage + 1);
    return tr('再浇 $remain g，进入「$next」', '$remain g more to reach «$next»');
  }

  int _streakEndingOn(DateTime date) {
    final days = _streakEligibleDays;
    var streak = 0;
    var check = _dateOnly(date);
    while (days.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int _waterForDiary({required int streak}) =>
      EchoTreeBubbleRules.diaryTotalGrams(streak);

  Future<void> _pruneExpiredBubbles({
    required bool persist,
    bool queueForShatter = true,
  }) async {
    if (_box == null) return;
    final raw = _box!.get(_bubblesKey) as List<dynamic>?;
    if (raw == null) return;

    final now = DateTime.now();
    final all = raw
        .map((e) => EchoWaterBubble.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    final valid = <EchoWaterBubble>[];
    final expired = <EchoWaterBubble>[];
    for (final bubble in all) {
      if (now.difference(bubble.createdAt) < EchoTreeGrowthModel.bubbleMaxAge) {
        valid.add(bubble);
      } else {
        expired.add(bubble);
      }
    }

    if (queueForShatter && expired.isNotEmpty) {
      final known = _shatterQueue.map((b) => b.id).toSet();
      for (final bubble in expired) {
        if (!known.contains(bubble.id)) {
          _shatterQueue.add(bubble);
        }
      }
    }

    if (persist && valid.length != all.length) {
      await _saveBubbles(_capPending(valid));
    } else if (persist) {
      await _normalizeStoredBubbles();
    }
  }

  Future<void> _saveBubbles(List<EchoWaterBubble> bubbles) async {
    final capped = _capPending(bubbles);
    await _box?.put(
      _bubblesKey,
      capped.map((b) => b.toMap()).toList(),
    );
  }

  Future<void> _markRewarded(String diaryId) async {
    final set = _rewardedDiaryIds..add(diaryId);
    await _box?.put(_rewardedKey, set.toList());
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
}
