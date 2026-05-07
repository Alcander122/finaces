import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/scheduled_payment_model.dart';

class AdvancedNotificationService {
  static final AdvancedNotificationService _instance = AdvancedNotificationService._internal();
  factory AdvancedNotificationService() => _instance;
  AdvancedNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// Inicializa el plugin, zonas horarias y solicita permisos si es necesario
  Future<void> init() async {
    if (_isInitialized) return;

    // Configuración para Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher'); // Asegúrate de tener este icono

    // Configuración para iOS
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false, // Pediremos permisos explícitamente después
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _plugin.initialize(initializationSettings);

    // Solicitar Permisos
    await _requestPermissions();

    _isInitialized = true;
    debugPrint("AdvancedNotificationService inicializado correctamente");
  }

  Future<void> _requestPermissions() async {
    if (Platform.isIOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
    } else if (Platform.isAndroid) {
      final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Solicitar permiso de notificaciones (Android 13+)
        await androidImplementation.requestNotificationsPermission();
        // Solicitar permiso de alarmas exactas (Android 12+)
        await androidImplementation.requestExactAlarmsPermission();
      }
    }
  }

  /// Programa las notificaciones para un pago con todos sus recordatorios
  Future<void> scheduleMultipleReminders(ScheduledPayment payment) async {
    // 1. Cancelar alarmas anteriores (útil al editar)
    await cancelPaymentReminders(payment);

    // 2. Programar las nuevas alarmas
    for (int daysBefore in payment.reminders) {
      final reminderDate = payment.dueDate.subtract(Duration(days: daysBefore));
      
      // En modo 'none' (solo 1 vez), no programamos si la fecha ya pasó.
      // Para recurrentes (weekly, monthly), la notificación DEBE programarse en el componente
      // correspondiente al siguiente ciclo. zondeSchedule + matchDateTimeComponents lo maneja.
      if (payment.frequency == 'none' && reminderDate.isBefore(DateTime.now())) {
         continue; 
      }

      // ID Único y predecible para este pago y día de anticipación (evita colisiones del hashCode)
      // Usamos el baseNotificationId + los días antes (ej: base 1600000 -> id 1600003 para 3 días)
      final int uniqueNotificationId = payment.baseNotificationId + daysBefore;

      DateTimeComponents? repeatComponent;
      switch (payment.frequency) {
        case 'weekly':
          repeatComponent = DateTimeComponents.dayOfWeekAndTime;
          break;
        case 'monthly':
          repeatComponent = DateTimeComponents.dayOfMonthAndTime;
          break;
        case 'yearly':
          repeatComponent = DateTimeComponents.dateAndTime;
          break;
        default:
          repeatComponent = null;
      }

      try {
        await _plugin.zonedSchedule(
          uniqueNotificationId,
          '⏰ Recordatorio de Pago',
          'Tu pago de ${payment.title} por \$${payment.amount} vence en $daysBefore día(s).',
          tz.TZDateTime.from(reminderDate, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'scheduled_payments_channel',
              'Pagos Programados',
              importance: Importance.max,
              priority: Priority.high,
              channelDescription: 'Recordatorios de vencimiento de pagos',
            ),
            iOS: DarwinNotificationDetails(
              interruptionLevel: InterruptionLevel.timeSensitive,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: repeatComponent,
        );
        debugPrint("Alarma programada ID: $uniqueNotificationId para ${payment.title} ($daysBefore días antes)");
      } catch (e) {
        debugPrint("Error programando alarma ID $uniqueNotificationId: $e");
      }
    }
  }

  /// Cancela todas las notificaciones asociadas a este pago
  Future<void> cancelPaymentReminders(ScheduledPayment payment) async {
    // Solo cancelamos los días que el usuario podría haber seleccionado (ej: 1 a 30)
    // O más fácilmente, como ya guardamos el baseNotificationId y los días (reminders)
    for (int days in payment.reminders) {
      final int idToCancel = payment.baseNotificationId + days;
      await _plugin.cancel(idToCancel);
      debugPrint("Alarma cancelada ID: $idToCancel");
    }
  }
}
