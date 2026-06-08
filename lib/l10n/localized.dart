import '../services/locale_service.dart';
import 'echo_translations.dart';

/// 当前界面是否为中文（简繁）。
bool get usesChineseUi => LocaleService.instance.usesChineseUi;

/// 非中文排版（较宽文案、英文式日期等）。
bool get isEnUi => !usesChineseUi;

/// 当前语言是否有完整翻译表。
bool get hasDedicatedTranslation =>
    EchoTranslations.translatedLanguageCodes
        .contains(LocaleService.instance.currentLocale.languageCode);

/// 按当前语言返回文案。
String tr(String zh, String en) {
  final lang = LocaleService.instance.currentLocale.languageCode;
  if (lang == 'zh') return zh;
  if (lang == 'en') return en;
  if (EchoTranslations.translatedLanguageCodes.contains(lang)) {
    return EchoTranslations.instance.translate(lang, en) ?? en;
  }
  return en;
}

List<String> trList(List<String> zh, List<String> en) {
  if (usesChineseUi) return zh;
  final lang = LocaleService.instance.currentLocale.languageCode;
  if (lang == 'en') return en;
  if (EchoTranslations.translatedLanguageCodes.contains(lang)) {
    return en
        .map((s) => EchoTranslations.instance.translate(lang, s) ?? s)
        .toList(growable: false);
  }
  return en;
}
