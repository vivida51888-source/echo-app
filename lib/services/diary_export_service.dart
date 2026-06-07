import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/diary.dart';
import '../utils/docx_builder.dart';
import 'diary_service.dart';
import 'todo_service.dart';

/// 回响导出：单篇 Word、批量 Word 压缩包、全量备份。
class DiaryExportService {
  DiaryExportService._();

  static final DiaryExportService instance = DiaryExportService._();

  static String exportDateStamp() =>
      DateFormat('yyyyMMdd').format(DateTime.now());

  static String _diaryBody(Diary diary) => diary.content;

  /// 单篇导出为 Word，文件名为导出当日 yyyyMMdd.docx。
  Future<void> shareDiaryWord(Diary diary) async {
    final stamp = exportDateStamp();
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, '$stamp.docx'));
    await file.writeAsBytes(DocxBuilder.build(_diaryBody(diary)));
    await Share.shareXFiles([XFile(file.path)]);
  }

  /// 时间范围内每篇日记一个 Word，打包为 yyyyMMdd.zip。
  Future<void> exportRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final diaries = DiaryService.instance.diaries.where((d) {
      final day = DateTime(d.createdAt.year, d.createdAt.month, d.createdAt.day);
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      return !day.isBefore(s) && !day.isAfter(e);
    }).toList();

    if (diaries.isEmpty) {
      throw StateError('该时间范围内没有回响');
    }

    final stamp = exportDateStamp();
    final dir = await getTemporaryDirectory();
    final exportDir = Directory(p.join(dir.path, 'echo_export_$stamp'));
    if (await exportDir.exists()) {
      await exportDir.delete(recursive: true);
    }
    await exportDir.create();

    final usedNames = <String>{};
    for (final diary in diaries) {
      final base = DateFormat('yyyyMMdd').format(diary.createdAt);
      var name = '$base.docx';
      var suffix = 2;
      while (usedNames.contains(name)) {
        name = '${base}_$suffix.docx';
        suffix++;
      }
      usedNames.add(name);

      await File(p.join(exportDir.path, name)).writeAsBytes(
        DocxBuilder.build(_diaryBody(diary)),
      );
    }

    final zipPath = p.join(dir.path, '$stamp.zip');
    await _zipDirectory(exportDir, zipPath);
    await exportDir.delete(recursive: true);
    await Share.shareXFiles([XFile(zipPath)]);
  }

  Future<void> exportFullArchive() async {
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final dir = await getTemporaryDirectory();
    final root = Directory(p.join(dir.path, 'echo_full_$stamp'));
    if (await root.exists()) await root.delete(recursive: true);
    await root.create();

    final diaries = DiaryService.instance.diaries;
    final diariesJson = diaries.map((d) => d.toMap()).toList();
    await File(p.join(root.path, 'diaries.json'))
        .writeAsString(jsonEncode(diariesJson));

    final todos = TodoService.instance.items;
    final todosJson = todos.map((t) => t.toMap()).toList();
    await File(p.join(root.path, 'todos.json'))
        .writeAsString(jsonEncode(todosJson));

    final imagesDir = Directory(p.join(root.path, 'images'));
    await imagesDir.create();
    for (final diary in diaries) {
      for (final img in diary.images) {
        final src = File(img);
        if (await src.exists()) {
          await src.copy(p.join(imagesDir.path, p.basename(img)));
        }
      }
    }

    final zipPath = p.join(dir.path, 'echo_full_$stamp.zip');
    await _zipDirectory(root, zipPath);
    await Share.shareXFiles([XFile(zipPath)]);
  }

  Future<void> _zipDirectory(Directory source, String zipPath) async {
    final archive = Archive();
    await for (final entity in source.list(recursive: true)) {
      if (entity is! File) continue;
      final rel = p.relative(entity.path, from: source.path);
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(rel, bytes.length, bytes));
    }
    await File(zipPath).writeAsBytes(ZipEncoder().encode(archive));
  }
}
