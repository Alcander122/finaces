// lib/core/data/services/BiometricAuthService.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resultado detallado para la autenticación biométrica
enum BiometricAuthStatus {
  success, // Autenticado correctamente
  failed, // Intento fallido (huella no coincide)
  canceled, // El usuario canceló el prompt
  notAvailable, // Dispositivo sin biometría o sin huellas registradas
  error, // Error inesperado/plataforma
}

/// Servicio para manejar la autenticación biométrica con persistencia por usuario.
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;

  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Genera una clave única por usuario para guardar si tiene biometría activada.
  /// Si no hay usuario, usa 'no_user' para evitar errores.
  String _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;
    return 'biometric_enabled_${user?.uid ?? 'no_user'}';
  }

  /// Verifica si el dispositivo soporta biometría y tiene al menos un método disponible.
  Future<bool> isBiometricAvailable() async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final available = await _localAuth.getAvailableBiometrics();
      return deviceSupported && available.isNotEmpty;
    } catch (e) {
      debugPrint('Error verificando disponibilidad biométrica: $e');
      return false;
    }
  }

  /// Verifica si el usuario actual tiene activada la biometría en la app (persistido en storage).
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _getUserKey());
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error leyendo estado de biometría: $e');
      return false;
    }
  }

  /// Activa o desactiva la biometría para el usuario actual (persiste en storage).
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _getUserKey(), value: enabled.toString());
      debugPrint('Biometría ${enabled ? 'activada' : 'desactivada'}');
    } catch (e) {
      debugPrint('Error guardando estado de biometría: $e');
      rethrow;
    }
  }

  /// Limpia la configuración de biometría del usuario actual (útil al cerrar sesión).
  Future<void> clearBiometricSetting() async {
    try {
      await _storage.delete(key: _getUserKey());
      debugPrint('Configuración biométrica eliminada');
    } catch (e) {
      debugPrint('Error limpiando configuración biométrica: $e');
    }
  }

  /// Método robusto que intenta autenticar y devuelve un estado detallado.
  /// NO cierra sesión ni desactiva biometría aquí.
  Future<BiometricAuthStatus> authenticateWithStatus() async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final enabled = await isBiometricEnabled();

      // Si no está activada en la app, o no hay hardware/dispositivo, devolvemos notAvailable
      if (!deviceSupported || availableBiometrics.isEmpty || !enabled) {
        debugPrint(
            'Biometría no disponible / no registrada o no activada en app');
        return BiometricAuthStatus.notAvailable;
      }

      // Detener autenticaciones previas para evitar errores
      try {
        await _localAuth.stopAuthentication();
      } catch (_) {}

      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a BillNance',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
          useErrorDialogs: false,
        ),
      );

      if (didAuthenticate) {
        debugPrint('Autenticación biométrica exitosa');
        return BiometricAuthStatus.success;
      } else {
        debugPrint(
            'Autenticación biométrica retornó false (cancelada/fallida)');
        return BiometricAuthStatus
            .canceled; // O podría ser failed, pero local_auth no distingue
      }
    } on PlatformException catch (e) {
      debugPrint(
          'PlatformException en biometric auth: ${e.code} - ${e.message}');

      final code = e.code.toLowerCase();

      if (code.contains('notavailable') ||
          code.contains('not_enrolled') ||
          code.contains('no_hardware')) {
        return BiometricAuthStatus.notAvailable;
      }
      if (code.contains('user_canceled') ||
          code.contains('not_authenticated') ||
          code.contains('canceled')) {
        return BiometricAuthStatus.canceled;
      }
      if (code.contains('locked') || code.contains('lockout')) {
        return BiometricAuthStatus.error;
      }

      return BiometricAuthStatus.error;
    } catch (e) {
      debugPrint('Error inesperado en authenticateWithStatus: $e');
      return BiometricAuthStatus.error;
    }
  }

  /// Método de compatibilidad: autentica y retorna true/false.
  /// ❗ IMPORTANTE: Este método NO desactiva biometría ni cierra sesión si falla.
  /// Solo muestra un SnackBar y retorna false.
  Future<bool> authenticate(BuildContext context) async {
    final status = await authenticateWithStatus();

    if (status == BiometricAuthStatus.success) {
      return true;
    }

    // Mostrar mensaje de error/cancelación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Autenticación cancelada o fallida'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // ❌ NO desactivamos biometría aquí → el usuario solo canceló.
    // ❌ NO cerramos sesión → el usuario sigue logueado.

    return false;
  }
}
