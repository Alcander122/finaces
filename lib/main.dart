import 'package:finances/core/controller/my_app.dart';
import 'package:finances/core/data/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Necesario para setLanguageCode
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase antes que cualquier otro servicio
  await Firebase.initializeApp();

  // SOLUCIÓN: Configurar idioma para Firebase (elimina el warning de locale)
  //await FirebaseAuth.instance.setLanguageCode("es");
  FirebaseAuth.instance.authStateChanges().listen((user) {
    if (user != null) {
      FirebaseAuth.instance.setLanguageCode("es");
    }
  });

  // Inicializar notificaciones después de Firebase
  try {
    await NotificationService().init();
  } catch (e) {
    debugPrint('Error al inicializar notificaciones: $e');
  }

   await FacebookAuth.i.webAndDesktopInitialize(
    appId: "642352742000792", // Usa tu App ID
    cookie: true,
    xfbml: true,
    version: "v18.0",
  );

  runApp(
    const ProviderScope(child: MyApp()),
  );
}
