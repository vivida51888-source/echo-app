import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/echo_strings.dart';
import '../l10n/localized.dart';
import '../models/future_letter.dart';
import '../navigation/app_page_route.dart';
import '../services/future_letter_service.dart';
import '../services/locale_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import '../utils/future_letter_copy.dart';
import '../services/echo_reward_service.dart';
import '../widgets/echo_action_sheet.dart';
import '../widgets/echo_confirm_sheet.dart';
import '../widgets/echo_hint.dart';
import '../widgets/echo_moment_toast.dart';
import '../widgets/echo_charm.dart';
import '../widgets/echo_coin_collect_overlay.dart';
import '../widgets/echo_coin_icon.dart';
import '../widgets/echo_empty_state.dart';
import '../widgets/future_letter_stationery.dart';
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

    if (!letter.isDue()) return;

    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) => _FutureLetterReadPage(letter: letter, openOnEnter: true),
      ),
    );
  }

  Future<void> _openEarly(FutureLetter letter) async {
    if (letter.isOpened || letter.isDue()) return;

    final cost = letter.earlyOpenCoinCost();
    final daysLeft = letter.daysUntil();
    final rewards = EchoRewardService.instance;
    if (!rewards.canAffordCoins(cost)) {
      await showEchoMomentToast(
        context,
        message: tr(
          '回响币不足，还需 ${cost - rewards.coins} 枚',
          'Need ${cost - rewards.coins} more Echo coins',
        ),
        kind: EchoMomentToastKind.coins,
      );
      return;
    }
    final confirmed = await showEchoConfirmSheet(
      context,
      title: tr('提前拆开', 'Open early'),
      message: FutureLetterCopy.earlyOpenPrompt(cost, daysLeft),
      confirmLabel: tr('消耗 $cost 回响币拆开', 'Open for $cost coins'),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFC99A3A).withValues(alpha: 0.14),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: EchoCoinIcon(size: 26),
        ),
      ),
    );
    if (!confirmed || !mounted) return;
    final ok = await _service.openEarly(letter.id);
    if (!mounted) return;
    if (ok) {
      await EchoCoinCollectOverlay.playSpend(context, amount: cost);
    }
    if (!mounted) return;
    if (!ok) {
      showEchoBriefHint(
        context,
        message: tr('拆开失败，请稍后再试', 'Could not open — try again'),
        tone: EchoBriefHintTone.gentle,
      );
      return;
    }
    final updated = _service.items.firstWhere((l) => l.id == letter.id);
    await Navigator.of(context).push(
      AppPageRoute<void>(
        builder: (_) =>
            _FutureLetterReadPage(letter: updated, openOnEnter: true),
      ),
    );
  }

  Future<void> _confirmDelete(FutureLetter letter) async {
    final ok = await showEchoActionSheet<bool>(
      context: context,
      message: tr(
        '删除这封信？\n封存的内容将无法找回。',
        'Delete this letter?\nSealed content cannot be recovered.',
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
      await _service.delete(letter.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final due = _service.dueItems;
    final pending = _service.pendingItems;
    final opened = _service.openedItems;
    final isEmpty = due.isEmpty && pending.isEmpty && opened.isEmpty;

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
                      _service.remindersEnabled
                          ? tr('送达提醒开', 'Delivery reminders on')
                          : tr('送达提醒关', 'Delivery reminders off'),
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
                          _SectionLabel(tr('今日可拆', 'Ready today')),
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
                          _SectionLabel(tr('封存中', 'Sealed')),
                          ...pending.map(
                            (l) => _LetterTile(
                              letter: l,
                              onTap: () => _openLetter(l),
                              onEarlyOpen: () => _openEarly(l),
                              onDelete: () => _confirmDelete(l),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                        if (opened.isNotEmpty) ...[
                          _SectionLabel(tr('已拆开', 'Opened')),
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
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          decoration: BoxDecoration(
            color: EchoColors.isDark
                ? const Color(0xFF353230)
                : const Color(0xFFEADFD0),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: EchoColors.dayDivider.withValues(alpha: 0.75),
              width: 0.6,
            ),
            boxShadow: [
              BoxShadow(
                color: EchoColors.dayTextPrimary.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.edit_outlined,
                size: 16,
                color: EchoColors.dayTextSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                tr('写一封信', 'Write a letter'),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: EchoColors.dayTextPrimary,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
      },
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
    this.onEarlyOpen,
    this.highlight = false,
    this.opened = false,
  });

  final FutureLetter letter;
  final VoidCallback onTap;
  final VoidCallback? onEarlyOpen;
  final VoidCallback onDelete;
  final bool highlight;
  final bool opened;

  FutureLetterVisualState get _visualState {
    if (opened) return FutureLetterVisualState.opened;
    if (highlight) return FutureLetterVisualState.ready;
    return FutureLetterVisualState.sealed;
  }

  @override
  Widget build(BuildContext context) {
    final tappable = opened || highlight;
    final envelope = FutureLetterEnvelopeTile(
      letter: letter,
      state: _visualState,
      onDelete: onDelete,
      footer: onEarlyOpen == null
          ? null
          : _EarlyOpenButton(
              cost: letter.earlyOpenCoinCost(),
              onTap: onEarlyOpen!,
            ),
    );

    if (!tappable) return envelope;

    return ScaleTap(
      onTap: onTap,
      scale: 0.985,
      child: envelope,
    );
  }
}

class _EarlyOpenButton extends StatelessWidget {
  const _EarlyOpenButton({
    required this.cost,
    required this.onTap,
  });

  final int cost;
  final VoidCallback onTap;

  static const _coinTint = Color(0xFFC99A3A);

  @override
  Widget build(BuildContext context) {
    return ScaleTap(
      onTap: onTap,
      scale: 0.96,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: EchoColors.daySurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: _coinTint.withValues(alpha: 0.35),
            width: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: EchoColors.dayTextPrimary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EchoCoinIcon(size: 16),
            const SizedBox(width: 7),
            Text(
              tr('提前拆开', 'Open early'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: EchoColors.dayTextPrimary,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                width: 0.5,
                height: 14,
                color: EchoColors.dayDivider.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '$cost',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _coinTint,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
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
      helpText: tr('选择送达日', 'Choose delivery date'),
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
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showEchoBriefHint(
        context,
        message: e is ArgumentError ? '${e.message}' : tr('保存失败', 'Save failed'),
        tone: EchoBriefHintTone.gentle,
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
                        _saving ? tr('封存中…', 'Sealing…') : tr('封存', 'Seal'),
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
                    tr('写给未来的自己', 'To your future self'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w300,
                      color: EchoColors.dayTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('将在 $deliverLabel 送达', 'Due on $deliverLabel'),
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
                      hintText: tr(
                        '想对未来的自己说什么…',
                        'What do you want to tell your future self…',
                      ),
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
                          color: EchoColors.dayTextSecondary
                              .withValues(alpha: 0.45),
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
                    tr('何时送达', 'Deliver when'),
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
                            ? tr('自选日期', 'Pick a date')
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
                    tr('来自过去的你', 'From your past self'),
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
