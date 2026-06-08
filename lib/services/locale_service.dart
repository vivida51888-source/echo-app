import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../l10n/localized.dart';

/// 可选界面语言（原生名称展示）。
class EchoLocaleOption {
  const EchoLocaleOption({
    required this.id,
    this.locale,
    required this.nativeLabel,
  });

  final String id;
  final Locale? locale;
  final String nativeLabel;

  bool get isSystem => id == LocaleService.systemId;

  bool get usesChineseUi => locale?.languageCode == 'zh';

  bool get usesChineseImages {
    final code = locale?.languageCode;
    return code == 'zh' || code == 'ja' || code == 'ko';
  }

  bool get hasDedicatedTranslation {
    final code = locale?.languageCode;
    if (code == null || code == 'zh' || code == 'en') return false;
    return true;
  }
}

/// 应用界面语言（与系统语言独立配置）。
class LocaleService extends ChangeNotifier {
  LocaleService._();

  static final LocaleService instance = LocaleService._();

  static const systemId = 'system';

  static const _boxName = 'echo_locale';
  static const _key = 'mode';

  /// 世界常用语言 + 简繁中文。
  static const supportedOptions = [
    EchoLocaleOption(id: systemId, locale: null, nativeLabel: ''),
    EchoLocaleOption(
      id: 'zh_CN',
      locale: Locale('zh', 'CN'),
      nativeLabel: '简体中文',
    ),
    EchoLocaleOption(
      id: 'zh_TW',
      locale: Locale('zh', 'TW'),
      nativeLabel: '繁體中文',
    ),
    EchoLocaleOption(
      id: 'en_US',
      locale: Locale('en', 'US'),
      nativeLabel: 'English',
    ),
    EchoLocaleOption(
      id: 'ja_JP',
      locale: Locale('ja', 'JP'),
      nativeLabel: '日本語',
    ),
    EchoLocaleOption(
      id: 'ko_KR',
      locale: Locale('ko', 'KR'),
      nativeLabel: '한국어',
    ),
    EchoLocaleOption(
      id: 'es_ES',
      locale: Locale('es', 'ES'),
      nativeLabel: 'Español',
    ),
    EchoLocaleOption(
      id: 'fr_FR',
      locale: Locale('fr', 'FR'),
      nativeLabel: 'Français',
    ),
    EchoLocaleOption(
      id: 'de_DE',
      locale: Locale('de', 'DE'),
      nativeLabel: 'Deutsch',
    ),
    EchoLocaleOption(
      id: 'pt_BR',
      locale: Locale('pt', 'BR'),
      nativeLabel: 'Português',
    ),
    EchoLocaleOption(
      id: 'it_IT',
      locale: Locale('it', 'IT'),
      nativeLabel: 'Italiano',
    ),
    EchoLocaleOption(
      id: 'ru_RU',
      locale: Locale('ru', 'RU'),
      nativeLabel: 'Русский',
    ),
    EchoLocaleOption(
      id: 'ar',
      locale: Locale('ar'),
      nativeLabel: 'العربية',
    ),
    EchoLocaleOption(
      id: 'hi_IN',
      locale: Locale('hi', 'IN'),
      nativeLabel: 'हिन्दी',
    ),
    EchoLocaleOption(
      id: 'th_TH',
      locale: Locale('th', 'TH'),
      nativeLabel: 'ไทย',
    ),
    EchoLocaleOption(
      id: 'vi_VN',
      locale: Locale('vi', 'VN'),
      nativeLabel: 'Tiếng Việt',
    ),
    EchoLocaleOption(
      id: 'id_ID',
      locale: Locale('id', 'ID'),
      nativeLabel: 'Bahasa Indonesia',
    ),
  ];

  static List<Locale> get supportedLocales => [
        for (final option in supportedOptions)
          if (option.locale != null) option.locale!,
      ];

  Box<dynamic>? _box;
  String _selectedId = systemId;

  String get selectedId => _selectedId;

  EchoLocaleOption get selectedOption => supportedOptions.firstWhere(
        (option) => option.id == _selectedId,
        orElse: () => supportedOptions.first,
      );

  /// 兼容旧代码：非中文界面（含已翻译语言）。
  bool get isEnglish => !usesChineseUi;

  bool get usesChineseUi => currentLocale.languageCode == 'zh';

  bool get usesChineseImages {
    final code = currentLocale.languageCode;
    return code == 'zh' || code == 'ja' || code == 'ko';
  }

  Future<void> init() async {
    _box = await Hive.openBox<dynamic>(_boxName);
    final raw = _box?.get(_key) as String?;
    _selectedId = _migrateId(raw);
    notifyListeners();
  }

  Future<void> setSelectedId(String id) async {
    if (_selectedId == id) return;
    if (!supportedOptions.any((option) => option.id == id)) return;
    _selectedId = id;
    await _box?.put(_key, id);
    notifyListeners();
  }

  String displayLabel() {
    final option = selectedOption;
    if (option.isSystem) {
      return tr('跟随系统', 'Follow system');
    }
    return option.nativeLabel;
  }

  String optionLabel(EchoLocaleOption option) {
    if (option.isSystem) {
      return tr('跟随系统', 'Follow system');
    }
    return option.nativeLabel;
  }

  String? optionSubtitle(EchoLocaleOption option) {
    if (option.isSystem) {
      return tr('优先使用系统语言', 'Uses device language when available');
    }
    if (option.usesChineseUi) {
      return tr('中文界面', 'Chinese interface');
    }
    if (option.locale?.languageCode == 'en') {
      return tr('英文界面', 'English interface');
    }
    final code = option.locale?.languageCode;
    if (code == null) return null;

    final label = _interfaceSubtitle(code);
    if (option.usesChineseImages) {
      return '$label · ${tr('中文启动图', 'Chinese splash')}';
    }
    return label;
  }

  Locale get currentLocale => resolveLocale(_platformLocale);

  Locale resolveLocale(Locale? platformLocale) {
    final option = selectedOption;
    if (option.isSystem) {
      return _localeFromPlatform(platformLocale);
    }
    return option.locale!;
  }

  String _migrateId(String? raw) {
    switch (raw) {
      case 'chinese':
        return 'zh_CN';
      case 'english':
        return 'en_US';
      case systemId:
        return systemId;
      case null:
        return systemId;
      default:
        if (supportedOptions.any((option) => option.id == raw)) {
          return raw;
        }
        return systemId;
    }
  }

  Locale _localeFromPlatform(Locale? platformLocale) {
    if (platformLocale == null) {
      return const Locale('zh', 'CN');
    }

    final code = platformLocale.languageCode.toLowerCase();
    final country = platformLocale.countryCode?.toUpperCase();

    for (final option in supportedOptions) {
      final locale = option.locale;
      if (locale == null) continue;
      if (locale.languageCode != code) continue;
      if (locale.countryCode == null || locale.countryCode == country) {
        return locale;
      }
    }

    return switch (code) {
      'zh' => (country == 'TW' || country == 'HK' || country == 'MO')
          ? const Locale('zh', 'TW')
          : const Locale('zh', 'CN'),
      'en' => const Locale('en', 'US'),
      'ja' => const Locale('ja', 'JP'),
      'ko' => const Locale('ko', 'KR'),
      'es' => const Locale('es', 'ES'),
      'fr' => const Locale('fr', 'FR'),
      'de' => const Locale('de', 'DE'),
      'pt' => const Locale('pt', 'BR'),
      'it' => const Locale('it', 'IT'),
      'ru' => const Locale('ru', 'RU'),
      'ar' => const Locale('ar'),
      'hi' => const Locale('hi', 'IN'),
      'th' => const Locale('th', 'TH'),
      'vi' => const Locale('vi', 'VN'),
      'id' => const Locale('id', 'ID'),
      _ => const Locale('en', 'US'),
    };
  }

  Locale get _platformLocale =>
      WidgetsBinding.instance.platformDispatcher.locale;
}

String _interfaceSubtitle(String code) {
  return switch (code) {
    'en' => tr('英文界面', 'English interface'),
    'ja' => tr('日语界面', 'Japanese interface'),
    'ko' => tr('韩语界面', 'Korean interface'),
    'es' => tr('西班牙语界面', 'Spanish interface'),
    'fr' => tr('法语界面', 'French interface'),
    'de' => tr('德语界面', 'German interface'),
    'pt' => tr('葡萄牙语界面', 'Portuguese interface'),
    'it' => tr('意大利语界面', 'Italian interface'),
    'ru' => tr('俄语界面', 'Russian interface'),
    'ar' => tr('阿拉伯语界面', 'Arabic interface'),
    'hi' => tr('印地语界面', 'Hindi interface'),
    'th' => tr('泰语界面', 'Thai interface'),
    'vi' => tr('越南语界面', 'Vietnamese interface'),
    'id' => tr('印尼语界面', 'Indonesian interface'),
    _ => tr('本地化界面', 'Localized interface'),
  };
}
