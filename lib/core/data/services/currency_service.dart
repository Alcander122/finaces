import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Proveedor para inyección de dependencias de CurrencyService
final currencyServiceProvider = Provider<CurrencyService>((ref) => CurrencyService());

class CurrencyService {
  // 📌 Usamos el endpoint abierto de ExchangeRate-API (sin llave, estable e ilimitado para uso de desarrollo)
  static const String API_URL = 'https://open.er-api.com/v6/latest';

  /// Retorna la tasa de conversión entre [from] y [to]
  Future<double> getExchangeRate(String from, String to) async {
    if (from == to) return 1.0;
    
    try {
      final response = await http.get(
        Uri.parse('$API_URL/$from'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          final toRate = rates[to];
          if (toRate != null) return (toRate as num).toDouble();
        }
      }
    } catch (e) {
      // Fallback silencioso en caso de error de red o timeout
    }

    // 🔙 Valores de respaldo realistas (COP/USD/EUR) en caso de fallo de red
    if (from == 'USD' && to == 'COP') return 4000.0;
    if (from == 'COP' && to == 'USD') return 1 / 4000.0;
    if (from == 'EUR' && to == 'COP') return 4300.0;
    if (from == 'COP' && to == 'EUR') return 1 / 4300.0;
    if (from == 'USD' && to == 'EUR') return 0.92;
    if (from == 'EUR' && to == 'USD') return 1 / 0.92;

    return 1.0;
  }
}

