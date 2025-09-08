// lib/core/data/services/BiometricAuthService.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Resultado detallado para la autenticación biométrica
enum BiometricAuthStatus {
  success, // autenticado correctamente
  failed, // intento fallido (huella no coincide)
  canceled, // el usuario canceló el prompt
  notAvailable, // dispositivo sin biometría o usuario no tiene huellas registradas
  error, // error inesperado/plataforma
}

/// Servicio para manejar la autenticación biométrica con persistencia por usuario.
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;

  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  /// Clave por usuario para guardar si tiene biometría activada
  String _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;
    return 'biometric_enabled_${user?.uid ?? 'no_user'}';
  }

  /// ¿El dispositivo puede usar biometría?
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

  /// ¿El usuario activó biometría en la app (persistida)?
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _getUserKey());
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error leyendo estado de biometría: $e');
      return false;
    }
  }

  /// Activa / desactiva biometría (persistencia por usuario)
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _getUserKey(), value: enabled.toString());
      debugPrint('Biometría ${enabled ? 'activada' : 'desactivada'}');
    } catch (e) {
      debugPrint('Error guardando estado de biometría: $e');
      rethrow;
    }
  }

  /// Limpia la configuración de biometría del usuario actual
  Future<void> clearBiometricSetting() async {
    try {
      await _storage.delete(key: _getUserKey());
      debugPrint('Configuración biométrica eliminada');
    } catch (e) {
      debugPrint('Error limpiando configuración biométrica: $e');
    }
  }

  /// Método robusto que intenta autenticar y devuelve un estado detallado.
  Future<BiometricAuthStatus> authenticateWithStatus() async {
    try {
      final deviceSupported = await _localAuth.isDeviceSupported();
      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      final enabled = await isBiometricEnabled();

      if (!deviceSupported || availableBiometrics.isEmpty || !enabled) {
        debugPrint(
            'Biometría no disponible / no registrada o no activada en app');
        return BiometricAuthStatus.notAvailable;
      }

      // detener autenticaciones previas para evitar errores
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
        return BiometricAuthStatus.canceled;
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

  /// Compatibilidad rápida: ahora recibe [BuildContext].
  /// Retorna true si autenticado, false si falla o cancela (y además hace signOut).
  Future<bool> authenticate(BuildContext context) async {
    final status = await authenticateWithStatus();

    if (status == BiometricAuthStatus.success) {
      return true;
    }

    // Mostrar un SnackBar si falla/cancela
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Autenticación cancelada o fallida'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // 🚨 Desactivar biometría automáticamente si cancela o falla
    await setBiometricEnabled(false);

    // También cerrar sesión
    await FirebaseAuth.instance.signOut();

    return false;
  }
}
