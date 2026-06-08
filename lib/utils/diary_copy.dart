import '../l10n/localized.dart';

/// 回响列表与写作页文案。
abstract final class DiaryCopy {
  static String get searchHint =>
      tr('搜索回响里的文字…', 'Search your echoes…');
  static String get moodFilterAll => tr('全部', 'All');
  static String get recordedTime => tr('记录时间', 'Recorded time');
  static String get savedSnack => tr('已放进回响', 'Saved to echoes');
  static String get leaveConfirmMessage =>
      tr('还没保存，要离开吗？', 'Leave without saving?');
  static String get noSearchResult => tr('没有匹配的回响', 'No matching echoes');
  static String get expandRecordedTime =>
      tr('调整记录时间', 'Adjust recorded time');
  static String get periodThisWeek => tr('本周', 'This week');
  static String get periodThisMonth => tr('本月', 'This month');
}
