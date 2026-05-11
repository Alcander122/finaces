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

  try {
    // 1. Inicializar Firebase
    await Firebase.initializeApp();

    // Configurar idioma para Firebase Auth
    FirebaseAuth.instance.setLanguageCode("es");

    // 2. 📢 INICIALIZAR ADMOB: Prepara el motor de anuncios para cargar banners e intersticiales
    // Se inicializa después de Firebase para asegurar la conectividad
    await MobileAds.instance.initialize();
    debugPrint('SDK de Google Mobile Ads inicializado');

    // 3. Inicializar Timezone
    await TimezoneService().init();

    // 4. Inicializar notificaciones locales
    final notificationService = NotificationService();
    await notificationService.init();
    await notificationService.requestPermissions();
  } catch (e) {
    debugPrint('Error durante la inicialización de servicios: $e');
    // No lanzamos excepción para evitar que la aplicación se cierre inesperadamente
  }

  // Ejecutar la aplicación envuelta en ProviderScope para el manejo de estados con Riverpod
  runApp(
    const ProviderScope(child: MyApp()),
  );
}
