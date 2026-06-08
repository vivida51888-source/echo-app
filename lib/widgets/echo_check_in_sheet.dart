import 'package:flutter/material.dart';

import '../l10n/localized.dart';
import '../models/echo_check_in.dart';
import '../services/echo_check_in_service.dart';
import '../theme/echo_colors.dart';
import '../theme/echo_radii.dart';
import '../theme/echo_typography.dart';
import 'echo_coin_collect_overlay.dart';
import 'echo_coin_icon.dart';
import 'echo_hint.dart';
import 'echo_moment_toast.dart';
import 'scale_tap.dart';

Future<void> showEchoCheckInSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _EchoCheckInSheet(),
  );
}

class _EchoCheckInSheet extends StatefulWidget {
  const _EchoCheckInSheet();

  @override
  State<_EchoCheckInSheet> createState() => _EchoCheckInSheetState();
}

class _EchoCheckInSheetState extends State<_EchoCheckInSheet> {
  final _service = EchoCheckInService.instance;
  var _claiming = false;

  @override
  void initState() {
    super.initState();
    _service.addListener(_rebuild);
  }

  @override
  void dispose() {
    _service.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  Future<void> _claimToday() async {
    if (_claiming || !_service.canCheckInToday) return;
    setState(() => _claiming = true);
    final reward = await _service.checkInToday();
    if (!mounted) return;
    setState(() => _claiming = false);
    _showClaimSnack(reward);
  }

  Future<void> _onDayTap(int day, DateTime month) async {
    if (_claiming || !_service.canClaimDay(day)) {
      if (day < month.day &&
          !_service.isDayChecked(day) &&
          _service.makeupUsedToday) {
        _showMakeupLimitSnack();
      }
      return;
    }

    setState(() => _claiming = true);
    final reward = day == month.day
        ? await _service.checkInToday()
        : await _service.makeUpDay(day);
    if (!mounted) return;
    setState(() => _claiming = false);
    _showClaimSnack(reward);
  }

  Future<void> _showClaimSnack(EchoCheckInReward? reward) async {
    if (reward == null || !mounted) return;
    if (reward.coins > 0) {
      final size = MediaQuery.sizeOf(context);
      await EchoCoinCollectOverlay.playEarn(
        context,
        amount: reward.coins,
        from: Offset(size.width * 0.5, size.height * 0.62),
      );
    }
    if (!mounted) return;
    await showEchoMomentToast(
      context,
      message: tr('签到成功 · ${reward.label}', 'Checked in · ${reward.label}'),
    );
  }

  void _showMakeupLimitSnack() {
    showEchoBriefHint(
      context,
      message: tr('今日补签次数已用完', 'Makeup check-in used for today'),
      tone: EchoBriefHintTone.gentle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewPaddingOf(context).bottom;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday;
    final leadingBlanks = firstWeekday - 1;
    final canClaimToday = _service.canCheckInToday;
    final checked = _service.checkedDaysThisMonth.toSet();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.88,
      ),
      decoration: BoxDecoration(
        color: EchoColors.daySurface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(EchoRadii.xl),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 12, 24, bottom + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: EchoColors.dayDivider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _CheckInHeader(
              year: now.year,
              month: now.month,
              checkedDays: _service.checkedCountThisMonth,
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  Expanded(
                    child: Center(
                      child: Text(
                        _weekdayLabels()[i],
                        style: EchoTypography.micro.copyWith(
                          color: i == 6
                              ? const Color(0xFF6B4E8A)
                              : const Color(0xFF3D5A80),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.58,
                ),
                itemCount: leadingBlanks + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingBlanks) {
                    return const SizedBox.shrink();
                  }
                  final day = index - leadingBlanks + 1;
                  final date = DateTime(now.year, now.month, day);
                  final reward = _service.rewardForDay(day, now);
                  final isChecked = checked.contains(day);
                  final isToday = day == now.day;
                  final isMissed = day < now.day && !isChecked;
                  final canTap = _service.canClaimDay(day);

                  return ScaleTap(
                    onTap: canTap ? () => _onDayTap(day, now) : null,
                    scale: 0.97,
                    child: _MonthDayCell(
                      date: date,
                      reward: reward,
                      isToday: isToday,
                      isChecked: isChecked,
                      isMissed: isMissed,
                      canTap: canTap,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            const _CheckInMakeupHint(),
            const SizedBox(height: 12),
            ScaleTap(
              onTap: canClaimToday && !_claiming ? _claimToday : null,
              scale: 0.98,
              child: AnimatedOpacity(
                opacity: canClaimToday ? 1 : 0.45,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: EchoColors.dayTextPrimary,
                    borderRadius: BorderRadius.circular(EchoRadii.md),
                  ),
                  child: Text(
                    canClaimToday
                        ? tr('领取今日奖励', 'Claim today\'s reward')
                        : tr('今日已签到', 'Checked in today'),
                    style: EchoTypography.labelLarge.copyWith(
                      color: EchoColors.daySurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _weekdayLabels() => isEnUi
      ? const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
      : const ['一', '二', '三', '四', '五', '六', '日'];

}

class _CheckInMakeupHint extends StatelessWidget {
  const _CheckInMakeupHint();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF3D5A80).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: const Color(0xFF3D5A80).withValues(alpha: 0.22),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Icon(
            Icons.event_repeat_outlined,
            size: 18,
            color: Color(0xFF2E4A6E),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              tr('漏签日期可点击补签，每天只能补签一次', 'Tap missed days to make up — once per day'),
              style: EchoTypography.labelMedium.copyWith(
                color: EchoColors.dayTextPrimary,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckInHeader extends StatelessWidget {
  const _CheckInHeader({
    required this.year,
    required this.month,
    required this.checkedDays,
  });

  final int year;
  final int month;
  final int checkedDays;

  @override
  Widget build(BuildContext context) {
    final monthLabel = isEnUi ? _monthNameEn(month) : '$month';

    final subtitle = tr('$year 年 $monthLabel 月 · 已签 $checkedDays 天', '$monthLabel $year · $checkedDays days');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFE8F1FB).withValues(alpha: 0.7),
            const Color(0xFFF3EBFF).withValues(alpha: 0.65),
          ],
        ),
        borderRadius: BorderRadius.circular(EchoRadii.md),
        border: Border.all(
          color: EchoColors.dayDivider.withValues(alpha: 0.45),
          width: 0.5,
        ),
      ),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
          const Icon(
            Icons.card_giftcard_rounded,
            size: 16,
            color: Color(0xFF5A7A9A),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr('当月签到奖励', 'This month\'s rewards'),
                style: EchoTypography.labelLarge.copyWith(
                  color: EchoColors.dayTextPrimary,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
              Text(
                subtitle,
                style: EchoTypography.micro.copyWith(
                  color: EchoColors.dayTextSecondary,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
        ),
      ),
    );
  }

  String _monthNameEn(int month) {
    const names = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month];
  }
}

class _MonthDayCell extends StatelessWidget {
  const _MonthDayCell({
    required this.date,
    required this.reward,
    required this.isToday,
    required this.isChecked,
    required this.isMissed,
    required this.canTap,
  });

  final DateTime date;
  final EchoCheckInReward reward;
  final bool isToday;
  final bool isChecked;
  final bool isMissed;
  final bool canTap;

  @override
  Widget build(BuildContext context) {
    final dimmed = isChecked;
    final isSunday = EchoCheckInColors.isSunday(date);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 3),
          decoration: BoxDecoration(
            color: EchoCheckInColors.dateBackground(date, dimmed: dimmed),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            border: isToday && !isChecked
                ? Border.all(
                    color: const Color(0xFFC99A3A).withValues(alpha: 0.7),
                    width: 1.2,
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            '${date.day}',
            style: EchoTypography.labelMedium.copyWith(
              color: EchoCheckInColors.dateText(date, dimmed: dimmed),
              fontWeight: isToday ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            decoration: BoxDecoration(
              color: EchoCheckInColors.rewardBackground(date, dimmed: dimmed),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(6),
              ),
              border: Border.all(
                color: EchoCheckInColors.rewardBorder(date, dimmed: dimmed),
                width: 0.8,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                _RewardPreview(
                  reward: reward,
                  dimmed: dimmed,
                  onDark: !dimmed,
                ),
                if (isChecked)
                  Positioned(
                    top: 0,
                    right: 2,
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 13,
                      color: isSunday
                          ? const Color(0xFFE8D4FF)
                          : const Color(0xFFB8D4F0),
                    ),
                  ),
                if (isMissed && canTap)
                  Positioned(
                    bottom: 0,
                    child: Text(
                      tr('补', 'Fix'),
                      style: EchoTypography.micro.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RewardPreview extends StatelessWidget {
  const _RewardPreview({
    required this.reward,
    required this.dimmed,
    required this.onDark,
  });

  final EchoCheckInReward reward;
  final bool dimmed;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final coinColor = dimmed
        ? const Color(0xFFC99A3A).withValues(alpha: 0.5)
        : onDark
            ? const Color(0xFFFFE9A8)
            : const Color(0xFFC99A3A);
    final bubbleColor = dimmed
        ? const Color(0xFF8FD4E8).withValues(alpha: 0.5)
        : onDark
            ? const Color(0xFFB8EEFF)
            : const Color(0xFF6B9EAE);
    final textColor = dimmed
        ? Colors.white.withValues(alpha: 0.45)
        : Colors.white.withValues(alpha: 0.95);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (reward.coins > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              EchoCoinIcon(size: 11, color: coinColor),
              const SizedBox(width: 2),
              Text(
                '${reward.coins}',
                style: EchoTypography.micro.copyWith(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        if (reward.coins > 0 && reward.bubbleGrams > 0) const SizedBox(height: 2),
        if (reward.bubbleGrams > 0)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bubble_chart_outlined, size: 11, color: bubbleColor),
              const SizedBox(width: 2),
              Text(
                '${reward.bubbleGrams}g',
                style: EchoTypography.micro.copyWith(
                  color: textColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
      ],
    );
  }
}
