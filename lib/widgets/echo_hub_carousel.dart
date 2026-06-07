import 'dart:io';

import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../navigation/app_page_route.dart';
import '../pages/diary_detail_page.dart';
import '../pages/echo_tree_page.dart';
import '../services/diary_service.dart';
import '../services/echo_stats_service.dart';
import '../services/echo_tree_service.dart';
import '../services/photo_wall_settings_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import 'echo_charm.dart';
import 'echo_empty_state.dart';
import 'echo_mood_journey_map.dart';
import 'echo_photo_wall.dart';
import 'scale_tap.dart';

class _HubModule {
  const _HubModule({
    required this.label,
    required this.icon,
    required this.tint,
  });

  final String label;
  final IconData icon;
  final Color tint;
}

const _modules = [
  _HubModule(
    label: '留影',
    icon: Icons.photo_library_outlined,
    tint: Color(0xFF7A8FA8),
  ),
  _HubModule(
    label: '篇章',
    icon: Icons.menu_book_outlined,
    tint: Color(0xFF8B7355),
  ),
  _HubModule(
    label: '雨露树',
    icon: Icons.eco_outlined,
    tint: Color(0xFF6A9A62),
  ),
  _HubModule(
    label: '统计',
    icon: Icons.route_outlined,
    tint: Color(0xFF8A7AA8),
  ),
];

/// 回响 hub：四入口横向滑屏，默认首屏为留影。
class EchoHubCarousel extends StatefulWidget {
  const EchoHubCarousel({
    super.key,
    required this.onOpenPhoto,
    required this.onOpenRecords,
    required this.onOpenTree,
    required this.onOpenStats,
    this.initialPage = 0,
    this.onModuleChanged,
  });

  final VoidCallback onOpenPhoto;
  final VoidCallback onOpenRecords;
  final VoidCallback onOpenTree;
  final VoidCallback onOpenStats;
  final int initialPage;
  final ValueChanged<int>? onModuleChanged;

  @override
  State<EchoHubCarousel> createState() => _EchoHubCarouselState();
}

class _EchoHubCarouselState extends State<EchoHubCarousel> {
  late final PageController _pageController;
  late int _pageIndex;
  bool _pageAnimating = false;

  final _diaryService = DiaryService.instance;
  final _treeService = EchoTreeService.instance;
  final _wallSettings = PhotoWallSettingsService.instance;

  @override
  void initState() {
    super.initState();
    _pageIndex = widget.initialPage.clamp(0, _modules.length - 1);
    _pageController = PageController(initialPage: _pageIndex);
    _diaryService.addListener(_onDataChanged);
    _treeService.addListener(_onDataChanged);
    _wallSettings.addListener(_onDataChanged);
  }

  @override
  void dispose() {
    _diaryService.removeListener(_onDataChanged);
    _treeService.removeListener(_onDataChanged);
    _wallSettings.removeListener(_onDataChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onDataChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _selectPage(int index) async {
    if (index == _pageIndex || _pageAnimating || !_pageController.hasClients) {
      return;
    }

    final distance = (index - _pageIndex).abs();
    if (distance > 1) {
      _pageController.jumpToPage(index);
      return;
    }

    _pageAnimating = true;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
    if (mounted) _pageAnimating = false;
  }

  void _onPageChanged(int index) {
    if (_pageIndex == index) return;
    setState(() => _pageIndex = index);
    widget.onModuleChanged?.call(index);
  }

  String _subtitleFor(int index) {
    switch (index) {
      case 0:
        return _photoWallSubtitle;
      case 1:
        return _recordsSubtitle;
      case 2:
        return _treeSubtitle;
      case 3:
        return _statsSubtitle;
      default:
        return '';
    }
  }

  VoidCallback _openFor(int index) {
    switch (index) {
      case 0:
        return widget.onOpenPhoto;
      case 1:
        return widget.onOpenRecords;
      case 2:
        return widget.onOpenTree;
      case 3:
        return widget.onOpenStats;
      default:
        return () {};
    }
  }

  String get _recordsSubtitle {
    final count = _diaryService.diaries.length;
    if (count == 0) return '还没有留下文字，去此刻写下第一篇';
    return '共 $count 篇 · 按月与按周浏览';
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
    if (!stats.hasMoodActivity) {
      return '看心情流转，也看阴晴圆缺';
    }
    final mood = stats.dominantMood?.label;
    if (mood != null && stats.totalMoodDays > 0) {
      return '本周心情多是$mood · ${stats.totalMoodDays} 天';
    }
    if (mood != null) return '本周心情多是$mood';
    return '看心情流转，也看阴晴圆缺';
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
    final stats = _photoWallPreviewStats();
    final periodName = _wallSettings.viewMode == PhotoWallViewMode.month
        ? DiaryFormat.monthTitle(stats.start.year, stats.start.month)
        : DiaryFormat.weekSectionTitle(stats.start, stats.end);
    if (stats.photoCount > 0) {
      return '共 $_photoCount 张 · $periodName ${stats.photoCount} 张';
    }
    final styleLabel = _wallSettings.frameStyleLabel;
    return '共 $_photoCount 张 · $periodName · $styleLabel';
  }

  EchoPeriodStatistics _photoWallPreviewStats() {
    final anchor = _wallSettings.viewAnchor;
    if (_wallSettings.viewMode == PhotoWallViewMode.month) {
      return EchoStatsService.instance.monthStatistics(
        anchor.year,
        anchor.month,
      );
    }
    final weekStart = EchoStatsService.instance.currentWeek(anchor).start;
    return EchoStatsService.instance.weekStatistics(weekStart);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EchoHubTabStrip(
          modules: _modules,
          selectedIndex: _pageIndex,
          onSelect: _selectPage,
        ),
        Expanded(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _modules.length,
            itemBuilder: (context, index) {
              return _EchoHubModulePage(
                module: _modules[index],
                subtitle: _subtitleFor(index),
                onOpen: _openFor(index),
                flatPreview: index == 3,
                child: _previewFor(index),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _previewFor(int index) {
    switch (index) {
      case 0:
        return const _PhotoPreview();
      case 1:
        return const _RecordsPreview();
      case 2:
        return const _TreePreview();
      case 3:
        return const _StatsPreview();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _EchoHubTabStrip extends StatelessWidget {
  const _EchoHubTabStrip({
    required this.modules,
    required this.selectedIndex,
    required this.onSelect,
  });

  final List<_HubModule> modules;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.pageHorizontal,
        0,
        EchoSpacing.pageHorizontal,
        EchoSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < modules.length; i++) ...[
            if (i > 0) const SizedBox(width: EchoSpacing.xxs),
            Expanded(
              child: _EchoHubTab(
                module: modules[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EchoHubTab extends StatelessWidget {
  const _EchoHubTab({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final _HubModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? module.tint : EchoColors.dayTextWhisper;

    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: EchoSpacing.xs,
          horizontal: EchoSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? module.tint.withValues(alpha: 0.1)
              : EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.sm),
          border: Border.all(
            color: selected
                ? module.tint.withValues(alpha: 0.28)
                : EchoColors.dayDivider,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(module.icon, size: 17, color: color),
            const SizedBox(height: 3),
            Text(
              module.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EchoTypography.labelMedium.copyWith(
                color: selected
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextSecondary,
                fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EchoHubModulePage extends StatelessWidget {
  const _EchoHubModulePage({
    required this.module,
    required this.subtitle,
    required this.onOpen,
    required this.child,
    this.flatPreview = false,
  });

  final _HubModule module;
  final String subtitle;
  final VoidCallback onOpen;
  final Widget child;
  /// 预览区自带区块卡片时，不再套外层矩形。
  final bool flatPreview;

  @override
  Widget build(BuildContext context) {
    final preview = flatPreview
        ? child
        : DecoratedBox(
            decoration: BoxDecoration(
              color: EchoColors.daySurface,
              borderRadius: BorderRadius.circular(EchoRadii.md),
              border: Border.all(color: EchoColors.dayDivider, width: 0.5),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(EchoRadii.md),
              child: child,
            ),
          );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.pageHorizontal,
        0,
        EchoSpacing.pageHorizontal,
        EchoSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      module.label,
                      style: EchoTypography.titleLarge.copyWith(
                        color: EchoColors.dayTextPrimary,
                      ),
                    ),
                    const SizedBox(height: EchoSpacing.xxs),
                    Text(
                      subtitle,
                      style: EchoTypography.labelMedium.copyWith(
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTap(
                onTap: onOpen,
                scale: 0.94,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, left: EchoSpacing.xs),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '进入',
                        style: EchoTypography.labelMedium.copyWith(
                          color: module.tint,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: module.tint,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: EchoSpacing.sm),
          Expanded(child: preview),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview();

  EchoPeriodStatistics _statsFor(PhotoWallSettingsService settings) {
    final anchor = settings.viewAnchor;
    if (settings.viewMode == PhotoWallViewMode.month) {
      return EchoStatsService.instance.monthStatistics(
        anchor.year,
        anchor.month,
      );
    }
    final weekStart = EchoStatsService.instance.currentWeek(anchor).start;
    return EchoStatsService.instance.weekStatistics(weekStart);
  }

  @override
  Widget build(BuildContext context) {
    final settings = PhotoWallSettingsService.instance;

    return ListenableBuilder(
      listenable: Listenable.merge([
        settings,
        DiaryService.instance,
      ]),
      builder: (context, _) {
        final stats = _statsFor(settings);
        final isWeekly = settings.viewMode == PhotoWallViewMode.week;

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: EchoPhotoWall(
                  items: stats.wallPins,
                  isWeekly: isWeekly,
                  compact: false,
                  pinAnimationScope: 'hub',
                  enablePolaroidActions: true,
                  showDates: settings.showPhotoDates,
                  periodKey:
                      'hub-${isWeekly ? 'w' : 'm'}-${stats.start.year}-${stats.start.month}-${stats.start.day}',
                  material: settings.material,
                  customWallPath: settings.customWallPath,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _RecordsPreview extends StatelessWidget {
  const _RecordsPreview();

  static const _previewCount = 5;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: DiaryService.instance,
      builder: (context, _) {
        final diaries =
            DiaryService.instance.diaries.take(_previewCount).toList();

        if (diaries.isEmpty) {
          return Center(
            child: EchoEmptyState(
              charm: EchoCharmKind.diary,
              compact: true,
              message: '还没有篇章\n去此刻写下第一篇',
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: EchoSpacing.md,
            vertical: EchoSpacing.sm,
          ),
          child: Column(
            children: [
              for (var i = 0; i < diaries.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 1,
                    color: EchoColors.dayDivider.withValues(alpha: 0.6),
                  ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _HubRecentDiaryRow(
                      diary: diaries[i],
                      onTap: () => _openDiaryDetail(context, diaries[i]),
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

Future<void> _openDiaryDetail(BuildContext context, Diary diary) async {
  await Navigator.of(context).push<bool>(
    AppPageRoute<bool>(
      builder: (_) => DiaryDetailPage(diaryId: diary.id),
    ),
  );
}

class _HubRecentDiaryRow extends StatelessWidget {
  const _HubRecentDiaryRow({
    required this.diary,
    required this.onTap,
  });

  final Diary diary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = DiaryFormat.deriveTitle(diary.content);
    final thumb = diary.hasImages ? diary.images.first : null;

    return ScaleTap(
      onTap: onTap,
      scale: 0.99,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              DiaryFormat.listDateLabel(diary.createdAt),
              style: EchoTypography.bodyMedium.copyWith(
                color: EchoColors.dayTextSecondary,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
          const SizedBox(width: EchoSpacing.sm),
          Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.isNotEmpty ? title : diary.previewLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EchoTypography.bodyMedium.copyWith(
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  if (diary.moodWeather != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      diary.moodWeather!,
                      style: EchoTypography.caption.copyWith(
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (thumb != null) ...[
              const SizedBox(width: EchoSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(EchoRadii.sm),
                child: Image.file(
                  File(thumb),
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                ),
              ),
            ],
        ],
      ),
    );
  }
}

class _TreePreview extends StatelessWidget {
  const _TreePreview();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: EchoTreePanel(inline: true),
    );
  }
}

class _StatsPreview extends StatelessWidget {
  const _StatsPreview();

  @override
  Widget build(BuildContext context) {
    final weekStart = EchoStatsService.instance.currentWeek(DateTime.now()).start;
    final stats = EchoStatsService.instance.weekStatistics(weekStart);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EchoColors.sectionCardFill(),
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.65),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EchoSpacing.sm + 2,
          EchoSpacing.md,
          EchoSpacing.sm + 2,
          EchoSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '心情地图',
              style: EchoTypography.titleMedium.copyWith(
                color: EchoColors.dayTextPrimary,
              ),
            ),
            const SizedBox(height: EchoSpacing.xxs),
            Text(
              '左右滑切换入口 · 点「进入」查看完整统计',
              style: EchoTypography.caption.copyWith(
                color: EchoColors.dayTextWhisper,
              ),
            ),
            const SizedBox(height: EchoSpacing.sm + 2),
            Expanded(
              child: EchoMoodJourneyMap(
                days: stats.days,
                isWeekly: true,
                onDayTap: (_) {},
                embedded: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
