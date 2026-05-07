import 'package:finances/core/controller/my_app.dart';
import 'package:finances/core/data/services/notification_service.dart';
import 'package:finances/features/scheduled_payments/services/advanced_notification_service.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// 🔑 LLAVE GLOBAL: Permite controlar el Navigator desde fuera de los widgets (ej. AuthProvider)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configuración de localización para español
  await initializeDateFormatting('es', null);

  try {
    await Firebase.initializeApp();
    FirebaseAuth.instance.setLanguageCode("es");
    await MobileAds.instance.initialize();
    await NotificationService().init();
    tz.initializeTimeZones();
    await AdvancedNotificationService().init();
  } catch (e) {
    debugPrint('Error durante la inicialización: $e');
  }

  runApp(
    const ProviderScope(child: MyApp()),
  );
}
