// bank_catalog_repository.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finances/core/data/models/bank_catalog_model.dart';
import 'package:finances/core/errors/handlers/db_error_handler.dart';

class BankCatalogRepository {
  static const String _cacheKey = 'finances_bank_catalog_cache';
  static const String _assetPath = 'assets/bancos_colombia.json';

  /// Obtiene el catálogo completo de bancos de forma offline-first
  Future<List<BankCatalogModel>> getCatalog() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? cachedJson = prefs.getString(_cacheKey);

      if (cachedJson != null && cachedJson.isNotEmpty) {
        try {
          final List<dynamic> decoded = json.decode(cachedJson);
          return decoded.map((item) => BankCatalogModel.fromJson(item)).toList();
        } catch (e) {
          // Si el JSON en caché está corrupto por algún motivo, lo eliminamos y usamos assets
          await prefs.remove(_cacheKey);
        }
      }

      // Fallback al JSON sembrado localmente en assets
      final String assetData = await rootBundle.loadString(_assetPath);
      final List<dynamic> decodedAsset = json.decode(assetData);
      return decodedAsset.map((item) => BankCatalogModel.fromJson(item)).toList();
    } catch (e) {
      throw DbErrorHandler.handle(e);
    }
  }

  /// Guarda una nueva versión del catálogo descargada en caché
  Future<void> saveCatalogToCache(String jsonContent) async {
    try {
      // Validación previa de integridad antes de guardar para evitar romper la app
      final List<dynamic> decoded = json.decode(jsonContent);
      if (decoded.isEmpty || decoded.first is! Map<String, dynamic>) {
        throw FormatException('Estructura de catálogo inválida');
      }

      // Validar campos obligatorios básicos en el primer elemento
      final testItem = decoded.first as Map<String, dynamic>;
      if (!testItem.containsKey('id') || !testItem.containsKey('nombre')) {
        throw FormatException('Faltan campos obligatorios id o nombre');
      }

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonContent);
    } catch (e) {
      throw DbErrorHandler.handle(e);
    }
  }

  /// Sincroniza dinámicamente el catálogo desde un origen remoto (ej. URL HTTP o Firebase Storage)
  /// En caso de fallo, se degrada elegantemente y continúa usando los datos locales de caché/assets.
  Future<bool> syncWithRemote(String remoteJsonUrl) async {
    // Por el momento simulamos un fetching seguro con validación
    // Esto se puede reemplazar en producción con llamadas reales a http/Storage.
    try {
      // Simulación de delay de red
      await Future.delayed(const Duration(seconds: 1));
      
      // Si la URL es vacía o falla, devolvemos false silenciosamente (Graceful Degradation)
      if (remoteJsonUrl.isEmpty) return false;
      
      return true;
    } catch (e) {
      // Ignoramos el error para no bloquear la app, telemetría podría registrarlo aquí
      return false;
    }
  }
}
