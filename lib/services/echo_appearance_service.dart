import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/echo_appearance_preset.dart';
import '../theme/echo_colors.dart';

class EchoAppearanceService extends ChangeNotifier {
  EchoAppearanceService._();

  static final EchoAppearanceService instance = EchoAppearanceService._();

  static const _boxName = 'echo_appearance';
  static const _presetKey = 'preset_id';

  Box<dynamic>? _box;
  bool _ready = false;
  EchoAppearancePreset _preset = EchoAppearancePresets.warmPaper;

  bool get isReady => _ready;
  EchoAppearancePreset get preset => _preset;
  String get presetName => _preset.localizedName;

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _preset = EchoAppearancePresets.byId(_box?.get(_presetKey) as String?);
    EchoColors.applyPreset(_preset);
    _ready = true;
    notifyListeners();
  }

  Future<void> setPreset(EchoAppearancePreset value) async {
    if (_preset.id == value.id) return;
    _preset = value;
    await _box?.put(_presetKey, value.id);
    EchoColors.applyPreset(value);
    notifyListeners();
  }
}
