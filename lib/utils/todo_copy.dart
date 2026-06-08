import '../l10n/localized.dart';

/// 待办相关温柔文案。
abstract final class TodoCopy {
  static String get createHint => tr(
        '试试：每个星期天下午6点给奶奶打电话',
        'Try: Call Grandma every Sunday at 6 PM',
      );
  static String get categoryLabel => tr('分类', 'Category');
  static String get noteHint => tr('备注（可选）', 'Note (optional)');
  static String get expiredLabel => tr('还在等你', 'Still waiting');
  static String get completedSection => tr('已安放', 'Done');
  static String get sleepingSection => tr('已休眠', 'Snoozed');
  static String get pendingSection => tr('待完成', 'To do');
  static String get emptyPending => tr(
        '还没有想提醒自己的事\n想到什么，轻轻记下就好',
        'Nothing to remind you of yet.\nNote what matters, gently.',
      );
  static String get emptySleeping => tr(
        '没有休眠中的待办\n提醒过后十分钟会自动进入休眠',
        'No snoozed tasks.\nTasks snooze 10 minutes after a reminder.',
      );
  static String get markDone => tr('安放', 'Done');
  static String get sleep => tr('休眠', 'Snooze');
  static String get wake => tr('唤醒', 'Wake');
  static String get toDiary => tr('记入回响', 'Add to echo');
  static String get edit => tr('编辑', 'Edit');
  static String get delete => tr('删除', 'Delete');
  static String get reschedule => tr('换个时间', 'Reschedule');
  static String get rescheduleTonight => tr('改到今晚', 'Tonight');
  static String get rescheduleTomorrow => tr('改到明天', 'Tomorrow');
  static String get deleteConfirm => tr('不再提醒这件事？', 'Stop reminding you?');
  static String get repeatDoneToday => tr('今日已完成', 'Done today');
  static String get nextReminder => tr('下次提醒', 'Next reminder');
  static String get subtasksLabel => tr('拆解步骤', 'Steps');
  static String get subtaskHint => tr('添加一个步骤…', 'Add a step…');
  static String get parsePreview => tr('识别结果', 'Parsed');
  static String get manualSettings => tr('手动设置', 'Manual');
  static String get allCategories => tr('全部', 'All');
  static String get importantCategory => tr('重要', 'Important');
  static String get moveToImportant => tr('移入重要', 'Mark important');
  static String get removeFromImportant => tr('移出重要', 'Unmark important');
  static String get weekStatsEntry => tr('本周概况', 'This week');
  static String get horizonFutureHint => tr(
        '不必赶在今天的事，慢慢靠近就好',
        'No rush — gentle progress is enough.',
      );
  static String get swipeStatusHint =>
      tr('左右滑动切换状态', 'Swipe left or right to change status');

  static const notificationTitle = 'Echo';

  static String get notificationSummary => tr('轻量提醒', 'Gentle reminder');

  static String notificationBody(String content) => tr('关于「$content」，到你轻轻约定的时间了。', 'It\'s time for «$content».');

  static String diarySeed(String content) => tr('今天完成了「$content」：', 'Finished today: «$content»: ');
}
