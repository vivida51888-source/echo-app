import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/diary.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../services/locale_service.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../utils/mood_trend_copy.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_controls.dart';
import '../widgets/echo_mood_journey_map.dart';
import '../widgets/echo_section_card.dart';
import '../widgets/mood_cycle_panel.dart';
import '../widgets/scale_tap.dart';
import 'diary_detail_page.dart';

enum _StatsMode { week, month }

/// 统计：心情地图 + 阴晴圆缺。
class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

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
            Expanded(
              child: EchoStatsPanel(showHeader: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// 统计页主体（全页与「回响」页内嵌共用）。
class EchoStatsPanel extends StatefulWidget {
  const EchoStatsPanel({
    super.key,
    this.scrollController,
    this.showHeader = false,
    this.inline = false,
    this.shrinkWrap = false,
  });

  final ScrollController? scrollController;
  final bool showHeader;
  final bool inline;
  final bool shrinkWrap;

  @override
  State<EchoStatsPanel> createState() => _EchoStatsPanelState();
}

class _EchoStatsPanelState extends State<EchoStatsPanel> {
  _StatsMode _mode = _StatsMode.week;
  late DateTime _anchor;
  int _slideDirection = 0;

  @override
  void initState() {
    super.initState();
    _anchor = DateTime.now();
  }

  EchoPeriodStatistics get _stats {
    if (_mode == _StatsMode.week) {
      final start = EchoStatsService.instance.currentWeek(_anchor).start;
      return EchoStatsService.instance.weekStatistics(start);
    }
    return EchoStatsService.instance.monthStatistics(
      _anchor.year,
      _anchor.month,
    );
  }

  void _shift(int delta) {
    setState(() {
      _slideDirection = delta > 0 ? 1 : -1;
      if (_mode == _StatsMode.week) {
        _anchor = _anchor.add(Duration(days: 7 * delta));
      } else {
        _anchor = DateTime(_anchor.year, _anchor.month + delta);
      }
    });
  }

  ValueKey<String> get _periodKey {
    if (_mode == _StatsMode.week) {
      final start = EchoStatsService.instance.currentWeek(_anchor).start;
      return ValueKey('w-${start.year}-${start.month}-${start.day}');
    }
    return ValueKey('m-${_anchor.year}-${_anchor.month}');
  }

  Future<void> _openJourneyDay(EchoDayStat day) async {
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
            label: _journeyDiaryLabel(diary),
            value: id,
          ),
        );
      }
      if (actions.isEmpty) return;
      diaryId = await showEchoActionSheet<String>(
        context: context,
        message: tr('${DiaryFormat.listDateLabel(day.date)} · ${day.entryCount} 篇回响', '${DiaryFormat.listDateLabel(day.date)} · ${day.entryCount} echoes'),
        actions: actions,
      );
    }

    if (diaryId == null || !mounted) return;
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => DiaryDetailPage(diaryId: diaryId!),
      ),
    );
  }

  static String _journeyDiaryLabel(Diary diary) {
    final time =
        '${diary.createdAt.hour.toString().padLeft(2, '0')}:'
        '${diary.createdAt.minute.toString().padLeft(2, '0')}';
    final preview = DiaryFormat.deriveTitle(diary.content);
    if (preview.isEmpty) return time;
    return '$time · $preview';
  }

  String get _periodTitle {
    final stats = _stats;
    if (_mode == _StatsMode.week) {
      return DiaryFormat.weekSectionTitle(stats.start, stats.end);
    }
    return DiaryFormat.monthTitle(_anchor.year, _anchor.month);
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final s = EchoStrings.of();
        final body = [
      if (widget.showHeader) ...[
        Text(
          s.hubStats,
          style: EchoTypography.displayMedium.copyWith(
            color: EchoColors.dayTextPrimary,
          ),
        ),
        const SizedBox(height: EchoSpacing.xxs + 2),
        Text(
          tr(
            '看心情如何流转，也看阴晴圆缺',
            'Watch mood drift — sun, cloud, rain, and moon',
          ),
          style: EchoTypography.labelMedium.copyWith(
            color: EchoColors.dayTextWhisper,
          ),
        ),
        const SizedBox(height: EchoSpacing.xl),
      ] else if (!widget.inline) ...[
        Text(
          s.hubStats,
          style: EchoTypography.caption.copyWith(
            color: EchoColors.dayTextWhisper,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: EchoSpacing.md),
      ],
      EchoSlidingSegmentedControl<_StatsMode>(
        segments: const [_StatsMode.week, _StatsMode.month],
        selected: _mode,
        onChanged: (m) => setState(() {
          _mode = m;
          _slideDirection = 0;
        }),
        labelBuilder: (m) =>
            m == _StatsMode.week ? tr('按周', 'By week') : tr('按月', 'By month'),
      ),
      const SizedBox(height: 8),
      EchoPeriodNavigatorBar(
        title: _periodTitle,
        onPrevious: () => _shift(-1),
        onNext: () => _shift(1),
      ),
      const SizedBox(height: EchoSpacing.lg),
      EchoPeriodInteractiveLayer(
        periodKey: _periodKey,
        slideDirection: _slideDirection,
        onPrevious: () => _shift(-1),
        onNext: () => _shift(1),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _OverviewWhisper(stats: stats),
            const SizedBox(height: 20),
            _QuickInsightRow(stats: stats),
          ],
        ),
      ),
      const SizedBox(height: EchoSpacing.sectionGap),
      EchoSectionCard(
        title: tr('心情地图', 'Mood map'),
        subtitle: stats.isWeekly
            ? tr(
                '滑动卷轴看天气变化，左右滑页面其他区域切换周次',
                'Scroll the strip — swipe elsewhere to change weeks',
              )
            : tr(
                '一月一路，左右滑页面其他区域切换月份',
                'Month at a glance — swipe elsewhere to change months',
              ),
        child: EchoMoodJourneyMap(
          days: stats.days,
          isWeekly: stats.isWeekly,
          onDayTap: _openJourneyDay,
          embedded: true,
        ),
      ),
      const SizedBox(height: EchoSpacing.xl),
      EchoPeriodInteractiveLayer(
        periodKey: _periodKey,
        slideDirection: _slideDirection,
        onPrevious: () => _shift(-1),
        onNext: () => _shift(1),
        child: EchoSectionCard(
          title: tr('阴晴圆缺', 'Sun & moon'),
          subtitle: tr(
            '五种天象心情，在这一段里各占多少天',
            'How many days each weather mood took this period',
          ),
          child: MoodCyclePanel(stats: stats),
        ),
      ),
    ];

    if (widget.inline) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: body,
        ),
      );
    }

    return ListView(
      controller: widget.scrollController,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
      padding: EdgeInsets.fromLTRB(
        EchoSpacing.pageHorizontal,
        widget.showHeader ? 0 : EchoSpacing.md,
        EchoSpacing.pageHorizontal,
        EchoSpacing.xxxl,
      ),
      children: body,
    );
      },
    );
  }
}

class _OverviewWhisper extends StatelessWidget {
  const _OverviewWhisper({required this.stats});

  final EchoPeriodStatistics stats;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: EchoColors.insightSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Text(
        MoodTrendCopy.periodWhisper(stats),
        style: EchoTypography.bodyMedium.copyWith(
          color: EchoColors.dayTextPrimary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

/// 顶部双指标：主调心情 + 记录天数。
class _QuickInsightRow extends StatelessWidget {
  const _QuickInsightRow({required this.stats});

  final EchoPeriodStatistics stats;

  @override
  Widget build(BuildContext context) {
    final mood = stats.dominantMood;
    final daysLabel = _moodDaysLabel(stats);

    return Row(
      children: [
        Expanded(
          child: _InsightPill(
            label: tr('主调心情', 'Dominant mood'),
            value: mood != null
                ? '${mood.emoji} ${mood.label}'
                : tr('尚未标记', 'Not marked'),
            muted: mood == null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _InsightPill(
            label: tr('标记天数', 'Mood days'),
            value: daysLabel,
            muted: !stats.hasMoodActivity,
            accent: stats.hasMoodActivity,
          ),
        ),
      ],
    );
  }

  String _moodDaysLabel(EchoPeriodStatistics stats) {
    if (!stats.hasMoodActivity) return tr('尚无记录', 'No records yet');
    return tr('${stats.totalMoodDays} 天', '${stats.totalMoodDays} days');
  }
}

/// 顶部双指标：主调心情 + 待办概况。
class _InsightPill extends StatelessWidget {
  const _InsightPill({
    required this.label,
    required this.value,
    this.muted = false,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool muted;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: accent
            ? EchoColors.insightSurface.withValues(alpha: 0.65)
            : EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.65),
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: EchoTypography.micro.copyWith(
              color: EchoColors.dayTextWhisper,
              fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: EchoTypography.labelLarge.copyWith(
              color: muted
                  ? EchoColors.dayTextWhisper
                  : EchoColors.dayTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

void openStatsPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const StatsPage()),
  );
}
