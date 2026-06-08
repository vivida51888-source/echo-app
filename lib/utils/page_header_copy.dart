import '../l10n/localized.dart';

/// 主 Tab 页左上角标题与一句话。
abstract final class PageHeaderCopy {
  static String get momentTitle => tr('此刻', 'Moment');
  static String get echoTitle => tr('回响', 'Echoes');
  static String get todoTitle => tr('待办', 'Tasks');
  static String get todoSubtitle => tr(
        '想到什么，轻轻记下就好',
        'Note what matters, gently',
      );
  static String get settingsTitle => tr('设置', 'Settings');
  static String get settingsSubtitle =>
      tr('隐私、备份、外观', 'Privacy, backup, appearance');
}
