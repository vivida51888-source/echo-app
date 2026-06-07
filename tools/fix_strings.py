# -*- coding: utf-8 -*-
"""Restore corrupted Chinese strings in lib/ Dart files."""
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

# Per-file exact substring replacements (old, new)
FILE_FIXES: dict[str, list[tuple[str, str]]] = {
    "lib/pages/diary_list_page.dart": [
        ("if (count == 0) return '还没有留下文字，去此刻写下第一\uFFFD?;", "if (count == 0) return '还没有留下文字，去此刻写下第一篇';"),
        ("return '\uFFFD?$count \uFFFD?· 时间轴、按月与按周浏览';", "return '共 $count 篇 · 时间轴、按月与按周浏览';"),
        ("个雨露待\uFFFD?;", "个雨露待收';"),
        ("得雨\uFFFD?;", "得雨露';"),
        ("件待\uFFFD?;", "件待办';"),
        ("return '\uFFFD?$_photoCount \uFFFD?· 本周 $weekPhotos \uFFFD?;", "return '共 $_photoCount 张 · 本周 $weekPhotos 张';"),
        ("return '\uFFFD?$_photoCount 张拍立得';", "return '共 $_photoCount 张拍立得';"),
        ("title: '雨露\uFFFD?,", "title: '雨露树',"),
        ("风格与设置页一致\uFFFD?", "风格与设置页一致。"),
    ],
    "lib/pages/settings_page.dart": [
        ("title: '印记 · 重要\uFFFD?,", "title: '印记 · 重要日',"),
        ("subtitle: '生日、纪念日\uFFFD?Echo 会轻轻记\uFFFD?,", "subtitle: '生日、纪念日… Echo 会轻轻记得',"),
        ("title: '待办\uFFFD?AI 洞察',", "title: '待办 · AI 洞察',"),
        ("title: '数据与隐\uFFFD?,", "title: '数据与隐私',"),
        ("subtitle: '纸色\uFFFD?· 当前$name',", "subtitle: '纸色 · 当前$name',"),
    ],
    "lib/pages/mood_bookshelf_page.dart": [
        ("弹层共用）\uFFFD?", "弹层共用）。"),
        ("'为书架命\uFFFD?,", "'为书架命名',"),
        ("有回\uFFFD?· 轻触书脊翻阅", "有回响 · 轻触书脊翻阅"),
        ("'$year · ${zodiac.label}\uFFFD?,", "'$year · ${zodiac.label}年',"),
        ("'如：春日絮语、雨夜独白\uFFFD?,", "'如：春日絮语、雨夜独白…',"),
        ("listDateLabel(day.date)} \uFFFD?${day.entryCount} 篇回\uFFFD?,", "listDateLabel(day.date)} · ${day.entryCount} 篇回响',"),
        ("最\uFFFD?", "最常见'"),
        ("'空白的一页，等待被写\uFFFD?,", "'空白的一页，等待被写下',"),
        ("value: '${stats.diaryDayCount} \uFFFD?,", "value: '${stats.diaryDayCount} 天',"),
        ("'写下的日子会在这里变成心情月\uFFFD?,", "'写下的日子会在这里变成心情月历',"),
        ("'记下 ${stats.diaryDayCount} \uFFFD?", "'记下 ${stats.diaryDayCount} 天'"),
        ("? ' · \uFFFD?${stats.diaryEntryCount} \uFFFD? : ''}'", "? ' · 共 ${stats.diaryEntryCount} 篇' : ''}'"),
        ("「此\uFFFD?· 回看过去」", "「此刻 · 回看过去」"),
        ("书架\uFFFD?", "书架。"),
    ],
    "lib/pages/echo_records_page.dart": [
        ("'记下 ${insight.entryCount} 次回\uFFFD?);", "'记下 ${insight.entryCount} 次回响');"),
        ("'待办完成 ${todos.completedCount} \uFFFD?);", "'待办完成 ${todos.completedCount} 件');"),
        ("message: '删除这篇回响\uFFFD?,", "message: '删除这篇回响？',"),
        ("'那些被留下来的时\uFFFD?,", "'那些被留下来的时光',"),
        ("? '记下 $monthCount \uFFFD?", "? '记下 $monthCount 篇'"),
        ("_tab('时间\uFFFD?, _EchoListMode.all),", "_tab('时间轴', _EchoListMode.all),"),
    ],
    "lib/pages/echo_tree_page.dart": [
        ("页内嵌共用）\uFFFD?", "页内嵌共用）。"),
        ("'雨露\uFFFD?,", "'雨露树',"),
        ("点能量泡就能收\uFFFD?", "点能量泡就能收集'"),
        ("收集后浇\uFFFD?,", "收集后浇水',"),
        ("'雨露最多保\uFFFD?2 \uFFFD?· 连续记录", "'雨露最多保留 2 个 · 连续记录"),
        ("'💧 浇水中\uFFFD?,", "'💧 浇水中…',"),
        ("'轻点能量泡收集雨\uFFFD?,", "'轻点能量泡收集雨露',"),
        ("'已连续记\uFFFD?${service.writingStreak} \uFFFD?,", "'已连续记录 ${service.writingStreak} 天',"),
        ("'${service.uniqueDiaryDays} \uFFFD?),", "'${service.uniqueDiaryDays} 天'),"),
        ("'${service.totalEntries} \uFFFD?),", "'${service.totalEntries} 篇'),"),
        ("label: '待收\uFFFD?,", "label: '待收集',"),
        ("'刚刚收集' : '已收\uFFFD?,", "'刚刚收集' : '已收集',"),
        ("'先收集雨\uFFFD?,", "'先收集雨露',"),
        ("'本阶\uFFFD?${", "'本阶段 ${"),
    ],
    "lib/pages/photo_wall_page.dart": [
        ("独立页与后续内嵌共用）\uFFFD?", "独立页与后续内嵌共用）。"),
        ("'保存失败，请检查相册权\uFFFD?,", "'保存失败，请检查相册权限',"),
        ("留在文字\uFFFD?;", "留在文字里';"),
        ("留在了文字\uFFFD?;", "留在了文字里';"),
        ("留下了一张画\uFFFD?;", "留下了一张画面';"),
        ("? '本周照片\uFFFD? : '本月照片\uFFFD?", "? '本周照片墙' : '本月照片墙'"),
        ("'长按翻转 · 点正面放\uFFFD?;", "'长按翻转 · 点正面放大';"),
        ("会讲故事的\uFFFD?,", "会讲故事的墙',"),
        ("? '保存中\uFFFD? : '保存海报'", "? '保存中…' : '保存海报'"),
        ("有什么不\uFFFD?,", "有什么不同',"),
        ("'钉墙音效\uFFFD?,", "'钉墙音效关',"),
        ("在 2\uFFFD? / 4\uFFFD? / 7+ 基础上", "在 2张 / 4张 / 7+ 基础上"),
        ("按约 4 倍类\uFFFD?", "按约 4 倍类比"),
    ],
    "lib/pages/stats_page.dart": [
        ("心情地\uFFFD?+ 轻量待办\uFFFD?", "心情地图 + 轻量待办。"),
        ("页内嵌共用）\uFFFD?", "页内嵌共用）。"),
        ("listDateLabel(day.date)} \uFFFD?${day.entryCount} 篇回\uFFFD?,", "listDateLabel(day.date)} · ${day.entryCount} 篇回响',"),
        ("回看心情旅\uFFFD?", "回看心情旅程'"),
        ("? '这一\uFFFD? : '这个\uFFFD?", "? '这一周' : '这一月'"),
        ("轻轻记下约\uFFFD?;", "轻轻记下约定';"),
        ("还没标记天\uFFFD?);", "还没标记天气');"),
        ("'安放\uFFFD?${stats.todoCompleted} 件约\uFFFD?);", "'安放了 ${stats.todoCompleted} 件约定');"),
        ("'完成\uFFFD?${stats.todoCompleted} 件轻量待\uFFFD?);", "'完成了 ${stats.todoCompleted} 件轻量待办');"),
        ("return '${parts.join('\uFFFD?)} \uFFFD?;", "return '${parts.join('；')}。';"),
        ("todoScheduled} \uFFFD?;", "todoScheduled} 件';"),
        (": '已安\uFFFD?,", ": '已安放',"),
        ("% 的约\uFFFD?", "% 的约定'"),
        ("'$span安放\uFFFD?${stats.todoCompleted} \uFFFD?,", "'$span安放了 ${stats.todoCompleted} 件',"),
        ("待办概况\uFFFD?", "待办概况。"),
    ],
    "lib/pages/diary_detail_page.dart": [
        ("'这篇回响已不\uFFFD?,", "'这篇回响已不在了',"),
        ("message: '删除这篇回响\uFFFD?,", "message: '删除这篇回响？',"),
    ],
    "lib/pages/future_letters_page.dart": [
        ("将无法找回\uFFFD?,", "将无法找回。',"),
        ("'送达提醒\uFFFD?,", "'送达提醒关',"),
        ("_SectionLabel('封存\uFFFD?),", "_SectionLabel('封存中'),"),
        ("_SectionLabel('已拆\uFFFD?),", "_SectionLabel('已拆开'),"),
        ("'封存中的\uFFFD?,", "'封存中的信',"),
        ("helpText: '选择送达\uFFFD?,", "helpText: '选择送达日',"),
        ("? '封存中\uFFFD? : '封存'", "? '封存中…' : '封存'"),
        ("'写给未来的自\uFFFD?,", "'写给未来的自己',"),
        ("'想对未来的自己说什么\uFFFD?,", "'想对未来的自己说什么…',"),
        ("? '自选日\uFFFD?", "? '自选日期'"),
    ],
    "lib/pages/important_days_page.dart": [
        ("message: '删除\uFFFD?{day.title}」？", "message: '删除「${day.title}」？"),
        ("提醒这一天\uFFFD?,", "提醒这一天。',"),
        ("'添加重要\uFFFD?,", "'添加重要日',"),
        ("title: '还没有印\uFFFD?,", "title: '还没有印记',"),
        ("和「此刻」轻轻相\uFFFD?,", "和「此刻」轻轻相遇',"),
        ("                '\uFFFD?,", "                '天',"),
        ("                unit: '\uFFFD?,", "                unit: '年',"),
        ("                  unit: '\uFFFD?,", "                  unit: '天',"),
        ("'整周\uFFFD?,", "'整周年',"),
        ("'${metric.month} \uFFFD?,", "'${metric.month} 月',"),
        ("? '选择起点\uFFFD? : '选择日期'", "? '选择起点日' : '选择日期'"),
        ("'请写一个名\uFFFD?,", "'请写一个名字',"),
        ("'至少选一种提醒方\uFFFD?,", "'至少选一种提醒方式',"),
        ("? '编辑重要\uFFFD? : '添加重要\uFFFD?,", "? '编辑重要日' : '添加重要日',"),
        ("'例如：入职、结婚、相\uFFFD?", "'例如：入职、结婚、相识'"),
        ("到刻度时提\uFFFD?", "到刻度时提醒'"),
        ("循环提\uFFFD?,", "循环提醒',"),
        ("? '起点\uFFFD? : '日期'", "? '起点日' : '日期'"),
        ("（可算第几年\uFFFD?,", "（可算第几年）',"),
        ("'每年循环，早\uFFFD?9:00 轻轻唤起'", "'每年循环，早上 9:00 轻轻唤起'"),
        ("'只给自己看，不会出现在通知\uFFFD?,", "'只给自己看，不会出现在通知里',"),
    ],
    "lib/pages/todo_edit_page.dart": [
        ("才能收到温柔提\uFFFD?,", "才能收到温柔提醒',"),
        ("'${dt.month}\uFFFD?{dt.day}\uFFFD?·", "'${dt.month}月${dt.day}日 ·"),
        ("'1 小时\uFFFD?,", "'1 小时后',"),
        ("'本周\uFFFD?,", "'本周末',"),
        ("'${_reminderAt.year}\uFFFD?{_reminderAt.month}\uFFFD?{_reminderAt.day}\uFFFD?,", "'${_reminderAt.year}年${_reminderAt.month}月${_reminderAt.day}日',"),
        ("打开待办编辑页\uFFFD?", "打开待办编辑页。"),
    ],
    "lib/widgets/photo_wall_export_sheet.dart": [
        ("确认保存\uFFFD?", "确认保存。"),
        ("会讲故事的\uFFFD?,", "会讲故事的墙',"),
        ("可以回看的风\uFFFD?,", "可以回看的风景',"),
        ("写给未来的便\uFFFD?,", "写给未来的便签',"),
        ("想留在海报上的\uFFFD?,", "想留在海报上的话',"),
        ("'保存到相\uFFFD?,", "'保存到相册',"),
    ],
}

# Full rewrites for files corrupted to ?? by a bad prior fix attempt
DIARY_LIST_PAGE = r'''import 'package:flutter/material.dart';

import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../services/echo_stats_service.dart';
import '../services/echo_tree_service.dart';
import '../theme/echo_colors.dart';
import '../widgets/echo_hub_tile.dart';
import '../widgets/echo_page_header.dart';
import 'echo_records_page.dart';
import 'echo_tree_page.dart';
import 'photo_wall_page.dart';
import 'stats_page.dart';

/// 「回响」入口：模块列表，风格与设置页一致。
class DiaryListPage extends StatefulWidget {
  const DiaryListPage({
    super.key,
    this.onWrite,
    this.highlightDiaryId,
    this.openWeeklyReport = false,
    this.onHighlightConsumed,
    this.onWeeklyReportOpened,
  });

  final VoidCallback? onWrite;
  final String? highlightDiaryId;
  final bool openWeeklyReport;
  final VoidCallback? onHighlightConsumed;
  final VoidCallback? onWeeklyReportOpened;

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final _diaryService = DiaryService.instance;
  final _treeService = EchoTreeService.instance;

  @override
  void initState() {
    super.initState();
    _diaryService.addListener(_onChanged);
    _treeService.addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
  }

  @override
  void didUpdateWidget(DiaryListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightDiaryId != null &&
        widget.highlightDiaryId != oldWidget.highlightDiaryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
    }
    if (widget.openWeeklyReport && !oldWidget.openWeeklyReport) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleDeepLink());
    }
  }

  @override
  void dispose() {
    _diaryService.removeListener(_onChanged);
    _treeService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _handleDeepLink() {
    if (!mounted) return;
    if (widget.highlightDiaryId != null || widget.openWeeklyReport) {
      _openRecords();
    }
  }

  String get _recordsSubtitle {
    final count = _diaryService.diaries.length;
    if (count == 0) return '还没有留下文字，去此刻写下第一篇';
    return '共 $count 篇 · 时间轴、按月与按周浏览';
  }

  String get _treeSubtitle {
    final growth = _treeService.growth;
    if (_treeService.hasPendingBubbles) {
      return '${growth.stageLabel} · ${_treeService.pendingBubbles.length} 个雨露待收';
    }
    if (_treeService.storedWater > 0) {
      return '${growth.stageLabel} · 已存 ${_treeService.storedWater}g 雨露';
    }
    return '${growth.stageLabel} · 写下文字得雨露';
  }

  String get _statsSubtitle {
    final weekStart = EchoStatsService.instance.currentWeek(DateTime.now()).start;
    final stats = EchoStatsService.instance.weekStatistics(weekStart);
    if (!stats.hasMoodActivity && !stats.hasTodoActivity) {
      return '看心情，也看轻量待办';
    }
    final mood = stats.dominantMood?.label;
    if (mood != null && stats.todoCompleted > 0) {
      return '本周心情多是$mood · ${stats.todoCompleted} 件待办';
    }
    if (mood != null) return '本周心情多是$mood';
    if (stats.todoCompleted > 0) return '本周完成 ${stats.todoCompleted} 件待办';
    return '看心情，也看轻量待办';
  }

  int get _photoCount {
    var count = 0;
    for (final diary in _diaryService.diaries) {
      count += diary.images.length;
    }
    return count;
  }

  String get _photoWallSubtitle {
    if (_photoCount == 0) {
      return '写回响时添照片，会慢慢贴满一面墙';
    }
    final weekStart = EchoStatsService.instance.currentWeek(DateTime.now()).start;
    final weekPhotos =
        EchoStatsService.instance.weekStatistics(weekStart).photoCount;
    if (weekPhotos > 0) {
      return '共 $_photoCount 张 · 本周 $weekPhotos 张';
    }
    return '共 $_photoCount 张拍立得';
  }

  Future<void> _openRecords() async {
    await Navigator.of(context).push<void>(
      AppPageRoute<void>(
        builder: (_) => EchoRecordsPage(
          onWrite: widget.onWrite,
          highlightDiaryId: widget.highlightDiaryId,
          openWeeklyReport: widget.openWeeklyReport,
          onHighlightConsumed: widget.onHighlightConsumed,
          onWeeklyReportOpened: widget.onWeeklyReportOpened,
        ),
      ),
    );
  }

  Future<void> _openTree() async {
    await Navigator.of(context).push<void>(
      AppPageRoute<void>(builder: (_) => const EchoTreePage()),
    );
  }

  Future<void> _openPhotoWall() async {
    await Navigator.of(context).push<void>(
      AppPageRoute<void>(builder: (_) => const PhotoWallPage()),
    );
  }

  Future<void> _openStats() async {
    await Navigator.of(context).push<void>(
      AppPageRoute<void>(builder: (_) => const StatsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EchoColors.appBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            EchoPageHeader(
              title: '回响',
              subtitle: '记录、生长与回望',
              trailing: EchoHeaderAction(
                icon: Icons.add_rounded,
                onTap: widget.onWrite,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  EchoHubTile(
                    title: '篇章',
                    subtitle: _recordsSubtitle,
                    icon: Icons.menu_book_outlined,
                    iconTint: const Color(0xFF8B7355),
                    onTap: _openRecords,
                  ),
                  EchoHubTile(
                    title: '雨露树',
                    subtitle: _treeSubtitle,
                    icon: Icons.eco_outlined,
                    iconTint: const Color(0xFF6A9A62),
                    onTap: _openTree,
                  ),
                  EchoHubTile(
                    title: '留影',
                    subtitle: _photoWallSubtitle,
                    icon: Icons.photo_library_outlined,
                    iconTint: const Color(0xFF7A8FA8),
                    onTap: _openPhotoWall,
                  ),
                  EchoHubTile(
                    title: '统计',
                    subtitle: _statsSubtitle,
                    icon: Icons.route_outlined,
                    iconTint: const Color(0xFF8A7AA8),
                    onTap: _openStats,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
'''


def is_double_corrupted(text: str) -> bool:
    return "return '????" in text or "title: '??'" in text


def main() -> None:
    # Always rewrite diary_list if corrupted
    diary_path = ROOT / "lib/pages/diary_list_page.dart"
    if is_double_corrupted(diary_path.read_text(encoding="utf-8", errors="replace")):
        diary_path.write_text(DIARY_LIST_PAGE, encoding="utf-8", newline="\n")
        print("Rewrote lib/pages/diary_list_page.dart")

    for rel, pairs in FILE_FIXES.items():
        path = ROOT / rel
        if not path.exists():
            print(f"SKIP missing {rel}")
            continue
        text = path.read_text(encoding="utf-8", errors="replace")
        orig = text
        for old, new in pairs:
            text = text.replace(old, new)
        if text != orig:
            path.write_text(text, encoding="utf-8", newline="\n")
            print(f"Fixed {rel}")
        else:
            print(f"No match {rel}")

    # Report unclosed string lines (heuristic)
    for rel in FILE_FIXES:
        path = ROOT / rel
        text = path.read_text(encoding="utf-8", errors="replace")
        bad = [i + 1 for i, line in enumerate(text.splitlines()) if "\uFFFD" in line]
        if bad:
            print(f"REMAINING U+FFFD in {rel} lines: {bad[:10]}")


if __name__ == "__main__":
    main()
