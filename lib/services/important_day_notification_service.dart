import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/important_day.dart';
import '../theme/echo_colors.dart';
import '../utils/important_day_copy.dart';
import 'important_day_service.dart';
import 'todo_notification_service.dart';

class ImportantDayNotificationService {
  ImportantDayNotificationService._();

  static final ImportantDayNotificationService instance =
      ImportantDayNotificationService._();

  static const _channelId = 'echo_important_days';
  static const _idBase = 700000000;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  bool get _supportsNativeNotifications {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;
    await TodoNotificationService.instance.initialize();
    if (!_supportsNativeNotifications) {
      _initialized = true;
      return;
    }
    await _ensureAndroidChannel();
    _initialized = true;
    await syncAll();
  }

  Future<void> _ensureAndroidChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final channel = AndroidNotificationChannel(
      _channelId,
      ImportantDayCopy.notificationChannelName,
      description: ImportantDayCopy.notificationChannelDescription,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> syncAll() async {
    if (!_initialized || !_supportsNativeNotifications) return;

    final service = ImportantDayService.instance;
    for (final day in service.items) {
      await cancel(day.id);
    }
    if (!service.remindersEnabled) return;

    for (final day in service.enabledItems) {
      await syncOne(day);
    }
  }

  Future<void> syncOne(ImportantDay day) async {
    if (!_initialized ||
        !_supportsNativeNotifications ||
        !day.enabled ||
        !ImportantDayService.instance.remindersEnabled) {
      await cancel(day.id);
      return;
    }

    await cancel(day.id);
    if (day.isAnchor) {
      await _syncAnchor(day);
    } else {
      await _syncAnnual(day);
    }
  }

  Future<void> _syncAnnual(ImportantDay day) async {
    final now = DateTime.now();
    for (final daysBefore in day.remindDaysBefore.toSet()) {
      final when = _nextAnnualRemindAt(day, daysBefore, now);
      if (when == null) continue;

      final body = ImportantDayCopy.notificationBody(day, daysBefore);
      await _schedule(
        id: _annualNotificationId(day.id, daysBefore),
        when: when,
        body: body,
        dayId: day.id,
        repeatYearly: true,
      );
    }
  }

  Future<void> _syncAnchor(ImportantDay day) async {
    final now = DateTime.now();
    for (final entry in day.upcomingMilestones(now)) {
      final when = DateTime(
        entry.when.year,
        entry.when.month,
        entry.when.day,
        9,
        0,
      );
      if (!when.isAfter(now)) continue;

      final body =
          ImportantDayCopy.notificationBodyMilestone(day, entry.hit);
      await _schedule(
        id: _milestoneNotificationId(day.id, entry.hit),
        when: when,
        body: body,
        dayId: day.id,
        repeatYearly: false,
      );
    }
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String body,
    required String dayId,
    required bool repeatYearly,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        ImportantDayCopy.notificationTitle,
        body,
        scheduled,
        _details(body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'important_day:$dayId',
        matchDateTimeComponents: repeatYearly
            ? DateTimeComponents.dayOfMonthAndTime
            : null,
      );
    } catch (e, stack) {
      debugPrint('Echo: important day schedule failed: $e\n$stack');
    }
  }

  DateTime? _nextAnnualRemindAt(
    ImportantDay day,
    int daysBefore,
    DateTime from,
  ) {
    final event = _nextEventOnOrAfter(from, day.month, day.day);
    var remind = DateTime(
      event.year,
      event.month,
      event.day,
      9,
      0,
    ).subtract(Duration(days: daysBefore));

    if (!remind.isAfter(from)) {
      final nextEvent = DateTime(event.year + 1, day.month, day.day, 9, 0);
      remind = nextEvent.subtract(Duration(days: daysBefore));
    }

    return remind;
  }

  DateTime _nextEventOnOrAfter(DateTime from, int month, int day) {
    var candidate = DateTime(from.year, month, day);
    final fromDay = DateTime(from.year, from.month, from.day);
    if (!candidate.isBefore(fromDay)) return candidate;
    return DateTime(from.year + 1, month, day);
  }

  NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        ImportantDayCopy.notificationChannelName,
        channelDescription: ImportantDayCopy.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        color: EchoColors.todoCompletedFill,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: ImportantDayCopy.notificationTitle,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );
  }

  Future<void> cancel(String dayId) async {
    if (!_initialized || !_supportsNativeNotifications) return;
    for (final offset in ImportantDayCopy.remindOptions.keys) {
      await _plugin.cancel(_annualNotificationId(dayId, offset));
    }
    for (final count in [52, 99, 100, 520, 1314]) {
      await _plugin.cancel(_milestoneNotificationId(
        dayId,
        ImportantDayMilestoneHit(dayCount: count),
      ));
    }
    for (var y = 1; y <= ImportantDay.anchorYearHorizon; y++) {
      await _plugin.cancel(_milestoneNotificationId(
        dayId,
        ImportantDayMilestoneHit(yearCount: y),
      ));
    }
  }

  int _annualNotificationId(String dayId, int daysBefore) =>
      _idBase + dayId.hashCode.abs() % 500000 + daysBefore;

  int _milestoneNotificationId(String dayId, ImportantDayMilestoneHit hit) {
    final slot = ImportantDayCopy.milestoneSlot(hit);
    return _idBase +
        500000 +
        dayId.hashCode.abs() % 400000 +
        slot.hashCode.abs() % 100000;
  }
}
