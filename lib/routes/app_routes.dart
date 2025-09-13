// lib/routes/app_routes.dart

import 'package:finances/presentations/screens/Ahorro/ahorro_screen.dart';
import 'package:finances/presentations/screens/Auth/LoginScreen.dart';
import 'package:finances/presentations/screens/Auth/register.screen.dart';
import 'package:finances/presentations/screens/Bancos/banks_screen.dart';
import 'package:finances/presentations/screens/Estadistica/statistics_screen.dart';
import 'package:finances/presentations/screens/Pagos/agregar_editar_pago_screen.dart';
import 'package:finances/presentations/screens/Pagos/pagos_screen.dart';
import 'package:finances/presentations/screens/Profile/profile_screen.dart';
import 'package:finances/presentations/screens/Portafolio/portafolio_screen.dart';
import 'package:finances/presentations/screens/Auth/welcome_screen.dart';
import 'package:finances/presentations/screens/Tutorial/TutorialScreen.dart';
import 'package:finances/presentations/screens/auth/app_blocked_screen.dart';
import 'package:finances/presentations/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:finances/presentations/screens/Home/home_screen.dart';
import 'package:finances/core/data/providers/auth_provider.dart';
import 'package:finances/presentations/screens/Estadistica/category_details.dart';
import 'package:finances/core/data/models/filter.dart';

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
  static const String banco = '/banco';
  static const String splash = '/splash';
  static const String appBlocked = '/app-blocked';
  static const String pagos = '/pagos';
  static const String tutorial = '/tutorial';
  static const String agregarPago = '/agregar-pago';
  static const String editarPago = '/editar-pago';
  static const String estadistica = '/Estadistica';
  // Nueva ruta para detalles de categoría
  static const String categoryDetails = '/category-details';

  static Map<String, WidgetBuilder> getRoutes(AuthState authState) {
    return {
      // ¡CORRECCIÓN! welcome siempre debe mostrar WelcomeScreen
      welcome: (context) => const WelcomeScreen(),

      // login siempre debe mostrar LoginScreen
      login: (context) => const LoginScreen(),

      // splash siempre debe mostrar SplashScreen
      splash: (context) => const SplashScreen(),

      // appBlocked siempre debe mostrar AppBlockedScreen
      appBlocked: (context) => const AppBlockedScreen(),

      // appBlocked siempre debe mostrar AppBlockedScreen
      tutorial: (context) => const TutorialScreen(),

      // home siempre debe mostrar HomeScreen
      home: (context) => const HomeScreen(),

      // profile siempre debe mostrar ProfileScreen
      profile: (context) => const ProfileScreen(),

      // register siempre debe mostrar RegisterScreen
      register: (context) => const RegisterScreen(),

      // banco siempre debe mostrar PantallaBancos
      banco: (context) => const PantallaBancos(),

      // portafolio siempre debe mostrar PortafolioScreen
      portafolio: (context) => const PortafolioScreen(),

      // ahorro siempre debe mostrar AhorroScreen
      ahorro: (context) => const AhorroScreen(),

      // estadistica siempre debe mostrar StatisticScreen
      estadistica: (context) => const StatisticScreen(),

      // categoryDetails siempre debe mostrar CategoryDetailsScreen
      categoryDetails: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CategoryDetailsScreen(
          category: args?['category'] ?? '',
          filter: args?['filter'] ?? const Filter(type: FilterType.monthly),
          isExpense: args?['isExpense'] ?? false,
        );
      },

      // pagos siempre debe mostrar PagosScreen
      pagos: (context) => const PagosScreen(),

      // agregarPago siempre debe mostrar AgregarEditarPagoScreen
      agregarPago: (context) => const AgregarEditarPagoScreen(),

      // editarPago siempre debe mostrar AgregarEditarPagoScreen
      editarPago: (context) => const AgregarEditarPagoScreen(),
    };
  }
}
