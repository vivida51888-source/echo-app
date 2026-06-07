import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/diary_format.dart';

typedef DiaryDraft = ({
  String draftId,
  String content,
  String? moodWeather,
  List<String> imagePaths,
  DateTime recordedAt,
  bool fromEmotionalEntry,
});

/// 写作页单份草稿（本地自动保存）。
class DiaryDraftService extends ChangeNotifier {
  DiaryDraftService._();

  static final DiaryDraftService instance = DiaryDraftService._();

  static const _boxName = 'echo_diary_draft';
  static const _key = 'current';

  Box<dynamic>? _box;
  DiaryDraft? _current;

  DiaryDraft? get current => _current;

  /// 今日是否有未保存草稿（有正文、图片或心情即算）。
  bool get hasTodayDraft {
    final draft = _current;
    if (draft == null) return false;
    if (!DiaryFormat.isToday(draft.recordedAt)) return false;
    return draft.content.trim().isNotEmpty ||
        draft.imagePaths.isNotEmpty ||
        (draft.moodWeather != null && draft.moodWeather!.isNotEmpty);
  }

  Future<void> init() async {
    await _ensureBox();
    await _reloadFromBox();
  }

  Future<void> _ensureBox() async {
    _box ??= await Hive.openBox<dynamic>(_boxName);
  }

  Future<void> _reloadFromBox() async {
    await _ensureBox();
    final raw = _box!.get(_key);
    if (raw == null) {
      _current = null;
      return;
    }
    final map = Map<dynamic, dynamic>.from(raw as Map);
    _current = (
      draftId: map['draftId'] as String,
      content: map['content'] as String? ?? '',
      moodWeather: map['moodWeather'] as String?,
      imagePaths: (map['imagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      fromEmotionalEntry: map['fromEmotionalEntry'] as bool? ?? false,
    );
  }

  Future<void> save({
    required String draftId,
    required String content,
    String? moodWeather,
    required List<String> imagePaths,
    required DateTime recordedAt,
    required bool fromEmotionalEntry,
  }) async {
    await _ensureBox();
    await _box!.put(_key, {
      'draftId': draftId,
      'content': content,
      'moodWeather': moodWeather,
      'imagePaths': imagePaths,
      'recordedAt': recordedAt.toIso8601String(),
      'fromEmotionalEntry': fromEmotionalEntry,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    _current = (
      draftId: draftId,
      content: content,
      moodWeather: moodWeather,
      imagePaths: imagePaths,
      recordedAt: recordedAt,
      fromEmotionalEntry: fromEmotionalEntry,
    );
    notifyListeners();
  }

  Future<DiaryDraft?> load() async {
    await _reloadFromBox();
    notifyListeners();
    return _current;
  }

  Future<void> clear() async {
    await _ensureBox();
    await _box!.delete(_key);
    _current = null;
    notifyListeners();
  }
}
