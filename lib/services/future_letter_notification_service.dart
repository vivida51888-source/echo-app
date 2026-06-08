import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/future_letter.dart';
import '../theme/echo_colors.dart';
import '../utils/future_letter_copy.dart';
import 'future_letter_service.dart';
import 'todo_notification_service.dart';

class FutureLetterNotificationService {
  FutureLetterNotificationService._();

  static final FutureLetterNotificationService instance =
      FutureLetterNotificationService._();

  static const _channelId = 'echo_future_letters';
  static const _idBase = 800000000;

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
      FutureLetterCopy.notificationChannelName,
      description: FutureLetterCopy.notificationChannelDescription,
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: false,
      showBadge: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
  }

  Future<void> syncAll() async {
    if (!_initialized || !_supportsNativeNotifications) return;

    final service = FutureLetterService.instance;
    for (final letter in service.items) {
      await cancel(letter.id);
    }
    if (!service.remindersEnabled) return;

    for (final letter in service.pendingItems) {
      await syncOne(letter);
    }
    for (final letter in service.dueItems) {
      await syncOne(letter);
    }
  }

  Future<void> syncOne(FutureLetter letter) async {
    if (!_initialized ||
        !_supportsNativeNotifications ||
        letter.isOpened ||
        !FutureLetterService.instance.remindersEnabled) {
      await cancel(letter.id);
      return;
    }

    await cancel(letter.id);

    final now = DateTime.now();
    final when = DateTime(
      letter.deliverAt.year,
      letter.deliverAt.month,
      letter.deliverAt.day,
      9,
      0,
    );
    if (!when.isAfter(now) && !letter.isDue(now)) return;

    final scheduleAt =
        when.isAfter(now) ? when : now.add(const Duration(minutes: 1));

    await _schedule(
      id: _notificationId(letter.id),
      when: scheduleAt,
      body: FutureLetterCopy.notificationBody(letter),
      letterId: letter.id,
    );
  }

  Future<void> _schedule({
    required int id,
    required DateTime when,
    required String body,
    required String letterId,
  }) async {
    final scheduled = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id,
        FutureLetterCopy.notificationTitle,
        body,
        scheduled,
        _details(body),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: 'future_letter:$letterId',
      );
    } catch (e, stack) {
      debugPrint('Echo: future letter schedule failed: $e\n$stack');
    }
  }

  NotificationDetails _details(String body) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        FutureLetterCopy.notificationChannelName,
        channelDescription: FutureLetterCopy.notificationChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        playSound: false,
        enableVibration: false,
        icon: '@mipmap/ic_launcher',
        color: EchoColors.dayWriting,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: FutureLetterCopy.notificationTitle,
        ),
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: false,
        presentSound: false,
      ),
    );
  }

  Future<void> cancel(String letterId) async {
    if (!_initialized || !_supportsNativeNotifications) return;
    await _plugin.cancel(_notificationId(letterId));
  }

  Future<void> cancelAll() async {
    if (!_initialized || !_supportsNativeNotifications) return;
    for (final letter in FutureLetterService.instance.items) {
      await cancel(letter.id);
    }
  }

  int _notificationId(String letterId) =>
      _idBase + letterId.hashCode.abs() % 100000000;
}
