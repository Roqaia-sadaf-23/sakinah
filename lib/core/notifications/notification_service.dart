import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../utils/timezone_utils.dart';

enum NotificationPermissionState { granted, denied, unsupported }

class LocalNotificationRequest {
  const LocalNotificationRequest({
    required this.id,
    required this.title,
    required this.body,
    required this.scheduledDate,
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.payload,
  });

  final int id;
  final String title;
  final String body;
  final tz.TZDateTime scheduledDate;
  final String channelId;
  final String channelName;
  final String channelDescription;
  final String payload;
}

abstract class NotificationService {
  Future<void> initialize();

  Future<String> refreshLocalTimezone();

  Future<bool> areNotificationsEnabled();

  Future<NotificationPermissionState> requestNotificationPermission();

  Future<bool> canScheduleExactNotifications();

  Future<bool> requestExactAlarmPermission();

  Future<bool> openAppNotificationSettings();

  Future<void> schedule(LocalNotificationRequest request);

  Future<void> cancel(int id);
}

class FlutterLocalNotificationService implements NotificationService {
  FlutterLocalNotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  Future<void>? _initialization;
  String _localTimezoneIdentifier = 'UTC';

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    TimezoneUtils.ensureInitialized();
    await refreshLocalTimezone();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
  }

  @override
  Future<String> refreshLocalTimezone() async {
    TimezoneUtils.ensureInitialized();
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(deviceTimezone.identifier);
      tz.setLocalLocation(location);
      _localTimezoneIdentifier = deviceTimezone.identifier;
    } catch (error) {
      if (kDebugMode) {
        debugPrint(
          '[PrayerNotification] Could not resolve device timezone; '
          'using $_localTimezoneIdentifier: $error',
        );
      }
      tz.setLocalLocation(TimezoneUtils.location(_localTimezoneIdentifier));
    }
    if (kDebugMode) {
      debugPrint(
        '[PrayerNotification] Device timezone=$_localTimezoneIdentifier '
        'now=${DateTime.now().toIso8601String()}',
      );
    }
    return _localTimezoneIdentifier;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<bool> areNotificationsEnabled() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.areNotificationsEnabled() ?? false;
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return (await ios?.checkPermissions())?.isEnabled ?? false;
    }
    return true;
  }

  @override
  Future<NotificationPermissionState> requestNotificationPermission() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _android?.requestNotificationsPermission();
      return granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted == true
          ? NotificationPermissionState.granted
          : NotificationPermissionState.denied;
    }

    return NotificationPermissionState.unsupported;
  }

  @override
  Future<bool> canScheduleExactNotifications() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.canScheduleExactNotifications() ?? false;
    }
    return true;
  }

  @override
  Future<bool> requestExactAlarmPermission() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return await _android?.requestExactAlarmsPermission() ?? false;
    }
    return true;
  }

  @override
  Future<bool> openAppNotificationSettings() async {
    await initialize();
    return await _plugin.openAppNotificationSettings() ?? false;
  }

  @override
  Future<void> schedule(LocalNotificationRequest request) async {
    await initialize();

    // A verified short Takbeer can later be placed in
    // android/app/src/main/res/raw and wired to the dedicated Takbeer channel.
    // Until then both reminder channels intentionally use the system sound.
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        request.channelId,
        request.channelName,
        channelDescription: request.channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
        playSound: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    final exactAvailable = await canScheduleExactNotifications();
    final preferredMode = exactAvailable
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
    if (kDebugMode) {
      debugPrint(
        '[PrayerNotification] Scheduling id=${request.id} '
        'at=${request.scheduledDate} mode=${preferredMode.name}',
      );
    }

    try {
      await _zonedSchedule(request, details, preferredMode);
    } on PlatformException catch (error) {
      if (!exactAvailable) rethrow;
      if (kDebugMode) {
        debugPrint(
          '[PrayerNotification] Exact scheduling failed for id=${request.id}; '
          'retrying inexact: $error',
        );
      }
      await _zonedSchedule(
        request,
        details,
        AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _zonedSchedule(
    LocalNotificationRequest request,
    NotificationDetails details,
    AndroidScheduleMode mode,
  ) => _plugin.zonedSchedule(
    id: request.id,
    title: request.title,
    body: request.body,
    scheduledDate: request.scheduledDate,
    notificationDetails: details,
    androidScheduleMode: mode,
    payload: request.payload,
  );

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }
}
