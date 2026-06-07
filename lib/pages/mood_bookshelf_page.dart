import 'package:flutter/material.dart';

import '../models/chinese_zodiac.dart';
import '../models/diary.dart';
import '../models/echo_mood_book.dart';
import '../models/weather_mood.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../services/echo_mood_book_service.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_controls.dart';
import '../widgets/mood_bookshelf.dart';
import '../widgets/mood_month_calendar.dart';
import '../widgets/scale_tap.dart';
import 'diary_detail_page.dart';

class MoodBookshelfPage extends StatelessWidget {
  const MoodBookshelfPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EchoColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  ScaleTap(
                    onTap: () => Navigator.pop(context),
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: MoodBookshelfPanel()),
          ],
        ),
      ),
    );
  }
}

/// 心情书架 · 可按年浏览，看见每个月的色调
class MoodBookshelfPanel extends StatefulWidget {
  const MoodBookshelfPanel({
    super.key,
    this.scrollController,
    this.compact = false,
  });

  final ScrollController? scrollController;
  final bool compact;

  @override
  State<MoodBookshelfPanel> createState() => _MoodBookshelfPanelState();
}

class _MoodBookshelfPanelState extends State<MoodBookshelfPanel> {
  late int _year;
  late List<int> _years;
  int _slideDirection = 0;
  final _bookService = EchoMoodBookService.instance;

  @override
  void initState() {
    super.initState();
    _years = _bookService.availableYears();
    _year = DateTime.now().year;
    if (!_years.contains(_year)) _year = _years.last;
    _bookService.addListener(_onChanged);
    DiaryService.instance.addListener(_onChanged);
  }

  @override
  void dispose() {
    _bookService.removeListener(_onChanged);
    DiaryService.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {
      _years = _bookService.availableYears();
      if (!_years.contains(_year)) _year = _years.last;
    });
  }

  List<EchoMoodBook> get _books => _bookService.booksForYear(_year);

  ChineseZodiac get _zodiac => ChineseZodiac.forYear(_year);

  int get _filledCount => _books.where((b) => b.hasEntries).length;

  void _selectYear(int year) {
    if (!_years.contains(year) || year == _year) return;
    setState(() {
      _slideDirection = year > _year ? 1 : -1;
      _year = year;
    });
  }

  void _shiftYear(int delta) {
    final index = _years.indexOf(_year);
    final next = index + delta;
    if (next < 0 || next >= _years.length) return;
    _selectYear(_years[next]);
  }

  Future<void> _pickYear() async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: EchoColors.daySurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _YearPickerSheet(
        years: _years,
        selectedYear: _year,
      ),
    );
    if (picked != null) _selectYear(picked);
  }

  Future<void> _openBook(EchoMoodBook book) async {
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => MoodBookDetailPage(
          year: book.year,
          month: book.month,
        ),
      ),
    );
  }

  Future<void> _renameBookshelf() async {
    final custom = _bookService.bookshelfTitle == EchoMoodBookService.defaultBookshelfTitle
        ? ''
        : _bookService.bookshelfTitle;
    final controller = TextEditingController(text: custom);
    final hasCustom = custom.isNotEmpty;
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EchoColors.daySurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '为书架命名',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: EchoMoodBookService.maxBookshelfTitleLength,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: EchoMoodBookService.defaultBookshelfTitle,
              hintStyle: TextStyle(
                color: EchoColors.dayTextWhisper.withValues(alpha: 0.9),
                fontWeight: FontWeight.w300,
              ),
              counterStyle: TextStyle(
                fontSize: 11,
                color: EchoColors.dayTextWhisper,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: EchoColors.dayDivider.withValues(alpha: 0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: EchoColors.dayDivider.withValues(alpha: 0.8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: EchoColors.todoCompletedFill.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          actions: [
            if (hasCustom)
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: Text(
                  '恢复默认',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextSecondary,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(
                '保存',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: EchoColors.dayTextPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _bookService.setBookshelfTitle(result.isEmpty ? null : result);
  }

  @override
  Widget build(BuildContext context) {
    final canPrev = _years.indexOf(_year) > 0;
    final canNext = _years.indexOf(_year) < _years.length - 1;
    final titleSize = widget.compact ? 22.0 : 28.0;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.fromLTRB(28, 0, 28, widget.compact ? 24 : 40),
      children: [
        ScaleTap(
          onTap: _renameBookshelf,
          scale: 0.98,
          child: Row(
            children: [
              Flexible(
                child: Text(
                  _bookService.bookshelfTitle,
                  style: TextStyle(
                    fontSize: titleSize,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.edit_outlined,
                size: widget.compact ? 16 : 18,
                color: EchoColors.dayTextWhisper.withValues(alpha: 0.85),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '写下的日子会在这里，排成一年的书架',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextWhisper.withValues(alpha: 0.95),
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: widget.compact ? 12 : 20),
        EchoPeriodInteractiveLayer(
          periodKey: ValueKey<int>(_year),
          slideDirection: _slideDirection,
          canPrevious: canPrev,
          canNext: canNext,
          onPrevious: () => _shiftYear(-1),
          onNext: () => _shiftYear(1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: _YearPill(
                  year: _year,
                  zodiac: _zodiac,
                  canPrev: canPrev,
                  canNext: canNext,
                  onPrev: () => _shiftYear(-1),
                  onNext: () => _shiftYear(1),
                  onPickYear: _pickYear,
                ),
              ),
              if (!widget.compact) ...[
                const SizedBox(height: 12),
                _ZodiacBanner(zodiac: _zodiac, year: _year),
              ],
              SizedBox(height: widget.compact ? 8 : 12),
              Text(
                _filledCount == 0
                    ? '这一年还没有写下回响'
                    : '$_filledCount 个月有回响 · 轻触书脊翻阅',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextSecondary,
                ),
              ),
              SizedBox(height: widget.compact ? 12 : 28),
              MoodBookshelf(
                year: _year,
                books: _books,
                onBookTap: _openBook,
              ),
              if (widget.compact) ...[
                const SizedBox(height: 20),
                _ZodiacBanner(zodiac: _zodiac, year: _year),
              ],
              if (!widget.compact) ...[
                const SizedBox(height: 32),
                _LegendStrip(books: _books),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ZodiacBanner extends StatelessWidget {
  const _ZodiacBanner({required this.zodiac, required this.year});

  final ChineseZodiac zodiac;
  final int year;

  @override
  Widget build(BuildContext context) {
    final theme = zodiac.theme;
    final maxWidth = (MediaQuery.sizeOf(context).width - 96).clamp(220.0, 268.0);

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.accent.withValues(alpha: 0.14),
                theme.alcoveMid.withValues(alpha: 0.35),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.accent.withValues(alpha: 0.22),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(zodiac.emoji, style: TextStyle(fontSize: 22, height: 1)),
              const SizedBox(width: 10),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$year · ${zodiac.label}年',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: EchoColors.dayTextPrimary,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    theme.tagline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _YearPill extends StatelessWidget {
  const _YearPill({
    required this.year,
    required this.zodiac,
    required this.canPrev,
    required this.canNext,
    required this.onPrev,
    required this.onNext,
    required this.onPickYear,
  });

  final int year;
  final ChineseZodiac zodiac;
  final bool canPrev;
  final bool canNext;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onPickYear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTap(
            onTap: canPrev ? onPrev : null,
            scale: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.chevron_left_rounded,
                size: 22,
                color: canPrev
                    ? EchoColors.dayTextSecondary
                    : EchoColors.dayDivider,
              ),
            ),
          ),
          ScaleTap(
            onTap: onPickYear,
            scale: 0.98,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    zodiac.emoji,
                    style: TextStyle(fontSize: 16, height: 1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$year',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: EchoColors.dayTextPrimary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: EchoColors.dayTextWhisper.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
          ),
          ScaleTap(
            onTap: canNext ? onNext : null,
            scale: 0.9,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 22,
                color: canNext
                    ? EchoColors.dayTextSecondary
                    : EchoColors.dayDivider,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YearPickerSheet extends StatelessWidget {
  const _YearPickerSheet({
    required this.years,
    required this.selectedYear,
  });

  final List<int> years;
  final int selectedYear;

  @override
  Widget build(BuildContext context) {
    final sortedYears = years.reversed.toList(growable: false);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.62;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: EchoColors.sheetHandle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '选择年份',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: EchoColors.dayTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '不同年份对应不同生肖书架',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextWhisper.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: sortedYears.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final year = sortedYears[index];
                  final zodiac = ChineseZodiac.forYear(year);
                  final theme = zodiac.theme;
                  final selected = year == selectedYear;

                  return ScaleTap(
                    onTap: () => Navigator.pop(context, year),
                    scale: 0.98,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.accent.withValues(alpha: 0.12)
                            : EchoColors.appBackground.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? theme.accent.withValues(alpha: 0.35)
                              : EchoColors.dayDivider.withValues(alpha: 0.55),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            zodiac.emoji,
                            style: TextStyle(fontSize: 24, height: 1),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$year · ${zodiac.label}年',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: selected
                                        ? FontWeight.w400
                                        : FontWeight.w300,
                                    color: EchoColors.dayTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  theme.tagline,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w300,
                                    color: EchoColors.dayTextSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: theme.accent.withValues(alpha: 0.85),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendStrip extends StatelessWidget {
  const _LegendStrip({required this.books});

  final List<EchoMoodBook> books;

  @override
  Widget build(BuildContext context) {
    final used = <String>{};
    final items = <EchoMoodStat>[];
    for (final book in books) {
      final mood = book.dominantMood;
      if (mood == null || used.contains(mood.label)) continue;
      used.add(mood.label);
      items.add(mood);
    }

    if (items.isEmpty) {
      return Text(
        '写下的日子会在这里，排成一年的书架',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: EchoColors.dayTextWhisper.withValues(alpha: 0.9),
          fontStyle: FontStyle.italic,
          height: 1.55,
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: items.map((m) {
        final color = WeatherMood.spineColor(m.display);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: EchoColors.daySurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: EchoColors.dayDivider, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${m.emoji} ${m.label}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: EchoColors.dayTextSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class MoodBookDetailPage extends StatefulWidget {
  const MoodBookDetailPage({
    super.key,
    required this.year,
    required this.month,
  });

  final int year;
  final int month;

  @override
  State<MoodBookDetailPage> createState() => _MoodBookDetailPageState();
}

class _MoodBookDetailPageState extends State<MoodBookDetailPage> {
  final _bookService = EchoMoodBookService.instance;

  @override
  void initState() {
    super.initState();
    _bookService.addListener(_onChanged);
  }

  @override
  void dispose() {
    _bookService.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  EchoMoodBook get book =>
      _bookService.bookFor(widget.year, widget.month);

  Future<void> _renameBook() async {
    final controller = TextEditingController(text: book.customTitle ?? '');
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: EchoColors.daySurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            '为这一册命名',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: EchoMoodBookService.maxTitleLength,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextPrimary,
            ),
            decoration: InputDecoration(
              hintText: '如：春日絮语、雨夜独白…',
              hintStyle: TextStyle(
                color: EchoColors.dayTextWhisper.withValues(alpha: 0.9),
                fontWeight: FontWeight.w300,
              ),
              counterStyle: TextStyle(
                fontSize: 11,
                color: EchoColors.dayTextWhisper,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: EchoColors.dayDivider.withValues(alpha: 0.8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: EchoColors.dayDivider.withValues(alpha: 0.8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: EchoColors.todoCompletedFill.withValues(alpha: 0.6),
                ),
              ),
            ),
          ),
          actions: [
            if (book.customTitle != null)
              TextButton(
                onPressed: () => Navigator.pop(context, ''),
                child: Text(
                  '恢复默认',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextSecondary,
                  ),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                '取消',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  color: EchoColors.dayTextSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(
                '保存',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  color: EchoColors.dayTextPrimary,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    await _bookService.setCustomTitle(
      widget.year,
      widget.month,
      result.isEmpty ? null : result,
    );
  }

  Future<void> _openDay(BuildContext context, EchoDayStat day) async {
    if (!day.hasDiary || day.diaryIds.isEmpty) return;

    String? diaryId;
    if (day.diaryIds.length == 1) {
      diaryId = day.diaryIds.first;
    } else {
      final actions = <EchoActionSheetItem<String>>[];
      for (final id in day.diaryIds) {
        final diary = DiaryService.instance.getDiaryById(id);
        if (diary == null) continue;
        actions.add(
          EchoActionSheetItem(
            label: _diarySheetLabel(diary),
            value: id,
          ),
        );
      }
      if (actions.isEmpty) return;
      diaryId = await showEchoActionSheet<String>(
        context: context,
        message: '${DiaryFormat.listDateLabel(day.date)} · ${day.entryCount} 篇回响',
        actions: actions,
      );
    }

    if (diaryId == null || !context.mounted) return;
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => DiaryDetailPage(diaryId: diaryId!),
      ),
    );
  }

  static String _diarySheetLabel(Diary diary) {
    final time =
        '${diary.createdAt.hour.toString().padLeft(2, '0')}:'
        '${diary.createdAt.minute.toString().padLeft(2, '0')}';
    final preview = DiaryFormat.deriveTitle(diary.content);
    if (preview.isEmpty) return time;
    return '$time · $preview';
  }

  @override
  Widget build(BuildContext context) {
    final current = book;
    final stats = current.stats;
    final moodTint = current.hasEntries
        ? WeatherMood.tintColor(current.dominantMood?.display)
        : EchoColors.dayWriting;
    final monthCaption = DiaryFormat.monthTitle(current.year, current.month);

    return Scaffold(
      backgroundColor: EchoColors.appBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 12, 0),
              child: Row(
                children: [
                  ScaleTap(
                    onTap: () => Navigator.pop(context),
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.arrow_back_ios_new,
                        size: 18,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          moodTint.withValues(alpha: 0.95),
                          EchoColors.daySurface,
                        ],
                      ),
                      border: Border.all(
                        color: EchoColors.dayDivider.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: current.spineColor.withValues(alpha: 0.12),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _BookCover(book: current),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ScaleTap(
                                onTap: _renameBook,
                                scale: 0.98,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        current.displayTitle,
                                        style: TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.w300,
                                          color: EchoColors.dayTextPrimary,
                                          letterSpacing: -0.3,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Icon(
                                        Icons.edit_outlined,
                                        size: 16,
                                        color: EchoColors.dayTextWhisper
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                monthCaption,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: EchoColors.dayTextWhisper,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                current.hasEntries
                                    ? '这个月，${current.dominantEmoji} ${current.dominantLabel} 最多'
                                    : '空白的一页，等待被写入',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w300,
                                  color: EchoColors.dayTextSecondary,
                                  fontStyle: FontStyle.italic,
                                  height: 1.45,
                                ),
                              ),
                              if (current.hasEntries) ...[
                                const SizedBox(height: 14),
                                _HeaderStat(
                                  label: '记下',
                                  value: '${stats.diaryDayCount} 天',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (!current.hasEntries)
                    _EmptyMonthCard()
                  else ...[
                    _CalendarCard(
                      stats: stats,
                      onDayTap: (day) => _openDay(context, day),
                    ),
                    if (stats.moods.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _MoodBreakdown(moods: stats.moods),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  const _BookCover({required this.book});

  final EchoMoodBook book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 132,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
        gradient: LinearGradient(
          colors: [book.spineHighlight, book.spineColor, book.spineShadow],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: book.spineShadow.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(4, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 5,
              decoration: BoxDecoration(
                color: EchoColors.daySurface.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(2),
                ),
              ),
            ),
          ),
          Center(
            child: Text(
              book.dominantEmoji,
              style: TextStyle(fontSize: 28, height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: EchoColors.dayTextSecondary,
        ),
      ),
    );
  }
}

class _EmptyMonthCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
      ),
      child: Column(
        children: [
          Text(
            '📖',
            style: TextStyle(
              fontSize: 36,
              color: EchoColors.dayTextWhisper.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '还没有这一月的回响',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextSecondary.withValues(alpha: 0.95),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '写下的日子会在这里变成心情月历',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: EchoColors.dayTextWhisper.withValues(alpha: 0.95),
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.stats, required this.onDayTap});

  final EchoPeriodStatistics stats;
  final ValueChanged<EchoDayStat> onDayTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              gradient: LinearGradient(
                colors: stats.moods.isEmpty
                    ? [EchoColors.dayDivider, EchoColors.dayDivider]
                    : [
                        WeatherMood.spineColor(stats.moods.first.display),
                        WeatherMood.spineColor(stats.moods.first.display)
                            .withValues(alpha: 0.4),
                      ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '心情月历',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '记下 ${stats.diaryDayCount} 天'
                  '${stats.diaryEntryCount > stats.diaryDayCount ? ' · 共 ${stats.diaryEntryCount} 篇' : ''}'
                  ' · 点日期读回响',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w300,
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
                const SizedBox(height: 22),
                MoodMonthCalendar(
                  days: stats.days,
                  onDayTap: onDayTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MoodBreakdown extends StatelessWidget {
  const _MoodBreakdown({required this.moods});

  final List<EchoMoodStat> moods;

  @override
  Widget build(BuildContext context) {
    final max = moods.first.count;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: EchoColors.dayWriting.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '心情分布',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...moods.map((m) {
            final ratio = m.count / max;
            final color = WeatherMood.spineColor(m.display);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    child: Text(m.emoji, style: TextStyle(fontSize: 18)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 8,
                        backgroundColor: EchoColors.dayDivider.withValues(alpha: 0.45),
                        valueColor: AlwaysStoppedAnimation(
                          color.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${m.count}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: EchoColors.dayTextWhisper,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

void openMoodBookshelfPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const MoodBookshelfPage()),
  );
}

/// 半屏打开心情书架 · 从统计页等入口快速翻阅
Future<void> showMoodBookshelfSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.74,
        minChildSize: 0.48,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: BoxDecoration(
              color: EchoColors.appBackground,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: EchoColors.sheetHandle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: MoodBookshelfPanel(
                    scrollController: scrollController,
                    compact: true,
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
