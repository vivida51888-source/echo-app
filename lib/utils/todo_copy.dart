/// 待办相关温柔文案。
abstract final class TodoCopy {
  static const createHint = '试试：每个星期天下午6点给奶奶打电话';
  static const categoryLabel = '分类';
  static const noteHint = '备注（可选）';
  static const expiredLabel = '还在等你';
  static const completedSection = '已安放';
  static const sleepingSection = '已休眠';
  static const pendingSection = '待完成';
  static const emptyPending = '还没有想提醒自己的事\n想到什么，轻轻记下就好';
  static const emptySleeping = '没有休眠中的待办\n提醒过后十分钟会自动进入休眠';
  static const markDone = '安放';
  static const sleep = '休眠';
  static const wake = '唤醒';
  static const toDiary = '记入回响';
  static const edit = '编辑';
  static const delete = '删除';
  static const reschedule = '换个时间';
  static const rescheduleTonight = '改到今晚';
  static const rescheduleTomorrow = '改到明天';
  static const deleteConfirm = '不再提醒这件事？';
  static const repeatDoneToday = '今日已完成';
  static const nextReminder = '下次提醒';
  static const subtasksLabel = '拆解步骤';
  static const subtaskHint = '添加一个步骤…';
  static const parsePreview = '识别结果';
  static const manualSettings = '手动设置';
  static const allCategories = '全部';
  static const importantCategory = '重要';
  static const moveToImportant = '移入重要';
  static const removeFromImportant = '移出重要';
  static const weekStatsEntry = '本周概况';
  static const horizonFutureHint = '不必赶在今天的事，慢慢靠近就好';
  static const swipeStatusHint = '左右滑动切换状态';

  static const notificationTitle = 'Echo';

  static const notificationSummary = '轻量提醒';

  static String notificationBody(String content) =>
      '关于「$content」，到你轻轻约定的时间了。';

  static String diarySeed(String content) => '今天完成了「$content」：';
}
