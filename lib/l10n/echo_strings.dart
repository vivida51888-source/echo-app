import 'package:flutter/material.dart';

import '../services/locale_service.dart';
import '../utils/echo_copy.dart';
import 'localized.dart';

/// 应用内文案。随 [LocaleService] 切换。
class EchoStrings {
  EchoStrings(this.locale);

  factory EchoStrings.of([Locale? locale]) =>
      EchoStrings(locale ?? LocaleService.instance.currentLocale);

  final Locale locale;

  bool get usesChineseText => locale.languageCode == 'zh';

  /// 非中文界面（日期格式、每日语录等沿用西文逻辑）。
  bool get isEn => !usesChineseText;

  static EchoStrings get current => EchoStrings.of();

  String get momentTitle => tr('此刻', 'Moment');
  String get echoTitle => tr('回响', 'Echoes');
  String get todoTitle => tr('待办', 'Tasks');
  String get settingsTitle => tr('设置', 'Settings');

  String get todoSubtitle =>
      tr('想到什么，轻轻记下就好', 'Note what matters, gently');

  String get settingsSubtitle =>
      tr('隐私、备份、外观', 'Privacy, backup, appearance');

  String get writeToday => tr('写下今天', 'Write today');
  String get continueToday => tr('继续写今天', 'Continue today');
  String get writeTodayHint =>
      tr('记下正在发生的感受', 'Capture what you feel right now');
  String get continueTodayHint =>
      tr('草稿还在，接着写吧', 'Your draft is still waiting');
  String get reviewPast => tr('回看过去', 'Look back');
  String reviewPastWithBookshelf(String title) => '$reviewPast · $title';

  String get languageTitle => tr('语言', 'Language');
  String get languageSubtitle =>
      tr('界面与启动图', 'Interface & splash screen');
  String get languagePageTitle => tr('语言', 'Language');
  String get languagePageFootnote => tr(
        '除简繁中文与英文外，其余语言均已提供完整翻译；日语与韩语使用中文启动图。日期等格式会随所选语言变化。',
        'All languages except Chinese and English are fully translated. Japanese and Korean use the Chinese splash image. Dates and formats follow your selection.',
      );

  // Settings groups & tiles
  String get settingsPrivacyGroup => tr('隐私与数据', 'Privacy & data');
  String get settingsRecordsGroup => tr('记录', 'Records');
  String get settingsKeepsakesGroup => keepsakesPageTitle;

  String get keepsakesPageTitle => tr('回响珍藏', 'Echo Treasury');
  String get keepsakesPageSubtitle => tr(
        '用回响币兑换 · 点亮成就星图',
        'Redeem with coins · light up achievements',
      );
  String get settingsAboutGroup => tr('关于', 'About');
  String get settingsDisplayGroup => tr('显示', 'Display');

  String get appLockTitle => tr('应用锁与隐私', 'App lock & privacy');
  String get appLockSubtitle =>
      tr('指纹、密码、多任务模糊', 'Fingerprint, PIN, app switcher blur');
  String get recycleBinTitle => tr('回收站', 'Recycle bin');
  String get recycleBinSubtitle =>
      tr('删除后保留 15 天', 'Kept for 15 days after delete');
  String get exportTitle => tr('备份与导出', 'Backup & export');
  String get exportSubtitle => tr('Word、全量 zip', 'Word, full zip');
  String get importantDaysTitle => tr('印记 · 重要日', 'Marks · Important days');
  String get importantDaysSubtitle =>
      tr('生日、纪念日提醒', 'Birthdays & anniversaries');
  String get echoShopTitle => tr('回响小铺', 'Echo shop');
  String get echoShopSubtitle =>
      tr('雨露与皮肤', 'Dew & skins with Echo coins');
  String get personalVaultTitle => tr('个人成就', 'Achievements');
  String get personalVaultSubtitle => tr(
        '三星成就 · 赚取回响币',
        'Three-star goals · earn Echo coins',
      );
  String get aboutEchoTitle => tr('关于 Echo', 'About Echo');
  String get aboutEchoSubtitle =>
      tr('版本与功能说明', 'Version & features');
  String get dataPrivacyTitle => tr('数据与隐私', 'Data & privacy');
  String get dataPrivacySubtitle =>
      tr('本地存储与权限', 'Local storage & permissions');
  String get appearanceTitle => tr('外观', 'Appearance');
  String appearanceSubtitle(String name) =>
      tr('纸色 · $name', 'Paper tone · $name');
  String get diaryStationeryTitle => tr('日记信纸', 'Diary stationery');
  String get nightModeTitle => tr('夜间模式', 'Night mode');

  // Echo hub modules
  String get hubPhoto => tr('留影', 'Photos');
  String get hubChapters => tr('篇章', 'Chapters');
  String get hubTree => tr('雨露树', 'Rain tree');
  String get hubStats => tr('统计', 'Stats');

  // Common
  String get cancel => tr('取消', 'Cancel');
  String get confirm => tr('确认', 'Confirm');
  String get save => tr('保存', 'Save');
  String get delete => tr('删除', 'Delete');
  String get edit => tr('编辑', 'Edit');
  String get done => tr('完成', 'Done');
  String get loading => tr('加载中…', 'Loading…');
  String get today => tr('今天', 'Today');
  String get yesterday => tr('昨天', 'Yesterday');

  String dailyPhrase(DateTime now) => EchoCopy.dailyPhrase(now);
}
