import 'package:finances/core/data/models/pago_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:intl/intl.dart';

/// Servicio para manejar notificaciones locales en la aplicación.
/// Se encarga de programar y cancelar notificaciones para pagos recurrentes.
class NotificationService {
  /// Instancia del plugin de notificaciones locales.
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Inicializa el servicio de notificaciones.
  /// Configura los ajustes necesarios para Android y carga la información de zonas horarias.
  Future<void> init() async {
    try {
      debugPrint("Inicializando servicio de notificaciones");
      // Configuración para Android (usa el ícono de la app)
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // Configuración general de inicialización
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      // Inicializa las zonas horarias para manejar correctamente las fechas
      tz.initializeTimeZones();

      // Inicializa el plugin de notificaciones con la configuración definida
      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      debugPrint("Servicio de notificaciones inicializado exitosamente");
    } catch (e) {
      debugPrint("Error inicializando notificaciones: $e");
    }
  }

  /// Programa una notificación recurrente basada en la frecuencia del pago.
  /// Esta es la función corregida para manejar la recurrencia correctamente.
  ///
  /// [pago] El objeto Pago que contiene la información de programación.
  Future<void> scheduleRecurringNotification(Pago pago) async {
    try {
      debugPrint(
          "Intentando programar notificación para pago: ${pago.id} (${pago.descripcion})");

      // 1. Calcular la fecha/hora base para la notificación
      // Se resta el número de días de anticipación a la fecha de vencimiento
      final DateTime notificationDateTime = pago.fechaVencimiento
          .subtract(Duration(days: pago.notificacionAntes));
      debugPrint(
          "Fecha base calculada para notificación: $notificationDateTime");

      // Convertir a TZDateTime para manejo correcto de zonas horarias
      final tz.TZDateTime tzDateTime =
          tz.TZDateTime.from(notificationDateTime, tz.local);

      // 2. Determinar el componente de fecha/hora para repetir
      DateTimeComponents? repeatComponent;
      switch (pago.frecuenciaRecurrencia) {
        case 'diario':
          repeatComponent = DateTimeComponents.time;
          break;
        case 'semanal':
          repeatComponent = DateTimeComponents.dayOfWeekAndTime;
          break;
        case 'mensual':
          repeatComponent = DateTimeComponents.dayOfMonthAndTime;
          break;
        case 'anual':
          repeatComponent = DateTimeComponents.dateAndTime;
          break;
        default:
          repeatComponent = null;
      }

      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'canal_pagos', // ID del canal
        'Notificaciones de Pagos', // Nombre del canal
        channelDescription:
            'Canal para recordatorios de pagos recurrentes', // Descripción del canal
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
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: repeatComponent,
      );

      debugPrint(
          "Notificación programada correctamente para pago ${pago.id} con frecuencia ${pago.frecuenciaRecurrencia} (ID: ${_getNotificationId(pago.id)})");
    } catch (e) {
      debugPrint(
          "Error programando notificación recurrente para pago ${pago.id}: $e");
    }
  }

  int _getNotificationId(String pagoId) {
    return pagoId.hashCode % 1000000000;
  }

  Future<void> cancelRecurringNotification(int notificationId) async {
    try {
      debugPrint("Cancelando notificación con ID: $notificationId");
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint(
          "Notificación con ID: $notificationId cancelada exitosamente.");
    } catch (e) {
      debugPrint("Error cancelando notificación con ID $notificationId: $e");
    }
  }
}
