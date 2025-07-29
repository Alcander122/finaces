import 'package:finances/core/data/models/pago_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:intl/intl.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' show DateTimeComponents;

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

  /// (Método auxiliar, no usado directamente para recurrencia en la versión corregida)
  /// Programa una notificación única para una fecha específica.
  /// [scheduledDate] La fecha y hora en que se debe mostrar la notificación.
  /// [title] El título de la notificación.
  /// [body] El cuerpo del mensaje de la notificación.
  Future<void> scheduleNotification(
      DateTime scheduledDate, String title, String body) async {
    try {
      // Convierte la fecha local a una fecha en la zona horaria local manejada por el paquete timezone
      final tz.TZDateTime tzDateTime =
          tz.TZDateTime.from(scheduledDate, tz.local);

      // Configuración específica para Android
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'canal_pagos',
        'Notificaciones de Pagos',
        channelDescription: 'Canal para recordatorios de pagos programados',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      // Configuración general de la notificación
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      // Programa la notificación usando zonedSchedule
      await flutterLocalNotificationsPlugin.zonedSchedule(
        scheduledDate.millisecondsSinceEpoch.hashCode % 1000000000, // ID único basado en la fecha
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

  /// Programa una notificación recurrente basada en la frecuencia del pago.
  /// Esta es la función corregida para manejar la recurrencia correctamente.
  ///
  /// [pago] El objeto Pago que contiene la información de programación.
  Future<void> scheduleRecurringNotification(Pago pago) async {
    try {
      debugPrint("Intentando programar notificación para pago: ${pago.id} (${pago.descripcion})");

      // 1. Calcular la fecha/hora base para la notificación
      // Se resta el número de días de anticipación a la fecha de vencimiento
      final DateTime notificationDateTime = pago.fechaVencimiento.subtract(Duration(days: pago.notificacionAntes));
      debugPrint("Fecha base calculada para notificación: $notificationDateTime");

      // Convertir a TZDateTime para manejo correcto de zonas horarias
      final tz.TZDateTime tzDateTime = tz.TZDateTime.from(notificationDateTime, tz.local);

      // 2. Determinar el componente de fecha/hora para repetir
      DateTimeComponents? repeatComponent;
      switch (pago.frecuenciaRecurrencia) {
        case 'diario':
          // Se repite diariamente a la misma hora
          repeatComponent = DateTimeComponents.time;
          debugPrint("Configurando recurrencia DIARIA");
          break;
        case 'semanal':
          // Se repite semanalmente el mismo día de la semana a la misma hora
          repeatComponent = DateTimeComponents.dayOfWeekAndTime;
          debugPrint("Configurando recurrencia SEMANAL");
          break;
        case 'mensual':
          // Se repite mensualmente el mismo día del mes a la misma hora
          // Nota: Puede tener problemas si el día no existe en un mes (ej: 31 de febrero)
          repeatComponent = DateTimeComponents.dayOfMonthAndTime;
          debugPrint("Configurando recurrencia MENSUAL");
          break;
        case 'anual':
          // Se repite anualmente el mismo día y mes a la misma hora
          repeatComponent = DateTimeComponents.dateAndTime;
          debugPrint("Configurando recurrencia ANUAL");
          break;
        default:
          // Si no coincide con una frecuencia conocida, programa solo una vez
          debugPrint("Frecuencia desconocida o no especificada: ${pago.frecuenciaRecurrencia}. Programando solo una notificación.");
          repeatComponent = null; // No se repite
      }

      // 3. Configurar los detalles de la notificación
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        'canal_pagos', // ID del canal
        'Notificaciones de Pagos', // Nombre del canal
        channelDescription: 'Canal para recordatorios de pagos recurrentes', // Descripción del canal
        importance: Importance.high, // Importancia alta para que se muestre prominentemente
        priority: Priority.high, // Prioridad alta
      );
      const NotificationDetails platformChannelSpecifics =
          NotificationDetails(android: androidPlatformChannelSpecifics);

      // 4. Programar la notificación con recurrencia
      await flutterLocalNotificationsPlugin.zonedSchedule(
        _getNotificationId(pago.id), // ID único para esta notificación basado en el ID del pago
        'Pago programado: ${pago.descripcion}', // Título de la notificación
        'Recuerda pagar ${pago.descripcion} el ${DateFormat.yMd().format(pago.fechaVencimiento)}', // Cuerpo del mensaje
        tzDateTime, // Fecha/Hora base calculada
        platformChannelSpecifics, // Detalles de la notificación
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime, // Interpretar la fecha como absoluta
        // Modo exacto que permite mostrar la notificación incluso en modo Doze (ahorro de energía)
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // Componente para repetir - Esta es la corrección principal
        matchDateTimeComponents: repeatComponent,
      );

      debugPrint("Notificación programada correctamente para pago ${pago.id} con frecuencia ${pago.frecuenciaRecurrencia} (ID: ${_getNotificationId(pago.id)})");

    } catch (e) {
      debugPrint("Error programando notificación recurrente para pago ${pago.id}: $e");
    }
  }

  /// (Función auxiliar, ya no se usa para calcular repeatInterval en zonedSchedule)
  /// Calcula un intervalo de repetición aproximado basado en la frecuencia.
  /// Este método ya no es necesario para zonedSchedule con matchDateTimeComponents.
  Duration getRepeatInterval(String frecuencia) {
    switch (frecuencia) {
      case 'diario':
        return const Duration(days: 1);
      case 'semanal':
        return const Duration(days: 7);
      case 'mensual':
        // Nota: 30 días es una aproximación
        return const Duration(days: 30);
      case 'anual':
        // Nota: 365 días es una aproximación
        return const Duration(days: 365);
      default:
        // Por defecto, mensual
        return const Duration(days: 30);
    }
  }

  /// Genera un ID único para una notificación basado en el ID del pago.
  /// [pagoId] El ID del pago.
  /// Returns: Un entero que representa el ID de la notificación.
  int _getNotificationId(String pagoId) {
    // Usa el hashCode del ID del pago y lo limita para evitar valores muy grandes
    return pagoId.hashCode % 1000000000;
  }

  /// Cancela una notificación programada.
  /// [notificationId] El ID de la notificación a cancelar.
  Future<void> cancelRecurringNotification(int notificationId) async {
    try {
      debugPrint("Cancelando notificación con ID: $notificationId");
      // Llama al plugin para cancelar la notificación específica
      await flutterLocalNotificationsPlugin.cancel(notificationId);
      debugPrint("Notificación con ID: $notificationId cancelada exitosamente.");
    } catch (e) {
      debugPrint("Error cancelando notificación con ID $notificationId: $e");
    }
  }
}
