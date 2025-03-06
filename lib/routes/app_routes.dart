// lib/routes/app_routes.dart
import 'package:finances/presentations/screens/auth/LoginScreen.dart';
import 'package:finances/presentations/screens/auth/register.screen.dart';
import 'package:finances/presentations/screens/profile/ProfileScreen.dart';
<<<<<<< HEAD
import 'package:finances/presentations/screens/portafolio/portafolio_screen.dart';
=======
import 'package:finances/presentations/screens/auth/welcome_screen.dart';
>>>>>>> d251a602acd46738823f2be3fca9c2d66ce3e325
import 'package:flutter/material.dart';
import 'package:finances/presentations/screens/home/home_screen.dart';

class AppRoutes {
  static const String login = '/';
  static const String loginScreen = '/loginScreen'; // Nueva ruta directa
  static const String home = '/home';
  static const String profile = '/profile';
  static const String register = '/register';
  static const String ingresos = '/ingresos';
<<<<<<< HEAD
  static const String portafolio = '/portafolio';
=======
  static const String welcome = '/welcome';

>>>>>>> d251a602acd46738823f2be3fca9c2d66ce3e325
  static Map<String, WidgetBuilder> getRoutes(authState) {
    return {
      login: (context) =>
          authState == null ? const WelcomeScreen() : const HomeScreen(),
      loginScreen: (context) => const LoginScreen(), // Nueva ruta directa
      home: (context) => const HomeScreen(),
      profile: (context) => const ProfileScreen(),
      register: (context) => const RegisterScreen(),
<<<<<<< HEAD
      portafolio: (context) => PortafolioScreen(),
=======
      ingresos: (context) => IngresosScreen(),
      welcome: (context) => const WelcomeScreen()
>>>>>>> d251a602acd46738823f2be3fca9c2d66ce3e325
    };
  }
}
