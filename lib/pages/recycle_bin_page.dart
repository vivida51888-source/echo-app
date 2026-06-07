import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/trashed_diary.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/diary_format.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_settings_layout.dart';
import '../widgets/scale_tap.dart';

class RecycleBinPage extends StatefulWidget {
  const RecycleBinPage({super.key});

  @override
  State<RecycleBinPage> createState() => _RecycleBinPageState();
}

const _thumbSize = 52.0;

class _RecycleBinPageState extends State<RecycleBinPage> {
  static const _tint = Color(0xFF8E8478);

  final _service = DiaryService.instance;

  @override
  void initState() {
    super.initState();
    _service.addListener(_onChanged);
  }

  @override
  void dispose() {
    _service.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() => setState(() {});

  Future<void> _restore(TrashedDiary item) async {
    await _service.restoreDiary(item.diary.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('已恢复'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _deleteForever(TrashedDiary item) async {
    final ok = await showEchoActionSheet<bool>(
      context: context,
      message: '永久删除这篇回响？\n删除后无法找回。',
      actions: const [
        EchoActionSheetItem(
          label: '永久删除',
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (ok == true) {
      await _service.permanentlyDelete(item.diary.id);
    }
  }

  Future<void> _emptyAll() async {
    final ok = await showEchoActionSheet<bool>(
      context: context,
      message: '清空回收站？\n所有内容将永久删除。',
      actions: const [
        EchoActionSheetItem(
          label: '清空',
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (ok == true) await _service.emptyTrash();
  }

  @override
  Widget build(BuildContext context) {
    final items = _service.trashedDiaries;

    return EchoSettingsScaffold(
      title: '回收站',
      actions: [
        if (items.isNotEmpty)
          TextButton(
            onPressed: _emptyAll,
            child: Text(
              '清空',
              style: EchoTypography.caption.copyWith(
                color: EchoColors.destructive,
              ),
            ),
          ),
      ],
      children: [
        if (items.isEmpty) ...[
          Text(
            '删除的内容会在这里保留 $diaryTrashRetentionDays 天',
            style: EchoTypography.caption.copyWith(
              color: EchoColors.dayTextSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: EchoSpacing.lg),
          EchoSettingsEmptyCard(
            icon: Icons.delete_outline_rounded,
            tint: _tint,
            message: '暂无已删除的回响',
          ),
        ] else ...[
          _TrashStatsCard(items: items, tint: _tint),
          const SizedBox(height: EchoSpacing.md),
          _TrashListCard(
            items: items,
            onRestore: _restore,
            onDeleteForever: _deleteForever,
          ),
        ],
      ],
    );
  }
}

/// 顶部统计：篇数 + 保留规则，一眼看清。
class _TrashStatsCard extends StatelessWidget {
  const _TrashStatsCard({
    required this.items,
    required this.tint,
  });

  final List<TrashedDiary> items;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    final soonest = items
        .map((e) => e.daysRemaining)
        .reduce((a, b) => a < b ? a : b);

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tint.withValues(alpha: 0.1),
            EchoColors.daySurface,
          ],
        ),
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.55),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          EchoSpacing.lg,
          EchoSpacing.lg,
          EchoSpacing.lg,
          EchoSpacing.md + 2,
        ),
        child: Row(
          children: [
            Text(
              '${items.length}',
              style: EchoTypography.displayMedium.copyWith(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: tint,
                height: 1,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: EchoSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '篇',
                  style: EchoTypography.labelMedium.copyWith(
                    color: EchoColors.dayTextSecondary,
                  ),
                ),
                Text(
                  '待恢复',
                  style: EchoTypography.micro.copyWith(
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
              ],
            ),
            Container(
              width: 0.5,
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: EchoSpacing.lg),
              color: EchoColors.dayDivider.withValues(alpha: 0.5),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '保留 $diaryTrashRetentionDays 天',
                    style: EchoTypography.bodyMedium.copyWith(
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    soonest <= 3
                        ? '最近一篇还剩 $soonest 天'
                        : '到期后自动清除',
                    style: EchoTypography.caption.copyWith(
                      color: soonest <= 3
                          ? EchoColors.destructive.withValues(alpha: 0.8)
                          : EchoColors.dayTextWhisper,
                    ),
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

class _TrashListCard extends StatelessWidget {
  const _TrashListCard({
    required this.items,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final List<TrashedDiary> items;
  final Future<void> Function(TrashedDiary item) onRestore;
  final Future<void> Function(TrashedDiary item) onDeleteForever;

  static const _rowInset = EchoSpacing.md + _thumbSize + EchoSpacing.sm + 2;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.6),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: EchoColors.dayTextPrimary.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(EchoRadii.lg),
        child: Column(
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Divider(
                  height: 1,
                  indent: _rowInset,
                  endIndent: EchoSpacing.md,
                  color: EchoColors.dayDivider.withValues(alpha: 0.4),
                ),
              _TrashRow(
                item: items[i],
                onRestore: () => onRestore(items[i]),
                onDeleteForever: () => onDeleteForever(items[i]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrashRow extends StatelessWidget {
  const _TrashRow({
    required this.item,
    required this.onRestore,
    required this.onDeleteForever,
  });

  final TrashedDiary item;
  final VoidCallback onRestore;
  final VoidCallback onDeleteForever;

  @override
  Widget build(BuildContext context) {
    final diary = item.diary;
    final title = DiaryFormat.deriveTitle(diary.content);
    final headline = title.isNotEmpty ? title : diary.previewLine;
    final urgent = item.daysRemaining <= 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        EchoSpacing.md,
        EchoSpacing.md,
        EchoSpacing.md,
        EchoSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TrashThumb(
            path: diary.hasImages ? diary.images.first : null,
          ),
          const SizedBox(width: EchoSpacing.sm + 2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        headline,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: EchoTypography.bodyMedium.copyWith(
                          color: EchoColors.dayTextPrimary,
                          height: 1.45,
                        ),
                      ),
                    ),
                    const SizedBox(width: EchoSpacing.xs),
                    _DaysChip(days: item.daysRemaining, urgent: urgent),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  DiaryFormat.dateLine(diary.createdAt),
                  style: EchoTypography.caption.copyWith(
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
                const SizedBox(height: EchoSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _TrashActionChip(
                      icon: Icons.restore_rounded,
                      label: '恢复',
                      onTap: onRestore,
                    ),
                    const SizedBox(width: EchoSpacing.xs),
                    _TrashActionChip(
                      icon: Icons.delete_outline_rounded,
                      onTap: onDeleteForever,
                      destructive: true,
                      iconOnly: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrashActionChip extends StatelessWidget {
  const _TrashActionChip({
    required this.icon,
    required this.onTap,
    this.label,
    this.destructive = false,
    this.iconOnly = false,
  });

  final IconData icon;
  final String? label;
  final VoidCallback onTap;
  final bool destructive;
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? EchoColors.destructive.withValues(alpha: 0.9)
        : EchoColors.dayTextSecondary;
    final background = destructive
        ? EchoColors.destructive.withValues(alpha: 0.07)
        : EchoColors.dayTextPrimary.withValues(alpha: 0.06);
    final borderColor = destructive
        ? EchoColors.destructive.withValues(alpha: 0.14)
        : EchoColors.dayTextPrimary.withValues(alpha: 0.1);

    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        height: 32,
        width: iconOnly ? 32 : null,
        padding: iconOnly
            ? null
            : const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(
            iconOnly ? EchoRadii.sm : EchoRadii.pill,
          ),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        alignment: Alignment.center,
        child: iconOnly
            ? Icon(icon, size: 17, color: color)
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: color),
                  const SizedBox(width: 4),
                  Text(
                    label!,
                    style: EchoTypography.caption.copyWith(
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _DaysChip extends StatelessWidget {
  const _DaysChip({required this.days, required this.urgent});

  final int days;
  final bool urgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: urgent
            ? EchoColors.destructive.withValues(alpha: 0.08)
            : EchoColors.appBackground.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(EchoRadii.pill),
      ),
      child: Text(
        '$days 天',
        style: EchoTypography.micro.copyWith(
          color: urgent
              ? EchoColors.destructive.withValues(alpha: 0.9)
              : EchoColors.dayTextWhisper,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _TrashThumb extends StatelessWidget {
  const _TrashThumb({this.path});

  final String? path;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(EchoRadii.sm),
      child: SizedBox(
        width: _thumbSize,
        height: _thumbSize,
        child: path != null
            ? _Photo(path: path!)
            : ColoredBox(
                color: EchoColors.appBackground.withValues(alpha: 0.8),
                child: Icon(
                  Icons.article_outlined,
                  size: 22,
                  color: EchoColors.dayTextWhisper.withValues(alpha: 0.7),
                ),
              ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final image = kIsWeb
        ? Image.network(path, fit: BoxFit.cover)
        : Image.file(File(path), fit: BoxFit.cover);

    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.04),
        BlendMode.darken,
      ),
      child: image,
    );
  }
}

void openRecycleBinPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const RecycleBinPage()),
  );
}
