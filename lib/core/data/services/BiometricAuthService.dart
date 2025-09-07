// lib/core/data/services/BiometricAuthService.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
//import 'package:logger/logger.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Servicio para manejar la autenticación biométrica con persistencia por usuario
class BiometricAuthService {
  static final BiometricAuthService _instance =
      BiometricAuthService._internal();
  factory BiometricAuthService() => _instance;

  BiometricAuthService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  //final Logger _logger = Logger();

  /// Obtiene la clave única para el usuario actual
  String _getUserKey() {
    final user = FirebaseAuth.instance.currentUser;
    return 'biometric_enabled_${user?.uid ?? 'no_user'}';
  }

  /// Verifica disponibilidad biométrica
  Future<bool> isBiometricAvailable() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (e) {
      debugPrint('Error verificando disponibilidad biométrica: $e');
      return false;
    }
  }

  /// Verifica si la biometría está activada para el usuario actual
  Future<bool> isBiometricEnabled() async {
    try {
      final enabled = await _storage.read(key: _getUserKey());
      return enabled == 'true';
    } catch (e) {
      debugPrint('Error leyendo estado de biometría: $e');
      return false;
    }
  }

  /// Activa/desactiva la biometría para el usuario actual
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: _getUserKey(), value: enabled.toString());
      debugPrint(
          'Biometría ${enabled ? 'activada' : 'desactivada'} para usuario');
    } catch (e) {
      debugPrint('Error guardando estado de biometría: $e');
      rethrow;
    }
  }

  /// Ejecuta la autenticación biométrica
  Future<bool> authenticate() async {
    try {
      final isAvailable = await isBiometricAvailable();
      final isEnabled = await isBiometricEnabled();

      if (!isAvailable || !isEnabled) return false;

      return await _localAuth.authenticate(
        localizedReason: 'Autentícate para acceder a BillNance',
        options: const AuthenticationOptions(
          biometricOnly: true,
          useErrorDialogs: true,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint('Error en autenticación biométrica: $e');
      return false;
    }
  }

  /// Limpia la configuración de biometría (solo al eliminar cuenta)
  Future<void> clearBiometricSetting() async {
    try {
      await _storage.delete(key: _getUserKey());
    } catch (e) {
      debugPrint('Error limpiando configuración biométrica: $e');
    }
  }
}
