import 'dart:convert';

import 'package:flutter/services.dart';

/// Loads locale string tables keyed by English source text.
class EchoTranslations {
  EchoTranslations._();

  static final EchoTranslations instance = EchoTranslations._();

  /// Non-Chinese / non-English UI locales with dedicated JSON tables.
  static const translatedLanguageCodes = {
    'es',
    'fr',
    'ja',
    'ko',
    'de',
    'pt',
    'it',
    'ru',
    'ar',
    'hi',
    'th',
    'vi',
    'id',
  };

  static const _assetLocales = [
    'es',
    'fr',
    'ja',
    'ko',
    'de',
    'pt',
    'it',
    'ru',
    'ar',
    'hi',
    'th',
    'vi',
    'id',
  ];

  final Map<String, Map<String, String>> _tables = {};
  bool _loaded = false;

  bool get isLoaded => _loaded;

  Future<void> load() async {
    if (_loaded) return;
    final results = await Future.wait(
      _assetLocales.map((code) => _loadMap('assets/l10n/$code.json')),
    );
    for (var i = 0; i < _assetLocales.length; i++) {
      _tables[_assetLocales[i]] = results[i];
    }
    _loaded = true;
  }

  Future<Map<String, String>> _loadMap(String path) async {
    final raw = await rootBundle.loadString(path);
    return (jsonDecode(raw) as Map<String, dynamic>).cast<String, String>();
  }

  String? translate(String languageCode, String english) {
    if (!_loaded) return null;
    return _tables[languageCode]?[english];
  }
}
