import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class TimezoneService {
  /// Inicializa la base de datos de zonas horarias.
  /// Debe llamarse en el main() antes de runApp().
  Future<void> init() async {
    tz.initializeTimeZones();
    // NOTA: Para obtener el timezone dinámico del dispositivo en la Fase 3
    // usaremos 'flutter_timezone'. Por ahora, dejamos la base inicializada.
  }

  tz.TZDateTime now() {
    return tz.TZDateTime.now(tz.local);
  }
}
