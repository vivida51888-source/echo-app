import 'package:intl/intl.dart';

import '../l10n/localized.dart';
import '../services/locale_service.dart';

abstract final class DiaryFormat {
  static const weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  static const _enWeekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  static const monthNames = [
    '',
    '一月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '十一月',
    '十二月',
  ];

  static const _enMonthNames = [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static bool _latin([bool? english]) => english ?? !usesChineseUi;

  static String _intlTag() {
    final code = LocaleService.instance.currentLocale.languageCode;
    return switch (code) {
      'zh' => 'zh_CN',
      'es' => 'es_ES',
      'fr' => 'fr_FR',
      'ja' => 'ja_JP',
      'ko' => 'ko_KR',
      'de' => 'de_DE',
      'pt' => 'pt_BR',
      'it' => 'it_IT',
      'ru' => 'ru_RU',
      'ar' => 'ar',
      'hi' => 'hi_IN',
      'th' => 'th_TH',
      'vi' => 'vi_VN',
      'id' => 'id_ID',
      _ => 'en_US',
    };
  }

  static String dateLine(DateTime date, {bool? english}) {
    if (!_latin(english)) {
      final weekday = weekdays[date.weekday - 1];
      return '${date.month}月${date.day}日 · $weekday';
    }
    final tag = _intlTag();
    final weekday = DateFormat.E(tag).format(date);
    final month = DateFormat.MMM(tag).format(date);
    return '$month ${date.day} · $weekday';
  }

  static String polaroidDateLabel(DateTime date, {bool? english}) {
    if (!_latin(english)) {
      return '${date.year}年${date.month}月${date.day}日';
    }
    return DateFormat.yMMMd(_intlTag()).format(date);
  }

  static String dateShort(DateTime date, {bool? english}) {
    if (!_latin(english)) {
      final weekday = weekdays[date.weekday - 1];
      return '$weekday · ${date.month}月${date.day}日';
    }
    final tag = _intlTag();
    final weekday = DateFormat.E(tag).format(date);
    final month = DateFormat.MMM(tag).format(date);
    return '$weekday · $month ${date.day}';
  }

  static String monthTitle(int year, int month, {bool? english}) {
    if (!_latin(english)) {
      return '$year年${monthNames[month]}';
    }
    final tag = _intlTag();
    if (tag == 'en_US') {
      return '${_enMonthNames[month]} $year';
    }
    return DateFormat.yMMMM(tag).format(DateTime(year, month));
  }

  static String monthTitleShort(int month, {bool? english}) {
    if (!_latin(english)) {
      return monthNames[month];
    }
    return DateFormat.MMM(_intlTag()).format(DateTime(2000, month, 1));
  }

  static String dateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${start.month}/${start.day} – ${end.month}/${end.day}';
    }
    if (start.year == end.year) {
      return '${start.month}/${start.day} – ${end.month}/${end.day}';
    }
    return '${start.year}/${start.month}/${start.day} – '
        '${end.year}/${end.month}/${end.day}';
  }

  static String weekSectionTitle(DateTime weekStart, DateTime weekEnd) {
    return dateRange(weekStart, weekEnd);
  }

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool isToday(DateTime date) => isSameDay(date, DateTime.now());

  static bool isYesterday(DateTime date) {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return isSameDay(date, y);
  }

  static String listDateLabel(DateTime date, {bool? english}) {
    if (!_latin(english)) {
      if (isToday(date)) return tr('今天', 'Today');
      if (isYesterday(date)) return tr('昨天', 'Yesterday');
      return '${date.month}月${date.day}日';
    }
    if (isToday(date)) return tr('今天', 'Today');
    if (isYesterday(date)) return tr('昨天', 'Yesterday');
    return DateFormat.MMMd(_intlTag()).format(date);
  }

  static String weekdayLabel(DateTime date, {bool? english}) =>
      _latin(english) ? _enWeekdays[date.weekday - 1] : weekdays[date.weekday - 1];

  static String weekdayGlyph(DateTime date, {bool? english}) {
    if (_latin(english)) {
      return DateFormat.E(_intlTag()).format(date);
    }
    const glyphs = ['一', '二', '三', '四', '五', '六', '日'];
    return glyphs[date.weekday - 1];
  }

  static String deriveTitle(String content) {
    final firstLine = content.split('\n').first.trim();
    if (firstLine.isEmpty) return '';
    if (firstLine.length <= 28) return firstLine;
    return '${firstLine.substring(0, 28)}…';
  }
}
