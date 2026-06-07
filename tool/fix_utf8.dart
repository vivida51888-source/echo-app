import 'dart:convert';
import 'dart:io';

void main() {
  final fixes = <String, List<List<String>>>{
    'pages/echo_tree_page.dart': [
      ['/// ????????????????????', '/// 雨露树主体（全页与「回响」页内嵌共用）。'],
      ["'???',", "'雨露树',"],
      ["? '???????????????????'", "? '雨露会随机漂在树周围，点能量泡就能收集'"],
      [": '?????? � ?????????',", ": '写回响得雨露 · 点能量泡收集后浇水',"],
      [": '?????? ? ?????????',", ": '写回响得雨露 · 点能量泡收集后浇水',"],
      ["'?????? 2 ? � ??????????'", "'雨露最多保留 2 份 · 连续记录，雨露更丰沛'"],
      ["'?? ????',", "'💧 浇水中…',"],
      ["'?????????',", "'轻点能量泡收集雨露',"],
      ["'????? \${service.writingStreak} ?',", "'已连续记下 \${service.writingStreak} 天',"],
      ["_StatChip(label: '??', value: '\${service.uniqueDiaryDays} ?'),", "_StatChip(label: '记下', value: '\${service.uniqueDiaryDays} 天'),"],
      ["_StatChip(label: '??', value: '\${service.totalEntries} ?'),", "_StatChip(label: '回响', value: '\${service.totalEntries} 篇'),"],
      ["label: '???',", "label: '待收露',"],
      ["label: lastCollected != null ? '????' : '???',", "label: lastCollected != null ? '刚刚收集' : '已收下',"],
      ["label: lastCollected != null ? '????' : '雨露树',", "label: lastCollected != null ? '刚刚收集' : '已收下',"],
      ["label: canCollect ? '????' : '????',", "label: canCollect ? '收集雨露' : '暂无雨露',"],
      ["label: canWater ? '?? \${service.storedWater}g' : '?????',", "label: canWater ? '浇水 \${service.storedWater}g' : '先收集雨露',"],
      ["'?? \${((progress * 100).round())}%'", "'生长 \${((progress * 100).round())}%'"],
    ],
    'pages/mood_bookshelf_page.dart': [
      ['/// ???? � ??????????????', '/// 心情书架 · 可按年浏览，看见每个月的色调'],
      ['/// ???? ? ??????????????', '/// 心情书架 · 可按年浏览，看见每个月的色调'],
      ["'?????'", "'为书架命名'"],
      ["'????'", "'恢复默认'"],
      ["'?????????????????'", "'写下的日子会在这里，排成一年的书架'"],
      ["? '??????????'", "? '这一年还没有写下回响'"],
      [": '\$_filledCount ????? � ??????'", ": '\$_filledCount 个月有回响 · 轻触书脊翻阅'"],
      [": '\$_filledCount ????? ? ??????'", ": '\$_filledCount 个月有回响 · 轻触书脊翻阅'"],
      ["'\$year ? \${zodiac.label}?',", "'\$year · \${zodiac.label}年',"],
      ["'??????'", "'为这一册命名'"],
      ["hintText: '????????????',", "hintText: '如：春日絮语、雨夜独白…',"],
      ["message: '\${DiaryFormat.listDateLabel(day.date)} � \${day.entryCount} ???',", "message: '\${DiaryFormat.listDateLabel(day.date)} · \${day.entryCount} 篇回响',"],
      ["? '????\${current.dominantEmoji} \${current.dominantLabel} ??'", "? '这个月，\${current.dominantEmoji} \${current.dominantLabel} 最多'"],
      [": '???????????',", ": '空白的一页，等待被写入',"],
      ["label: '??',", "label: '记下',"],
      ["value: '\${stats.diaryDayCount} ?',", "value: '\${stats.diaryDayCount} 天',"],
      ["'?????????'", "'还没有这一月的回响'"],
      ["'???????????????'", "'写下的日子会在这里变成心情月历'"],
      ["'????'", "'心情月历'"],
      ["'?? \${stats.diaryDayCount} ?'", "'记下 \${stats.diaryDayCount} 天'"],
      ["' � ? \${stats.diaryEntryCount} ?'", "' · 共 \${stats.diaryEntryCount} 篇'"],
      ["' � ??????'", "' · 点日期读回响'"],
      ["'????'", "'心情分布'"],
      ['/// ???????? � ???????????', '/// 半屏打开心情书架 · 从统计页等入口快速翻阅'],
      ["return '\$time ? \$preview';", "return '\$time · \$preview';"],
    ],
    'pages/diary_detail_page.dart': [
      ["'???????',", "'这篇回响已不在',"],
      ["EchoActionSheetItem(label: '??', value: 'edit'),", "EchoActionSheetItem(label: '编辑', value: 'edit'),"],
      ["label: '??',", "label: '删除',"],
      ["message: '???????',", "message: '删除这篇回响？',"],
    ],
    'pages/settings_page.dart': [
      ["subtitle: '纸色 · 当前\$name',", "subtitle: '纸色调 · 当前\$name',"],
    ],
  };

  final moodButtons = [
    [
      "onPressed: () => Navigator.pop(context),\n              child: const Text(\n                '??',",
      "onPressed: () => Navigator.pop(context),\n              child: const Text(\n                '取消',",
    ],
    [
      "onPressed: () => Navigator.pop(context, controller.text),\n              child: const Text(\n                '??',",
      "onPressed: () => Navigator.pop(context, controller.text),\n              child: const Text(\n                '保存',",
    ],
  ];

  for (final entry in fixes.entries) {
    final file = File('lib/${entry.key}');
    if (!file.existsSync()) {
      stdout.writeln('Missing ${entry.key}');
      continue;
    }
    var text = utf8.decode(file.readAsBytesSync(), allowMalformed: true);
    final orig = text;
    for (final pair in entry.value) {
      if (text.contains(pair[0])) {
        text = text.replaceAll(pair[0], pair[1]);
      }
    }
    if (entry.key == 'pages/mood_bookshelf_page.dart') {
      for (final pair in moodButtons) {
        text = text.replaceAll(pair[0], pair[1]);
      }
    }
    if (text != orig) {
      file.writeAsStringSync(text, encoding: utf8);
      stdout.writeln('Fixed ${entry.key}');
    } else {
      stdout.writeln('No changes ${entry.key}');
    }
  }
}
