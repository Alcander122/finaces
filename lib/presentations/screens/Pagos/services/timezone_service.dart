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
      // 1. Intentar con la zona horaria del dispositivo
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      final String timeZoneId = timeZoneInfo.identifier;
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneId));
        debugPrint('Zona horaria del dispositivo configurada: $timeZoneId');
      } catch (e) {
        debugPrint('Zona horaria del dispositivo no soportada ($timeZoneId), intentando fallback a America/Bogota: $e');
        tz.setLocalLocation(tz.getLocation('America/Bogota'));
      }
    } catch (e) {
      debugPrint('Error obteniendo flutter_timezone: $e, intentando fallback a America/Bogota');
      try {
        tz.setLocalLocation(tz.getLocation('America/Bogota'));
      } catch (_) {
        debugPrint('Fallo fallback a America/Bogota, configurando UTC');
        tz.setLocalLocation(tz.UTC);
      }
    }
  }

  tz.TZDateTime now() {
    return tz.TZDateTime.now(tz.local);
  }
}
