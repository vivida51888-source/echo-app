import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/important_day.dart';
import '../navigation/app_page_route.dart';
import '../services/important_day_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_spacing.dart';
import '../theme/echo_typography.dart';
import '../utils/important_day_copy.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_charm.dart';
import '../widgets/echo_empty_state.dart';
import '../widgets/scale_tap.dart';

class ImportantDaysPage extends StatefulWidget {
  const ImportantDaysPage({super.key});

  @override
  State<ImportantDaysPage> createState() => _ImportantDaysPageState();
}

class _ImportantDaysPageState extends State<ImportantDaysPage> {
  final _service = ImportantDayService.instance;

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

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openEditor([ImportantDay? existing]) async {
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => ImportantDayEditPage(day: existing),
      ),
    );
  }

  Future<void> _confirmDelete(ImportantDay day) async {
    final ok = await showEchoActionSheet<bool>(
      context: context,
      message: tr(
        '删除「${day.title}」？\nEcho 将不再提醒这一天。',
        'Delete «${day.title}»?\nEcho will stop reminding you.',
      ),
      actions: [
        EchoActionSheetItem(
          label: EchoStrings.current.delete,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (ok == true) {
      await _service.delete(day.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final anchors = _service.anchorItems;
    final annuals = _service.annualItems;
    final isEmpty = anchors.isEmpty && annuals.isEmpty;

    return ListenableBuilder(
      listenable: LocaleService.instance,
      builder: (context, _) {
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
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ImportantDayCopy.pageTitle,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ImportantDayCopy.pageSubtitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextWhisper,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      tr('轻轻提醒', 'Gentle reminders'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: EchoColors.dayTextPrimary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _service.remindersEnabled,
                    onChanged: (v) => _service.setRemindersEnabled(v),
                    activeColor: EchoColors.dayTextPrimary,
                  ),
                ],
              ),
            ),
            const Divider(height: 1, indent: 28, endIndent: 28),
            Expanded(
              child: isEmpty
                  ? _EmptyHint(onAdd: () => _openEditor())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 100),
                      children: [
                        if (anchors.isNotEmpty)
                          _ImportantDaySection(
                            tint: ImportantDayCopy.anchorSectionTint,
                            children: [
                              _SectionHeader(
                                title: ImportantDayCopy.anchorSectionTitle,
                                subtitle:
                                    ImportantDayCopy.anchorSectionSubtitle,
                                highlight: ImportantDayCopy.anchorMetricLabel,
                                highlightTint: ImportantDayCopy.anchorHighlightTint,
                                charm: EchoCharmKind.milestone,
                              ),
                              for (final day in anchors)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ImportantDayTile(
                                    day: day,
                                    onTap: () => _openEditor(day),
                                    onDelete: () => _confirmDelete(day),
                                  ),
                                ),
                            ],
                          ),
                        if (anchors.isNotEmpty && annuals.isNotEmpty)
                          const SizedBox(height: 14),
                        if (annuals.isNotEmpty)
                          _ImportantDaySection(
                            tint: ImportantDayCopy.annualSectionTint,
                            children: [
                              _SectionHeader(
                                title: ImportantDayCopy.annualSectionTitle,
                                subtitle:
                                    ImportantDayCopy.annualSectionSubtitle,
                                highlight: ImportantDayCopy.annualHighlight,
                                highlightTint: ImportantDayCopy.annualHighlightTint,
                                charm: EchoCharmKind.wallCalendar,
                              ),
                              for (final day in annuals)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _ImportantDayTile(
                                    day: day,
                                    onTap: () => _openEditor(day),
                                    onDelete: () => _confirmDelete(day),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTap(
        onTap: () => _openEditor(),
        scale: 0.94,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8, right: 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: EchoColors.dayWriting.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: EchoColors.dayDivider.withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
          child: Text(
            tr('添加重要日', 'Add important day'),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
            ),
          ),
        ),
      ),
    );
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: EchoEmptyState(
        charm: EchoCharmKind.imprint,
        title: tr('还没有印记', 'No marks yet'),
        message: tr(
          '把对你重要的日子放进来\nEcho 会在那天，和「此刻」轻轻相遇',
          'Add days that matter to you.\nEcho will meet them gently on the day.',
        ),
        actionLabel: tr('添加第一个重要日', 'Add your first mark'),
        onAction: onAdd,
      ),
    );
  }
}

class _ImportantDaySection extends StatelessWidget {
  const _ImportantDaySection({required this.tint, required this.children});

  final Color tint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.highlight,
    this.highlightTint,
    this.charm,
  });

  final String title;
  final String? subtitle;
  final String? highlight;
  final Color? highlightTint;
  final EchoCharmKind? charm;

  @override
  Widget build(BuildContext context) {
    final tint = highlightTint ?? EchoColors.dayTextSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: EchoColors.dayTextPrimary,
                ),
              ),
              if (charm != null) ...[
                const SizedBox(width: 6),
                EchoCharm(
                  kind: charm!,
                  size: 24,
                  animate: false,
                ),
              ],
            ],
          ),
          if (subtitle != null && highlight != null) ...[
            const SizedBox(height: 6),
            _HighlightedCaption(
              prefix: subtitle!.replaceAll(highlight!, ''),
              highlight: highlight!,
              tint: tint,
            ),
          ] else if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w300,
                color: EchoColors.dayTextWhisper,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HighlightedCaption extends StatelessWidget {
  const _HighlightedCaption({
    required this.prefix,
    required this.highlight,
    required this.tint,
  });

  final String prefix;
  final String highlight;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w300,
          color: EchoColors.dayTextWhisper,
          height: 1.35,
        ),
        children: [
          if (prefix.isNotEmpty) TextSpan(text: prefix),
          TextSpan(
            text: highlight,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: tint,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportantDayTile extends StatelessWidget {
  const _ImportantDayTile({
    required this.day,
    required this.onTap,
    required this.onDelete,
  });

  final ImportantDay day;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final metric = ImportantDayCopy.listMetric(day);
    final whisper = ImportantDayCopy.listWhisperLine(day);
    final isAnchor = day.isAnchor;
    final cardTint = isAnchor
        ? ImportantDayCopy.anchorCardTint
        : ImportantDayCopy.annualCardTint;
    final accentLine = isAnchor
        ? EchoColors.todoCompletedBorder.withValues(alpha: 0.55)
        : EchoColors.dayDivider.withValues(alpha: 0.95);
    final metricAccent = isAnchor
        ? ImportantDayCopy.anchorAccent
        : ImportantDayCopy.annualAccent;

    return ScaleTap(
      onTap: onTap,
      onLongPress: onDelete,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        decoration: BoxDecoration(
          color: cardTint,
          borderRadius: BorderRadius.circular(EchoRadii.md),
          border: Border.all(
            color: accentLine,
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: EchoColors.dayTextPrimary.withValues(alpha: 0.025),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _MetricBlock(
              metric: metric,
              accent: metricAccent,
              isAnchor: isAnchor,
            ),
            Container(
              width: 0.5,
              height: 56,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              color: EchoColors.dayDivider.withValues(alpha: 0.85),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    day.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EchoTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ImportantDayCopy.listDetailLine(day),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.dayTextWhisper,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  if (whisper != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      whisper,
                      style: EchoTypography.micro.copyWith(
                        color: EchoColors.dayTextSecondary,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
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

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.metric,
    required this.accent,
    required this.isAnchor,
  });

  final ImportantDayListMetric metric;
  final Color accent;
  final bool isAnchor;

  static const _tabular = [FontFeature.tabularFigures()];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isAnchor ? 0.14 : 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.22),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          child: switch (metric.style) {
            ImportantDayMetricStyle.word => _metricText(metric.word ?? ''),
            ImportantDayMetricStyle.days => _dayCount(metric.days ?? 0),
            ImportantDayMetricStyle.duration => _elapsedDuration(
                metric.years ?? 0,
                metric.durationDays ?? 0,
              ),
            ImportantDayMetricStyle.countdown => _dayCount(metric.days ?? 0),
          },
        ),
      ),
    );
  }

  Widget _metricText(String value) {
    return Text(
      value,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w400,
        color: EchoColors.dayTextPrimary,
        height: 1.2,
      ),
    );
  }

  Widget _dayCount(int count) {
    const numberSize = 30.0;
    const unitSize = 17.0;

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: numberSize,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextPrimary,
              height: 1,
              letterSpacing: -0.6,
              fontFeatures: _tabular,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            tr('天', 'd'),
            style: TextStyle(
              fontSize: unitSize,
              fontWeight: FontWeight.w500,
              color: accent.withValues(alpha: 0.88),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _elapsedDuration(int years, int days) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _DurationLine(
          value: '$years',
          unit: tr('年', 'y'),
          valueSize: 24,
          unitSize: 13,
        ),
        if (days != 0) ...[
          const SizedBox(height: 5),
          _dayCount(days),
        ] else ...[
          const SizedBox(height: 2),
          Text(
            tr('整周年', 'Full year'),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: EchoColors.dayTextSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _DurationLine extends StatelessWidget {
  const _DurationLine({
    required this.value,
    required this.unit,
    required this.valueSize,
    required this.unitSize,
  });

  final String value;
  final String unit;
  final double valueSize;
  final double unitSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: valueSize,
            fontWeight: FontWeight.w400,
            color: EchoColors.dayTextPrimary,
            height: 1,
            fontFeatures: _MetricBlock._tabular,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: unitSize,
            fontWeight: FontWeight.w500,
            color: EchoColors.dayTextSecondary,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class ImportantDayEditPage extends StatefulWidget {
  const ImportantDayEditPage({super.key, this.day});

  final ImportantDay? day;

  @override
  State<ImportantDayEditPage> createState() => _ImportantDayEditPageState();
}

class _ImportantDayEditPageState extends State<ImportantDayEditPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late ImportantDayMode _mode;
  late ImportantDayKind _kind;
  late int _month;
  late int _day;
  late int _startYear;

  bool get _isEditing => widget.day != null;
  bool get _isAnchor => _mode == ImportantDayMode.anchor;

  Color get _modeTint => _isAnchor
      ? ImportantDayCopy.anchorAccent
      : ImportantDayCopy.annualAccent;

  @override
  void initState() {
    super.initState();
    final existing = widget.day;
    final now = DateTime.now();
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');
    _mode = existing?.mode ?? ImportantDayMode.annual;
    _kind = existing?.kind ??
        (_mode == ImportantDayMode.anchor
            ? ImportantDayKind.work
            : ImportantDayKind.birthday);
    _month = existing?.month ?? now.month;
    _day = existing?.day ?? now.day;
    _startYear = existing?.startYear ?? now.year;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = DateTime(_startYear, _month, _day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: _isAnchor ? now : DateTime(2100),
      helpText: _isAnchor
          ? tr('选择开始日期', 'Choose start date')
          : tr('选择每年日期', 'Choose annual date'),
      builder: (context, child) {
        final brightness =
            EchoColors.isDark ? Brightness.dark : Brightness.light;
        return Theme(
          data: Theme.of(context).copyWith(
            brightness: brightness,
            colorScheme: ColorScheme.fromSeed(
              seedColor: EchoColors.dayTextPrimary,
              brightness: brightness,
              primary: EchoColors.dayTextPrimary,
              onPrimary: EchoColors.daySurface,
              surface: EchoColors.daySurface,
              onSurface: EchoColors.dayTextPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() {
      _month = picked.month;
      _day = picked.day;
      _startYear = picked.year;
    });
  }

  void _setMode(ImportantDayMode mode) {
    if (_mode == mode) return;
    setState(() {
      _mode = mode;
      final kinds = ImportantDayKind.forMode(mode);
      if (!kinds.contains(_kind)) {
        _kind = kinds.first;
      }
    });
  }

  ImportantDay _draftDay() {
    return ImportantDay(
      id: '',
      title: '',
      month: _month,
      day: _day,
      startYear: _startYear,
      mode: _mode,
      kind: _kind,
      createdAt: DateTime.now(),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      showEchoBriefHint(
        context,
        message: tr('请写一个名字', 'Please enter a name'),
        tone: EchoBriefHintTone.gentle,
      );
      return;
    }

    final day = ImportantDay(
      id: widget.day?.id ?? newImportantDayId(),
      title: title,
      month: _month,
      day: _day,
      startYear: _startYear,
      mode: _mode,
      kind: _kind,
      remindDaysBefore: _isAnchor ? const [0] : const [0, 3],
      enabled: true,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      createdAt: widget.day?.createdAt ?? DateTime.now(),
    );

    await ImportantDayService.instance.save(day);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draftDay();

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
                    onTap: _save,
                    scale: 0.94,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        EchoStrings.current.save,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: EchoColors.dayTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 4, 28, 40),
                children: [
                  Text(
                    _isEditing
                        ? tr('编辑重要日', 'Edit important day')
                        : tr('添加重要日', 'Add important day'),
                    style: EchoTypography.displayMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(
                      '创建后会自动开启提醒，早上 9:00 轻轻唤起',
                      'Reminders turn on automatically — a gentle nudge at 9:00 AM',
                    ),
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.dayTextWhisper,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.xl),
                  _ModeHubStrip(
                    selected: _mode,
                    onSelect: _setMode,
                  ),
                  const SizedBox(height: EchoSpacing.lg),
                  _SectionLabel(tr('名字', 'Name')),
                  _EchoFilledField(
                    controller: _titleController,
                    hintText: _isAnchor
                        ? tr('例如：入职、结婚、相识', 'e.g. new job, wedding, first met')
                        : tr('例如：妈妈的生日、相识纪念日', 'e.g. Mom\'s birthday, anniversary'),
                    maxLength: ImportantDayService.maxTitleLength,
                  ),
                  const SizedBox(height: EchoSpacing.lg),
                  _SectionLabel(tr('类型', 'Type')),
                  Wrap(
                    spacing: EchoSpacing.xs,
                    runSpacing: EchoSpacing.xs,
                    children: ImportantDayKind.forMode(_mode).map((kind) {
                      final selected = _kind == kind;
                      return _KindChip(
                        label: kind.localizedLabel,
                        selected: selected,
                        tint: _modeTint,
                        onTap: () => setState(() => _kind = kind),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: EchoSpacing.lg),
                  _SectionLabel(_isAnchor ? tr('开始日期', 'Start date') : tr('每年日期', 'Annual date')),
                  ScaleTap(
                    onTap: _pickDate,
                    scale: 0.98,
                    child: _DatePickerCard(
                      day: draft,
                      tint: _modeTint,
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.md),
                  Text(
                    _isAnchor
                        ? ImportantDayCopy.anchorMilestoneHint(_kind)
                        : (tr('每年 ${draft.month} 月 ${draft.day} 日 · 当天与提前 3 天提醒', 'Every ${draft.month}/${draft.day} · on the day & 3 days before')),
                    style: EchoTypography.caption.copyWith(
                      color: EchoColors.dayTextWhisper,
                      fontWeight: FontWeight.w300,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: EchoSpacing.lg),
                  _SectionLabel(tr('备注（可选）', 'Note (optional)')),
                  _EchoFilledField(
                    controller: _noteController,
                    hintText: tr('只给自己看，不会出现在通知里', 'Private — not shown in notifications'),
                    maxLength: ImportantDayService.maxNoteLength,
                    maxLines: 3,
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

class _ModeHubStrip extends StatelessWidget {
  const _ModeHubStrip({
    required this.selected,
    required this.onSelect,
  });

  final ImportantDayMode selected;
  final ValueChanged<ImportantDayMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < ImportantDayMode.values.length; i++) ...[
          if (i > 0) const SizedBox(width: EchoSpacing.xxs),
          Expanded(
            child: _ModeHubTab(
              mode: ImportantDayMode.values[i],
              selected: ImportantDayMode.values[i] == selected,
              onTap: () => onSelect(ImportantDayMode.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeHubTab extends StatelessWidget {
  const _ModeHubTab({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ImportantDayMode mode;
  final bool selected;
  final VoidCallback onTap;

  Color get _tint => mode == ImportantDayMode.anchor
      ? ImportantDayCopy.anchorAccent
      : ImportantDayCopy.annualAccent;

  IconData get _icon => mode == ImportantDayMode.anchor
      ? Icons.flag_outlined
      : Icons.event_repeat_outlined;

  @override
  Widget build(BuildContext context) {
    final tint = _tint;
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
          vertical: EchoSpacing.sm,
          horizontal: EchoSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: selected
              ? tint.withValues(alpha: 0.12)
              : EchoColors.daySurface,
          borderRadius: BorderRadius.circular(EchoRadii.sm),
          border: Border.all(
            color: selected
                ? tint.withValues(alpha: 0.32)
                : EchoColors.dayDivider,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: 18,
              color: selected ? tint : EchoColors.dayTextWhisper,
            ),
            const SizedBox(height: 4),
            Text(
              mode.localizedLabel,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: EchoTypography.labelMedium.copyWith(
                fontWeight: selected ? FontWeight.w500 : FontWeight.w300,
                color: selected
                    ? EchoColors.dayTextPrimary
                    : EchoColors.dayTextSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              mode == ImportantDayMode.anchor
                  ? tr('累计天数', 'Days elapsed')
                  : tr('倒计时', 'Countdown'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: EchoTypography.micro.copyWith(
                color: EchoColors.dayTextWhisper,
                fontWeight: FontWeight.w300,
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  const _DatePickerCard({
    required this.day,
    required this.tint,
  });

  final ImportantDay day;
  final Color tint;

  String get _preview {
    if (day.isAnchor) {
      final elapsed = day.daysElapsed();
      if (elapsed == null) {
        return tr('起算后将显示天数', 'Days will show after start date');
      }
      return tr('$elapsed 天', '$elapsed days');
    }
    return ImportantDayCopy.countdownLabel(day);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: EchoSpacing.md,
        vertical: EchoSpacing.md,
      ),
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          tint.withValues(alpha: 0.1),
          EchoColors.daySurface,
        ),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: tint.withValues(alpha: 0.28),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              day.isAnchor ? Icons.flag_outlined : Icons.schedule_outlined,
              size: 20,
              color: tint,
            ),
          ),
          const SizedBox(width: EchoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ImportantDayCopy.dateLabel(day),
                  style: EchoTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _preview,
                  style: EchoTypography.caption.copyWith(
                    color: tint.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: EchoColors.dayTextWhisper,
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.tint,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color tint;
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
          color: selected ? tint : EchoColors.dayWriting.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: !selected
              ? Border.all(color: tint.withValues(alpha: 0.18), width: 0.5)
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: selected ? EchoColors.daySurface : EchoColors.dayTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _EchoFilledField extends StatelessWidget {
  const _EchoFilledField({
    required this.controller,
    required this.hintText,
    required this.maxLength,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hintText;
  final int maxLength;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      style: EchoTypography.bodyMedium.copyWith(
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: EchoTypography.bodyMedium.copyWith(
          color: EchoColors.dayHint,
          fontWeight: FontWeight.w300,
        ),
        filled: true,
        fillColor: EchoColors.dayWriting.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EchoRadii.md),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        counterText: '',
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EchoSpacing.xs),
      child: Text(
        text,
        style: EchoTypography.labelMedium.copyWith(
          color: EchoColors.dayTextSecondary,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
