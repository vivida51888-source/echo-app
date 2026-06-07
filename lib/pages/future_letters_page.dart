import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/future_letter.dart';
import '../navigation/app_page_route.dart';
import '../services/future_letter_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../utils/future_letter_copy.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_charm.dart';
import '../widgets/echo_empty_state.dart';
import '../pages/keepsakes_page.dart';
import '../services/echo_collectible_service.dart';
import '../widgets/scale_tap.dart';

class FutureLettersPage extends StatefulWidget {
  const FutureLettersPage({super.key});

  @override
  State<FutureLettersPage> createState() => _FutureLettersPageState();
}

class _FutureLettersPageState extends State<FutureLettersPage> {
  final _service = FutureLetterService.instance;

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

  Future<void> _openCompose() async {
    await Navigator.of(context).push(
      AppPageRoute<void>(builder: (_) => const _FutureLetterComposePage()),
    );
  }

  Future<void> _openLetter(FutureLetter letter) async {
    if (letter.isOpened) {
      await Navigator.of(context).push(
        AppPageRoute<void>(
          builder: (_) => _FutureLetterReadPage(letter: letter),
        ),
      );
      return;
    }

    if (!letter.isDue()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            FutureLetterCopy.sealedHint,
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: EchoColors.dayTextPrimary,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => _FutureLetterReadPage(letter: letter, openOnEnter: true),
      ),
    );
  }

  Future<void> _confirmDelete(FutureLetter letter) async {
    final ok = await showEchoActionSheet<bool>(
      context: context,
      message: '删除这封信？\n封存的内容将无法找回。',
      actions: [
        const EchoActionSheetItem(
          label: '删除',
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (ok == true) {
      await _service.delete(letter.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = _service.dueItems;
    final pending = _service.pendingItems;
    final opened = _service.openedItems;
    final isEmpty = due.isEmpty && pending.isEmpty && opened.isEmpty;

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
                    FutureLetterCopy.pageTitle,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    FutureLetterCopy.pageSubtitle,
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
                      _service.remindersEnabled ? '送达提醒开' : '送达提醒关',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: _service.remindersEnabled,
                    onChanged: _service.setRemindersEnabled,
                    activeColor: EchoColors.dayTextPrimary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: isEmpty
                  ? Center(
                      child: EchoEmptyState(
                        charm: EchoCharmKind.envelope,
                        message: FutureLetterCopy.emptyListLine,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(28, 8, 28, 100),
                      children: [
                        if (due.isNotEmpty) ...[
                          const _SectionLabel('今日可拆'),
                          ...due.map(
                            (l) => _LetterTile(
                              letter: l,
                              onTap: () => _openLetter(l),
                              onDelete: () => _confirmDelete(l),
                              highlight: true,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (pending.isNotEmpty) ...[
                          const _SectionLabel('封存中'),
                          ...pending.map(
                            (l) => _LetterTile(
                              letter: l,
                              onTap: () => _openLetter(l),
                              onDelete: () => _confirmDelete(l),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (opened.isNotEmpty) ...[
                          const _SectionLabel('已拆开'),
                          ...opened.map(
                            (l) => _LetterTile(
                              letter: l,
                              onTap: () => _openLetter(l),
                              onDelete: () => _confirmDelete(l),
                              opened: true,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTap(
        onTap: _openCompose,
        scale: 0.96,
        child: Container(
          margin: const EdgeInsets.only(right: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: EchoColors.dayTextPrimary,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(alpha: 0.18),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '写一封信',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: EchoColors.daySurface,
            ),
          ),
        ),
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
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w300,
          color: EchoColors.dayTextWhisper,
        ),
      ),
    );
  }
}

class _LetterTile extends StatelessWidget {
  const _LetterTile({
    required this.letter,
    required this.onTap,
    required this.onDelete,
    this.highlight = false,
    this.opened = false,
  });

  final FutureLetter letter;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool highlight;
  final bool opened;

  @override
  Widget build(BuildContext context) {
    final status = FutureLetterCopy.listStatus(letter);
    final tint = highlight
        ? const Color(0xFFE8EEF5)
        : opened
            ? EchoColors.dayWriting.withValues(alpha: 0.35)
            : EchoColors.daySurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ScaleTap(
        onTap: onTap,
        scale: 0.99,
        child: Container(
          decoration: BoxDecoration(
            color: tint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: highlight
                  ? const Color(0xFFB8C8D8).withValues(alpha: 0.55)
                  : EchoColors.dayDivider.withValues(alpha: 0.65),
              width: 0.5,
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(
                  opened
                      ? Icons.mail_outline
                      : highlight
                          ? Icons.mark_email_unread_outlined
                          : Icons.lock_outline,
                  size: 18,
                  color: highlight
                      ? EchoColors.dayTextPrimary
                      : EchoColors.dayTextWhisper,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      opened ? letter.previewLine() : '封存中的信',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: opened
                            ? EchoColors.dayTextPrimary
                            : EchoColors.dayTextSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: highlight
                            ? EchoColors.dayTextSecondary
                            : EchoColors.dayTextWhisper,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DiaryFormat.listDateLabel(letter.deliverAt)} 送达',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextWhisper,
                      ),
                    ),
                  ],
                ),
              ),
              ScaleTap(
                onTap: onDelete,
                scale: 0.9,
                child: Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.more_horiz,
                    size: 18,
                    color: EchoColors.dayTextWhisper,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FutureLetterComposePage extends StatefulWidget {
  const _FutureLetterComposePage();

  @override
  State<_FutureLetterComposePage> createState() =>
      _FutureLetterComposePageState();
}

class _FutureLetterComposePageState extends State<_FutureLetterComposePage> {
  final _controller = TextEditingController();
  FutureLetterPreset _preset = FutureLetterPreset.days30;
  DateTime? _customDate;
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  DateTime get _deliverAt {
    if (_customDate != null) {
      return DateTime(_customDate!.year, _customDate!.month, _customDate!.day);
    }
    return _preset.deliverFrom(DateTime.now());
  }

  Future<void> _pickCustomDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final first = today.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: _customDate ?? today,
      firstDate: first,
      lastDate: now.add(const Duration(days: 365 * 5)),
      helpText: '选择送达日',
    );
    if (picked != null) {
      setState(() {
        _customDate = picked;
        _preset = FutureLetterPreset.days30;
      });
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await FutureLetterService.instance.create(
        content: _controller.text,
        deliverAt: _deliverAt,
      );
      if (!mounted) return;
      final seed = EchoCollectibleService.instance.takeLastEarned();
      if (seed != null) {
        showCollectibleEarnedSnack(context, seed);
      }
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ArgumentError ? '${e.message}' : '保存失败',
            style: TextStyle(fontWeight: FontWeight.w300),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: EchoColors.dayTextPrimary,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final deliverLabel = DiaryFormat.listDateLabel(_deliverAt);

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
                    onTap: _saving ? null : () => Navigator.pop(context),
                    scale: 0.9,
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(
                        Icons.close,
                        size: 20,
                        color: EchoColors.dayTextSecondary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ScaleTap(
                    onTap: _saving ? null : _save,
                    scale: 0.96,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _saving ? '封存中…' : '封存',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          color: _saving
                              ? EchoColors.dayTextWhisper
                              : EchoColors.dayTextPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
                children: [
                  Text(
                    '写给未来的自己',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '将在 $deliverLabel 送达',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextWhisper,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _controller,
                    maxLines: 12,
                    minLines: 8,
                    maxLength: FutureLetter.maxContentLength,
                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                      height: 1.65,
                    ),
                    decoration: InputDecoration(
                      hintText: '想对未来的自己说什么…',
                      hintStyle: TextStyle(
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextWhisper,
                      ),
                      filled: true,
                      fillColor: EchoColors.dayWriting.withValues(alpha: 0.55),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: EchoColors.dayDivider.withValues(alpha: 0.6),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: EchoColors.dayDivider.withValues(alpha: 0.6),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color:
                              EchoColors.dayTextSecondary.withValues(alpha: 0.45),
                        ),
                      ),
                      contentPadding: const EdgeInsets.all(16),
                      counterStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextWhisper,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '何时送达',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final preset in FutureLetterPreset.values)
                        _PresetChip(
                          label: preset.label,
                          selected:
                              _customDate == null && _preset == preset,
                          onTap: () => setState(() {
                            _preset = preset;
                            _customDate = null;
                          }),
                        ),
                      _PresetChip(
                        label: _customDate == null
                            ? '自选日期'
                            : DiaryFormat.listDateLabel(_customDate!),
                        selected: _customDate != null,
                        onTap: _pickCustomDate,
                      ),
                    ],
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

class _PresetChip extends StatelessWidget {
  const _PresetChip({
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
            color: selected
                ? EchoColors.dayTextPrimary
                : EchoColors.dayTextSecondary,
          ),
        ),
      ),
    );
  }
}

class _FutureLetterReadPage extends StatefulWidget {
  const _FutureLetterReadPage({
    required this.letter,
    this.openOnEnter = false,
  });

  final FutureLetter letter;
  final bool openOnEnter;

  @override
  State<_FutureLetterReadPage> createState() => _FutureLetterReadPageState();
}

class _FutureLetterReadPageState extends State<_FutureLetterReadPage> {
  late FutureLetter _letter;

  @override
  void initState() {
    super.initState();
    _letter = widget.letter;
    if (widget.openOnEnter && !_letter.isOpened) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _markOpened());
    }
  }

  Future<void> _markOpened() async {
    await FutureLetterService.instance.open(_letter.id);
    if (!mounted) return;
    FutureLetter? updated;
    for (final l in FutureLetterService.instance.items) {
      if (l.id == _letter.id) {
        updated = l;
        break;
      }
    }
    if (updated != null) {
      setState(() => _letter = updated!);
    }
  }

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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(28, 8, 28, 40),
                children: [
                  Text(
                    '来自过去的你',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FutureLetterCopy.readFooter(_letter),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextWhisper,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                    decoration: BoxDecoration(
                      color: EchoColors.dayWriting.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: EchoColors.dayDivider.withValues(alpha: 0.6),
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      _letter.content,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                        color: EchoColors.dayTextPrimary,
                        height: 1.75,
                      ),
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
