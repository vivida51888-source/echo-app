import 'dart:math';

import '../services/echo_insight_service.dart';

/// 首页漂流瓶：每周随机 1～2 天出现，同一自然周内结果稳定。
abstract final class DriftBottleSchedule {
  static bool isVisibleOn(DateTime date) {
    final day = EchoInsightService.dateOnly(date);
    final weekStart = EchoInsightService.startOfWeek(day);
    final weekSeed = weekStart.millisecondsSinceEpoch ~/ 86400000;
    final rand = Random(weekSeed);

    final appearanceCount = rand.nextInt(2) + 1;
    final chosenWeekdays = <int>{};
    while (chosenWeekdays.length < appearanceCount) {
      chosenWeekdays.add(rand.nextInt(7) + 1);
    }

    return chosenWeekdays.contains(day.weekday);
  }
}
