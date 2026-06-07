import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 应用界面语言（与系统语言独立配置）。
enum EchoAppLocale {
  system,
  chinese,
  english,
}

extension EchoAppLocaleLabel on EchoAppLocale {
  String label({required bool englishUi}) => switch (this) {
        EchoAppLocale.system =>
          englishUi ? 'Follow system' : '跟随系统',
        EchoAppLocale.chinese => '简体中文',
        EchoAppLocale.english => 'English',
      };

  String subtitle({required bool englishUi}) => switch (this) {
        EchoAppLocale.system => englishUi
            ? 'Uses device language when available'
            : '优先使用系统语言',
        EchoAppLocale.chinese =>
          englishUi ? 'Chinese interface' : '始终使用中文界面',
        EchoAppLocale.english =>
          englishUi ? 'English interface' : '始终使用英文界面',
      };
}

class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const _boxName = 'echo_locale';
  static const _key = 'mode';

  static const supportedLocales = [
    Locale('zh', 'CN'),
    Locale('en', 'US'),
  ];

  Box<dynamic>? _box;
  EchoAppLocale _mode = EchoAppLocale.system;

  EchoAppLocale get mode => _mode;

  bool get isEnglish => currentLocale.languageCode == 'en';

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    final raw = _box?.get(_key) as String?;
    _mode = EchoAppLocale.values.firstWhere(
      (m) => m.name == raw,
      orElse: () => EchoAppLocale.system,
    );
    notifyListeners();
  }

  Future<void> setMode(EchoAppLocale value) async {
    if (_mode == value) return;
    _mode = value;
    await _box?.put(_key, value.name);
    notifyListeners();
  }

  Locale get currentLocale => resolveLocale(_platformLocale);

  Locale resolveLocale(Locale? platformLocale) {
    return switch (_mode) {
      EchoAppLocale.chinese => const Locale('zh', 'CN'),
      EchoAppLocale.english => const Locale('en', 'US'),
      EchoAppLocale.system => _localeFromPlatform(platformLocale),
    };
  }

  Locale _localeFromPlatform(Locale? platformLocale) {
    if (platformLocale != null &&
        platformLocale.languageCode.toLowerCase() == 'en') {
      return const Locale('en', 'US');
    }
    return const Locale('zh', 'CN');
  }

  Locale get _platformLocale =>
      WidgetsBinding.instance.platformDispatcher.locale;
}
