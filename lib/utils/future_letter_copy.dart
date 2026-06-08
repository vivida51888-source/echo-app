import '../l10n/localized.dart';
import '../models/future_letter.dart';
import 'diary_format.dart';

abstract final class FutureLetterCopy {
  static String get pageTitle => tr('给未来的信', 'Letter to the future');
  static String get pageSubtitle => tr(
        '写给以后的自己，到日子再轻轻拆开',
        'Write to your future self — open when the day arrives',
      );

  static String get notificationChannelName =>
      tr('未来来信', 'Future letters');
  static String get notificationChannelDescription => tr(
        'Echo 封存信件送达时的提醒',
        'When a sealed letter is ready to open',
      );
  static String get notificationTitle => tr('Echo · 未来来信', 'Echo · Future letter');

  static String get settingsTitle => tr('给未来的信', 'Letters to the future');
  static String get settingsSubtitle => tr(
        '指定日期送达，本地通知提醒',
        'Deliver on a date — local notification',
      );

  static String notificationBody(FutureLetter letter) {
    if (letter.isDue()) {
      return tr(
        '有一封你写给自己的信，今天可以拆开了',
        'A letter to yourself is ready to open today',
      );
    }
    return tr(
      '有一封写给未来的信，快要到了',
      'A letter to the future is almost due',
    );
  }

  static String listStatus(FutureLetter letter, [DateTime? now]) {
    if (letter.isOpened) {
      final date = DiaryFormat.listDateLabel(letter.openedAt!);
      return tr('已于 $date 拆开', 'Opened on $date');
    }
    if (letter.isDue(now)) return tr('今天可以拆开', 'Ready today');
    final days = letter.daysUntil(now);
    if (days == 1) return tr('明日送达', 'Arrives tomorrow');
    return tr('还有 $days 天', '$days days left');
  }

  static String homeWhisper(FutureLetter letter) {
    return tr(
      '有一封写给未来的信，今天可以拆开了',
      'A letter to the future is ready to open today',
    );
  }

  static String get emptyListLine => tr(
        '还没有封存信件\n写一封给未来的自己吧',
        'No sealed letters yet.\nWrite one to your future self.',
      );

  static String get sealedHint =>
      tr('封存中，到日子才能拆开', 'Sealed until delivery day');

  static String earlyOpenPrompt(int coins, int daysLeft) => tr(
        '距送达还有 $daysLeft 天\n提前拆开需消耗 $coins 回响币',
        '$daysLeft days until delivery\nOpen early for $coins Echo coins',
      );

  static String readFooter(FutureLetter letter) {
    final written = DiaryFormat.listDateLabel(letter.createdAt);
    final due = DiaryFormat.listDateLabel(letter.deliverAt);
    return tr('$written 写下 · $due 送达', 'Written $written · Due $due');
  }
}
