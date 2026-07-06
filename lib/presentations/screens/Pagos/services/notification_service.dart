import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  
  static const String channelId = 'finance_reminders_channel';
  static const String channelName = 'Recordatorios de Pago';
  static const String channelDescription = 'Avisos sobre próximos vencimientos de pagos';

  Future<void> init() async {
    const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: iosInitSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    developer.log('Inicializado correctamente.', name: 'NotificationService');
  }

  void _onNotificationTapped(NotificationResponse response) {
    developer.log('Notification tapped: ${response.payload}', name: 'NotificationService');
    // Futuro: Redirección de UI al tocar la notificación
  }

  Future<bool> requestPermissions() async {
    bool granted = false;
    try {
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        // Pedir notificaciones estándar (Android 13+)
        final bool? notificationsGranted = await androidPlugin.requestNotificationsPermission();
        granted = notificationsGranted ?? false;

        // Pedir permisos explícitos de Alarmas Exactas para Android 12, 13 y 14 (sin permiso de batería)
        final status = await Permission.scheduleExactAlarm.status;
        if (status.isDenied || status.isPermanentlyDenied) {
          developer.log('Permiso de alarmas exactas denegado, solicitando...', name: 'NotificationService');
          await Permission.scheduleExactAlarm.request();
        }
      } else {
        // iOS
        final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
        final bool? iosGranted = await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);
        granted = iosGranted ?? false;
      }
      developer.log('Permisos concedidos: $granted', name: 'NotificationService');
      return granted;
    } catch (e) {
      developer.log('Error pidiendo permisos: $e', name: 'NotificationService', error: e);
      return false;
    }
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            channelName,
            channelDescription: channelDescription,
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      developer.log('Programada: ID $id para $scheduledDate', name: 'NotificationService');
    } catch (e) {
      // Fallback si "Exact Alarms" está denegado en Android 12/13+
      developer.log('Fallo alarma exacta, usando inexacta.', name: 'NotificationService', error: e);
      try {
        await _plugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              channelName,
              channelDescription: channelDescription,
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (fallbackError) {
        developer.log('Error fatal programando notificación.', name: 'NotificationService', error: fallbackError);
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id);
    developer.log('ID $id cancelada.', name: 'NotificationService');
  }
}
