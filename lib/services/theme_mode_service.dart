import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../theme/echo_colors.dart';

/// 仅保留日间默认与夜间模式（已移除「跟随系统」「浅色」）。
enum EchoThemeMode { day, dark }

extension EchoThemeModeLabel on EchoThemeMode {
  String get label => switch (this) {
        EchoThemeMode.day => '未开启',
        EchoThemeMode.dark => '已开启',
      };
}

/// 应用明暗模式（与纸色预设独立）。
class ThemeModeService extends ChangeNotifier {
  ThemeModeService._();

  static final ThemeModeService instance = ThemeModeService._();

  static const _boxName = 'echo_theme_mode';
  static const _key = 'mode';

  Box<dynamic>? _box;
  EchoThemeMode _mode = EchoThemeMode.day;

  EchoThemeMode get mode => _mode;

  bool get isNightMode => _mode == EchoThemeMode.dark;

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    final raw = _box?.get(_key) as String?;
    _mode = _parseStored(raw);
    _syncEchoColorsBrightness();
    notifyListeners();
  }

  EchoThemeMode _parseStored(String? raw) {
    if (raw == 'dark') return EchoThemeMode.dark;
    // 旧版 system / light 统一回落为日间默认
    return EchoThemeMode.day;
  }

  Future<void> setMode(EchoThemeMode value) async {
    if (_mode == value) return;
    _mode = value;
    await _box?.put(_key, value.name);
    _syncEchoColorsBrightness();
    notifyListeners();
  }

  Future<void> setNightMode(bool enabled) async {
    await setMode(enabled ? EchoThemeMode.dark : EchoThemeMode.day);
  }

  void _syncEchoColorsBrightness() {
    EchoColors.setThemeAppearance(isDark: _mode == EchoThemeMode.dark);
  }

  Brightness resolveBrightness(BuildContext context) {
    return _mode == EchoThemeMode.dark
        ? Brightness.dark
        : Brightness.light;
  }

  bool isDark(BuildContext context) => _mode == EchoThemeMode.dark;
}
