import 'package:flutter/material.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../navigation/app_page_route.dart';
import '../services/diary_export_service.dart';
import '../services/diary_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_settings_layout.dart';
import '../widgets/scale_tap.dart';

class ExportDataPage extends StatefulWidget {
  const ExportDataPage({super.key});

  @override
  State<ExportDataPage> createState() => _ExportDataPageState();
}

class _ExportDataPageState extends State<ExportDataPage> {
  static const _wordTint = Color(0xFF8B7355);
  static const _archiveTint = Color(0xFF7A8FA8);

  DateTime _start = DateTime.now().subtract(const Duration(days: 30));
  DateTime _end = DateTime.now();
  bool _busy = false;

  int get _daySpan {
    final s = DateTime(_start.year, _start.month, _start.day);
    final e = DateTime(_end.year, _end.month, _end.day);
    return e.difference(s).inDays + 1;
  }

  int get _diariesInRange {
    final s = DateTime(_start.year, _start.month, _start.day);
    final e = DateTime(_end.year, _end.month, _end.day);
    return DiaryService.instance.diaries.where((d) {
      final day = DateTime(d.createdAt.year, d.createdAt.month, d.createdAt.day);
      return !day.isBefore(s) && !day.isAfter(e);
    }).length;
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        showEchoBriefHint(
          context,
          message: e is StateError
              ? e.message
              : tr('导出未完成，请稍后再试', 'Export did not finish — try again later'),
          tone: EchoBriefHintTone.gentle,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickStart() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: _end,
    );
    if (date != null) setState(() => _start = date);
  }

  Future<void> _pickEnd() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _end = date);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
        final s = EchoStrings.of();
        return EchoSettingsScaffold(
          title: s.exportTitle,
          children: [
            EchoSettingsSectionCard(
              tint: _wordTint,
              icon: Icons.description_outlined,
              title: tr('导出 Word', 'Export Word'),
              description: tr(
                '选定日期范围，每篇一个 .docx，打包为 zip。',
                'Pick a date range — one .docx per entry, zipped.',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DateRangePanel(
                    start: _start,
                    end: _end,
                    daySpan: _daySpan,
                    diaryCount: _diariesInRange,
                    onPickStart: _pickStart,
                    onPickEnd: _pickEnd,
                  ),
                  const SizedBox(height: EchoSpacing.lg),
                  EchoSettingsActionButton(
                    label: _busy
                        ? tr('导出中…', 'Exporting…')
                        : tr('导出 Word 压缩包', 'Export Word zip'),
                    tint: _wordTint,
                    icon: Icons.folder_zip_outlined,
                    busy: _busy,
                    onTap: _busy
                        ? null
                        : () => _run(
                              () => DiaryExportService.instance.exportRange(
                                start: _start,
                                end: _end,
                              ),
                            ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EchoSpacing.lg),
            EchoSettingsSectionCard(
              tint: _archiveTint,
              icon: Icons.inventory_2_outlined,
              title: tr('全量备份', 'Full backup'),
              description: tr(
                '回响、待办与图片一并归档，便于换机或本地留存。',
                'Echoes, tasks, and photos — for device migration or local archive.',
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EchoSettingsTagRow(
                    tags: trList(
                      ['回响', '待办', '图片'],
                      ['Echoes', 'Tasks', 'Photos'],
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.lg),
                  EchoSettingsActionButton(
                    label: _busy
                        ? tr('打包中…', 'Packaging…')
                        : tr('导出全量压缩包', 'Export full archive'),
                    tint: _archiveTint,
                    icon: Icons.cloud_download_outlined,
                    busy: _busy,
                    onTap: _busy
                        ? null
                        : () => _run(DiaryExportService.instance.exportFullArchive),
                  ),
                ],
              ),
            ),
            const SizedBox(height: EchoSpacing.xl),
            EchoSettingsFootnote(
              tr(
                '导出后通过系统分享保存。网盘自动同步将在后续版本提供。',
                'Save via the system share sheet after export. Cloud sync is planned.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DateRangePanel extends StatelessWidget {
  const _DateRangePanel({
    required this.start,
    required this.end,
    required this.daySpan,
    required this.diaryCount,
    required this.onPickStart,
    required this.onPickEnd,
  });

  final DateTime start;
  final DateTime end;
  final int daySpan;
  final int diaryCount;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  @override
  Widget build(BuildContext context) {
    return EchoSettingsInsetPanel(
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _DateCell(
                    label: tr('开始', 'Start'),
                    date: start,
                    onTap: onPickStart,
                  ),
                ),
                Container(
                  width: 0.5,
                  color: EchoColors.dayDivider.withValues(alpha: 0.5),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
                Container(
                  width: 0.5,
                  color: EchoColors.dayDivider.withValues(alpha: 0.5),
                ),
                Expanded(
                  child: _DateCell(
                    label: tr('结束', 'End'),
                    date: end,
                    onTap: onPickEnd,
                    alignEnd: true,
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: EchoColors.dayDivider.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EchoSpacing.md,
              vertical: EchoSpacing.sm + 2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: EchoColors.dayTextWhisper,
                ),
                const SizedBox(width: 6),
                Text(
                  tr('共 $daySpan 天', '$daySpan days'),
                  style: EchoTypography.micro.copyWith(
                    color: EchoColors.dayTextSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  diaryCount > 0
                      ? (tr('$diaryCount 篇回响', '$diaryCount echoes'))
                      : tr('该时段暂无回响', 'No echoes in this range'),
                  style: EchoTypography.micro.copyWith(
                    color: diaryCount > 0
                        ? EchoColors.dayTextSecondary
                        : EchoColors.dayTextWhisper,
                    fontStyle: diaryCount > 0
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateCell extends StatelessWidget {
  const _DateCell({
    required this.label,
    required this.date,
    required this.onTap,
    this.alignEnd = false,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.98,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment:
              alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: EchoTypography.micro.copyWith(
                color: EchoColors.dayTextWhisper,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(date),
              style: EchoTypography.labelLarge.copyWith(
                color: EchoColors.dayTextPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}

void openExportDataPage(BuildContext context) {
  Navigator.of(context).push(
    AppPageRoute<void>(builder: (_) => const ExportDataPage()),
  );
}
