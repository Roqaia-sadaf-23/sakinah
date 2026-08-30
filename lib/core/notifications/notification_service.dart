import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

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

  @override
  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
    tz_data.initializeTimeZones();
    try {
      final deviceTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTimezone.identifier));
    } catch (error) {
      debugPrint('Could not resolve device timezone: $error');
      tz.setLocalLocation(tz.UTC);
    }

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
    return true;
  }

  @override
  Future<NotificationPermissionState> requestNotificationPermission() async {
    await initialize();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _android?.requestNotificationsPermission();
      return granted == false
          ? NotificationPermissionState.denied
          : NotificationPermissionState.granted;
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
      return granted == false
          ? NotificationPermissionState.denied
          : NotificationPermissionState.granted;
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

    await _plugin.zonedSchedule(
      id: request.id,
      title: request.title,
      body: request.body,
      scheduledDate: request.scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: request.payload,
    );
  }

  @override
  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }
}
