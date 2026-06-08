import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/echo_check_in.dart';
import 'echo_reward_service.dart';
import 'echo_tree_service.dart';

/// 每日签到：自然月日历；今日签到 + 每日一次补签。
class EchoCheckInService extends ChangeNotifier {
  EchoCheckInService._();

  static final EchoCheckInService instance = EchoCheckInService._();

  static const _boxName = 'echo_check_in';
  static const _monthKey = 'active_month';
  static const _checkedDaysKey = 'checked_days';
  static const _makeupUsedDateKey = 'makeup_used_date';

  Box<dynamic>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  DateTime get _today => _dateOnly(DateTime.now());

  String get activeMonthKey => _monthKeyFor(_today);

  List<int> get checkedDaysThisMonth {
    _ensureActiveMonth(_today);
    final raw = _box?.get(_checkedDaysKey) as List<dynamic>?;
    if (raw == null) return [];
    return raw.map((e) => e as int).toList()..sort();
  }

  int get checkedCountThisMonth => checkedDaysThisMonth.length;

  bool get canCheckInToday => !isDayChecked(_today.day);

  bool get makeupUsedToday {
    final raw = _box?.get(_makeupUsedDateKey) as String?;
    if (raw == null) return false;
    return _isSameDay(DateTime.parse(raw), _today);
  }

  List<int> get missedDaysThisMonth {
    _ensureActiveMonth(_today);
    final checked = checkedDaysThisMonth.toSet();
    return [
      for (var d = 1; d < _today.day; d++)
        if (!checked.contains(d)) d,
    ];
  }

  bool get canMakeUpToday =>
      !makeupUsedToday && missedDaysThisMonth.isNotEmpty;

  EchoCheckInReward get todayReward =>
      EchoCheckInRewards.forDate(_today);

  EchoCheckInReward rewardForDay(int day, [DateTime? month]) {
    final ref = month ?? _today;
    return EchoCheckInRewards.forDate(DateTime(ref.year, ref.month, day));
  }

  bool isDayChecked(int day) {
    _ensureActiveMonth(_today);
    return checkedDaysThisMonth.contains(day);
  }

  bool canClaimDay(int day) {
    _ensureActiveMonth(_today);
    if (isDayChecked(day)) return false;
    if (day > _today.day) return false;
    if (day == _today.day) return true;
    return !makeupUsedToday;
  }

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _ensureActiveMonth(_today);
    _ready = true;
    notifyListeners();
  }

  Future<EchoCheckInReward?> checkInToday() => _claimDay(_today.day);

  Future<EchoCheckInReward?> makeUpDay(int day) async {
    if (day >= _today.day || isDayChecked(day) || makeupUsedToday) {
      return null;
    }
    return _claimDay(day, isMakeup: true);
  }

  Future<EchoCheckInReward?> _claimDay(int day, {bool isMakeup = false}) async {
    if (_box == null) return null;

    final claimDate = DateTime(_today.year, _today.month, day);
    _ensureActiveMonth(claimDate);

    if (checkedDaysThisMonth.contains(day)) return null;
    if (day > _today.day) return null;
    if (isMakeup && (day == _today.day || makeupUsedToday)) return null;

    final reward = EchoCheckInRewards.forDate(claimDate);
    final dayKey = '${_monthKeyFor(claimDate)}-$day';

    if (reward.coins > 0) {
      await EchoRewardService.instance.grantCoins(reward.coins);
    }
    if (reward.bubbleGrams > 0) {
      await EchoTreeService.instance.spawnCheckInBubble(
        reward.bubbleGrams,
        dayKey: dayKey,
      );
    }

    final days = List<int>.from(checkedDaysThisMonth)..add(day);
    days.sort();
    await _box!.put(_checkedDaysKey, days);

    if (isMakeup) {
      await _box!.put(_makeupUsedDateKey, _today.toIso8601String());
    }

    notifyListeners();
    return reward;
  }

  void _ensureActiveMonth(DateTime date) {
    if (_box == null) return;
    final key = _monthKeyFor(date);
    final stored = _box!.get(_monthKey) as String?;
    if (stored != key) {
      _box!.put(_monthKey, key);
      _box!.put(_checkedDaysKey, <int>[]);
      _box!.delete(_makeupUsedDateKey);
    }
  }

  static String _monthKeyFor(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  static DateTime _dateOnly(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
