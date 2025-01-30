// lib/routes/app_routes.dart
import 'package:finances/presentations/screens/auth/LoginScreen.dart';
import 'package:finances/presentations/screens/auth/register.screen.dart';
import 'package:finances/presentations/screens/ingresos/ingresos_screen.dart';
import 'package:finances/presentations/screens/profile/ProfileScreen.dart';
import 'package:flutter/material.dart';
import 'package:finances/presentations/screens/home/home_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String loginScreen = '/loginScreen'; // Nueva ruta directa
  static const String home = '/home';
  static const String profile = '/profile';
  static const String register = '/register';
  static const String ingresos = '/ingresos';

  static Map<String, WidgetBuilder> getRoutes(authState) {
    return {
      login: (context) =>
          authState == null ? const LoginScreen() : const HomeScreen(),
      loginScreen: (context) => const LoginScreen(), // Nueva ruta directa
      home: (context) => const HomeScreen(),
      profile: (context) => const ProfileScreen(),
      register: (context) => const RegisterScreen(),
      ingresos: (context) => IngresosScreen(),
    };
  }
}
