import 'package:flutter/material.dart';

import '../services/locale_service.dart';

/// 按界面语言解析图片资源路径。
abstract final class LocaleAssets {
  static String _folder(Locale locale) =>
      locale.languageCode == 'en' ? 'en' : 'zh';

  static String splashScreen([Locale? locale]) {
    final code = _folder(locale ?? LocaleService.instance.currentLocale);
    return 'assets/images/$code/splash_screen.png';
  }

}
