import '../models/future_letter.dart';
import 'diary_format.dart';

abstract final class FutureLetterCopy {
  static const pageTitle = '给未来的信';
  static const pageSubtitle = '写给以后的自己，到日子再轻轻拆开';

  static const notificationChannelName = '未来来信';
  static const notificationChannelDescription = 'Echo 封存信件送达时的提醒';
  static const notificationTitle = 'Echo · 未来来信';

  static const settingsTitle = '给未来的信';
  static const settingsSubtitle = '指定日期送达，本地通知提醒';

  static String notificationBody(FutureLetter letter) {
    if (letter.isDue()) {
      return '有一封你写给自己的信，今天可以拆开了';
    }
    return '有一封写给未来的信，快要到了';
  }

  static String listStatus(FutureLetter letter, [DateTime? now]) {
    if (letter.isOpened) {
      return '已于 ${DiaryFormat.listDateLabel(letter.openedAt!)} 拆开';
    }
    if (letter.isDue(now)) return '今天可以拆开';
    final days = letter.daysUntil(now);
    if (days == 1) return '明日送达';
    return '还有 $days 天';
  }

  static String homeWhisper(FutureLetter letter) {
    return '有一封写给未来的信，今天可以拆开了';
  }

  static const emptyListLine = '还没有封存信件\n写一封给未来的自己吧';

  static String sealedHint = '封存中，到日子才能拆开';

  static String readFooter(FutureLetter letter) {
    final written = DiaryFormat.listDateLabel(letter.createdAt);
    final due = DiaryFormat.listDateLabel(letter.deliverAt);
    return '$written 写下 · $due 送达';
  }
}
