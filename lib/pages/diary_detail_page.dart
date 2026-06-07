import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/diary.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_export_service.dart';
import '../services/diary_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_photo_wall.dart';
import '../widgets/scale_tap.dart';
import 'write_diary_page.dart';

/// 朋友圈式九宫格间距。
const _kMomentsGap = 4.0;

class DiaryDetailPage extends StatefulWidget {
  const DiaryDetailPage({super.key, required this.diaryId});

  final String diaryId;

  @override
  State<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends State<DiaryDetailPage> {
  final _service = DiaryService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onDiariesChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onDiariesChanged);
    super.dispose();
  }

  void _onDiariesChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final diary = _service.getDiaryById(widget.diaryId);
    if (diary == null) {
      return Scaffold(
        backgroundColor: EchoColors.appBackground,
        body: Center(
          child: Text(
            '这篇回响已不在了',
            style: EchoTypography.labelMedium.copyWith(
              color: EchoColors.dayTextSecondary,
            ),
          ),
        ),
      );
    }

    final text = diary.content.trim();

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
                  const Spacer(),
                  ScaleTap(
                    onTap: () => _showActions(context, diary),
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.more_horiz,
                        size: 22,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  EchoSpacing.pageHorizontal,
                  EchoSpacing.xs,
                  EchoSpacing.pageHorizontal,
                  EchoSpacing.xxxl,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (text.isNotEmpty)
                      Text(
                        text,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: EchoColors.dayTextPrimary,
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
                    if (diary.hasImages) ...[
                      SizedBox(height: text.isNotEmpty ? 10 : 0),
                      _WechatMomentsPhotoGrid(images: diary.images),
                    ],
                    const SizedBox(height: EchoSpacing.sm + 2),
                    _MomentsMetaRow(diary: diary),
                    if (diary.hasAiInsight) ...[
                      const SizedBox(height: EchoSpacing.sectionGap),
                      _AiInsightCard(diary: diary),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showActions(BuildContext context, Diary diary) async {
    final action = await showEchoActionSheet<String>(
      context: context,
      actions: [
        const EchoActionSheetItem(label: '编辑', value: 'edit'),
        const EchoActionSheetItem(label: '导出 Word', value: 'export_word'),
        EchoActionSheetItem(
          label: diary.isFavorite ? '取消收藏' : '收藏',
          value: 'favorite',
        ),
        EchoActionSheetItem(
          label: diary.inDriftBottle ? '移出漂流瓶' : '放进漂流瓶',
          value: 'drift',
        ),
        const EchoActionSheetItem(
          label: '删除',
          value: 'delete',
          isDestructive: true,
        ),
      ],
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'edit':
        final savedId = await Navigator.of(context).push<String>(
          AppPageRoute<String>(
            builder: (_) => WriteDiaryPage(editingDiary: diary),
          ),
        );
        if (savedId != null && context.mounted) {
          Navigator.pop(context, true);
        }
      case 'export_word':
        await DiaryExportService.instance.shareDiaryWord(diary);
      case 'favorite':
        await _service.toggleFavorite(diary.id);
      case 'drift':
        await _service.toggleDriftBottle(diary.id);
      case 'delete':
        final confirm = await showEchoActionSheet<bool>(
          context: context,
          message: '移至回收站？\n15 天内可在设置中恢复。',
          actions: const [
            EchoActionSheetItem(
              label: '删除',
              value: true,
              isDestructive: true,
            ),
          ],
        );
        if (confirm == true) {
          await _service.deleteDiary(diary.id);
          if (context.mounted) Navigator.pop(context, true);
        }
    }
  }
}

class _MomentsMetaRow extends StatelessWidget {
  const _MomentsMetaRow({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    final time =
        '${diary.createdAt.hour.toString().padLeft(2, '0')}:'
        '${diary.createdAt.minute.toString().padLeft(2, '0')}';

    return Row(
      children: [
        Text(
          DiaryFormat.listDateLabel(diary.createdAt),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: EchoColors.dayTextPrimary,
          ),
        ),
        const SizedBox(width: EchoSpacing.sm),
        Text(
          time,
          style: EchoTypography.caption.copyWith(
            color: EchoColors.dayTextWhisper,
          ),
        ),
        if (diary.moodWeather != null) ...[
          const SizedBox(width: EchoSpacing.sm),
          Text(
            diary.moodWeather!,
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextSecondary,
            ),
          ),
        ],
        if (diary.hasLocation &&
            (diary.placeLabel?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(width: EchoSpacing.sm),
          Text(
            diary.placeLabel!.trim(),
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextWhisper,
            ),
          ),
        ],
        if (diary.isFavorite) ...[
          const SizedBox(width: EchoSpacing.sm),
          Icon(
            Icons.bookmark,
            size: 14,
            color: EchoColors.todoCompletedFill.withValues(alpha: 0.85),
          ),
        ],
        if (diary.inDriftBottle) ...[
          const SizedBox(width: 6),
          Icon(
            Icons.inbox_outlined,
            size: 14,
            color: EchoColors.dayTextWhisper,
          ),
        ],
      ],
    );
  }
}

/// 朋友圈式图片区：以三列九宫格单元为基准，1–2 张不会过大。
class _WechatMomentsPhotoGrid extends StatelessWidget {
  const _WechatMomentsPhotoGrid({required this.images});

  final List<String> images;

  static _MomentsPhotoMetrics _metrics(BuildContext context) {
    final contentWidth =
        MediaQuery.sizeOf(context).width - EchoSpacing.pageHorizontal * 2;
    final gridWidth = (contentWidth * 0.72).clamp(210.0, 264.0);
    final cellSize = (gridWidth - _kMomentsGap * 2) / 3;
    return _MomentsPhotoMetrics(
      gridWidth: gridWidth,
      cellSize: cellSize,
    );
  }

  int _crossAxisCount(int count) {
    if (count == 2 || count == 4) return 2;
    return 3;
  }

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();

    final m = _metrics(context);

    if (images.length == 1) {
      return _MomentsSinglePhoto(
        path: images.first,
        maxWidth: m.singleMaxWidth,
        maxHeight: m.singleMaxHeight,
      );
    }

    final columns = _crossAxisCount(images.length);
    final packWidth = columns == 2 ? m.twoColumnWidth : m.gridWidth;
    final rows = (images.length + columns - 1) ~/ columns;
    final gridHeight = rows * m.cellSize + (rows - 1) * _kMomentsGap;

    return SizedBox(
      width: packWidth,
      height: gridHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: _kMomentsGap,
          mainAxisSpacing: _kMomentsGap,
          childAspectRatio: 1,
        ),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return _MomentsGridTile(path: images[index]);
        },
      ),
    );
  }
}

class _MomentsPhotoMetrics {
  const _MomentsPhotoMetrics({
    required this.gridWidth,
    required this.cellSize,
  });

  final double gridWidth;
  final double cellSize;

  /// 两列区域宽（2 张 / 4 张图）
  double get twoColumnWidth => cellSize * 2 + _kMomentsGap;

  /// 单图最大宽：占两格
  double get singleMaxWidth => twoColumnWidth;

  /// 单图最大高：略高于两格，竖图也不会过长
  double get singleMaxHeight => cellSize * 2.5 + _kMomentsGap;
}

class _MomentsSinglePhoto extends StatefulWidget {
  const _MomentsSinglePhoto({
    required this.path,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String path;
  final double maxWidth;
  final double maxHeight;

  @override
  State<_MomentsSinglePhoto> createState() => _MomentsSinglePhotoState();
}

class _MomentsSinglePhotoState extends State<_MomentsSinglePhoto> {
  Size? _size;

  @override
  void initState() {
    super.initState();
    _resolveSize();
  }

  Future<void> _resolveSize() async {
    if (kIsWeb) return;
    try {
      final bytes = await File(widget.path).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      if (!mounted) return;
      setState(() {
        _size = Size(image.width.toDouble(), image.height.toDouble());
      });
      image.dispose();
    } catch (_) {}
  }

  Size _displaySize() {
    final maxW = widget.maxWidth;
    final maxH = widget.maxHeight;

    if (_size == null || _size!.width <= 0 || _size!.height <= 0) {
      final side = (maxW * 0.85).clamp(96.0, maxW);
      return Size(side, side);
    }

    final ratio = _size!.width / _size!.height;
    if (ratio >= 1.05) {
      var w = maxW;
      var h = w / ratio;
      if (h > maxH) {
        h = maxH;
        w = h * ratio;
      }
      return Size(w, h);
    }
    if (ratio <= 0.95) {
      var h = maxH;
      var w = h * ratio;
      if (w > maxW) {
        w = maxW;
        h = w / ratio;
      }
      return Size(w, h);
    }
    final side = maxW.clamp(96.0, maxW);
    return Size(side, side);
  }

  @override
  Widget build(BuildContext context) {
    final size = _displaySize();

    return ScaleTap(
      onTap: () => openPhotoLightbox(context, widget.path),
      scale: 0.99,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: _DiaryPhoto(path: widget.path),
        ),
      ),
    );
  }
}

class _MomentsGridTile extends StatelessWidget {
  const _MomentsGridTile({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: () => openPhotoLightbox(context, path),
      scale: 0.99,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: _DiaryPhoto(path: path),
      ),
    );
  }
}

class _DiaryPhoto extends StatelessWidget {
  const _DiaryPhoto({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Image.network(path, fit: BoxFit.cover, width: double.infinity);
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

class _AiInsightCard extends StatelessWidget {
  const _AiInsightCard({required this.diary});

  final Diary diary;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EchoSpacing.lg),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: EchoColors.dayDivider, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Echo',
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: EchoSpacing.sm),
          Text(
            diary.aiSummary,
            style: EchoTypography.bodyMedium.copyWith(
              color: EchoColors.dayTextPrimary,
              height: 1.7,
            ),
          ),
          if (diary.aiKeywords.isNotEmpty) ...[
            const SizedBox(height: EchoSpacing.md),
            Wrap(
              spacing: EchoSpacing.sm,
              runSpacing: EchoSpacing.xs,
              children: diary.aiKeywords
                  .map(
                    (k) => Text(
                      k,
                      style: EchoTypography.caption.copyWith(
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}
