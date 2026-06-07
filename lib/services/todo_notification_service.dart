import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/todo_reminder.dart';
import '../theme/echo_colors.dart';
import '../utils/china_workday_calendar.dart';
import '../utils/todo_copy.dart';
import '../utils/todo_schedule.dart';
import 'todo_service.dart';

/// 点击通知后由 [MainShell] 注册，用于切到待办 Tab。
typedef TodoReminderTapHandler = void Function(String todoId);

class TodoNotificationService {
  TodoNotificationService._();

  static final TodoNotificationService instance = TodoNotificationService._();

  static const _channelId = 'echo_todo';
  static const _channelName = '回响提醒';
  static const _channelDescription = 'Echo 温柔的待办提醒，不催促，只轻轻唤起';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Timer? _purgeTimer;
  TodoReminderTapHandler? _onReminderTap;

  bool get _supportsNativeNotifications {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  void setReminderTapHandler(TodoReminderTapHandler? handler) {
    _onReminderTap = handler;
  }

  /// 注册待办提醒通知渠道与权限（Android / iOS）。
  Future<void> initialize() async {
    if (_initialized) return;

    if (!_supportsNativeNotifications) {
      _initialized = true;
      return;
    }

    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationResponse,
    );

    await _ensureAndroidChannel();
    await _requestPermissions();

    _initialized = true;
    _purgeTimer?.cancel();
    _purgeTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => purgeExpiredTodos(),
    );
    await purgeExpiredTodos();
    await syncAll();
  }

  /// 到期未安放的待办自动休眠，并取消已清除项的通知。
  Future<void> purgeExpiredTodos() async {
    await TodoService.instance.processAutoSleep();
  }

  Future<void> _configureLocalTimezone() async {
    tz_data.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Echo: timezone fallback to local: $e');
      tz.setLocalLocation(tz.local);
    }
  }

  Future<void> _ensureAndroidChannel() async {
    if (defaultTargetPlatform != TargetPlatform.android) return;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
  }

  /// 保存待办后确认通知权限；返回是否可正常投递提醒。
  Future<bool> ensureReadyForReminders() async {
    if (!_supportsNativeNotifications) return true;
    if (!_initialized) await initialize();
    return _notificationsEnabled();
  }

  /// 从通知冷启动 App 时，在 [MainShell] 注册点击回调后调用。
  Future<void> processLaunchNotification() async {
    if (!_initialized) return;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      _handlePayload(details!.notificationResponse?.payload);
    }
  }

  Future<bool> _requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      final notificationGranted =
          await androidPlugin?.requestNotificationsPermission() ?? true;

      final canExact =
          await androidPlugin?.canScheduleExactNotifications() ?? false;
      if (!canExact) {
        await androidPlugin?.requestExactAlarmsPermission();
      }

      return notificationGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await iosPlugin?.requestPermissions(
            alert: true,
            badge: false,
            sound: false,
          ) ??
          false;
      return granted;
    }

    return true;
  }

  Future<bool> _notificationsEnabled() async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      var enabled = await androidPlugin?.areNotificationsEnabled() ?? false;
      if (!enabled) {
        enabled =
            await androidPlugin?.requestNotificationsPermission() ?? false;
      }
      if (enabled) {
        final canExact =
            await androidPlugin?.canScheduleExactNotifications() ?? false;
        if (!canExact) {
          await androidPlugin?.requestExactAlarmsPermission();
        }
      }
      return enabled;
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      return await iosPlugin?.requestPermissions(
            alert: true,
            badge: false,
            sound: false,
          ) ??
          false;
    }

    return true;
  }

  NotificationDetails _notificationDetails(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        color: EchoColors.todoCompletedFill,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: TodoCopy.notificationTitle,
          summaryText: TodoCopy.notificationSummary,
        ),
        ticker: TodoCopy.notificationTitle,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
        subtitle: TodoCopy.notificationSummary,
      ),
    );
  }

  Future<void> syncAll() async {
    if (!_initialized || !_supportsNativeNotifications) return;
    await _plugin.cancelAll();
    final now = DateTime.now();
    for (final todo in TodoService.instance.items) {
      if (!todo.isPermanentlyCompleted) {
        await schedule(todo, now: now);
      }
    }
  }

  Future<void> schedule(TodoReminder todo, {DateTime? now}) async {
    if (!_initialized ||
        !_supportsNativeNotifications ||
        todo.isPermanentlyCompleted) {
      return;
    }

    final current = now ?? DateTime.now();
    var when = todo.reminderAt;
    if (todo.repeat == TodoRepeat.workday) {
      when = ChinaWorkdayCalendar.ensureWorkdayReminder(when, now: current);
    }
    if (!when.isAfter(current)) {
      if (todo.repeat == TodoRepeat.none) return;
      when = todo.repeat == TodoRepeat.workday
          ? ChinaWorkdayCalendar.nextOccurrenceAfter(
              current,
              hour: todo.reminderAt.hour,
              minute: todo.reminderAt.minute,
            )
          : _nextOccurrence(todo, current);
    }

    final scheduled = tz.TZDateTime.from(when, tz.local);
    final body = TodoCopy.notificationBody(todo.content);
    final mode = await _androidScheduleMode();

    try {
      await _plugin.zonedSchedule(
        _notificationId(todo.id),
        TodoCopy.notificationTitle,
        body,
        scheduled,
        _notificationDetails(body),
        androidScheduleMode: mode,
        payload: _payloadFor(todo.id),
        matchDateTimeComponents: _matchComponents(todo.repeat),
      );
    } catch (e, stack) {
      debugPrint('Echo: schedule notification failed: $e\n$stack');
    }
  }

  Future<AndroidScheduleMode> _androidScheduleMode() async {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final canExact =
        await androidPlugin?.canScheduleExactNotifications() ?? false;

    return canExact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }

  DateTimeComponents? _matchComponents(TodoRepeat repeat) {
    switch (repeat) {
      case TodoRepeat.none:
        return null;
      case TodoRepeat.daily:
        return DateTimeComponents.time;
      case TodoRepeat.alternateDay:
        return null;
      case TodoRepeat.weekly:
        return DateTimeComponents.dayOfWeekAndTime;
      case TodoRepeat.monthly:
        return DateTimeComponents.dayOfMonthAndTime;
      case TodoRepeat.workday:
        return null;
    }
  }

  DateTime _nextOccurrence(TodoReminder todo, DateTime from) {
    return TodoSchedule.nextOccurrence(todo, after: from);
  }

  Future<void> cancel(String todoId) async {
    if (!_initialized || !_supportsNativeNotifications) return;
    await _plugin.cancel(_notificationId(todoId));
  }

  /// 调试用：约 8 秒后弹出一条测试通知。
  Future<void> showTestNotification() async {
    if (!_initialized || !_supportsNativeNotifications) return;

    final when = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 8));
    const body = '这是一条温柔的测试提醒。';

    await _plugin.zonedSchedule(
      999001,
      TodoCopy.notificationTitle,
      body,
      when,
      _notificationDetails(body),
      androidScheduleMode: await _androidScheduleMode(),
      payload: 'todo:test',
    );
  }

  int _notificationId(String todoId) => todoId.hashCode.abs() % 2147483647;

  String _payloadFor(String todoId) => 'todo:$todoId';

  void _onNotificationResponse(NotificationResponse response) {
    _handlePayload(response.payload);
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationResponse(NotificationResponse response) {
    // 仅记录；点击一般在回到前台时由 onDidReceiveNotificationResponse 处理。
  }

  void _handlePayload(String? payload) {
    if (payload == null || !payload.startsWith('todo:')) return;
    final todoId = payload.substring(4);
    if (todoId == 'test') return;
    _onReminderTap?.call(todoId);
  }
}
