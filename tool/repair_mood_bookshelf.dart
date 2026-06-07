import 'dart:convert';
import 'dart:io';

void repair(String path) {
  final file = File(path);
  final bytes = file.readAsBytesSync();
  try {
    utf8.decode(bytes);
    stdout.writeln('OK: $path');
    return;
  } catch (e) {
    stdout.writeln('Repairing $path: $e');
  }
  final text = utf8.decode(bytes, allowMalformed: true);
  file.writeAsStringSync(text, encoding: utf8);
}

void apply(String path, List<List<String>> pairs) {
  final file = File(path);
  var text = utf8.decode(file.readAsBytesSync());
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
  }
}

void main() {
  repair('lib/pages/mood_bookshelf_page.dart');

  apply('lib/pages/mood_bookshelf_page.dart', [
    ["/// ???? ? ??????????????", '/// 心情书架 · 可按年浏览，看见每个月的色调'],
    ["'?????'", "'为书架命名'"],
    ["'????'", "'恢复默认'"],
    ["'?????????????????'", "'写下的日子会在这里，排成一年的书架'"],
    ["? '??????????'", "? '这一年还没有写下回响'"],
    [": '\$_filledCount ????? ? ??????'", ": '\$_filledCount 个月有回响 · 轻触书脊翻阅'"],
    ["'\$year ? \${zodiac.label}?'", "'\$year · \${zodiac.label}座'"],
    ["'??????'", "'为这一册命名'"],
    ["hintText: '????????????'", "hintText: '如：春日絮语、雨夜独白…'"],
    [
      "message: '\${DiaryFormat.listDateLabel(day.date)} ? \${day.entryCount} ???'",
      "message: '\${DiaryFormat.listDateLabel(day.date)} · \${day.entryCount} 篇回响'",
    ],
    [
      "? '????\${current.dominantEmoji} \${current.dominantLabel} ??'",
      "? '这个月，\${current.dominantEmoji} \${current.dominantLabel} 最多'",
    ],
    [": '???????????'", ": '空白的一页，等待被写入'"],
    ["label: '??',", "label: '记下',"],
    ["'?????????'", "'还没有这一月的回响'"],
    ["'???????????????'", "'写下的日子会在这里变成心情月历'"],
    [
      "onPressed: () => Navigator.pop(context),\r\n              child: const Text(\r\n                '??',",
      "onPressed: () => Navigator.pop(context),\r\n              child: const Text(\r\n                '取消',",
    ],
    [
      "onPressed: () => Navigator.pop(context, controller.text),\r\n              child: const Text(\r\n                '??',",
      "onPressed: () => Navigator.pop(context, controller.text),\r\n              child: const Text(\r\n                '保存',",
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
}
