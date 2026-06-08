import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/photo_wall_frame_style.dart';
import '../models/photo_wall_material.dart';

enum PhotoWallViewMode { week, month }

class PhotoWallSettingsService extends ChangeNotifier {
  PhotoWallSettingsService._();

  static final PhotoWallSettingsService instance = PhotoWallSettingsService._();

  static const _boxName = 'echo_photo_wall_settings';
  static const _materialKey = 'material';
  static const _pinSoundKey = 'pin_sound';
  static const _seenPathsKey = 'seen_pin_paths';
  static const _seenByScopeKey = 'seen_pin_by_scope';
  static const _customWallKey = 'custom_wall_path';
  static const _posterCaptionKey = 'poster_caption';
  static const _viewModeKey = 'view_mode';
  static const _viewAnchorKey = 'view_anchor';
  static const _showDatesKey = 'show_dates';
  static const _frameStyleKey = 'frame_style';
  /// 切到胶片前保存的拍立得墙面，切回时恢复。
  static const _polaroidMaterialKey = 'polaroid_material';

  Box<dynamic>? _box;
  bool _ready = false;

  bool get isReady => _ready;

  PhotoWallMaterial _storedMaterial() =>
      PhotoWallMaterial.fromName(_box?.get(_materialKey) as String? ?? '');

  bool _isFilmWallMaterial(PhotoWallMaterial value) =>
      PhotoWallMaterial.filmWall.contains(value);

  PhotoWallMaterial _filmMaterial() {
    final stored = _storedMaterial();
    if (_isFilmWallMaterial(stored)) return stored;
    return PhotoWallMaterial.negative25;
  }

  PhotoWallMaterial _polaroidMaterialFallback() {
    final backupRaw = _box?.get(_polaroidMaterialKey) as String?;
    final backup = backupRaw == null || backupRaw.isEmpty
        ? PhotoWallMaterial.plain
        : PhotoWallMaterial.fromName(backupRaw);
    if (backupRaw != null &&
        backupRaw.isNotEmpty &&
        !_isFilmWallMaterial(backup)) {
      return backup;
    }
    final stored = _storedMaterial();
    if (!_isFilmWallMaterial(stored)) return stored;
    return PhotoWallMaterial.plain;
  }

  PhotoWallMaterial get material {
    if (frameStyle == PhotoWallFrameStyle.filmStrip) {
      return _filmMaterial();
    }
    return _polaroidMaterialFallback();
  }

  String? get customWallPath {
    final path = _box?.get(_customWallKey) as String?;
    if (path == null || path.isEmpty) return null;
    if (!kIsWeb && !File(path).existsSync()) return null;
    return path;
  }

  String get materialDisplayLabel {
    if (frameStyle == PhotoWallFrameStyle.filmStrip) {
      return _filmMaterial().localizedLabel;
    }
    if (material.isCustom && customWallPath != null) {
      return PhotoWallMaterial.custom.localizedLabel;
    }
    return material.localizedLabel;
  }

  String get posterCaption => _box?.get(_posterCaptionKey) as String? ?? '';

  /// 留影页 / Hub 预览共用的按周·按月与当前定位。
  PhotoWallViewMode get viewMode {
    final raw = _box?.get(_viewModeKey) as String?;
    return raw == 'month' ? PhotoWallViewMode.month : PhotoWallViewMode.week;
  }

  DateTime get viewAnchor {
    final raw = _box?.get(_viewAnchorKey) as String?;
    if (raw != null) {
      try {
        return DateTime.parse(raw);
      } catch (_) {}
    }
    return DateTime.now();
  }

  Future<void> setViewState({
    required PhotoWallViewMode mode,
    required DateTime anchor,
  }) async {
    if (_box == null) return;
    await _box!.put(
      _viewModeKey,
      mode == PhotoWallViewMode.month ? 'month' : 'week',
    );
    await _box!.put(_viewAnchorKey, anchor.toIso8601String());
    notifyListeners();
  }

  Future<void> setPosterCaption(String value) async {
    await _box?.put(_posterCaptionKey, value.trim());
    notifyListeners();
  }

  bool get pinSoundEnabled =>
      _box?.get(_pinSoundKey, defaultValue: true) as bool? ?? true;

  bool get showPhotoDates =>
      _box?.get(_showDatesKey, defaultValue: true) as bool? ?? true;

  PhotoWallFrameStyle get frameStyle => PhotoWallFrameStyle.fromName(
        _box?.get(_frameStyleKey) as String?,
      );

  String get frameStyleLabel => frameStyle.localizedLabel;

  Future<void> setShowPhotoDates(bool value) async {
    await _box?.put(_showDatesKey, value);
    notifyListeners();
  }

  Future<void> setFrameStyle(PhotoWallFrameStyle value) async {
    if (_box == null) return;
    final stored = _storedMaterial();
    await _box!.put(_frameStyleKey, value.storageName);
    if (value == PhotoWallFrameStyle.filmStrip) {
      if (!_isFilmWallMaterial(stored)) {
        await _box!.put(_polaroidMaterialKey, stored.name);
      }
      if (!_isFilmWallMaterial(_storedMaterial())) {
        await _box!.put(_materialKey, PhotoWallMaterial.negative25.name);
      }
    } else {
      final restore = _polaroidMaterialFallback();
      await _box!.put(_materialKey, restore.name);
    }
    notifyListeners();
  }

  Set<String> get seenPinPaths {
    final raw = _box?.get(_seenPathsKey);
    if (raw is List) {
      return raw.whereType<String>().toSet();
    }
    return {};
  }

  bool isPinSeen(String path) => seenPinPaths.contains(path);

  Map<String, Set<String>> get seenPinPathsByScope {
    final raw = _box?.get(_seenByScopeKey);
    if (raw is! Map) return {};
    final map = <String, Set<String>>{};
    raw.forEach((key, value) {
      if (key is! String || value is! List) return;
      map[key] = value.whereType<String>().toSet();
    });
    return map;
  }

  bool isPinSeenInScope(String path, String scope) {
    if (seenPinPathsByScope[scope]?.contains(path) ?? false) return true;
    // 旧版全局记录仅视为已在留影详情播放过。
    return scope == 'wall' && isPinSeen(path);
  }

  Future<void> markPinSeen(String path) async {
    final next = {...seenPinPaths, path};
    await _box?.put(_seenPathsKey, next.toList());
  }

  Future<void> markPinSeenInScope(String path, String scope) async {
    if (_box == null) return;
    final raw = Map<dynamic, dynamic>.from(
      (_box!.get(_seenByScopeKey) as Map?) ?? {},
    );
    final current = (raw[scope] as List?)?.whereType<String>().toSet() ?? {};
    raw[scope] = [...current, path].toList();
    await _box!.put(_seenByScopeKey, raw);
    if (scope == 'wall') {
      await markPinSeen(path);
    }
  }

  Future<void> init() async {
    if (_ready) return;
    _box = await Hive.openBox<dynamic>(_boxName);
    // 拖拽钉墙已移除，清掉历史偏移让照片回到默认布局。
    await _box!.delete('pin_offsets');
    _ready = true;
    notifyListeners();
  }

  Future<void> setMaterial(PhotoWallMaterial value) async {
    if (_box == null) return;
    await _box!.put(_materialKey, value.name);
    if (frameStyle != PhotoWallFrameStyle.filmStrip &&
        !_isFilmWallMaterial(value)) {
      await _box!.put(_polaroidMaterialKey, value.name);
    }
    notifyListeners();
  }

  Future<void> setPinSoundEnabled(bool value) async {
    await _box?.put(_pinSoundKey, value);
    notifyListeners();
  }

  Future<bool> pickAndSetCustomWall() async {
    if (kIsWeb) return false;

    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 88,
    );
    if (file == null) return false;

    try {
      final path = await _persistCustomWall(file);
      await _box?.put(_customWallKey, path);
      await _box?.put(_materialKey, PhotoWallMaterial.custom.name);
      if (frameStyle != PhotoWallFrameStyle.filmStrip) {
        await _box?.put(_polaroidMaterialKey, PhotoWallMaterial.custom.name);
      }
      notifyListeners();
      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PhotoWallSettingsService.pickAndSetCustomWall: $e\n$st');
      }
      return false;
    }
  }

  Future<String> _persistCustomWall(XFile file) async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'photo_wall'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }

    final oldPath = _box?.get(_customWallKey) as String?;
    if (oldPath != null && oldPath.isNotEmpty) {
      final old = File(oldPath);
      if (await old.exists()) {
        await old.delete();
      }
    }

    final ext = p.extension(file.path);
    final normalizedExt = ext.isEmpty ? '.jpg' : ext.toLowerCase();
    final target = p.join(
      folder.path,
      'custom_${DateTime.now().microsecondsSinceEpoch}$normalizedExt',
    );
    await File(target).writeAsBytes(await file.readAsBytes(), flush: true);
    return target;
  }
}
