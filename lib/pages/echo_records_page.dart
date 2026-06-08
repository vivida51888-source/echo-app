import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/diary.dart';
import '../models/weather_mood.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../services/locale_service.dart';
import '../services/echo_insight_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_copy.dart';
import '../utils/diary_format.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_charm.dart';
import '../widgets/echo_controls.dart';
import '../widgets/echo_empty_state.dart';
import '../widgets/scale_tap.dart';
import 'diary_detail_page.dart';
import 'write_diary_page.dart';

enum _EchoListMode { byMonth, byWeek }

class _MoodTab {
  const _MoodTab({required this.label, this.mood, this.favoritesOnly = false});

  final String label;
  final String? mood;
  final bool favoritesOnly;
}


class EchoRecordsPage extends StatefulWidget {
  const EchoRecordsPage({
    super.key,
    this.onWrite,
    this.highlightDiaryId,
    this.onHighlightConsumed,
  });

  final VoidCallback? onWrite;
  final String? highlightDiaryId;
  final VoidCallback? onHighlightConsumed;

  @override
  State<EchoRecordsPage> createState() => _EchoRecordsPageState();
}

class _EchoRecordsPageState extends State<EchoRecordsPage> {
  final _service = DiaryService.instance;
  final _insight = EchoInsightService.instance;
  final _searchController = TextEditingController();
  final _moodPageController = PageController();
  final _itemKeys = <String, GlobalKey>{};

  _EchoListMode _mode = _EchoListMode.byMonth;
  late int _pickedYear;
  late int _pickedMonth;
  late DateTime _pickedWeekStart;
  int _moodTabIndex = 0;
  bool _searchExpanded = false;
  String? _flashingDiaryId;

  List<_MoodTab> get _moodTabs => [
        _MoodTab(label: DiaryCopy.moodFilterAll),
        _MoodTab(label: tr('收藏', 'Favorites'), favoritesOnly: true),
        ...WeatherMood.options.map(
          (m) => _MoodTab(label: m.display, mood: m.display),
        ),
      ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _pickedYear = now.year;
    _pickedMonth = now.month;
    _pickedWeekStart = EchoInsightService.startOfWeek(now);
    _service.addListener(_onDiariesChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.highlightDiaryId != null) {
        _prepareHighlight(widget.highlightDiaryId!);
      }
    });
  }

  @override
  void didUpdateWidget(EchoRecordsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.highlightDiaryId != null &&
        widget.highlightDiaryId != oldWidget.highlightDiaryId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prepareHighlight(widget.highlightDiaryId!);
      });
    }
  }

  @override
  void dispose() {
    _service.removeListener(_onDiariesChanged);
    _searchController.dispose();
    _moodPageController.dispose();
    super.dispose();
  }

  void _onDiariesChanged() => setState(() {});

  GlobalKey _keyForDiary(String id) =>
      _itemKeys.putIfAbsent(id, GlobalKey.new);

  void _prepareHighlight(String diaryId) {
    final diary = _service.getDiaryById(diaryId);
    if (diary == null) return;

    setState(() {
      _pickedYear = diary.createdAt.year;
      _pickedMonth = diary.createdAt.month;
      _pickedWeekStart = EchoInsightService.startOfWeek(diary.createdAt);
      _flashingDiaryId = diaryId;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _flashingDiaryId == diaryId) {
        setState(() => _flashingDiaryId = null);
      }
      widget.onHighlightConsumed?.call();
    });
  }

  List<Diary> _diariesInPeriod() {
    switch (_mode) {
      case _EchoListMode.byMonth:
        _ensurePickedMonthValid();
        return _insight.diariesInMonth(_pickedYear, _pickedMonth);
      case _EchoListMode.byWeek:
        return _insight.diariesInWeek(_pickedWeekStart);
    }
  }

  List<Diary> _filterDiaries(List<Diary> source, _MoodTab tab) {
    var list = source;
    final query = _searchController.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list
          .where((d) => d.content.toLowerCase().contains(query))
          .toList();
    }
    if (tab.favoritesOnly) {
      list = list.where((d) => d.isFavorite).toList();
    } else if (tab.mood != null) {
      list = list.where((d) => d.moodWeather == tab.mood).toList();
    }
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  void _ensurePickedMonthValid() {
    final months = _insight.monthsWithEntries();
    if (months.isEmpty) return;
    final hasCurrent = months.any(
      (m) => m.year == _pickedYear && m.month == _pickedMonth,
    );
    if (!hasCurrent) {
      _pickedYear = months.first.year;
      _pickedMonth = months.first.month;
    }
  }

  void _shiftMonth(int delta) {
    final months = _insight.monthsWithEntries();
    if (months.isEmpty) return;

    final idx = months.indexWhere(
      (m) => m.year == _pickedYear && m.month == _pickedMonth,
    );
    if (idx < 0) {
      setState(() {
        _pickedYear = months.first.year;
        _pickedMonth = months.first.month;
      });
      return;
    }

    final next = idx + delta;
    if (next < 0 || next >= months.length) return;

    setState(() {
      _pickedYear = months[next].year;
      _pickedMonth = months[next].month;
    });
  }

  void _shiftWeek(int deltaWeeks) {
    final thisWeek = EchoInsightService.startOfWeek(DateTime.now());
    final next = _pickedWeekStart.add(Duration(days: 7 * deltaWeeks));
    if (next.isAfter(thisWeek)) return;
    setState(() => _pickedWeekStart = next);
  }

  bool get _canGoNewerWeek {
    final thisWeek = EchoInsightService.startOfWeek(DateTime.now());
    return _pickedWeekStart.isBefore(thisWeek);
  }

  Future<void> _openDetail(Diary diary) async {
    final changed = await Navigator.of(context).push<bool>(
      AppPageRoute<bool>(
        builder: (_) => DiaryDetailPage(diaryId: diary.id),
      ),
    );
    if (changed == true && mounted) setState(() {});
  }

  Future<void> _openWrite({Diary? editingDiary}) async {
    if (editingDiary == null && widget.onWrite != null) {
      widget.onWrite!();
      return;
    }
    final savedId = await Navigator.of(context).push<String>(
      AppPageRoute<String>(
        builder: (_) => WriteDiaryPage(editingDiary: editingDiary),
      ),
    );
    if (savedId != null && mounted) {
      _prepareHighlight(savedId);
    }
  }

  Future<void> _showDiaryActions(Diary diary) async {
    final s = EchoStrings.of();
    final action = await showEchoActionSheet<String>(
      context: context,
      actions: [
        EchoActionSheetItem(label: s.edit, value: 'edit'),
        EchoActionSheetItem(
          label: diary.isFavorite
              ? tr('取消收藏', 'Remove favorite')
              : tr('收藏', 'Favorite'),
          value: 'favorite',
        ),
        EchoActionSheetItem(
          label: diary.inDriftBottle
              ? tr('移出漂流瓶', 'Remove from bottle')
              : tr('放进漂流瓶', 'Put in bottle'),
          value: 'drift',
        ),
        EchoActionSheetItem(
          label: s.delete,
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );

    if (!mounted || action == null) return;

    switch (action) {
      case 'edit':
        await _openWrite(editingDiary: diary);
      case 'favorite':
        await _service.toggleFavorite(diary.id);
      case 'drift':
        await _service.toggleDriftBottle(diary.id);
      case 'delete':
        await _confirmDelete(diary);
    }
  }

  Future<void> _confirmDelete(Diary diary) async {
    final s = EchoStrings.of();
    final confirm = await showEchoActionSheet<bool>(
      context: context,
      message: tr(
        '移至回收站？\n15 天内可在设置中恢复。',
        'Move to recycle bin?\nRecover within 15 days in Settings.',
      ),
      actions: [
        EchoActionSheetItem(
          label: s.delete,
          value: true,
          isDestructive: true,
        ),
      ],
    );

    if (confirm == true) {
      await _service.deleteDiary(diary.id);
    }
  }

  void _selectMoodTab(int index) {
    if (_moodTabIndex == index) return;
    setState(() => _moodTabIndex = index);
    _moodPageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final periodDiaries = _diariesInPeriod();
    final months = _insight.monthsWithEntries();
    final monthIdx = months.indexWhere(
      (m) => m.year == _pickedYear && m.month == _pickedMonth,
    );

    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final s = EchoStrings.of();
        return ColoredBox(
      color: EchoColors.appBackground,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 16, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  ScaleTap(
                    onTap: () => Navigator.pop(context),
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      s.hubChapters,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ScaleTap(
                    onTap: () => setState(() {
                      _searchExpanded = !_searchExpanded;
                      if (!_searchExpanded) _searchController.clear();
                    }),
                    scale: 0.9,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        _searchExpanded ? Icons.close : Icons.search,
                        size: 22,
                        color: _searchExpanded
                            ? EchoColors.dayTextPrimary
                            : EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  ScaleTap(
                    onTap: () {
                      _selectMoodTab(1);
                    },
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(
                        Icons.bookmark_border,
                        size: 22,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  ScaleTap(
                    onTap: () => _openWrite(),
                    scale: 0.92,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(4, 8, 0, 8),
                      child: Icon(
                        Icons.add,
                        size: 24,
                        color: EchoColors.dayTextPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_searchExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  autocorrect: false,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: DiaryCopy.searchHint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayHint,
                    ),
                    filled: true,
                    fillColor: EchoColors.dayWriting.withValues(alpha: 0.5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    isDense: true,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: EchoSlidingSegmentedControl<_EchoListMode>(
                segments: const [_EchoListMode.byMonth, _EchoListMode.byWeek],
                selected: _mode,
                onChanged: (m) => setState(() => _mode = m),
                labelBuilder: (m) => m == _EchoListMode.byMonth
                    ? tr('按月', 'By month')
                    : tr('按周', 'By week'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: EchoPeriodNavigatorBar(
                title: _mode == _EchoListMode.byMonth
                    ? DiaryFormat.monthTitle(_pickedYear, _pickedMonth)
                    : DiaryFormat.weekSectionTitle(
                        _pickedWeekStart,
                        EchoInsightService.endOfWeek(_pickedWeekStart),
                      ),
                canPrevious: _mode == _EchoListMode.byMonth
                    ? monthIdx >= 0 && monthIdx < months.length - 1
                    : true,
                canNext: _mode == _EchoListMode.byMonth
                    ? monthIdx > 0
                    : _canGoNewerWeek,
                onPrevious: () => _mode == _EchoListMode.byMonth
                    ? _shiftMonth(1)
                    : _shiftWeek(-1),
                onNext: () => _mode == _EchoListMode.byMonth
                    ? _shiftMonth(-1)
                    : _shiftWeek(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 0),
              child: SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _moodTabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = _moodTabs[index];
                    return _MoodTabChip(
                      label: tab.label,
                      selected: _moodTabIndex == index,
                      onTap: () => _selectMoodTab(index),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              child: _service.diaries.isEmpty
                  ? Center(
                      child: EchoEmptyState(
                        charm: EchoCharmKind.diary,
                        message: tr(
                          '还没有回响\n回到此刻，写下第一篇吧',
                          'No echoes yet.\nReturn to Moment and write your first.',
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _moodPageController,
                      onPageChanged: (i) => setState(() => _moodTabIndex = i),
                      itemCount: _moodTabs.length,
                      itemBuilder: (context, index) {
                        final tab = _moodTabs[index];
                        final list = _filterDiaries(periodDiaries, tab);

                        if (list.isEmpty) {
                          return Center(
                            child: Text(
                              _searchController.text.trim().isNotEmpty
                                  ? DiaryCopy.noSearchResult
                                  : tr('这一段时间还没有回响', 'No echoes in this period'),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w300,
                                color: EchoColors.dayTextSecondary,
                              ),
                            ),
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: EchoColors.dayDivider.withValues(alpha: 0.55),
                          ),
                          itemBuilder: (context, i) {
                            final diary = list[i];
                            return KeyedSubtree(
                              key: _keyForDiary(diary.id),
                              child: _DiaryListEntry(
                                diary: diary,
                                highlighted: diary.id == _flashingDiaryId,
                                onTap: () => _openDetail(diary),
                                onLongPress: () => _showDiaryActions(diary),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
      },
    );
  }
}

class _MoodTabChip extends StatelessWidget {
  const _MoodTabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? EchoColors.dayTextPrimary
              : EchoColors.dayWriting.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: selected
                ? EchoColors.daySurface
                : EchoColors.dayTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _DiaryListEntry extends StatelessWidget {
  const _DiaryListEntry({
    required this.diary,
    required this.onTap,
    required this.onLongPress,
    this.highlighted = false,
  });

  final Diary diary;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final thumb = diary.hasImages ? diary.images.first : null;
    final title = DiaryFormat.deriveTitle(diary.content);
    final showSubtitle = title.isNotEmpty &&
        diary.previewLine.isNotEmpty &&
        diary.previewLine != title;

    return ScaleTap(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: 0.99,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: highlighted
              ? EchoColors.todoCompletedSurface.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 36,
              child: Text(
                '${diary.createdAt.day}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextPrimary,
                  height: 1,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : diary.previewLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: EchoColors.dayTextPrimary,
                      height: 1.45,
                    ),
                  ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 4),
                    Text(
                      diary.previewLine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (diary.moodWeather != null)
                        Text(
                          diary.moodWeather!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            color: EchoColors.dayTextWhisper,
                          ),
                        ),
                      if (diary.isFavorite) ...[
                        if (diary.moodWeather != null)
                          const SizedBox(width: 8),
                        Icon(
                          Icons.bookmark,
                          size: 13,
                          color: EchoColors.todoCompletedFill.withValues(
                            alpha: 0.85,
                          ),
                        ),
                      ],
                      if (diary.inDriftBottle) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.inbox_outlined,
                          size: 13,
                          color: EchoColors.dayTextWhisper,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (thumb != null) ...[
              const SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: kIsWeb
                      ? Image.network(thumb, fit: BoxFit.cover)
                      : Image.file(File(thumb), fit: BoxFit.cover),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
