import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('lib/pages/mood_bookshelf_page.dart');
  var text = utf8.decode(file.readAsBytesSync());

  final pairs = <List<String>>[
    '/// ???? ? ??????????????', '/// 心情书架 · 可按年浏览，看见每个月的色调',
    "'?????'", "'为书架命名'",
    "'????'", "'恢复默认'",
    "'?????????????????'", "'写下的日子会在这里，排成一年的书架'",
    "? '??????????'", "? '这一年还没有写下回响'",
    ": '\$_filledCount ????? ? ??????'", ": '\$_filledCount 个月有回响 · 轻触书脊翻阅'",
    "'\$year ? \${zodiac.label}?'", "'\$year · \${zodiac.label}座'",
    "'??????'", "'为这一册命名'",
    "hintText: '????????????',", "hintText: '如：春日絮语、雨夜独白…',",
    "? '????\${current.dominantEmoji} \${current.dominantLabel} ??'", "? '这个月，\${current.dominantEmoji} \${current.dominantLabel} 最多'",
    ": '???????????',", ": '空白的一页，等待被写入',",
    "label: '??',", "label: '记下',",
    "'?????????'", "'还没有这一月的回响'",
    "'???????????????'", "'写下的日子会在这里变成心情月历'",
    "'????'", "'心情月历'",
    "'?? \${stats.diaryDayCount} ?'", "'记下 \${stats.diaryDayCount} 天'",
    "' ? ? \${stats.diaryEntryCount} ?'", "' · 共 \${stats.diaryEntryCount} 篇'",
    "' ? ??????'", "' · 点日期读回响'",
    "'????'", "'心情分布'",
    '/// ???????? ? ???????????', '/// 半屏打开心情书架 · 从统计页等入口快速翻阅',
    "'??'", "'取消'",
  ];

  // Apply longer patterns first; cancel/save need ordered passes
  for (final pair in pairs) {
    if (text.contains(pair[0])) {
      text = text.replaceAll(pair[0], pair[1]);
    }
  }

  // Second pass: remaining save buttons (after cancel replaced all ??)
  text = text.replaceAll(
    "onPressed: () => Navigator.pop(context, controller.text),\n              child: const Text(\n                '取消',",
    "onPressed: () => Navigator.pop(context, controller.text),\n              child: const Text(\n                '保存',",
  );

  text = text.replaceAll(
    "message: '\${DiaryFormat.listDateLabel(day.date)} ? \${day.entryCount} ???',",
    "message: '\${DiaryFormat.listDateLabel(day.date)} · \${day.entryCount} 篇回响',",
  );

  text = text.replaceAll(
    "child: Column(\n        children: [\n          Text(\n            '取消',",
    "child: Column(\n        children: [\n          Text(\n            '📖',",
  );

  file.writeAsStringSync(text, encoding: utf8);
  stdout.writeln('Fixed mood_bookshelf_page.dart');
}
