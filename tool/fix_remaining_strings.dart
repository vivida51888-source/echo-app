import 'dart:convert';
import 'dart:io';

void apply(String path, List<List<String>> pairs) {
  final file = File(path);
  var text = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
  var changed = false;
  for (final pair in pairs) {
    if (text.contains(pair[0])) {
      text = text.replaceAll(pair[0], pair[1]);
      changed = true;
    }
  }
  if (changed) {
    file.writeAsStringSync(text, encoding: utf8);
    stdout.writeln('Fixed $path');
  } else {
    stdout.writeln('No changes $path');
  }
}

void main() {
  apply('lib/pages/mood_bookshelf_page.dart', [
    [
      "onPressed: () => Navigator.pop(context),\r\n              child: const Text(\r\n                '??',",
      "onPressed: () => Navigator.pop(context),\r\n              child: const Text(\r\n                '取消',",
    ],
    [
      "onPressed: () => Navigator.pop(context, controller.text),\r\n              child: const Text(\r\n                '??',",
      "onPressed: () => Navigator.pop(context, controller.text),\r\n              child: const Text(\r\n                '保存',",
    ],
    [
      "message: '\${DiaryFormat.listDateLabel(day.date)} ? \${day.entryCount} ???',",
      "message: '\${DiaryFormat.listDateLabel(day.date)} · \${day.entryCount} 篇回响',",
    ],
    [
      "Text(\r\n            '??',\r\n            style: TextStyle(\r\n              fontSize: 36,",
      "Text(\r\n            '📖',\r\n            style: TextStyle(\r\n              fontSize: 36,",
    ],
    [
      "const Text(\r\n                  '恢复默认',\r\n                  style: TextStyle(\r\n                    fontSize: 18,",
      "const Text(\r\n                  '心情月历',\r\n                  style: TextStyle(\r\n                    fontSize: 18,",
    ],
    [
      "'记下 \${stats.diaryDayCount} 天'\r\n                  '\${stats.diaryEntryCount > stats.diaryDayCount ? ' ? ? \${stats.diaryEntryCount} ?' : ''}'\r\n                  ' ? ??????',",
      "'记下 \${stats.diaryDayCount} 天'\r\n                  '\${stats.diaryEntryCount > stats.diaryDayCount ? ' · 共 \${stats.diaryEntryCount} 篇' : ''}'\r\n                  ' · 点日期读回响',",
    ],
    [
      "const Text(\r\n            '恢复默认',\r\n            style: TextStyle(\r\n              fontSize: 16,",
      "const Text(\r\n            '心情分布',\r\n            style: TextStyle(\r\n              fontSize: 16,",
    ],
    [
      '/// ???????? ? ???????????',
      '/// 半屏打开心情书架 · 从统计页等入口快速翻阅',
    ],
  ]);

  apply('lib/pages/echo_tree_page.dart', [
    ["'?????? 2 ? ? ??????????'", "'雨露最多保留 2 份 · 连续记录，雨露更丰沛'"],
    ["_StatChip(label: '??', value: '\${growth.lifeWater}g'),", "_StatChip(label: '生命', value: '\${growth.lifeWater}g'),"],
    ["label: '雨露树',", "label: '待收露',"],
  ]);
}
