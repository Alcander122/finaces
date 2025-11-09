import 'dart:convert';
import 'package:http/http.dart' as http;

// Servicio para obtener datos de mercado usando Alpha Vantage (gratuita).
// Regístrate en https://www.alphavantage.co/support/#api-key para tu clave gratuita.
// Límite: 25 requests/día en el plan gratuito.
class MarketService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static const String _apiKey =
      'XCVNZ4VVX56WZ1HN'; // Reemplaza con tu clave gratuita.

  // Obtiene el precio actual de un símbolo (stocks, ETFs).
  Future<double?> getCurrentPrice(String symbol) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final quote = data['Global Quote'];
        if (quote != null) {
          return double.parse(quote['05. price']); // Extrae el precio actual.
        }
      }
    } catch (e) {
      // Log de error: print('Error al obtener precio de $symbol: $e');
    }
    return null; // Retorna null si falla.
  }

  // Obtiene el precio de una criptomoneda (e.g., "BTCUSD").
  Future<double?> getCryptoPrice(String cryptoPair) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl?function=DIGITAL_CURRENCY_DAILY&symbol=$cryptoPair&market=USD&apikey=$_apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timeSeries = data['Time Series (Digital Currency Daily)'];
        if (timeSeries != null && timeSeries.isNotEmpty) {
          final latest = timeSeries.entries.first.value;
          return double.parse(
              latest['4a. close (USD)']); // Precio de cierre más reciente.
        }
      }
    } catch (e) {
      // Log de error: print('Error al obtener precio de $cryptoPair: $e');
    }
    return null;
  }

  // Obtiene la tasa de cambio entre dos monedas (e.g., "USD" a "COP").
  Future<double?> getForexRate(String from, String to) async {
    try {
      final uri = Uri.parse(
          '$_baseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=$from&to_currency=$to&apikey=$_apiKey');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final realtime = data['Realtime Currency Exchange Rate'];
        if (realtime != null) {
          return double.parse(realtime['5. Exchange Rate']); // Tasa de cambio.
        }
      }
    } catch (e) {
      // Log de error: print('Error al obtener tasa de cambio de $from a $to: $e');
    }
    return null;
  }

  // Valor placeholder para bonos (Alpha Vantage no los soporta; usa un valor fijo o externo).
  double getBondValue(String bondType) {
    // Ejemplo: Valor fijo basado en un bono típico (ajusta según necesidad).
    const Map<String, double> bondValues = {
      'US Treasury': 1000.0, // Valor nominal típico de bonos del Tesoro USA.
      'Corporate': 500.0, // Valor estimado para bonos corporativos.
    };
    return bondValues[bondType] ?? 100.0; // Valor por defecto.
  }
}
