// notification_service.dart
import 'package:finances/core/data/models/pago_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:intl/intl.dart';

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    try {
      debugPrint("Inicializando servicio de notificaciones");
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );
      tz.initializeTimeZones();
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);
      debugPrint("Servicio de notificaciones inicializado exitosamente");
    } catch (e) {
      debugPrint("Error inicializando notificaciones: $e");
    }
  }

  // Programa una notificación
  Future<void> scheduleNotification(
      DateTime scheduledDate, String title, String body) async {
    try {
      final tz.TZDateTime tzDateTime =
          tz.TZDateTime.from(scheduledDate, tz.local);
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
    } catch (e) {
      debugPrint("Error programando notificación: $e");
    }
  }

  Future<void> scheduleRecurringNotification(Pago pago) async {
    try {
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(
        pago.fechaVencimiento.subtract(Duration(days: pago.notificacionAntes)),
        tz.local,
      );

      final Duration repeatInterval =
          _getRepeatInterval(pago.frecuenciaRecurrencia);

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'canal_pagos',
        'Notificaciones de Pagos',
        channelDescription: 'Canal para recordatorios de pagos recurrentes',
        importance: Importance.high,
        priority: Priority.high,
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      await flutterLocalNotificationsPlugin.zonedSchedule(
        _getNotificationId(pago.id),
        'Pago programado: ${pago.descripcion}',
        'Recuerda pagar ${pago.descripcion} el ${DateFormat.yMd().format(pago.fechaVencimiento)}',
        tzDateTime,
        platformChannelSpecifics,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: AndroidScheduleMode.exact,
      );
    } catch (e) {
      debugPrint("Error programando notificación recurrente: $e");
    }
  }

  Duration _getRepeatInterval(String frecuencia) {
    switch (frecuencia) {
      case 'diario':
        return const Duration(days: 1);
      case 'semanal':
        return const Duration(days: 7);
      case 'mensual':
        return const Duration(days: 30);
      case 'anual':
        return const Duration(days: 365);
      default:
        return const Duration(days: 30);
    }
  }

  int _getNotificationId(String pagoId) {
    return pagoId.hashCode % 1000000000;
  }

  // Cancela una notificación programada
  Future<void> cancelRecurringNotification(int notificationId) async {
    try {
      debugPrint("Cancelando notificación con ID: $notificationId");
      await flutterLocalNotificationsPlugin.cancel(notificationId);
    } catch (e) {
      debugPrint("Error cancelando notificación: $e");
    }
  }
}
