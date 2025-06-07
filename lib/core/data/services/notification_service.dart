// notification_service.dart
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      debugPrint("Inicializando servicio de notificaciones");
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      tz.initializeTimeZones();
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint("Servicio de notificaciones inicializado exitosamente");
    } catch (e) {
      debugPrint("Error inicializando notificaciones: $e");
    }
  }

  Future<void> showNotification(String title, String body) async {
    try {
      debugPrint("Mostrando notificación: $title");
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'canal_pagos', 
        'Notificaciones de Pagos',
        importance: Importance.high,
        priority: Priority.high,
        channelDescription: 'Canal para recordatorios de pagos',
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.show(
        0, 
        title,
        body,
        platformChannelSpecifics,
        payload: 'notificacion_pago',
      );
    } catch (e) {
      debugPrint("Error mostrando notificación: $e");
    }
  }

  Future<void> scheduleNotification(
      DateTime scheduledDate, String title, String body) async {
    try {
      debugPrint("Programando notificación para $scheduledDate");
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'canal_pagos',
        'Notificaciones de Pagos',
        channelDescription: 'Canal para recordatorios de pagos programados',
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);
      await flutterLocalNotificationsPlugin.zonedSchedule(
        scheduledDate.millisecondsSinceEpoch.hashCode % 1000000000,
        title,
        body,
        tzDateTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,
      );
      debugPrint("Notificación programada exitosamente");
    } catch (e) {
      debugPrint("Error programando notificación: $e");
    }
  }
}