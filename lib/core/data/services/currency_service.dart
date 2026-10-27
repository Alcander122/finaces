import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Proveedor para inyección de dependencias de CurrencyService
final currencyServiceProvider = Provider<CurrencyService>((ref) => CurrencyService());

/// Modelo de datos con las tasas calculadas, timestamp y estado de caché
class CurrencyRates {
  final double usdToCop;
  final double eurToCop;
  final DateTime lastUpdated;
  final bool isFromCache;

  const CurrencyRates({
    required this.usdToCop,
    required this.eurToCop,
    required this.lastUpdated,
    this.isFromCache = false,
  });

  /// Mapa de conversión directo a COP
  Map<String, double> toMap() => {
        'USD': usdToCop,
        'EUR': eurToCop,
        'COP': 1.0,
      };
}

class CurrencyService {
  // 📌 Usamos el endpoint abierto de ExchangeRate-API con base USD (1 sola llamada HTTP)
  static const String _apiUrl = 'https://open.er-api.com/v6/latest/USD';

  static const String _cacheUsdKey = 'currency_cache_usd_cop';
  static const String _cacheEurKey = 'currency_cache_eur_cop';
  static const String _cacheTimestampKey = 'currency_cache_timestamp';
  static const Duration cacheTtl = Duration(hours: 12);

  /// Obtiene las tasas de conversión (USD y EUR cruzado a COP) con soporte de caché de 12 horas
  /// y actualización forzada opcional con [forceRefresh].
  Future<CurrencyRates> getRates({bool forceRefresh = false}) async {
    final prefs = await SharedPreferences.getInstance();

    final cachedUsd = prefs.getDouble(_cacheUsdKey);
    final cachedEur = prefs.getDouble(_cacheEurKey);
    final cachedTimestamp = prefs.getInt(_cacheTimestampKey);

    // 1. Verificar si el caché local en SharedPreferences aún es válido
    if (!forceRefresh &&
        cachedUsd != null &&
        cachedEur != null &&
        cachedTimestamp != null) {
      final cacheDate = DateTime.fromMillisecondsSinceEpoch(cachedTimestamp);
      final age = DateTime.now().difference(cacheDate);

      if (age < cacheTtl) {
        return CurrencyRates(
          usdToCop: cachedUsd,
          eurToCop: cachedEur,
          lastUpdated: cacheDate,
          isFromCache: true,
        );
      }
    }

    // 2. Realizar una sola llamada HTTP con base USD
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 7));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          final copRate = (rates['COP'] as num?)?.toDouble();
          final eurRate = (rates['EUR'] as num?)?.toDouble();

          if (copRate != null && eurRate != null && eurRate > 0) {
            // Tasa cruzada: 1 EUR en COP = (USD -> COP) / (USD -> EUR)
            final eurToCop = copRate / eurRate;
            final now = DateTime.now();

            // Guardar en SharedPreferences
            await prefs.setDouble(_cacheUsdKey, copRate);
            await prefs.setDouble(_cacheEurKey, eurToCop);
            await prefs.setInt(_cacheTimestampKey, now.millisecondsSinceEpoch);

            return CurrencyRates(
              usdToCop: copRate,
              eurToCop: eurToCop,
              lastUpdated: now,
              isFromCache: false,
            );
          }
        }
      }
    } catch (_) {
      // Fallback a caché antiguo si existe
      if (cachedUsd != null && cachedEur != null && cachedTimestamp != null) {
        return CurrencyRates(
          usdToCop: cachedUsd,
          eurToCop: cachedEur,
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(cachedTimestamp),
          isFromCache: true,
        );
      }
    }

    // 3. Fallback estático realista en caso de fallo absoluto sin caché previo
    final fallbackDate = cachedTimestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(cachedTimestamp)
        : DateTime.now();

    return CurrencyRates(
      usdToCop: cachedUsd ?? 4000.0,
      eurToCop: cachedEur ?? 4300.0,
      lastUpdated: fallbackDate,
      isFromCache: cachedUsd != null,
    );
  }

  /// Retorna la tasa de conversión entre [from] y [to] manteniendo compatibilidad
  Future<double> getExchangeRate(String from, String to,
      {bool forceRefresh = false}) async {
    final fromUpper = from.toUpperCase();
    final toUpper = to.toUpperCase();
    if (fromUpper == toUpper) return 1.0;

    final rates = await getRates(forceRefresh: forceRefresh);
    final map = rates.toMap();

    final fromRate = map[fromUpper] ?? 1.0;
    final toRate = map[toUpper] ?? 1.0;

    if (toRate == 0) return 1.0;
    return fromRate / toRate;
  }
}
