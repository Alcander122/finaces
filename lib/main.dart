import 'package:finances/core/controller/my_app.dart';
import 'package:finances/presentations/screens/Pagos/services/notification_service.dart';
import 'package:finances/presentations/screens/Pagos/services/timezone_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // 🚀 Importación necesaria para anuncios

void main() async {
  // Asegurar la inicialización de Flutter antes de llamar a servicios externos
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de localización para español (requerido para formatos de moneda y fechas en Cali)
  await initializeDateFormatting('es', null);
  debugPrint('Datos de localización para español inicializados correctamente');

  // 1. Inicializar Firebase
  try {
    await Firebase.initializeApp();
    FirebaseAuth.instance.setLanguageCode("es");
    debugPrint('Firebase inicializado correctamente');
  } catch (e) {
    debugPrint('Error inicializando Firebase: $e');
  }

  // 2. 📢 INICIALIZAR ADMOB
  try {
    await MobileAds.instance.initialize();
    debugPrint('SDK de Google Mobile Ads inicializado');
  } catch (e) {
    debugPrint('Error inicializando Google Mobile Ads: $e');
  }

  // 3. Inicializar Timezone
  try {
    await TimezoneService().init();
    debugPrint('TimezoneService inicializado correctamente');
  } catch (e) {
    debugPrint('Error inicializando TimezoneService: $e');
  }

  // 4. Inicializar notificaciones locales
  try {
    final notificationService = NotificationService();
    await notificationService.init();
    debugPrint('NotificationService inicializado correctamente');
  } catch (e) {
    debugPrint('Error inicializando NotificationService: $e');
  }

  // Ejecutar la aplicación envuelta en ProviderScope para el manejo de estados con Riverpod
  runApp(
    const ProviderScope(child: MyApp()),
  );
}
