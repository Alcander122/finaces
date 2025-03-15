import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyService {
  static const String API_URL = 'https://api.exchangerate.host/latest?base=USD';

  Future<double> getExchangeRate(String from, String to) async {
    try {
      final response = await http.get(Uri.parse('$API_URL&symbols=$from,$to'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        final fromRate = rates[from] ?? 1.0;
        final toRate = rates[to] ?? 1.0;
        return from == 'USD' ? toRate : 1 / fromRate;
      }
    } catch (e) {
      //print('Error obteniendo tasa de cambio: $e');
    }
    // Valor de respaldo realista para COP-USD
    return from == 'COP' ? 0.00025 : 4000.0;
  }
}
