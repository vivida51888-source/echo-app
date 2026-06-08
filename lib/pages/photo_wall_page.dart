import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/photo_wall_frame_style.dart';
import '../models/photo_wall_material.dart';
import '../navigation/app_page_route.dart';
import '../services/echo_insight_service.dart';
import '../services/diary_service.dart';
import '../services/locale_service.dart';
import '../services/echo_stats_service.dart';
import '../pages/keepsakes_page.dart';
import '../services/echo_reward_service.dart';
import '../services/photo_wall_settings_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../widgets/echo_controls.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_photo_wall.dart';
import '../widgets/photo_wall_export_sheet.dart';
import '../widgets/photo_wall_poster.dart';
import '../widgets/scale_tap.dart';

enum _WallMode { week, month }

class PhotoWallPage extends StatelessWidget {
  const PhotoWallPage({super.key});

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
              child: EchoPhotoWallPanel(showHeader: true),
            ),
          ],
        ),
      ),
    );
  }
}

/// 照片墙主体（独立页与后续内嵌共用）。
class EchoPhotoWallPanel extends StatefulWidget {
  const EchoPhotoWallPanel({
    super.key,
    this.scrollController,
    this.showHeader = false,
    this.shrinkWrap = false,
  });

  final ScrollController? scrollController;
  final bool showHeader;
  final bool shrinkWrap;

  @override
  State<EchoPhotoWallPanel> createState() => _EchoPhotoWallPanelState();
}

class _EchoPhotoWallPanelState extends State<EchoPhotoWallPanel> {
  _WallMode _mode = _WallMode.week;
  late DateTime _anchor;
  int _slideDirection = 0;
  bool _exporting = false;
  final _diaryService = DiaryService.instance;

  @override
  void initState() {
    super.initState();
    final settings = PhotoWallSettingsService.instance;
    _mode = settings.viewMode == PhotoWallViewMode.month
        ? _WallMode.month
        : _WallMode.week;
    _anchor = settings.viewAnchor;
    _diaryService.addListener(_onDiariesChanged);
  }

  @override
  void dispose() {
    _diaryService.removeListener(_onDiariesChanged);
    super.dispose();
  }

  void _onDiariesChanged() {
    if (mounted) setState(() {});
  }

  void _persistViewState() {
    PhotoWallSettingsService.instance.setViewState(
      mode: _mode == _WallMode.month
          ? PhotoWallViewMode.month
          : PhotoWallViewMode.week,
      anchor: _anchor,
    );
  }

  EchoPeriodStatistics get _stats {
    if (_mode == _WallMode.week) {
      final start = EchoStatsService.instance.currentWeek(_anchor).start;
      return EchoStatsService.instance.weekStatistics(start);
    }
    return EchoStatsService.instance.monthStatistics(
      _anchor.year,
      _anchor.month,
    );
  }

  EchoPeriodStatistics get _previousStats =>
      EchoStatsService.instance.previousPeriod(_stats);

  String get _periodTitle {
    final stats = _stats;
    if (_mode == _WallMode.week) {
      return DiaryFormat.weekSectionTitle(stats.start, stats.end);
    }
    return DiaryFormat.monthTitle(_anchor.year, _anchor.month);
  }

  void _shift(int delta) {
    setState(() {
      _slideDirection = delta > 0 ? 1 : -1;
      if (_mode == _WallMode.week) {
        _anchor = _anchor.add(Duration(days: 7 * delta));
      } else {
        _anchor = DateTime(_anchor.year, _anchor.month + delta);
      }
    });
    _persistViewState();
  }

  Future<void> _exportWall() async {
    if (_exporting || kIsWeb) return;

    final stats = _stats;
    final settings = PhotoWallSettingsService.instance;
    final caption = await showPhotoWallExportSheet(
      context,
      periodTitle: _periodTitle,
      defaultCaption: _wallWhisper(stats),
      photoCount: stats.photoCount,
      savedCaption: settings.posterCaption,
    );
    if (!mounted || caption == null) return;

    setState(() => _exporting = true);
    await settings.setPosterCaption(caption);

    final ok = await EchoPhotoWallExport.savePoster(
      context: context,
      poster: EchoPhotoWallPoster(
        periodTitle: _periodTitle,
        caption: caption,
        isWeekly: stats.isWeekly,
        items: stats.wallPins,
        material: settings.material,
        customWallPath: settings.customWallPath,
      ),
    );

    if (!mounted) return;
    setState(() => _exporting = false);
    showEchoBriefHint(
      context,
      message: ok
          ? tr('海报已保存到相册', 'Poster saved to Photos')
          : tr('保存失败，请检查相册权限', 'Save failed — check Photos permission'),
      tone: ok ? EchoBriefHintTone.success : EchoBriefHintTone.gentle,
    );
  }

  String _wallWhisper(EchoPeriodStatistics stats) {
    if (stats.photoCount == 0) {
      return _wallEmptyLine(stats);
    }
    return _wallPhotoLine(stats);
  }

  String _wallEmptyLine(EchoPeriodStatistics stats) {
    if (_isCurrentPeriod(stats)) {
      return tr(
        '这些日子，还悄悄留在文字里',
        'These days still live quietly in your words',
      );
    }
    return tr(
      '那些日子，悄悄留在了文字里',
      'Those days stayed quietly in your words',
    );
  }

  String _wallPhotoLine(EchoPeriodStatistics stats) {
    final prefix = _isCurrentPeriod(stats)
        ? tr('这些日子', 'These days')
        : tr('那些日子', 'Those days');
    final count = stats.photoCount;
    final mood = stats.dominantMood;

    String base;
    if (stats.isWeekly) {
      if (count == 1) {
        base = tr(
          '$prefix，也悄悄留下了一张画面',
          '$prefix, one image quietly appeared',
        );
      } else if (count <= 3) {
        base = tr(
          '$prefix，好几帧画面悄悄贴上了墙',
          '$prefix, a few frames pinned to the wall',
        );
      } else if (count <= 6) {
        base = tr(
          '$prefix，许多瞬间悄悄收进了墙里',
          '$prefix, many moments gathered on the wall',
        );
      } else {
        base = tr(
          '$prefix，散落的照片悄悄拼成一面墙',
          '$prefix, scattered photos became a wall',
        );
      }
    } else {
      if (count == 1) {
        base = tr(
          '$prefix，也悄悄留下了一张画面',
          '$prefix, one image quietly appeared',
        );
      } else if (count <= 10) {
        base = tr(
          '$prefix，好几帧画面悄悄贴上了墙',
          '$prefix, a few frames pinned to the wall',
        );
      } else if (count <= 24) {
        base = tr(
          '$prefix，许多瞬间悄悄收进了墙里',
          '$prefix, many moments gathered on the wall',
        );
      } else {
        base = tr(
          '$prefix，散落的照片悄悄拼成一面墙',
          '$prefix, scattered photos became a wall',
        );
      }
    }

    if (mood != null && count >= 2 && stats.start.day % 3 == 0) {
      return tr('$base · ${mood.emoji}${mood.label}居多', '$base · mostly ${mood.emoji} ${mood.label}');
    }
    return base;
  }

  String _wallEmptyMessage(EchoPeriodStatistics stats) {
    return _wallEmptyLine(stats);
  }

  String _wallSectionTitle(EchoPeriodStatistics stats) {
    if (_isCurrentPeriod(stats)) {
      return stats.isWeekly
          ? tr('本周照片墙', 'This week\'s wall')
          : tr('本月照片墙', 'This month\'s wall');
    }
    return stats.isWeekly
        ? tr('这一周照片墙', 'That week\'s wall')
        : tr('这一月照片墙', 'That month\'s wall');
  }

  String _wallSectionSubtitle(EchoPeriodStatistics stats) {
    if (stats.hasPhotos) {
      final style = PhotoWallSettingsService.instance.frameStyle;
      if (style == PhotoWallFrameStyle.filmStrip) {
        return tr(
          '长按翻转 · 点图放大 · 背面可吐出胶片',
          'Long-press to flip · tap to zoom · film strip on back',
        );
      }
      return tr(
        '长按翻转 · 点图放大 · 背面吐出拍立得',
        'Long-press to flip · tap to zoom · Polaroid on back',
      );
    }
    return _wallEmptyLine(stats);
  }

  bool _isCurrentPeriod(EchoPeriodStatistics stats) {
    final now = DateTime.now();
    if (stats.isWeekly) {
      final currentStart =
          EchoStatsService.instance.currentWeek(now).start;
      return EchoInsightService.dateOnly(stats.start) ==
          EchoInsightService.dateOnly(currentStart);
    }
    return stats.start.year == now.year && stats.start.month == now.month;
  }

  String get _periodKey {
    final stats = _stats;
    if (_mode == _WallMode.week) {
      return 'w-${stats.start.year}-${stats.start.month}-${stats.start.day}';
    }
    return 'm-${_anchor.year}-${_anchor.month}';
  }

  ValueKey<String> get _periodValueKey => ValueKey(_periodKey);

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final previousStats = _previousStats;

    return ListenableBuilder(
      listenable: Listenable.merge([
        PhotoWallSettingsService.instance,
        _diaryService,
        LocaleService.instance,
      ]),
      builder: (context, _) {
        final settings = PhotoWallSettingsService.instance;
        final s = EchoStrings.of();
        final body = [
          if (widget.showHeader) ...[
            Text(
              s.hubPhoto,
              style: EchoTypography.displayMedium.copyWith(
                color: EchoColors.dayTextPrimary,
              ),
            ),
            const SizedBox(height: EchoSpacing.xxs + 2),
            Text(
              tr(
                '日记里的照片，拼成一面会讲故事的墙',
                'Photos from your journal, arranged as a storytelling wall',
              ),
              style: EchoTypography.labelMedium.copyWith(
                color: EchoColors.dayTextWhisper,
              ),
            ),
            const SizedBox(height: EchoSpacing.xl),
          ],
          EchoSlidingSegmentedControl<_WallMode>(
            segments: const [_WallMode.week, _WallMode.month],
            selected: _mode,
            onChanged: (m) {
              setState(() {
                _mode = m;
                _slideDirection = 0;
              });
              _persistViewState();
            },
            labelBuilder: (m) =>
                m == _WallMode.week ? tr('按周', 'By week') : tr('按月', 'By month'),
          ),
          const SizedBox(height: EchoSpacing.xs),
          EchoPeriodNavigatorBar(
            title: _periodTitle,
            onPrevious: () => _shift(-1),
            onNext: () => _shift(1),
          ),
          const SizedBox(height: EchoSpacing.lg),
          _WallMaterialPicker(
            material: settings.material,
            displayLabel: settings.materialDisplayLabel,
            frameStyle: settings.frameStyle,
            pinSoundEnabled: settings.pinSoundEnabled,
            showPhotoDates: settings.showPhotoDates,
            onMaterialChanged: settings.setMaterial,
            onPickCustomWall: settings.pickAndSetCustomWall,
            onFrameStyleChanged: settings.setFrameStyle,
            onPinSoundChanged: settings.setPinSoundEnabled,
            onShowPhotoDatesChanged: settings.setShowPhotoDates,
          ),
          const SizedBox(height: 20),
          EchoPeriodInteractiveLayer(
            periodKey: _periodValueKey,
            slideDirection: _slideDirection,
            onPrevious: () => _shift(-1),
            onNext: () => _shift(1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  decoration: BoxDecoration(
                    color: EchoColors.dayWriting.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _wallWhisper(stats),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                      height: 1.65,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: _WallSectionLabel(
                        title: _wallSectionTitle(stats),
                        subtitle: _wallSectionSubtitle(stats),
                      ),
                    ),
                    if (!kIsWeb)
                      ScaleTap(
                        onTap: _exporting ? null : _exportWall,
                        scale: 0.96,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            _exporting
                                ? tr('保存中…', 'Saving…')
                                : tr('保存海报', 'Save poster'),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              color: _exporting
                                  ? EchoColors.dayTextWhisper
                                  : EchoColors.dayTextSecondary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                EchoPhotoWall(
                  items: stats.wallPins,
                  isWeekly: stats.isWeekly,
                  periodKey: _periodKey,
                  material: settings.material,
                  customWallPath: settings.customWallPath,
                  enablePolaroidActions: true,
                  emptyMessage:
                      stats.hasPhotos ? null : _wallEmptyMessage(stats),
                ),
                const SizedBox(height: 32),
                _WallSectionLabel(
                  title: stats.isWeekly
                      ? tr('两周对照', 'Two weeks')
                      : tr('两月对照', 'Two months'),
                  subtitle: stats.isWeekly
                      ? tr(
                          '左右滑动页面其他区域，切换周次对比',
                          'Swipe elsewhere on the page to compare weeks',
                        )
                      : tr(
                          '左右滑动页面其他区域，切换月份对比',
                          'Swipe elsewhere on the page to compare months',
                        ),
                ),
                const SizedBox(height: 16),
                EchoPhotoWallCompare(
                  current: stats,
                  previous: previousStats,
                  isWeekly: stats.isWeekly,
                ),
              ],
            ),
          ),
        ];

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

class _WallMaterialPicker extends StatelessWidget {
  const _WallMaterialPicker({
    required this.material,
    required this.displayLabel,
    required this.frameStyle,
    required this.pinSoundEnabled,
    required this.showPhotoDates,
    required this.onMaterialChanged,
    required this.onPickCustomWall,
    required this.onFrameStyleChanged,
    required this.onPinSoundChanged,
    required this.onShowPhotoDatesChanged,
  });

  final PhotoWallMaterial material;
  final String displayLabel;
  final PhotoWallFrameStyle frameStyle;
  final bool pinSoundEnabled;
  final bool showPhotoDates;
  final ValueChanged<PhotoWallMaterial> onMaterialChanged;
  final Future<bool> Function() onPickCustomWall;
  final ValueChanged<PhotoWallFrameStyle> onFrameStyleChanged;
  final ValueChanged<bool> onPinSoundChanged;
  final ValueChanged<bool> onShowPhotoDatesChanged;

  Future<void> _openPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<PhotoWallMaterial>(
      context: context,
      backgroundColor: EchoColors.appBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _WallMaterialSheet(
        selected: material,
        frameStyle: frameStyle,
      ),
    );
    if (!context.mounted || picked == null) return;

    if (picked == PhotoWallMaterial.custom) {
      await onPickCustomWall();
      return;
    }
    if (!EchoRewardService.instance.isWallUnlocked(picked)) {
      if (!context.mounted) return;
      showEchoBriefHint(
        context,
        message: tr('在回响小铺解锁此墙面', 'Unlock this wall in Echo shop'),
        tone: EchoBriefHintTone.gentle,
        icon: Icons.lock_outline_rounded,
        actionLabel: tr('前往', 'Go'),
        onAction: () => openKeepsakesPage(context),
      );
      return;
    }
    onMaterialChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: EchoColors.dayWriting.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          ScaleTap(
            onTap: () => _openPicker(context),
            scale: 0.99,
            child: Row(
              children: [
                Text(
                  tr('墙面', 'Wall'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: EchoColors.dayTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  displayLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: EchoColors.dayTextPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.unfold_more_rounded,
                  size: 18,
                  color: EchoColors.dayTextWhisper,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: EchoColors.dayDivider.withValues(alpha: 0.45),
            ),
          ),
          Row(
            children: [
              Text(
                tr('照片样式', 'Photo style'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: EchoColors.dayTextSecondary,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 168,
                child: EchoSlidingSegmentedControl<PhotoWallFrameStyle>(
                  segments: PhotoWallFrameStyle.values,
                  selected: frameStyle,
                  onChanged: onFrameStyleChanged,
                  labelBuilder: (s) => s.localizedLabel,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(
              height: 1,
              color: EchoColors.dayDivider.withValues(alpha: 0.45),
            ),
          ),
          Row(
            children: [
              ScaleTap(
                onTap: () => onPinSoundChanged(!pinSoundEnabled),
                scale: 0.98,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      pinSoundEnabled
                          ? Icons.volume_up_outlined
                          : Icons.volume_off_outlined,
                      size: 16,
                      color: pinSoundEnabled
                          ? EchoColors.dayTextSecondary
                          : EchoColors.dayTextWhisper,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      pinSoundEnabled
                          ? tr('钉墙音效开', 'Pin sound on')
                          : tr('钉墙音效关', 'Pin sound off'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: pinSoundEnabled
                            ? EchoColors.dayTextSecondary
                            : EchoColors.dayTextWhisper,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ScaleTap(
                onTap: () => onShowPhotoDatesChanged(!showPhotoDates),
                scale: 0.98,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 16,
                      color: showPhotoDates
                          ? EchoColors.dayTextSecondary
                          : EchoColors.dayTextWhisper,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showPhotoDates
                          ? tr('显示照片日期', 'Show dates')
                          : tr('隐藏照片日期', 'Hide dates'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: showPhotoDates
                            ? EchoColors.dayTextSecondary
                            : EchoColors.dayTextWhisper,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _pickWallMaterial(BuildContext context, PhotoWallMaterial material) {
  if (!EchoRewardService.instance.isWallUnlocked(material)) {
    showEchoBriefHint(
      context,
      message: tr('在回响小铺解锁此墙面', 'Unlock this wall in Echo shop'),
      tone: EchoBriefHintTone.gentle,
      icon: Icons.lock_outline_rounded,
      actionLabel: tr('前往', 'Go'),
      onAction: () {
        Navigator.pop(context);
        openKeepsakesPage(context);
      },
    );
    return;
  }
  Navigator.pop(context, material);
}

class _WallMaterialSheet extends StatelessWidget {
  const _WallMaterialSheet({
    required this.selected,
    required this.frameStyle,
  });

  final PhotoWallMaterial selected;
  final PhotoWallFrameStyle frameStyle;

  @override
  Widget build(BuildContext context) {
    final options = PhotoWallMaterial.pickerOptions(frameStyle);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EchoColors.dayDivider.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              tr('选择墙面', 'Choose wall'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: EchoColors.dayTextPrimary,
              ),
            ),
            const SizedBox(height: 20),
            if (frameStyle == PhotoWallFrameStyle.filmStrip) ...[
              _SheetSectionLabel(tr('基础', 'Basic')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in options)
                    _MaterialChip(
                      label: m.localizedLabel,
                      selected: selected == m,
                      locked: !EchoRewardService.instance.isWallUnlocked(m),
                      onTap: () => _pickWallMaterial(context, m),
                    ),
                ],
              ),
            ] else ...[
              _SheetSectionLabel(tr('基础', 'Basic')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in PhotoWallMaterial.basic)
                    _MaterialChip(
                      label: m.localizedLabel,
                      selected: selected == m,
                      locked: !EchoRewardService.instance.isWallUnlocked(m),
                      onTap: () => _pickWallMaterial(context, m),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetSectionLabel(tr('自然景色', 'Nature')),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in PhotoWallMaterial.natureSeasons)
                    _MaterialChip(
                      label: m.localizedLabel,
                      selected: selected == m,
                      locked: !EchoRewardService.instance.isWallUnlocked(m),
                      onTap: () => _pickWallMaterial(context, m),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _SheetSectionLabel(tr('更多', 'More')),
              const SizedBox(height: 10),
              _MaterialChip(
                label: PhotoWallMaterial.custom.localizedLabel,
                selected: selected == PhotoWallMaterial.custom,
                locked: false,
                onTap: () => Navigator.pop(context, PhotoWallMaterial.custom),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetSectionLabel extends StatelessWidget {
  const _SheetSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w300,
        color: EchoColors.dayTextWhisper,
      ),
    );
  }
}

class _MaterialChip extends StatelessWidget {
  const _MaterialChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.locked = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? EchoColors.dayWriting.withValues(alpha: 0.95)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? EchoColors.dayDivider : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (locked) ...[
              Icon(
                Icons.lock_outline,
                size: 12,
                color: EchoColors.dayTextWhisper,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
                color: selected
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WallSectionLabel extends StatelessWidget {
  const _WallSectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w400,
            color: EchoColors.dayTextPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: EchoColors.dayTextWhisper,
          ),
        ),
      ],
    );
  }
}

void openPhotoWallPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const PhotoWallPage()),
  );
}
