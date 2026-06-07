import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import '../utils/echo_copy.dart';

/// 应用内文案（中英）。随 [LocaleService] 切换。
class EchoStrings {
  EchoStrings(this.locale);

  factory EchoStrings.of([Locale? locale]) =>
      EchoStrings(locale ?? LocaleService.instance.currentLocale);

  final Locale locale;

  bool get isEn => locale.languageCode == 'en';

  static EchoStrings get current => EchoStrings.of();

  String get momentTitle => isEn ? 'Moment' : '此刻';
  String get echoTitle => isEn ? 'Echoes' : '回响';
  String get todoTitle => isEn ? 'Tasks' : '待办';
  String get settingsTitle => isEn ? 'Settings' : '设置';

  String get todoSubtitle => isEn
      ? 'Note what matters, gently'
      : '想到什么，轻轻记下就好';

  String get settingsSubtitle =>
      isEn ? 'Privacy, backup, appearance' : '隐私、备份、外观';

  String get writeToday => isEn ? 'Write today' : '写下今天';
  String get continueToday => isEn ? 'Continue today' : '继续写今天';
  String get reviewPast => isEn ? 'Look back' : '回看过去';
  String reviewPastWithBookshelf(String title) => '$reviewPast · $title';

  String get languageTitle => isEn ? 'Language' : '语言';
  String get languageSubtitle =>
      isEn ? 'Interface & splash screen' : '界面与启动图';
  String get languagePageTitle => isEn ? 'Language' : '语言';
  String get languagePageFootnote => isEn
      ? 'The splash screen follows your language choice.'
      : '启动图会随语言切换。';

  String dailyPhrase(DateTime now) {
    if (!isEn) return EchoCopy.dailyPhrase(now);

    final hour = now.hour;
    final pool = hour < 5 || hour >= 22
        ? _enNightPhrases
        : hour < 11
            ? _enDawnPhrases
            : hour < 17
                ? _enDayPhrases
                : _enDuskPhrases;
    final index = (now.year * 1000 + now.month * 50 + now.day) % pool.length;
    return pool[index];
  }

  static const _enNightPhrases = [
    'The night is quiet — leave a thought for yourself.',
    'Moonlight is soft; so can your heart be.',
    'Before sleep, gift yourself a gentle sentence.',
  ];

  static const _enDawnPhrases = [
    'Morning light arrives — begin softly.',
    'A new day opens like a blank page.',
    'Breathe in the dawn; you are allowed to start slow.',
  ];

  static const _enDayPhrases = [
    'Afternoon drifts by — capture a small moment.',
    'Ordinary hours still deserve to be remembered.',
    'Let today leave a quiet echo.',
  ];

  static const _enDuskPhrases = [
    'Dusk settles in — put the day down gently.',
    'The sky fades; keep what mattered.',
    'Evening is for softer words.',
  ];
}
