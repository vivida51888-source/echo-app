import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/diary.dart';
import '../models/trashed_diary.dart';
import '../models/weather_mood.dart';
import '../utils/diary_format.dart';
import 'diary_image_storage.dart';
import 'echo_reward_service.dart';
import 'echo_tree_service.dart';
import 'mock_ai_service.dart';
import 'widget_bridge_service.dart';

class DiaryService extends ChangeNotifier {
  DiaryService._();

  static final DiaryService instance = DiaryService._();

  static const _boxName = 'echo_diaries';
  static const _trashBoxName = 'echo_diaries_trash';

  Box<dynamic>? _box;
  Box<dynamic>? _trashBox;
  bool _ready = false;

  bool get isReady => _ready;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_boxName);
    _trashBox = await Hive.openBox<dynamic>(_trashBoxName);
    if (_box!.isEmpty) {
      await _seedSamples();
    }
    await purgeExpiredTrash();
    _ready = true;
    notifyListeners();
  }

  Future<void> _seedSamples() async {
    final samples = [
      Diary(
        id: 'seed_1',
        content:
            '下班路上忽然下起小雨，站在便利店门口等雨停。今天工作很累，但朋友的问候让人心里暖了一点。',
        moodWeather: '🌧 小雨',
        createdAt: DateTime(2026, 5, 17, 19, 30),
        aiKeywords: const ['下雨', '工作', '朋友'],
        aiSummary: '雨声里的情绪，也被你温柔地接住了。',
      ),
      Diary(
        id: 'seed_2',
        content: '打字打了很久，最后还是删掉了。有些话大概只适合留在心里。',
        moodWeather: '⛅ 多云',
        createdAt: DateTime(2026, 5, 15, 23, 12),
        aiKeywords: const ['孤独'],
        aiSummary: '有些时刻一个人静静待着，也是一种回响。',
      ),
      Diary(
        id: 'seed_3',
        content: '周末在家整理房间，阳光从窗帘缝里漏进来，忽然觉得生活也没那么糟。',
        moodWeather: '☀️ 晴',
        createdAt: DateTime(2026, 5, 10, 11, 0),
        aiKeywords: const ['温柔'],
        aiSummary: '文字里藏着细小的温柔，Echo 替你留住了。',
      ),
      Diary(
        id: 'seed_4',
        content: '四月末的项目终于收尾，和同事们去吃了顿简单的饭，聊了些无关紧要的开心事。',
        moodWeather: '⛅ 多云',
        createdAt: DateTime(2026, 4, 28, 20, 15),
        aiKeywords: const ['工作', '朋友'],
        aiSummary: '与人的联结，总是生命里很亮的一页。',
      ),
    ];
    for (final diary in samples) {
      await _box!.put(diary.id, diary.toMap());
    }
  }

  List<Diary> get diaries {
    if (_box == null) return [];
    final list = _box!.values
        .map((e) => Diary.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  List<TrashedDiary> get trashedDiaries {
    if (_trashBox == null) return [];
    final list = _trashBox!.values
        .map((e) => TrashedDiary.fromMap(Map<dynamic, dynamic>.from(e as Map)))
        .toList();
    list.sort((a, b) => b.deletedAt.compareTo(a.deletedAt));
    return list;
  }

  Diary? findTodayEntry() {
    for (final diary in diaries) {
      if (DiaryFormat.isToday(diary.createdAt)) return diary;
    }
    return null;
  }

  Diary? get latestEntry {
    final list = diaries;
    if (list.isEmpty) return null;
    return list.first;
  }

  Diary? getDiaryById(String id) {
    final raw = _box?.get(id);
    if (raw == null) return null;
    return Diary.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  TrashedDiary? getTrashedById(String id) {
    final raw = _trashBox?.get(id);
    if (raw == null) return null;
    return TrashedDiary.fromMap(Map<dynamic, dynamic>.from(raw as Map));
  }

  Diary? randomDriftBottleDiary({String? excludeId}) {
    final candidates = diaries.where((d) {
      if (!d.inDriftBottle) return false;
      if (excludeId != null && d.id == excludeId) return false;
      return d.content.trim().isNotEmpty;
    }).toList();
    if (candidates.isEmpty) return null;
    return candidates[Random().nextInt(candidates.length)];
  }

  List<Diary> get favoriteDiaries =>
      diaries.where((d) => d.isFavorite).toList();

  List<Diary> get driftBottleDiaries =>
      diaries.where((d) => d.inDriftBottle).toList();

  Future<void> toggleFavorite(String id) async {
    final diary = getDiaryById(id);
    if (diary == null) return;
    await _box!.put(id, diary.copyWith(isFavorite: !diary.isFavorite).toMap());
    notifyListeners();
  }

  Future<void> toggleDriftBottle(String id) async {
    final diary = getDiaryById(id);
    if (diary == null) return;
    await _box!.put(
      id,
      diary.copyWith(inDriftBottle: !diary.inDriftBottle).toMap(),
    );
    notifyListeners();
  }

  Diary? randomPastDiary({String? excludeId}) =>
      randomDriftBottleDiary(excludeId: excludeId);

  Future<Diary> save({
    String? id,
    required String content,
    String? moodWeather,
    required List<String> imagePaths,
    DateTime? createdAt,
    double? latitude,
    double? longitude,
    String? placeLabel,
    bool clearLocation = false,
  }) async {
    final diaryId = id ?? DateTime.now().millisecondsSinceEpoch.toString();
    final isNewSave = !_box!.containsKey(diaryId);
    final ai = MockAiService.instance.analyze(
      content,
      seed: diaryId,
      hasImages: imagePaths.isNotEmpty,
    );

    final existing = getDiaryById(diaryId);

    final diary = Diary(
      id: diaryId,
      content: content,
      moodWeather: WeatherMood.resolveDisplay(moodWeather),
      images: imagePaths,
      createdAt: createdAt ?? DateTime.now(),
      aiKeywords: ai.keywords,
      aiSummary: ai.summary,
      isFavorite: existing?.isFavorite ?? false,
      inDriftBottle: existing?.inDriftBottle ?? false,
      latitude: clearLocation ? null : (latitude ?? existing?.latitude),
      longitude: clearLocation ? null : (longitude ?? existing?.longitude),
      placeLabel: clearLocation ? null : (placeLabel ?? existing?.placeLabel),
    );

    await _box!.put(diary.id, diary.toMap());
    notifyListeners();
    await EchoTreeService.instance.grantWaterForDiary(
      diary,
      isNewSave: isNewSave,
      savedAt: DateTime.now(),
    );
    await WidgetBridgeService.instance.syncFromApp();
    await EchoRewardService.instance.onDiaryActivity();
    return diary;
  }

  /// 移入回收站，保留 15 天。
  Future<void> deleteDiary(String id) async {
    final diary = getDiaryById(id);
    if (diary == null) return;
    await _trashBox!.put(
      id,
      TrashedDiary(diary: diary, deletedAt: DateTime.now()).toMap(),
    );
    await _box!.delete(id);
    notifyListeners();
    await WidgetBridgeService.instance.syncFromApp();
  }

  Future<void> restoreDiary(String id) async {
    final trashed = getTrashedById(id);
    if (trashed == null) return;
    await _box!.put(id, trashed.diary.toMap());
    await _trashBox!.delete(id);
    notifyListeners();
    await WidgetBridgeService.instance.syncFromApp();
  }

  Future<void> permanentlyDelete(String id) async {
    final trashed = getTrashedById(id);
    if (trashed == null) return;
    if (trashed.diary.images.isNotEmpty) {
      await DiaryImageStorage.instance.deleteImages(trashed.diary.images);
    }
    await _trashBox!.delete(id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final ids = _trashBox!.keys.cast<String>().toList();
    for (final id in ids) {
      await permanentlyDelete(id);
    }
  }

  Future<void> purgeExpiredTrash() async {
    if (_trashBox == null) return;
    final cutoff = DateTime.now().subtract(
      const Duration(days: diaryTrashRetentionDays),
    );
    final expired = trashedDiaries
        .where((t) => !t.deletedAt.isAfter(cutoff))
        .map((t) => t.diary.id)
        .toList();
    for (final id in expired) {
      await permanentlyDelete(id);
    }
  }
}
