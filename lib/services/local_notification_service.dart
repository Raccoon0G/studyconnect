import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:vibration/vibration.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifier =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
    );

    await _notifier.initialize(initSettings);
  }

  static Future<void> show({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'canal_id',
          'Canal de notificaciones',
          importance: Importance.max,
          priority: Priority.high,
          color: Colors.blue,
          playSound: true,
        );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
    );

    await _notifier.show(id, title, body, platformDetails);

    // Vibración opcional (solo si está disponible)
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 300);
    }
  }
}
