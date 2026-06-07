import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 将图片复制到应用私有目录，重启后仍可访问。
class DiaryImageStorage {
  DiaryImageStorage._();

  static final DiaryImageStorage instance = DiaryImageStorage._();

  Future<String> get _root async {
    final dir = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(dir.path, 'diary_images'));
    if (!await folder.exists()) {
      await folder.create(recursive: true);
    }
    return folder.path;
  }

  Future<String> persistImage(XFile file, String diaryId) async {
    final root = await _root;
    final ext = p.extension(file.path);
    final normalizedExt = ext.isEmpty ? '.jpg' : ext.toLowerCase();
    final target = p.join(
      root,
      '${diaryId}_${DateTime.now().microsecondsSinceEpoch}$normalizedExt',
    );

    final bytes = await file.readAsBytes();
    await File(target).writeAsBytes(bytes, flush: true);
    return target;
  }

  Future<List<String>> persistImages(
    List<XFile> files,
    String diaryId,
    List<String> existingPaths,
  ) async {
    final paths = List<String>.from(existingPaths);
    for (final file in files) {
      if (paths.length >= 9) break;
      try {
        paths.add(await persistImage(file, diaryId));
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('DiaryImageStorage.persistImage failed: $e\n$st');
        }
      }
    }
    return paths;
  }

  Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      if (path.trim().isEmpty) continue;
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('DiaryImageStorage.deleteImages failed: $path $e\n$st');
        }
      }
    }
  }
}
