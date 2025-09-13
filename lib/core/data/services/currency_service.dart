import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyService {
  // ignore: constant_identifier_names
  static const String API_URL = 'https://api.exchangerate.host/latest';

  /// Retorna la tasa de conversión entre [from] y [to]
  Future<double> getExchangeRate(String from, String to) async {
    try {
      // 📌 Definimos la moneda base como "from"
      final response = await http.get(
        Uri.parse('$API_URL?base=$from&symbols=$to'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final toRate = rates[to];
        if (toRate != null) return (toRate as num).toDouble();
      }
    } catch (e) {
      // Log o manejo de error
      // debugPrint('Error obteniendo tasa de cambio: $e');
    }

    // 🔙 Valor de respaldo (ejemplo COP/USD realista)
    if (from == 'COP' && to == 'USD') return 0.00025;
    if (from == 'USD' && to == 'COP') return 4000.0;

    // 🔙 Si no hay datos, devolvemos 1.0 (equivalente)
    return 1.0;
  }
}
