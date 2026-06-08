import '../data/daily_quotes.dart';
import '../l10n/echo_strings.dart';
import '../services/diary_service.dart';
import '../utils/diary_format.dart';
import '../utils/home_moment.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// 同步数据到桌面小组件。
class WidgetBridgeService {
  WidgetBridgeService._();

  static final WidgetBridgeService instance = WidgetBridgeService._();

  static const androidWidgetName = 'EchoHomeWidget';
  static const iosAppGroupId = 'group.com.example.echo_app';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(iosAppGroupId);
      await syncFromApp();
    } catch (e, st) {
      if (kDebugMode) debugPrint('WidgetBridgeService.init: $e\n$st');
    }
  }

  Future<void> syncFromApp() async {
    try {
      final now = DateTime.now();
      final moment = HomeMoment.snapshot();
      final strings = EchoStrings.of();
      final phrase = moment.action == HomeMomentAction.showQuote && !strings.isEn
          ? DailyQuotes.forDate(now).text
          : strings.dailyPhrase(now);
      final pending = DiaryService.instance.diaries.length;

      await HomeWidget.saveWidgetData<String>('phrase', phrase);
      await HomeWidget.saveWidgetData<String>(
        'date',
        DiaryFormat.dateLine(now),
      );
      await HomeWidget.saveWidgetData<bool>(
        'hasToday',
        moment.action != HomeMomentAction.writeToday,
      );
      await HomeWidget.saveWidgetData<int>('diaryCount', pending);
      await HomeWidget.updateWidget(
        name: androidWidgetName,
        androidName: androidWidgetName,
        iOSName: 'EchoWidget',
      );
    } catch (e, st) {
      if (kDebugMode) debugPrint('WidgetBridgeService.sync: $e\n$st');
    }
  }
}
