import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/echo_collectible.dart';

/// 情绪小铺 / 个人仓库：收集纪念物。
class EchoCollectibleService extends ChangeNotifier {
  EchoCollectibleService._();

  static final EchoCollectibleService instance = EchoCollectibleService._();

  static const _boxName = 'echo_collectibles';
  static const _itemsKey = 'items';
  static const _todoDaysKey = 'todo_completion_days';
  static const _flowerTiersKey = 'granted_flower_tiers';

  static const flowerTiers = [3, 7, 14];

  Box<dynamic>? _box;
  bool _ready = false;
  EchoCollectibleItem? _lastEarned;

  bool get isReady => _ready;

  Set<int> get grantedFlowerTiers => _grantedFlowerTiers;

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _ready = true;
    notifyListeners();
  }

  List<EchoCollectibleItem> get items {
    final raw = _box?.get(_itemsKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .map(
          (e) => EchoCollectibleItem.fromMap(
            Map<dynamic, dynamic>.from(e as Map),
          ),
        )
        .toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  }

  int countOf(EchoCollectibleKind kind) =>
      items.where((item) => item.kind == kind).length;

  int get todoCompletionStreak => _streakEndingOn(DateTime.now());

  Set<int> get _grantedFlowerTiers {
    final raw = _box?.get(_flowerTiersKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw.map((e) => e as int).toSet();
  }

  Set<DateTime> get _todoCompletionDays {
    final raw = _box?.get(_todoDaysKey) as List<dynamic>?;
    if (raw == null) return {};
    return raw
        .map((e) => DateTime.parse(e as String))
        .map(_dateOnly)
        .toSet();
  }

  /// 完成待办后调用：更新连续天数，并在 3 / 7 / 14 天发放专注之花。
  Future<EchoCollectibleItem?> onTodoCompleted([DateTime? now]) async {
    if (_box == null) return null;
    final day = _dateOnly(now ?? DateTime.now());
    final days = _todoCompletionDays..add(day);
    await _box!.put(
      _todoDaysKey,
      days.map((d) => d.toIso8601String()).toList(),
    );

    final streak = _streakEndingOn(day);
    final tiers = _grantedFlowerTiers;

    for (final tier in flowerTiers) {
      if (streak >= tier && !tiers.contains(tier)) {
        tiers.add(tier);
        await _box!.put(_flowerTiersKey, tiers.toList());
        return _grant(
          kind: EchoCollectibleKind.focusFlower,
          sourceId: 'streak_$tier',
          streakDays: tier,
        );
      }
    }

    notifyListeners();
    return null;
  }

  EchoCollectibleItem? takeLastEarned() {
    final item = _lastEarned;
    _lastEarned = null;
    return item;
  }

  Future<EchoCollectibleItem?> grantTimeSeed(String letterId) async {
    return _grant(
      kind: EchoCollectibleKind.timeSeed,
      sourceId: letterId,
    );
  }

  Future<EchoCollectibleItem?> grantResonanceShell(String diaryId) async {
    return _grant(
      kind: EchoCollectibleKind.resonanceShell,
      sourceId: diaryId,
    );
  }

  Future<EchoCollectibleItem?> _grant({
    required EchoCollectibleKind kind,
    String? sourceId,
    int? streakDays,
  }) async {
    if (_box == null) return null;

    if (sourceId != null) {
      final exists = items.any(
        (item) => item.kind == kind && item.sourceId == sourceId,
      );
      if (exists) return null;
    }

    final item = EchoCollectibleItem(
      id: '${kind.storageName}_${DateTime.now().microsecondsSinceEpoch}',
      kind: kind,
      earnedAt: DateTime.now(),
      sourceId: sourceId,
      streakDays: streakDays,
    );

    final next = [...items, item];
    await _box!.put(_itemsKey, next.map((e) => e.toMap()).toList());
    _lastEarned = item;
    notifyListeners();
    return item;
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
