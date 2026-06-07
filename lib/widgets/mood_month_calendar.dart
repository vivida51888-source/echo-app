import 'package:flutter/material.dart';

import '../models/weather_mood.dart';
import '../services/echo_stats_service.dart';
import '../theme/echo_colors.dart';
import '../utils/diary_format.dart';
import 'scale_tap.dart';

/// 按月展示每天的心情（心情月历），可点击有记录的日子。
class MoodMonthCalendar extends StatelessWidget {
  const MoodMonthCalendar({
    super.key,
    required this.days,
    this.onDayTap,
    this.compact = false,
  });

  final List<EchoDayStat> days;
  final ValueChanged<EchoDayStat>? onDayTap;
  final bool compact;

  static const _weekLabels = ['一', '二', '三', '四', '五', '六', '日'];

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = compact
            ? 38.0
            : ((constraints.maxWidth - 6 * 6) / 7).clamp(38.0, 46.0);

        final firstWeekday = days.first.date.weekday;
        final leading = firstWeekday - 1;
        final totalCells = leading + days.length;
        final rows = (totalCells / 7).ceil();

        return Column(
          children: [
            Row(
              children: List.generate(7, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      _weekLabels[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                        color: EchoColors.dayTextWhisper,
                      ),
                    ),
                  ),
                );
              }),
            ),
            SizedBox(height: compact ? 8 : 12),
            ...List.generate(rows, (row) {
              return Padding(
                padding: EdgeInsets.only(bottom: compact ? 5 : 7),
                child: Row(
                  children: List.generate(7, (col) {
                    final index = row * 7 + col - leading;
                    if (index < 0 || index >= days.length) {
                      return Expanded(child: SizedBox(height: cellSize + 6));
                    }
                    return Expanded(
                      child: Center(
                        child: _DayCell(
                          day: days[index],
                          size: cellSize,
                          onTap: onDayTap,
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.size,
    this.onTap,
  });

  final EchoDayStat day;
  final double size;
  final ValueChanged<EchoDayStat>? onTap;

  @override
  Widget build(BuildContext context) {
    final isToday = DiaryFormat.isToday(day.date);
    final tappable = day.hasDiary && onTap != null;
    final mood = day.moodWeather;
    final tint = day.hasDiary && mood != null
        ? WeatherMood.tintColor(mood)
        : EchoColors.dayWriting.withValues(alpha: 0.35);
    final spine = day.hasDiary && mood != null
        ? WeatherMood.spineColor(mood)
        : EchoColors.dayDivider;

    final cell = Container(
      width: size,
      height: size + 4,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isToday
              ? spine.withValues(alpha: 0.55)
              : day.hasDiary
                  ? spine.withValues(alpha: 0.22)
                  : EchoColors.dayDivider.withValues(alpha: 0.4),
          width: isToday ? 1.2 : 0.5,
        ),
        boxShadow: day.hasDiary
            ? [
                BoxShadow(
                  color: spine.withValues(alpha: 0.14),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 4,
            left: 0,
            right: 0,
            child: Text(
              '${day.date.day}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isToday ? FontWeight.w500 : FontWeight.w300,
                color: day.hasDiary
                    ? EchoColors.dayTextPrimary.withValues(alpha: 0.55)
                    : EchoColors.dayTextWhisper.withValues(alpha: 0.85),
                height: 1,
              ),
            ),
          ),
          if (day.hasDiary && mood != null)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  WeatherMood.fromDisplay(mood)?.emoji ??
                      mood.split(' ').first,
                  style: TextStyle(fontSize: size * 0.36, height: 1),
                ),
              ),
            ),
          if (day.entryCount > 1)
            Positioned(
              top: 2,
              right: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: EchoColors.dayTextPrimary.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${day.entryCount}',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w500,
                    color: EchoColors.daySurface,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (!tappable) return cell;

    return ScaleTap(
      onTap: () => onTap!(day),
      scale: 0.92,
      child: cell,
    );
  }
}
