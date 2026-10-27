import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 Servicio centralizado de almacenamiento seguro (Keystore en Android / Keychain en iOS / SharedPreferences en Web)
class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _keyLastEmail = 'last_email';
  static const String _prefixBiometric = 'biometric_enabled_';

  // ===========================================================================
  // 1. GESTIÓN DE ÚLTIMO CORREO (last_email)
  // ===========================================================================

  /// Guarda el último correo de forma segura
  Future<void> saveLastEmail(String email) async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyLastEmail, email);
        return;
      }
      await _storage.write(key: _keyLastEmail, value: email);
    } catch (e) {
      debugPrint('Error guardando último correo: $e');
    }
  }

  /// Obtiene el último correo (con fallback transparente desde SharedPreferences)
  Future<String?> getLastEmail() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getString(_keyLastEmail);
      }
      String? email = await _storage.read(key: _keyLastEmail);
      
      // Migración transparente si venía de SharedPreferences
      if (email == null || email.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        email = prefs.getString(_keyLastEmail);
        if (email != null && email.isNotEmpty) {
          await saveLastEmail(email);
          await prefs.remove(_keyLastEmail);
        }
      }
      return email;
    } catch (e) {
      debugPrint('Error leyendo último correo: $e');
      return null;
    }
  }

  /// Limpia el último correo guardado
  Future<void> clearLastEmail() async {
    try {
      if (kIsWeb) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove(_keyLastEmail);
        return;
      }
      await _storage.delete(key: _keyLastEmail);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyLastEmail);
    } catch (e) {
      debugPrint('Error limpiando último correo: $e');
    }
  }

  // ===========================================================================
  // 2. GESTIÓN DE ESTADO BIOMÉTRICO (biometric_enabled_<uid>)
  // ===========================================================================

  /// Guarda el estado biométrico del usuario cifrado en el Keystore/Keychain
  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    if (kIsWeb) return;
    try {
      final key = '$_prefixBiometric$userId';
      await _storage.write(key: key, value: enabled.toString());
    } catch (e) {
      debugPrint('Error guardando biometría: $e');
    }
  }

  /// Lee el estado biométrico del usuario de forma segura
  Future<bool> isBiometricEnabled(String userId) async {
    if (kIsWeb) return false;
    try {
      final key = '$_prefixBiometric$userId';
      final value = await _storage.read(key: key);
      
      if (value != null) {
        return value.toLowerCase() == 'true';
      }

      // Migración transparente de SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (prefs.containsKey(key)) {
        final legacyValue = prefs.getBool(key) ?? false;
        await setBiometricEnabled(userId, legacyValue);
        await prefs.remove(key);
        return legacyValue;
      }

      return false;
    } catch (e) {
      debugPrint('Error leyendo biometría: $e');
      return false;
    }
  }

  /// Limpia la configuración biométrica del usuario
  Future<void> clearBiometricSetting(String userId) async {
    if (kIsWeb) return;
    try {
      final key = '$_prefixBiometric$userId';
      await _storage.delete(key: key);
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error limpiando biometría: $e');
    }
  }
}
