import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/important_day.dart';
import '../utils/important_day_copy.dart';
import 'important_day_notification_service.dart';

/// 印记 · 重要日：本地存储与排序。
class ImportantDayService extends ChangeNotifier {
  ImportantDayService._();

  static final ImportantDayService instance = ImportantDayService._();

  static const _boxName = 'echo_important_days';
  static const _remindersEnabledKey = '__reminders_enabled__';
  static const maxTitleLength = 24;
  static const maxNoteLength = 80;

  Box<dynamic>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  bool get remindersEnabled =>
      _box?.get(_remindersEnabledKey, defaultValue: true) as bool? ?? true;

  List<ImportantDay> get anchorItems {
    final list = _items.where((d) => d.isAnchor).toList();
    list.sort((a, b) {
      final ae = a.daysElapsed() ?? 0;
      final be = b.daysElapsed() ?? 0;
      return be.compareTo(ae);
    });
    return List.unmodifiable(list);
  }

  List<ImportantDay> get annualItems {
    final list = _items.where((d) => !d.isAnchor).toList();
    list.sort((a, b) {
      final cmp = a.daysUntil().compareTo(b.daysUntil());
      if (cmp != 0) return cmp;
      return a.title.compareTo(b.title);
    });
    return List.unmodifiable(list);
  }

  List<ImportantDay> get items {
    final list = _items;
    list.sort((a, b) {
      final cmp = a.daysUntil().compareTo(b.daysUntil());
      if (cmp != 0) return cmp;
      return a.title.compareTo(b.title);
    });
    return List.unmodifiable(list);
  }

  List<ImportantDay> get enabledItems =>
      items.where((d) => d.enabled).toList(growable: false);

  List<ImportantDay> _items = [];

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    _items = _box!.keys
        .where((k) => k is String && !k.startsWith('__'))
        .map((k) => ImportantDay.fromJson(
              Map<dynamic, dynamic>.from(_box!.get(k) as Map),
            ))
        .toList();
    _ready = true;
    notifyListeners();
  }

  ImportantDay? todayHighlight([DateTime? now]) {
    final base = now ?? DateTime.now();
    for (final day in enabledItems) {
      if (day.isToday(base)) return day;
    }
    return null;
  }

  /// 首页 whisper：轮回日提前/当天，或起点日刻度当天。
  String? whisperForHome([DateTime? now]) {
    final base = now ?? DateTime.now();
    ImportantDay? annualMatch;
    var annualDaysUntil = -1;

    for (final day in enabledItems) {
      if (day.isAnchor) {
        final hit = day.milestoneOn(base);
        if (hit != null) {
          return ImportantDayCopy.homeWhisperMilestone(day, hit);
        }
        continue;
      }

      final until = day.daysUntil(base);
      if (!day.remindDaysBefore.contains(until)) continue;
      if (annualMatch == null || until < annualDaysUntil) {
        annualMatch = day;
        annualDaysUntil = until;
      }
    }

    if (annualMatch == null) return null;
    if (annualDaysUntil == 0) {
      return ImportantDayCopy.homeWhisper(annualMatch, base);
    }
    return ImportantDayCopy.homeWhisperAdvance(annualMatch, annualDaysUntil);
  }

  String? whisperForToday([DateTime? now]) => whisperForHome(now);

  ImportantDay? findById(String id) {
    for (final day in _items) {
      if (day.id == id) return day;
    }
    return null;
  }

  Future<void> setRemindersEnabled(bool value) async {
    await _box?.put(_remindersEnabledKey, value);
    notifyListeners();
    await ImportantDayNotificationService.instance.syncAll();
  }

  Future<ImportantDay> save(ImportantDay day) async {
    final normalized = day.copyWith(
      title: _trim(day.title, maxTitleLength),
      note: day.note == null ? null : _trim(day.note!, maxNoteLength),
    );
    await _box?.put(normalized.id, normalized.toJson());
    final index = _items.indexWhere((d) => d.id == normalized.id);
    if (index >= 0) {
      _items[index] = normalized;
    } else {
      _items.add(normalized);
    }
    notifyListeners();
    await ImportantDayNotificationService.instance.syncOne(normalized);
    return normalized;
  }

  Future<void> delete(String id) async {
    await _box?.delete(id);
    _items.removeWhere((d) => d.id == id);
    notifyListeners();
    await ImportantDayNotificationService.instance.cancel(id);
  }

  Future<void> toggleEnabled(String id, bool enabled) async {
    final day = findById(id);
    if (day == null) return;
    await save(day.copyWith(enabled: enabled));
  }

  String _trim(String value, int max) {
    final trimmed = value.trim();
    if (trimmed.length <= max) return trimmed;
    return trimmed.substring(0, max);
  }
}

String newImportantDayId() =>
    'id_${DateTime.now().microsecondsSinceEpoch}';
