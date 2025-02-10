import 'package:http/http.dart' as http;
import 'dart:convert';

class CurrencyService {
  static const String API_URL =
      'https://api.exchangerate-api.com/v4/latest/USD';

  Future<double> getExchangeRate(String from, String to) async {
    try {
      final response = await http.get(Uri.parse(API_URL));
      if (response.statusCode == 200) {
        final rates = json.decode(response.body)['rates'];
        final fromRate = rates[from] ?? 1.0;
        final toRate = rates[to] ?? 1.0;
        return toRate / fromRate;
      }
    } catch (e) {
      print('Error obteniendo tasa de cambio: $e');
    }
    return 1.0;
  }
}
