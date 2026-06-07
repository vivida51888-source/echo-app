import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const ROOT = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');

function corrupted(text) {
  return text.includes("return '????") || text.includes("title: '??") || text.includes("'???'") || text.includes('????????');
}

for (const [src, dest] of [
  ['tools/settings_page.dart', 'lib/pages/settings_page.dart'],
  ['tools/diary_detail_page.dart', 'lib/pages/diary_detail_page.dart'],
]) {
  const target = path.join(ROOT, dest);
  const text = fs.readFileSync(target, 'utf8');
  if (corrupted(text)) {
    fs.copyFileSync(path.join(ROOT, src), target);
    console.log('Copied', dest);
  }
}

const echoFixes = [
  ['/// ??????????????????????', '/// 回响之树主体（全页与「回响」页内嵌共用）。'],
  ["            '???',", "            '雨露树',"],
  ["              ? '????????????????????", "              ? '雨露会随机漂在树周围，点能量泡就能收集'"],
  ["              : '?????? \uFFFD? ??????????,", "              : '写回响得雨露 · 点能量泡收集后浇水',"],
  ["              : '?????? ? ??????????,", "              : '写回响得雨露 · 点能量泡收集后浇水',"],
  ["          '???????2 ??\uFFFD? ??????????'", "          '雨露最多保留 2 个 · 连续记录，雨露更丰沛'"],
  ["          '???????2 ?? ? ??????????'", "          '雨露最多保留 2 个 · 连续记录，雨露更丰沛'"],
  ["                          '?? ?????,", "                          '💧 浇水中…',"],
  ["                          '??????????,", "                          '轻点能量泡收集雨露',"],
  ["                '??????${service.writingStreak} ??,", "                '已连续记录 ${service.writingStreak} 天',"],
  ["_StatChip(label: '??', value: '${service.uniqueDiaryDays} ??),", "_StatChip(label: '记下', value: '${service.uniqueDiaryDays} 天'),"],
  ["_StatChip(label: '??', value: '${service.totalEntries} ??),", "_StatChip(label: '回响', value: '${service.totalEntries} 篇'),"],
  ["_StatChip(label: '????', value: '${growth.lifeWater}g'),", "_StatChip(label: '累计雨露', value: '${growth.lifeWater}g'),"],
  ["            label: '????,", "            label: '待收集',"],
  ["            label: lastCollected != null ? '????' : '????,", "            label: lastCollected != null ? '刚刚收集' : '已收集',"],
  ["            label: canCollect ? '????' : '????',", "            label: canCollect ? '收集雨露' : '暂无雨露',"],
  ["            label: canWater ? '?? ${service.storedWater}g' : '??????,", "            label: canWater ? '浇水 ${service.storedWater}g' : '先收集雨露',"],
  ["            '????${((progress * 100).round())}%'", "            '本阶段 ${((progress * 100).round())}%'"],
];

const echoPath = path.join(ROOT, 'lib/pages/echo_tree_page.dart');
let echo = fs.readFileSync(echoPath, 'utf8');
if (corrupted(echo)) {
  for (const [old, neu] of echoFixes) echo = echo.split(old).join(neu);
  fs.writeFileSync(echoPath, echo, 'utf8');
  console.log('Patched echo_tree_page.dart');
}

const statsPath = path.join(ROOT, 'lib/pages/stats_page.dart');
let stats = fs.readFileSync(statsPath, 'utf8');
const statsOrig = stats;
stats = stats.replace(/return '\$\{parts\.join\('.*?'\)\}.*?;/, "return '${parts.join('；')}。';");
stats = stats.replace('分类色条\uFFFD?', '分类色条。');
if (stats !== statsOrig) {
  fs.writeFileSync(statsPath, stats, 'utf8');
  console.log('Patched stats_page.dart');
}

const idPath = path.join(ROOT, 'lib/pages/important_days_page.dart');
let id = fs.readFileSync(idPath, 'utf8');
const idOrig = id;
id = id.split("'编辑重要\uFFFD? : '添加重要日'").join("'编辑重要日' : '添加重要日'");
if (id !== idOrig) {
  fs.writeFileSync(idPath, id, 'utf8');
  console.log('Patched important_days_page.dart');
}

const mbPath = path.join(ROOT, 'lib/pages/mood_bookshelf_page.dart');
let mb = fs.readFileSync(mbPath, 'utf8');
const mbOrig = mb;
mb = mb.replace(/\/\/\/ .*showMoodBookshelfSheet/, '/// 「此刻 · 回看过去」弹层：展示心情之书书架。');
// Fix calendar subtitle lines if still broken
mb = mb.split("'记下 ${stats.diaryDayCount} \uFFFD?").join("'记下 ${stats.diaryDayCount} 天'");
mb = mb.split("? ' · \uFFFD?${stats.diaryEntryCount} \uFFFD? : ''}'").join("? ' · 共 ${stats.diaryEntryCount} 篇' : ''}'");
if (mb !== mbOrig) {
  fs.writeFileSync(mbPath, mb, 'utf8');
  console.log('Patched mood_bookshelf_page.dart');
}

for (const rel of [
  'lib/pages/settings_page.dart',
  'lib/pages/mood_bookshelf_page.dart',
  'lib/pages/echo_tree_page.dart',
  'lib/pages/stats_page.dart',
]) {
  const t = fs.readFileSync(path.join(ROOT, rel), 'utf8');
  const bad = t.split('\n').map((l, i) => (l.includes('\uFFFD') || (l.includes('??') && l.includes("'"))) ? i + 1 : 0).filter(Boolean);
  if (bad.length) console.log('CHECK', rel, bad.slice(0, 6));
}
