import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

fs.copyFileSync(
  path.join(ROOT, 'tools/diary_detail_page.dart'),
  path.join(ROOT, 'lib/pages/diary_detail_page.dart'),
);
console.log('Copied diary_detail_page.dart');

const patches = {
  'lib/pages/echo_tree_page.dart': [
    ["              ? '???????????????????'", "              ? '雨露会随机漂在树周围，点能量泡就能收集'"],
    ["              : '?????? ? ?????????'", "              : '写回响得雨露 · 点能量泡收集后浇水'"],
    ["          '?????? 2 ? \uFFFD? ??????????'", "          '雨露最多保留 2 个 · 连续记录，雨露更丰沛'"],
    ["          '?????? 2 ? ? ??????????'", "          '雨露最多保留 2 个 · 连续记录，雨露更丰沛'"],
    ["label: lastCollected != null ? '????' : '雨露树',", "label: lastCollected != null ? '刚刚收集' : '已收集',"],
    ["                '已连续记下 ${service.writingStreak} 天',", "                '已连续记录 ${service.writingStreak} 天',"],
  ],
  'lib/pages/mood_bookshelf_page.dart': [
    ["                    '$year ? ${zodiac.label}?',", "                    '$year · ${zodiac.label}年',"],
    ["    return '$time ? $preview';", "    return '$time · $preview';"],
    ["                                    ? '这个月，${current.dominantEmoji} ${current.dominantLabel} 最多'", "                                    ? '这个月，${current.dominantEmoji} ${current.dominantLabel} 最常见'"],
    ["                                    : '空白的一页，等待被写入',", "                                    : '空白的一页，等待被写下',"],
    ["                  '${stats.diaryEntryCount > stats.diaryDayCount ? ' \uFFFD? ? ${stats.diaryEntryCount} ?' : ''}'", "                  '${stats.diaryEntryCount > stats.diaryDayCount ? ' · 共 ${stats.diaryEntryCount} 篇' : ''}'"],
    ["                  '${stats.diaryEntryCount > stats.diaryDayCount ? ' ? ? ${stats.diaryEntryCount} ?' : ''}'", "                  '${stats.diaryEntryCount > stats.diaryDayCount ? ' · 共 ${stats.diaryEntryCount} 篇' : ''}'"],
  ],
};

for (const [rel, pairs] of Object.entries(patches)) {
  const fp = path.join(ROOT, rel);
  let text = fs.readFileSync(fp, 'utf8');
  const orig = text;
  for (const [old, neu] of pairs) text = text.split(old).join(neu);
  // Fix dialog 取消/保存 buttons corrupted to ??
  text = text.replace(
    /onPressed: \(\) => Navigator\.pop\(context\),\s*\n\s*child: const Text\(\s*\n\s*'\?\?',/g,
    "onPressed: () => Navigator.pop(context),\n              child: const Text(\n                '取消',",
  );
  text = text.replace(
    /onPressed: \(\) => Navigator\.pop\(context, controller\.text\),\s*\n\s*child: const Text\(\s*\n\s*'\?\?',/g,
    "onPressed: () => Navigator.pop(context, controller.text),\n              child: const Text(\n                '保存',",
  );
  if (text !== orig) {
    fs.writeFileSync(fp, text, 'utf8');
    console.log('Patched', rel);
  }
}

// Verify unclosed strings
for (const rel of Object.keys(patches).concat(['lib/pages/diary_detail_page.dart', 'lib/pages/settings_page.dart'])) {
  const lines = fs.readFileSync(path.join(ROOT, rel), 'utf8').split('\n');
  const bad = [];
  for (let i = 0; i < lines.length; i++) {
    const l = lines[i];
    if (l.includes('\uFFFD')) bad.push(i + 1);
    if (/return '[^']*$/.test(l.trim()) || /message: '[^']*$/.test(l.trim())) bad.push(i + 1);
  }
  if (bad.length) console.log('BAD', rel, [...new Set(bad)].slice(0, 10));
  else console.log('OK', rel);
}
