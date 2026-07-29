import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Clave usada para guardar la preferencia en el almacenamiento local
const _kThemeKey = 'isDarkMode';

/// Maneja el estado del tema (claro u oscuro) y lo persiste entre sesiones.
class ThemeNotifier extends StateNotifier<ThemeMode> {
  // Por defecto arranca en oscuro (el look actual de la app)
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  /// Carga la preferencia guardada en el dispositivo al arrancar la app.
  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemeKey) ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Alterna entre oscuro y claro y guarda la nueva elección del usuario.
  Future<void> toggleTheme() async {
    final prefs = await SharedPreferences.getInstance();
    if (state == ThemeMode.dark) {
      state = ThemeMode.light;
      await prefs.setBool(_kThemeKey, false);
    } else {
      state = ThemeMode.dark;
      await prefs.setBool(_kThemeKey, true);
    }
  }
}

/// Provider global que expone el ThemeMode actual a toda la aplicación.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);
