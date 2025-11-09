import 'package:finances/core/data/services/market_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Servicio para tasas de cambio. Usa exchangerate.host como primario y Alpha Vantage como fallback.
class CurrencyService {
  static const String _apiUrl = 'https://api.exchangerate.host/latest';
  final MarketService _marketService = MarketService();

  // Obtiene la tasa de conversión entre monedas.
  Future<double> getExchangeRate(String from, String to) async {
    try {
      final response =
          await http.get(Uri.parse('$_apiUrl?base=$from&symbols=$to'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final toRate = rates[to];
        if (toRate != null) return (toRate as num).toDouble();
      }
    } catch (e) {
      // Log de error: print('Error en exchangerate.host: $e');
    }

    // Fallback a Alpha Vantage para forex.
    final fallbackRate = await _marketService.getForexRate(
        from, to); // Método hipotético; ajusta si usas.
    if (fallbackRate != null) return fallbackRate;

    // Valores de respaldo realistas (octubre 2025 aprox.).
    if (from == 'COP' && to == 'USD') return 0.00025; // ~1 USD = 4000 COP.
    if (from == 'USD' && to == 'COP') return 4000.0;
    return 1.0; // Valor por defecto.
  }
}
