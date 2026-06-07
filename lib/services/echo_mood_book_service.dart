import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/echo_mood_book.dart';
import 'diary_service.dart';
import 'echo_stats_service.dart';

/// 聚合年度心情之书数据与自定义书名。
class EchoMoodBookService extends ChangeNotifier {
  EchoMoodBookService._();

  static final EchoMoodBookService instance = EchoMoodBookService._();

  static const _boxName = 'echo_mood_books';
  static const _titlesKey = 'custom_titles';
  static const _bookshelfTitleKey = 'bookshelf_title';
  static const defaultBookshelfTitle = '心情之书';
  static const maxTitleLength = 16;
  static const maxBookshelfTitleLength = 20;

  Box<dynamic>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _ready = true;
  }

  EchoMoodBook bookFor(int year, int month) {
    final stats = EchoStatsService.instance.monthStatistics(year, month);
    return EchoMoodBook(
      year: year,
      month: month,
      stats: stats,
      customTitle: customTitle(year, month),
    );
  }

  List<EchoMoodBook> booksForYear(int year) {
    return List.generate(12, (i) => bookFor(year, i + 1));
  }

  String? customTitle(int year, int month) {
    final map = _titlesMap;
    final key = _key(year, month);
    final value = map[key];
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  String get bookshelfTitle {
    final value = _box?.get(_bookshelfTitleKey) as String?;
    if (value == null || value.trim().isEmpty) return defaultBookshelfTitle;
    return value.trim();
  }

  Future<void> setBookshelfTitle(String? title) async {
    final trimmed = title?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == defaultBookshelfTitle) {
      await _box?.delete(_bookshelfTitleKey);
    } else {
      await _box?.put(
        _bookshelfTitleKey,
        trimmed.length > maxBookshelfTitleLength
            ? trimmed.substring(0, maxBookshelfTitleLength)
            : trimmed,
      );
    }
    notifyListeners();
  }

  Future<void> setCustomTitle(int year, int month, String? title) async {
    final map = Map<String, String>.from(_titlesMap);
    final key = _key(year, month);
    final trimmed = title?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      map.remove(key);
    } else {
      map[key] = trimmed.length > maxTitleLength
          ? trimmed.substring(0, maxTitleLength)
          : trimmed;
    }
    await _box?.put(_titlesKey, map);
    notifyListeners();
  }

  /// 至少展示一个完整生肖周期（12 年）。
  static const int minBrowseSpan = 12;

  /// 无更早日记时，最多向前浏览的年限（约三个生肖周期）。
  static const int maxBrowseSpan = 36;

  List<int> availableYears([DateTime? now]) {
    final currentYear = (now ?? DateTime.now()).year;
    var minYear = currentYear - minBrowseSpan + 1;

    for (final d in DiaryService.instance.diaries) {
      if (d.createdAt.year < minYear) minYear = d.createdAt.year;
    }

    final floorYear = currentYear - maxBrowseSpan + 1;
    if (minYear < floorYear) minYear = floorYear;

    return List.generate(currentYear - minYear + 1, (i) => minYear + i);
  }

  Map<String, String> get _titlesMap {
    final raw = _box?.get(_titlesKey) as Map<dynamic, dynamic>?;
    if (raw == null) return {};
    return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
  }

  static String _key(int year, int month) => '${year}_$month';
}
