import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/diary_stationery.dart';
import 'echo_reward_service.dart';

class DiaryStationeryService extends ChangeNotifier {
  DiaryStationeryService._();

  static final DiaryStationeryService instance = DiaryStationeryService._();

  static const _boxName = 'echo_diary_stationery';
  static const _presetKey = 'stationery_id';

  Box<dynamic>? _box;
  bool _ready = false;
  DiaryStationery _current = DiaryStationeries.plain;

  bool get isReady => _ready;
  DiaryStationery get current => _current;
  String get currentName => _current.localizedName;

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _current = DiaryStationeries.byId(_box?.get(_presetKey) as String?);
    _ready = true;
    notifyListeners();
  }

  Future<void> setStationery(DiaryStationery value) async {
    if (_current.id == value.id) return;
    if (!EchoRewardService.instance.isStationeryUnlocked(value.id)) return;
    _current = value;
    await _box?.put(_presetKey, value.id);
    notifyListeners();
  }
}
