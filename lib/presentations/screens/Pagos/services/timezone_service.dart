import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/foundation.dart';

class TimezoneService {
  /// Inicializa la base de datos de zonas horarias.
  /// Debe llamarse en el main() antes de runApp().
  Future<void> init() async {
    tz.initializeTimeZones();
    try {
      // Obtener el timezone dinámico del dispositivo (Soluciona el problema de UTC vs Local)
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      debugPrint('Error inicializando flutter_timezone: $e');
    }
  }

  tz.TZDateTime now() {
    return tz.TZDateTime.now(tz.local);
  }
}
