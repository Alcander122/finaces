import 'package:finances/core/data/services/currency_service.dart';

class CurrencyConverter {
  final CurrencyService _currencyService = CurrencyService();

  Future<double> convert(double amount, String from, String to) async {
    final rate = await _currencyService.getExchangeRate(from, to);
    return amount * rate;
  }
}
