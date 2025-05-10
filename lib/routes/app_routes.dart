// lib/routes/app_routes.dart
import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/Auth/LoginScreen.dart';
import 'package:finances/presentations/screens/Auth/register.screen.dart';
import 'package:finances/presentations/screens/Estadistica/Statistics_Screen.dart';
import 'package:finances/presentations/screens/Profile/profile_screen.dart';
import 'package:finances/presentations/screens/Portafolio/portafolio_screen.dart';
import 'package:finances/presentations/screens/Auth/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:finances/presentations/screens/Home/home_screen.dart';
import 'package:finances/core/data/providers/auth_provider.dart';

class AppRoutes {
  // Ruta exclusiva para la pantalla de bienvenida.
  static const String welcome = '/welcome';
  // Ruta para la pantalla de login.
  static const String login = '/loginScreen';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String register = '/register';
  static const String ingresos = '/ingresos';
  static const String portafolio = '/portafolio';
  static const String ahorro = '/ahorro';
  static const String Estadistica = '/Estadistica';


  // Aquí se decide qué pantalla mostrar según el estado de autenticación.
  // En lugar de verificar si authState es null, se comprueba si authState.user es null.
  static Map<String, WidgetBuilder> getRoutes(AuthState authState) {
    return {
      welcome: (context) =>
          authState.user == null ? const WelcomeScreen() : const HomeScreen(),
      login: (context) => const LoginScreen(),
      home: (context) => const HomeScreen(),
      profile: (context) => const ProfileScreen(),
      register: (context) => const RegisterScreen(),
      portafolio: (context) => const PortafolioScreen(),
      ahorro: (context) => const AhorroScreen(),
      Estadistica: (context) => StatisticsScreen(),
    };
  }
}
