import 'package:finances/core/controller/my_app.dart';
import 'package:finances/core/data/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Asegurar la inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de localización para español
  await initializeDateFormatting('es', null);
  debugPrint('Datos de localización para español inicializados correctamente');

  try {
    // Inicializar Firebase
    await Firebase.initializeApp();

    // 🔑 CLAVE: Configurar Firebase Auth para NO persistir la sesión localmente
    // Esto asegura que al cerrar la app o desinstalarla, la sesión se borre completamente
    // Persistence.NONE significa que Firebase no guardará ninguna sesión en el dispositivo
    FirebaseAuth.instance.setPersistence(Persistence.NONE);

    // Configurar idioma para Firebase Auth (versión mejorada)
    FirebaseAuth.instance.setLanguageCode("es");

    // Inicializar notificaciones
    await NotificationService().init();

    // Inicializar Facebook Auth
    /* await FacebookAuth.i.webAndDesktopInitialize(
      appId: "642352742000792",
      cookie: true,
      xfbml: true,
      version: "v18.0",
    );*/
  } catch (e) {
    debugPrint('Error durante la inicialización: $e');
    // No lanzamos excepción para evitar caída de la app
  }

  // Ejecutar la aplicación
  runApp(
    const ProviderScope(child: MyApp()),
  );
}
