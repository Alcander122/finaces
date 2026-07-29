import 'package:flutter/material.dart';

// ============================================================================
// PALETA MODO CLARO
// Fondo claro (#F8F9FA), texto oscuro, primario azul KUPI
// ============================================================================
const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFF003366),          // Azul primario KUPI
  onPrimary: Color(0xFFFFFFFF),        // Texto sobre primario
  secondary: Color(0xFF6EAEE7),        // Azul secundario
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFBA1A1A),
  onError: Color(0xFFFFFFFF),
  surface: Color(0xFFF8F9FA),          // Fondo claro del Scaffold y Cards
  onSurface: Color(0xFF1A1C18),        // Texto oscuro sobre fondo claro
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFFC2C8BC),
);

// ============================================================================
// PALETA MODO OSCURO
// Fondo muy oscuro (#0B0E14) con textos blancos — aspecto actual de la app
// ============================================================================
const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFF6EAEE7),          // Azul más claro para mejor contraste en oscuro
  onPrimary: Color(0xFF003366),
  secondary: Color(0xFF416FDF),
  onSecondary: Color(0xFFFFFFFF),
  error: Color(0xFFCF6679),
  onError: Color(0xFF000000),
  surface: Color(0xFF0B0E14),          // Fondo oscuro característico de la app
  onSurface: Color(0xFFFFFFFF),        // Texto blanco sobre fondo oscuro
  shadow: Color(0xFF000000),
  outlineVariant: Color(0xFF44474E),
);

// ============================================================================
// TEMA MODO CLARO
// ============================================================================
ThemeData lightMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: lightColorScheme,
  // El Scaffold usa el color 'surface' de la paleta (fondo claro)
  scaffoldBackgroundColor: lightColorScheme.surface,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(lightColorScheme.primary),
      foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
      elevation: WidgetStateProperty.all<double>(5.0),
      padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  ),
);

// ============================================================================
// TEMA MODO OSCURO
// ============================================================================
ThemeData darkMode = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: darkColorScheme,
  // El Scaffold usa el color 'surface' oscuro de la paleta
  scaffoldBackgroundColor: darkColorScheme.surface,
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStateProperty.all<Color>(darkColorScheme.primary),
      foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
      elevation: WidgetStateProperty.all<double>(5.0),
      padding: WidgetStateProperty.all<EdgeInsets>(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 18)),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  ),
);

// ============================================================================
// EXTENSIÓN DE CONTEXTO
// Permite acceder rápidamente a los colores del tema actual en cualquier widget
// Uso: context.colors.onSurface en lugar de Theme.of(context).colorScheme.onSurface
// ============================================================================
extension ThemeContextExtension on BuildContext {
  /// Acceso directo al ColorScheme del tema activo
  ColorScheme get colors => Theme.of(this).colorScheme;

  /// Devuelve true si la app está en modo oscuro
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
