import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🔐 Servicio centralizado de almacenamiento seguro (Keystore en Android / Keychain en iOS)
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

  /// Guarda el último correo de forma cifrada
  Future<void> saveLastEmail(String email) async {
    await _storage.write(key: _keyLastEmail, value: email);
  }

  /// Obtiene el último correo cifrado (con migración transparente desde SharedPreferences)
  Future<String?> getLastEmail() async {
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
  }

  /// Limpia el último correo guardado
  Future<void> clearLastEmail() async {
    await _storage.delete(key: _keyLastEmail);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastEmail);
  }

  // ===========================================================================
  // 2. GESTIÓN DE ESTADO BIOMÉTRICO (biometric_enabled_<uid>)
  // ===========================================================================

  /// Guarda el estado biométrico del usuario cifrado en el Keystore/Keychain
  Future<void> setBiometricEnabled(String userId, bool enabled) async {
    final key = '$_prefixBiometric$userId';
    await _storage.write(key: key, value: enabled.toString());
  }

  /// Lee el estado biométrico del usuario de forma segura
  Future<bool> isBiometricEnabled(String userId) async {
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
  }

  /// Limpia la configuración biométrica del usuario
  Future<void> clearBiometricSetting(String userId) async {
    final key = '$_prefixBiometric$userId';
    await _storage.delete(key: key);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }
}
