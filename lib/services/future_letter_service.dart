import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/future_letter.dart';
import '../utils/diary_format.dart';
import '../utils/future_letter_copy.dart';
import 'future_letter_notification_service.dart';
import 'echo_reward_service.dart';
import 'echo_tree_service.dart';

class FutureLetterService extends ChangeNotifier {
  FutureLetterService._();

  static final FutureLetterService instance = FutureLetterService._();

  static const _boxName = 'echo_future_letters';
  static const _remindersKey = '__reminders_enabled__';

  Box<dynamic>? _box;
  bool _ready = false;
  List<FutureLetter> _items = [];

  bool get isReady => _ready;

  bool get remindersEnabled =>
      _box?.get(_remindersKey, defaultValue: true) as bool? ?? true;

  List<FutureLetter> get items => List.unmodifiable(_items);

  List<FutureLetter> get dueItems {
    final now = DateTime.now();
    return _items.where((l) => l.isDue(now)).toList()
      ..sort((a, b) => a.deliverAt.compareTo(b.deliverAt));
  }

  List<FutureLetter> get pendingItems {
    final now = DateTime.now();
    return _items.where((l) => l.isPending(now)).toList()
      ..sort((a, b) => a.deliverAt.compareTo(b.deliverAt));
  }

  List<FutureLetter> get openedItems {
    return _items.where((l) => l.isOpened).toList()
      ..sort((a, b) => b.openedAt!.compareTo(a.openedAt!));
  }

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _items = _box!.keys
        .where((k) => k is String && !k.startsWith('__'))
        .map(
          (k) => FutureLetter.fromJson(
            Map<dynamic, dynamic>.from(_box!.get(k) as Map),
          ),
        )
        .toList();
    _ready = true;
    notifyListeners();
  }

  FutureLetter? dueTodayForHome([DateTime? now]) {
    final due = dueItems;
    if (due.isEmpty) return null;
    return due.first;
  }

  String? whisperForHome([DateTime? now]) {
    if (dueTodayForHome(now) == null) return null;
    return FutureLetterCopy.homeWhisper(dueTodayForHome(now)!);
  }

  Future<FutureLetter> create({
    required String content,
    required DateTime deliverAt,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('信件内容不能为空');
    }
    if (trimmed.length > FutureLetter.maxContentLength) {
      throw ArgumentError('信件过长');
    }

    final today = DateTime.now();
    final deliverDay = DateTime(
      deliverAt.year,
      deliverAt.month,
      deliverAt.day,
    );
    final todayDay = DateTime(today.year, today.month, today.day);
    if (!deliverDay.isAfter(todayDay)) {
      throw ArgumentError('送达日须晚于今天');
    }

    final letter = FutureLetter(
      id: _newId(),
      content: trimmed,
      createdAt: today,
      deliverAt: deliverDay,
    );
    await _save(letter);
    await FutureLetterNotificationService.instance.syncOne(letter);
    await EchoRewardService.instance.onFutureLetterSealed();
    notifyListeners();
    return letter;
  }

  Future<void> open(String id) async {
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) return;
    final letter = _items[index];
    if (letter.isOpened || !letter.isDue()) return;
    await _markOpened(letter);
  }

  /// 消耗回响币提前拆信。
  Future<bool> openEarly(String id) async {
    final index = _items.indexWhere((l) => l.id == id);
    if (index < 0) return false;
    final letter = _items[index];
    if (letter.isOpened || letter.isDue()) return false;

    final cost = letter.earlyOpenCoinCost();
    final paid = await EchoRewardService.instance.spendCoins(cost);
    if (!paid) return false;

    await _markOpened(letter);
    return true;
  }

  Future<void> _markOpened(FutureLetter letter) async {
    final opened = letter.copyWith(openedAt: DateTime.now());
    await _save(opened);
    await FutureLetterNotificationService.instance.cancel(letter.id);
    await EchoTreeService.instance.grantWaterForFutureLetter(opened);
    notifyListeners();
  }

  Future<void> delete(String id) async {
    _items.removeWhere((l) => l.id == id);
    await _box?.delete(id);
    await FutureLetterNotificationService.instance.cancel(id);
    notifyListeners();
  }

  Future<void> setRemindersEnabled(bool value) async {
    await _box?.put(_remindersKey, value);
    notifyListeners();
    if (value) {
      await FutureLetterNotificationService.instance.syncAll();
    } else {
      await FutureLetterNotificationService.instance.cancelAll();
    }
  }

  Future<void> _save(FutureLetter letter) async {
    final index = _items.indexWhere((l) => l.id == letter.id);
    if (index >= 0) {
      _items[index] = letter;
    } else {
      _items.add(letter);
    }
    await _box?.put(letter.id, letter.toJson());
  }

  String _newId() => 'fl_${DateTime.now().microsecondsSinceEpoch}';
}
